# Epic: 战斗计算器

> **Layer**: Feature Integration
> **GDD**: design/gdd/combat-calculator.md
> **Architecture Module**: `CombatCalculator` (服务)
> **Status**: Done
> **Stories**: Created (2 stories)

## Overview

战斗计算器不控制战斗循环，也不显示战斗过程。它是一个纯函数式服务：给定玩家/敌人属性快照、战斗配置和种子，返回同样的结果。半自动战斗系统用它处理在线战斗，离线战斗模拟系统用它批量估算或复放战斗。这个共享点是高风险系统的核心缓解：在线与离线不能各写一套伤害公式。

Architecture ownership: `CombatCalculator` owns 伤害公式执行.

## Governing ADRs

| ADR | Decision Summary | Engine Risk |
|-----|------------------|-------------|
| ADR-0009: 在线/离线战斗路径统一 | Both online and offline combat use the same `CombatCalculator` for attack resolution and the same `LootSystem` for rewards. SemiAutoCombatSystem manages live encounter cadence and event publication. OfflineCombatSimulation uses snapshots and copied RNG states to run batched encounters, producing a draft consumed by OfflineRewardSettlement. | LOW |
| ADR-0007: 修正器叠加顺序 | Use one `ModifierEngine` service with a three-stage pipeline: `base + add_sum`, then same-pool additive percentage multipliers, then cross-pool multiplication. MVP pools are `equipment`, `realm`, `zone`, and `buff`. Targets are strings such as `player.atk` and `lingqi_production`. | LOW |
| ADR-0013: FormulaEngine 表达式 DSL 深度 | Implement a bounded expression evaluator, not a general-purpose DSL. It supports arithmetic, variables, selected safe functions, boolean-to-float comparisons, simple ternary-style conditionals where specified by GDD, and formula caching. The evaluator returns `float`; systems convert to/from BigNumber where appropriate. | LOW |
| ADR-0004: 确定性随机数架构 | Implement `RNGManager` as an Autoload with a 64-bit master seed and independent `RandomNumberGenerator` instances for `COMBAT`, `LOOT`, `EVENT`, and `AFFIX`, plus optional named extension streams. Derive stream seeds from master seed using FNV-1a. Offline simulations operate on saved state copies and discard them after settlement. | MEDIUM |

## GDD Requirements

| TR-ID | Requirement | ADR Coverage |
|-------|-------------|--------------|
| TR-combat-calculator-001 | CombatCalculator provides the shared attack/damage resolution path for online and offline combat. | ADR-0009, ADR-0007, ADR-0013, ADR-0004 |

**Untraced requirements**: 0 known in `docs/architecture/tr-registry.yaml`; the registry currently exposes one stable system-level TR for this GDD.

## Engine Risk

**MEDIUM** — highest governing ADR knowledge risk. Engine baseline: Godot 4.6.2.

## Cross-Epic Dependencies

- Upstream: 属性系统, 公式引擎, 随机数与种子系统, 修正器/倍率引擎
- Downstream: 半自动战斗系统

## Definition of Done

This epic is complete when:
- All stories are implemented, reviewed, and closed via `/story-done`.
- All acceptance criteria from `design/gdd/combat-calculator.md` are verified.
- All Logic and Integration stories have passing test files under `tests/`.
- All Visual/Feel and UI stories have evidence docs with sign-off under `production/qa/evidence/`.
- Any Godot 4.6.2 behavior named by the governing ADRs is verified against `docs/engine-reference/godot/`.

## Stories

| # | Story | Type | Status | ADR |
|---|-------|------|--------|-----|
| 001 | [CombatResult is identical](story-001-combatresult-is-identical.md) | Integration | Done | ADR-0009 |
| 002 | [all attacks use crit_dmg multiplier](story-002-all-attacks-use-crit-dmg-multiplier.md) | Logic | Done | ADR-0007 |

## Next Step

Run `/story-readiness production/epics/combat-calculator/story-001-*.md` before implementing the first story in this epic.
