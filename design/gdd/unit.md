# Unit

> **Status**: In Design
> **Author**: binlee1990 + Claude
> **Last Updated**: 2026-04-29
> **Implements Pillar**: Pillar 1 — Data-Driven (all unit stats are external config); Pillar 4 — Generic Vocabulary (HP/ATK/DEF/MOV/RNG are cross-genre SRPG terms)

## Overview

The Unit system defines the game pieces players command and fight: each unit is a named entity carrying five stats — `HP`, `ATK`, `DEF`, `MOV`, `RNG` — and belongs to one of two factions (Player or Enemy, embedded in this system at MVP). Units are placed on the Map at grid coordinates and rendered as flat-colored geometric shapes with HP text heads-up, per the Programmer Art Functional palette. The Unit system is the Core layer's stable interface: five downstream systems (Turn System, Movement, Attack, Victory, AI) consume the Unit public API, so this GDD defines not just what a unit *is* but the contract every system reads from. Without units, there are no actors — the board would be an empty grid with no one to move, attack, or win.

## Player Fantasy

The Unit system's fantasy is **ownership through decision**. A unit has no name, no backstory, no class — it is yours because *you* decided where it stands, when it moves, and whom it attacks. Five transparent numbers — HP, ATK, DEF, MOV, RNG — are a promise: MOV 5 means 5 tiles of reach, HP 8 means 8 points of survival, and every reduction is a visible consequence of a choice already made. When a unit falls, the loss is not narrative grief but tactical contraction: fewer pieces, fewer options, fewer threats to project. The fantasy lives in the moment of hovering a tile and knowing — with total transparency — exactly what will happen if you click. No hidden modifiers, no dice rolls. The weight is in the decision, not in the unknown.

## Detailed Design

### Core Rules

1. **Stats**: Each unit carries five integer stats. All stats are data-driven — defined in a `UnitStats` custom Resource (`.tres`), never hardcoded.

| Stat | Symbol | Type | Default | Range | Description |
|------|--------|------|---------|-------|-------------|
| Hit Points | `hp` / `max_hp` | int | 10 | 5–20 | Current and maximum health. `hp ≤ 0` = death |
| Attack | `atk` | int | 5 | 3–8 | Raw damage before DEF reduction |
| Defense | `def` | int | 2 | 0–5 | Flat damage reduction |
| Movement | `mov` | int | 4 | 2–6 | BFS range radius in tiles |
| Range | `rng` | int | 1 | 1–3 | Manhattan distance for attack targeting |

`hp` is a mutable field (current health); all other stats are read-only after creation. `max_hp` is the constant ceiling.

2. **Faction**: Each unit belongs to exactly one faction — `PLAYER` or `ENEMY`. Defined as a standalone `enum` in `Faction.Type` (separate file `src/core/faction.gd`, not nested in Unit). Faction determines:
   - Visual color: Player = `#3B82F6` (blue), Enemy = `#EF4444` (red)
   - Turn eligibility: only units of the active faction may act
   - Targetability: a unit may only target units of the opposing faction

3. **Unit Identity**: Each unit receives an auto-generated `unit_id: String` on instantiation (`"unit_0"`, `"enemy_2"`, etc.). Used by the debug overlay and future save/load. Not displayed in normal gameplay.

4. **Unit Scene Structure**: Unit is a `Node2D`-root scene (`Unit.tscn`) with two children:
   - `ColorRect` (48×48px, centered within the 64×64 tile) — faction-colored flat rectangle
   - `Label` (offset `Vector2(0, -40)` above unit center) — HP display in `"HP: 8/10"` format

5. **Unit Data**: A `UnitStats` custom Resource (`.tres`) holds the archetype stat block. Unit reads its `.tres` on `_ready()`. This separates data from presentation — the same `soldier.tres` can be applied to multiple Unit instances.

6. **Grid Position**: Unit owns `grid_position: Vector2i` (row, col). World pixel placement is derived via Map's `tile_center(grid_position)`. Unit does NOT compute pixel positions internally.

7. **Action State**: Unit tracks `has_acted_this_turn: bool`. Set to `true` after the unit completes its move+attack action. Reset to `false` by the Turn System at the start of the next faction's turn via `reset_action_state()`.

