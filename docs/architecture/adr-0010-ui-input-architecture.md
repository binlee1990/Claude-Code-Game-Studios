# ADR-0010: UI / Input Architecture

## Status
Accepted

## Date
2026-04-30

## Engine Compatibility

| Field | Value |
|-------|-------|
| **Engine** | Godot 4.6.2-stable |
| **Domain** | Presentation (input handling, highlight rendering, HUD, screen flow) |
| **Knowledge Risk** | MEDIUM — UI dual-focus system (4.6): mouse/touch focus separate from keyboard/gamepad. MVP mouse-only makes this low-impact. `_draw()` + `draw_rect()` stable since 4.0. |
| **References Consulted** | `docs/engine-reference/godot/VERSION.md`, `docs/engine-reference/godot/breaking-changes.md`, `docs/engine-reference/godot/current-best-practices.md`, `docs/engine-reference/godot/modules/input.md`, `docs/engine-reference/godot/modules/ui.md` |
| **Post-Cutoff APIs Used** | None (MVP mouse-only avoids dual-focus complexity) |
| **Verification Required** | Low — verify `_draw()` performance with ~115 rects at 32×32 map (expected <1ms) |

## ADR Dependencies

| Field | Value |
|-------|-------|
| **Depends On** | ADR-0001 (GridSpace — click→grid resolution), ADR-0002 (DI Architecture — InputHandler as RefCounted), ADR-0003 (Unit — reads all attributes for selection/display), ADR-0004 (Turn — reads state for HUD + input gating), ADR-0005 (Map — reads topology for rendering), ADR-0006 (Movement — consumes MovementResult for highlights), ADR-0007 (Attack — consumes target lists + damage preview), ADR-0008 (AI — hotseat mode via NullAI), ADR-0009 (Victory — consumes match_ended for result screen) |
| **Enables** | All UI epics — highlight rendering, HUD, input handling, result screen |
| **Blocks** | UI epic — no visible game without this |
| **Ordering Note** | Must be Accepted tenth (last). UI is the terminal layer — depends on all upstream ADRs but blocks none. |

## Context

### Problem Statement

UI / Input is the Presentation layer — the sole interface between the player and the game. It must receive all mouse input, resolve clicks to grid coordinates, manage an input context state machine (BOARD_IDLE → UNIT_SELECTED → ATTACK_TARGETING), render three highlight layers (move range, path preview, attack targets) using code-drawn rectangles, display HUD elements (turn counter, faction indicator, End Turn button), and present result screens (WIN/LOSE/DRAW). Without a codified UI ADR, the rendering strategy, input flow, color tokens, and z-ordering remain scattered across GDD visual sections rather than centralized in an architectural decision.

### Constraints

- All rendering is code-drawn (`_draw()` + `draw_rect()`) — no textures, no sprites
- MVP is mouse-only — no keyboard navigation, no gamepad (4.6 dual-focus irrelevant)
- HUD uses CanvasLayer anchored to screen space (decoupled from world camera)
- Result overlay blocks all click-through via `MOUSE_FILTER_STOP`
- InputHandler must be RefCounted (DI pattern), not a Node
- Highlight rendering uses 3 separate Node2D children of Board
- Debug coordinate overlay default ON (toggle via backtick key)
- No audio feedback — all incorrect clicks silently ignored

### Requirements

- InputHandler: RefCounted, receives events from Game._unhandled_input(), dispatches by InputContext
- InputContext state machine: BOARD_IDLE ⇄ UNIT_SELECTED ⇄ ATTACK_TARGETING → BOARD_IDLE
- 3×HighlightLayer (Node2D): move (z=1 cyan), path (z=2 bright cyan), attack (z=3 orange)
- HUD CanvasLayer (layer 0): turn indicator, faction indicator, End Turn button
- Result overlay CanvasLayer (layer 10): WIN/LOSE/DRAW + "Play Again" button
- Color tokens decoupled from faction colors
- Click→grid via GridSpace.world_to_grid(); out-of-bounds silently ignored

## Decision

