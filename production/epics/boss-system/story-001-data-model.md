# Story: Boss 系统 Epic 创建 + 数据模型

> **Epic**: boss-system
> **Story ID**: BOSS-001
> **Type**: Design/Logic
> **Priority**: Must Have
> **Estimate**: 0.5d
> **ADR**: ADR-013
> **GDD**: `design/gdd/boss-system.md`
> **TR**: TR-boss-001

## Summary

创建 Boss 系统 Epic 目录，实现 `BossProfile` / `BossPhase` / `BossCheckpoint` Resource 数据模型。定义 5 种 BossType 枚举（TUTORIAL/NARRATIVE/APTITUDE/PEAK/HIDDEN）及默认行为参数。

## Acceptance Criteria

- [ ] **AC-1**: `BossProfile` Resource 可序列化，包含 boss_type / phases / action_patterns / checkpoint 字段
- [ ] **AC-2**: `BossPhase` Resource 包含 phase_index / hp_threshold / active_patterns / on_enter_effects
- [ ] **AC-3**: `BossCheckpoint` Resource 包含 phase_index / retained_hp_ratio / free_retries / pattern_hints_revealed
- [ ] **AC-4**: BossType enum 5 种类型，每种有对应的默认 phase_count/checkpoint/hint_level
- [ ] **AC-5**: BossProfile 可从 battle_definition JSON 的 `boss` 节加载
- [ ] **AC-6**: Unit test 覆盖 Resource 序列化/反序列化 + BossType 默认值

## Implementation Notes

- Resource-based 数据模型，与 Skill/Equipment/Difficulty 一致
- BossProfile.boss_type 决定默认参数，可通过字段覆盖
- 检查点数据存储在 battle_state 级别，不写入永久 SaveData

## Test Evidence

- `tests/unit/boss/boss_profile_test.gd`
