# Movement

> **Status**: In Design
> **Author**: binlee1990 + Claude
> **Last Updated**: 2026-04-29
> **Implements Pillar**: Pillar 2 — System Orthogonality (BFS over Map grid, reads Unit stats, emits result set)

## Overview

Movement is the player's primary agency verb in the SRPG skeleton: click a unit, see blue reachable-tile highlights bloom outward from its position, hover a destination to preview the exact von Neumann path, click to commit. The system reads `unit.mov` as the BFS radius and queries Map's tile walkability and occupancy to compute the exact set of reachable tiles and the shortest path to each. Movement is teleport-style — the unit's `grid_position` updates instantly, consistent with the MVP's "no animation" stance. Every highlighted tile is a guarantee: if it's blue, you can reach it in ≤ MOV steps. Without Movement, the board is a static diorama — units can't reposition, can't close distance, can't flank. Movement is the first half of every action the Turn System governs.

## Player Fantasy

Movement is the most tactile interaction in the skeleton. Click a unit and the board answers — blue tiles bloom outward, one ring per MOV point, each tile a guarantee: if it is blue, you can reach it. Hover a destination and the exact von Neumann path snaps into view. Click again and the unit commits instantly. No animation, no waiting — the board responds at the speed of your mouse. Click, see, commit.

## Detailed Design

### Core Rules

1. **BFS Range Computation**: Movement resolves reachable tiles via breadth-first search from `unit.grid_position`. Each expansion step queries `Map.get_neighbors(coord)` (4-neighbor von Neumann), filters via `Map.is_walkable(coord)`, and respects `unit.mov` as the maximum depth. All tiles have movement cost 1 at MVP (no terrain effects). BFS uses `Dictionary[Vector2i, Vector2i]` as a parent map and `Dictionary[Vector2i, int]` for distances. The start tile is special-cased: added to the visited set before expansion, since `is_walkable()` would return false for the unit's own occupied tile. The BFS result is returned as an immutable `MovementResult` RefCounted.

2. **Reachable Set**: `{tiles within ≤ MOV steps via walkable tiles}`. Includes the start tile (0 steps) per Rule 1 special case. Excludes blocked tiles, obstacle tiles, and tiles occupied by other units (per `Map.is_walkable()`). Dead units' former tiles are walkable — the dead unit is removed from occupancy before the next BFS run.

3. **Path Computation**: For any reachable tile, the path is reconstructed lazily from the BFS parent map: follow parent pointers from target back to start, then reverse the result. Since BFS visits tiles in order of increasing distance, the first parent recorded is one of possibly several equal-length shortest paths. The returned path is `Array[Vector2i]` from start to target inclusive. Path reconstruction is O(path_length) ≤ O(MOV) ≤ 6 dictionary lookups, effectively O(1).

4. **Movement Execution**: When the player confirms a destination, Input calls `Map.move_unit(unit, from, to)`. This is Map's atomic method (Map Edge Cases OQ3) that updates `_occupancy` and `unit.grid_position` in a single operation. Movement does NOT execute the move — it only computes reachability. Input is the coordinator.

5. **Skip-Move (0 Steps)**: Clicking the unit's own tile (start tile, distance 0) is a valid move. The unit enters MOVED state without changing position, then proceeds to attack targeting. This enables "attack without moving" — standard SRPG behavior.

6. **Post-Move State**: After `Map.move_unit()` succeeds, Input sets `unit.action_state = MOVED` (Unit GDD state machine: SELECTED → MOVED). Movement does NOT set `has_acted_this_turn` — that flag is set after the full move+attack action completes, owned by Input/Turn System.

7. **Hover Preview**: When the player hovers a tile in the reachable set, Input calls `MovementResult.get_path_to(tile)` to retrieve the path. UI renders the path tiles in a distinct highlight color (e.g., brighter blue or cyan). When the cursor leaves the reachable set, Input clears the preview. Movement only provides data; UI/Input owns rendering.

