# ADR-0004: Turn System Architecture

## Status
Accepted

## Date
2026-04-30

## Engine Compatibility

| Field | Value |
|-------|-------|
| **Engine** | Godot 4.6.2-stable |
| **Domain** | Core (state machine, signal dispatch, RefCounted coordination) |
| **Knowledge Risk** | LOW — RefCounted, Signal, Dictionary all stable since 4.0 |
| **References Consulted** | `docs/engine-reference/godot/VERSION.md`, `docs/engine-reference/godot/current-best-practices.md` |
| **Post-Cutoff APIs Used** | None |
| **Verification Required** | None |

## ADR Dependencies

| Field | Value |
|-------|-------|
| **Depends On** | ADR-0002 (DI Architecture — TurnManager follows DI pattern), ADR-0003 (Unit Interface — reads faction/has_acted/is_alive) |
| **Enables** | All Feature-layer ADRs that respond to Turn signals (Movement, Attack, Victory, AI, UI) |
| **Blocks** | Turn, Movement, Attack, Victory, AI, UI epics — no system can operate without Turn state machine |
| **Ordering Note** | Must be Accepted fourth (final Foundation+Core ADR). After this, Feature-layer ADRs can be written independently. |

## Context

### Problem Statement

The game needs a camp rotation state machine that drives the match loop. Without a centralized Turn System, each system would need to independently track "whose turn is it?" — leading to inconsistent state, race conditions on faction switches, and untestable inter-system coordination. Turn System is the heartbeat: it tells every other system "it's your turn" or "it's not your turn." It must be a pure coordinator — owning the state machine but delegating all domain logic (victory determination, AI planning, movement execution) to injected specialists.

### Constraints

- TurnManager must be RefCounted (DI pattern per ADR-0002), not a Node
- All game values (turn_cap) must be data-driven via TurnConfig.tres (Pillar 1)
- VictoryChecker and AIController are injected — TurnManager owns the wiring, not the logic
- Auto-advance must trigger within the same frame (MVP synchronous execution)
- end_reason must have a single source of truth (VictoryChecker, per Victory GDD)
- End Turn must be reentrancy-guarded
- Match state transitions must be idempotent-after-terminal (MATCH_ENDED absorbs all calls)

### Requirements

- 4-state machine: MATCH_NOT_STARTED → FACTION_PHASE_ACTIVE ⇄ FACTION_PHASE_ENDING → MATCH_ENDED
- PLAYER always starts first, turn_number starts at 1
- Auto-advance: when all alive units of active faction have acted
- Manual End Turn: forfeits remaining unacted units
- Turn increment: only after ENEMY phase ends (a "turn" = full PLAYER+ENEMY cycle)
- turn_cap breach → match_ended with VictoryChecker-determined winner
- Faction elimination → match_ended immediately, skipping remaining actions

## Decision

**TurnManager is a RefCounted state machine with 4 states, 5 transitions, and 5 signals. It receives all units at `start_match()`, injects VictoryChecker and AIController, and is the sole authority on `active_faction`, `turn_number`, and `current_state`. Victory determination is delegated to VictoryChecker; AI planning is delegated to AIController. TurnManager owns only the coordination logic.**

### State Machine

```
                    ┌──────────────────────┐
                    │  MATCH_NOT_STARTED   │
                    └──────────┬───────────┘
                               │ start_match(units)
                               ▼
              ┌────────────────────────────────┐
              │    FACTION_PHASE_ACTIVE         │◄─────────────────────┐
              │  (units act, auto-advance polls) │                      │
              └────────────┬───────────────────┘                      │
                           │ auto-advance OR end_turn_requested        │
                           ▼                                          │
              ┌────────────────────────────────┐                      │
              │    FACTION_PHASE_ENDING         │                      │
              │  (reset, increment, victory chk)│                      │
              └────────┬───────────────────────┘                      │
                       │                                              │
               ┌───────┴───────┐                                      │
               ▼               ▼                                      │
    winner != NONE        winner == NONE ─────────────────────────────┘
               │
               ▼
    ┌──────────────────┐
    │   MATCH_ENDED    │  (terminal — absorbs all calls)
    └──────────────────┘
```

### Public Interface

