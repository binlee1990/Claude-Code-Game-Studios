# QA Evidence — Sprint-009 Complete

> **Date**: 2026-05-02
> **Status**: ALL PASS

## Gates

| Gate | Result | Evidence |
|------|--------|----------|
| godot --check-only | PASS | 退出码 0 |
| GUT runner | PASS | `1021 | Pass: 1021 | Fail: 0` (baseline 879 + 142 new) |
| Windows export | PASS | `builds/windows/SRPG.exe`, 124,383,896 bytes |
| Packaged smoke | PENDING | 需人工启动验证 |

## Test Coverage by System

| System | Unit Tests | Integration Tests | Total |
|--------|-----------|-------------------|-------|
| fog-of-war | 31 (visibility + rendering + target_filter) | 4 (save/load) | 35 |
| bond-combo | 34 (validator + UI state) | 0 | 34 |
| difficulty | 34 (data_model + integration_mock) | 0 | 34 |
| boss | 35 (profile + action_pattern) | 0 | 35 |
| equipment (extreme-risk) | 13 | 0 | 13 |
| **New Total** | **147** | **4** | **151** |

## Verification Notes

- 原有 879 tests 全部保持 PASS，无回归
- DifficultyManager 作为 Autoload 在 headless 和 export 模式均正常加载
- FogStateManager (RefCounted) 不依赖 scene tree，测试覆盖完整
- 所有 Resource 类 (BossProfile/BossPhase/BossCheckpoint/BossActionPattern/ComboSkillData) 序列化/反序列化正确
- ComboValidator 门槛检查覆盖：距离/AP/冷却/羁绊等级/单位可用性/玩家触发/无效配对
