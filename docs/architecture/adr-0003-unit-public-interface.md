# ADR-0003: Unit Public Interface Contract

## Status
Proposed

## Date
2026-04-30

## Engine Compatibility

| Field | Value |
|-------|-------|
| **Engine** | Godot 4.6.2-stable |
| **Domain** | Core (entity, Resource loading, Node2D scene) |
| **Knowledge Risk** | LOW — Node2D, Resource, Signal, Label, ColorRect all stable since 4.0 |
| **References Consulted** | `docs/engine-reference/godot/VERSION.md`, `docs/engine-reference/godot/current-best-practices.md`, `docs/engine-reference/godot/deprecated-apis.md` |
| **Post-Cutoff APIs Used** | None |
| **Verification Required** | None |

## ADR Dependencies

| Field | Value |
|-------|-------|
| **Depends On** | ADR-0001 (GridSpace — for unit placement coordinates), ADR-0002 (DI Architecture — Unit follows injection pattern) |
| **Enables** | ADR-0004 (Turn System — reads faction/has_acted/is_alive), all Feature-layer ADRs (Movement, Attack, Victory, AI) |
| **Blocks** | Unit, Turn, Movement, Attack, Victory, AI, UI epics — all depend on the Unit public interface being stable |
| **Ordering Note** | Must be Accepted third (after ADR-0001, ADR-0002), before any system that consumes Unit state |

## Context

### Problem Statement

Unit is consumed by 5 downstream systems (Turn System, Movement, Attack, Victory, AI) plus UI. A late change to Unit's public interface — renaming a field, changing a method signature, altering mutation rules — would cascade into all 5 consumers, requiring coordinated PRs. The systems-index.md identifies Unit as a HIGH RISK system: "后期变更会级联引发 Movement/Attack/Turn/AI/UI 重写." This ADR locks the public contract before any downstream implementation begins.

### Constraints

- Unit is a `Node2D` scene (must be in scene tree for rendering), not a pure RefCounted
- UnitStats must be data-driven (`.tres` Resource), per Pillar 1
- Faction enum is in standalone file `src/core/faction.gd` — not nested in Unit
- Only specific fields are mutable; the rest are read-only after init
- MVP has no counter-attack, no status effects, no XP — the interface must not preclude these (reserved slots OK)

### Requirements

- 5 downstream systems must be able to read unit state without knowing Unit internals
- Only owner (Unit) + authorized writers (Attack for HP, Turn for action_state, Map for grid_position) may mutate state
- Invalid .tres data must fail-fast at load time (not silently correct)
- `unit_died` signal must fire exactly once, before `queue_free()`, with the unit reference

## Decision

**Unit exposes a strictly controlled public interface: 5 read-only attributes (`max_hp`, `atk`, `def`, `mov`, `rng`, `faction`), 4 mutable fields with defined writers (`hp`, `grid_position`, `action_state`, `has_acted_this_turn`), 2 mutation methods (`take_damage()`, `heal()`), 1 reset method (`reset_action_state()`), and 1 signal (`unit_died`). All mutation paths are explicitly documented with their authorized callers.**

### Public Interface (Complete)

```gdscript
# src/unit/unit.gd
class_name Unit extends Node2D

# ── Immutable (set at init, read-only thereafter) ──
var unit_id: String              # Auto-generated, monotonically increasing
var max_hp: int                  # Range [5, 20], loaded from UnitStats.tres
var atk: int                     # Range [3, 8]
var def: int                     # Range [0, 5]
var mov: int                     # Range [2, 6] — BFS radius
var rng: int                     # Range [1, 3] — Attack range (Manhattan)
var faction: Faction.Type        # PLAYER or ENEMY

# ── Mutable (specific writers only) ──
var hp: int                      # Writer: AttackResolver (via take_damage), future healer
var grid_position: Vector2i      # Writer: Map.move_unit() — atomic occupancy+position update
var action_state: UnitState      # Writer: InputHandler (select), Map.move_unit() (moved),
                                 #        AttackResolver (acted), TurnManager (reset)
var has_acted_this_turn: bool    # Writer: AttackResolver (execution/skip), TurnManager (reset)

# ── State Queries ──
func is_alive() -> bool:         return hp > 0
func is_dead() -> bool:          return hp <= 0
func can_be_selected() -> bool:  return is_alive() and not has_acted_this_turn and action_state == UnitState.IDLE
func can_move() -> bool:         return action_state == UnitState.SELECTED
func can_attack() -> bool:       return action_state in [UnitState.SELECTED, UnitState.MOVED]

# ── Mutations ──
func take_damage(amount: int) -> void:
    assert(amount > 0, "take_damage: amount must be > 0")
    if not is_alive(): return
    hp = clampi(hp - amount, 0, max_hp)
    if hp == 0:
        unit_died.emit(self)

func heal(amount: int) -> void:   # Reserved — unused in MVP
    assert(amount > 0, "heal: amount must be > 0")
    hp = clampi(hp + amount, 0, max_hp)

func reset_action_state() -> void:
    has_acted_this_turn = false
    action_state = UnitState.IDLE

# ── Signal ──
signal unit_died(unit: Unit)
```