```gdscript
# src/turn/turn_manager.gd
class_name TurnManager extends RefCounted

# ── State (read-only to consumers) ──
var current_state: TurnState = TurnState.MATCH_NOT_STARTED
var active_faction: Faction.Type
var turn_number: int = 1
var turn_cap: int

# ── Lifecycle ──
func initialize(
    units: Array[Unit],
    config: TurnConfig,
    victory_checker: VictoryChecker,
    ai_controller: AIController
) -> void:
    _all_units = units
    _turn_cap = config.turn_cap
    _victory_checker = victory_checker
    _ai_controller = ai_controller

func start_match() -> void:
    assert(current_state == TurnState.MATCH_NOT_STARTED, "Match already started")
    assert(not _all_units.is_empty(), "Cannot start match with zero units")
    assert(_victory_checker != null, "VictoryChecker not injected")
    assert(_ai_controller != null, "AIController not injected")

    active_faction = Faction.Type.PLAYER
    turn_number = 1
    _reset_all_units()
    current_state = TurnState.FACTION_PHASE_ACTIVE

    match_started.emit()
    turn_started.emit(1)
    faction_activated.emit(Faction.Type.PLAYER)

func end_current_faction_turn() -> void:
    if current_state != TurnState.FACTION_PHASE_ACTIVE: return  # reentrancy guard
    _transition_to_ending()

# ── Signals ──
signal match_started()
signal turn_started(turn_number: int)
signal faction_activated(faction: Faction.Type)
signal faction_phase_ended(faction: Faction.Type)
signal match_ended(reason: String, winner: Faction.Type)

# ── Internal ──
func _on_unit_died(unit: Unit) -> void:
    if current_state != TurnState.FACTION_PHASE_ACTIVE: return
    _all_units.erase(unit)
    _check_faction_elimination()

func _on_unit_action_completed(unit: Unit) -> void:
    if current_state != TurnState.FACTION_PHASE_ACTIVE: return
    if _check_auto_advance():
        _transition_to_ending()
```

### FACTION_PHASE_ENDING Sequence (synchronous)

```
1. _transition_to_ending():
   current_state = FACTION_PHASE_ENDING
   faction_phase_ended.emit(active_faction)

2. Determine next_faction:
   next = (active_faction == PLAYER) ? ENEMY : PLAYER

3. Reset incoming faction units:
   for u in _all_units where u.faction == next: u.reset_action_state()

4. Increment turn (only when ENEMY phase ends):
   if active_faction == ENEMY:
       turn_number += 1
       cap_breached = (turn_number > turn_cap)

5. Victory check:
   result = _victory_checker.determine_winner(_all_units, turn_number, turn_cap)
   # result = {winner: Faction.Type, reason: String}

6. Route:
   if result.winner != Faction.Type.NONE:
       current_state = MATCH_ENDED
       match_ended.emit(result.reason, result.winner)
   else:
       active_faction = next
       current_state = FACTION_PHASE_ACTIVE
       faction_activated.emit(next)
       if next == Faction.Type.PLAYER:
           turn_started.emit(turn_number)
```

### Auto-Advance Formula

```
auto_advance = ∀ u ∈ _all_units:
    (u.faction == active_faction ∧ u.is_alive()) → u.has_acted_this_turn
```

Vacuous truth: if active faction has zero alive units → auto_advance = true. Phase transitions immediately.

### Faction Elimination Check

```
faction_eliminated = (alive_count(PLAYER) == 0) OR (alive_count(ENEMY) == 0)
```

If faction_eliminated is true during `_on_unit_died()`: immediately transition to FACTION_PHASE_ENDING → Victory check → MATCH_ENDED. Remaining unacted units of the winning faction are skipped.

### TurnConfig Resource

```gdscript
# assets/data/turn_config.gd
class_name TurnConfig extends Resource
@export var turn_cap: int = 30   # Range [1, 99]
@export var end_turn_allowed_during_phase: Dictionary = {
    Faction.Type.PLAYER: true,
    Faction.Type.ENEMY: true,    # MVP hotseat: both factions can end turn
}
```

### Signal Contract Summary

