# SRPG_MINI — 主架构文档

## Document Status
- **Version**: 1
- **Last Updated**: 2026-05-02
- **Engine**: Godot 4.6.2-stable
- **GDDs Covered**: map, unit, turn, movement, attack, victory, ai, ui (all 8 MVP GDDs)
- **ADRs Referenced**: ADR-0001~0010 (all 10 ADRs covering Foundation, Core, Feature, and Presentation layers)
- **Technical Director Sign-Off**: 2026-05-02 — PASS (10 ADRs reviewed; 63 / 65 technical requirements covered, 97%; no blocking architecture issues)
- **Lead Programmer Feasibility**: SKIPPED — Lean mode

## Engine Knowledge Gap Summary

| Risk | Domains | Impacted Systems |
|------|---------|-----------------|
| **HIGH** | GDScript `@abstract` (4.5+), UI dual-focus (4.6), Jolt default physics (4.6), D3D12 default (4.6) | AI (AIController), UI/Input |
| **MEDIUM** | `duplicate_deep()` (4.5), dedicated Navigation2D server (4.5), SDL3 gamepad (4.5) | (none at MVP) |
| **LOW** | TileMapLayer, Node2D, Control, ResourceLoader, Signal — stable since 4.0–4.3 | Map, Unit, Turn, Movement, Attack, Victory |

**Key mitigations**:
- `@abstract` is editor-level only in Godot 4.5+; release builds need `assert(false)` fallback in base class (already specified in AI GDD)
- Dual-focus (4.6) means `grab_focus()` affects keyboard/gamepad only, not mouse — MVP is mouse-only, so this has zero impact unless keyboard navigation is added later
- Jolt default (4.6) irrelevant — MVP uses 2D only (Godot Physics 2D unchanged)
- D3D12 default (4.6) irrelevant at MVP — Forward+ renderer, no custom shaders, flat-color rectangles only

---

## System Layer Map

```
┌─────────────────────────────────────────────────────────────┐
│  PRESENTATION LAYER                                         │
│  ┌──────────┐                                               │
│  │ UI/Input │  InputHandler + 3×HighlightLayer + HUD        │
│  │          │  CanvasLayer + Result Overlay + Debug Overlay  │
│  └────┬─────┘                                               │
│       │ reads all upstream, owns NO game logic               │
├───────┼─────────────────────────────────────────────────────┤
│  FEATURE LAYER                                              │
│  ┌──────────┐  ┌──────────┐  ┌──────────┐  ┌────────────┐  │
│  │ Movement │  │  Attack  │  │ Victory  │  │ AI /        │  │
│  │Resolver  │  │Resolver  │  │ Checker  │  │ AIController│  │
│  │ +Result  │  │+RangeRes │  │          │  │ +NullAI     │  │
│  └────┬─────┘  └────┬─────┘  └────┬─────┘  └──────┬─────┘  │
│       │              │             │               │        │
│   RefCounted     RefCounted    RefCounted      RefCounted   │
│   纯函数         纯函数        纯函数          @abstract    │
├───────┼──────────────┼─────────────┼───────────────┼────────┤
│  CORE LAYER                                                  │
│  ┌──────────┐  ┌──────────────┐                              │
│  │   Unit   │  │ TurnManager  │                              │
│  │ Node2D   │  │ RefCounted   │                              │
│  └────┬─────┘  └──────┬───────┘                              │
│       │                │                                      │
│   owns: stats,     owns: turn_number, active_faction,        │
│   action_state,    current_state, signals,                    │
│   faction, hp      end_current_faction_turn()                 │
├───────┼────────────────┼────────────────────────────────────┤
│  FOUNDATION LAYER                                            │
│  ┌──────────┐                                                │
│  │   Map    │  CSV state + optional visual background +       │
│  │          │  TileMapLayer fallback + GridSpace + occupancy  │
│  └──────────┘                                                │
│   Node2D (scene root)                                        │
│   owns: grid topology, walkability, occupancy,               │
│         grid↔world transform                                 │
├─────────────────────────────────────────────────────────────┤
│  PLATFORM LAYER                                              │
│  Godot 4.6.2: TileMapLayer, Node2D, Control, CanvasLayer,    │
│  Input, ResourceLoader, RefCounted, Signal                    │
└─────────────────────────────────────────────────────────────┘
```

