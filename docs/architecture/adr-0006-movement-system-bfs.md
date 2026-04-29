# ADR-0006: Movement System — BFS + MovementResult

## Status
Accepted

## Date
2026-04-30

## Engine Compatibility

| Field | Value |
|-------|-------|
| **Engine** | Godot 4.6.2-stable |
| **Domain** | Feature (graph algorithm, pure computation) |
| **Knowledge Risk** | LOW — `RefCounted`, `Array`, `Dictionary`, `Vector2i` all stable since 4.0 |
| **References Consulted** | `docs/engine-reference/godot/VERSION.md`, `docs/engine-reference/godot/current-best-practices.md` |
| **Post-Cutoff APIs Used** | None |
| **Verification Required** | None |

## ADR Dependencies

| Field | Value |
|-------|-------|
| **Depends On** | ADR-0001 (GridSpace — coordinate system), ADR-0002 (DI Architecture — Resolver pattern), ADR-0003 (Unit Interface — reads `mov`, `grid_position`, `is_alive`), ADR-0005 (Map — consumes `get_neighbors`, `is_walkable`, `move_unit`) |
| **Enables** | ADR-0007 (Attack — shares Manhattan distance formula), ADR-0008 (AI — BasicAI calls `compute_reachable`), UI (consumes `MovementResult` for highlight rendering) |
| **Blocks** | Movement, Attack (Manhattan distance consumer), AI (Tier 2 BasicAI), UI (move highlight) epics |
| **Ordering Note** | Must be Accepted sixth (after ADR-0005), before Attack and AI ADRs that consume Movement's interfaces |

## Context

### Problem Statement

Movement is the player's primary verb in the SRPG core loop ("select → move → attack → grey out"). It requires BFS over a grid graph to compute reachable tiles, path reconstruction for hover preview, and clean data handoff to UI for highlight rendering. Without a codified Movement system ADR, the BFS algorithm, result data structure, and ownership of Manhattan distance (consumed by Attack for range checks) remain implementation details rather than architectural decisions. Movement is the first Feature-layer system — it establishes the "pure function resolver + immutable result" pattern that Attack and AI follow.

### Constraints

- BFS must operate on Map's grid topology (4-directional von Neumann) via the public Map interface
- Movement computation must be pure (no side effects on Map or Unit) — only Input writes via `Map.move_unit()`
- Result must be immutable to prevent accidental mutation by UI highlight rendering code
- Manhattan distance formula must have a single owner (Movement GDD F2) and be referenced by Attack GDD F2
- Performance: BFS on 32×32 grid with MOV=6 must complete in <1ms (Frame budget: 16.6ms)
- Must handle degenerate cases: dead unit, null Map, out-of-bounds start, MOV=0, all neighbors blocked

### Requirements

- `MovementResolver.compute_reachable(unit, map) → MovementResult` — pure function entry point
- BFS from `unit.grid_position`, max depth = `unit.mov`, filtering via `Map.is_walkable()`
- Start tile special-cased (unit occupies it — `is_walkable` returns false for occupied tiles)
- `MovementResult` exposes `get_reachable_tiles()`, `get_path_to(target)`, `get_distance_to(target)`, `get_start_tile()`
- Path reconstruction from BFS parent map: O(path_length) ≤ O(MOV) ≤ 6 lookups
- Manhattan distance: `|dr| + |dc|` — defined here, consumed by Attack

## Decision

**MovementResolver is a RefCounted pure function with a single entry point `compute_reachable(unit, map) → MovementResult`. BFS expands from the unit's grid position through Map's 4-directional neighbors, respecting walkability and occupancy, up to `unit.mov` depth. MovementResult is an immutable data object that lazily reconstructs paths from the BFS parent map. Manhattan distance is owned by Movement GDD F2 and referenced by Attack for range checks. MovementResolver does NOT execute movement — InputHandler calls `Map.move_unit()` after the player confirms a target tile.**

### MovementResolver