8. **Death**: When `hp` is reduced to ≤ 0:
   - Unit emits `unit_died(unit)` signal.
   - Map (listener) calls `remove_unit(coord)` and `queue_free()`.
   - Turn System and Victory (listeners) process the death for turn flow and win-check.
   - Unit never calls `queue_free()` on itself.

9. **Visual State Mapping**:
   - Normal (idle, alive, has NOT acted): full faction color, full opacity
   - Acted (has acted this turn): desaturated — modulate to `Color.GRAY` at 50% alpha

### States and Transitions

| State | Meaning | Valid Transitions |
|-------|---------|-------------------|
| `IDLE` | Alive, not selected, may or may not have acted | → SELECTED (player clicks unit) |
| `SELECTED` | Currently the active selection for input | → MOVED (move confirmed), → ATTACK_TARGETING (attack chosen after move) |
| `MOVED` | Unit has moved; now choosing attack target or skip | → ACTED (attack confirmed or skip) |
| `ACTED` | Move+attack consumed; `has_acted = true` | → IDLE (Turn System resets on new faction turn) |
| `DEAD` | `hp ≤ 0`; removed from board | Terminal — unit is `queue_free()`'d |

State transitions are driven by the Input system (click → select, click → move/attack). The Unit stores the current state as `action_state: enum` and exposes precondition checks:
- `can_be_selected()` → `is_alive AND faction == active_faction AND NOT has_acted`
- `can_move()` → `action_state in [SELECTED]`
- `can_attack()` → `action_state in [SELECTED, MOVED] AND rng ≥ distance_to_target`

### Interactions with Other Systems

| Downstream System | What Unit Exposes | Data Direction |
|---|---|---|
| **Turn System** | `faction`, `has_acted_this_turn`, `reset_action_state()`, `unit_died` signal | Turn → Unit (reset); Unit → Turn (death signal) |
| **Movement** | `mov`, `grid_position`, `set_grid_position()` | Movement → Unit (position write) |
| **Attack** | `atk`, `def`, `rng`, `hp`, `take_damage(amount)`, `is_alive` | Attack → Unit (HP write) |
| **Victory** | `faction`, `is_alive`, `unit_died` signal | Unit → Victory (poll + signal) |
| **AI** | All stats, `grid_position`, `can_be_selected()` equivalent | AI → Unit (via Movement/Attack proxies) |
| **UI / Input** | `hp`/`max_hp`, `faction`, `grid_position`, `has_acted_this_turn`, `action_state` | Unit → UI (read-only) |

## Formulas

### F1: take_damage

`hp = clamp(hp - amount, 0, max_hp)`

| Variable | Symbol | Type | Range | Description |
|----------|--------|------|-------|-------------|
| Current HP | hp | int | [0, max_hp] | Mutable current health |
| Damage amount | amount | int | [1, ∞) | Raw damage after DEF reduction (computed by Attack) |
| Max HP | max_hp | int | [5, 20] | Constant ceiling |

**Output Range**: hp ∈ [0, max_hp]. **Example**: a unit with hp=8, max_hp=10 takes `take_damage(5)` → hp becomes 3. `take_damage(12)` → hp becomes 0, `unit_died` emitted.

### F2: is_alive / is_dead

`is_alive = (hp > 0)` / `is_dead = (hp ≤ 0)`

| Variable | Type | Range | Description |
|----------|------|-------|-------------|
| hp | int | [0, max_hp] | Current health |

Boolean check consumed by Turn System, Movement (cannot move dead units), Victory (faction-elimination), and UI/HUD.

### F3: clamp_hp

`hp = clamp(hp, 0, max_hp)`

Enforced after every HP modification — damage and healing. No out-of-range HP is ever visible.

### F4: stat validation (`.tres` load-time)

For each stat `S` in `{max_hp: [5,20], atk: [3,8], def: [0,5], mov: [2,6], rng: [1,3]}`: assert `S` is within range on `.tres` load. Out-of-range data is a hard fail — bad data is a bug, not silently corrected.

### F5: heal (reserved interface, MVP unused)

`hp = clamp(hp + amount, 0, max_hp)`

Declared but not wired at MVP. Prevents future healing systems from needing to edit Unit internals.

> **What belongs elsewhere**: `damage = max(ATK - DEF, 1)` is owned by the Attack GDD (Module 5). Distance calculations (Manhattan) belong to Movement. Faction-elimination counting belongs to Victory.