---

## Module Ownership

### Foundation Layer — Map

| Aspect | Detail |
|--------|--------|
| **Owns** | `_tile_states: Dictionary[Vector2i, TileState]` (walkable/blocked/obstacle/rough), `_occupancy: Dictionary[Vector2i, Unit]`, `GridSpace` instance (world↔grid transform), optional per-map `Sprite2D` visual background, `TileMapLayer` fallback node |
| **Exposes** | `world_to_grid(Vector2) → Vector2i`, `grid_to_world(Vector2i) → Vector2`, `tile_center(Vector2i) → Vector2`, `is_coord_in_bounds(Vector2i) → bool`, `is_walkable(Vector2i) → bool`, `get_neighbors(Vector2i) → Array[Vector2i]`, `get_unit_at(Vector2i) → Unit`, `place_unit(Unit, Vector2i) → bool`, `remove_unit(Vector2i) → bool`, `move_unit(Unit, Vector2i, Vector2i) → bool` |
| **Consumes** | (nothing — Foundation layer, no upstream deps) |
| **Engine APIs** | `Sprite2D`, `Texture2D`, `TileMapLayer.set_cell()` fallback (4.3+, LOW risk), `Node2D`, `RefCounted`, `ResourceLoader` (CSV and visual loading) |

### Core Layer — Unit

| Aspect | Detail |
|--------|--------|
| **Owns** | `hp: int`, `max_hp: int`, `atk: int`, `def: int`, `mov: int`, `rng: int`, `faction: Faction.Type`, `grid_position: Vector2i`, `action_state: UnitState` (IDLE/SELECTED/MOVED/ACTED/DEAD), `has_acted_this_turn: bool`, `unit_id: String`, `ColorRect` state container + `TextureRect` static token + `Label` child nodes |
| **Exposes** | All owned fields (read-only except `hp`, `grid_position`, `action_state`, `has_acted`), `take_damage(int)`, `heal(int)`, `reset_action_state()`, `can_be_selected() → bool`, `can_move() → bool`, `can_attack() → bool`, `is_alive → bool`, `is_dead → bool`, signal `unit_died(unit)` |
| **Consumes** | Map: `tile_center()`, `place_unit()`, `remove_unit()` |
| **Engine APIs** | `Node2D` (scene root), `ColorRect`, `TextureRect`, `Texture2D`, `Label`, `Resource` (.tres loading), `RefCounted` (UnitStats) — all LOW risk |

### Core Layer — Turn System

| Aspect | Detail |
|--------|--------|
| **Owns** | `active_faction: Faction.Type`, `turn_number: int`, `turn_cap: int`, `current_state: TurnState` (MATCH_NOT_STARTED/FACTION_PHASE_ACTIVE/FACTION_PHASE_ENDING/MATCH_ENDED), `_all_units: Array[Unit]`, `TurnConfig` reference, `VictoryChecker` reference, `AIController` reference, `AIActionExecutor` reference |
| **Exposes** | Signals: `match_started()`, `turn_started(int)`, `faction_activated(Faction.Type)`, `faction_phase_ended(Faction.Type)`, `match_ended(String, Faction.Type)`. Methods: `start_match(Array[Unit])`, `end_current_faction_turn()`. Read-only: `active_faction`, `turn_number`, `turn_cap`, `current_state` |
| **Consumes** | Unit: `faction`, `has_acted_this_turn`, `is_alive`, `reset_action_state()`, `unit_died` signal. Map: `move_unit()`. AttackResolver: `execute_attack()`. VictoryChecker: `determine_winner(units, turn_number, turn_cap) → {winner, reason}`. AIController: `take_turn(units, world_state) → ActionList` |
| **Engine APIs** | `RefCounted` — no scene tree dependency. **No Autoload.** DI-managed. LOW risk |

### Feature Layer — Movement

| Aspect | Detail |
|--------|--------|
| **Owns** | `MovementResolver` (BFS algorithm), `MovementResult` (immutable result: tiles, parent map, distance map) |
| **Exposes** | `MovementResolver.compute_reachable(unit, map) → MovementResult`. Result API: `get_reachable_tiles()`, `get_path_to(Vector2i)`, `get_distance_to(Vector2i)`, `get_start_tile()` |
| **Consumes** | Map: `get_neighbors()`, `is_walkable()`. Unit: `mov`, `grid_position`, `is_alive` |
| **Engine APIs** | `RefCounted` only — pure math over Map interface. Zero engine dependencies. LOW risk |

