# ADR-0007: Attack System — Damage Formula + Range Check

## Status
Proposed

## Date
2026-04-30

## Engine Compatibility

| Field | Value |
|-------|-------|
| **Engine** | Godot 4.6.2-stable |
| **Domain** | Feature (deterministic formula, target filtering, RefCounted resolver) |
| **Knowledge Risk** | LOW — `RefCounted`, `Array`, `Signal` all stable since 4.0 |
| **References Consulted** | `docs/engine-reference/godot/VERSION.md`, `docs/engine-reference/godot/current-best-practices.md` |
| **Post-Cutoff APIs Used** | None |
| **Verification Required** | None |

## ADR Dependencies

| Field | Value |
|-------|-------|
| **Depends On** | ADR-0001 (GridSpace — for Map coordinate queries), ADR-0002 (DI Architecture — Resolver pattern), ADR-0003 (Unit Interface — reads `atk/def/rng/hp`, writes via `take_damage`), ADR-0005 (Map — consumes `get_unit_at`), ADR-0006 (Movement — references `manhattan()` for range check) |
| **Enables** | ADR-0008 (AI — BasicAI calls `get_valid_targets` + `execute_attack`), UI (consumes `get_valid_targets` for highlight, `resolve_damage` for preview) |
| **Blocks** | Attack, AI (Tier 2 BasicAI target selection), UI (attack highlight + damage preview) epics |
| **Ordering Note** | Must be Accepted seventh (after ADR-0006), before AI ADR which consumes Attack's target list |

## Context

### Problem Statement

Attack is the resolution phase of the SRPG action loop — it converts player intent (click on enemy) into game state change (HP reduction, possible death). Without a codified Attack ADR, the damage formula, range check, target filtering, and execution flow remain scattered across GDD sections rather than centralized in an architectural decision. Attack is the second Feature-layer system; it follows the same "pure function resolver + immutable result" pattern established by Movement (ADR-0006). The key architectural questions are: (1) the damage formula's floor guarantee, (2) ownership of the range check formula, (3) the separation between target-listing (AttackRangeResolver) and execution (AttackResolver).

### Constraints

- Damage must be deterministic — no RNG, no crit, no hit rate
- Damage floor = 1 (prevents stalemate when ATK ≤ DEF)
- Range check uses Manhattan distance (owned by Movement GDD F2, consumed here)
- Target filtering must exclude same-faction, dead, and out-of-range units
- Attack execution is synchronous (MVP: no animation delay)
- No counter-attack in MVP; `damage_dealt` signal reserved for Tier 2
- Must provide a static damage preview method for UI hover (no side effects)

### Requirements

- `AttackResolver.execute_attack(attacker, target) → AttackResult` — full execution
- `AttackResolver.resolve_damage(atk, def) → int` — static preview, no Unit references
- `AttackRangeResolver.get_valid_targets(unit, map) → Array[Unit]` — sorted target list
- `AttackResult` immutable: `{damage, killed, attacker, target}`
- Precondition guards: attacker alive, target alive, attacker not acted, target in range, different faction
- `damage_dealt(attacker, target, damage)` signal emitted on successful attack

## Decision

**AttackResolver is a RefCounted with two entry points: `execute_attack(attacker, target) → AttackResult` for full execution, and `static resolve_damage(atk, def) → int` for UI preview. AttackRangeResolver provides `get_valid_targets(unit, map) → Array[Unit]` sorted by distance then HP. The damage formula `max(atk − def, 1)` is deterministic with a floor of 1. Range is checked via Movement's `manhattan()` function. Precondition failures return `AttackResult.INVALID` — no exceptions, no partial state changes. The `damage_dealt` signal is emitted on success but no counter-attack logic exists in MVP.**

### AttackResolver