## Edge Cases

- **If `take_damage(amount)` called on an already-dead unit**: returns immediately, no signal emitted. Guarded by `if not is_alive: return` at entry.

- **If `amount ≤ 0` passed to `take_damage`**: asserts `amount > 0`. Negative damage bypasses the unwired `heal()` interface — not allowed.

- **If exact kill (`amount == hp`)**: hp becomes 0, `is_alive` → false, `unit_died` emitted once. No special case needed — `clamp` naturally produces 0.

- **If `.tres` stat outside declared range**: `assert(false)` on `_ready()` with message naming the file, stat, value, and allowed range. Unit never enters the scene tree.

- **If `.tres` file missing or corrupt**: `ResourceLoader` returns null. Unit logs error and `queue_free()` before entering scene tree.

- **If player clicks a unit in SELECTED or ACTED state**: `can_be_selected()` additionally checks `action_state == IDLE`. Units not in IDLE reject selection.

- **If player tries to target same-faction unit for attack**: `can_attack()` includes `target.faction != self.faction`. Same-faction targeting is rejected.

- **If Turn System calls `reset_action_state()` on a unit still in SELECTED/MOVED state**: state is forced to IDLE regardless of current state. Turn transition overrides any in-progress action.

- **If external code directly sets `action_state` or read-only stats**: assert on write attempt. Only `hp`, `grid_position`, `has_acted_this_turn`, and `action_state` (via defined flows) are mutable.

- **If `max_hp` is somehow 0**: stat validation rejects on load (floor is 5). Impossible in normal operation.

- **If `unit_id` collides**: auto-generation uses a monotonic counter, not random. Two units instantiated in the same frame still get unique IDs.

- **If two units placed on same tile**: Map's `place_unit()` rejects with occupancy check — Unit trusts Map, does not self-validate peers.

- **If `grid_position` set outside map bounds**: Map rejects. Unit never self-positions or self-validates against map bounds.

- **If faction is changed at runtime**: No setter exists. Faction is init-only. Assert on write attempt.

## Dependencies

### Upstream Dependencies

| System | Type | Interface Consumed | Notes |
|--------|------|--------------------|-------|
| **Map / Coordinates** | Hard | `grid_to_world()`, `tile_center()`, `place_unit()`, `remove_unit()`, `is_walkable()` | Unit cannot exist on the board without Map |

### Downstream Dependencies (systems that depend on Unit)

| System | Type | Interface Exposed | Notes |
|--------|------|-------------------|-------|
| **Turn System** | Hard | `faction`, `has_acted_this_turn`, `reset_action_state()`, `is_alive`, `unit_died` signal | Iterates units by faction, resets action state |
| **Movement** | Hard | `mov`, `grid_position`, `set_grid_position()`, `is_alive` | BFS range radius, position write |
| **Attack** | Hard | `atk`, `def`, `rng`, `hp`, `take_damage()`, `is_alive`, `faction` | Damage computation, target validation |
| **Victory** | Hard | `faction`, `is_alive`, `unit_died` signal | Faction-elimination polling |
| **AI** | Hard | All stats, `grid_position`, `faction`, `is_alive`, `has_acted_this_turn` | AI reads unit state to decide actions |
| **UI / Input** | Hard | `hp`/`max_hp`, `faction`, `grid_position`, `action_state`, `has_acted_this_turn`, `unit_id` | Rendering, HP label, selection, debug overlay |

All six downstream dependencies are **hard** — no downstream system functions without Unit.

### External Dependencies

| Dependency | Type | Notes |
|------------|------|-------|
| `UnitStats` Resource (.tres) | Data | Per-archetype stat blocks in `assets/data/units/`. Pillar 1 compliance. |
| `Unit.tscn` | Scene | Node2D-root scene template. Visual structure decoupled from stat data. |
| `Faction.Type` enum | Code | Standalone file `src/core/faction.gd`. Not nested in Unit — enables Tier 2 extraction. |

## Tuning Knobs

