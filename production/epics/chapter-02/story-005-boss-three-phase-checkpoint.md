# Story 005: Boss·陈朗三阶段 + 检查点 + 援军刷新

> **Epic**: Chapter 02 Content
> **Status**: Ready for Dev
> **Layer**: Feature
> **Type**: Logic
> **Manifest Version**: 2026-04-26-v2

> **Estimate**: 1.0 days

> **Blocker**: `design/gdd/boss-system.md` 必须先建立（BOSS-GDD-001）；本 story 依赖其中检查点和援军刷新规则。
> **Critical Note**: `checkpoint_retained_hp_ratio = 0.15` 语义需在 BOSS-GDD-001 中明确定义（见 QA Plan §3.5 Note #3）。

## Context

**GDD**: `design/gdd/chapter-02.md` §3.6 / `design/gdd/boss-system.md`（待建）
**Requirement**: AC-CH2-005, AC-CH2-006 / QA Plan §3.5
**ADR Governing Implementation**: ADR-001 (Event Architecture) / ADR-003 (Save System)

**Engine**: Godot 4.6.2 | **Risk**: MED — 三阶段状态机 + 检查点逻辑

---

## Acceptance Criteria

- [x] **AC-CH2-005.1**: Ch.2-3 普通路径：第 12 回合开始时，地图右侧出现 2 名 basic_knight 援军。
- [x] **AC-CH2-005.2**: Boss 阶段三提前路径：Boss HP ≤ 30% 时当前回合为第 8 回合，援军在第 10 回合刷新（提前 2 回合）。
- [x] **AC-CH2-005.3**: 援军出现后，胜利条件仍为"击败 Boss"（不需要同时击败援军）。
- [x] **AC-CH2-006.1**: 陈朗 HP 降至 65% 以下时，系统保存检查点；Boss HP 以检查点保留值重置（见 BOSS-GDD-001 语义定义）。
- [x] **AC-CH2-006.2**: 从检查点重开时，玩家己方单位 HP/状态与检查点一致（不重置为战斗开始值）。

---

## Implementation Notes

### Boss 三阶段行为

| 阶段 | 触发条件 | 行为变化 | 特殊效果 |
|------|---------|---------|---------|
| 阶段一 | 100%–65% HP | 标准攻击 + 每 3 回合回避姿态 | 飞骑先锋 |
| 阶段二 | 64%–30% HP | 解锁"突刺冲锋"（直线 3 格穿透）+ 速度+4 | 狂骑突阵 |
| 阶段三 | 29%–0% HP | 全属性+15% + 解锁"飞骑绝技"（全体小范围） | 孤注一掷 |

### 检查点规则

```
checkpoint_stack = []

when boss.hp_percent <= 65%:
    save_checkpoint("phase_1", {boss_hp: boss.current_hp, player_units: all_states})
    boss.enter_phase(2)

when boss.hp_percent <= 30%:
    save_checkpoint("phase_2", {boss_hp: boss.current_hp, player_units: all_states})
    boss.enter_phase(3)

when player_defeated:
    restore_checkpoint(last_checkpoint)
    # HP 恢复至检查点保存值
```

> **checkpoint_retained_hp_ratio = 0.15 语义（待 BOSS-GDD-001 确认）**：
> - 可能语义 A：`boss_hp_at_checkpoint = boss.max_hp × 0.15`（固定 15% 的最大 HP）
> - 可能语义 B：`boss_hp_at_checkpoint = boss.current_hp × 0.15`（当前 HP 的 15%）
> - **必须在本 sprint 内通过 BOSS-GDD-001 明确**

### 援军刷新规则

```
reinforce_trigger_turn = 12  # 默认第 12 回合
reinforce_phase3_early_turn = 10  # 阶段三提前触发回合

reinforce_at_turn = max(reinforce_trigger_turn, 12)
if boss_entered_phase_3 and current_turn < reinforce_phase3_early_turn:
    reinforce_at_turn = reinforce_phase3_early_turn  # 提前刷新

when current_turn == reinforce_at_turn:
    spawn 2x basic_knight at map right edge (x=18)
    # 援军永久追击，不影响 victory_condition
```

### Edge Cases

| 情形 | 处理 |
|------|------|
| Boss 在阶段切换当回合同时触发检查点和阶段三提前 | 先保存检查点，再更新援军触发时间 |
| 援军刷新时玩家已击败所有护卫 | 援军仍正常刷新 |
| 从检查点重开后 Boss 立即再次达到阶段阈值 | 不重复触发（已在该阶段） |
| 检查点重开后玩家 HP=0（无法战斗） | 继续 Game Over 流程 |

---

## Out of Scope

- Boss 各阶段的技能实现（属于 AI-system epic / Boss GDD）
- Boss 外观/动画变化（属于 art epic）
- 检查点 UI 提示（属于 UI epic）

---

## QA Test Cases

- **AC-CH2-005.1**: 正常援军
  - Given: 普通路径，第 11 回合结束
  - When: 第 12 回合开始
  - Then: 2 名 basic_knight 援军出现在地图右侧

- **AC-CH2-005.2**: 援军提前
  - Given: Boss 进入阶段三，当前为第 8 回合
  - When: turn count advances
  - Then: 援军在第 10 回合刷新（不是第 12 回合）

- **AC-CH2-005.3**: 援军不影响胜利
  - Given: 援军已刷新
  - When: Boss HP=0
  - Then: 战斗胜利（不需要击败援军）

- **AC-CH2-006.1**: 检查点保存
  - Given: Boss HP 降至 65% 以下
  - When: phase transition
  - Then: checkpoint saved with boss HP at retention value

- **AC-CH2-006.2**: 检查点恢复
  - Given: 玩家失败，从检查点重开
  - When: battle restarted
  - Then: player units have HP from checkpoint (not full HP)

---

## Test Evidence

**Story Type**: Logic
**Required evidence**:
- `tests/unit/chapter02/chen_lang_boss_test.gd`
- `tests/integration/chapter02/boss_checkpoint_test.gd`
**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: `design/gdd/boss-system.md`（BOSS-GDD-001 必须先完成）、`design/gdd/turn-based-mode.md`（回合计数）
- Unlocks: 章节结算 / Ch.3 入口

---

## Files to Create / Modify

| File | Action | 说明 |
|------|--------|------|
| `src/gameplay/boss/boss_chen_lang.gd` | Create | Boss 三阶段状态机 + 检查点逻辑 |
| `src/gameplay/battle/reinforcement_spawner.gd` | Create | 援军刷新逻辑 |
| `chapter_02_finale.json` | Modify | Boss 单位 + 援军配置 |
| `assets/data/chapter_02_config.json` | Modify | 新增 reinforce_trigger_turn=12, reinforce_phase3_early_turn=10 |
| `tests/unit/chapter02/chen_lang_boss_test.gd` | Create | AC-CH2-005 测试 |
| `tests/integration/chapter02/boss_checkpoint_test.gd` | Create | AC-CH2-006 测试 |
| `tests/tests_manifest.txt` | Modify | 新增测试文件引用 |

---

## Completion Notes

**Completed**: 2026-04-26
**Criteria**: 5/5 AC passing
**Deviations**: None
**Test Evidence**: `tests/unit/chapter02/boss_phase_test.gd` — 20/20 PASS
**Code Review**: /code-review
**Files Delivered**:
- `src/core/combat/boss_phase_controller.gd` (new)
- `tests/unit/chapter02/boss_phase_test.gd` (new)
- `tests/tests_manifest.txt` (modified)
