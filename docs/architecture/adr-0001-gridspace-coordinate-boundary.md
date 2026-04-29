# ADR-0001: GridSpace — Coordinate Transform Boundary

## Status
Accepted

## Date
2026-04-30

## Engine Compatibility

| Field | Value |
|-------|-------|
| **Engine** | Godot 4.6.2-stable |
| **Domain** | Core (coordinate transforms, Map integration) |
| **Knowledge Risk** | LOW — all APIs stable since Godot 4.0 |
| **References Consulted** | `docs/engine-reference/godot/VERSION.md`, `docs/engine-reference/godot/breaking-changes.md`, `docs/engine-reference/godot/deprecated-apis.md`, `docs/engine-reference/godot/modules/ui.md` |
| **Post-Cutoff APIs Used** | None |
| **Verification Required** | None |

## ADR Dependencies

| Field | Value |
|-------|-------|
| **Depends On** | None (Foundation layer — no upstream ADRs) |
| **Enables** | ADR-0002 (DI Architecture — establishes the first DI-managed RefCounted), ADR-0003 (Unit Interface — Unit placement uses GridSpace) |
| **Blocks** | All Map/Unit/Movement/Attack/UI epics — must be Accepted before any system that consumes grid coordinates can be implemented |
| **Ordering Note** | Must be written and Accepted first, before any other ADR |

## Context

### Problem Statement

The SRPG grid uses two coordinate spaces: grid coordinates `(row, col)` and world pixel coordinates `(x, y)`. Without a single authoritative conversion boundary, `position * 64` and `position / 64` math leaks into rendering code, UI, BFS, and attack range checks. This creates a brittle codebase where changing `TILE_SIZE` from 64 to any other value requires finding and updating every inline multiplication — a violation of Pillar 2 (System Orthogonality). The Game Concept document identifies this as Technical Risk R4 and mandates a single named boundary.

### Constraints

- Map GDD already defines `GridSpace` as the authority for `world_to_grid` / `grid_to_world`
- All 7 downstream systems consume grid coordinates — the interface must be stable
- MVP uses `TILE_SIZE = 64` (locked by art bible)
- Project standard: RefCounted + DI over Autoloads (established in architecture.md Principle 1)
- Forbidden pattern: inline coordinate math outside GridSpace must be enforceable

### Requirements

- Must provide `world_to_grid(Vector2) → Vector2i` — pixel to grid coordinate
- Must provide `grid_to_world(Vector2i) → Vector2` — grid to tile top-left pixel
- Must provide `tile_center(Vector2i) → Vector2` — grid to tile center (common placement target)
- Must encapsulate `TILE_SIZE` constant — no other file may reference it directly
- Must be usable by RefCounted logic objects (MovementResolver, AttackResolver) that have no Node access
- Must be testable in isolation without a running scene tree

## Decision

**GridSpace is a `RefCounted` class created by Map and passed to all consumers via dependency injection.** It is the sole location in the codebase that performs coordinate conversion math involving `TILE_SIZE`.

### Implementation

```gdscript
# src/core/grid_space.gd
class_name GridSpace extends RefCounted

const TILE_SIZE: int = 64

func world_to_grid(world_pos: Vector2) -> Vector2i:
    return Vector2i(floori(world_pos.y / TILE_SIZE), floori(world_pos.x / TILE_SIZE))

func grid_to_world(grid_pos: Vector2i) -> Vector2:
    return Vector2(grid_pos.y * TILE_SIZE, grid_pos.x * TILE_SIZE)

func tile_center(grid_pos: Vector2i) -> Vector2:
    return grid_to_world(grid_pos) + Vector2(TILE_SIZE / 2.0, TILE_SIZE / 2.0)
```

### Ownership and Distribution

```
Game scene (_ready):
  1. Map creates GridSpace.new()
  2. Map stores reference for its own use
  3. Map passes GridSpace to Unit (for placement via tile_center)
  4. Game passes GridSpace to InputHandler (for click→grid resolution)
  5. Game passes GridSpace to HighlightLayers (for draw_rect positioning)
  6. MovementResolver, AttackResolver, VictoryChecker, TurnManager do NOT
     receive GridSpace — they work in grid coordinates only
```

### Forbidden Pattern

```
# FORBIDDEN anywhere outside GridSpace:
var pixel_x = col * 64         # ✗ — use GridSpace.grid_to_world()
var grid_col = pixel_x / 64    # ✗ — use GridSpace.world_to_grid()
var TILE_SIZE = 64             # ✗ — duplicate constant definition
```

Enforcement: documented in `.claude/docs/technical-preferences.md` Forbidden Patterns. CI grep gate deferred to CI pipeline setup.

### Why RefCounted, Not Autoload

- GridSpace is not a service — it's a data object owned by Map
- Map is the authority on grid topology; GridSpace is a utility it provides
- DI makes dependencies explicit in constructor signatures (testability)
- Autoload would create a global singleton that Map doesn't control — if TILE_SIZE ever becomes per-map (Tier 2+), the Autoload pattern breaks

## Alternatives Considered

### Alternative 1: Autoload GridSpace Singleton

- **Description**: `GridSpace` as an Autoload, accessible globally via `GridSpace.world_to_grid()`
- **Pros**: Zero wiring; any system can call it without DI setup
- **Cons**: Violates project DI standard; creates hidden dependency; cannot support per-map TILE_SIZE in future; complicates unit testing (global state)
- **Rejection Reason**: Project architecture explicitly rejects Autoloads for logic objects. DI pattern costs one extra constructor parameter — negligible vs. the long-term coupling cost.