**InputHandler is a RefCounted that receives all mouse events from Game._unhandled_input() and dispatches based on an InputContext state machine (BOARD_IDLE, UNIT_SELECTED, ATTACK_TARGETING). Three HighlightLayer Node2D children of Board render move range, path preview, and attack targets using `_draw()` + `draw_rect()`. HUD is a CanvasLayer (layer 0) reading TurnManager state. Result overlay is a CanvasLayer (layer 10) activated by `match_ended` signal. All visual elements are code-drawn with no textures, following Programmer Art Functional philosophy. Color tokens are decoupled: highlight colors ≠ faction colors.**

### InputHandler

```gdscript
# src/ui/input_handler.gd
class_name InputHandler extends RefCounted

enum InputContext { BOARD_IDLE, UNIT_SELECTED, ATTACK_TARGETING }

var _map: Map
var _grid_space: GridSpace
var _turn_manager: TurnManager
var _movement_resolver: MovementResolver
var _attack_resolver: AttackResolver
var _attack_range_resolver: AttackRangeResolver

var _context: InputContext = InputContext.BOARD_IDLE
var _selected_unit: Unit = null
var _current_movement_result: MovementResult = null

func initialize(
    map: Map,
    grid_space: GridSpace,
    turn_manager: TurnManager,
    movement_resolver: MovementResolver,
    attack_resolver: AttackResolver,
    attack_range_resolver: AttackRangeResolver,
) -> void:
    _map = map
    _grid_space = grid_space
    _turn_manager = turn_manager
    _movement_resolver = movement_resolver
    _attack_resolver = attack_resolver
    _attack_range_resolver = attack_range_resolver

func handle_event(event: InputEvent) -> void:
    # ── State gating ──
    if _turn_manager.current_state != TurnState.FACTION_PHASE_ACTIVE:
        return
    
    if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
        _handle_click(event.position)
    elif event is InputEventMouse:
        _handle_hover(event.position)
    elif event is InputEventKey and event.keycode == KEY_ESCAPE and event.pressed:
        _handle_cancel()

func _handle_click(screen_pos: Vector2) -> void:
    var grid_pos: Vector2i = _grid_space.world_to_grid(screen_pos)
    if not _map.is_coord_in_bounds(grid_pos):
        return
    
    match _context:
        InputContext.BOARD_IDLE:
            var unit: Unit = _map.get_unit_at(grid_pos)
            if unit != null and unit.can_be_selected() and unit.faction == _turn_manager.active_faction:
                _select_unit(unit)
        
        InputContext.UNIT_SELECTED:
            # Check direct attack first (SELECTED → ACTED shortcut)
            var targets: Array[Unit] = _attack_range_resolver.get_valid_targets(_selected_unit, _map)
            var clicked_enemy: Unit = _map.get_unit_at(grid_pos)
            if clicked_enemy != null and clicked_enemy in targets:
                _execute_direct_attack(clicked_enemy)
                return
            
            # Check move
            if _current_movement_result != null and _current_movement_result.get_distance_to(grid_pos) >= 0:
                _execute_move(grid_pos)
                return
            
            # Check switch selection
            var other_unit: Unit = _map.get_unit_at(grid_pos)
            if other_unit != null and other_unit.can_be_selected() and other_unit != _selected_unit:
                _deselect_unit()
                _select_unit(other_unit)
        
        InputContext.ATTACK_TARGETING:
            var target: Unit = _map.get_unit_at(grid_pos)
            var valid_targets: Array[Unit] = _attack_range_resolver.get_valid_targets(_selected_unit, _map)
            if target != null and target in valid_targets:
                _execute_attack(target)

func _handle_hover(screen_pos: Vector2) -> void:
    var grid_pos: Vector2i = _grid_space.world_to_grid(screen_pos)
    # UI reads grid_pos and updates highlight layers
    # Path preview: MovementResult.get_path_to(grid_pos)
    # Damage preview: AttackResolver.resolve_damage(atk, def)

func _handle_cancel() -> void:
    match _context:
        InputContext.UNIT_SELECTED:
            _deselect_unit()
        InputContext.ATTACK_TARGETING:
            _skip_attack()

func _select_unit(unit: Unit) -> void:
    _selected_unit = unit
    _selected_unit.action_state = UnitState.SELECTED
    _current_movement_result = _movement_resolver.compute_reachable(unit, _map)
    _context = InputContext.UNIT_SELECTED
    # UI: render move highlights + attack highlights

func _deselect_unit() -> void:
    if _selected_unit != null:
        _selected_unit.action_state = UnitState.IDLE
    _selected_unit = null
    _current_movement_result = null
    _context = InputContext.BOARD_IDLE
    # UI: clear all highlights

func _execute_move(to: Vector2i) -> void:
    var from := _selected_unit.grid_position
    if _map.move_unit(_selected_unit, from, to):
        _selected_unit.action_state = UnitState.MOVED
        _current_movement_result = null
        # UI: clear move highlights
        # Enter attack targeting
        var targets: Array[Unit] = _attack_range_resolver.get_valid_targets(_selected_unit, _map)
        if targets.is_empty():
            _skip_attack()
        else:
            _context = InputContext.ATTACK_TARGETING
            # UI: render attack highlights

func _execute_direct_attack(target: Unit) -> void:
    var result: AttackResult = _attack_resolver.execute_attack(_selected_unit, target)
    _selected_unit = null
    _current_movement_result = null
    _context = InputContext.BOARD_IDLE
    # UI: show damage number (600ms), clear all highlights

func _execute_attack(target: Unit) -> void:
    var result: AttackResult = _attack_resolver.execute_attack(_selected_unit, target)
    _selected_unit = null
    _context = InputContext.BOARD_IDLE
    # UI: show damage number (600ms), clear all highlights

func _skip_attack() -> void:
    _selected_unit.has_acted_this_turn = true
    _selected_unit.action_state = UnitState.ACTED
    _selected_unit = null
    _context = InputContext.BOARD_IDLE
    # UI: clear all highlights
```

