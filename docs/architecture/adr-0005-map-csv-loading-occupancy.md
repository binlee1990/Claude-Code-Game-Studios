# ADR-0005: Map CSV Loading Format & Occupancy Tracking

## Status
Accepted

## Date
2026-04-30

## Engine Compatibility

| Field | Value |
|-------|-------|
| **Engine** | Godot 4.6.2-stable |
| **Domain** | Foundation (data loading, grid topology, occupancy) |
| **Knowledge Risk** | LOW — `ResourceLoader`, `FileAccess`, `Dictionary`, `TileMapLayer.set_cell()` all stable since 4.0 |
| **References Consulted** | `docs/engine-reference/godot/VERSION.md`, `docs/engine-reference/godot/deprecated-apis.md`, `docs/engine-reference/godot/current-best-practices.md` |
| **Post-Cutoff APIs Used** | None |
| **Verification Required** | None |

## ADR Dependencies

| Field | Value |
|-------|-------|
| **Depends On** | ADR-0001 (GridSpace — coordinate transform authority), ADR-0002 (DI Architecture — Map follows DI pattern) |
| **Enables** | ADR-0006 (Movement — consumes `get_neighbors`, `is_walkable`, `move_unit`), ADR-0007 (Attack — consumes `get_unit_at`), ADR-0008 (AI — consumes Map topology via WorldState), UI (consumes all Map queries) |
| **Blocks** | Map, Movement, Attack, AI, UI epics — no system can function without Map providing grid topology + occupancy |
| **Ordering Note** | Must be Accepted fifth (after ADR-0001–0004), before any Feature-layer ADR that references Map topology |

## Context

### Problem Statement

Map is the Foundation layer — all 7 downstream systems depend on it for grid topology, walkability, and occupancy queries. Without a codified data format and loading procedure, each system would need to independently parse and validate the map, or worse, rely on hardcoded grid layouts. The Map GDD specifies CSV loading, three tile states, 4-directional neighbor queries, and runtime occupancy tracking — but does not define the implementation contract. This ADR codifies the Map's complete data contract: CSV format, validation rules, occupancy data structure, and atomic move operation.

### Constraints

- Map data must be external (CSV in `assets/data/maps/`) — Pillar 1 (Data-Driven)
- Tile states are immutable after load (no terrain destruction in MVP)
- Occupancy is mutable and must stay consistent with `unit.grid_position`
- `move_unit()` must be atomic — no partial update window between `remove_unit` and `place_unit`
- Map is a `Node2D` scene (needs `TileMapLayer` child for rendering), not a pure RefCounted
- Dimensions: [8, 32] per axis
- MVP uses single TileMapLayer (Godot 4.3+ standard)

### Requirements

- CSV format: header `cols,rows` then per-cell characters (`.` walkable, `#` blocked, `O` obstacle)
- Validation on load: dimension range, row/col count match, valid characters only, file exists
- Occupancy tracking: `Dictionary[Vector2i, Unit]` for O(1) `get_unit_at()` lookup
- `is_walkable(coord)` must check BOTH tile state AND occupancy
- `get_neighbors(coord)` returns 4 cardinal directions, in-bounds only, does NOT filter walkability
- `place_unit(unit, coord)` / `remove_unit(coord)` / `move_unit(unit, from, to)` with validation
- Map scene: empty `TileMapLayer` node populated at `_ready()` via `set_cell()`

## Decision

**Map loads grid topology from a CSV file in `assets/data/maps/`. Validation fails fast with explicit error messages on dimension mismatch, invalid characters, or missing files. Runtime occupancy is tracked in a `Dictionary[Vector2i, Unit]`. `move_unit(unit, from, to)` is the sole atomic position-update operation — it updates both occupancy dict and `unit.grid_position` in one call, eliminating the desync window between separate `place`/`remove` calls.**

### CSV Format

```csv
16,12
................
................
....##....##....
....##....##....
................
................
....##..........
....##..........
................
................
........##......
........##......
................
```

- Line 1: `cols,rows` (no whitespace). `cols` = horizontal count, `rows` = vertical count.
- Lines 2+: one character per cell, exactly `cols` characters per line, exactly `rows` data lines.
- Characters: `.` = walkable, `#` = blocked, `O` = obstacle.
- No trailing whitespace. No comments. UTF-8 encoding.

### Map Class Interface