```gdscript
# src/attack/attack_resolver.gd
class_name AttackResolver extends RefCounted

signal damage_dealt(attacker: Unit, target: Unit, damage: int)

const DAMAGE_FLOOR: int = 1

static func resolve_damage(atk: int, def: int) -> int:
    return maxi(atk - def, DAMAGE_FLOOR)

func execute_attack(attacker: Unit, target: Unit) -> AttackResult:
    # ── Precondition guards ──
    if attacker == null:
        return AttackResult.invalid("attacker is null")
    if target == null:
        return AttackResult.invalid("target is null")
    if not attacker.is_alive():
        return AttackResult.invalid("attacker is dead")
    if not target.is_alive():
        return AttackResult.invalid("target is already dead")
    if attacker.has_acted_this_turn:
        return AttackResult.invalid("attacker has already acted this turn")
    if attacker.action_state not in [UnitState.SELECTED, UnitState.MOVED]:
        return AttackResult.invalid("attacker not in attack-ready state")
    if target.faction == attacker.faction:
        return AttackResult.invalid("cannot attack same-faction unit")
    
    # ── Range check ──
    var dist: int = MovementResolver.manhattan(attacker.grid_position, target.grid_position)
    if dist == 0 or dist > attacker.rng:
        return AttackResult.invalid("target out of range (dist=%d, rng=%d)" % [dist, attacker.rng])
    
    # ── Damage computation ──
    var damage: int = resolve_damage(attacker.atk, target.def)
    
    # ── Apply damage ──
    target.take_damage(damage)
    
    # ── Update attacker state ──
    attacker.has_acted_this_turn = true
    attacker.action_state = UnitState.ACTED
    
    # ── Emit signal ──
    damage_dealt.emit(attacker, target, damage)
    
    return AttackResult.new(damage, not target.is_alive(), attacker, target)
```

### AttackRangeResolver

```gdscript
# src/attack/attack_range_resolver.gd
class_name AttackRangeResolver extends RefCounted

func get_valid_targets(unit: Unit, map: Map) -> Array[Unit]:
    var targets: Array[Unit] = []
    
    if unit == null or map == null:
        return targets
    
    # Collect all enemy units in range
    for coord in _get_potential_target_coords(unit):
        var target: Unit = map.get_unit_at(coord)
        if target == null:
            continue
        if not target.is_alive():
            continue
        if target.faction == unit.faction:
            continue
        targets.append(target)
    
    # Sort: distance ascending, then HP ascending (lowest HP first)
    targets.sort_custom(_sort_by_distance_then_hp.bind(unit.grid_position))
    
    return targets

func _get_potential_target_coords(unit: Unit) -> Array[Vector2i]:
    # Generate all coords within Manhattan distance ≤ unit.rng
    var coords: Array[Vector2i] = []
    var center := unit.grid_position
    var rng: int = unit.rng
    
    for dr in range(-rng, rng + 1):
        var remaining: int = rng - absi(dr)
        for dc in range(-remaining, remaining + 1):
            if dr == 0 and dc == 0:
                continue  # exclude self
            coords.append(Vector2i(center.x + dr, center.y + dc))
    
    return coords

static func _sort_by_distance_then_hp(a: Unit, b: Unit, origin: Vector2i) -> bool:
    var da: int = MovementResolver.manhattan(origin, a.grid_position)
    var db: int = MovementResolver.manhattan(origin, b.grid_position)
    if da != db:
        return da < db
    return a.hp < b.hp
```

### AttackResult

```gdscript
# src/attack/attack_result.gd
class_name AttackResult extends RefCounted

var damage: int
var killed: bool
var attacker: Unit
var target: Unit
var is_valid: bool
var error_message: String

static var INVALID: AttackResult = _create_invalid()

func _init(p_damage: int, p_killed: bool, p_attacker: Unit, p_target: Unit) -> void:
    damage = p_damage
    killed = p_killed
    attacker = p_attacker
    target = p_target
    is_valid = true
    error_message = ""

static func invalid(reason: String) -> AttackResult:
    var result := AttackResult.new(0, false, null, null)
    result.is_valid = false
    result.error_message = reason
    return result

static func _create_invalid() -> AttackResult:
    return invalid("sentinel")
```

### Design Rationale

**Why separate AttackResolver and AttackRangeResolver**: They serve different consumers and have different call patterns. `AttackRangeResolver` is called on unit selection (to show attackable targets) and after movement (to re-evaluate). `AttackResolver` is called on click confirmation. The separation follows Interface Segregation: UI only needs target lists for rendering; it shouldn't have access to `execute_attack()`. Conversely, AI (Tier 2) calls both — `get_valid_targets()` to choose, `execute_attack()` to commit.

**Why `resolve_damage` is static**: UI calls this for hover preview — it needs the damage number without any Unit references or side effects. A static method accepting bare integers makes this contract explicit. The same formula (`max(atk - def, 1)`) is used by both `resolve_damage` (preview) and `execute_attack` (execution) — single source of truth in the static method.

**Why `AttackResult.INVALID` is a sentinel, not null**: Returning `null` would require every caller to null-check. The sentinel pattern allows callers to check `result.is_valid` or `result == AttackResult.INVALID` for a clear failure path without null-reference risk.

