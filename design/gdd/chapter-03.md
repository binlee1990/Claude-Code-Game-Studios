# Chapter 3 关卡设计文档

> 版本: v0.1 | 日期: 2026-04-27 | 状态: Skeleton / Readiness
> 文件路径: design/gdd/chapter-03.md
> Sprint: 005 / CH3-001

---

## 1. Overview

第三章承接 Ch.2 的 B2-GATE 结果，目标是在不立即分裂成三条完整路线的前提下，让玩家第一次感到自身信念值正在形成稳定倾向。本章暂定作为 soft_lock 前置章：通过 B3-N1、B3-N2、B3-GATE、B3-N3 逐步放大路线差异，并为 Ch.4 的 hard_lock 做叙事预警。

本文件是 Sprint-005 readiness skeleton，不包含正式战斗实现、敌人配置或剧情定稿。

---

## 2. Player Fantasy

- 玩家看见 Ch.2 选择带来的队伍态度变化。
- 玩家第一次用基地/管理/培养成果进入章节准备。
- 玩家开始理解“仁/义/智”不是单次选择，而是整支队伍的路线气质。

---

## 3. Detailed Rules

### 3.1 Chapter Structure Placeholder

| 战斗编号 | 战斗 ID | 类型 | 核心机制 | 信念值触发 |
|---|---|---|---|---|
| Ch.3-1 | `chapter_03_act_a` | 待定 | 开章立场选择 + Ch.2 carry state | B3-N1 |
| Ch.3-2 | `chapter_03_act_b` | 待定 | 行为结果累积，可能引入 Bond special dialogue | B3-N2 |
| Ch.3 Gate | `chapter_03_act_b` 结算后 | branch_gate / soft_lock | 首次 soft_lock 判断 | B3-GATE |
| Ch.3-3 | `chapter_03_finale` | 待定 | 章节终结选择，预告 Ch.4 route pressure | B3-N3 |

### 3.2 Belief Branching Placeholders

Source of truth: `design/narrative/belief-branching.md` §3.4.

| 节点 ID | 触发位置（占位） | 类型 | 预计信念值权重 | 备注 |
|---|---|---|---|---|
| B3-N1 | `chapter_03_act_a` | 叙事选择 | 三路线各 ±8 ~ ±12 | Ch.3 开章立场选择 |
| B3-N2 | `chapter_03_act_b` | 行为结果 | 三路线各 ±5 ~ ±10 | 战斗行为累积 |
| B3-GATE | `chapter_03_act_b` 结算后 | branch_gate / soft_lock | 领先路线差值判断 | 第一次 soft_lock 判断 |
| B3-N3 | `chapter_03_finale` | 叙事选择 | 三路线各 ±8 | 章节终结选择 |

### 3.3 Dependencies To Resolve Before Implementation

| Dependency | Why It Matters | Sprint-006 Readiness |
|---|---|---|
| Bond system MVP | Ch.3 may need route-character special dialogue | `production/epics/bond-system/EPIC.md` |
| Base full phase 1 | Ch.3 is the first chapter after base MVP | `docs/active/base-full-readiness-brief.md` |
| Resource economy tuning | Ch.3 reward/cost curve depends on Sprint-004 market | `docs/architecture/ADR-008-resource-economy-upgrade.md` |
| Equipment upgrade scope | Ch.3 difficulty may require enhancement UI decisions | `docs/architecture/ADR-009-equipment-upgrade.md` |

---

## 4. Formulas

Formal formulas are not finalized. Initial placeholders:

```text
B3 dominant_route = argmax(ren, yi, zhi)
B3 margin = dominant_value - second_value
soft_lock_candidate = margin >= 20
```

The B3-GATE default route and threshold must be finalized in the full Ch.3 GDD before implementation.

---

## 5. Edge Cases

- If Ch.2 human playtest data is still missing, Ch.3 implementation must avoid assuming the培养闭环 fully solves difficulty.
- If B2-GATE data is absent in older saves, Ch.3 should use a neutral/default route and log the missing state.
- If Bond MVP is not ready, Ch.3 special dialogue must degrade to route-only dialogue rather than blocking combat implementation.

---

## 6. UI / Audio / Visual Requirements

Placeholder only:

- Chapter select / briefing must expose current belief tendency.
- Any Bond-specific dialogue must show a clear character-pair indicator.
- No new art/audio asset requirement is authorized by this skeleton.

---

## 7. Acceptance Criteria For Full GDD

- [ ] All Ch.3 battles have IDs, objectives, map assumptions, unit lists, and failure states.
- [ ] B3-N1/B3-N2/B3-GATE/B3-N3 have concrete belief deltas and default route rules.
- [ ] Save/load fields for B3-GATE and soft_lock are specified.
- [ ] Dependencies on Bond/Base/Fog are either implemented, explicitly deferred, or designed as graceful degradation.
- [ ] Automated test candidates are listed before implementation begins.

---

## 8. Sprint-006 Handoff

Recommended next step: turn this skeleton into a full eight-section Ch.3 GDD only after Sprint-005 localization/Credits gates remain green. Ch.3 combat implementation should start after the full GDD is reviewed.
