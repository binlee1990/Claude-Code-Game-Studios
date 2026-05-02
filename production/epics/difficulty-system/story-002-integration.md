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

- [x] **AC-1**: Combat enemy stat scaling API 由 `DifficultyManager.scale_enemy_stat()` 提供并由 integration mock 覆盖
- [x] **AC-2**: Settlement multiplier API 由 `get_exp_multiplier()` / `get_resource_multiplier()` 提供并由 integration mock 覆盖
- [x] **AC-3**: AI 策略等级随 difficulty phase 切换（phase 1→baseline, phase 3→advanced, phase 4→optimal）
- [x] **AC-4**: Bond 好感度不受 difficulty 影响（白名单验证）
- [x] **AC-5**: 非迷雾关卡中 combat 单元测试不因 DifficultyManager 引入而失败（回归验证）
- [x] **AC-6**: Bridge + integration mock 覆盖 combat / settlement / AI multiplier 链路

## Implementation Notes

- Combat: 在 enemy stat 初始化时调用 `DifficultyManager.scale_enemy_stat(base_value)`
- Settlement: 在 SettlementResult 生成前查询倍率
- AI: 在 AI decision 入口处查询 `get_ai_strategy_level()`
- 各系统不持有本地缓存，每次查询走 DifficultyManager

## Test Evidence

- `tests/unit/difficulty/integration_mock_test.gd`
- `tests/unit/difficulty/difficulty_bridge_test.gd`
- `tests/unit/difficulty/data_model_test.gd`

## Completion

Completed in Sprint-009. A future end-to-end battle-level test remains advisory, not a blocker for the current AI-verifiable integration contract.