| Knob | Location | Safe Range | What Happens If Too Low | What Happens If Too High | Notes |
|------|----------|------------|------------------------|------------------------|-------|
| `max_hp` | UnitStats.tres | [5, 20] | Units die in 1 hit from any attacker — no tactical depth | Units become bullet sponges, matches drag | Default 10 gives 2-3 hit survival vs ATK 5 |
| `atk` | UnitStats.tres | [3, 8] | Below 3: units with DEF 2 take 1 damage minimum — combat feels futile | Above 8: one-shots become common against HP 10 units | Default 5 creates 2-3 hit kill vs HP 10, DEF 2 |
| `def` | UnitStats.tres | [0, 5] | 0 DEF: ATK = raw damage, no mitigation layer | 5 DEF: only ATK ≥ 7 does more than 2 damage — defense dominates | Default 2 absorbs 40% of default ATK 5 |
| `mov` | UnitStats.tres | [2, 6] | 2 tiles: unit can barely reposition, map feels claustrophobic | 6 tiles: unit crosses default 16×12 map in 2 turns, range loses meaning | Default 4 is the standard SRPG move value |
| `rng` | UnitStats.tres | [1, 3] | 1: melee-only — unit must be adjacent to attack | 3: half the board is reachable from center — positioning trivialized | Default 1 (melee) for MVP; ranged archetypes at rng 2–3 are Tier 2 |

**Knob interactions**:
- `atk` vs `def`: damage = `max(atk − def, 1)`. Raising `def` globally makes `atk` less meaningful. Raising `atk` globally makes `def` irrelevant. These two define the lethality curve together.
- `mov` vs `rng`: threat radius = `mov + rng`. A unit with MOV 6 + RNG 3 projects threat 9 tiles from its starting position — nearly the full map width.
- `max_hp` vs `atk − def`: hits-to-kill = `ceil(max_hp / max(atk − def, 1))`. Adjusting HP without checking this ratio can create immortal units or glass cannons.

## Visual/Audio Requirements

Per Programmer Art Functional anchor. No audio.

- **Unit body**: 48×48px `ColorRect`, centered within the 64×64 tile. Faction-colored flat rectangle — Player `#3B82F6` (blue), Enemy `#EF4444` (red).
- **HP label**: `Label` node offset `Vector2(0, -40)` above unit center. Format: `"HP: 8/10"`. Font: Godot default (no custom font at MVP).
- **Action state visual**: Acted units → modulate to `Color.GRAY` at 50% alpha.
- **Death**: No corpse, no death animation. Unit is `queue_free()`'d after `unit_died` signal.
- **Selection highlight**: Deferred to UI / Input GDD (highlight overlay belongs to that system).

> 📌 **Asset Spec** — Visual requirements defined. Run `/asset-spec system:unit` after art bible approval to produce per-unit visual descriptions and generation prompts.

## UI Requirements

This system has no UI of its own. Unit selection, HP display overlay, and action menus are owned by the UI / Input GDD. The HP Label child node is a Unit-owned rendering element, not a UI screen.

## Acceptance Criteria

### Core Rules

**AC-C1 — Stats data-driven** (Logic)
GIVEN a UnitStats.tres with max_hp=10, atk=5, def=2, mov=4, rng=1, WHEN a Unit loads it on `_ready()`, THEN hp==max_hp==10 and all five stats match `.tres` exactly. No hardcoded defaults survive.

**AC-C2 — Faction color** (Visual)
GIVEN a PLAYER Unit, THEN ColorRect.modulate is blue (`#3B82F6`). GIVEN an ENEMY Unit, THEN red (`#EF4444`).

**AC-C3 — unit_id monotonic** (Logic)
GIVEN zero existing units, WHEN three Units are instantiated, THEN unit_ids are `"unit_0"`, `"unit_1"`, `"unit_2"` — monotonic, no collisions.

**AC-C4 — Scene structure** (Visual)
GIVEN Unit.tscn opened in editor, WHEN inspected, THEN root is Node2D with exactly two children: a ColorRect (48×48) and a Label offset above center.

**AC-C5 — .tres instance separation** (Logic)
GIVEN two Units both loading the same soldier.tres, WHEN Unit A takes `take_damage(4)` reducing hp 10→6, THEN Unit B's hp remains 10. Each Unit owns mutable hp independently.

**AC-C6 — grid_position ownership** (Logic)
GIVEN a Unit placed at grid (2,3), WHEN `unit.grid_position` is read, THEN `Vector2i(2,3)`. Unit contains zero pixel-math — world position derives solely via Map.