8. **Highlight Display**: All reachable tiles are highlighted in blue (Programmer Art Functional palette). The start tile is rendered distinctly (e.g., darker blue). Path preview tiles use a third color (e.g., cyan). Highlight rendering is entirely owned by UI/Input — Movement only provides the `MovementResult` data object.

9. **Constraints**:
   - Unit must be in SELECTED state to begin movement (`can_move()` precondition from Unit GDD).
   - Unit must be alive (`is_alive == true`).
   - Unit must belong to the active faction (enforced by Input, not Movement).
   - Movement cannot pass through blocked, obstacle, or occupied tiles. BFS enforces this via `Map.is_walkable()`.
   - Movement computation is a pure function — no side effects on Map, Unit, or any other system.

### Movement Flow

```
1. Player clicks unit
   → Input checks unit.can_be_selected()
   → unit.action_state = SELECTED

2. Compute reachable area
   → result = MovementResolver.compute_reachable(unit, map)
   → returns MovementResult (reachable tiles + parent map)

3. Highlight reachable tiles
   → UI reads result.get_reachable_tiles()
   → renders all tiles blue

4. Player hovers a tile
   → if tile in reachable set: path = result.get_path_to(tile)
   → UI highlights path tiles

5. Player clicks a reachable tile
   → Input calls Map.move_unit(unit, unit.grid_position, clicked_tile)
   → unit.action_state = MOVED
   → UI clears all highlights

6. Cancel (deselect)
   → Player presses Escape or right-clicks
   → Input resets unit.action_state = IDLE
   → Input clears highlights (MovementResult discarded)
```

### MovementResult API

`MovementResult` is an immutable RefCounted returned by `MovementResolver.compute_reachable()`:

| Method | Returns | Description |
|--------|---------|-------------|
| `get_reachable_tiles()` | `Array[Vector2i]` | All tiles within MOV steps. Includes start tile. |
| `get_path_to(target: Vector2i)` | `Array[Vector2i]` | Shortest path from start to target (start → ... → target inclusive). Empty array if target not reachable. |
| `get_distance_to(target: Vector2i)` | `int` | Step count to target. -1 if target not reachable. |
| `get_start_tile()` | `Vector2i` | The unit's starting position. |

### Interactions with Other Systems

| System | Direction | Data Flow | Interface |
|--------|-----------|-----------|-----------|
| **Map** | Upstream (reads) | Movement queries grid topology | `Map.get_neighbors(coord)`, `Map.is_walkable(coord)` — BFS frontier expansion and filtering |
| **Map** | Upstream (write, via Input) | Input executes move | `Map.move_unit(unit, from, to)` — atomic occupancy + position update. Called by Input, NOT by Movement |
| **Unit** | Upstream (reads) | Movement reads unit state | `unit.mov: int` — BFS radius. `unit.grid_position: Vector2i` — BFS start. `unit.is_alive: bool` — dead units cannot move. `unit.action_state` — must be SELECTED |
| **Unit** | Downstream (write, via Input) | Input updates unit state | `unit.grid_position = to` (inside `Map.move_unit()`). `unit.action_state = MOVED` (set by Input after successful move) |
| **UI / Input** | Downstream (data) | Movement provides computation results | `MovementResult` — reachable tiles, paths, distances. UI reads for highlight rendering |
| **UI / Input** | Upstream (call) | Input invokes computation | `MovementResolver.compute_reachable(unit, map) -> MovementResult` — called when unit enters SELECTED |
| **Turn System** | Indirect | Movement gated by turn state | Input enforces `active_faction` match and `current_state == FACTION_PHASE_ACTIVE` before allowing movement. Movement does not reference Turn System directly |
| **Attack** | Indirect | Movement triggers attack phase entry | After unit enters MOVED state, Input transitions to attack targeting. Movement has no direct Attack dependency |

## Formulas

### F1: BFS Reachable Set

The BFS reachable set formula is defined as:

`reachable = BFS(start = unit.grid_position, max_depth = unit.mov, neighbors_fn = Map.get_neighbors, walkable_fn = Map.is_walkable)`

**Variables:**

