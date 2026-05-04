# Epic: 修正器/倍率引擎

> **Layer**: Core Data
> **GDD**: design/gdd/modifier-engine.md
> **Architecture Module**: `ModifierEngine` (RefCounted) (Autoload 持有)
> **Status**: Ready
> **Stories**: Created (7 stories)

## Overview

修正器/倍率引擎是游戏中所有数值修正的统一管理、叠加和查询服务。游戏中任何"基础值 + 多个修正 → 最终值"的场景——装备加成、技能增幅、Buff/Debuff、境界加成、账号天赋、里程碑奖励、区域效果——都通过本引擎处理叠加逻辑，而不是在各系统中硬编码。

Architecture ownership: `ModifierEngine (RefCounted)` owns 修正器注册表, 叠加顺序, 倍率计算.

## Governing ADRs

| ADR | Decision Summary | Engine Risk |
|-----|------------------|-------------|
| ADR-0007: 修正器叠加顺序 | Use one `ModifierEngine` service with a three-stage pipeline: `base + add_sum`, then same-pool additive percentage multipliers, then cross-pool multiplication. MVP pools are `equipment`, `realm`, `zone`, and `buff`. Targets are strings such as `player.atk` and `lingqi_production`. | LOW |
| ADR-0008: Autoload 初始化顺序 | Use explicit Autoload order in `project.godot`: | MEDIUM |

## GDD Requirements

| TR-ID | Requirement | ADR Coverage |
|-------|-------------|--------------|
| TR-modifier-engine-001 | ModifierEngine owns modifier registration, target naming, ADD and MULT pool stacking, cache invalidation, and expiry events. | ADR-0007, ADR-0008 |

**Untraced requirements**: 0 known in `docs/architecture/tr-registry.yaml`; the registry currently exposes one stable system-level TR for this GDD.

## Engine Risk

**MEDIUM** — highest governing ADR knowledge risk. Engine baseline: Godot 4.6.2.

## Cross-Epic Dependencies

- Upstream: 公式引擎, 大数值系统, 事件总线
- Downstream: 属性系统, 产出乘数系统, 调试控制台, 等级系统, 战斗计算器

## Definition of Done

This epic is complete when:
- All stories are implemented, reviewed, and closed via `/story-done`.
- All acceptance criteria from `design/gdd/modifier-engine.md` are verified.
- All Logic and Integration stories have passing test files under `tests/`.
- All Visual/Feel and UI stories have evidence docs with sign-off under `production/qa/evidence/`.
- Any Godot 4.6.2 behavior named by the governing ADRs is verified against `docs/engine-reference/godot/`.

## Stories

| # | Story | Type | Status | ADR |
|---|-------|------|--------|-----|
| 001 | [返回 `250.0`](story-001-250-0.md) | UI | Ready | ADR-0007 |
| 002 | [结果为 BigNumber 表示 2500](story-002-bignumber-2500.md) | Config/Data | Ready | ADR-0007 |
| 003 | [返回 `true`；再次调用 `unregister("abc")` 返回 `false`](story-003-true-unregister-abc-false.md) | Logic | Ready | ADR-0007 |
| 004 | [返回空字符串 `""`，打印警告](story-004-004-logic.md) | Logic | Ready | ADR-0007 |
| 005 | [成功返回 ID，`get_add_sum` 包含 `0.0` 贡献](story-005-id-get-add-sum-0-0.md) | Logic | Ready | ADR-0007 |
| 006 | [第二次直接返回缓存值](story-006-006-ui.md) | UI | Ready | ADR-0007 |
| 007 | [返回的数组长度为 2 且包含 `"player.atk"` 和 `"lingqi_production"`（去重，顺序不保证）；空注册表时返](story-007-2-player-atk-lingqi-production.md) | Config/Data | Ready | ADR-0007 |

## Next Step

Run `/story-readiness production/epics/modifier-engine/story-001-*.md` before implementing the first story in this epic.
