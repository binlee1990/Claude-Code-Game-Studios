# Epic: Difficulty System

> **Status**: Complete
> **Created**: 2026-05-01
> **GDD**: `design/gdd/difficulty-system.md`
> **ADR**: `docs/architecture/ADR-012-difficulty-system.md`
> **System**: difficulty
> **Layer**: Meta
> **Priority**: Vertical Slice

## Scope

实现一周目固定难度曲线（4 阶段倍率）数据模型 + combat/settlement/AI 三系统集成。NG+ 难度倍率选择排除在本 epic 外。

## Stories

| # | Story | Type | Est. | Status |
|---|-------|------|------|--------|
| 001 | Difficulty data model + 一周目固定曲线 | Logic | 0.5d | Complete |
| 002 | Difficulty 集成（combat/settlement/AI） | Integration | 0.75d | Complete |

## Out of Scope

- NG+ 难度倍率选择 UI
- 成就点数兑换流程
- 多周目难度中途切换

## GDD Requirements

- TR-diff-001: 一周目固定曲线（4 phases × enemy/exp/resource multipliers）
- TR-diff-002: Difficulty integration with combat/settlement/AI

## Completion Evidence

- `src/core/difficulty/difficulty_manager.gd`
- `src/core/difficulty/difficulty_bridge.gd`
- `assets/data/difficulty/phase_curve.json`
- `tests/unit/difficulty/data_model_test.gd`
- `tests/unit/difficulty/integration_mock_test.gd`
- `tests/unit/difficulty/difficulty_bridge_test.gd`
- Strict packaged smoke no longer emits DifficultyManager autoload startup errors.
