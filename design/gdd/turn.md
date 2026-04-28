# Turn System

> **Status**: In Design
> **Author**: binlee1990 + Claude
> **Last Updated**: 2026-04-29
> **Implements Pillar**: Pillar 2 — System Orthogonality (Turn state machine exposes signals, not internal state)

## Overview

The Turn System is the faction-rotation state machine that governs who acts and when. It iterates through the two factions — PLAYER, then ENEMY, then back — managing the active faction, auto-advancing when all units in the active faction have acted, and exposing a manual "End Turn" override. The Turn System owns no gameplay state of its own: it reads unit `faction` and `has_acted_this_turn` from the Unit system, emits signals at turn boundaries (`turn_started`, `faction_activated`, `turn_ended`), and calls `reset_action_state()` on all units when a new faction turn begins. A configurable turn-cap terminates the match as a deadlock guard. The Turn System is a pure coordinator — it tells every other system "it's your turn to act" or "it's not," and nothing more. Without it, there is no structure: units would sit frozen on the board with no mechanism to advance action, no constraint on action order, and no way for the match to end outside of elimination.

## Player Fantasy

The Turn System gives the match a heartbeat — every faction-phase boundary is a natural pause: survey the board, evaluate threats, commit to a plan. Without it, the board is frozen; with it, the match breathes. Underneath the rhythm is a guarantee: both factions play by the same clock, one turn per rotation, no hidden priority tricks. The player always knows where they are in the cycle, and when every unit has acted, the system advances automatically — no forgotten units, no ambiguity.

## Detailed Design

### Core Rules

1. **Faction Rotation Order**: Fixed two-faction cycle: `PLAYER → ENEMY → PLAYER → ...`. The cycle never skips a faction — even if a faction has zero alive units, the phase transition still occurs (auto-advancing immediately per Rule 3).

2. **Turn Flow**: When a faction phase begins, all units of that faction have `has_acted_this_turn == false` (reset by `reset_action_state()`). The player selects units of the active faction one at a time; each unit may move and then attack (one packed action), after which `has_acted_this_turn` is set to `true`. The phase continues until (a) all alive units of the active faction have `has_acted == true` (Rule 3), or (b) the player presses End Turn (Rule 4).

3. **Auto-Advance**: After each unit completes its action and after each `unit_died` signal, Turn System polls the "all acted" condition: for all units `u` where `u.faction == active_faction AND u.is_alive`, `u.has_acted_this_turn == true`. When this condition holds, Turn System immediately transitions to `FACTION_PHASE_ENDING`. This includes the trivial case where the active faction has zero alive units at phase start.

4. **Manual End Turn**: At MVP, End Turn is available during any faction phase (both PLAYER and ENEMY, since both are player-controlled in hot-seat). Pressing End Turn transitions to `FACTION_PHASE_ENDING`; any alive units of the active faction that have NOT yet acted forfeit their action for this phase. When Tier 2 BasicAI replaces NullAI, the AI signals its own completion via `AIController`; End Turn during ENEMY phase becomes configurable via `end_turn_allowed_during_phase: Dictionary[Faction.Type, bool]` in TurnConfig. End Turn is guarded against re-entrant calls during phase transition.

5. **Turn Cap**: The match has a configurable `turn_cap` stored in `TurnConfig.tres` (a custom Resource), satisfying Pillar 1 (data-driven). Default: 30. Range: [1, 99]. When `turn_number > turn_cap` after an ENEMY phase ends, the match terminates with reason `turn_cap_reached`. The Victory system determines the winner/draw from the final board state.

6. **Turn Counting**: One "turn" = one complete faction cycle (PLAYER phase + ENEMY phase). `turn_number` starts at `1` at match start. It increments by 1 at the end of each ENEMY phase. Displayed as "Turn X/Y" in the HUD.

7. **Unit Death During Phase**: When a unit dies mid-phase, it is excluded from the "all acted" check (only `is_alive` units count). If the death causes the "all acted" condition to become true, auto-advance triggers immediately. Additionally: if a unit death eliminates an entire faction (zero alive units remaining), the phase ends immediately — remaining unacted units of the eliminated faction are skipped, and the match transitions to `MATCH_ENDED`.

8. **Match Start**: Always PLAYER faction first. `turn_number = 1`. `reset_action_state()` called on all units (both factions) during initialization.

9. **Architecture**: `TurnManager` is a `RefCounted` instance, created by the Game scene (composition root) and dependency-injected into all consumers (Input, Victory, AI, UI). It emits signals directly — no SignalBus Autoload at MVP. This matches the `GridSpace` pattern established by the Map GDD and satisfies the project's "dependency injection over singletons" standard. `TurnManager` receives the unit list via `start_match(all_units: Array[Unit])` at match initialization; it does NOT discover units from the scene tree.

### States and Transitions

**States:**

| State | Meaning | Player-Visible? |
|-------|---------|-----------------|
| `MATCH_NOT_STARTED` | Match has not begun. No faction active. Input blocked. | Yes — pre-match screen |
| `FACTION_PHASE_ACTIVE` | A faction is currently acting. Units of `active_faction` are eligible for selection. | Yes — normal gameplay |
| `FACTION_PHASE_ENDING` | Transition between faction phases. Processing: unit reset, turn increment, victory check. Input blocked. | Brief — synchronous at MVP; reserved for future transition animation |
| `MATCH_ENDED` | Match concluded. No further input accepted. Terminal state. | Yes — result screen |

**Transition Table:**

| From | To | Trigger | Actions |
|------|----|---------|---------|
| `MATCH_NOT_STARTED` | `FACTION_PHASE_ACTIVE` | `start_match(units)` | Set `active_faction = PLAYER`. Set `turn_number = 1`. Call `reset_action_state()` on all units. Emit `match_started`, `turn_started(1)`, `faction_activated(PLAYER)`. |
| `FACTION_PHASE_ACTIVE` | `FACTION_PHASE_ENDING` | Auto-advance condition met OR `end_turn_requested` received | Guard re-entrant calls. Emit `faction_phase_ended(active_faction)`. Run ending sequence (below). |
| `FACTION_PHASE_ENDING` | `FACTION_PHASE_ACTIVE` | Ending sequence complete AND match not over | `active_faction = next_faction`. Emit `faction_activated(next)`. If `next == PLAYER`: emit `turn_started(turn_number)`. |
| `FACTION_PHASE_ENDING` | `MATCH_ENDED` | Ending sequence complete AND (turn-cap reached OR faction eliminated) | Emit `match_ended(reason, winner)`. Disable all input. |
| `MATCH_ENDED` | (none) | Terminal | — |