### HighlightLayer

```gdscript
# src/ui/highlight_layer.gd
class_name HighlightLayer extends Node2D

var _tiles: Array[Vector2i] = []
var _color: Color
var _grid_space: GridSpace

func initialize(grid_space: GridSpace, color: Color) -> void:
    _grid_space = grid_space
    _color = color

func set_highlight(tiles: Array[Vector2i]) -> void:
    _tiles = tiles
    queue_redraw()

func _draw() -> void:
    var rect := Rect2(0, 0, GridSpace.TILE_SIZE, GridSpace.TILE_SIZE)
    for tile in _tiles:
        rect.position = _grid_space.grid_to_world(tile)
        draw_rect(rect, _color)
```

### Game._unhandled_input() Bridge

```gdscript
# In src/game/game.gd (Node2D composition root)
func _unhandled_input(event: InputEvent) -> void:
    _input_handler.handle_event(event)
```

### Scene Tree Structure

```
Game (Node2D)                           # Composition root
├── Map (Node2D)                        # TileMapLayer child
│   └── TileMapLayer (%TileMapLayer)
├── Board (Node2D)                      # Game world container
│   ├── MoveHighlightLayer (z=1)        # Cyan #0891B2
│   ├── PathHighlightLayer (z=2)        # Bright cyan #06B6D4
│   ├── AttackHighlightLayer (z=3)      # Orange #EA580C
│   └── Unit* (Node2D)                  # Units instantiated at runtime
├── HUD (CanvasLayer, layer 0)          # Screen-space
│   ├── TurnLabel
│   ├── FactionLabel
│   └── EndTurnButton
└── ResultOverlay (CanvasLayer, layer 10) # Full-screen overlay
    ├── Background (ColorRect, mouse_filter=STOP)
    ├── TitleLabel
    ├── ReasonLabel
    └── PlayAgainButton
```

### Color Tokens

| Token | Hex | Usage | Owner |
|-------|-----|-------|-------|
| `MOVE_HIGHLIGHT` | `#0891B2` | Reachable tile highlight | HighlightLayer (move) |
| `PATH_HIGHLIGHT` | `#06B6D4` | Path preview overlay | HighlightLayer (path) |
| `ATTACK_HIGHLIGHT` | `#EA580C` | Attack target highlight | HighlightLayer (attack) |
| `DAMAGE_NORMAL` | `#F59E0B` | Damage preview (non-lethal) | UI Label |
| `DAMAGE_LETHAL` | `#EF4444` | Damage preview (will kill) | UI Label |
| `FACTION_PLAYER` | `#3B82F6` | Unit body + faction indicator | Unit / HUD |
| `FACTION_ENEMY` | `#EF4444` | Unit body + faction indicator | Unit / HUD |
| `UNIT_ACTED` | `Color.GRAY` | Acted unit desaturation | Unit (modulate) |
| `VICTORY_TEXT` | `#10B981` | WIN screen title | ResultOverlay |
| `DEFEAT_TEXT` | `#EF4444` | LOSE screen title | ResultOverlay |
| `DRAW_TEXT` | `#9CA3AF` | DRAW screen title | ResultOverlay |