```gdscript
# src/movement/movement_resolver.gd
class_name MovementResolver extends RefCounted

func compute_reachable(unit: Unit, map: Map) -> MovementResult:
    # Null/error guards
    if unit == null or map == null or not unit.is_alive():
        return MovementResult.new(Vector2i(-1, -1), {}, {})
    
    var start: Vector2i = unit.grid_position
    if not map.is_coord_in_bounds(start):
        return MovementResult.new(start, {}, {})
    
    var mov: int = unit.mov
    if mov <= 0:
        var single: Dictionary = {}
        single[start] = 0
        return MovementResult.new(start, {}, single)  # parent empty; only start
    
    # BFS
    var parent: Dictionary[Vector2i, Vector2i] = {}
    var dist: Dictionary[Vector2i, int] = {}
    var queue: Array[Vector2i] = [start]
    dist[start] = 0
    
    while not queue.is_empty():
        var current: Vector2i = queue.pop_front()
        var current_dist: int = dist[current]
        
        if current_dist >= mov:
            continue  # max depth reached; don't expand further
        
        for neighbor in map.get_neighbors(current):
            if dist.has(neighbor):
                continue  # already visited
            if not map.is_walkable(neighbor) and neighbor != start:
                continue  # blocked or occupied (start is always "reachable")
            
            dist[neighbor] = current_dist + 1
            parent[neighbor] = current
            queue.append(neighbor)
    
    return MovementResult.new(start, parent, dist)
```

### MovementResult

```gdscript
# src/movement/movement_result.gd
class_name MovementResult extends RefCounted

var _start: Vector2i
var _parent: Dictionary[Vector2i, Vector2i]
var _dist: Dictionary[Vector2i, int]

func _init(start: Vector2i, parent: Dictionary[Vector2i, Vector2i], dist: Dictionary[Vector2i, int]) -> void:
    _start = start
    _parent = parent
    _dist = dist

func get_start_tile() -> Vector2i:
    return _start

func get_reachable_tiles() -> Array[Vector2i]:
    return _dist.keys()  # Returns all tiles with a distance entry

func get_path_to(target: Vector2i) -> Array[Vector2i]:
    if not _dist.has(target):
        return []
    if target == _start:
        return [_start]
    
    var path: Array[Vector2i] = [target]
    var current: Vector2i = target
    while current != _start:
        current = _parent.get(current, _start)  # fallback shouldn't trigger
        path.append(current)
    path.reverse()
    return path

func get_distance_to(target: Vector2i) -> int:
    return _dist.get(target, -1)
```

### Manhattan Distance Formula

```gdscript
# Owned by Movement system. Defined here; consumed by Attack (ADR-0007).
static func manhattan(a: Vector2i, b: Vector2i) -> int:
    return absi(a.x - b.x) + absi(a.y - b.y)
```

Placement: `MovementResolver` as a static method, or in a standalone `src/movement/manhattan.gd` utility. The static method approach keeps the formula co-located with the system that defines it while making it importable by Attack without instantiating a resolver.

> **Attack GDD F2 Boundary Note**: Attack references Manhattan distance for range checks (`in_range = manhattan(attacker, target) ≤ attacker.rng`). The formula is defined once in Movement and imported by Attack — no duplicate definition.

### Design Rationale

**Why BFS over A\* or Dijkstra**: MVP has uniform tile costs (all walkable tiles cost 1). BFS is optimal for uniform-cost grids — O(V+E) with no priority queue overhead. A* would add heuristic computation with zero benefit when all edges have equal weight. Tier 2 terrain costs will require Dijkstra (or BFS with cost-aware expansion), but the `compute_reachable` signature already supports this — only the internal algorithm changes.

**Why immutable MovementResult**: The result is consumed by UI highlight rendering (potentially across multiple frames of hover preview). If UI could mutate the result (e.g., accidentally modifying the tiles array), subsequent path queries would produce garbage. RefCounted + constructor-only field setting enforces immutability.

**Why path reconstruction is lazy (not pre-computed for all tiles)**: BFS produces O(N) parent pointers. Pre-computing paths for all ~85 tiles would be O(N × MOV) = ~510 array allocations at selection time. Lazy reconstruction computes only the path the player is hovering over — typically 1 path at a time, O(MOV) ≤ 6 lookups. Total path computation across a full hover session <0.1ms.

**Why map reference is per-call, not constructor-injected**: MovementResolver holds no state. Passing `map` per-call allows the same resolver instance to serve multiple units across different maps (Tier 3 multi-level). Constructor injection of Map would require one resolver-per-map — unnecessary coupling.

