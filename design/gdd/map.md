# Map / Coordinates

> **Status**: In Design
> **Author**: binlee1990 + Claude
> **Last Updated**: 2026-04-29
> **Implements Pillar**: Pillar 2 — System Orthogonality (GridSpace boundary is the firewall against coordinate logic leaking into rendering)

## Overview

The Map / Coordinates system defines the spatial topology of the game board: a square grid of tiles connected by 4-neighbor (von Neumann) adjacency, with each tile in exactly one of three states — **walkable**, **blocked**, or **obstacle**. A `GridSpace` boundary owns the authoritative conversion between grid coordinates (integer index pairs) and world pixel positions; every other system reads spatial data through this interface, and no other system performs inline coordinate math. The map is rendered via Godot's `TileMapLayer` node, which displays each tile state as a distinct flat color per the Programmer Art Functional palette. This system is the foundation layer — Unit placement, Movement BFS, Attack range computation, AI targeting, and UI highlighting all depend on it for the answer to "where." Without it, there is no board, no adjacency, and no way to place or move anything.

## Player Fantasy

The Map / Coordinates system serves no direct player emotion — and that is its success condition. Its fantasy is **transparency**: the grid is so predictable that the player stops thinking about "the grid" and starts thinking about *tactics*. A tile that looks walkable is walkable. A clicked coordinate resolves to exactly that tile, every time. Adjacency follows the simple von Neumann rule (up/down/left/right), with no diagonal ambiguity. The GridSpace boundary guarantees that the path previewed in Movement matches the tile the Attack system evaluates. When the map system draws attention to itself, something is wrong. When it is invisible, it has done its job.

## Detailed Design

### Core Rules

1. **Grid**: A rectangular grid of `cols × rows` tiles. Bounds: configurable per map, range `[8, 32]` per axis. Default MVP map: `16 × 12`.

2. **Coordinate System**: Origin at top-left corner. Row-major: `(row, col)`, row increases downward (matching Godot Y-down screen coords). Tile size: 64×64 pixels (locked by art bible).

3. **Adjacency**: 4-neighbor von Neumann only — `(r-1, c)`, `(r+1, c)`, `(r, c-1)`, `(r, c+1)`. No diagonal neighbors. Edge tiles have 2–3 neighbors. No wrap-around.