**Why damage floor is 1, not 0**: Without the floor, ATK ≤ DEF produces zero damage — a unit could be attacked indefinitely without progress. Floor=1 guarantees every attack makes progress, preventing stalemate. This is the standard SRPG convention (Fire Emblem, FFT, XCOM all use damage ≥ 1). Tier 2 could make the floor configurable per-unit or per-ability.

## Alternatives Considered

### Alternative 1: Single AttackResolver Class (No RangeResolver)

- **Description**: `AttackResolver` handles both target listing and execution in one class
- **Pros**: One less file; simpler DI wiring
- **Cons**: UI gets access to `execute_attack()` when it only needs `get_valid_targets()`. Single Responsibility violation. Target listing is a read-only query; execution is a state mutation — different concerns, different callers.
- **Rejection Reason**: Interface Segregation. UI should not be able to call `execute_attack()` — only InputHandler should. Separate classes enforce this at the type level.

### Alternative 2: Damage Formula in Unit (unit.calculate_damage_to(target))

- **Description**: `unit.calculate_damage_to(target) → int` — damage formula is a Unit method
- **Pros**: Damage depends on Unit stats; colocation with the data seems natural
- **Cons**: Unit gains knowledge of the combat formula. If the formula changes (e.g., adding weapon triangle in Tier 2), Unit must be modified. Unit already has 5 downstream consumers — adding combat logic violates Single Responsibility.
- **Rejection Reason**: Damage calculation is a game rule, not a property of Unit. AttackResolver as the formula owner enables formula changes without touching Unit code.

### Alternative 3: Range Check Inside AttackResolver Only

- **Description**: No `AttackRangeResolver`; UI calls `AttackResolver.is_in_range(unit, target) → bool` for each potential target
- **Pros**: Simpler API; one less class
- **Cons**: UI must iterate all enemy units and check range individually — O(enemies × range_area). Range check requires Manhattan distance computation (trivial, but the iteration pattern is scattered across UI code). Sorting by distance/HP becomes UI's responsibility.
- **Rejection Reason**: Centralized target filtering in `AttackRangeResolver` gives AI (Tier 2) a single entry point for target selection. UI benefits from the sorted list without implementing sort logic.

## Consequences

### Positive