**Why MovementResolver does not execute movement**: Separation of computation from execution. BFS is read-only and side-effect-free — it can be called for preview without committing. Only InputHandler (with player confirmation) calls `Map.move_unit()`. This split enables AI to call `compute_reachable` for planning without accidentally moving units.

## Alternatives Considered

### Alternative 1: Movement as a Unit Method

- **Description**: `unit.get_reachable_tiles(map) → Array[Vector2i]` — BFS is a method on the Unit class
- **Pros**: Fewer classes; familiar OOP pattern
- **Cons**: Unit becomes responsible for graph algorithms — bloats the class (Unit already has 5 downstream consumers). Testing BFS requires a Unit instance with valid stats. Violates Single Responsibility.
- **Rejection Reason**: Movement computation is an independent algorithm, not a property of Unit. The pure function pattern (RefCounted resolver) is consistent with Attack, Victory, and AI.

### Alternative 2: Pre-Compute All Paths in MovementResult

- **Description**: BFS produces a `Dictionary[Vector2i, Array[Vector2i]]` mapping every reachable tile to its full path array
- **Pros**: Zero path reconstruction cost at hover time; simpler `get_path_to()` (just dictionary lookup)
- **Cons**: ~85 path arrays allocated at selection time, even if the player never hovers. Memory: ~85 × avg 3 tiles × 8 bytes ≈ 2KB (acceptable at MVP scale, but the allocation pattern is wasteful).
- **Rejection Reason**: Lazy reconstruction is O(MOV) ≤ 6 lookups — not a bottleneck. Pre-computation optimizes for a case (hovering all tiles) that almost never occurs. If profiling shows hover lag, this decision can be revisited with zero API change (internal optimization).

### Alternative 3: Manhattan Distance Owned by Attack

- **Description**: Attack GDD defines its own Manhattan distance formula; Movement uses BFS distance (not Manhattan)
- **Pros**: Each system owns its own distance metric; no cross-reference needed
- **Cons**: Two definitions of the same formula in different files — drift risk. Movement GDD already defines F2 (Manhattan) with Attack GDD F2 explicitly referencing it.
- **Rejection Reason**: Single source of truth. Manhattan distance is a geometric property of the grid, not of Attack. Movement GDD defined it first (design order 4 vs 5); Attack consumes it.

## Consequences

### Positive

- BFS is algorithmically optimal for uniform-cost grids
- MovementResult immutability prevents UI from corrupting path data
- Lazy path reconstruction minimizes allocation at selection time
- Manhattan distance has a single owner — no formula drift
- Pure function pattern enables unit testing without scene tree (instantiate resolver + mock Map + create Unit)
- Same pattern extends to tier 2 (Dijkstra for terrain costs) with zero interface change

### Negative

- MovementResolver must accept `map` parameter on every call (but this is intentional — stateless)
- `get_path_to()` returns `[]` for unreachable instead of raising an error — calling code must check (but GDScript convention favors empty returns over exceptions)
- Manhattan distance as static method means Attack must import Movement — a minor dependency (but the dependency already exists in the GDD dependency graph)

### Risks

- **Risk**: BFS performance degrades on very large maps (64×64 at Tier 3).
  - **Mitigation**: MOV is capped at 6. BFS visits at most ~85 tiles regardless of map size (limited by MOV depth, not map area). Map boundary is irrelevant to performance.
  
- **Risk**: `get_path_to()` returns a path that becomes invalid after a unit between BFS and move execution occupies a tile on the path.
  - **Mitigation**: `Map.move_unit()` is atomic and validates the target tile. If occupied, it returns false. InputHandler must re-compute BFS or show "tile occupied" feedback. This is documented in Movement GDD Edge Case (TOCTOU).

## GDD Requirements Addressed