### Feature Layer — Attack

| Aspect | Detail |
|--------|--------|
| **Owns** | `AttackResolver` (damage + execution), `AttackRangeResolver` (target filtering + sorting), `AttackResult` (immutable: damage, killed, attacker, target) |
| **Exposes** | `AttackResolver.execute_attack(attacker, target) → AttackResult`, `AttackResolver.resolve_damage(atk, def) → int` (static), `AttackRangeResolver.get_valid_targets(unit, map) → Array[Unit]`. Signal: `damage_dealt(attacker, target, damage)` |
| **Consumes** | Map: `get_unit_at()`. Unit: `atk`, `def`, `rng`, `hp`, `faction`, `is_alive`, `take_damage()`, `grid_position` |
| **Engine APIs** | `RefCounted` only — pure math. Manhattan distance formula owned by Movement GDD, consumed here. LOW risk |

### Feature Layer — Victory

| Aspect | Detail |
|--------|--------|
| **Owns** | `VictoryChecker` (pure function, no state) |
| **Exposes** | `determine_winner(units: Array[Unit], turn_number: int, turn_cap: int) → Dictionary{winner: Faction.Type, reason: String}` |
| **Consumes** | Unit: `faction`, `is_alive` (read-only) |
| **Engine APIs** | `RefCounted` only — pure logic. LOW risk |

### Feature Layer — AI / AIController

| Aspect | Detail |
|--------|--------|
| **Owns** | `AIController` (@abstract base, RefCounted), `NullAI` (MVP implementation), `BasicAI` (Tier 2 planner), `ActionPlan`, `ActionList`, `WorldState`, `ActionType` enum |
| **Exposes** | `AIController.take_turn(units: Array[Unit], world_state: WorldState) → ActionList` |
| **Consumes** | Turn System (caller — invokes `take_turn()`). Map (via WorldState): `get_neighbors()`, `is_walkable()`, `get_unit_at()`. Unit: all attributes (read-only). Movement: `MovementResolver.compute_reachable()` (Tier 2). Attack: `AttackRangeResolver.get_valid_targets()` (Tier 2) |
| **Engine APIs** | `RefCounted`, `@abstract` decorator (Godot 4.5+, ⚠️ HIGH risk — editor-only, needs `assert(false)` fallback). `Dictionary.duplicate()` for WorldState.clone() |

### Presentation Layer — UI / Input

| Aspect | Detail |
|--------|--------|
| **Owns** | `InputHandler` (RefCounted), `HighlightLayer` ×3 (move/path/attack, Node2D with `_draw()`), HUD CanvasLayer (turn indicator, faction indicator, End Turn button), Result Overlay CanvasLayer (WIN/LOSE/DRAW), Debug Overlay, `InputContext` enum (BOARD_IDLE/UNIT_SELECTED/ATTACK_TARGETING) |
| **Exposes** | (terminal node — exposes nothing downstream; all game logic functions without UI) |
| **Consumes** | **All 7 upstream systems** — Map: `world_to_grid()`, `grid_to_world()`, `is_coord_in_bounds()`, `get_unit_at()`, `move_unit()`. Unit: all attributes + `can_be_selected/move/attack()`. Turn: `active_faction`, `turn_number`, `turn_cap`, `current_state`, all signals, `end_current_faction_turn()`. Movement: `compute_reachable()`, MovementResult API. Attack: `get_valid_targets()`, `resolve_damage()`, `execute_attack()`. Victory: `match_ended` signal (via Turn). AI: `faction_activated(ENEMY)` signal (hotseat mode) |
| **Engine APIs** | `Node2D._draw()` + `draw_rect()`, `Control` / `CanvasLayer`, `Label`, `Button` + `StyleBoxFlat`, `Input.get_mouse_position()`, `InputMap`, `InputEventMouseButton`, `Input.CURSOR_*` — ⚠️ MEDIUM risk (dual-focus in 4.6; MVP mouse-only makes this low-impact) |

---

## Data Flow

### Frame Update Path (idle / hover / click)