**FACTION_PHASE_ENDING Processing Sequence** (runs synchronously):

1. Determine next faction: `next = (active_faction == PLAYER) ? ENEMY : PLAYER`
2. Reset incoming units: for all `u` where `u.faction == next`: call `u.reset_action_state()`
3. If ending faction was ENEMY: `turn_number += 1`. If `turn_number > turn_cap`: flag `turn_cap_reached`
4. Victory check via `VictoryChecker.determine_winner(units, turn_number, turn_cap)`: returns `{winner: Faction.Type, reason: String}`. If winner is not NONE: flag `faction_eliminated`
5. Route: if `turn_cap_reached OR faction_eliminated` → transition to `MATCH_ENDED`. Else → transition to `FACTION_PHASE_ACTIVE` with `active_faction = next`

### Signals

| Signal | When Emitted | Consumers |
|--------|-------------|-----------|
| `match_started()` | Match initialization complete | UI, Victory |
| `turn_started(turn_number: int)` | Start of each PLAYER phase (beginning of new turn) | UI/HUD — turn counter |
| `faction_activated(faction: Faction.Type)` | A faction begins its phase | UI/HUD — turn indicator; Input — enable/disable unit selection by faction; AI — `take_turn()` entry point (Tier 2) |
| `faction_phase_ended(faction: Faction.Type)` | A faction's phase concludes | UI — transition; Input — clear selection + highlights |
| `match_ended(reason: String, winner: Faction.Type)` | Match terminates | UI — result screen; Input — disable all interaction; AI — cancel (Tier 2) |

`reason` values: `"elimination"` or `"turn_cap"`. `winner` may be `Faction.Type.NONE` for draws (e.g., mutual elimination).

### Interactions with Other Systems

| System | Direction | Data Flow | Interface |
|--------|-----------|-----------|-----------|
| **Unit** | Upstream (reads) | Turn System reads unit state | `unit.faction`, `unit.has_acted_this_turn`, `unit.is_alive` |
| **Unit** | Downstream (writes) | Turn System resets units | `unit.reset_action_state()` — called on all units at match start, and on incoming faction's units at each phase start |
| **Unit** | Upstream (signal) | Unit death notifications | Listens to `unit.unit_died(unit)` on all registered units. On receipt: re-evaluate auto-advance and faction elimination |
| **AI** | Downstream (call, Tier 2) | Turn System invokes AI for ENEMY phase | `AIController.take_turn(units, world_state) -> ActionList`. Turn System owns execution of returned actions. At MVP: AI is `NullAI` — `faction_activated(ENEMY)` is consumed by Input system for hot-seat control |
| **Victory** | Downstream (signal) | Turn System notifies match end | Emits `match_ended(reason, winner)`. Victory system owns the winner/draw determination logic via `VictoryChecker.determine_winner()` |
| **Victory** | Upstream (call) | Turn System queries winner | `VictoryChecker.determine_winner(units, turn_number, turn_cap) -> Dictionary{winner, reason}`. Called during FACTION_PHASE_ENDING step 4 |
| **UI / Input** | Downstream (data) | Turn System exposes HUD state | `active_faction: Faction.Type`, `turn_number: int`, `turn_cap: int`, `current_state: TurnState` — read by HUD for turn indicator and End Turn button visibility |
| **UI / Input** | Upstream (call) | Player triggers End Turn | `end_current_faction_turn()` — called by Input system on End Turn button press. Guarded: ignored if `current_state != FACTION_PHASE_ACTIVE` or transition in progress |
| **Movement / Attack** | Indirect | Turn System gates input only | Turn System does NOT call Movement or Attack directly. It exposes `active_faction` and `current_state`; the Input system uses these to enforce "only units of active faction are selectable" |

## Formulas

### F1: Auto-Advance Condition

The auto-advance formula is defined as:

`auto_advance = ∀ u ∈ units : (u.faction == active_faction ∧ u.is_alive) → u.has_acted`

**Variables:**

| Variable | Symbol | Type | Range | Description |
|----------|--------|------|-------|-------------|
| Auto-advance flag | auto_advance | bool | {true, false} | Whether the active faction phase should end |
| Active faction | active_faction | enum | {PLAYER, ENEMY} | The faction currently taking its phase |
| Registered units | units | Array[Unit] | [0, N] | All units in the match |
| Unit faction | u.faction | enum | {PLAYER, ENEMY} | Which faction the unit belongs to |
| Unit alive | u.is_alive | bool | {true, false} | hp > 0 |
| Unit acted | u.has_acted | bool | {true, false} | Unit completed its move+attack this phase |

**Output Range:** `true` when all alive units in the active faction have acted (or no alive units exist — vacuous truth). `false` when at least one alive unit in the active faction has not yet acted.

**Extreme Behavior:**
- Active faction has zero alive units: vacuous truth → `auto_advance = true`, phase transitions immediately.
- Active faction has ≥1 alive, unacted unit: `auto_advance = false`.
- All alive units have acted: `auto_advance = true`.

**Example:** active_faction = PLAYER. 3 player units: U1 (alive, not acted), U2 (alive, acted), U3 (alive, not acted). First check hits U1 → `has_acted == false` → returns `false` immediately. Player must act with U1 and U3, or press End Turn.

### F2: Turn Increment

The turn increment formula is defined as:

```
if ending_faction == ENEMY:
    new_turn_number = turn_number + 1
    turn_cap_reached = (new_turn_number > turn_cap)
else:
    new_turn_number = turn_number
    turn_cap_reached = false
```