| Variable | Symbol | Type | Range | Description |
|----------|--------|------|-------|-------------|
| Start tile | start | Vector2i | in-bounds tile | unit.grid_position |
| Movement radius | mov | int | [2, 6] | unit.mov from UnitStats |
| Frontier queue | queue | Array[Vector2i] | [1, ~85] | BFS expansion queue, max size = von Neumann diamond area |
| Parent map | parent | Dictionary[Vector2i, Vector2i] | [0, ~85] entries | tile → parent tile for path reconstruction |
| Distance map | dist | Dictionary[Vector2i, int] | [0, ~85] entries | tile → steps from start |

**Output:** `MovementResult` containing all tiles where `dist[tile] ≤ mov` and `is_walkable(tile) == true`. Start tile exempt from walkability check (unit occupies its own tile).

**Performance:** Worst case MOV=6 on open 32×32 grid: approximately 85 tiles visited, ~340 neighbor queries. Expected <0.5ms in GDScript — well within the 16.6ms frame budget.

**Example:** unit at (5, 5) with MOV=4 on an open map → reachable set is a von Neumann diamond of radius 4, containing `2×4×(4+1) + 1 = 41` tiles.

### F2: Manhattan Distance

The Manhattan distance formula is defined as:

`manhattan(a, b) = |a.row − b.row| + |a.col − b.col|`

**Variables:**

| Variable | Symbol | Type | Range | Description |
|----------|--------|------|-------|-------------|
| Tile A | a | Vector2i | in-bounds | First tile coordinate |
| Tile B | b | Vector2i | in-bounds | Second tile coordinate |
| Distance | result | int | [0, map_cols + map_rows] | Manhattan distance in tile steps |

**Output Range:** [0, map_cols + map_rows − 2] on a rectangular map.

**Usage:** Quick out-of-range rejection before hover path computation. If `manhattan(unit_pos, hovered_tile) > unit.mov`, the tile cannot be reachable (necessary but not sufficient — blocked tiles may further constrain reachability).

**Example:** unit at (5, 5), hovered tile at (5, 9) → `manhattan = |5−5| + |9−5| = 4`. Since MOV ≥ 4, the tile may be reachable (BFS confirms).

### F3: Path Steps

The path steps formula is defined as:

`path_length(target) = dist[target]`

where `dist` is the BFS distance map from F1.

**Variables:**

| Variable | Symbol | Type | Range | Description |
|----------|--------|------|-------|-------------|
| Target tile | target | Vector2i | in-bounds, reachable | Destination tile |
| Distance | dist[target] | int | [0, mov] | Step count from start to target |

**Output Range:** [0, mov]. 0 for the start tile. Maximum `mov` for the farthest reachable tiles.

**Behavior when target not reachable:** `dist[target]` is undefined (key not in dictionary). `MovementResult.get_distance_to()` returns -1.

**Example:** unit at (5, 5), target at (5, 9) via 4 eastward steps on open terrain → `path_length = 4`.

> **Boundary note**: The Manhattan distance formula (F2) belongs to the Movement system as a utility, but the concept of "Manhattan distance" is also used by the Attack system (target range validation). Attack GDD may reference this formula or define its own range computation — whichever system "owns" the formula will be determined during Attack GDD authoring. The Movement GDD defines it here for path-rejection purposes.

## Edge Cases

### Precondition Violations

- **If `compute_reachable()` is called on a dead unit**: Returns empty `MovementResult`. `get_reachable_tiles()` returns `[]`. `get_start_tile()` returns `Vector2i(-1, -1)` sentinel. No crash — caller is responsible for checking `unit.is_alive` before invoking.

- **If `map` reference is null**: Returns empty `MovementResult`. No crash. Caller (Input) ensures Map is loaded before movement begins.

- **If `unit.grid_position` is out of map bounds**: BFS trusts `Map.get_neighbors()` for boundary filtering — an out-of-bounds start coordinate produces 0 neighbors. Result: `{start}` (only tile). Movement does not duplicate bounds checking; Map is the authority.

- **If called when `unit.action_state != SELECTED`**: Movement is a pure function — it computes reachability regardless of unit state. Caller (Input) owns precondition enforcement. Result is valid but ignored if state is wrong.