```
Input.get_mouse_position()
  → GridSpace.world_to_grid(pos)
    → InputContext dispatch:
        BOARD_IDLE:        Unit.can_be_selected() → select
        UNIT_SELECTED:     MovementResult.get_path_to(tile) → path preview
                           AttackRangeResolver.get_valid_targets() → target highlight
        ATTACK_TARGETING:  AttackResolver.resolve_damage(atk, def) → damage preview
```

### Move + Attack Commit Path

```
Click reachable tile:
  InputHandler → Map.move_unit(unit, from, to)          [atomic: occupancy + position]
               → unit.action_state = MOVED
               → AttackRangeResolver.get_valid_targets()

Click attack target:
  InputHandler → AttackResolver.execute_attack(attacker, target)
               → target.take_damage(damage)
                 → if hp ≤ 0: unit_died signal
                   → Map.remove_unit(coord) + queue_free()
                   → TurnManager re-evaluates auto-advance + faction elimination
               → attacker.has_acted = true
               → attacker.action_state = ACTED
               → damage_dealt signal (reserved for Tier 2 counter-attack)
```

### Turn State Machine Flow

```
start_match(units)
  → match_started signal
  → turn_started(1) signal → HUD updates
  → faction_activated(PLAYER) signal → Input enabled for PLAYER units

[PLAYER phase] → player moves + attacks units
  → after each action: TurnManager checks auto-advance condition
  → after each unit_died: TurnManager checks faction elimination

auto-advance OR end_turn_requested:
  → FACTION_PHASE_ENDING
    → faction_phase_ended signal → UI clears highlights
    → determines next_faction
    → resets incoming faction's action_state
    → if ending_faction == ENEMY: turn_number += 1
    → VictoryChecker.determine_winner(units, turn_number, turn_cap)
      → if winner != NONE: → MATCH_ENDED, match_ended(reason, winner) signal
      → else: → FACTION_PHASE_ACTIVE, faction_activated(next) signal
        → if next_faction == ENEMY and AI returns non-empty ActionList:
          → AIActionExecutor applies move/attack/wait plans through Map + AttackResolver
          → NullAI empty ActionList leaves ENEMY phase available for hotseat control
```

### Save/Load Path

```
(MVP: no save/load. Reserved for Tier 3.)

Serialization boundary design (pre-registered):
  - Map state: tile_states (immutable after load — don't need to save), occupancy dict
  - Unit state: {unit_id, hp, max_hp, atk, def, mov, rng, faction, grid_position, action_state, has_acted}
  - Turn state: {active_faction, turn_number, turn_cap, current_state}
  - Victory state: (derived — not persisted separately)
  - Save format: JSON or .tres-based Resource
  - Each module exposes to_dict() / from_dict() on its owned state
```

### Runtime AI Mode Selection

`src/game.gd` remains the composition root for AI selection. It reads `srpg_mini/enemy_ai_mode` from `project.godot` and accepts command-line demo overrides:

- `hotseat` (default): instantiate `NullAI`; ENEMY phase stays manually controllable.
- `basic`: instantiate `BasicAI`; ENEMY phase executes non-empty ActionLists through `TurnManager`.
- CLI examples: `--enemy-ai=basic` or `--enemy-ai hotseat`.

### Initialization Order

```
1. Game scene (_ready):
   a. Create Map (load CSV → load optional visual background or set TileMapLayer fallback cells → build occupancy dict)
   b. Create GridSpace (RefCounted, DI into all consumers)
   c. Instantiate Units (from .tres stats → place on Map via place_unit)
   d. Create TurnManager (RefCounted, inject: units, TurnConfig, VictoryChecker, AIController)
   e. Create MovementResolver, AttackResolver, AttackRangeResolver (RefCounted, DI)
   f. Create InputHandler (RefCounted, inject all resolvers + TurnManager + Map)
   g. Create HighlightLayers (3×Node2D, add to Board as children)
   h. Create HUD CanvasLayer + Result Overlay CanvasLayer
   i. Connect all signals (TurnManager → UI, Unit → TurnManager, Unit → Map)
   j. TurnManager.start_match(all_units) → game begins
```

---

## API Boundaries

### Foundation: Map (GridSpace)

