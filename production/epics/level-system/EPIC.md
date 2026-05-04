# Epic: 等级系统

> **Layer**: Feature
> **GDD**: design/gdd/level-system.md
> **Architecture Module**: `LevelSystem` (RefCounted) (Autoload 持有)
> **Status**: Ready
> **Stories**: Created (12 stories)

## Overview

等级系统是玩家成长曲线的核心驱动器。玩家通过自动战斗、挂机探索等途径累积 `exp`（战斗经验），本系统在 exp 跨过阈值时把等级 +1，同时把 6 项 MVP 属性（`hp_max / atk / def / spd / crit_rate / crit_dmg`）的基础值按成长公式提升一档。等级越高 → 属性越强 → 玩家可挑战更难的区域 → 区域 exp 产出更高 → 等级再提升——这构成 game-concept §10.2 "第一条可玩闭环"中"等级提升 → 强化角色 → 推进区域"的关键三连环节。在 HUD 上，玩家看到的不是"系统在跑什么"，而是"我又升了一级、攻击 +5、距离突破下一境界还差 7 级"——这种"今天比昨天更强、且可量化"的体验是等级系统直接服务的玩家幻想。

Architecture ownership: `LevelSystem (RefCounted)` owns 等级/经验状态, 升级触发.

## Governing ADRs

| ADR | Decision Summary | Engine Risk |
|-----|------------------|-------------|
| ADR-0013: FormulaEngine 表达式 DSL 深度 | Implement a bounded expression evaluator, not a general-purpose DSL. It supports arithmetic, variables, selected safe functions, boolean-to-float comparisons, simple ternary-style conditionals where specified by GDD, and formula caching. The evaluator returns `float`; systems convert to/from BigNumber where appropriate. | LOW |
| ADR-0007: 修正器叠加顺序 | Use one `ModifierEngine` service with a three-stage pipeline: `base + add_sum`, then same-pool additive percentage multipliers, then cross-pool multiplication. MVP pools are `equipment`, `realm`, `zone`, and `buff`. Targets are strings such as `player.atk` and `lingqi_production`. | LOW |
| ADR-0010: ResourceSystem 不可变 BigNumber 策略 | ResourceSystem stores BigNumber values as immutable value objects. Operations calculate new BigNumber instances and replace the stored value. `add()` returns the actual added amount. `spend()` is atomic per resource. `batch_add()` executes sequential per-resource adds and returns a dictionary of actual additions; it does not roll back earlier successful changes. | LOW |

## GDD Requirements

| TR-ID | Requirement | ADR Coverage |
|-------|-------------|--------------|
| TR-level-system-001 | LevelSystem handles level/experience/realm progression using approved data, formulas, resource, modifier, event, and save boundaries. | ADR-0013, ADR-0007, ADR-0010 |

**Untraced requirements**: 0 known in `docs/architecture/tr-registry.yaml`; the registry currently exposes one stable system-level TR for this GDD.

## Engine Risk

**LOW** — highest governing ADR knowledge risk. Engine baseline: Godot 4.6.2.

## Cross-Epic Dependencies

- Upstream: 属性系统, 公式引擎, 资源系统, 修正器/倍率引擎, 事件总线, 大数值系统, 数据配置系统, 存档系统
- Downstream: 半自动战斗系统, 地图推进系统

## Definition of Done

This epic is complete when:
- All stories are implemented, reviewed, and closed via `/story-done`.
- All acceptance criteria from `design/gdd/level-system.md` are verified.
- All Logic and Integration stories have passing test files under `tests/`.
- All Visual/Feel and UI stories have evidence docs with sign-off under `production/qa/evidence/`.
- Any Godot 4.6.2 behavior named by the governing ADRs is verified against `docs/engine-reference/godot/`.

## Stories

| # | Story | Type | Status | ADR |
|---|-------|------|--------|-----|
| 001 | [实体生命周期](story-001-001-config-data.md) | Config/Data | Ready | ADR-0013 |
| 002 | [gain_exp 主路径 1](story-002-gain-exp-1.md) | Integration | Ready | ADR-0013 |
| 003 | [gain_exp 主路径 2](story-003-gain-exp-2.md) | Integration | Ready | ADR-0013 |
| 004 | [境界跨越 + modifier](story-004-modifier.md) | Logic | Ready | ADR-0007 |
| 005 | [save.loaded 重建 1](story-005-save-loaded-1.md) | Integration | Ready | ADR-0013 |
| 006 | [save.loaded 重建 2](story-006-save-loaded-2.md) | Integration | Ready | ADR-0013 |
| 007 | [reset 接口](story-007-reset.md) | Integration | Ready | ADR-0013 |
| 008 | [公式求值 1](story-008-1.md) | Logic | Ready | ADR-0007 |
| 009 | [公式求值 2](story-009-2.md) | Logic | Ready | ADR-0007 |
| 010 | [公式异常 / 边界](story-010-010-integration.md) | Integration | Ready | ADR-0013 |
| 011 | [跨系统集成](story-011-011-logic.md) | Logic | Ready | ADR-0007 |
| 012 | [性能 / 内存](story-012-012-logic.md) | Logic | Ready | ADR-0007 |

## Next Step

Run `/story-readiness production/epics/level-system/story-001-*.md` before implementing the first story in this epic.
