# Story 004: 镇压战部分失败结算（流民逃离 + 击杀计数对比）

> **Epic**: Chapter 02 Content
> **Status**: Ready for Dev
> **Layer**: Feature
> **Type**: Logic
> **Manifest Version**: 2026-04-26-v2

> **Estimate**: 0.5 days

## Context

**GDD**: `design/gdd/chapter-02.md` §3.5, §5.9 / `design/gdd/battle-settlement.md`
**Requirement**: AC-CH2-004（B2-N2B 部分） / QA Plan §3.4
**ADR Governing Implementation**: ADR-001 (Event Architecture) / ADR-003 (Save System)

**Engine**: Godot 4.6.2 | **Risk**: LOW

---

## Acceptance Criteria

- [ ] **AC-CH2-004.3**: 镇压战胜利时，豪强 NPC 击杀数 > 我方击杀数 → 义+10 / 智-5。
- [ ] **AC-CH2-004.4**: 镇压战胜利时，我方击杀数 ≥ 豪强 NPC 击杀数 → 义+3 / 智+2。
- [ ] **AC-CH2-004.5**: 流民逃离计数 > 4 时，触发部分失败结算（义-5 但不 Game Over）。

---

## Implementation Notes

### 镇压战胜利条件

- 主要：击败所有敌方流民残部
- 辅助：流民成功逃离地图边缘（算作"歼灭"但计入逃离计数）

### 逃离计数

```
flee_count += 1  # 每当流民 civilian 从地图边缘离开
```

### 击杀计数

```
player_kill_count += 1  # 我方单位击杀敌方
npc_kill_count += 1     # 豪强 NPC 击杀敌方（由 NPC AI 系统上报）
```

### B2-N2B 结算

```
when battle_ended and branch == "suppression":
    if player_kill_count > npc_kill_count:
        belief_values.yi += 3
        belief_values.zhi += 2
    elif npc_kill_count > player_kill_count:
        belief_values.yi += 10
        belief_values.zhi -= 5
```

### 部分失败结算（逃离 > 4）

```
if flee_count > 4:
    # 部分失败：非 Game Over，但给予义-5
    belief_values.yi -= 5
    trigger_settlement("partial_failure")  # 显示特殊结算画面
else:
    trigger_settlement("victory")  # 正常胜利结算
```

### Edge Cases

| 情形 | 处理 |
|------|------|
| flee_count == 4 | 正常胜利（上限不触发） |
| flee_count == 5 | 部分失败（第一次触发） |
| 我方与豪强击杀数相等 | 走 `player_kill_count >= npc_kill_count` 分支 |
| 豪强 NPC 未击杀任何敌人 | npc_kill_count = 0 |
| 部分失败 + 我方全员退场 | 先部分失败，再触发 Game Over |

---

## Out of Scope

- 豪强 NPC AI 击杀上报机制（由 AI-system epic 实现）
- 部分失败结算的 UI 显示（属于 UI epic）
- 流民 civilian 的移动 AI 逻辑

---

## QA Test Cases

- **AC-CH2-004.3**: 豪强多杀
  - Given: player_kill_count=2, npc_kill_count=4
  - When: suppression battle ends (victory)
  - Then: yi += 10, zhi -= 5

- **AC-CH2-004.4**: 我方多杀
  - Given: player_kill_count=5, npc_kill_count=2
  - When: suppression battle ends (victory)
  - Then: yi += 3, zhi += 2

- **AC-CH2-004.5**: 部分失败
  - Given: flee_count=5, battle_victory=true
  - When: suppression battle ends
  - Then: yi -= 5, settlement_type = "partial_failure"

---

## Test Evidence

**Story Type**: Logic
**Required evidence**: `tests/unit/chapter02/suppression_settlement_test.gd`
**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: `design/gdd/battle-settlement.md`（结算触发）、`design/gdd/ai-system.md`（NPC 击杀上报）
- Unlocks: CH2-c-001（信念值分叉完成后触发）

---

## Files to Create / Modify

| File | Action | 说明 |
|------|--------|------|
| `src/core/settlement/suppression_battle_settlement.gd` | Create | 镇压战特殊结算逻辑 |
| `src/core/save/progress_data.gd` | Modify | 新增 `flee_count`, `player_kill_count`, `npc_kill_count` 字段 |
| `assets/data/chapter_02_config.json` | Modify | 新增 `suppression_flee_limit=4` |
| `tests/unit/chapter02/suppression_settlement_test.gd` | Create | AC-CH2-004.3~5 测试 |
| `tests/tests_manifest.txt` | Modify | 新增测试文件引用 |

---

## Completion Notes

**Completed**: YYYY-MM-DD
**Criteria**: X/X AC passing
**Deviations**: None
**Test Evidence**: `tests/unit/chapter02/suppression_settlement_test.gd` — N/N PASS
**Code Review**: /code-review
**Files Delivered**: (list files)
