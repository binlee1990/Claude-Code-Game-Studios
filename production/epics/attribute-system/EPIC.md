# Epic: 属性系统

> **Layer**: Core Gameplay
> **GDD**: design/gdd/attribute-system.md
> **Architecture Module**: `AttributeSystem` (RefCounted) (Autoload 持有)
> **Status**: Ready
> **Stories**: Created (12 stories)

## Overview

属性系统是游戏中所有实体（主角、弟子、敌人、Boss）数值面板的统一存储、整合与变更通知服务。游戏世界的每一个会"打人"或"被打"的对象——它的生命、攻击、防御、速度、暴击率/暴击伤害、命中、闪避、韧性、神识、气运、因果——都以"实体 ID × 属性 ID → BigNumber 数值"的二维映射形式存放在这里。它不计算属性成长公式（由公式引擎负责）、不管理装备/技能/Buff 的叠加顺序（由修正器/倍率引擎负责）、不决定"升级时该加多少攻击"（由等级系统决定）；它只回答四个问题：**这个实体的某个属性基础值是多少？最终值（含所有修正）是多少？我帮你改完了基础值，谁需要被通知？哪些属性是这个实体需要展示的？**

Architecture ownership: `AttributeSystem (RefCounted)` owns 属性基础值, 修正器整合查询.

## Governing ADRs

| ADR | Decision Summary | Engine Risk |
|-----|------------------|-------------|
| ADR-0007: 修正器叠加顺序 | Use one `ModifierEngine` service with a three-stage pipeline: `base + add_sum`, then same-pool additive percentage multipliers, then cross-pool multiplication. MVP pools are `equipment`, `realm`, `zone`, and `buff`. Targets are strings such as `player.atk` and `lingqi_production`. | LOW |
| ADR-0001: BigNumber 实现策略 | Implement `BigNumber` as an immutable `RefCounted` GDScript value type using `mantissa: float` and `exponent: int`. Normalized non-zero values keep `mantissa` in `[1.0, 10.0)` and `exponent` in `[0, 308]`. Zero is `{0.0, 0}`. Overflow saturates to `MAX`; negative or sub-unit absolute results clamp to `ZERO`. | HIGH |
| ADR-0002: 事件总线架构 | Use a global `EventBus` Autoload Node with string event names and `Dictionary` payloads. The bus dispatches events synchronously in the current frame. Exact subscriptions are the production path. Prefix pattern subscriptions exist only for debug tooling such as `event watch resource`. Coalesced events are allowed only for display refreshes where latest-state wins. | HIGH |

## GDD Requirements

| TR-ID | Requirement | ADR Coverage |
|-------|-------------|--------------|
| TR-attribute-system-001 | AttributeSystem owns entity attribute base values, final-value queries through ModifierEngine, events, snapshot, and restore. | ADR-0007, ADR-0001, ADR-0002 |

**Untraced requirements**: 0 known in `docs/architecture/tr-registry.yaml`; the registry currently exposes one stable system-level TR for this GDD.

## Engine Risk

**HIGH** — highest governing ADR knowledge risk. Engine baseline: Godot 4.6.2.

## Cross-Epic Dependencies

- Upstream: 大数值系统, 修正器/倍率引擎, 事件总线, 数据配置系统
- Downstream: 调试控制台, 等级系统, 敌人数据库, 战斗计算器

## Definition of Done

This epic is complete when:
- All stories are implemented, reviewed, and closed via `/story-done`.
- All acceptance criteria from `design/gdd/attribute-system.md` are verified.
- All Logic and Integration stories have passing test files under `tests/`.
- All Visual/Feel and UI stories have evidence docs with sign-off under `production/qa/evidence/`.
- Any Godot 4.6.2 behavior named by the governing ADRs is verified against `docs/engine-reference/godot/`.

## Stories

| # | Story | Type | Status | ADR |
|---|-------|------|--------|-----|
| 001 | [实体生命周期 1](story-001-1.md) | Config/Data | Ready | ADR-0007 |
| 002 | [实体生命周期 2](story-002-2.md) | Integration | Ready | ADR-0002 |
| 003 | [Single CRUD 1](story-003-single-crud-1.md) | Config/Data | Ready | ADR-0007 |
| 004 | [Single CRUD 2](story-004-single-crud-2.md) | Logic | Ready | ADR-0001 |
| 005 | [Final Value Integration 1](story-005-final-value-integration-1.md) | UI | Ready | ADR-0002 |
| 006 | [Final Value Integration 2](story-006-final-value-integration-2.md) | Integration | Ready | ADR-0002 |
| 007 | [Events](story-007-events.md) | UI | Ready | ADR-0002 |
| 008 | [Batch / Snapshot / Restore 1](story-008-batch-snapshot-restore-1.md) | Config/Data | Ready | ADR-0007 |
| 009 | [Batch / Snapshot / Restore 2](story-009-batch-snapshot-restore-2.md) | UI | Ready | ADR-0002 |
| 010 | [Edge Cases](story-010-edge-cases.md) | Integration | Ready | ADR-0002 |
| 011 | [Performance / Memory 1](story-011-performance-memory-1.md) | Logic | Ready | ADR-0001 |
| 012 | [Performance / Memory 2](story-012-performance-memory-2.md) | Logic | Ready | ADR-0001 |

## Next Step

Run `/story-readiness production/epics/attribute-system/story-001-*.md` before implementing the first story in this epic.