```gdscript
# GridSpace — coordinate transform authority
class_name GridSpace extends RefCounted

func world_to_grid(world_pos: Vector2) -> Vector2i  # pixel → (row, col)
func grid_to_world(grid_pos: Vector2i) -> Vector2    # (row, col) → tile top-left pixel
func tile_center(grid_pos: Vector2i) -> Vector2       # (row, col) → tile center pixel

# Map — grid topology + occupancy
class_name Map extends Node2D

func is_coord_in_bounds(coord: Vector2i) -> bool
func is_walkable(coord: Vector2i) -> bool            # tile == WALKABLE AND coord not occupied
func get_neighbors(coord: Vector2i) -> Array[Vector2i]  # 4-directional, in-bounds only
func get_unit_at(coord: Vector2i) -> Unit              # null if empty
func place_unit(unit: Unit, coord: Vector2i) -> bool
func remove_unit(coord: Vector2i) -> bool
func move_unit(unit: Unit, from: Vector2i, to: Vector2i) -> bool  # atomic!
```

### Core: Unit

```gdscript
# UnitStats — data-driven prototype (.tres)
class_name UnitStats extends Resource
@export var max_hp: int = 10   # [5, 20]
@export var atk: int = 5       # [3, 8]
@export var def: int = 2       # [0, 5]
@export var mov: int = 4       # [2, 6]
@export var rng: int = 1       # [1, 3]

# Unit — scene entity (Node2D)
class_name Unit extends Node2D

# Read-only (set at init)
var unit_id: String
var max_hp: int
var atk: int
var def: int
var mov: int
var rng: int
var faction: Faction.Type

# Mutable state
var hp: int
var grid_position: Vector2i
var action_state: UnitState   # IDLE | SELECTED | MOVED | ACTED | DEAD
var has_acted_this_turn: bool

# State queries
func is_alive() -> bool
func is_dead() -> bool
func can_be_selected() -> bool     # alive AND faction==active AND NOT has_acted AND state==IDLE
func can_move() -> bool            # state == SELECTED
func can_attack() -> bool          # state in [SELECTED, MOVED] AND rng ≥ distance

# Mutations
func take_damage(amount: int) -> void   # amount > 0; hp = clamp(hp-amount, 0, max_hp)
func heal(amount: int) -> void          # reserved, unused in MVP
func reset_action_state() -> void       # called by TurnManager

# Signal
signal unit_died(unit: Unit)
```

### Core: Turn System (TurnManager)

```gdscript
class_name TurnManager extends RefCounted

# State (read-only to consumers)
var current_state: TurnState    # MATCH_NOT_STARTED | FACTION_PHASE_ACTIVE | FACTION_PHASE_ENDING | MATCH_ENDED
var active_faction: Faction.Type
var turn_number: int
var turn_cap: int

# Lifecycle
func start_match(all_units: Array[Unit]) -> void   # assert: current_state == MATCH_NOT_STARTED
func end_current_faction_turn() -> void             # guarded: current_state == FACTION_PHASE_ACTIVE

# AI runtime execution
func _run_ai_phase_if_ready() -> void               # ENEMY only; empty ActionList preserves hotseat

# Signals
signal match_started()
signal turn_started(turn_number: int)
signal faction_activated(faction: Faction.Type)
signal faction_phase_ended(faction: Faction.Type)
signal match_ended(reason: String, winner: Faction.Type)
```

### Feature: Movement

```gdscript
class_name MovementResolver extends RefCounted
func compute_reachable(unit: Unit, map: Map) -> MovementResult

class_name MovementResult extends RefCounted
func get_reachable_tiles() -> Array[Vector2i]
func get_path_to(target: Vector2i) -> Array[Vector2i]   # [] if unreachable
func get_distance_to(target: Vector2i) -> int            # -1 if unreachable
func get_start_tile() -> Vector2i
```

### Feature: Attack

```gdscript
class_name AttackResolver extends RefCounted
func execute_attack(attacker: Unit, target: Unit) -> AttackResult
static func resolve_damage(atk: int, def: int) -> int   # max(atk-def, 1)
signal damage_dealt(attacker: Unit, target: Unit, damage: int)

class_name AttackRangeResolver extends RefCounted
func get_valid_targets(unit: Unit, map: Map) -> Array[Unit]  # sorted: distance ↑, then HP ↓

class_name AttackResult extends RefCounted
var damage: int
var killed: bool
var attacker: Unit
var target: Unit
```

