# ADR-0008: AI Controller Interface

## Status
Accepted

## Date
2026-04-30

## Engine Compatibility

| Field | Value |
|-------|-------|
| **Engine** | Godot 4.6.2-stable |
| **Domain** | Feature (abstract interface, data structures, execution model) |
| **Knowledge Risk** | MEDIUM — `@abstract` decorator (Godot 4.5+). Class-level @abstract IS runtime-enforced; method-level @abstract needs `assert(false)` fallback for release builds |
| **References Consulted** | `docs/engine-reference/godot/VERSION.md`, `docs/engine-reference/godot/breaking-changes.md`, `docs/engine-reference/godot/current-best-practices.md`, `docs/engine-reference/godot/deprecated-apis.md` |
| **Post-Cutoff APIs Used** | `@abstract` decorator (Godot 4.5+) |
| **Verification Required** | Yes — verify `@abstract` on class prevents `.new()` at runtime in Godot 4.6.2 |

## ADR Dependencies

| Field | Value |
|-------|-------|
| **Depends On** | ADR-0002 (DI Architecture — AIController follows RefCounted pattern), ADR-0004 (Turn System — TurnManager calls `take_turn()`), ADR-0005 (Map — consumed via WorldState), ADR-0006 (Movement — BasicAI calls `compute_reachable`), ADR-0007 (Attack — BasicAI calls `get_valid_targets` + `execute_attack`) |
| **Enables** | BasicAI (Tier 2 — implementation of AI behavior), UI (hotseat mode via NullAI) |
| **Blocks** | AI epic, Turn System (AIController integration) |
| **Ordering Note** | Must be Accepted eighth (after ADR-0006 and ADR-0007), before Turn System implementation which needs the AIController interface |

## Context

### Problem Statement

The AIController interface is the most critical interface in the project (Game Concept Risk R5): if designed incorrectly, every Tier 2 AI implementation (BasicAI, future heuristic AI) would require Turn System modifications. The AI system must define a clean contract where AI produces data (ActionList) and Turn System executes it — AI never modifies game state directly. MVP only ships NullAI (returns empty ActionList — hotseat mode), but the interface must be validated by prototyping both NullAI and a BasicAI stub to prove it accommodates two mutually distinct behaviors without any Turn System code changes. This ADR codifies the interface, data structures, and execution model.

### Constraints

- AIController must be `@abstract` — base class cannot be instantiated
- AI must be a pure function: `take_turn(units, world_state) → ActionList`, no side effects
- Turn System owns execution — AI only returns data
- MVP: NullAI returns empty ActionList; ENEMY phase controlled by human (hotseat)
- Interface must accommodate NullAI (zero actions) and BasicAI (move+attack decisions) without Turn edits
- WorldState must be cloneable for AI branch simulation (Tier 2)
- AI must not cache state across `take_turn()` calls

### Requirements

- `@abstract class AIController extends RefCounted` with `@abstract func take_turn(...)`
- ActionPlan: unit, type (ActionType enum), move_target, attack_target
- ActionList: ordered plans, `get_actions()` returns defensive copy
- WorldState: `all_units`, `map`, `_occupancy_snapshot`, `clone()` deep copy
- NullAI: `take_turn()` always returns empty ActionList
- Turn System execution: validate each plan before executing, skip invalid ones, consume `has_acted`

## Decision

**AIController is a `@abstract` `RefCounted` base class defining `take_turn(units: Array[Unit], world_state: WorldState) → ActionList`. AI implementations return a list of `ActionPlan` objects describing each unit's intended move and attack. Turn System iterates the returned ActionList, validates each plan (unit alive, faction matches, target valid), and executes via `Map.move_unit()` and `AttackResolver.execute_attack()`. AI never modifies game state directly. NullAI returns an empty ActionList — MVP hotseat mode relies on InputHandler consuming `faction_activated(ENEMY)` for manual enemy control. The interface is validated by admitting both NullAI (zero behavior) and BasicAI (nearest-target heuristic) without any Turn System code changes.**

### AIController Base Class

```gdscript
# src/ai/ai_controller.gd
@abstract
class_name AIController extends RefCounted

@abstract
func take_turn(units: Array[Unit], world_state: WorldState) -> ActionList:
    assert(false, "AIController.take_turn() must be overridden by subclass")
    return ActionList.new()  # Release fallback — empty list (safe default)
```

