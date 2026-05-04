# Epic: 产出乘数系统

> **Layer**: Core Gameplay
> **GDD**: design/gdd/output-multiplier-system.md
> **Architecture Module**: `OutputMultiplierSystem` (RefCounted) (Autoload 持有)
> **Status**: Ready
> **Stories**: Created (9 stories)

## Overview

产出乘数系统是资源产出速率与修正器/倍率引擎之间的翻译层。游戏中的每个资源（灵气、修为、灵石、药材、战斗经验）背后都有一个"产出倍率"——来自装备加成、技能天赋、境界突破、灵丹 Buff、区域效果等多个来源——这些来源各自属于不同的叠加池（池内先加总再乘、池间独立相乘）。产出乘数系统的核心职责是：**为每种资源定义具体的产出乘数来源集合、每个来源归属的叠加池、以及池间叠乘顺序**，然后将这些注册到修正器/倍率引擎，最终计算出该资源的"每 tick 产出量 = 基础产出 × 总倍率"，供自动产出系统和修炼系统直接使用。

Architecture ownership: `OutputMultiplierSystem (RefCounted)` owns 每秒产出率计算.

## Governing ADRs

| ADR | Decision Summary | Engine Risk |
|-----|------------------|-------------|
| ADR-0007: 修正器叠加顺序 | Use one `ModifierEngine` service with a three-stage pipeline: `base + add_sum`, then same-pool additive percentage multipliers, then cross-pool multiplication. MVP pools are `equipment`, `realm`, `zone`, and `buff`. Targets are strings such as `player.atk` and `lingqi_production`. | LOW |
| ADR-0010: ResourceSystem 不可变 BigNumber 策略 | ResourceSystem stores BigNumber values as immutable value objects. Operations calculate new BigNumber instances and replace the stored value. `add()` returns the actual added amount. `spend()` is atomic per resource. `batch_add()` executes sequential per-resource adds and returns a dictionary of actual additions; it does not roll back earlier successful changes. | LOW |

## GDD Requirements

| TR-ID | Requirement | ADR Coverage |
|-------|-------------|--------------|
| TR-output-multiplier-001 | OutputMultiplierSystem translates production config and modifier pools into per-resource production rates and tick amounts. | ADR-0007, ADR-0010 |

**Untraced requirements**: 0 known in `docs/architecture/tr-registry.yaml`; the registry currently exposes one stable system-level TR for this GDD.

## Engine Risk

**LOW** — highest governing ADR knowledge risk. Engine baseline: Godot 4.6.2.

## Cross-Epic Dependencies

- Upstream: 修正器/倍率引擎, 数据配置系统, 事件总线, 大数值系统
- Downstream: 调试控制台, 自动产出系统

## Definition of Done

This epic is complete when:
- All stories are implemented, reviewed, and closed via `/story-done`.
- All acceptance criteria from `design/gdd/output-multiplier-system.md` are verified.
- All Logic and Integration stories have passing test files under `tests/`.
- All Visual/Feel and UI stories have evidence docs with sign-off under `production/qa/evidence/`.
- Any Godot 4.6.2 behavior named by the governing ADRs is verified against `docs/engine-reference/godot/`.

## Stories

| # | Story | Type | Status | ADR |
|---|-------|------|--------|-----|
| 001 | [Configuration and Initialization](story-001-configuration-and-initialization.md) | UI | Ready | ADR-0007 |
| 002 | [Activation and Source Registration 1](story-002-activation-and-source-registration-1.md) | UI | Ready | ADR-0007 |
| 003 | [Activation and Source Registration 2](story-003-activation-and-source-registration-2.md) | UI | Ready | ADR-0007 |
| 004 | [Query and Formula Verification 1](story-004-query-and-formula-verification-1.md) | UI | Ready | ADR-0007 |
| 005 | [Query and Formula Verification 2](story-005-query-and-formula-verification-2.md) | UI | Ready | ADR-0007 |
| 006 | [Within-Pool Additivity and Cross-Pool Multiplicativity](story-006-within-pool-additivity-and-cross-pool-multiplicativity.md) | UI | Ready | ADR-0007 |
| 007 | [Deactivation and Lifecycle](story-007-deactivation-and-lifecycle.md) | UI | Ready | ADR-0007 |
| 008 | [Event Emission](story-008-event-emission.md) | UI | Ready | ADR-0007 |
| 009 | [Error Handling](story-009-error-handling.md) | Logic | Ready | ADR-0007 |

## Next Step

Run `/story-readiness production/epics/output-multiplier-system/story-001-*.md` before implementing the first story in this epic.