### Alternative 2: Each System Does Its Own Conversion

- **Description**: No shared GridSpace; each system that needs pixel coordinates imports a shared `TILE_SIZE` constant and does its own math
- **Pros**: No extra class; no wiring
- **Cons**: Violates Pillar 2 (System Orthogonality); changing TILE_SIZE requires touching N files; Game Concept Risk R4 explicitly warns against this; code review burden (must check every `*64` occurrence)
- **Rejection Reason**: This is the exact anti-pattern the architecture is designed to prevent. Centralizing the transform is non-negotiable per the Game Concept document.

### Alternative 3: GridSpace as a Static Utility Class (no instantiation)

- **Description**: All methods are `static`; `TILE_SIZE` is a `const` on the class
- **Pros**: No instance needed; zero wiring; call as `GridSpace.world_to_grid(pos)`
- **Cons**: Hardcoded `TILE_SIZE` — if per-map tile sizes are ever needed (Tier 2+), static const cannot vary; less testable (cannot inject a mock with different TILE_SIZE); GoF Singleton in disguise
- **Rejection Reason**: Instance-based design costs nothing (one `GridSpace.new()` call) and keeps the door open for per-map configuration. Static utility is premature optimization.

## Consequences

### Positive

- Single point of change: modifying `TILE_SIZE` requires editing exactly one file
- Testable: unit tests can create a GridSpace and verify `world_to_grid`/`grid_to_world` roundtrip
- Explicit dependencies: every consumer declares its need for coordinate conversion in its constructor
- CI-enforceable: a grep for `[*\/]\s*64` in game code (excluding GridSpace) catches violations

### Negative

- One extra constructor parameter for consumers that need pixel coordinates (InputHandler, HighlightLayer)
- Slight indirection: `grid_space.world_to_grid(pos)` vs. inline `pos / 64` (intentional — the indirection is the point)

### Risks

- **Risk**: `Vector2i` constructor swapped x/y — `Vector2i(x, y)` where x is column, but grid uses (row, col).
  - **Mitigation**: `world_to_grid` correctly maps `floori(y/64)` → row (`.y`), `floori(x/64)` → col (`.x`). `grid_to_world` maps `col` → `.x`, `row` → `.y`. Both are internally consistent and roundtrip-safe. Unit test AC verifies roundtrip.

## GDD Requirements Addressed

| GDD System | Requirement | How This ADR Addresses It |
|------------|-------------|--------------------------|
| map.md | Core Rule 5: GridSpace as sole coordinate transform authority | Defines the exact class, methods, and ownership |
| map.md | F1: `grid_to_world(row, col) = (col * TILE_SIZE, row * TILE_SIZE)` | Implemented as `grid_to_world(Vector2i) → Vector2` |
| map.md | F2: `world_to_grid(x, y) = (floor(y/TILE_SIZE), floor(x/TILE_SIZE))` | Implemented as `world_to_grid(Vector2) → Vector2i` |
| map.md | F3: `tile_center = grid_to_world + Vector2(32, 32)` | Implemented as `tile_center(Vector2i) → Vector2` |
| map.md | Edge Case: "GridSpace 之外不得出现内联 `* 64` 运算" | Codified as Forbidden Pattern with CI grep gate |
| game-concept.md | Risk R4: coordinate conversion leakage | Explicitly prevented by this ADR's boundary |
| movement.md | UI Requirements: highlight rendering uses `grid_to_world()` | GridSpace provides this method |
| ui.md | A1: click→grid resolution via `world_to_grid()` | GridSpace provides this method |

## Performance Implications

- **CPU**: Negligible — two integer divisions and one multiplication per call. BFS may call `grid_to_world()` for draw_rect positioning (~85 calls max for MOV=6), totaling <0.1ms.
- **Memory**: One `GridSpace` instance (negligible — one const int + vtable pointer).
- **Load Time**: Zero impact.

## Migration Plan

This is a greenfield decision — no existing code to migrate. Implementation order:
1. Create `src/core/grid_space.gd` with the class definition
2. Add Forbidden Pattern to `.claude/docs/technical-preferences.md`
3. Map._ready() creates GridSpace instance
4. All subsequent systems receive GridSpace via constructor injection

## Validation Criteria

- [ ] `grid_to_world(2, 3)` returns `Vector2(192, 128)` — matches Map GDD AC-F1
- [ ] `world_to_grid(215, 150)` returns `Vector2i(2, 3)` — matches Map GDD AC-F2
- [ ] `tile_center(2, 3)` returns `Vector2(224, 160)` — matches Map GDD AC-F3
- [ ] Roundtrip: `world_to_grid(grid_to_world(pos)) == pos` for all valid grid positions
- [ ] Grep for `* 64` and `/ 64` in `src/` (excluding `grid_space.gd`) returns zero results

## Related Decisions

- ADR-0002: Dependency Injection Architecture (establishes the DI pattern GridSpace follows)
- ADR-0003: Unit Public Interface (Unit placement uses `tile_center()`)
- `design/gdd/map.md` — Map GDD (defines GridSpace requirements)
- `design/gdd/game-concept.md` — Risk R4 (motivates this ADR)