### NullAI

```gdscript
# src/ai/null_ai.gd
class_name NullAI extends AIController

func take_turn(units: Array[Unit], world_state: WorldState) -> ActionList:
    return ActionList.new()  # Always empty — ENEMY units do nothing
```

### ActionType Enum

```gdscript
# src/ai/action_type.gd
enum ActionType {
    MOVE_AND_ATTACK,   # Move to move_target, then attack attack_target
    MOVE_ONLY,         # Move to move_target, skip attack
    ATTACK_ONLY,       # Attack attack_target from current position
    WAIT,              # Skip entire phase (move_target == unit.grid_position, attack_target == null)
}
```

### ActionPlan

```gdscript
# src/ai/action_plan.gd
class_name ActionPlan extends RefCounted

var unit: Unit
var type: ActionType
var move_target: Vector2i
var attack_target: Unit

func _init(p_unit: Unit, p_type: ActionType, p_move_target: Vector2i, p_attack_target: Unit = null) -> void:
    assert(p_unit != null, "ActionPlan: unit must not be null")
    
    # Validate field completeness per type
    match p_type:
        ActionType.MOVE_AND_ATTACK:
            assert(p_move_target != p_unit.grid_position, "MOVE_AND_ATTACK requires move_target != current position")
            assert(p_attack_target != null, "MOVE_AND_ATTACK requires attack_target")
        ActionType.MOVE_ONLY:
            assert(p_move_target != p_unit.grid_position, "MOVE_ONLY requires move_target != current position")
        ActionType.ATTACK_ONLY:
            assert(p_move_target == p_unit.grid_position, "ATTACK_ONLY requires move_target == current position")
            assert(p_attack_target != null, "ATTACK_ONLY requires attack_target")
        ActionType.WAIT:
            assert(p_move_target == p_unit.grid_position, "WAIT requires move_target == current position")
            assert(p_attack_target == null, "WAIT requires attack_target == null")
    
    unit = p_unit
    type = p_type
    move_target = p_move_target
    attack_target = p_attack_target
```

### ActionList

```gdscript
# src/ai/action_list.gd
class_name ActionList extends RefCounted

var _actions: Array[ActionPlan] = []

func add(action: ActionPlan) -> void:
    _actions.append(action)

func get_actions() -> Array[ActionPlan]:
    return _actions.duplicate()  # Defensive copy

func is_empty() -> bool:
    return _actions.is_empty()

func size() -> int:
    return _actions.size()
```

### WorldState

```gdscript
# src/ai/world_state.gd
class_name WorldState extends RefCounted

var all_units: Array[Unit]
var map: Map
var _occupancy_snapshot: Dictionary[Vector2i, Unit] = {}

func _init(p_units: Array[Unit], p_map: Map) -> void:
    all_units = p_units
    map = p_map
    # Build occupancy snapshot from map
    for unit in p_units:
        if unit.is_alive():
            _occupancy_snapshot[unit.grid_position] = unit

func clone() -> WorldState:
    var copy := WorldState.new(all_units, map)
    copy._occupancy_snapshot = _occupancy_snapshot.duplicate()  # Deep copy
    return copy

func get_unit_at(coord: Vector2i) -> Unit:
    return _occupancy_snapshot.get(coord, null)

func simulate_move(unit: Unit, from_coord: Vector2i, to_coord: Vector2i) -> void:
    """For AI branch simulation only — modifies the CLONE's snapshot, never the original."""
    _occupancy_snapshot.erase(from_coord)
    _occupancy_snapshot[to_coord] = unit
```

### Turn System Execution Model