### Degenerate BFS Results

- **If only the start tile is reachable** (all neighbors blocked, or MOV too low to reach any walkable neighbor): Reachable set = `{start_tile}`. Unit can still confirm a skip-move (0 steps, Core Rule 5). Path preview displays only the start tile. Not an error — valid tactical situation (e.g., unit cornered).

### TOCTOU Race

- **If a target tile becomes occupied between BFS computation and move execution**: `Map.move_unit()` rejects the move (Map Edge Case — occupied coord returns false). Movement does not detect or handle this — it is a documented handoff. Input must either re-compute BFS or display "tile occupied" feedback to the player.

### API Edge Cases

- **If `get_path_to(start_tile)` is called**: Returns `[start_tile]` (single-element array), not empty. Distance = 0.

- **If `get_distance_to(start_tile)` is called**: Returns `0`, not `-1`.

### Boundary Conditions

- **If unit is on a corner tile of an 8×8 map (smallest) with MOV=6**: BFS is naturally constrained by map edges. At `(0,0)`, max reachable tiles ≈36 (half-diamond clipped by two boundaries). `get_neighbors()` returns 2 for corner tiles — BFS adapts naturally. No special handling required.

## Dependencies

### Upstream Dependencies

| System | Type | Interface Consumed | Notes |
|--------|------|--------------------|-------|
| **Map** | Hard | `get_neighbors(coord)`, `is_walkable(coord)`, `move_unit(unit, from, to)` | BFS topology queries + occupancy filtering. `move_unit()` is called by Input after Movement computation, not by Movement directly. `move_unit()` is documented in Map Edge Cases OQ3 as the required atomic method. |
| **Unit** | Hard | `unit.mov: int`, `unit.grid_position: Vector2i`, `unit.is_alive: bool`, `unit.action_state` | BFS radius + start position. Interface locked by Unit GDD. |

### Downstream Dependencies

| System | Type | Interface Exposed | Notes |
|--------|------|-------------------|-------|
| **UI / Input** | Hard | `MovementResult` (reachable tiles, paths, distances); `MovementResolver.compute_reachable()` | UI reads `MovementResult` for highlight rendering. Input calls `compute_reachable()` when unit enters SELECTED, and `map.move_unit()` on click confirmation. |
| **Attack** | Indirect | Post-MOVED trigger | Unit entering MOVED state (after successful move or skip-move) enables attack targeting. Movement does not call Attack directly. |
| **Turn System** | Indirect | Input gating | Input enforces `active_faction` match and `current_state == FACTION_PHASE_ACTIVE` before allowing movement. Movement does not reference Turn System directly. |

### External Dependencies

| Dependency | Type | Notes |
|------------|------|-------|
| `MovementResolver` (RefCounted) | Code | Pure BFS computation, no side effects. Created by Game scene, DI-injected into Input. |
| `MovementResult` (RefCounted) | Code | Immutable result wrapper. Lazy path reconstruction from BFS parent map. |

## Tuning Knobs

| Knob | Location | Safe Range | What Happens If Too Low | What Happens If Too High | Notes |
|------|----------|------------|------------------------|------------------------|-------|
| `unit.mov` | UnitStats.tres | [2, 6] | 2: unit can barely reposition — tactical depth collapses, flanking impossible | 6: unit crosses a default 16×12 map in ~3 turns — positioning becomes trivial | Defined in Unit GDD. Movement reads it, does not own it. Default 4. |

**Knob interactions**: `unit.mov` is the sole movement tunable at MVP. Terrain costs (Tier 2) will add per-tile-type cost multipliers that interact with MOV — a MOV 4 unit on cost-2 terrain effectively has MOV 2 reach. This interaction will be defined in the Terrain GDD (Tier 2).

## Visual/Audio Requirements

N/A — Movement owns no rendering nodes. Highlight colors are specified here for reference but rendered by the UI / Input system:

| Visual Element | Color | Owner |
|---------------|-------|-------|
| Reachable tile highlight | Blue (`#3B82F6`, Programmer Art Functional player faction blue) | UI / Input |
| Start tile highlight | Darker blue or distinct border | UI / Input |
| Path preview highlight | Cyan or brighter blue | UI / Input |