**Variables:**

| Variable | Symbol | Type | Range | Description |
|----------|--------|------|-------|-------------|
| Ending faction | ending_faction | enum | {PLAYER, ENEMY} | The faction whose phase just ended |
| Current turn | turn_number | int | [1, turn_cap] | Turn counter before increment |
| New turn | new_turn_number | int | [1, turn_cap + 1] | Turn counter after increment |
| Turn cap | turn_cap | int | [1, 99] | Maximum turns per match (from TurnConfig.tres, default 30) |
| Cap reached | turn_cap_reached | bool | {true, false} | Whether the turn cap has been exceeded |

**Output Range:** `new_turn_number ∈ [1, turn_cap + 1]`. Never exceeds `turn_cap + 1` — once exceeded, the match ends and no further increments occur.

**Extreme Behavior:**
- `turn_cap = 1`: first ENEMY phase end → `turn_cap_reached = true`.
- `turn_cap = 99`: normal increment, extremely unlikely to trigger.
- PLAYER phase end: `turn_number` unchanged, `turn_cap_reached` always `false`.

**Example:** turn_number = 5, turn_cap = 30, ending_faction = ENEMY → `new_turn_number = 6`, `6 > 30` → `false`, match continues. If turn_number = 30, ending_faction = ENEMY → `new_turn_number = 31`, `31 > 30` → `true`, match ends.

### F3: Next Faction

The next faction formula is defined as:

`next_faction = (active_faction == PLAYER) ? ENEMY : PLAYER`

**Variables:**

| Variable | Symbol | Type | Range | Description |
|----------|--------|------|-------|-------------|
| Active faction | active_faction | enum | {PLAYER, ENEMY} | The faction whose phase is ending |
| Next faction | next_faction | enum | {PLAYER, ENEMY} | The faction whose phase begins next |

**Output Range:** {PLAYER, ENEMY}. Always the opposite of `active_faction`.

**Example:** active_faction = PLAYER → next_faction = ENEMY. active_faction = ENEMY → next_faction = PLAYER. Deterministic, no edge cases.

### F4: Match End Condition

The match end condition formula is defined as:

```
faction_eliminated = (alive_count(PLAYER) == 0) OR (alive_count(ENEMY) == 0)
should_end_match = turn_cap_reached OR faction_eliminated
end_reason = faction_eliminated ? "elimination" : (turn_cap_reached ? "turn_cap" : "")
```

**Variables:**

| Variable | Symbol | Type | Range | Description |
|----------|--------|------|-------|-------------|
| Faction eliminated | faction_eliminated | bool | {true, false} | At least one faction has zero alive units |
| Turn cap reached | turn_cap_reached | bool | {true, false} | Output from F2 |
| Should end match | should_end_match | bool | {true, false} | Route to MATCH_ENDED? |
| End reason | end_reason | String | {"", "elimination", "turn_cap"} | Why the match ended |

**Output Range:** `should_end_match ∈ {true, false}`. `end_reason` is non-empty iff `should_end_match == true`.

**Extreme Behavior:**
- Both factions eliminated simultaneously: `faction_eliminated = true`, `end_reason = "elimination"`. Winner determined by VictoryChecker.
- `turn_cap_reached` AND `faction_eliminated` both true: `faction_eliminated` is evaluated first in the FACTION_PHASE_ENDING sequence; `end_reason = "elimination"`.

**Example 1:** PLAYER alive = 3, ENEMY alive = 0 → `faction_eliminated = true` → `should_end_match = true`, `end_reason = "elimination"`.

**Example 2:** `turn_cap_reached = true`, both factions have alive units → `should_end_match = true`, `end_reason = "turn_cap"`. VictoryChecker determines winner by unit count.

**Example 3:** `turn_cap_reached = false`, `faction_eliminated = false` → `should_end_match = false`. Route to next FACTION_PHASE_ACTIVE.

### F5: Faction Alive Count

The faction alive count formula is defined as:

`alive_count(faction) = |{ u ∈ units : u.faction == faction ∧ u.is_alive }|`

**Variables:**

| Variable | Symbol | Type | Range | Description |
|----------|--------|------|-------|-------------|
| Target faction | faction | enum | {PLAYER, ENEMY} | Which faction to count |
| Registered units | units | Array[Unit] | [0, N] | All units in the match |
| Alive count | result | int | [0, N] | Number of alive units in target faction |

**Output Range:** [0, N], where N is the initial unit count for that faction. Never negative.

**Extreme Behavior:**
- Faction has zero units (none placed): returns 0 → F1 vacuous truth auto-advance, F4 faction_eliminated.
- All units in faction dead: returns 0 → `faction_eliminated = true`.

**Example:** 3 PLAYER units (U1 alive, U2 dead, U3 alive) → `alive_count(PLAYER) = 2`. 2 ENEMY units (E1 dead, E2 dead) → `alive_count(ENEMY) = 0` → F4 `faction_eliminated = true`.

> **Boundary note**: Winner determination (`VictoryChecker.determine_winner(alive_counts, end_reason)`) is owned by the Victory GDD (Module 6). Turn System only detects termination conditions and delegates the "who won" question.

## Edge Cases

### Initialization & Configuration

- **If `start_match()` is called with an empty unit array**: All factions have zero alive units. PLAYER phase begins, F1 vacuous truth triggers immediate auto-advance → FACTION_PHASE_ENDING → PLAYER phase ends (turn_number stays 1, since ending faction is PLAYER not ENEMY) → VictoryChecker sees both factions at alive_count=0 → faction_eliminated → MATCH_ENDED with winner=NONE (draw). Match starts and ends in one frame. Valid degenerate behavior for an empty board.

