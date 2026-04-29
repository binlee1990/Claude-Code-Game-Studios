# Story 003: 移动执行 + Map 集成

> **Epic**: Movement | **Status**: Ready | **Layer**: Feature | **Type**: Integration

## Context
**GDD**: `design/gdd/movement.md` | **Requirement**: `TR-mov-003`, `TR-mov-004`
**ADR**: ADR-0006: Movement BFS | **Engine**: Godot 4.6.2 | **Risk**: LOW

## Acceptance Criteria
- [ ] **AC-MOVE-005**: Map.move_unit(unit, from, to) 原子完成（remove+place 单次调用）
- [ ] **AC-MOVE-007**: 移动后 unit.action_state: SELECTED→MOVED
- [ ] **AC-MOVE-009**: 死亡/非 IDLE 状态单位→拒绝移动
- [ ] **AC-MOVE-018**: TOCTOU——BFS 后目标在移动前被占用→移动失败
- [ ] **AC-MOVE-019**: 移动到 blocked/已占用瓦片→拒绝
- [ ] **AC-MOVE-024**: 完整移动后 Map._occupancy 一致（from 空，to 有 unit）
- [ ] **AC-MOVE-025**: 移动后 unit 处于 MOVED 状态，攻击瞄准可用

## Implementation Notes
```gdscript
class_name MovementResolver extends RefCounted
func execute_move(unit: Unit, target: Vector2i, result: MovementResult, map: Map) -> bool:
    if not unit.can_move(): return false
    if not result.reachable.has(target): return false
    var from := unit.grid_position
    if not map.move_unit(unit, from, target): return false  # TOCTOU guard
    unit.action_state = ActionState.MOVED
    return true
```

## Test Evidence
**Required**: `tests/integration/movement/movement_execution_test.gd`

## Dependencies
- Depends on: Story 001（BFS）、Story 002（MovementResult）、Map Epic（move_unit）
- Unlocks: Attack Epic（移动后攻击瞄准）