No audio. Movement is instantaneous (teleport-style) — no footstep or slide SFX at MVP.

> **Asset Spec**: No visual assets needed for Movement itself. Highlight rendering uses flat-color overlays on TileMapLayer — part of the UI / Input system's asset spec, not Movement's.

## UI Requirements

Movement does not render UI directly. It exposes data for UI consumption via `MovementResult`:

| Data | Method | UI Usage |
|------|--------|----------|
| Reachable tiles | `get_reachable_tiles()` | Blue highlight overlay on all reachable tiles |
| Path to hovered tile | `get_path_to(tile)` | Path preview highlight (cyan) on hover |
| Distance to tile | `get_distance_to(tile)` | Optional: display step count on hover |
| Start tile | `get_start_tile()` | Distinct start tile highlight |

Input handling flow:
- **Click unit** (SELECTED state) → UI calls `MovementResolver.compute_reachable()` → renders highlights
- **Hover tile** → UI calls `MovementResult.get_path_to(tile)` → renders path preview
- **Click reachable tile** → UI calls `Map.move_unit()` → clears highlights → unit enters MOVED
- **Right-click / Escape** (cancel) → UI clears highlights → unit returns to IDLE

## Acceptance Criteria

### Core Rules

**AC-MOVE-001 — BFS Reachable Area on Open Grid (Rule 1, F1)** [Logic]
GIVEN a 5×5 all-walkable map, unit at (2,2), MOV=2, WHEN `MovementResolver.compute_reachable(unit, map)` is called, THEN the reachable set contains exactly 13 tiles — all tiles with Manhattan distance ≤ 2 that are within map bounds, found via 4-neighbor BFS.

**AC-MOVE-002 — BFS Correctly Avoids Blocked/Occupied Tiles (Rule 1)** [Logic]
GIVEN a 3×3 all-walkable map where tile (1,1) is occupied by an enemy unit, friendly unit at (1,0), MOV=2, WHEN `compute_reachable()` is called, THEN (1,1) and (1,2) are NOT in the reachable set — the only 2-step path to (1,2) passes through occupied (1,1).

**AC-MOVE-003 — Start Tile Always in Reachable Set (Rule 2)** [Logic]
GIVEN any valid map and unit at any walkable tile, WHEN `compute_reachable()` is called, THEN the unit's current `grid_position` is always in the reachable set, even if MOV is at minimum. Start tile is special-cased (unit occupies its own tile).

**AC-MOVE-004 — Path Reconstruction Returns Shortest Path (Rule 3, F3)** [Logic]
GIVEN a 5×5 all-walkable map, BFS from (0,0) to (2,1), WHEN `MovementResult.get_path_to((2,1))` is called, THEN the returned array has length 4 (start + 3 steps), each adjacent pair satisfies 4-neighbor adjacency, and all tiles on the path are walkable.

**AC-MOVE-005 — Map.move_unit() Complete Move (Rule 4)** [Integration]
GIVEN unit at (0,0), target (0,1) empty and walkable, WHEN `Map.move_unit(unit, (0,0), (0,1))` is called, THEN unit.grid_position becomes (0,1), Map updates occupancy atomically (old tile released, new tile occupied), and the operation returns `true`.

**AC-MOVE-006 — Skip-Move (0 Steps) (Rule 5)** [Logic]
GIVEN unit at (2,3) in SELECTED state, WHEN the player confirms movement to (2,3) (same tile), THEN it is treated as a valid move: movement phase consumed, unit enters MOVED state without changing position.

**AC-MOVE-007 — Post-Move State: SELECTED → MOVED (Rule 6)** [Integration]
GIVEN unit in SELECTED state at (0,0), target (0,2) confirmed as valid, WHEN `Map.move_unit()` completes, THEN unit `action_state` is MOVED, and subsequent `can_move()` returns `false`.

