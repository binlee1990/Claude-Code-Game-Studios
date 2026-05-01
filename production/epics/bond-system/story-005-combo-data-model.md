# Story: Combo Skill Data Model + Trigger

> **Epic**: bond-system
> **Story ID**: BOND-COMBO-001
> **Type**: Logic
> **Priority**: Must Have
> **Estimate**: 0.5d
> **ADR**: ADR-011
> **GDD**: `design/gdd/bond-system.md`
> **TR**: TR-bond-005

## Summary

实现 `ComboSkillData` Resource 数据模型 + 4 种羁绊类型的组合技定义（战友/师徒/宿敌/恋人）+ 触发门槛验证（距离 ≤3、AP 消耗、冷却、存活、未控制）。冷却按 pair_key + skill_id 存储在 battle_state。

## Acceptance Criteria

- [ ] **AC-1**: `ComboSkillData` Resource 包含 skill_id/bond_type/skill_type/ap_cost/cooldown_turns/range_max/effect_params
- [ ] **AC-2**: 4 种 bond type 各有对应的 combo skill 定义（战友=协力一击/师徒=技能传授/宿敌=竞争觉醒/恋人=誓约守护）
- [ ] **AC-3**: `ComboValidator` 验证门槛：曼哈顿距离 ≤3、双方 AP 充足、冷却未激活、双方存活未撤退未控制
- [ ] **AC-4**: 冷却存储格式 `battle_state.combo_cooldowns[pair_key + skill_id] = remaining_turns`
- [ ] **AC-5**: 任一门槛不满足时返回具体失败原因（距离不足/AP不足/冷却中/单位不可用）
- [ ] **AC-6**: MVP 仅玩家可触发，ComboValidator 接受 `is_player: bool` 参数 gating
- [ ] **AC-7**: Unit test 覆盖全部门槛 + 4 种 combo type 的 effect_params 正确性

## Implementation Notes

- 复用 BondRegistry pair key 生成逻辑
- 距离校验需要缓存 unit position lookup（避免每帧扫描 25×25 网格）
- 触发流程通过 GameEvents 信号链：`combo_skill_requested → ComboValidator → ComboExecutor → combo_skill_executed`

## Test Evidence

- `tests/unit/bond/combo_data_model_test.gd`
- `tests/unit/bond/combo_validator_test.gd`