### Mutation Authorization Table

| Field | Authorized Writers | Forbidden Writers |
|-------|-------------------|-------------------|
| `hp` | `take_damage()` (called by AttackResolver), `heal()` (future) | Direct assignment from any external system |
| `grid_position` | `Map.move_unit()` (atomic with occupancy update) | Direct assignment, MovementResolver |
| `action_state` | InputHandler (select/move/attack), TurnManager (reset) | Direct assignment from Movement/Attack/AI |
| `has_acted_this_turn` | AttackResolver (execution/skip), TurnManager (reset) | Direct assignment from InputHandler, Movement, AI |
| `max_hp/atk/def/mov/rng/faction` | Unit._ready() (from .tres) | Any external system — assertion-guarded |

### UnitStats Resource

```gdscript
# src/unit/unit_stats.gd
class_name UnitStats extends Resource

@export var max_hp: int = 10     @export var atk: int = 5
@export var def: int = 2         @export var mov: int = 4
@export var rng: int = 1

func validate() -> bool:
    assert(max_hp >= 5 and max_hp <= 20, "max_hp out of range [5,20]: %d" % max_hp)
    assert(atk >= 3 and atk <= 8, "atk out of range [3,8]: %d" % atk)
    assert(def >= 0 and def <= 5, "def out of range [0,5]: %d" % def)
    assert(mov >= 2 and mov <= 6, "mov out of range [2,6]: %d" % mov)
    assert(rng >= 1 and rng <= 3, "rng out of range [1,3]: %d" % rng)
    return true
```

### Signal Contract

```
signal unit_died(unit: Unit)
  Emitted: exactly once, when hp reaches 0 via take_damage()
  Consumers:
    - Map: removes occupancy, calls queue_free() on the unit node
    - TurnManager: re-evaluates auto-advance and faction elimination
    - Victory: (via TurnManager's re-evaluation of elimination)
  Guarantee: signal fires BEFORE queue_free(). Consumers receive valid unit reference.
  After signal: Map calls queue_free(). TurnManager removes unit from _all_units.
```

## Alternatives Considered

### Alternative 1: All Fields Public (GDScript Default)

- **Description**: Make all unit fields `var` with no access control; let any system read/write directly
- **Pros**: Zero boilerplate; familiar GDScript pattern
- **Cons**: No control over mutation paths; hard to debug HP changes; violates Single Writer principle; makes Unit GDD's risk (5 consumers) unmanaged
- **Rejection Reason**: Unit is the most-consumed interface in the project. Uncontrolled writes would make debugging impossible and violate System Orthogonality.

### Alternative 2: Getter/Setter Methods for Everything

- **Description**: All fields private; access via `get_hp()`/`set_hp()` methods
- **Pros**: Full control; can add logging/validation in setters
- **Cons**: Verbose; GDScript convention is direct property access; 5 downstream systems would need to call `unit.get_atk()` instead of `unit.atk` — noisy diff for no benefit on read-only fields
- **Rejection Reason**: Read-only fields don't need getter methods — GDScript's `var` with documented read-only contract is sufficient. Only mutation methods need wrapping (take_damage over direct hp= assignment).

### Alternative 3: Resource-Based Unit State (Godot Resource Serialization)

- **Description**: Unit state as a separate Resource object; Unit node holds a reference
- **Pros**: Built-in serialization; `.tres` editor support; easy save/load
- **Cons**: Two-object pattern for every unit (Node2D + Resource); Resource duplication semantics (must use `duplicate_deep()` in 4.5+); over-engineered for MVP
- **Rejection Reason**: Unit already uses UnitStats Resource for prototype data. Splitting runtime state into a separate Resource adds complexity without benefit at MVP. Revisit for Tier 3 save/load.

## Consequences

### Positive

- Every system that reads Unit state knows exactly which fields are safe to read
- HP mutations are traceable through a single method (`take_damage`)
- Assertion guards catch invalid writes at development time
- `unit_died` signal contract guarantees Map + Turn + Victory receive consistent notification
- `.tres` validation fails fast — corrupted unit data never silently enters the game

### Negative