### Design Rationale

**Why InputHandler is RefCounted, not a Node**: Follows ADR-0002 — all logic objects are RefCounted. InputHandler owns the input context state machine (pure logic), but does not render anything. The bridge from Godot's `_unhandled_input()` (which requires a Node) to InputHandler is a single line in Game.gd. This keeps InputHandler testable without a scene tree — instantiate, inject mock Map/Turn/Resolvers, call `handle_event()` with synthetic events.

**Why input goes through `_unhandled_input()`, not `_input()`**: `_unhandled_input()` fires after Control nodes (HUD buttons) have consumed their events. This naturally implements the input priority chain: overlay buttons > HUD buttons > board clicks. No manual "is the cursor over a button?" check needed.

**Why 3 separate HighlightLayer nodes (not one with color switching)**: Each layer has a different z_index and independently calls `queue_redraw()`. Move highlight changes on unit selection/deselection. Path highlight changes on hover. Attack highlight changes on enter/exit attack targeting. Separate nodes mean each only redraws when its own data changes — no full refresh of all highlights when only the path changes.

**Why `_draw()` + `draw_rect()` over `Sprite2D` or `TextureRect`**: Programmer Art Functional — no textures, no assets. `draw_rect()` with solid color is the simplest possible rendering. At MVP scale (~115 rects max), GPU overhead is negligible. If performance profiling shows `_draw()` overhead (unlikely for <200 rects), this can be replaced with a single `Polygon2D` batch — zero API change to HighlightLayer consumers.

**Why color tokens are decoupled from faction colors**: Movement cyan ≠ Player blue. Attack orange ≠ Enemy red. This ensures highlight state (where can I go? who can I attack?) is visually distinct from unit identity (whose unit is this?). The player never confuses "can move here" with "this is my unit."

**Why no SignalBus for UI updates**: HUD reads TurnManager's read-only properties (`turn_number`, `active_faction`, `current_state`) on signal receipt. The signal triggers a refresh; the properties provide the data. This avoids stale data in signal parameters — the state lives in TurnManager, not in the signal payload. Per ADR-0002: "Signal for Notification, Poll for State."

## Alternatives Considered

### Alternative 1: InputHandler as a Node (Scene Tree)

- **Description**: InputHandler extends Node, added to scene tree, receives `_unhandled_input()` directly
- **Pros**: Natural Godot pattern; no event forwarding bridge; can use `@onready` for dependency wiring
- **Cons**: Tied to scene tree — can't unit test without instantiating a scene. Violates ADR-0002 (logic objects are RefCounted). Input context state machine is pure logic — it doesn't need `_ready()` or `_process()`.
- **Rejection Reason**: ADR-0002 established RefCounted for all logic objects. The one-line bridge in Game.gd is a negligible cost for full testability.

### Alternative 2: Single HighlightLayer with Color Array

- **Description**: One Node2D that draws all highlights, varying color per tile based on a `Dictionary[Vector2i, Color]`
- **Pros**: One node instead of three; simpler scene tree
- **Cons**: All highlights redraw when any one changes (hover path change triggers full redraw of move + attack tiles). z-ordering requires draw order management within `_draw()`. Color logic centralized in one place — harder to reason about.
- **Rejection Reason**: Three nodes with independent `queue_redraw()` is more performant (each redraws only when its data changes) and clearer (z_index enforces layer order visually in the scene tree).

### Alternative 3: Texture-Based Highlighting (Sprite2D per Tile)