4. **Tile States**: Each tile is exactly one of three states, immutable after map load:
   - **walkable**: Units can stand here. Rendered as `TILE_DEFAULT` (#374151).
   - **blocked**: Units cannot stand here. MVP functionally identical to obstacle. Rendered as `TILE_BLOCKED` (#111827).
   - **obstacle**: Units cannot stand here. Provisioned for future line-of-sight blocking. Rendered as `TILE_OBSTACLE` (#1F2937).

5. **GridSpace Boundary**: The `GridSpace` object (a `RefCounted` instance, owned by the Map scene and dependency-injected into downstream systems) is the single authority for coordinate conversion:
   - `world_to_grid(world_pos: Vector2) → Vector2i` — pixel position to tile (row, col).
   - `grid_to_world(grid_pos: Vector2i) → Vector2` — tile (row, col) to tile top-left pixel corner.
   - No other system may compute `position * 64` or `position / 64`. Enforced in code review.

6. **Map Data Format**: CSV file per map in `assets/data/maps/`. First row: `cols,rows`. Remaining rows: one character per cell — `.` = walkable, `#` = blocked, `O` = obstacle. Edit-friendly and git-diffable.

7. **Map Loading**: The Map scene contains an empty `TileMapLayer` node. On `_ready()`, Map reads its assigned CSV, validates bounds, and calls `TileMapLayer.set_cell()` per tile. Three atlas tiles in the TileSet resource correspond to the three states. No pre-painted cells in the scene file.

8. **Occupancy**: Runtime occupancy is tracked separately from tile state:
   - **Unit** owns `grid_position: Vector2i` — the authoritative unit position.
   - **Map** owns a `_occupancy: Dictionary[Vector2i, Unit]` — O(1) reverse lookup.
   - Map exposes `is_walkable(coord: Vector2i) → bool`: returns `true` iff `tile_state == WALKABLE AND coord not in _occupancy`.
   - Map exposes `place_unit(unit, coord)` / `remove_unit(coord)` for occupancy updates.
   - Map exposes `get_unit_at(coord: Vector2i) → Unit` (returns `null` if empty).

9. **Neighbor Query**: `Map.get_neighbors(coord: Vector2i) → Array[Vector2i]` returns only in-bounds coordinates in 4-neighbor order. Does NOT filter by walkability — that is the caller's responsibility (enables BFS to manage its own visited set).

### States and Transitions

**Tile state** is immutable at runtime. A tile's walkable/blocked/obstacle status is read from the CSV and never modified during gameplay.

**Occupancy state** is mutable and managed by Movement:
| Transition | Trigger | Effect |
|---|---|---|
| Empty → Occupied | Unit moves onto tile | Map._occupancy[coord] = unit; unit.grid_position = coord |
| Occupied → Empty | Unit moves off tile | Map._occupancy.erase(coord) |
| Occupied → Occupied | Unit dies on tile | Map._occupancy.erase(coord); tile remains walkable |

There is no "occupied by obstacle" — obstacles are a tile state, not an entity.

### Interactions with Other Systems

| Downstream System | What Map Exposes | Data Direction |
|---|---|---|
| **Unit** | `grid_to_world()` — places unit scene nodes at tile centers | Map → Unit |
| **Movement** | `is_walkable(coord)`, `get_neighbors(coord)` — BFS frontier expansion; `place_unit()`/`remove_unit()` — occupancy writes | Map ↔ Movement |
| **Attack** | `get_neighbors(coord)` — range ring computation; `get_unit_at(coord)` — target validation | Map → Attack |
| **UI / Input** | `world_to_grid()` — click→tile resolution; `grid_to_world()` — highlight overlay placement; tile state query — color selection | Map → UI |

Map exposes no write interfaces to Attack or UI — those systems are read-only consumers.

## Formulas

### F1: grid_to_world

`grid_to_world(row, col) = (col * TILE_SIZE, row * TILE_SIZE)`

| Variable | Symbol | Type | Range | Description |
|----------|--------|------|-------|-------------|
| Row index | row | int | [0, map_rows−1] | Tile row index |
| Column index | col | int | [0, map_cols−1] | Tile column index |
| Tile size | TILE_SIZE | const int | 64 | Pixels per tile edge (art bible locked) |

**Output**: Tile top-left corner in world pixel coordinates. For unit placement, caller computes center: `grid_to_world(r,c) + Vector2(32, 32)`.

**Example**: `grid_to_world(2, 3) = (192, 128)` — tile at row 2, col 3 has top-left corner at pixel (192, 128); center at (224, 160).

### F2: world_to_grid

`world_to_grid(x, y) = (floor(y / TILE_SIZE), floor(x / TILE_SIZE))`

| Variable | Symbol | Type | Range | Description |
|----------|--------|------|-------|-------------|
| Pixel X | x | float | any | Screen/world-space X |
| Pixel Y | y | float | any | Screen/world-space Y |
| Tile size | TILE_SIZE | const int | 64 | Pixels per tile edge |

**Output**: Unbounded `Vector2i(row, col)`. Caller is responsible for `is_coord_in_bounds` check. Floor handles boundary: a pixel exactly on a tile edge resolves to the higher-index tile.

**Example**: `world_to_grid(215, 150) = (2, 3)`.

### F3: tile_center (convenience wrapper)

`tile_center(row, col) = grid_to_world(row, col) + Vector2(32, 32)`

**Output**: World pixel position for unit scene node placement.

**Example**: `tile_center(2, 3) = (224, 160)`.

### F4: is_coord_in_bounds

`is_coord_in_bounds(row, col) = (0 ≤ row < map_rows) AND (0 ≤ col < map_cols)`

**Output**: `true` iff coordinate is within the map rectangle. Used by `get_neighbors` to filter edge tiles and by UI to reject out-of-bounds clicks.

### F5: neighbor_offsets

`NEIGHBOR_OFFSETS = [(-1, 0), (1, 0), (0, -1), (0, 1)]`

4 cardinal von Neumann offsets in order: up, down, left, right. `get_neighbors(coord)` adds each to `coord` and retains only in-bounds results.

> **What belongs elsewhere**: Manhattan distance (`|r1−r2| + |c1−c2|`) belongs to Movement (BFS heuristic). Path cost belongs to Movement. Chebyshev distance is out of scope.

## Edge Cases

- **If `world_to_grid` receives negative pixel values**: returns negative row/col index. Callers must check `is_coord_in_bounds` before use — consistent with F2's unbounded-output contract.

- **If `grid_to_world` receives out-of-bounds coordinates**: returns the pixel position that tile *would* have if it existed (no clamping). Callers own bounds checking — consistent with F1.

- **If `place_unit(unit, coord)` receives an out-of-bounds or non-walkable coord**: rejects with an error signal and returns `false`. No occupancy change.

- **If `place_unit(unit, coord)` receives an already-occupied coord**: rejects and returns `false`. The existing unit is not displaced.

- **If `remove_unit(coord)` is called on an empty tile**: emits a warning via `push_warning()` and returns `false`. `Dictionary.erase()` itself is a no-op on missing keys, but the warning surfaces the caller bug.

- **If `unit.grid_position` and `_occupancy` desync** (e.g., partial move failure): no runtime detection in MVP. The Movement system owns both writes; a single atomic `move_unit(unit, from, to)` method on Map eliminates the desync window. Movement GDD must call this method instead of separate `place/remove` calls.

- **If a pixel lies exactly on a tile boundary** (e.g., `x = 64.0`): `floor()` resolves to the higher-index tile. IEEE 754 precision near exact multiples of 64 is reliable for SRPG-typical coordinate ranges (< 2048px).

- **If `get_neighbors` is called on a corner tile**: returns 2 neighbors. An edge tile returns 3. All 4 offsets are checked against `is_coord_in_bounds`.

- **If CSV header declares dimensions outside [8, 32]**: map load fails with an error message stating the allowed range and the actual value.

- **If CSV row/column count does not match the header**: map load fails with an error message stating expected vs actual dimensions.

- **If CSV contains a character other than `.`, `#`, or `O`**: map load fails with an error message stating the invalid character and its position (row, col).

- **If CSV file is missing or unreadable**: map load fails with an error message stating the file path and OS error.

- **If all tiles are blocked/obstacle**: map loads successfully (valid degenerate state). Unit placement phase will have no valid positions — this is a design-time map error, not a runtime crash. The Map system does not enforce "at least one walkable tile" at the data layer.

## Dependencies

Map / Coordinates is the Foundation layer — it has no upstream dependencies.

### Downstream Dependencies (systems that depend on Map)

| System | Dependency Type | Interface Required | Notes |
|--------|----------------|--------------------|-------|
| **Unit** | Hard | `grid_to_world()` | Unit placement needs pixel positions from grid coords |
| **Movement** | Hard | `is_walkable()`, `get_neighbors()`, `place_unit()`, `remove_unit()` | BFS traversal + occupancy writes |
| **Attack** | Hard | `get_neighbors()`, `get_unit_at()` | Range ring computation + target validation |
| **UI / Input** | Hard | `world_to_grid()`, `grid_to_world()`, tile state query | Click→tile resolution, highlight placement, color selection |

All four dependencies are **hard** — the downstream system cannot function without Map.

### External Dependencies

| Dependency | Type | Notes |
|------------|------|-------|
| `TileMapLayer` (Godot 4.6) | Engine | Rendering node. Loose-coupled — replaceable without changing Map's logic interface. |
| CSV map files (`assets/data/maps/`) | Data | Pillar 1 compliance. Map loads from external data, not from a pre-painted scene. |
| TileSet resource (.tres) | Asset | Three atlas tiles for the three tile states. Created once, reused across all maps. |

## Tuning Knobs

| Knob | Location | Safe Range | What Happens If Too Low | What Happens If Too High | Notes |
|------|----------|------------|------------------------|------------------------|-------|
| `map_cols` | CSV header | [8, 32] | Tactical depth evaporates — fewer than 8 columns make flanking impossible | BFS over 32×32 is still <1ms, but screen space exceeds 2048px (no scrolling implemented in MVP) | Per-map configurable |
| `map_rows` | CSV header | [8, 32] | Same as cols — vertical space too cramped | Same as cols — vertical scroll needed past 2048px | Per-map configurable |
| `TILE_SIZE` | Art bible constant | [32, 128] | Below 32px: tiles become hard to click precisely | Above 128px: 16×12 map exceeds 2048px on the larger axis, units appear tiny relative to tiles | Locked at 64 for MVP. Changing this requires TileSet rebuild + art bible update. |
| Per-tile state | CSV grid cells | `.` `#` `O` only | N/A | N/A | Three states only at MVP. Future terrain types (Tier 2) add characters to this set. |

**Knob interactions**: `map_cols × TILE_SIZE` determines total pixel width. If `map_cols` is increased, `TILE_SIZE` may need reduction to fit the screen, and vice versa. These two knobs should be tuned together against the target resolution (1920×1080 for MVP).

## Visual/Audio Requirements

[To be designed]

## UI Requirements

[To be designed]

## Acceptance Criteria

### Core Rules

**AC-C1 — Grid bounds**
GIVEN a Map loading from CSV, WHEN the CSV header row is `16,12`, THEN the grid is 16×12. WHEN the header specifies dimensions outside [8,32], THEN map load fails with an error message stating the range and actual value.

**AC-C2 — Coordinate orientation**
GIVEN a loaded map with TILE_SIZE=64, WHEN `grid_to_world(0,0)` is called, THEN it returns `Vector2(0,0)`. WHEN `grid_to_world(1,0)` and `grid_to_world(0,1)` are called, THEN row increase moves Y downward and column increase moves X rightward by exactly 64px each.

**AC-C3 — von Neumann adjacency**
GIVEN a central tile, WHEN `get_neighbors(row,col)` is called, THEN the result contains exactly four cardinal-direction coordinates and zero diagonals.

**AC-C4 — Tile state immutability**
GIVEN a loaded map, WHEN any tile's state is re-queried after load, THEN every tile matches its CSV value and no public API exists to mutate tile state.

**AC-C5 — GridSpace conversion accuracy**
GIVEN a `GridSpace` instance, WHEN `world_to_grid(Vector2(215, 150))` is called, THEN it returns `Vector2i(2, 3)`. WHEN `grid_to_world(Vector2i(2, 3))` is called, THEN it returns `Vector2(192, 128)`.

**AC-C6 — CSV mapping**
GIVEN a CSV using `.`, `#`, `O` characters, WHEN the map loads, THEN `.` → walkable, `#` → blocked, `O` → obstacle.

**AC-C7 — Empty TileMapLayer at scene root**
GIVEN the Map scene file, WHEN inspected, THEN the TileMapLayer node contains zero pre-painted cells. WHEN `_ready()` runs, THEN `set_cell()` is invoked once per CSV cell.

**AC-C8 — is_walkable dual check**
GIVEN an empty walkable tile, WHEN `is_walkable(coord)` is called, THEN `true`. GIVEN that tile after `place_unit` succeeds, WHEN re-queried, THEN `false`. GIVEN a blocked or obstacle tile, WHEN queried, THEN `false` regardless of occupancy.

**AC-C9 — get_neighbors bounds only**
GIVEN corner tile `(0,0)`, WHEN `get_neighbors(0,0)` is called, THEN exactly 2 coords returned (down and right), both in-bounds, and blocked neighbors ARE included.

**AC-C10 — place_unit rejection**
GIVEN an out-of-bounds, non-walkable, or occupied coord, WHEN `place_unit(unit, coord)` is called, THEN it returns `false` and occupancy is unchanged.

**AC-C11 — remove_unit on empty tile**
GIVEN an empty tile, WHEN `remove_unit(coord)` is called, THEN `push_warning()` is emitted and it returns `false`.

**AC-C12 — CSV validation errors**
GIVEN a CSV with mismatched row/col count, unknown characters, or a missing file, WHEN the map attempts to load, THEN it fails with a specific error message identifying the problem.

### Formulas

**AC-F1 — grid_to_world**
GIVEN row=2, col=3, TILE_SIZE=64, WHEN `grid_to_world(2,3)` is evaluated, THEN `Vector2(192, 128)` — i.e. `(col*64, row*64)`.

**AC-F2 — world_to_grid**
GIVEN pixel (215, 150), WHEN `world_to_grid(215, 150)` is evaluated, THEN `Vector2i(2, 3)` — i.e. `(floor(150/64), floor(215/64))`.

**AC-F3 — tile_center**
GIVEN row=2, col=3, WHEN `tile_center(2,3)` is evaluated, THEN `Vector2(224, 160)` — matching `grid_to_world + Vector2(32,32)`.

**AC-F4 — is_coord_in_bounds**
GIVEN a 16×12 map: `(0,0)` → `true`, `(15,11)` → `true`, `(-1,0)` → `false`, `(0,12)` → `false`.

**AC-F5 — NEIGHBOR_OFFSETS constant**
GIVEN the constant, WHEN inspected, THEN its value is exactly `[(-1,0),(1,0),(0,-1),(0,1)]`.

> **Note**: "No inline `* 64` math outside GridSpace" is a code-review enforcement rule, not a runtime AC. It belongs in the project's Forbidden Patterns, not this GDD.

## Open Questions

- **OQ1 — CI grep gate for coordinate math enforcement**: The rule "no inline `* 64` or `/ 64` outside GridSpace" is a code-review constraint, not a runtime test. Should a CI grep check be added to the project's Forbidden Patterns? → Defer to `/architecture-decision` when establishing the CI pipeline.

- **OQ2 — GridSpace as RefCounted with dependency injection**: The gameplay-programmer recommended GridSpace as a plain `RefCounted` (not an Autoload) to preserve testability. This is an architectural decision. → Defer to `/architecture-decision` for the Map system ADR.

- **OQ3 — Atomic move_unit vs separate place/remove**: The Edge Cases section notes that separate `place_unit`/`remove_unit` calls create a desync window. A single `move_unit(unit, from, to)` method on Map would eliminate this. → Movement GDD must use this interface; Map GDD adds it to the interface spec.

- **OQ4 — All-blocked map detection**: An all-blocked map loads successfully (valid degenerate state) but has no unit placement positions. Should the Map system warn on load if zero walkable tiles exist? → Defer to Unit GDD (unit placement phase will naturally fail — no special detection needed at Map level unless Unit GDD requests it).