**AC-C7 — has_acted lifecycle** (Logic)
GIVEN a fresh Unit, THEN `has_acted_this_turn == false`. After move+attack completes, THEN `true`. After Turn System calls `reset_action_state()`, THEN `false`.

**AC-C8 — Death chain** (Integration)
GIVEN a Unit with hp=1, WHEN `take_damage(3)`, THEN hp→0, `unit_died` emits exactly once, Map removes occupancy, `queue_free()` follows. Signal fires before node freed.

**AC-C9 — Visual desaturation** (Visual)
GIVEN a Unit that has NOT acted, THEN full faction color + full opacity. GIVEN `has_acted_this_turn == true`, THEN desaturated (`Color.GRAY`, 50% alpha).

### State Machine

**AC-S1 — can_be_selected complete precondition** (Logic)
GIVEN a Unit with `is_alive AND faction==active_faction AND NOT has_acted AND action_state==IDLE`, WHEN `can_be_selected()`, THEN `true`. Any missing condition → `false`.

**AC-S2 — can_move / can_attack** (Logic)
GIVEN a Unit in SELECTED, THEN `can_move()` → `true`. GIVEN SELECTED or MOVED + enemy target within `rng`, THEN `can_attack()` → `true`. GIVEN same-faction target, THEN `false` regardless of state.

**AC-S3 — reset_action_state override** (Logic)
GIVEN a Unit in SELECTED or MOVED, WHEN `reset_action_state()`, THEN state forced to IDLE.

### Formulas

**AC-F1 — take_damage clamp + dead guard** (Logic)
GIVEN hp=8 max_hp=10, WHEN `take_damage(5)` → hp=3. WHEN `take_damage(12)` on hp=3 → hp=0 + `unit_died`. GIVEN hp=0, WHEN `take_damage(any)`, THEN returns immediately, no signal.

**AC-F2 — is_alive / is_dead** (Logic)
GIVEN hp=5, THEN `is_alive()==true`, `is_dead()==false`. GIVEN hp=0, THEN inverse. hp=1 is alive; hp=0 is dead. No ambiguity.

**AC-F3 — clamp_hp enforcement** (Logic)
GIVEN hp=8 max_hp=10, WHEN `heal(5)`, THEN hp=10 (capped, not 13). After any HP modification, hp ∈ [0, max_hp].

**AC-F4 — .tres validation** (Logic)
GIVEN UnitStats.tres with atk=12 (outside [3,8]), WHEN loaded, THEN assert fails with message naming file/stat/value/range. GIVEN missing/corrupt .tres, THEN error logged + `queue_free()`.

**AC-F5 — heal() reserved** (Logic)
GIVEN the Unit class, WHEN inspected, THEN `heal(amount: int)` method exists with `hp = clamp(hp+amount, 0, max_hp)` but is not wired to any MVP caller.

### Edge Case Guards

**AC-E1 — Read-only stat mutation guard** (Logic)
GIVEN a live Unit, WHEN external code attempts to set atk/def/mov/rng/max_hp/faction directly, THEN assert fails. Only hp, grid_position, has_acted, and action_state are writable.

**AC-E2 — Negative/zero damage rejected** (Logic)
GIVEN `take_damage(0)` or `take_damage(-3)`, THEN assert fails: "amount must be > 0".

## Open Questions

- **OQ1 — UnitStats.tres field naming**: Should the `.tres` use `max_hp` (constant) as the exported field name, with `hp` initialized from it on `_ready()`? → Resolve during implementation.
- **OQ2 — Faction extraction timing**: Faction enum is embedded in Unit at MVP. Tier 2 extraction to a standalone Faction system requires moving `src/core/faction.gd` — a zero-logic-change move. Should extraction happen before any Tier 2 GDDs are written? → Defer to Tier 2 planning.
- **OQ3 — heal() wiring**: The `heal(amount)` interface is reserved but unwired at MVP. Which Tier 2/3 system first uses it? → Defer to future GDDs (likely Class Triangle or XP/Level-up).
- **OQ4 — unit_id counter persistence**: Currently per-session monotonic counter. If save/load (Tier 3) needs persistent IDs, the counter must become save-aware. → Defer to Save/Load GDD.