- **Description**: Pre-render highlight squares as textures; instantiate Sprite2D nodes for each highlighted tile
- **Pros**: Potential GPU batching benefits; familiar Godot workflow
- **Cons**: Node instantiation overhead — selecting a unit creates ~85 Sprite2D nodes, then removes them on deselect. Node creation/destruction per selection is wasteful. 85 nodes × 3 layers = 255 nodes for full selection display.
- **Rejection Reason**: `_draw()` + `draw_rect()` is simpler and avoids node churn. No texture assets to manage. For ~115 rectangles, the draw-call approach is more efficient than scene-tree manipulation.

### Alternative 4: UI as Godot Control Nodes (UI Toolkit)

- **Description**: Use Godot's Control system for board interaction (TextureRect per tile, Button per unit)
- **Pros**: Built-in theming, localization support, accessibility (AccessKit in 4.5+)
- **Cons**: Control nodes assume rectangular layouts and text-centric interaction. Grid-based tactical gameplay doesn't map well to Control's anchor/margin system. Per-tile Control nodes would be ~192 controls — Godot handles this but it's the wrong abstraction.
- **Rejection Reason**: The board is a game world rendered in world space, not a UI layout. Node2D + `_draw()` is the correct Godot pattern for game-world rendering. HUD elements (CanvasLayer + Control) use the Control system — this is the right split.

## Consequences

### Positive

- InputHandler is fully unit-testable without scene tree (synthetic events → state assertions)
- 3-layer highlight system with independent redraw per layer
- Event forwarding bridge (Game._unhandled_input → InputHandler.handle_event) is a single line
- Color tokens are centralized and decoupled from faction identity
- HUD and board rendering use the correct Godot patterns (CanvasLayer vs Node2D._draw())
- Result overlay `MOUSE_FILTER_STOP` naturally prevents click-through — no manual input gating

### Negative

- InputHandler is the largest class in the system (~150 lines) because it coordinates all upstream systems
- HighlightLayers need `GridSpace` reference for pixel positioning (constructor-injected — explicit dependency)
- Debug overlay creates up to 1024 Label nodes at 32×32 (acceptable; documented scalability concern)

### Risks

- **Risk**: `_draw()` performance with many highlights on large maps.
  - **Mitigation**: At MVP 32×32, max ~115 rectangles per selection. `draw_rect()` in `_draw()` is GPU-efficient — <1ms. If Tier 3 maps exceed 64×64, switch to `draw_multirect()` (single draw call for all rects).

- **Risk**: InputHandler.initialize() has 6 parameters — "too many constructor arguments" smell.
  - **Mitigation**: These are the actual dependencies (Map, GridSpace, TurnManager, 3 resolvers). Splitting into smaller objects would add indirection without reducing dependency count. At MVP scale, 6 parameters is manageable. If Tier 2+ adds more resolvers, group into an `InputHandlerDependencies` struct.

- **Risk**: UI dual-focus (4.6) — `grab_focus()` only affects keyboard/gamepad. MVP is mouse-only so this has zero impact. If keyboard navigation is added (Tier 2+), test both focus paths.

## GDD Requirements Addressed

| GDD System | Requirement | How This ADR Addresses It |
|------------|-------------|--------------------------|
| ui.md | A1: Click→grid resolution | `_grid_space.world_to_grid()` in `_handle_click()` |
| ui.md | A2: Context-dependent click interpretation | InputContext state machine dispatch table |
| ui.md | A3: Hover preview (path + damage) | `_handle_hover()` + HighlightLayer updates |
| ui.md | A4: Cancel (Escape/right-click) | `_handle_cancel()` with context-dependent behavior |
| ui.md | B1–B6: Complete interaction flow | `_select_unit → _execute_move → _execute_attack → _skip_attack` |
| ui.md | C1–C7: Constraints and gating | Turn state gate, active faction gate, action state gate, has_acted gate |
| ui.md | D1–D4: Rendering organization | Layer order + HighlightLayer z_index + debug overlay |
| ui.md | E1–E5: HUD elements | Turn indicator, faction indicator, End Turn button on CanvasLayer |
| ui.md | F1–F4: Screen states | BOARD / WIN / LOSE / DRAW with result overlay + "Play Again" |
| ui.md | Color tokens (Visual/Audio) | Centralized color token table, decoupled from faction colors |
| ui.md | All edge cases (double-click, resize, phase transition, click-through) | State guards + MOUSE_FILTER_STOP |
| ui.md | InputHandler as RefCounted, DI | Follows ADR-0002 pattern; 3×HighlightLayer as Node2D |
| game-concept.md | Programmer Art Functional anchor | All rendering code-drawn — no textures, no sprites, no animation |
| game-concept.md | Pillar 2: System Orthogonality | UI reads all upstream; owns no game logic; terminal layer |

