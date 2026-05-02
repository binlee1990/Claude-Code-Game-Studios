# Story: Combo Skill Battle UI + 4 类型效果集成

> **Epic**: bond-system
> **Story ID**: BOND-COMBO-002
> **Type**: Integration/UI
> **Priority**: Should Have
> **Estimate**: 0.5d
> **ADR**: ADR-011
> **GDD**: `design/gdd/bond-system.md`
> **TR**: TR-bond-006
> **Deps**: BOND-COMBO-001

## Summary

在 Battle HUD 中添加组合技触发按钮（玩家主动触发入口），集成 4 种 combo 效果到现有 damage/status_effect 管线。按钮在门槛不满足时禁用并显示短文本原因。

## Acceptance Criteria

- [x] **AC-1**: Battle HUD 中距离 ≤3 的已羁绊角色 pair 显示 combo 按钮（从 ComboSkillData 读取）
- [x] **AC-2**: 按钮在门槛不满足时 disabled + tooltip 显示失败原因
- [x] **AC-3**: 伤害型（协力一击）通过现有 damage pipeline 生效（×1.5 + 无视 20% 防御）
- [x] **AC-4**: 临时技能型（技能传授）通过 status_effects 写入临时技能引用，3 回合后移除
- [x] **AC-5**: 增益型（竞争觉醒）通过 attack_bonus status_effect 生效，2 回合后移除
- [x] **AC-6**: 防护型（誓约守护）注册 before_fatal_damage 拦截器，消耗 30% HP
- [x] **AC-7**: Combo 执行后冷却写入 battle_state，按钮进入 cooldown 倒计时
- [x] **AC-8**: Integration test 覆盖完整 trigger→execute→cooldown→HUD refresh 链路

## Implementation Notes

- 监听 `GameEvents.combo_skill_executed` 刷新 HUD
- 4 种效果通过现有 status_effect / combat modifier 管线实现，不新建并行 buff 系统
- 冷却倒计时在 battle HUD 中以灰色半透明覆盖显示

## Test Evidence

- `tests/integration/bond/combo_battle_ui_test.gd`

## Completion Note

Completed in Sprint-009. Human visual inspection of active/disabled button clarity remains tracked as MAN-009.
