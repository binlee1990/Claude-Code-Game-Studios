# Story 001: BFS 可达范围计算 + Manhattan 距离

> **Epic**: Movement | **Status**: Ready | **Layer**: Feature | **Type**: Logic

## Context
**GDD**: `design/gdd/movement.md` | **Requirement**: `TR-mov-001`, `TR-mov-005`
**ADR**: ADR-0006: Movement BFS | **Engine**: Godot 4.6.2 | **Risk**: LOW

## Acceptance Criteria
- [ ] **AC-MOVE-001**: 开阔网格上 BFS 按 mov 步数限制正确计算可达瓦片
- [ ] **AC-MOVE-002**: BFS 正确避开 blocked/obstacle/已占用瓦片
- [ ] **AC-MOVE-003**: 起始瓦片始终在可达集中（0 步）
- [ ] **AC-MOVE-010**: BFS 距离层与步数一致
- [ ] **AC-MOVE-011**: Manhattan 距离 `|r1-r2| + |c1-c2|` 正确计算
- [ ] **AC-MOVE-021**: 地图边界裁剪（角落瓦片仅 2 邻居）
- [ ] **AC-MOVE-022**: 除起始瓦片外全阻挡→可达集仅起始瓦片
- [ ] **AC-MOVE-023**: 性能：32×32 网格 MOV=6 时 BFS <1ms

## Implementation Notes
- `MovementResolver.compute_reachable(unit, map) → Array[Vector2i]`：BFS 队列，步数分层，不重复 visited
- `manhattan(a: Vector2i, b: Vector2i) → int` 静态方法：`abs(a.x-b.x) + abs(a.y-b.y)`
- BFS 使用 `map.get_neighbors()`（不滤可通行性）+ `map.is_walkable()` 过滤

## Test Evidence
**Required**: `tests/unit/movement/movement_bfs_test.gd`

## Dependencies
- Depends on: Map Epic（get_neighbors/is_walkable）、Unit Epic（mov 属性）
- Unlocks: Story 002（MovementResult + 路径重建）