| GDD System | Requirement | How This ADR Addresses It |
|------------|-------------|--------------------------|
| movement.md | Core Rule 1: BFS range computation | `compute_reachable()` — BFS over Map grid, start tile special-cased |
| movement.md | Core Rule 2: Reachable set definition | `MovementResult.get_reachable_tiles()` — all tiles with dist ≤ MOV, walkable + unoccupied |
| movement.md | Core Rule 3: Path calculation | `MovementResult.get_path_to()` — backtrack parent map, reverse |
| movement.md | Core Rule 4: Movement execution | Documented: InputHandler calls `Map.move_unit()` — Movement does NOT execute |
| movement.md | Core Rule 5: 0-step move (same tile) | Start tile is always in reachable set — confirmable as valid move |
| movement.md | Core Rule 6: Post-move state | Documented: InputHandler sets `action_state = MOVED` after `move_unit()` |
| movement.md | Core Rule 7: Hover preview | `get_path_to(tile)` returns data; UI renders |
| movement.md | F1: BFS reachable set formula | Codified in BFS algorithm |
| movement.md | F2: Manhattan distance | `manhattan(a, b) = absi(a.x-b.x) + absi(a.y-b.y)` — owned here |
| movement.md | F3: Path steps | `get_distance_to(target)` = BFS distance from start |
| movement.md | All edge cases (dead unit, null map, OOB, MOV=0, all blocked) | Null guards + empty result returns |
| attack.md | F2: Range check via Manhattan | References Movement's `manhattan()` |
| attack.md | Dependencies: Manhattan distance ownership | Resolved — single owner (Movement), single consumer (Attack) |
| game-concept.md | Pillar 2: System Orthogonality | Pure function, no side effects, explicit Map dependency via parameter |

## Performance Implications

- **CPU**: BFS on 32×32 grid, MOV=6: at most 85 tiles visited, each with 4 neighbor checks = ~340 iterations. GDScript BFS <0.5ms (well within 16.6ms frame budget). Path reconstruction: O(MOV) ≤ 6 Dictionary lookups per hover — negligible.
- **Memory**: `MovementResult`: 2 Dictionaries (parent + dist) × ~85 entries each × ~40 bytes ≈ 7KB. Allocated once per unit selection, GC'd on deselection. At MVP scale (1 selected unit at a time), this is <10KB peak.
- **Load Time**: No impact — `MovementResolver` is instantiated at Game._ready(), zero initialization cost.

## Migration Plan

Greenfield. Implementation order:
1. Create `src/movement/movement_resolver.gd` with BFS algorithm
2. Create `src/movement/movement_result.gd` with immutable result + path reconstruction
3. Add `manhattan()` static method to MovementResolver
4. Wire in Game._ready() per ADR-0002: `var movement_resolver := MovementResolver.new()`
5. Inject into InputHandler for `compute_reachable()` calls on unit selection
6. Unit test BFS on known grid configurations (open, blocked, occupied, corner, MOV=0)

## Validation Criteria

- [ ] Open 5×5 grid, unit at (2,2), MOV=2 → 13 reachable tiles (Manhattan distance ≤ 2)
- [ ] Unit at (2,2), MOV=2, tile (1,1) occupied → (1,1) and (1,2) excluded (path blocked)
- [ ] Unit at (0,0) on 8×8, MOV=3 → reachable tiles clipped by map boundary
- [ ] `get_path_to((0,3))` returns `[(0,0), (0,1), (0,2), (0,3)]` (4 elements, start→target inclusive)
- [ ] `get_path_to(start_tile)` returns `[start_tile]` (single element)
- [ ] `get_path_to(unreachable_tile)` returns `[]`
- [ ] `get_distance_to(start_tile)` returns 0
- [ ] `get_distance_to(unreachable_tile)` returns -1
- [ ] Dead unit → `get_reachable_tiles()` returns `[]`
- [ ] null Map → `get_reachable_tiles()` returns `[]`
- [ ] MOV=0 → reachable set = `{start_tile}` only
- [ ] All neighbors blocked → reachable set = `{start_tile}` only
- [ ] 32×32 open grid, center, MOV=6 → ~85 tiles, execution time <1ms
- [ ] `manhattan((0,0), (3,4))` = 7; `manhattan((2,3), (2,3))` = 0
- [ ] BFS result is deterministic (same input → same tile set + same paths)

## Related Decisions

- ADR-0001: GridSpace Coordinate Boundary (Map topology uses GridSpace)
- ADR-0002: Dependency Injection Architecture (Resolver pattern)
- ADR-0003: Unit Public Interface (reads `mov`, `grid_position`, `is_alive`)
- ADR-0005: Map CSV Loading & Occupancy (consumes `get_neighbors`, `is_walkable`, `move_unit`)
- ADR-0007: Attack System (references Manhattan distance)
- ADR-0008: AI Controller Interface (BasicAI calls `compute_reachable`)
- `design/gdd/movement.md` — Movement GDD (authoritative design)