```gdscript
# src/map/map.gd
class_name Map extends Node2D

# ── Tile States (immutable after load) ──
enum TileState { WALKABLE, BLOCKED, OBSTACLE }

# ── Internal ──
var _grid_space: GridSpace                     # DI from ADR-0001
var _tile_states: Dictionary[Vector2i, TileState] = {}
var _occupancy: Dictionary[Vector2i, Unit] = {}
var _cols: int = 0
var _rows: int = 0

# ── Initialization ──
func initialize(grid_space: GridSpace, map_name: String) -> void:
    _grid_space = grid_space
    _load_csv("res://assets/data/maps/%s.csv" % map_name)
    _render_tiles()

# ── Public Queries ──
func is_coord_in_bounds(coord: Vector2i) -> bool:
    return coord.x >= 0 and coord.x < _rows and coord.y >= 0 and coord.y < _cols

func get_tile_state(coord: Vector2i) -> TileState:
    return _tile_states.get(coord, TileState.BLOCKED)  # out-of-bounds = blocked

func is_walkable(coord: Vector2i) -> bool:
    if not is_coord_in_bounds(coord): return false
    if _tile_states.get(coord) != TileState.WALKABLE: return false
    if _occupancy.has(coord): return false
    return true

func get_neighbors(coord: Vector2i) -> Array[Vector2i]:
    var result: Array[Vector2i] = []
    for offset in NEIGHBOR_OFFSETS:
        var neighbor := coord + offset
        if is_coord_in_bounds(neighbor):
            result.append(neighbor)
    return result

func get_unit_at(coord: Vector2i) -> Unit:
    return _occupancy.get(coord, null)

func get_dimensions() -> Dictionary:
    return { "cols": _cols, "rows": _rows }

# ── Occupancy Mutations ──
func place_unit(unit: Unit, coord: Vector2i) -> bool:
    if not is_coord_in_bounds(coord): return false
    if _tile_states.get(coord) != TileState.WALKABLE: return false
    if _occupancy.has(coord): return false
    _occupancy[coord] = unit
    unit.grid_position = coord
    return true

func remove_unit(coord: Vector2i) -> bool:
    if not _occupancy.has(coord):
        push_warning("remove_unit: no unit at %s" % coord)
        return false
    _occupancy.erase(coord)
    return true

func move_unit(unit: Unit, from: Vector2i, to: Vector2i) -> bool:
    # Atomic: validate both from and to before any mutation
    if _occupancy.get(from) != unit:
        push_warning("move_unit: unit not at expected position %s" % from)
        return false
    if not is_coord_in_bounds(to): return false
    if _tile_states.get(to) != TileState.WALKABLE: return false
    if from != to and _occupancy.has(to): return false
    # Atomic update
    _occupancy.erase(from)
    _occupancy[to] = unit
    unit.grid_position = to
    return true

# ── Constants ──
const NEIGHBOR_OFFSETS: Array[Vector2i] = [
    Vector2i(-1, 0), Vector2i(1, 0),   # up, down
    Vector2i(0, -1), Vector2i(0, 1),    # left, right
]
```

### CSV Validation (in `_load_csv`)

```
1. FileAccess.open(csv_path, FileAccess.READ)
   → if null: push_error("Map CSV not found: %s" % csv_path); return

2. Header line: split on "," → [cols_str, rows_str]
   → assert both are valid ints
   → assert cols ∈ [8, 32] AND rows ∈ [8, 32]

3. For each data line (row r from 0 to rows-1):
   → assert line.length() == cols (no missing/extra chars)
   → For each char (col c from 0 to cols-1):
       → if '.' → _tile_states[Vector2i(r, c)] = TileState.WALKABLE
       → elif '#' → TileState.BLOCKED
       → elif 'O' → TileState.OBSTACLE
       → else → assert(false, "Invalid char '%s' at (%d,%d)" % [ch, r, c])

4. → assert exactly rows data lines were read (not fewer, not more)
```

### TileMapLayer Rendering (in `_render_tiles`)

```gdscript
func _render_tiles() -> void:
    var tilemap: TileMapLayer = %TileMapLayer
    tilemap.clear()
    for coord in _tile_states:
        var atlas_coords := _tile_state_to_atlas(_tile_states[coord])
        tilemap.set_cell(coord, 0, atlas_coords)  # layer 0
```

