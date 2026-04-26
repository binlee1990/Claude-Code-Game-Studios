# Story 001: 章节路由与信念值首次分叉（B2-GATE 实装）

> **Epic**: Chapter 02 Content
> **Status**: Ready for Dev
> **Layer**: Feature
> **Type**: Logic
> **Manifest Version**: 2026-04-26-v2

> **Estimate**: 0.5 days

## Context

**GDD**: `design/gdd/chapter-02.md` §3.8, §4.5 / `design/narrative/belief-branching.md` §4.1
**Requirement**: AC-CH2-001, AC-CH2-007 / QA Plan §3.1
**ADR Governing Implementation**: ADR-001 (Event Architecture) / ADR-003 (Save System)

**Engine**: Godot 4.6.2 | **Risk**: LOW

---

## Acceptance Criteria

- [ ] **AC-CH2-001.1**: 给定存档：Ch.2-1 结算后 yi=15, ren=5, zhi=8（义领先 ≥5），系统路由至 chapter_02_act_b（branch_variant = suppression）。
- [ ] **AC-CH2-001.2**: 给定存档：Ch.2-1 结算后 yi=10, ren=12, zhi=8（仁领先），系统路由至 chapter_02_act_b（branch_variant = mercy）。
- [ ] **AC-CH2-001.3**: 给定存档：三值相等（yi=ren=zhi=10），系统默认路由至 mercy，`belief_branch = "mercy_default"` 写入存档。
- [ ] **AC-CH2-007.1**: 仁值为 95，触发 仁+10，最终仁值 = 100（不超出上限）。
- [ ] **AC-CH2-007.2**: 义值为 3，触发 义-8，最终义值 = 0（不低于下限）。

---

## Implementation Notes

### B2-GATE 判定公式

```
yi = belief_values.yi
ren = belief_values.ren
zhi = belief_values.zhi
margin = yi - max(ren, zhi)

if margin >= 5:
    branch = "suppression"
else:
    branch = "mercy_default"  # 双平局时也走默认
belief_branch = branch
```

### 信念值 Clamp

```
belief_values.{ren|yi|zhi} = clamp(value, 0, 100)
```

### 菜单脚本路由逻辑

`chapter_02_act_a` 战斗结算后，由 `battle-settlement` 触发 B2-GATE 判定，
结果写入 `progress_data.belief_branch`。菜单脚本读取该字段，
加载 `chapter_02_act_b` 时传入 `branch_variant` 参数（"mercy" 或 "suppression"）。

### Edge Cases

| 情形 | 处理 |
|------|------|
| yi = max 且 margin = 0 | `"mercy_default"`（非主动选择） |
| margin = 4（差 1 分） | `"mercy"`（不触发 suppression） |
| 任意属性超出 [0,100] | 自动 clamp |

---

## Out of Scope

- Ch.2-2A/2B 内部兵力配置（由各自 JSON 定义）
- 护送战/镇压战的具体战斗机制
- B3-GATE 或后续章节分叉

---

## QA Test Cases

- **AC-CH2-001.1**: 义领先路由
  - Given: belief_values = {ren:5, yi:15, zhi:8}
  - When: B2-GATE evaluated
  - Then: branch_variant = "suppression"

- **AC-CH2-001.2**: 仁领先路由
  - Given: belief_values = {ren:12, yi:10, zhi:8}
  - When: B2-GATE evaluated
  - Then: branch_variant = "mercy"

- **AC-CH2-001.3**: 双平局默认
  - Given: belief_values = {ren:10, yi:10, zhi:10}
  - When: B2-GATE evaluated
  - Then: branch_variant = "mercy_default"

- **AC-CH2-007.1**: 正向溢出截断
  - Given: belief_values.ren = 95, delta = +10
  - When: apply belief change
  - Then: belief_values.ren = 100

- **AC-CH2-007.2**: 负向溢出截断
  - Given: belief_values.yi = 3, delta = -8
  - When: apply belief change
  - Then: belief_values.yi = 0

---

## Test Evidence

**Story Type**: Logic
**Required evidence**: `tests/unit/chapter02/branch_gate_test.gd`
**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: `design/gdd/battle-settlement.md`（结算触发）、`design/gdd/SRPG 核心模块设计总纲.md`（信念值属性）
- Unlocks: CH2-c-002, CH2-c-003, CH2-c-004（act_b 分支路由）

---

## Files to Create / Modify

| File | Action | 说明 |
|------|--------|------|
| `src/core/belief/belief_gate.gd` | Create | B2-GATE 判定逻辑 + clamp |
| `src/core/save/progress_data.gd` | Modify | 新增 `belief_branch` 字段 |
| `tests/unit/chapter02/branch_gate_test.gd` | Create | AC-CH2-001 + AC-CH2-007 测试 |
| `tests/tests_manifest.txt` | Modify | 新增测试文件引用 |

---

## Completion Notes

**Completed**: YYYY-MM-DD
**Criteria**: X/X AC passing
**Deviations**: None
**Test Evidence**: `tests/unit/chapter02/branch_gate_test.gd` — N/N PASS
**Code Review**: /code-review
**Files Delivered**: (list files)