**AC-MOVE-008 — Hover Preview Exposes Path Data (Rule 7)** [Integration]
GIVEN unit in SELECTED state with reachable set computed, WHEN UI queries `MovementResult.get_path_to(tile)` for a reachable tile, THEN a valid path array is returned and `get_distance_to(tile)` returns the step count. If the tile is not reachable, both return empty array or -1 respectively.

**AC-MOVE-009 — Constraints: Dead or Wrong-State Unit Cannot Move (Rule 9)** [Logic]
GIVEN unit with `is_alive() == false` or `action_state != SELECTED`, WHEN `compute_reachable()` is called, THEN the result is an empty reachable set. No crash, no side effects.

### Formulas

**AC-MOVE-010 — F1: BFS Distance Layers on Open Grid** [Logic]
GIVEN an 8×8 all-walkable map, unit at (4,4), MOV=3, WHEN BFS runs, THEN each distance layer d ∈ [0,3] contains exactly the number of tiles where `|r−4| + |c−4| = d`: d=0 → 1, d=1 → 4, d=2 → 8, d=3 → 12, total 25 tiles. All tiles provably reachable in ≤ 3 steps via 4-neighbor BFS.

**AC-MOVE-011 — F2: Manhattan Distance** [Logic]
GIVEN points (0,0) and (3,4), WHEN Manhattan distance is computed, THEN result = `|3−0| + |4−0| = 7`. Symmetric: `d(a,b) == d(b,a)`. If `manhattan(start, tile) > unit.mov`, the tile cannot be reachable (necessary condition).

**AC-MOVE-012 — F3: Path Steps** [Logic]
GIVEN path array `[(0,0), (0,1), (1,1), (2,1), (2,2)]`, WHEN `path_length` is computed (`len(path) − 1`), THEN result = 4. GIVEN single-element path `[(0,0)]`, THEN steps = 0 (skip-move). Empty path returns 0, no crash.

### Edge Cases

**AC-MOVE-013 — Edge: Dead Unit Rejected** [Logic]
GIVEN unit with `is_alive() == false` at a valid coordinate, WHEN `compute_reachable()`, `get_path_to()`, or movement execution is attempted, THEN the method returns empty/error immediately. No computation, no side effects, no exception.

**AC-MOVE-014 — Edge: Null Map Rejected** [Logic]
GIVEN a valid unit but `map == null`, WHEN `compute_reachable()` is called, THEN the method returns an empty `MovementResult`. No crash.

**AC-MOVE-015 — Edge: Out-of-Bounds Start Position** [Logic]
GIVEN unit at a coordinate outside map bounds (e.g., (-1, 5)), WHEN `compute_reachable()` is called, THEN the result is an empty set — BFS cannot expand from an out-of-bounds position.

**AC-MOVE-016 — Edge: Degenerate BFS — MOV=0** [Logic]
GIVEN unit at (2,3) with MOV=0 on a 5×5 all-walkable map, WHEN `compute_reachable()` is called, THEN the result is `{(2,3)}` — only the start tile. `get_path_to((2,3))` returns `[(2,3)]`, steps = 0.

**AC-MOVE-017 — Edge: Degenerate BFS — All Neighbors Blocked** [Logic]
GIVEN unit on a walkable tile whose 4 neighbors are all blocked (`is_walkable` returns false for all 4), WHEN `compute_reachable()` is called, THEN even with MOV > 0, the reachable set is `{start_tile}` only — BFS frontier exhausted after d=0.

**AC-MOVE-018 — Edge: TOCTOU — Target Occupied After BFS** [Logic]
GIVEN a path computed when the target was empty, but the target tile becomes occupied before `Map.move_unit()` executes, WHEN `move_unit()` is called, THEN Map rejects the move and returns `false`. Unit stays at original position. No partial movement. Atomic via `move_unit()`.

**AC-MOVE-019 — Edge: Move to Blocked/Occupied Tile** [Integration]
GIVEN unit at (0,0), target (0,1) is blocked or enemy-occupied, WHEN `Map.move_unit(unit, (0,0), (0,1))` is called, THEN it returns `false`, unit.grid_position remains (0,0), and occupancy is unchanged.