### Feature: Victory

```gdscript
class_name VictoryChecker extends RefCounted
func determine_winner(units: Array[Unit], turn_number: int, turn_cap: int) -> Dictionary
# Returns: {winner: Faction.Type, reason: String}
# reason: "" (continue) | "elimination" | "turn_cap"
# winner: PLAYER | ENEMY | NONE (NONE only when reason="" or reason="turn_cap"+draw)
```

### Feature: AI

```gdscript
@abstract
class_name AIController extends RefCounted

@abstract
func take_turn(units: Array[Unit], world_state: WorldState) -> ActionList

class_name ActionPlan extends RefCounted
var unit: Unit
var type: ActionType       # MOVE_AND_ATTACK | MOVE_ONLY | ATTACK_ONLY | WAIT
var move_target: Vector2i
var attack_target: Unit

class_name ActionList extends RefCounted
func add(action: ActionPlan) -> void
func get_actions() -> Array[ActionPlan]
func is_empty() -> bool
func size() -> int

class_name WorldState extends RefCounted
var all_units: Array[Unit]
var map: Map
func clone() -> WorldState   # deep copies _occupancy_snapshot
```

---

## ADR Audit

### Existing ADRs

| ADR | Title | Status |
|-----|-------|--------|
| ADR-0001 | GridSpace — Coordinate Transform Boundary | Proposed (2026-04-30) |
| ADR-0002 | Dependency Injection Architecture | Proposed (2026-04-30) |
| ADR-0003 | Unit Public Interface Contract | Proposed (2026-04-30) |
| ADR-0004 | Turn System Architecture | Proposed (2026-04-30) |
| ADR-0005 | Map CSV Loading Format & Occupancy Tracking | Proposed (2026-04-30) |
| ADR-0006 | Movement System — BFS + MovementResult | Proposed (2026-04-30) |
| ADR-0007 | Attack System — Damage Formula + Range Check | Proposed (2026-04-30) |
| ADR-0008 | AI Controller Interface | Proposed (2026-04-30) |
| ADR-0009 | Victory System | Proposed (2026-04-30) |
| ADR-0010 | UI / Input Architecture | Proposed (2026-04-30) |

Full traceability matrix maintained at `docs/architecture/architecture-review-2026-04-30.md`.
TR registry at `docs/architecture/tr-registry.yaml` (65 entries, version 2).

### Technical Requirements Baseline

Extracted from 8 GDDs + cross-cutting concerns. See `docs/architecture/tr-registry.yaml` for the canonical list.

| Layer | System | TR Count | ✅ Covered | ⚠️ Partial | ❌ Gaps | Key ADRs |
|-------|--------|----------|-----------|-----------|---------|----------|
| Foundation | Map | 9 | 9 | 0 | 0 | ADR-0001, ADR-0005 |
| Core | Unit | 10 | 8 | 1 | 1 | ADR-0003 |
| Core | Turn | 10 | 10 | 0 | 0 | ADR-0004 |
| Feature | Movement | 6 | 6 | 0 | 0 | ADR-0006 |
| Feature | Attack | 7 | 7 | 0 | 0 | ADR-0007 |
| Feature | Victory | 5 | 5 | 0 | 0 | ADR-0009 (+ADR-0004) |
| Feature | AI | 7 | 7 | 0 | 0 | ADR-0008 |
| Presentation | UI | 8 | 8 | 0 | 0 | ADR-0010 (+ADR-0001, ADR-0002) |
| Cross-cutting | — | 3 | 3 | 0 | 0 | ADR-0001, ADR-0002 |
| **Total** | | **65** | **63 (97%)** | **1 (1.5%)** | **1 (1.5%)** | |

**Coverage**: 63 / 65 requirements covered by 10 ADRs. Only TR-unit-009 (unit_id generation) and TR-unit-010 (visual state mapping) remain — both minor implementation details.

---

## Required ADRs

### ✅ Must Have — Done (Foundation & Core)

1. **✅ ADR-0001: GridSpace — Coordinate Transform Boundary**
   Covers: Map TRs, cross-cutting forbidden patterns
   Status: Proposed (2026-04-30)

2. **✅ ADR-0002: Dependency Injection Architecture**
   Covers: Turn, Movement, Attack, Victory, AI, UI cross-cutting pattern
   Status: Proposed (2026-04-30)