| Signal | Emit Condition | Consumers |
|--------|---------------|-----------|
| `match_started()` | After start_match() initialization | HUD, InputHandler |
| `turn_started(int)` | Every PLAYER phase start | HUD (turn counter) |
| `faction_activated(Faction.Type)` | Every faction phase start | HUD (indicator), InputHandler (gating) |
| `faction_phase_ended(Faction.Type)` | Every faction phase end | UI (clear highlights) |
| `match_ended(String, Faction.Type)` | Match terminal state reached | UI (result screen), InputHandler (disable) |

### AIController Integration (Tier 2 Prepared, MVP NullAI)

```gdscript
# In FACTION_PHASE_ACTIVE, when active_faction == ENEMY:
#   action_list = _ai_controller.take_turn(enemy_units, world_state)
#   for plan in action_list.get_actions():
#       # Execute each plan (sequential, synchronous)
#       if not plan.unit.is_alive() or plan.unit.faction != active_faction:
#           continue
#       if plan.move_target != plan.unit.grid_position:
#           map.move_unit(plan.unit, plan.unit.grid_position, plan.move_target)
#       if plan.attack_target != null and plan.attack_target.is_alive():
#           attack_resolver.execute_attack(plan.unit, plan.attack_target)
#       plan.unit.has_acted_this_turn = true
#       plan.unit.action_state = UnitState.ACTED
#   # After all plans executed: auto-advance triggers
```

MVP: NullAI returns empty ActionList. ENEMY phase controlled by human player via hotseat (InputHandler responds to `faction_activated(ENEMY)`).

## Alternatives Considered

### Alternative 1: TurnManager as Node (Scene Tree)

- **Description**: TurnManager as a Node child of Game scene, using `_process()` for auto-advance polling
- **Pros**: Familiar Godot pattern; automatic lifecycle; can use `@onready` for dependency wiring
- **Cons**: Tied to scene tree — cannot unit test without instantiating a scene; `_process()` polling wastes CPU (auto-advance is event-driven, not per-frame); violates ADR-0002 DI pattern
- **Rejection Reason**: TurnManager is pure logic — no rendering, no physics, no `_process()` needed. Event-driven auto-advance (triggered by action completion and unit death) is more efficient and testable.

### Alternative 2: Distributed Turn Logic (No Central TurnManager)

- **Description**: Each Unit tracks its own has_acted; InputHandler checks "all acted" after each action; VictoryChecker runs independently
- **Pros**: No central coordinator; fewer files
- **Cons**: "All acted" check duplicated across InputHandler and Unit death handlers; faction elimination logic scattered; no single place to guard against actions during phase transitions; signal wiring is implicit and fragile
- **Rejection Reason**: Distributed turn logic creates hidden coupling — the "all acted" condition becomes a distributed consensus problem. Central TurnManager is the single observer of all action completions and deaths.

### Alternative 3: TurnManager Emits end_reason (Not VictoryChecker)

- **Description**: TurnManager internally derives end_reason from faction counts and turn_cap, then passes it to VictoryChecker for winner determination only
- **Pros**: TurnManager controls the full termination flow
- **Cons**: Two sources of truth for end_reason — TurnManager and VictoryChecker could disagree. Victory GDD explicitly makes VictoryChecker the sole authority.
- **Rejection Reason**: Victory GDD F3 boundary note explicitly deprecated Turn System F4's end_reason derivation. Single source of truth principle: VictoryChecker returns both winner AND reason.

## Consequences

### Positive

- Single coordinator for all match phase transitions — debuggable, testable
- Event-driven auto-advance — no per-frame polling
- Reentrancy guard prevents End Turn double-trigger
- MATCH_ENDED is a true terminal state — absorbs all subsequent calls
- AIController slot is prepared but MVP uses NullAI — zero-cost interface validation
- TurnConfig.tres makes turn_cap data-driven — tunable without code changes

### Negative

- TurnManager must hold references to all units (up to ~8 at MVP — negligible)
- Signal wiring is explicit in Game._ready() — ~6 signal connections (manageable)
- ENEMY phase in hotseat mode relies on InputHandler checking faction_activated(ENEMY) — implicit contract, not type-enforced

### Risks

- **Risk**: A delayed signal connection misses the initial `match_started` / `faction_activated`.
  - **Mitigation**: TurnManager exposes `current_state`, `active_faction`, `turn_number` as read-only properties. Late-connecting consumers poll these. Documented in Turn GDD AC-TURN-053.

