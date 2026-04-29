# Story 002: MovementResult + 路径重建

> **Epic**: Movement | **Status**: Ready | **Layer**: Feature | **Type**: Logic

## Context
**GDD**: `design/gdd/movement.md` | **Requirement**: `TR-mov-002`, `TR-mov-006`
**ADR**: ADR-0006: Movement BFS | **Engine**: Godot 4.6.2 | **Risk**: LOW

## Acceptance Criteria
- [ ] **AC-MOVE-004**: BFS 父映射路径重建返回最短路径（步数=Manhattan 距离）
- [ ] **AC-MOVE-006**: 原地移动（0 步）→路径仅含起始瓦片
- [ ] **AC-MOVE-008**: 路径预览暴露完整路径数组供 UI 渲染
- [ ] **AC-MOVE-013**: 拒绝死亡单位移动
- [ ] **AC-MOVE-014**: 拒绝 null Map
- [ ] **AC-MOVE-015**: 越界起始位置→空 MovementResult
- [ ] **AC-MOVE-016**: MOV=0 退化 BFS→仅起始瓦片
- [ ] **AC-MOVE-017**: 所有邻域被阻挡→仅起始瓦片
- [ ] **AC-MOVE-020**: 已 MOVED 状态重复移动→拒绝

## Implementation Notes
```gdscript
class_name MovementResult extends RefCounted
var reachable: Array[Vector2i] = []
var parents: Dictionary = {}  # Dictionary[Vector2i, Vector2i]
var start: Vector2i

func get_path_to(target: Vector2i) -> Array[Vector2i]:
    # 从 target 回溯到 start
```
- MovementResult 为不可变数据对象——构造后字段只读
- `compute_reachable()` 返回 MovementResult（含 reachable + parents）

## Test Evidence
**Required**: `tests/unit/movement/movement_result_test.gd`

## Dependencies
- Depends on: Story 001（BFS——返回 MovementResult 的 reachable + parents）
- Unlocks: Story 003（移动执行）
