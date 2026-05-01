# Story: Difficulty Integration

> **Epic**: difficulty-system
> **Story ID**: DIFF-002
> **Type**: Integration
> **Priority**: Should Have
> **Estimate**: 0.75d
> **ADR**: ADR-012
> **GDD**: `design/gdd/difficulty-system.md`
> **TR**: TR-diff-002
> **Deps**: DIFF-001

## Summary

将 `DifficultyManager` 集成到 combat（enemy stat ×倍率）、settlement（exp/drop ×倍率）、AI（策略等级切换）三个系统。按 combat→settlement→AI 顺序集成。

## Acceptance Criteria

- [ ] **AC-1**: Combat 中 enemy HP/ATK 实际应用 `DifficultyManager.scale_enemy_stat()`
- [ ] **AC-2**: Settlement 中 exp 应用 `get_exp_multiplier()`，drop 应用 `get_resource_multiplier()`
- [ ] **AC-3**: AI 策略等级随 difficulty phase 切换（phase 1→base, phase 3→advanced, phase 4→optimal）
- [ ] **AC-4**: Bond 好感度不受 difficulty 影响（白名单验证）
- [ ] **AC-5**: 非迷雾关卡中 combat 单元测试不因 DifficultyManager 引入而失败（回归验证）
- [ ] **AC-6**: Integration test 覆盖 combat→settlement 完整倍率链路

## Implementation Notes

- Combat: 在 enemy stat 初始化时调用 `DifficultyManager.scale_enemy_stat(base_value)`
- Settlement: 在 SettlementResult 生成前查询倍率
- AI: 在 AI decision 入口处查询 `get_ai_strategy_level()`
- 各系统不持有本地缓存，每次查询走 DifficultyManager

## Test Evidence

- `tests/unit/difficulty/integration_combat_test.gd`
- `tests/unit/difficulty/integration_settlement_test.gd`
- `tests/integration/difficulty/difficulty_pipeline_test.gd`
