# Story 004: Weighted Terrain Movement — cost-aware reachability and paths

> **Epic**: Movement
> **Status**: Done
> **Layer**: Feature
> **Type**: Logic

## Context

MVP movement used uniform-cost BFS because every walkable tile cost 1. Sprint 9 adds rough terrain with cost 2, so reachability must be based on total movement cost while keeping the same public MovementResult contract.

## Acceptance Criteria

- [x] All-walkable maps preserve prior reachable counts.
- [x] Movement budget is consumed by `Map.get_movement_cost(coord)`.
- [x] Rough terrain requires enough remaining movement budget to enter.
- [x] Tiles beyond rough terrain are excluded when total cost exceeds `unit.mov`.
- [x] `MovementResult.get_distance_to()` returns total movement cost.
- [x] `MovementResult.get_path_to()` reconstructs the lowest-cost known path.
- [x] Movement remains pure and does not mutate Map or Unit.

## Test Evidence

- `tests/unit/movement/movement_bfs_test.gd`
- `tests/unit/movement/movement_result_test.gd`
- Full runner: `Total Passed: 297`; zero script errors, assertion failures, error lines, or warnings observed.

## Out of Scope

- Per-unit terrain affinities.
- Terrain costs above 2.
- UI explanation of terrain costs.
