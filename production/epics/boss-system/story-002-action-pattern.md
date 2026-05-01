# Story: Boss Action Pattern 数据模型

> **Epic**: boss-system
> **Story ID**: BOSS-002
> **Type**: Logic
> **Priority**: Should Have
> **Estimate**: 0.5d
> **ADR**: ADR-013
> **GDD**: `design/gdd/boss-system.md`
> **TR**: TR-boss-002
> **Deps**: BOSS-001

## Summary

实现 `BossActionPattern` Resource 数据模型，定义 telegraph 前兆时长、range indicator 类型、元素属性、冷却周期、目标范围等字段。

## Acceptance Criteria

- [ ] **AC-1**: `BossActionPattern` Resource 包含 pattern_id / telegraph_duration / range_indicator / element_type / cooldown_turns / targets 字段
- [ ] **AC-2**: `telegraph_duration` 默认 0.7s，范围 [0.3, 1.5]
- [ ] **AC-3**: `targets` 枚举支持 SINGLE / ROW / CROSS / AREA 四种目标范围
- [ ] **AC-4**: `range_indicator` 类型枚举定义完整（矩形/十字/菱形/全屏）
- [ ] **AC-5**: Action pattern 与 BossPhase 的 `active_patterns` 索引正确关联
- [ ] **AC-6**: Unit test 覆盖所有枚举字段 + JSON 反序列化

## Implementation Notes

- 前兆动画在 Godot 中用 `Tween` 或 `AnimationPlayer` 实现，数据模型中仅存储时长
- range_indicator 用 TileMapLayer 或 CanvasItem 绘制几何占位（矩形/十字/菱形）
- MVP 不做正式视觉资产

## Test Evidence

- `tests/unit/boss/action_pattern_test.gd`
