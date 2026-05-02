# QA Evidence — Sprint-009 Complete

> **Date**: 2026-05-02
> **Status**: ALL PASS

## Gates

| Gate | Result | Evidence |
|------|--------|----------|
| godot --check-only | PASS | 退出码 0 |
| GUT runner | PASS | `Total: 1037 | Pass: 1037 | Fail: 0` |
| Windows export | PASS | `builds/windows/SRPG.exe`, 124,407,080 bytes, SHA256 `3530468C51EE43725DC5F54B2A3540351671711EC5DE4D40A5626C463CBE0E6A` |
| Packaged smoke | PASS | `PACKAGED_PLAYTHROUGH_SMOKE PASS`, strict gate rejects `SCRIPT ERROR`, `ERROR:`, and smoke FAIL output |

## Test Coverage by System

| System | Unit Tests | Integration Tests | Total |
|--------|-----------|-------------------|-------|
| fog-of-war | 39 (visibility + rendering + target_filter + battle integration) | 4 (save/load) | 43 |
| bond-combo | 23 (validator) | 10 (battle UI) | 33 |
| difficulty | 37 (data_model + integration_mock + bridge) | 0 | 37 |
| boss | 55 (profile + action_pattern + standalone pattern) | 0 | 55 |
| equipment (extreme-risk) | 13 | UI regression covered in character management integration | 13+ |
| save robustness | 0 | invalid save resource handled gracefully | 1+ |

## Verification Notes

- 原有 879 tests 全部保持 PASS，无回归；post-audit hardening 后总基线为 1037/1037 PASS
- DifficultyManager 作为 Autoload 在 headless 和 export 模式均正常加载
- FogStateManager (RefCounted) 不依赖 scene tree，测试覆盖完整
- 所有 Resource 类 (BossProfile/BossPhase/BossCheckpoint/BossActionPattern/ComboSkillData) 序列化/反序列化正确
- ComboValidator 门槛检查覆盖：距离/AP/冷却/羁绊等级/单位可用性/玩家触发/无效配对
- Equipment +11+ extreme-risk 使用真实成功率曲线与保护符号消耗规则；UI 会显示 `x2+` 保护符号需求
- `tools/package_windows_release.ps1` 现在等待并解析完整 GUT summary，再执行 export 和 packaged smoke