## Performance Implications

- **CPU**: `_draw()` with ~115 `draw_rect()` calls <1ms. `handle_event()` ≈ Dictionary lookup + bounds check + context dispatch <0.1ms. HUD updates ≈ Label.text assignment (string) — negligible.
- **Memory**: 3 HighlightLayer nodes (lightweight Node2D). HUD ≈ ~6 Control nodes. Result overlay ≈ ~4 Control nodes. Debug overlay ≈ up to 1024 Labels (MVP 16×12 = 192 labels, ~50KB). Total UI memory <500KB.
- **Load Time**: HighlightLayer._draw() called on `queue_redraw()` only — zero load time impact.

## Migration Plan

Greenfield. Implementation order:
1. Create `src/ui/highlight_layer.gd` with `_draw()` + `set_highlight()`
2. Create `src/ui/input_handler.gd` with InputContext state machine
3. Create Board.tscn: Node2D with 3×HighlightLayer children
4. Create HUD.tscn: CanvasLayer with turn/faction labels + End Turn button
5. Create ResultOverlay.tscn: CanvasLayer with background + title + reason + button
6. Wire in Game._ready() per ADR-0002: create InputHandler, inject all dependencies
7. Wire `_unhandled_input()` bridge: Game → InputHandler.handle_event()
8. Wire all TurnManager signals to HUD update methods
9. Visual test: select unit → move highlight → hover path → attack target → damage preview → result screen

## Validation Criteria

- [ ] Click on walkable tile → `world_to_grid()` returns correct `Vector2i`
- [ ] Click out of board bounds → silently ignored (no state change)
- [ ] BOARD_IDLE + click PLAYER idle unit → unit selected, move highlights rendered
- [ ] BOARD_IDLE + click ENEMY unit → ignored
- [ ] UNIT_SELECTED + click reachable tile → unit moves, enters ATTACK_TARGETING
- [ ] UNIT_SELECTED + click enemy in range → direct attack (SELECTED→ACTED, no move)
- [ ] UNIT_SELECTED + Escape → deselect, state returns to BOARD_IDLE
- [ ] ATTACK_TARGETING + click valid target → attack executes, damage number appears
- [ ] ATTACK_TARGETING + Escape → skip attack, unit becomes ACTED
- [ ] Move highlight renders on correct tiles with `#0891B2`
- [ ] Path preview renders on correct tiles with `#06B6D4`
- [ ] Attack highlight renders on correct tiles with `#EA580C`
- [ ] HUD shows "Turn 1/30" and "Player Turn" after match_started
- [ ] End Turn button visible only in FACTION_PHASE_ACTIVE
- [ ] match_ended("elimination", PLAYER) → WIN screen with green "VICTORY"
- [ ] "Play Again" button triggers match restart
- [ ] Result overlay blocks click-through (MOUSE_FILTER_STOP)
- [ ] FACTION_PHASE_ENDING → all highlights cleared, selection cancelled
- [ ] Debug overlay toggles on/off with backtick key
- [ ] InputHandler extends RefCounted, receives all deps via initialize()

## Related Decisions

- ADR-0001: GridSpace Coordinate Boundary (click→grid resolution)
- ADR-0002: Dependency Injection Architecture (InputHandler as RefCounted)
- ADR-0003: Unit Public Interface (reads all attributes for selection/display)
- ADR-0004: Turn System Architecture (reads state for HUD + input gating)
- ADR-0005: Map CSV Loading & Occupancy (reads topology, calls move_unit)
- ADR-0006: Movement System (consumes MovementResult for move/path highlights)
- ADR-0007: Attack System (consumes target lists + resolve_damage for preview)
- ADR-0008: AI Controller Interface (hotseat mode via NullAI)
- ADR-0009: Victory System (consumes match_ended for result screen)
- `design/gdd/ui.md` — UI GDD (authoritative design)
