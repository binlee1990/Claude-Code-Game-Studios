# Story: Difficulty Data Model + 一周目固定曲线

> **Epic**: difficulty-system
> **Story ID**: DIFF-001
> **Type**: Logic
> **Priority**: Must Have
> **Estimate**: 0.5d
> **ADR**: ADR-012
> **GDD**: `design/gdd/difficulty-system.md`
> **TR**: TR-diff-001

## Summary

实现 `BattleDifficultyProfile` Resource 数据模型 + 章节→阶段映射表 + `DifficultyManager` Autoload 骨架。一周目 4 阶段固定曲线（教学 0.7× / 成长 1.0× / 挑战 1.2× / 高潮 1.4×）。

## Acceptance Criteria

- [ ] **AC-1**: `BattleDifficultyProfile` Resource 包含 phase/enemy_stat_mult/exp_mult/resource_mult/ai_strategy_level 字段
- [ ] **AC-2**: 章节→phase 映射表正确：Ch.1-2→教学(0.7×), Ch.3-5→成长(1.0×), Ch.6-8→挑战(1.2×), Ch.9-10→高潮(1.4×)
- [ ] **AC-3**: `DifficultyManager` Autoload 提供 `get_profile(chapter: int)` 接口
- [ ] **AC-4**: 映射表从 `assets/data/difficulty/phase_curve.json` 加载，代码不硬编码
- [ ] **AC-5**: NG+ 倍率字段预留（`ng_multiplier: float = 1.0`），一周目固定为 1.0
- [ ] **AC-6**: Unit test 覆盖章节映射正确性 + 倍率值精度

## Implementation Notes

- DifficultyManager 注册为 Autoload
- 白名单常量预先定义（不受难度影响的系统：Bond/Belief/AttributeGrowth/Save）
- 使用 `FileAccess.get_file_as_string()` 加载 JSON（Godot 4.6）

## Test Evidence

- `tests/unit/difficulty/data_model_test.gd`