**AC-MOVE-020 — Edge: Repeat Move to Same Tile When Already MOVED** [Logic]
GIVEN unit has already completed a move (state = MOVED), WHEN `execute_move()` is attempted again to the same tile, THEN the method is rejected — state guard prevents double-consumption. Unit stays at its position.

**AC-MOVE-021 — Edge: Map Boundary Clipping (8×8 Corner)** [Logic]
GIVEN an 8×8 all-walkable map, unit at corner (0,0), MOV=3, WHEN `compute_reachable()` is called, THEN the reachable set contains all tiles satisfying `r + c ≤ 3` within bounds — BFS correctly clipped at r<0 and c<0 boundaries. Same verified for opposite corner (0,7).

**AC-MOVE-022 — Edge: All Tiles Blocked Except Start** [Logic]
GIVEN a 3×3 map with 1 walkable tile (1,1) and all others blocked, unit at (1,1), MOV=6, WHEN `compute_reachable()` is called, THEN result is `{(1,1)}` — BFS frontier cannot expand to any neighbor, but does not loop infinitely or crash.

### Performance

**AC-MOVE-023 — Performance: BFS < 1ms at MOV=6 on 32×32 Grid** [Logic]
GIVEN a 32×32 all-walkable map, unit at center (16,16), MOV=6, WHEN `compute_reachable()` is called, THEN total execution time (including bounds checks and queue operations) is below 1 millisecond. Reachable set size ≈85 tiles (von Neumann diamond). Verifies BFS scalability for all map sizes in [8, 32] range.

### Integration: End-to-End

**AC-MOVE-024 — Integration: Full Move → Occupancy Consistency** [Integration]
GIVEN a 5×5 map with two friendly units, no enemies, WHEN unit A moves from (0,0) to (0,2) (path confirmed), THEN: unit A.grid_position = (0,2); `Map.get_unit_at((0,0))` returns null; `Map.get_unit_at((0,2))` returns unit A; unit B is unaffected; `Map.is_walkable((0,0))` returns true (released); `Map.is_walkable((0,2))` returns false (occupied by A).

**AC-MOVE-025 — Integration: Post-Move Enables Attack Targeting** [Integration]
GIVEN unit in SELECTED state, moves from (1,1) to (1,3), WHEN `execute_move` completes, THEN: unit.action_state = MOVED; `has_acted_this_turn` is false (attack not yet consumed); unit can proceed to attack targeting; `can_move()` returns false; `can_attack()` returns true if a target is within `rng`.

### Summary

| Category | Count | Logic | Integration | Gate |
|----------|-------|-------|-------------|------|
| Core Rules (9) | 9 | 6 | 3 | BLOCKING |
| Formulas (3) | 3 | 3 | 0 | BLOCKING |
| Edge Cases (10) | 10 | 9 | 1 | BLOCKING |
| Performance (1) | 1 | 1 | 0 | BLOCKING |
| End-to-End (2) | 2 | 0 | 2 | BLOCKING |
| **Total** | **25** | **19** | **6** | — |

All 25 criteria are BLOCKING. 19 require automated unit tests in `tests/unit/movement/`. 6 require integration tests in `tests/integration/movement/`.

## Open Questions

- **OQ1 — `Map.move_unit()` formalization**: Movement GDD requires `Map.move_unit(unit, from, to) -> bool` as an atomic method. Currently documented in Map GDD Edge Cases OQ3 as a recommendation. Should this be promoted to Map GDD Core Rules before Movement implementation? → Defer to Map GDD update (can be done as a quick retrofit).

- **OQ2 — Manhattan distance ownership**: F2 defines Manhattan distance in the Movement GDD, but the Attack system (Order 5) also uses Manhattan distance for range validation. Should the formula "live" in Movement and be referenced by Attack, or should each system define its own? → Resolve during Attack GDD authoring.

- **OQ3 — MOV=0 unit archetype**: The Unit GDD locks MOV range to [2, 6]. A MOV=0 unit (immobile turret) is not possible at MVP. Should the range floor be lowered to 0 for Tier 2? → Defer to Tier 2 design.