- **If `start_match()` is called with units in only one faction**: PLAYER phase proceeds normally if PLAYER has units, or auto-advances immediately if PLAYER has zero. When FACTION_PHASE_ENDING runs, the empty faction triggers faction_eliminated → MATCH_ENDED. The empty faction never gets a phase. Valid behavior; map designers should be warned at placement time (not Turn System's responsibility).

- **If `start_match()` is called a second time** (current_state != MATCH_NOT_STARTED): Rejected. `push_error("start_match() called while match already in progress")`. No state change. Guards against accidental re-initialization that would reset turn_number and unit list.

- **If `TurnConfig.tres` is missing or fails to load**: `start_match()` asserts `turn_config != null` with message naming the expected file path. Match does not start. No silent fallback to a hardcoded default — bad data is a bug, consistent with Unit GDD's `.tres` validation philosophy.

- **If `turn_cap` is outside [1, 99]** (0, negative, or >99): TurnConfig `@export` validation asserts on load with message naming the file, value, and allowed range. Match does not start. Consistent with Unit GDD F4 (stat validation on `.tres` load).

- **If `VictoryChecker` is null when `start_match()` is called**: `start_match()` asserts `victory_checker != null`. TurnManager cannot determine winners without it; rejection is a hard fail. Consistent with the dependency injection contract.

### State Transition Guards

- **If `end_current_faction_turn()` is called during FACTION_PHASE_ENDING or MATCH_ENDED**: Ignored silently. The method guards `current_state == FACTION_PHASE_ACTIVE`. At MVP the transition is synchronous so this is unreachable in normal play; the guard exists for future async transitions (animation/sfx in Tier 2+).

- **If `end_current_faction_turn()` is called from within a signal handler** (re-entrant call during the same signal dispatch): The `current_state` guard rejects it — the state is already FACTION_PHASE_ENDING by the time any signal handler runs. No infinite recursion.

- **If `unit_died` signal fires during FACTION_PHASE_ENDING** (theoretical at MVP — no delayed damage sources): Signal handler guards `current_state == FACTION_PHASE_ACTIVE`. Deaths during transition are ignored; elimination was already checked in the ending sequence step 4.

### Data Integrity

- **If TurnManager holds a reference to a unit that has been `queue_free()`'d**: TurnManager listens to `unit_died` and removes the unit from its internal `_all_units` array on receipt: `_all_units.erase(dead_unit)`. The unit is freed by Map after the signal; TurnManager no longer holds the reference. A `is_instance_valid()` guard on all unit iteration provides a GDScript-specific safety net against bypassed signal paths.

- **If external code directly sets `unit.has_acted_this_turn` (bypassing defined flows)**: The auto-advance condition reads whatever value is set. Turn System owns `reset_action_state()` (sets to false); Movement/Attack completion owns setting to true. External writes produce undefined auto-advance timing. Not guarded at runtime — enforced in code review via Forbidden Patterns.

### Elimination & Turn-Cap Interactions

- **If a faction is eliminated by the LAST unacted unit of the active faction** (auto-advance AND elimination both become true simultaneously): The `unit_died` handler checks elimination first (faction_eliminated = true → immediate MATCH_ENDED). Auto-advance is skipped. The eliminated faction's remaining unacted units are irrelevant — the match is over.

- **If `turn_cap_reached` and `faction_eliminated` are both true in the same FACTION_PHASE_ENDING sequence**: Elimination takes priority. `end_reason = "elimination"`. This occurs when the final ENEMY phase kill also crosses the turn cap threshold. Elimination is a stronger signal than timeout.

- **If `turn_cap = 1` and one faction starts with zero units**: PLAYER phase → auto-advance (if PLAYER empty) or normal play → FACTION_PHASE_ENDING → ending faction is PLAYER (turn_number stays 1, NOT incremented — only ENEMY phase endings increment) → faction_eliminated detected → MATCH_ENDED. The turn cap is never checked because elimination triggers first and the turn was never incremented. Valid degenerate behavior.

### Signal Connection Lifecycle

- **If a consumer connects to TurnManager signals after `start_match()` has already fired** (e.g., late-instantiated UI element): The consumer misses the initial `match_started` and first `faction_activated(PLAYER)` signals. Mitigation: TurnManager exposes `current_state`, `active_faction`, and `turn_number` as public read-only properties. Late-connecting consumers poll these to initialize their display. This is a documented contract, not a bug.

## Dependencies

### Upstream Dependencies

| System | Type | Interface Consumed | Notes |
|--------|------|--------------------|-------|
| **Unit** | Hard | `unit.faction`, `unit.has_acted_this_turn`, `unit.is_alive`, `unit.reset_action_state()`, `unit.unit_died` signal | Interface locked by Unit GDD. Without Unit, Turn System has nothing to iterate. |
| **TurnConfig.tres** | Data | `ResourceLoader.load()` → `turn_cap: int` | Custom Resource in `assets/data/`. Pillar 1 compliance. |
| **VictoryChecker** | Hard | `determine_winner(units, turn_number, turn_cap) -> {winner, reason}` | Injected RefCounted. Must be non-null before `start_match()` (assertion guard). |

### Downstream Dependencies

| System | Type | Interface Exposed | Notes |
|--------|------|-------------------|-------|
| **AI / AIController** | Hard (Tier 2) | Calls `take_turn(units, world_state) -> ActionList` during ENEMY phase | At MVP: AI is `NullAI` — Turn System emits `faction_activated(ENEMY)`, consumed by Input system for hot-seat control. Interface slot exists, not wired at MVP. |
| **Victory** | Hard | Emits `match_ended(reason, winner)`; calls `VictoryChecker.determine_winner()` | Turn System detects termination conditions; Victory owns winner logic. Bidirectional contract. |
| **UI / Input** | Hard | Exposes `active_faction`, `turn_number`, `turn_cap`, `current_state` (read-only); receives `end_current_faction_turn()` call | HUD reads state for turn indicator + End Turn button. Input system gates unit selection by `active_faction`. |

### External Dependencies

| Dependency | Type | Notes |
|------------|------|-------|
| `TurnConfig` Resource (.tres) | Data | Per-match turn cap configuration in `assets/data/`. Pillar 1 compliance. |
| `TurnManager` (RefCounted) | Code | Created by Game scene (composition root), DI-injected into consumers. Matches GridSpace pattern. |
| `Faction.Type` enum | Code | Defined in `src/core/faction.gd` (Unit GDD). Turn System reads, does not own.

## Tuning Knobs

| Knob | Location | Safe Range | What Happens If Too Low | What Happens If Too High | Notes |
|------|----------|------------|------------------------|------------------------|-------|
| `turn_cap` | TurnConfig.tres | [1, 99] | 1: match ends after one full cycle — nearly unplayable, useful only for testing | 99: matches may run 30+ minutes with large unit counts, exceeding session budget (5-15 min). Warn if >50. | Default 30. With ~4 units per side, 30 turns ≈ 10–15 minutes. |
| `end_turn_allowed_during_phase` | TurnConfig.tres (reserved) | `{PLAYER: true, ENEMY: true}` at MVP | N/A — reserved for Tier 2 | N/A | When BasicAI (Tier 2) replaces NullAI, ENEMY → false so AI signals completion instead. Defined as `Dictionary[Faction.Type, bool]`. |

**Knob interactions**: `turn_cap` interacts with unit count — more units per faction means longer phases, fewer total turns fit in the session budget. If MVP expands to 6+ units per side, consider lowering `turn_cap` to ~20.

## Visual/Audio Requirements

N/A — Turn System is a pure logic state machine. It owns no rendering nodes and emits no audio. The turn indicator and End Turn button visuals are owned by the UI / Input GDD. The `faction_activated` and `match_ended` signals are the hooks UI uses to trigger any visual transitions.

## UI Requirements

Turn System does not render UI directly, but exposes the following data for HUD consumption:

| Data | Type | HUD Usage |
|------|------|-----------|
| `active_faction` | Faction.Type | Turn indicator display — "Player Turn" / "Enemy Turn" |
| `turn_number` | int | "Turn X / Y" counter |
| `turn_cap` | int | "Turn X / Y" counter |
| `current_state` | TurnState | End Turn button visibility (shown only in FACTION_PHASE_ACTIVE; hidden in MATCH_ENDED and MATCH_NOT_STARTED) |

Input binding: the End Turn button triggers the `end_turn` InputMap action, which routes to `TurnManager.end_current_faction_turn()`. The Input system owns the button widget and click handling; Turn System only receives the method call.

> **UX Flag — Turn System**: This system contributes HUD data but no standalone screen. In Phase 4 (Pre-Production), the `/ux-design` for the HUD should reference `TurnManager`'s exposed properties as the data source for the turn indicator and End Turn button. Note this in the systems index for the UI / Input system.

## Acceptance Criteria

### A. Core Rules

**AC-TURN-001 — Faction Rotation Order (Rule 1)** [Logic]
GIVEN a match has started with `active_faction = PLAYER` and at least one PLAYER unit alive, WHEN the PLAYER phase ends (all PLAYER units have acted), THEN `active_faction` transitions to `ENEMY`, and after the ENEMY phase ends, `active_faction` transitions back to `PLAYER`.

**AC-TURN-002 — Zero-Unit Faction Not Skipped (Rule 1)** [Logic]
GIVEN a match where PLAYER has zero alive units and ENEMY has at least one alive unit, WHEN `start_match()` is called, THEN the PLAYER phase still occurs (auto-advances immediately per F1 vacuous truth), and the ENEMY phase begins — the cycle is never skipped.

**AC-TURN-003 — Unit Action State Reset on Phase Start (Rule 2)** [Integration]
GIVEN a faction phase has just ended and the next faction's phase is about to begin, WHEN `FACTION_PHASE_ENDING` processing runs step 2 (reset incoming units), THEN every alive unit of the incoming faction has `has_acted_this_turn == false`.

**AC-TURN-004 — has_acted Set After Action (Rule 2)** [Integration]
GIVEN a unit of the active faction that has not yet acted this phase, WHEN that unit completes its move+attack action, THEN `unit.has_acted_this_turn` is `true`.

**AC-TURN-005 — Auto-Advance Triggers After Last Unit Acts (Rule 3)** [Logic]
GIVEN a `FACTION_PHASE_ACTIVE` state where exactly one alive unit of the active faction has `has_acted == false`, and all other alive units of the active faction have `has_acted == true`, WHEN that last unacted unit sets `has_acted = true`, THEN the Turn System transitions to `FACTION_PHASE_ENDING`.

**AC-TURN-006 — Auto-Advance on Vacuous Truth (Rule 3)** [Logic]
GIVEN a `FACTION_PHASE_ACTIVE` state where the active faction has zero alive units, WHEN the phase begins (immediately after `faction_activated` is emitted), THEN the Turn System transitions to `FACTION_PHASE_ENDING` without requiring any player input.

**AC-TURN-007 — Manual End Turn Forfeits Remaining Actions (Rule 4)** [Logic]
GIVEN a `FACTION_PHASE_ACTIVE` state where 3 PLAYER units are alive and only 1 has acted, WHEN `end_current_faction_turn()` is called, THEN the phase transitions to `FACTION_PHASE_ENDING`; the 2 unacted units do not get to act this phase.

**AC-TURN-008 — End Turn Re-entrant Guard (Rule 4)** [Logic]
GIVEN the Turn System is in `FACTION_PHASE_ENDING` state, WHEN `end_current_faction_turn()` is called, THEN the call is silently ignored; no state change occurs and no error is raised.

**AC-TURN-009 — Turn Config Default Value (Rule 5)** [Integration]
GIVEN a `TurnConfig.tres` resource with `turn_cap = 30` (default), WHEN `start_match()` loads the config, THEN `turn_cap` is `30`.

**AC-TURN-010 — Turn Cap Range Validation (Rule 5)** [Logic]
GIVEN a `TurnConfig.tres` resource with `turn_cap` set to a value outside [1, 99] (e.g., 0 or 100), WHEN the resource is loaded, THEN an assertion fails with a message naming the file, the invalid value, and the allowed range; the match does not start.

**AC-TURN-011 — Turn Increments After ENEMY Phase Only (Rule 6)** [Logic]
GIVEN a match at `turn_number = 1`, WHEN the PLAYER phase ends and `FACTION_PHASE_ENDING` processes, THEN `turn_number` remains `1` (NOT incremented).

**AC-TURN-012 — Turn Increments After Full Cycle (Rule 6)** [Logic]
GIVEN a match at `turn_number = 1`, WHEN the ENEMY phase ends and `FACTION_PHASE_ENDING` processes, THEN `turn_number` becomes `2`.

**AC-TURN-013 — Dead Unit Excluded from Auto-Advance (Rule 7)** [Logic]
GIVEN a `FACTION_PHASE_ACTIVE` state where the active faction has 2 alive units (both unacted) and 1 dead unit, WHEN one alive unit acts (setting `has_acted = true`), THEN auto-advance does NOT trigger — the dead unit is not counted, and 1 alive unacted unit remains.

**AC-TURN-014 — Elimination Ends Match Immediately (Rule 7)** [Logic]
GIVEN a `FACTION_PHASE_ACTIVE` state where the ENEMY faction has exactly 1 alive unit, and PLAYER units still have unacted units, WHEN a PLAYER unit kills that last ENEMY unit (`unit_died` signal fires), THEN the match transitions directly to `MATCH_ENDED` with `reason = "elimination"`; remaining unacted PLAYER units are skipped.

**AC-TURN-015 — Match Starts PLAYER First, turn_number=1 (Rule 8)** [Logic]
GIVEN a valid `TurnManager` instance with all dependencies injected, WHEN `start_match(units)` is called, THEN `active_faction == PLAYER` and `turn_number == 1`.

**AC-TURN-016 — Architecture: RefCounted, DI, No Autoload (Rule 9)** [Logic/Structural]
GIVEN the Turn System implementation, WHEN code review inspects `TurnManager`, THEN `TurnManager` extends `RefCounted` (not `Node`), does NOT use `Autoload` or `SignalBus`, and receives all dependencies (`units`, `turn_config`, `victory_checker`) via constructor or method injection. Verified by code review and static analysis, not automated test execution.

### B. Formulas

**AC-TURN-017 — F1: All Acted → Auto-Advance True** [Logic]
GIVEN 3 PLAYER units, all alive, all with `has_acted == true`; `active_faction = PLAYER`, WHEN the auto-advance condition is evaluated, THEN `auto_advance == true`.

**AC-TURN-018 — F1: One Unacted → Auto-Advance False** [Logic]
GIVEN 3 PLAYER units, all alive, 2 with `has_acted == true` and 1 with `has_acted == false`; `active_faction = PLAYER`, WHEN the auto-advance condition is evaluated, THEN `auto_advance == false`.

**AC-TURN-019 — F1: Vacuous Truth — Zero Alive in Active Faction** [Logic]
GIVEN 0 alive PLAYER units; `active_faction = PLAYER`, WHEN the auto-advance condition is evaluated, THEN `auto_advance == true` (vacuous truth: the condition "all alive units have acted" is trivially satisfied).

**AC-TURN-020 — F2: PLAYER Phase End Does Not Increment** [Logic]
GIVEN `turn_number = 5`, `turn_cap = 30`, `ending_faction = PLAYER`, WHEN F2 is evaluated, THEN `new_turn_number = 5`, `turn_cap_reached = false`.

**AC-TURN-021 — F2: ENEMY Phase End Increments** [Logic]
GIVEN `turn_number = 5`, `turn_cap = 30`, `ending_faction = ENEMY`, WHEN F2 is evaluated, THEN `new_turn_number = 6`, `turn_cap_reached = false`.

**AC-TURN-022 — F2: Turn Cap Reached** [Logic]
GIVEN `turn_number = 30`, `turn_cap = 30`, `ending_faction = ENEMY`, WHEN F2 is evaluated, THEN `new_turn_number = 31`, `turn_cap_reached = true`.

**AC-TURN-023 — F3: PLAYER → ENEMY** [Logic]
GIVEN `active_faction = PLAYER`, WHEN F3 is evaluated, THEN `next_faction = ENEMY`.

**AC-TURN-024 — F3: ENEMY → PLAYER** [Logic]
GIVEN `active_faction = ENEMY`, WHEN F3 is evaluated, THEN `next_faction = PLAYER`.

**AC-TURN-025 — F4: Elimination Ends Match** [Logic]
GIVEN `alive_count(PLAYER) = 3`, `alive_count(ENEMY) = 0`, WHEN F4 is evaluated, THEN `should_end_match = true`, `end_reason = "elimination"`.

**AC-TURN-026 — F4: Turn Cap Ends Match** [Logic]
GIVEN `turn_cap_reached = true`, `alive_count(PLAYER) > 0`, `alive_count(ENEMY) > 0`, WHEN F4 is evaluated, THEN `should_end_match = true`, `end_reason = "turn_cap"`.

**AC-TURN-027 — F4: Elimination Priority Over Turn Cap** [Logic]
GIVEN `turn_cap_reached = true` AND `faction_eliminated = true` simultaneously, WHEN the FACTION_PHASE_ENDING routing decision is made (step 5), THEN `end_reason = "elimination"` (elimination takes priority over turn cap).

**AC-TURN-028 — F4: Neither Condition → Continue** [Logic]
GIVEN `turn_cap_reached = false`, `faction_eliminated = false`, WHEN F4 is evaluated, THEN `should_end_match = false`, routing continues to the next `FACTION_PHASE_ACTIVE`.

**AC-TURN-029 — F5: Alive Count — Mixed Dead/Alive** [Logic]
GIVEN 3 PLAYER units: U1 (alive), U2 (dead), U3 (alive), WHEN `alive_count(PLAYER)` is evaluated, THEN result is `2`.

**AC-TURN-030 — F5: Alive Count — All Dead** [Logic]
GIVEN 2 ENEMY units: both dead, WHEN `alive_count(ENEMY)` is evaluated, THEN result is `0` → triggers `faction_eliminated = true` per F4.

**AC-TURN-031 — F5: Alive Count — Zero Units in Faction** [Logic]
GIVEN a match where no ENEMY units were placed (empty array for that faction), WHEN `alive_count(ENEMY)` is evaluated, THEN result is `0`.

### C. State Machine Transitions

**AC-TURN-032 — Transition: MATCH_NOT_STARTED → FACTION_PHASE_ACTIVE** [Logic]
GIVEN `current_state = MATCH_NOT_STARTED`, WHEN `start_match(units)` is called with valid inputs, THEN `current_state` becomes `FACTION_PHASE_ACTIVE`, `active_faction = PLAYER`, `turn_number = 1`, and signals `match_started`, `turn_started(1)`, `faction_activated(PLAYER)` are emitted in that order.

**AC-TURN-033 — Transition: FACTION_PHASE_ACTIVE → FACTION_PHASE_ENDING (auto-advance)** [Logic]
GIVEN `current_state = FACTION_PHASE_ACTIVE`, all alive units of active faction have acted, WHEN the last unit completes its action, THEN `current_state` transitions to `FACTION_PHASE_ENDING`, `faction_phase_ended(active_faction)` is emitted.

**AC-TURN-034 — Transition: FACTION_PHASE_ACTIVE → FACTION_PHASE_ENDING (manual end turn)** [Logic]
GIVEN `current_state = FACTION_PHASE_ACTIVE`, WHEN `end_current_faction_turn()` is called, THEN `current_state` transitions to `FACTION_PHASE_ENDING`, `faction_phase_ended(active_faction)` is emitted.

**AC-TURN-035 — Transition: FACTION_PHASE_ENDING → FACTION_PHASE_ACTIVE (next faction)** [Logic]
GIVEN `current_state = FACTION_PHASE_ENDING`, ending sequence complete, no elimination, turn cap not reached, WHEN the ending sequence routes to "continue", THEN `current_state` becomes `FACTION_PHASE_ACTIVE` with `active_faction = next_faction`; `faction_activated(next)` is emitted; if `next == PLAYER`, `turn_started(turn_number)` is also emitted.

**AC-TURN-036 — Transition: FACTION_PHASE_ENDING → MATCH_ENDED (elimination)** [Logic]
GIVEN `current_state = FACTION_PHASE_ENDING`, `faction_eliminated = true`, WHEN the ending sequence reaches step 5 (routing), THEN `current_state` becomes `MATCH_ENDED`; `match_ended("elimination", winner)` is emitted.

**AC-TURN-037 — Transition: FACTION_PHASE_ENDING → MATCH_ENDED (turn cap)** [Logic]
GIVEN `current_state = FACTION_PHASE_ENDING`, `turn_cap_reached = true`, `faction_eliminated = false`, WHEN the ending sequence reaches step 5 (routing), THEN `current_state` becomes `MATCH_ENDED`; `match_ended("turn_cap", winner)` is emitted.

**AC-TURN-038 — Terminal State: MATCH_ENDED Accepts No Transitions** [Logic]
GIVEN `current_state = MATCH_ENDED`, WHEN any method that would change state is called (`end_current_faction_turn()`, or a death signal arrives, or a unit completes an action), THEN no state change occurs; all such calls are silently ignored.

### D. Signal Emission

**AC-TURN-039 — match_started Signal** [Logic]
GIVEN a `TurnManager` instance with a signal watcher connected to `match_started`, WHEN `start_match(units)` is called, THEN `match_started` is emitted exactly once, after `reset_action_state()` has been called on all units.

**AC-TURN-040 — turn_started Signal** [Logic]
GIVEN a match in progress with `turn_number = N`, WHEN a new PLAYER phase begins (transition from FACTION_PHASE_ENDING), THEN `turn_started(N)` is emitted with the current `turn_number` value.

**AC-TURN-041 — faction_activated Signal** [Logic]
GIVEN a faction phase is about to begin, WHEN the transition to `FACTION_PHASE_ACTIVE` completes, THEN `faction_activated(faction)` is emitted with the correct `Faction.Type` value for the incoming faction.

**AC-TURN-042 — faction_phase_ended Signal** [Logic]
GIVEN a faction phase is ending (auto-advance or manual end turn), WHEN the transition to `FACTION_PHASE_ENDING` occurs, THEN `faction_phase_ended(faction)` is emitted with the faction whose phase just ended.

**AC-TURN-043 — match_ended Signal (elimination)** [Logic]
GIVEN a match where all ENEMY units have died, WHEN the match transitions to `MATCH_ENDED`, THEN `match_ended("elimination", PLAYER)` is emitted.

**AC-TURN-044 — match_ended Signal (turn_cap)** [Logic]
GIVEN a match where `turn_cap_reached = true` and both factions have alive units, WHEN the match transitions to `MATCH_ENDED`, THEN `match_ended("turn_cap", winner)` is emitted, where `winner` is determined by `VictoryChecker`.

**AC-TURN-045 — match_ended Signal (draw)** [Logic]
GIVEN both factions eliminated simultaneously (mutual destruction), WHEN the match transitions to `MATCH_ENDED`, THEN `match_ended("elimination", Faction.Type.NONE)` is emitted.

### E. Key Edge Cases

**AC-TURN-046 — Edge: Empty Unit Array → Immediate Draw** [Logic]
GIVEN `start_match()` is called with an empty unit array `[]`, WHEN the match initializes, THEN the match starts and ends in the same frame: PLAYER phase auto-advances (vacuous truth), FACTION_PHASE_ENDING detects both factions eliminated, MATCH_ENDED emitted with `winner = NONE` and `reason = "elimination"`.

**AC-TURN-047 — Edge: start_match Twice Rejected** [Logic]
GIVEN `start_match()` has already been called and `current_state != MATCH_NOT_STARTED`, WHEN `start_match()` is called a second time, THEN `push_error()` is called with a message indicating the match is already in progress; no state change occurs; the existing match state is preserved.

**AC-TURN-048 — Edge: TurnConfig Missing → Assertion Fail** [Logic]
GIVEN `turn_config` is `null` (resource failed to load or was not injected), WHEN `start_match()` is called, THEN an assertion fails with a message naming the expected file path; the match does not start.

**AC-TURN-049 — Edge: VictoryChecker Null → Assertion Fail** [Logic]
GIVEN `victory_checker` is `null` (not injected), WHEN `start_match()` is called, THEN an assertion fails; the match does not start.

**AC-TURN-050 — Edge: unit_died During FACTION_PHASE_ENDING Ignored** [Logic/Instrumented]
GIVEN `current_state = FACTION_PHASE_ENDING` (mid-transition), WHEN a `unit_died` signal fires (theoretical — not reachable at MVP without delayed damage), THEN the signal handler guards and ignores the death; elimination is not re-evaluated; the transition in progress completes normally. Requires instrumentation to test at MVP.

**AC-TURN-051 — Edge: Last Unacted Unit Eliminates Faction → Immediate End** [Logic]
GIVEN PLAYER phase active; ENEMY has 1 alive unit; that unit is the only unacted PLAYER unit's attack target, WHEN the PLAYER unit attacks and kills the last ENEMY unit, THEN `unit_died` handler detects `faction_eliminated = true` and routes to `MATCH_ENDED` immediately; auto-advance is skipped; any remaining unacted PLAYER units do not get to act.

**AC-TURN-052 — Edge: Both turn_cap_reached AND faction_eliminated → Elimination Wins** [Logic]
GIVEN a FACTION_PHASE_ENDING sequence where ending_faction = ENEMY, turn_number = 30, turn_cap = 30, AND the final ENEMY kill also eliminated the ENEMY faction, WHEN the ending sequence evaluates step 4 (victory check) and step 5 (routing), THEN `end_reason = "elimination"` (NOT "turn_cap"); elimination priority is enforced.

**AC-TURN-053 — Edge: Late Signal Connection — Consumer Polls State** [Integration]
GIVEN a UI element is instantiated AFTER `start_match()` has already fired `match_started` and `faction_activated(PLAYER)`, WHEN the late-connecting consumer reads `TurnManager.current_state`, `active_faction`, and `turn_number`, THEN these read-only properties return the correct current values (`FACTION_PHASE_ACTIVE`, `PLAYER`, `1`, respectively), allowing the consumer to initialize its display correctly without having received the initial signals.

**AC-TURN-054 — Edge: turn_cap = 1, One Faction Empty → Immediate End** [Logic]
GIVEN `turn_cap = 1`, PLAYER has 0 units, ENEMY has 1 unit, WHEN `start_match()` is called, THEN PLAYER phase auto-advances (vacuous truth); FACTION_PHASE_ENDING detects `faction_eliminated = true`; MATCH_ENDED emitted with `reason = "elimination"`; `turn_number` is never incremented beyond 1; turn cap is never reached.

**AC-TURN-055 — Edge: is_instance_valid Guard on Unit Iteration** [Logic]
GIVEN a unit reference in `_all_units` has been `queue_free()`'d without the `unit_died` signal firing (bypassed signal path), WHEN Turn System iterates `_all_units` for auto-advance or reset, THEN the freed unit is skipped (via `is_instance_valid()` check); no crash or null-reference error occurs.

### F. Untestable / Requires Instrumentation

**AC-TURN-056 — UNTESTABLE: External has_acted Writes (Data Integrity Edge Case)** [UNTESTABLE by design]
GIVEN external code directly sets `unit.has_acted_this_turn = true` bypassing the normal move+attack completion flow, WHEN the auto-advance condition is evaluated, THEN the system reads the externally-set value and may trigger auto-advance at an unexpected time. This edge case is explicitly NOT guarded at runtime — enforced in code review via Forbidden Patterns. Recommendation: add to `.claude/docs/technical-preferences.md` Forbidden Patterns: "External code must not write to `unit.has_acted_this_turn` — only the Turn System (reset) and Movement/Attack completion (set true) may modify this field."

**AC-TURN-057 — INSTRUMENTED: End Turn During Signal Handler (Re-entrant Guard)** [Logic/Instrumented]
GIVEN a signal handler connected to `faction_phase_ended` that calls `end_current_faction_turn()`, WHEN `faction_phase_ended` is emitted during a normal phase transition, THEN the re-entrant call to `end_current_faction_turn()` is silently ignored; no infinite recursion occurs. Requires test to deliberately create the re-entrant condition (not reachable in normal MVP play).

### Summary

| Category | Count | Logic | Integration | Untestable/Instrumented |
|----------|-------|-------|-------------|------------------------|
| Core Rules (1-8) | 16 | 10 | 4 | 2 |
| Formulas (F1-F5) | 15 | 15 | 0 | 0 |
| State Transitions | 7 | 7 | 0 | 0 |
| Signal Emission | 7 | 7 | 0 | 0 |
| Edge Cases | 12 | 9 | 1 | 2 |
| **Total** | **57** | **48** | **5** | **4** |

**Gate Summary:**
- **BLOCKING (Logic)**: 48 criteria — each requires an automated unit test in `tests/unit/turn/`
- **BLOCKING (Integration)**: 5 criteria — each requires an integration test or documented playtest
- **UNTESTABLE / INSTRUMENTED**: 4 criteria flagged above

## Open Questions

- **OQ1 — turn_cap default value**: Set at 30 per game-concept Q1 resolution (data-driven from day 1). Tuning knob lists default 30 with safe range [1, 99]. Any objection before locking this value? → Resolved: 30 confirmed, data-driven via TurnConfig.tres.
- **OQ2 — AIController interface**: `take_turn(units, world_state) -> ActionList` is defined as provisional in this GDD. Exact `ActionList` and `WorldState` types will be finalized in the AI GDD (Order 7). Turn System only needs the call signature, not the implementation.
- **OQ3 — VictoryChecker contract**: `determine_winner(units, turn_number, turn_cap) -> {winner, reason}` is defined here as Turn System's dependency. Victory GDD (Order 6) must confirm this exact signature. Provisional until Victory GDD is authored.
- **OQ4 — TurnManager as RefCounted with DI**: Architecture decision (Rule 9). Should this be formalized in an ADR before implementation? → Defer to `/architecture-decision turn-system` after GDD is reviewed.