3. **✅ ADR-0003: Unit Public Interface Contract**
   Covers: Unit TRs, 5 downstream consumer stability
   Status: Proposed (2026-04-30)

4. **✅ ADR-0004: Turn System Architecture**
   Covers: Turn TRs, Victory + AI injection contracts
   Status: Proposed (2026-04-30)

### 🔴 Must Have — Before Feature Implementation

5. **✅ ADR-0005: Map CSV Loading Format & Occupancy**
   Covers: map.md TRs (CSV format, validation, occupancy tracking, atomic move_unit)
   Status: Proposed (2026-04-30)

6. **✅ ADR-0006: Movement System (BFS + MovementResult)**
   Covers: movement.md TRs (BFS reachable tiles, Manhattan distance, path reconstruction)
   Status: Proposed (2026-04-30)

7. **✅ ADR-0007: Attack System (Damage Formula + Range)**
   Covers: attack.md TRs (deterministic damage, range check, AttackResult)
   Status: Proposed (2026-04-30)

8. **✅ ADR-0008: AI Controller Interface**
   Covers: ai.md TRs (@abstract AIController, ActionPlan/ActionList/WorldState)
   Status: Proposed (2026-04-30)

### 🟡 Should Have — Before System Implementation

9. **✅ ADR-0009: Victory System**
   Covers: victory.md TRs (7-row decision table, elimination priority, mutual annihilation fallback)
   Status: Proposed (2026-04-30)

10. **✅ ADR-0010: UI / Input Architecture**
    Covers: ui.md TRs (InputContext state machine, HighlightLayers, HUD, result overlay, color tokens)
    Status: Proposed (2026-04-30)

### 🟢 Can Defer

11. **Faction Enum Location** — Minor; already specified in ADR-0003
12. **Color Token Specification** — Covered in ADR-0010
13. **Manhattan Distance Ownership** — Resolved: ADR-0006 owns formula, ADR-0007 references it

---

## Architecture Principles

Derived from Game Concept pillars + GDD analysis:

1. **Dependency Injection, Never Service Location**
   All logic objects are `RefCounted`, created by the Game composition root, and passed via constructor/method injection. No Autoloads. No SignalBus. No `get_node("../../../SomeManager")`. Every dependency is explicit in the constructor signature.

2. **Pure Computation, No Hidden State**
   MovementResolver, AttackResolver, VictoryChecker, AIController are pure functions — same inputs produce same outputs. They hold no mutable state across calls. Only Map (occupancy) and Unit (hp, action_state) own mutable game state. TurnManager bridges pure computation and mutable state via its internal state machine.

3. **Read Interfaces, Write Through Owners**
   A module may read any field exposed on another module's public interface. It may only write through the owning module's mutation methods. Example: Attack reads `unit.def` directly; Attack calls `unit.take_damage()` to modify `hp`. Attack never writes `unit.hp = value` directly.

4. **Signal for Notification, Poll for State**
   Signals announce events (`unit_died`, `faction_activated`, `match_ended`). Consumers that need current state after connecting late poll the source's read-only properties. No signal carries state that can go stale before the consumer processes it — state lives in the owner's properties.

5. **Data-Driven Values, Fail-Fast on Bad Data**
   All game values (UnitStats, TurnConfig, Map CSV) live in external data files. Loading validates ranges and fails with explicit messages on invalid data. No silent fallback to hardcoded defaults. Bad data is a bug, not a runtime condition to recover from.

---

## Open Questions

- **OQ1 — CI grep gate for forbidden patterns**: When should the CI check for inline `* TILE_SIZE` outside GridSpace be added? → Deferred to CI pipeline setup ADR.
- **OQ2 — WorldState versioning for async AI**: MVP synchronous execution doesn't need it. Tier 2 async AI (`begin_thinking()` / `thinking_complete` signal) will need it. → Deferred to Tier 2.
- **OQ3 — Save/Load serialization format**: JSON or .tres-based? → Deferred to Tier 3 Save/Load ADR.
- **OQ4 — SignalBus for cross-cutting events at scale**: MVP's 8 systems with direct signal connections are manageable. At Tier 2+ (10+ systems), a SignalBus may reduce wiring complexity. → Deferred; revisit after BasicAI + Terrain + Class Triangle are added.