- Read-only enforcement relies on convention + code review (GDScript has no `readonly` keyword)
- `take_damage()` indirection adds one function call per attack (negligible)
- `heal()` method exists but is unused in MVP — dead code until Tier 2+

### Risks

- **Risk**: A developer bypasses `take_damage()` and writes `unit.hp = 0` directly.
  - **Mitigation**: Code review rule in Forbidden Patterns: "Only AttackResolver may call take_damage(). No external code may write unit.hp directly." Acceptance test verifies mutation paths.

- **Risk**: `unit_died` signal fires, but a consumer hasn't connected yet (late UI initialization).
  - **Mitigation**: Late-connecting consumers poll `unit.is_alive` and `TurnManager.current_state` — documented in Turn GDD AC-TURN-053.

## GDD Requirements Addressed

| GDD System | Requirement | How This ADR Addresses It |
|------------|-------------|--------------------------|
| unit.md | Core Rule 1: 5 stats data-driven via UnitStats.tres | Defines UnitStats Resource class with `validate()` |
| unit.md | Core Rule 2: Faction enum in standalone file | Confirmed: `src/core/faction.gd`, not nested in Unit |
| unit.md | Core Rule 3: unit_id auto-generated | Monotonically increasing counter |
| unit.md | Core Rule 4: Node2D scene with ColorRect + Label | Confirmed scene structure |
| unit.md | Core Rule 7: `has_acted_this_turn` + action_state | Defines field + authorized writers |
| unit.md | Core Rule 8: Death — signal, Map removes, queue_free | Defines signal contract with 3 consumers |
| unit.md | F1: take_damage — `hp = clamp(hp-amount, 0, max_hp)` | Codified in public interface |
| unit.md | F4: .tres validation — fail on out-of-range stats | Codified in `UnitStats.validate()` |
| unit.md | Edge Case: read-only fields assertion-guarded | Documented in Mutation Authorization Table |
| turn.md | Interactions: reads `faction`, `has_acted`, `is_alive` | All exposed as public read-only |
| movement.md | Interactions: reads `mov`, `grid_position` | All exposed as public read-only |
| attack.md | Interactions: reads `atk/def/rng`, writes via `take_damage` | Mutation path defined |
| victory.md | Interactions: reads `faction`, `is_alive` | All exposed as public read-only |
| ai.md | Interactions: reads all attributes (read-only) | Confirmed: AI only reads, never writes Unit state |

## Performance Implications

- **CPU**: `take_damage()` ≈ integer subtraction + clamp + one branch. <1μs per call.
- **Memory**: One UnitStats Resource per prototype (shared across instances). Unit instances share the same `.tres` reference.
- **Load Time**: `.tres` loading is Godot's native ResourceLoader — negligible.

## Migration Plan

Greenfield. Implementation order:
1. Create `src/core/faction.gd` with `Faction.Type` enum (including `NONE` for draw representation)
2. Create `src/core/unit_state.gd` with `UnitState` enum
3. Create `src/unit/unit_stats.gd` with `UnitStats` Resource + `validate()`
4. Create `src/unit/unit.gd` with the public interface defined in this ADR
5. Create `assets/data/units/` with sample `.tres` files
6. Add Forbidden Patterns to `.claude/docs/technical-preferences.md`

## Validation Criteria

- [ ] `UnitStats.validate()` passes for all stats in declared ranges
- [ ] `UnitStats.validate()` asserts for any stat outside declared range
- [ ] `unit.take_damage(5)` when hp=10 → hp=5; when hp=3 → hp=0 + `unit_died` emitted
- [ ] `unit.take_damage(5)` when hp=0 → immediate return, no signal
- [ ] `unit.take_damage(0)` or `unit.take_damage(-1)` → assertion failure
- [ ] Direct write to `unit.atk` from external code → assertion failure
- [ ] `unit.can_be_selected()` returns true only when `alive AND !has_acted AND state==IDLE`
- [ ] `unit.can_attack()` returns true only when `state in [SELECTED, MOVED]`
- [ ] `unit.heal(5)` when hp=8, max_hp=10 → hp=10 (capped, not 13)
- [ ] 3 units instantiated → `unit_id` = "unit_0", "unit_1", "unit_2"

## Related Decisions

- ADR-0001: GridSpace Coordinate Boundary (Unit placement uses tile_center)
- ADR-0002: DI Architecture (Unit follows DI for its dependencies)
- ADR-0004: Turn System Architecture (Turn reads Unit state, calls reset_action_state)
- `design/gdd/unit.md` — Unit GDD (authoritative design)
- `design/gdd/game-concept.md` — Pillar 1 (data-driven), Module 2 (Unit decision)