- **Risk**: External code modifies `unit.has_acted_this_turn` directly, triggering unexpected auto-advance.
  - **Mitigation**: Forbidden Pattern: "Only TurnManager (reset) and AttackResolver (execution/skip) may write `has_acted_this_turn`."

- **Risk**: `turn_cap = 1` edge case: match ends after one ENEMY phase, which may surprise testers.
  - **Mitigation**: TurnConfig validation enforces [1, 99] range. Default is 30. Accepted as valid edge case behavior.

## GDD Requirements Addressed

| GDD System | Requirement | How This ADR Addresses It |
|------------|-------------|--------------------------|
| turn.md | Rule 1: Faction rotation PLAYER→ENEMY→PLAYER | Codified in F3: next_faction formula |
| turn.md | Rule 2: Phase flow — all units act, then advance | Codified in F1: auto-advance condition |
| turn.md | Rule 3: Auto-advance (vacuous truth for zero alive) | Implemented in `_check_auto_advance()` |
| turn.md | Rule 4: Manual End Turn — forfeit remaining | `end_current_faction_turn()` with reentrancy guard |
| turn.md | Rule 5: Turn cap from TurnConfig.tres | TurnConfig Resource with [1, 99] validation |
| turn.md | Rule 6: Turn increments only after ENEMY phase | Codified in ending sequence step 4 |
| turn.md | Rule 7: Death mid-phase excludes from auto-advance | `_on_unit_died()` removes from _all_units |
| turn.md | Rule 8: PLAYER starts, turn_number=1 | `start_match()` initialization |
| turn.md | Rule 9: RefCounted, DI, no Autoload | Confirmed RefCounted pattern |
| turn.md | F4: end_reason deprecated — VictoryChecker authority | Codified: ending sequence step 5 reads victory.reason |
| turn.md | Signals: 5 defined, 5 consumers | Signal contract table |
| victory.md | Core Rule 7: end_reason single source | VictoryChecker.determine_winner() → reason |
| ai.md | Core Rule 7: Execution model (Turn executes, AI plans) | AIController integration block |
| game-concept.md | Pillar 1: Data-driven | TurnConfig.tres external data |

## Performance Implications

- **CPU**: Auto-advance check ≈ O(N) where N ≤ 8 (MVP) — negligible. Signal emission ≈ hash table lookup. Entire ending sequence <0.1ms.
- **Memory**: TurnManager + TurnConfig + signal connections = negligible (<1KB).
- **Load Time**: TurnConfig.tres loaded via ResourceLoader — negligible.

## Migration Plan

Greenfield. Implementation order:
1. Create `src/core/turn_state.gd` with TurnState enum
2. Create `assets/data/turn_config.gd` + `turn_config.tres`
3. Create `src/turn/turn_manager.gd` with full state machine
4. Wire in Game._ready() per ADR-0002 composition root pattern
5. Unit test all 37 state transitions (from Turn GDD acceptance criteria)

## Validation Criteria

- [ ] `start_match()` transitions MATCH_NOT_STARTED → FACTION_PHASE_ACTIVE, emits 3 signals in correct order
- [ ] Auto-advance triggers when all alive units of active faction have `has_acted == true`
- [ ] Auto-advance triggers immediately when active faction has zero alive units (vacuous truth)
- [ ] `end_current_faction_turn()` in FACTION_PHASE_ENDING is silently ignored (reentrancy guard)
- [ ] `turn_number` increments only after ENEMY phase ends, not after PLAYER phase
- [ ] `turn_cap` breach → match_ended with VictoryChecker-determined winner
- [ ] Faction elimination mid-phase → immediate MATCH_ENDED, remaining actions skipped
- [ ] `start_match()` called twice → push_error, no state change
- [ ] MATCH_ENDED absorbs all subsequent state change attempts
- [ ] VictoryChecker null at start_match → assertion failure

## Related Decisions

- ADR-0002: DI Architecture (TurnManager follows this pattern)
- ADR-0003: Unit Public Interface (TurnManager reads faction/has_acted/is_alive)
- `design/gdd/turn.md` — Turn GDD (authoritative design)
- `design/gdd/victory.md` — Victory GDD (determine_winner contract)
- `design/gdd/ai.md` — AI GDD (AIController take_turn contract)