```gdscript
# In TurnManager (ADR-0004), when active_faction == ENEMY:
func _execute_ai_turn() -> void:
    var enemy_units: Array[Unit] = []
    for u in _all_units:
        if u.faction == Faction.Type.ENEMY and u.is_alive() and not u.has_acted_this_turn:
            enemy_units.append(u)
    
    if enemy_units.is_empty():
        _transition_to_ending()
        return
    
    var world_state := WorldState.new(_all_units, _map)
    var action_list: ActionList = _ai_controller.take_turn(enemy_units, world_state)
    
    # Release fallback: if action_list is null (missing override in release), treat as empty
    if action_list == null or action_list.is_empty():
        # NullAI or release fallback — no actions. In hotseat mode,
        # InputHandler consumes faction_activated(ENEMY) for manual control.
        return  # Don't auto-advance — wait for human input in hotseat
    
    for plan in action_list.get_actions():
        if plan == null:
            continue
        var unit: Unit = plan.unit
        if unit == null or not unit.is_alive():
            continue
        if unit.faction != Faction.Type.ENEMY:
            push_warning("AI returned action for non-ENEMY unit: %s" % unit.unit_id)
            continue
        if unit.has_acted_this_turn:
            continue
        
        # Execute move
        if plan.move_target != unit.grid_position:
            if not _map.move_unit(unit, unit.grid_position, plan.move_target):
                push_warning("AI move failed for unit %s to %s" % [unit.unit_id, plan.move_target])
        
        # Execute attack
        if plan.attack_target != null and plan.attack_target.is_alive():
            var result: AttackResult = _attack_resolver.execute_attack(unit, plan.attack_target)
            if not result.is_valid:
                push_warning("AI attack failed: %s" % result.error_message)
        
        unit.has_acted_this_turn = true
        unit.action_state = UnitState.ACTED
        
        # After each action, check for auto-advance or faction elimination
        if _check_faction_elimination():
            return  # Match ended — stop executing
        if _check_auto_advance():
            _transition_to_ending()
            return
```

### Design Rationale

**Why AI returns data, Turn executes**: This is the core separation of concerns. AI is a decision-making algorithm — it computes what to do. Turn is a coordination engine — it ensures actions happen in the correct phase and updates game state. If AI executed actions directly, it would need write access to Map, Unit, and Attack — violating the read-only contract. The data-return model enables:
- AI testing without game state (call `take_turn()`, inspect returned ActionList)
- AI replacement without Turn edits (swap NullAI → BasicAI → HeuristicAI)
- Turn validation of AI decisions (faction guard, alive check, occupancy check)

**Why WorldState is a snapshot, not live Map access**: If AI accessed Map directly during planning, its decisions could be affected by changes from earlier ActionPlans in the same list. The snapshot model freezes the world at the start of the ENEMY phase. AI can `clone()` the snapshot for branch simulation (comparing "move E1 first vs E2 first") without polluting the original. Tier 2 BasicAI uses this for occupancy conflict resolution.

**Why `ActionPlan.type` is advisory (Turn ignores it)**: Turn's execution logic reads `move_target` and `attack_target` directly — the `type` field is for human readability and debug logging. This design prevents inconsistency between the declared type and the actual field values. AI implementers must understand: Turn follows the fields, not the label.

**Why `action_list == null` guard exists**: In release builds, `@abstract` on methods is not enforced. If a subclass omits the `take_turn()` override, the base `pass` body returns `null` (GDScript default). The null guard prevents a crash when the execution loop tries `for plan in null.get_actions()`. The base class's `assert(false)` + `return ActionList.new()` provides a second layer of defense in debug builds.

**Why ActionList returns a defensive copy**: Prevents AI implementations from modifying the action list after returning it (e.g., if Turn caches the list reference). Also prevents Turn from accidentally mutating AI's internal state.

**Why NULL_AI does not auto-advance ENEMY phase**: In hotseat mode, after NullAI returns an empty ActionList, the ENEMY phase must wait for human input. Turn System's `_execute_ai_turn()` returns early when `action_list.is_empty()` — it does NOT auto-advance. The human player controls ENEMY units via InputHandler, and presses End Turn to advance. This is the documented hotseat contract.

## Alternatives Considered

### Alternative 1: AI Controls Units Directly (No ActionList)

- **Description**: AIController receives write access to Map and AttackResolver; it calls `map.move_unit()` and `attack_resolver.execute_attack()` directly
- **Pros**: Simpler Turn code — no ActionList iteration loop
- **Cons**: AI must be trusted to validate its own actions (no Turn safety net). AI becomes stateful and harder to test. Turn can't inspect or log AI decisions before execution. Swapping AI implementations risks introducing side-effect bugs.
- **Rejection Reason**: AI as a pure data producer is the core architectural insight from Game Concept R5. Separating planning from execution enables interface validation, testing, and safe AI replacement.

### Alternative 2: AIController as a Node (Scene Tree)