- Deterministic damage makes combat fully predictable — no RNG frustration
- Damage floor = 1 prevents stalemate; every attack makes progress
- Static `resolve_damage` enables UI preview without coupling to Unit instances
- Separate resolver classes enforce Interface Segregation (UI can't execute attacks)
- `AttackResult.INVALID` sentinel provides clear precondition failure handling
- `damage_dealt` signal is reserved for Tier 2 counter-attack — zero code change needed
- Pure function pattern enables unit testing without scene tree

### Negative

- Two resolver classes instead of one (but justified by Interface Segregation)
- Manhattan distance dependency on Movement creates a cross-system import (but this mirrors the GDD dependency graph — Attack depends on Movement)
- `DAMAGE_FLOOR = 1` as a const means changing it requires a code change (acceptable — it's a game rule, not a tuning value)

### Risks

- **Risk**: `execute_attack()` sets `has_acted = true` even if `take_damage()` is a no-op (target already dead guard). This is intentional — the action was consumed by the attempt. But if both guards trigger (dead target + dead attacker edge case), the return is INVALID and `has_acted` is NOT set. Consistent: INVALID = action not consumed; success = action consumed.

- **Risk**: AttackResolver depends on `MovementResolver.manhattan()` — a cross-system static call. If Movement is refactored, the import path may break.
  - **Mitigation**: `manhattan()` is a pure static function — trivial to relocate to a shared utility if needed. The GDD ownership chain (Movement defines, Attack references) is encoded in both GDDs.

## GDD Requirements Addressed

| GDD System | Requirement | How This ADR Addresses It |
|------------|-------------|--------------------------|
| attack.md | Core Rule 1: Attack preconditions | Precondition guards in `execute_attack()` — alive, faction, state, not acted |
| attack.md | Core Rule 2: Range check (Manhattan ≤ rng) | `MovementResolver.manhattan()` call in `execute_attack()` |
| attack.md | Core Rule 3: Target validation | `get_valid_targets()` — faction, alive, range; `execute_attack()` duplicate guards |
| attack.md | Core Rule 4: Damage formula `max(atk-def, 1)` | `resolve_damage()` + `DAMAGE_FLOOR = 1` |
| attack.md | Core Rule 5: Attack execution flow | `execute_attack()` — damage compute → apply → state update → signal |
| attack.md | Core Rule 6: Direct attack from SELECTED | Supported: `action_state in [SELECTED, MOVED]` guard |
| attack.md | Core Rule 7: Post-move attack from MOVED | Supported: same guard |
| attack.md | Core Rule 8: Skip attack | Documented — InputHandler sets `has_acted=true, action_state=ACTED` without calling `execute_attack()` |
| attack.md | Core Rule 9: No counter-attack (MVP) | `damage_dealt` signal emitted; no consumer in MVP |
| attack.md | Core Rule 10: AttackResolver as RefCounted | `extends RefCounted`, pure function pattern |
| attack.md | Core Rule 11: AttackRangeResolver | `get_valid_targets()` — filter + sort |
| attack.md | Core Rule 12: resolve_damage preview | Static method, bare integers, no side effects |
| attack.md | F1: Damage formula | `maxi(atk - def, DAMAGE_FLOOR)` |
| attack.md | F2: Range check Manhattan | `MovementResolver.manhattan()` |
| attack.md | F4: resolve_damage (preview) | `static func resolve_damage(atk, def)` |
| attack.md | All edge cases (dead target, same faction, out-of-range, null) | Precondition guards return `AttackResult.INVALID` |
| movement.md | F2: Manhattan distance ownership | Confirmed: Movement owns formula, Attack consumes via static import |
| game-concept.md | Pillar 2: System Orthogonality | Pure function, no side effects beyond Unit state writes |

## Performance Implications

- **CPU**: `resolve_damage()` ≈ one subtraction + one max. <1ns. `get_valid_targets()` ≈ O(rng²) coordinate generation + O(enemies) filtering. For RNG=3 → 24 coordinates checked, ~4 enemies → <100 iterations total. <0.1ms. `execute_attack()` ≈ guards + `resolve_damage` + `take_damage` + signal emit. <0.1ms.
- **Memory**: `AttackResult` ≈ 5 fields × 8 bytes = 40 bytes per attack. `AttackRangeResolver` returns array of Unit references (no allocation beyond the array). Negligible.
- **Load Time**: No impact — resolvers are instantiated at Game._ready().

## Migration Plan

Greenfield. Implementation order:
1. Create `src/attack/attack_result.gd` with `AttackResult` class + INVALID sentinel
2. Create `src/attack/attack_resolver.gd` with `resolve_damage()` + `execute_attack()`
3. Create `src/attack/attack_range_resolver.gd` with `get_valid_targets()`
4. Wire in Game._ready() per ADR-0002: `var attack_resolver := AttackResolver.new()`
5. Inject into InputHandler for attack target highlighting and execution
6. Unit test all 36 ATK×DEF combinations + range edge cases

## Validation Criteria

- [ ] `resolve_damage(5, 2)` = 3; `resolve_damage(3, 5)` = 1 (floor); `resolve_damage(8, 0)` = 8
- [ ] All 36 ATK×DEF combinations within [3,8]×[0,5] → `damage ≥ 1` and `damage ≤ 8`
- [ ] `execute_attack(alive_attacker, alive_enemy_target)` → `AttackResult.is_valid == true`, damage applied, `has_acted == true`
- [ ] `execute_attack(dead_attacker, target)` → `AttackResult.INVALID`, no state change
- [ ] `execute_attack(attacker, same_faction_target)` → `AttackResult.INVALID`
- [ ] `execute_attack(attacker, target_out_of_range)` → `AttackResult.INVALID`
- [ ] `execute_attack(already_acted_attacker, target)` → `AttackResult.INVALID`
- [ ] `execute_attack(attacker, null_target)` → `AttackResult.INVALID`
- [ ] `get_valid_targets(unit, map)` filters: same-faction excluded, dead excluded, out-of-range excluded
- [ ] `get_valid_targets()` returns list sorted by distance ascending, then HP ascending
- [ ] Successful attack emits `damage_dealt(attacker, target, damage)` exactly once
- [ ] Successful attack sets `attacker.has_acted = true` and `action_state = ACTED`
- [ ] `resolve_damage(999, -5)` = 1004 (does NOT validate stat ranges — pure math)
- [ ] `damage_dealt` signal carries correct attacker, target, and damage values

## Related Decisions

- ADR-0001: GridSpace Coordinate Boundary (Map uses GridSpace for coordinates)
- ADR-0002: Dependency Injection Architecture (Resolver pattern)
- ADR-0003: Unit Public Interface (reads `atk/def/rng/hp/faction`, writes via `take_damage`)
- ADR-0005: Map CSV Loading & Occupancy (consumes `get_unit_at`)
- ADR-0006: Movement System (references `manhattan()` for range check)
- ADR-0008: AI Controller Interface (BasicAI calls `get_valid_targets` + `execute_attack`)
- `design/gdd/attack.md` — Attack GDD (authoritative design)