Three atlas tiles in the TileSet resource map to WALKABLE (#374151), BLOCKED (#111827), OBSTACLE (#1F2937).

### Design Rationale

**Why `Dictionary[Vector2i, Unit]` for occupancy**: O(1) lookup for `get_unit_at()` and `is_walkable()`. At MVP scale (~8 units), the alternative (iterating all units) is equally fast, but Dictionary establishes the pattern for larger maps. `Vector2i` is hashable in Godot 4.x.

**Why `move_unit()` is atomic**: Map GDD OQ3 and Movement GDD both identify the desync window between separate `remove_unit` + `place_unit` calls. If a BFS or death signal fires between the two, occupancy is temporarily inconsistent. Atomic `move_unit` eliminates this window entirely. `place_unit` and `remove_unit` remain available for unit creation (initial placement) and death (queue_free), but movement always routes through `move_unit`.

**Why `get_neighbors` does not filter walkability**: The BFS algorithm (Movement) needs raw topology to manage its own visited set. Filtering walkability in `get_neighbors` would make BFS visited-set tracking impossible (can't distinguish "blocked, not visited" from "walkable, already visited"). Each consumer (Movement BFS, AI pathfinding) applies its own filtering criteria.

**Why tile states are immutable after load**: MVP has no terrain destruction or modification. Immutability simplifies caching and eliminates mutation-tracking overhead. Tier 2 terrain effects will add a separate `_terrain_effects: Dictionary[Vector2i, TerrainModifier]` layer rather than mutating base tile states.

## Alternatives Considered

### Alternative 1: JSON Map Format

- **Description**: Map data as JSON with explicit tile objects: `{"cols": 16, "rows": 12, "tiles": [{"r": 0, "c": 0, "state": "walkable"}, ...]}`
- **Pros**: Self-documenting, extensible with per-tile metadata, standard parsing
- **Cons**: Verbose — a 16×12 grid is ~1.5KB of JSON vs ~200 bytes of CSV. Harder to visually edit (can't see the grid shape). Godot has no built-in JSON schema validation.
- **Rejection Reason**: CSV is git-diffable and visually editable — a map designer can see the grid shape in a text editor. MVP doesn't need per-tile metadata. JSON remains viable for Tier 2+ if terrain effects require per-tile properties.

### Alternative 2: Pre-Built TileMapLayer Scene (No CSV)

- **Description**: Design maps in the Godot editor using TileMapLayer's built-in painting tools. No CSV loading code.
- **Pros**: Visual editing, zero parsing code, uses engine-native workflow
- **Cons**: Binary .tscn files are not git-diffable. Map changes in PRs are opaque. Violates Pillar 1 (Data-Driven) — map data is embedded in a scene file, not an external data file.
- **Rejection Reason**: Pillar 1 requires all game data to be external and diffable. CSV is the simplest format that satisfies this constraint.

### Alternative 3: Separate Occupancy Layer (Array-Based)

- **Description**: Occupancy tracked as a 2D array `Array[Array]` indexed by row/col, parallel to tile states
- **Pros**: Direct indexing: `_occupancy[r][c]` — no Dictionary hashing overhead
- **Cons**: Sparse — at MVP scale (~8 units on 192 cells), 96% of the array is empty. Two parallel arrays must stay in sync (tile state + occupancy), creating a desync risk. Resize on map change requires reallocation.
- **Rejection Reason**: Dictionary[Vector2i, Unit] is O(1) for the operations that matter (point queries from BFS and attack range checks), uses memory proportional to unit count (not map size), and has no sync risk (single source of truth).

## Consequences

### Positive

- CSV maps are human-readable, git-diffable, and trivially editable in any text editor
- Validation fails fast with exact error location — no silent corruption
- `move_unit()` atomicity eliminates an entire class of occupancy desync bugs
- `get_neighbors` separation of topology from walkability enables correct BFS visited-set management
- `Dictionary[Vector2i, Unit]` scales with unit count, not map size

### Negative

- CSV format cannot express per-tile metadata (Tier 2 terrain effects will need an additional data layer)
- `move_unit()` adds a third occupancy mutation method alongside `place_unit`/`remove_unit` — but the three have clearly separated use cases (spawn, death, movement)
- TileMapLayer rendering adds ~192 `set_cell()` calls at load (negligible — <1ms)

### Risks

- **Risk**: CSV file has trailing whitespace or empty lines that break the row count check.
  - **Mitigation**: `_load_csv` strips trailing whitespace from each line and skips empty lines after the data section. Exact row count assertion catches mismatches.

- **Risk**: `move_unit` is called with `from` that doesn't match the unit's actual position (caller bug).
  - **Mitigation**: Assert `_occupancy.get(from) == unit`. Returns false on mismatch — no silent position corruption.

## GDD Requirements Addressed

| GDD System | Requirement | How This ADR Addresses It |
|------------|-------------|--------------------------|
| map.md | Core Rule 4: Three tile states | `TileState` enum + CSV character mapping |
| map.md | Core Rule 5: GridSpace boundary | `GridSpace` injected at `initialize()` per ADR-0001 |
| map.md | Core Rule 6: CSV data format | Full CSV format specification + `_load_csv()` procedure |
| map.md | Core Rule 7: Map loading procedure | `initialize()` → `_load_csv()` → `_render_tiles()` |
| map.md | Core Rule 8: Runtime occupancy | `Dictionary[Vector2i, Unit]` + `place/remove/move` |
| map.md | Core Rule 9: Neighbor query | `get_neighbors()` — 4-directional, in-bounds, no walkability filter |
| map.md | F1–F5: grid_to_world, world_to_grid, tile_center, is_coord_in_bounds, neighbor_offsets | Implemented via GridSpace (ADR-0001) + Map methods |
| map.md | Edge Case: Atomic move_unit | `move_unit(unit, from, to)` — validates from, atomically updates occupancy + position |
| map.md | Edge Cases: place/remove validation | `place_unit()` rejects out-of-bounds, blocked, occupied. `remove_unit()` warns on empty. |
| map.md | All CSV validation edge cases (dimensions, chars, missing file) | Explicit assertions with file+position in error messages |
| movement.md | Core Rule 4: move_unit atomic requirement | `move_unit()` codified as the sole movement entry point |
| game-concept.md | Pillar 1: Data-Driven | CSV external data file, loaded at runtime |
| game-concept.md | Pillar 2: System Orthogonality | Map exposes topology + occupancy as pure queries — no consumer knows CSV internals |

## Performance Implications

- **CPU**: CSV parsing ≈ O(cols×rows) = 192 iterations at default 16×12. <0.5ms at load time. `set_cell()` calls ≈ 192 per map. TileMapLayer batches these internally. `get_neighbors()` ≈ 4 bounds checks. `is_walkable()` ≈ 1 Dictionary lookup. All queries O(1).
- **Memory**: `_tile_states` Dictionary ≈ 192 entries × ~32 bytes ≈ 6KB. `_occupancy` Dictionary ≈ 8 entries × ~40 bytes ≈ 320 bytes. Negligible.
- **Load Time**: `FileAccess.open()` + 192-character parse <1ms.

## Migration Plan

Greenfield. Implementation order:
1. Create `src/map/map.gd` with the class interface defined in this ADR
2. Create `assets/data/maps/test_map.csv` (16×12, open field with two barrier lines)
3. Create TileSet resource with 3 atlas tiles (WALKABLE #374151, BLOCKED #111827, OBSTACLE #1F2937)
4. Create Map.tscn: Node2D root + TileMapLayer child (%TileMapLayer)
5. Wire in Game._ready() per ADR-0002 composition root pattern

## Validation Criteria

- [ ] CSV with `16,12` header + 12 lines of 16 chars loads successfully → 192 tile states populated
- [ ] CSV with `cols=33` (>32 max) → assert fails with dimension range message
- [ ] CSV with row count mismatch → assert fails with expected vs actual
- [ ] CSV with invalid character `X` → assert fails with char + position (r,c)
- [ ] CSV file missing → `push_error` with file path
- [ ] `is_walkable((0,0))` on walkable empty tile → `true`
- [ ] `is_walkable((0,0))` after `place_unit(u, (0,0))` → `false`
- [ ] `is_walkable((0,0))` on blocked tile → `false` regardless of occupancy
- [ ] `get_neighbors((0,0))` on 16×12 map → exactly 2 results: `(1,0)` and `(0,1)`
- [ ] `get_neighbors((5,5))` on interior tile → exactly 4 results
- [ ] `place_unit(u, blocked_coord)` → `false`, occupancy unchanged
- [ ] `place_unit(u, occupied_coord)` → `false`, original unit stays
- [ ] `move_unit(u, from, to)` with valid to → `true`, `_occupancy[to] == u`, `_occupancy` has no `from`
- [ ] `move_unit(u, wrong_from, to)` → `false`, push_warning, no state change
- [ ] `move_unit(u, from, occupied_to)` → `false`, unit stays at `from`
- [ ] `remove_unit(empty_coord)` → `false`, push_warning
- [ ] `get_unit_at(occupied_coord)` → correct Unit reference
- [ ] `get_unit_at(empty_coord)` → `null`

## Related Decisions

- ADR-0001: GridSpace Coordinate Boundary (Map creates and holds GridSpace)
- ADR-0002: Dependency Injection Architecture (Map initialization follows DI pattern)
- ADR-0006: Movement System (consumes `get_neighbors`, `is_walkable`, `move_unit`)
- ADR-0007: Attack System (consumes `get_unit_at`)
- `design/gdd/map.md` — Map GDD (authoritative design)