- **Description**: AIController extends Node, uses `_process()` for async thinking, emits `actions_ready` signal
- **Pros**: Natural async pattern; can spread AI computation across frames for complex heuristics
- **Cons**: Tied to scene tree — can't unit test without a scene. Async adds complexity MVP doesn't need (all AI decisions are O(N) where N ≤ 4). Violates ADR-0002 (logic objects are RefCounted).
- **Rejection Reason**: MVP AI is computationally trivial (NullAI = empty list, BasicAI = nearest-target). Synchronous execution is simpler and testable. If Tier 2+ requires async AI (e.g., minimax search), the interface can be extended with `begin_thinking()` / `thinking_complete` signal — additive change, not a retrofit.

### Alternative 3: AI Returns a Single Action (Not a List)

- **Description**: `take_turn()` returns one `ActionPlan`; Turn calls it repeatedly until null
- **Pros**: AI can react to intermediate game state (action N+1 sees the result of action N)
- **Cons**: AI must maintain state across calls (violates pure function constraint). Turn must loop calling AI — more complex than iterating a list. Sequencing decisions (which unit moves first) become implicit in the call order.
- **Rejection Reason**: AI is better at sequencing when it can see all units at once. The ActionList model lets AI resolve occupancy conflicts internally (via WorldState.clone() simulation) before returning a coherent plan. Turn's sequential execution already reflects intermediate state changes — action N+1 executes on the post-action-N game state.

## Consequences

### Positive

- AI is a pure function — same input, same output. Fully testable.
- Turn's execution validation is a safety net — AI bugs produce warnings, not corrupted state
- Interface validated by NullAI + BasicAI stub (two mutually distinct behaviors, zero Turn edits)
- WorldState.clone() enables AI branch simulation without polluting live state
- Defensive copy in `get_actions()` prevents post-return mutation
- Release null-guard prevents crash from missing `take_turn()` override
- `@abstract` on class prevents `AIController.new()` at runtime (4.5+)

### Negative

- ActionPlan/ActionList/WorldState/ActionType = 4 additional files for the interface layer
- Turn's execution loop is ~40 lines (acceptable for the coordination it provides)
- WorldState snapshot may be slightly stale if Turn modifies state before calling AI (MVP: Turn calls AI immediately — no staleness. Tier 2 async: version number field can detect staleness)

### Risks

- **Risk**: AI returns ActionList that doesn't cover all ENEMY units (partial coverage → auto-advance never triggers).
  - **Mitigation**: AI must generate one ActionPlan per unit. Turn does NOT validate coverage completeness (it trusts AI). If BasicAI violates this, ENEMY phase hangs until manual End Turn. AI GDD F1-R1/R2 documents the completeness requirement.

- **Risk**: AI's `take_turn()` implementation modifies the passed WorldState directly (instead of clone).
  - **Mitigation**: Documented constraint. AI GDD F1 consistency predicate. If violated, Turn's subsequent operations see incorrect occupancy. Code review rule: "AIController subclasses must not modify the WorldState passed to `take_turn()`."

- **Risk**: NullAI in non-hotseat mode causes infinite ENEMY phase (empty ActionList → no auto-advance).
  - **Mitigation**: Game startup configuration check: if `mode != hotseat AND ai is NullAI`, push_warning and require confirmation. This is a configuration validation concern, not an AI runtime concern.

## GDD Requirements Addressed

| GDD System | Requirement | How This ADR Addresses It |
|------------|-------------|--------------------------|
| ai.md | Core Rule 1: @abstract AIController base class | `@abstract class AIController extends RefCounted` |
| ai.md | Core Rule 2: take_turn contract | `take_turn(units, world_state) → ActionList` — AI returns data only |
| ai.md | Core Rule 3: ActionPlan data structure | ActionPlan class with 4 fields + type-validated constructor |
| ai.md | Core Rule 4: ActionList data structure | ActionList class with defensive copy |
| ai.md | Core Rule 5: WorldState data structure | WorldState class with clone() + simulate_move() |
| ai.md | Core Rule 6: NullAI specification | NullAI class — always returns empty ActionList |
| ai.md | Core Rule 7: Turn execution model | Full execution loop in `_execute_ai_turn()` |
| ai.md | Core Rule 8: AI consistency responsibility | Documented F1 predicate; Turn validates best-effort |
| ai.md | Core Rule 9: AIController as RefCounted, DI | Follows ADR-0002 pattern |
| ai.md | Core Rule 10: BasicAI behavioral sketch | Documented as interface validation reference |
| ai.md | F1: ActionList consistency predicate (R1–R6) | Codified in ActionPlan constructor assertions |
| ai.md | All edge cases (empty units, null WorldState, missing override, release fallback) | Addressed in guards and fallback logic |
| turn.md | Rule 5: AIController injection | TurnManager receives AIController via constructor; MVP uses NullAI |
| turn.md | Interactions: AI execution | `_execute_ai_turn()` called in ENEMY FACTION_PHASE_ACTIVE |
| game-concept.md | Risk R5: AIController interface prototype | Interface admits NullAI + BasicAI without Turn edits (verifiable by prototype) |
| game-concept.md | Pillar 2: System Orthogonality | AI is a pure function; Turn owns execution |

## Performance Implications

- **CPU**: `NullAI.take_turn()` ≈ instant (returns empty ActionList). `BasicAI.take_turn()` (Tier 2) ≈ BFS for each unit + target filtering ≈ ~4 units × 0.5ms = 2ms. Well within frame budget. `WorldState.clone()` ≈ Dictionary.duplicate() with ~8 entries — <0.1ms.
- **Memory**: `WorldState` ≈ Array[Unit] reference + Map reference + Dictionary (~320 bytes). `ActionList` ≈ Array[ActionPlan] (~4 plans × 40 bytes = 160 bytes). All temporary — GC'd after ENEMY phase ends.
- **Load Time**: No impact — AIController is created at Game._ready().

## Migration Plan

Greenfield. Implementation order:
1. Create `src/ai/action_type.gd` with ActionType enum
2. Create `src/ai/action_plan.gd` with ActionPlan class + type-validated constructor
3. Create `src/ai/action_list.gd` with ActionList class
4. Create `src/ai/world_state.gd` with WorldState class + clone()
5. Create `src/ai/ai_controller.gd` with @abstract base class
6. Create `src/ai/null_ai.gd` with NullAI implementation
7. Wire in Game._ready(): `var ai_controller: AIController = NullAI.new()`
8. Inject into TurnManager per ADR-0004
9. **Before Turn System implementation**: prototype both NullAI and BasicAI stub to validate interface — per Game Concept R5

## Validation Criteria

- [ ] `AIController.new()` prevented at runtime (class-level @abstract in 4.5+)
- [ ] `NullAI.take_turn(any_units, any_worldstate)` returns ActionList with `is_empty() == true`
- [ ] `ActionPlan` construction validates field completeness per type (MOVE_AND_ATTACK, MOVE_ONLY, ATTACK_ONLY, WAIT)
- [ ] `ActionPlan` with null unit → assertion failure
- [ ] `ActionList.get_actions()` returns defensive copy — modifying returned array doesn't affect internal
- [ ] `WorldState.clone()` produces independent occupancy snapshot — modifying clone doesn't affect original
- [ ] BasicAI stub (extends AIController, overrides take_turn) imports only AI types + MovementResolver + AttackRangeResolver — does NOT import TurnManager
- [ ] AIController and NullAI extend RefCounted — no `_ready()`, `_process()`, signal declarations, or Node references
- [ ] Release fallback: calling base `AIController.take_turn()` returns empty ActionList (assert disabled)
- [ ] Turn execution loop skips null ActionPlan entries
- [ ] Turn execution loop skips actions for dead/null/wrong-faction units
- [ ] Turn execution loop skips attack when target is dead at execution time
- [ ] `action_list == null` guard prevents crash in Turn execution loop

## Related Decisions

- ADR-0002: Dependency Injection Architecture (AIController follows RefCounted DI pattern)
- ADR-0004: Turn System Architecture (TurnManager calls `take_turn()`, executes ActionList)
- ADR-0005: Map CSV Loading & Occupancy (WorldState wraps Map)
- ADR-0006: Movement System (BasicAI calls `compute_reachable`)
- ADR-0007: Attack System (BasicAI calls `get_valid_targets` + `execute_attack`)
- `design/gdd/ai.md` — AI GDD (authoritative design)
- `design/gdd/game-concept.md` — Risk R5 (AIController interface prototype requirement)
