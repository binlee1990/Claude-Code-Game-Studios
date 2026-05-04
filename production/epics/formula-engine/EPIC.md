# Epic: 公式引擎

> **Layer**: Core Data
> **GDD**: design/gdd/formula-engine.md
> **Architecture Module**: `FormulaEngine` (静态工具)
> **Status**: Done
> **Stories**: Created (10 stories)

## Overview

公式引擎是整个游戏的统一数学表达式求值服务层。所有涉及数值计算的机制——修炼产出、资源消耗、伤害公式、成长曲线、软上限、掉落权重——都通过公式引擎计算，而不是在各自系统中硬编码公式逻辑。这一集中化设计确保公式定义可配置、可热更新、可单测，且所有系统共享同一套数学规则。

Architecture ownership: `FormulaEngine` owns 表达式解析, 变量上下文.

## Governing ADRs

| ADR | Decision Summary | Engine Risk |
|-----|------------------|-------------|
| ADR-0013: FormulaEngine 表达式 DSL 深度 | Implement a bounded expression evaluator, not a general-purpose DSL. It supports arithmetic, variables, selected safe functions, boolean-to-float comparisons, simple ternary-style conditionals where specified by GDD, and formula caching. The evaluator returns `float`; systems convert to/from BigNumber where appropriate. | LOW |

## GDD Requirements

| TR-ID | Requirement | ADR Coverage |
|-------|-------------|--------------|
| TR-formula-engine-001 | FormulaEngine evaluates bounded cached float expressions and safe helper functions for growth, combat, and balance formulas. | ADR-0013 |

**Untraced requirements**: 0 known in `docs/architecture/tr-registry.yaml`; the registry currently exposes one stable system-level TR for this GDD.

## Engine Risk

**LOW** — highest governing ADR knowledge risk. Engine baseline: Godot 4.6.2.

## Cross-Epic Dependencies

- Upstream: 大数值系统, 随机数与种子系统
- Downstream: 修正器/倍率引擎, 等级系统, 战斗计算器

## Definition of Done

This epic is complete when:
- All stories are implemented, reviewed, and closed via `/story-done`.
- All acceptance criteria from `design/gdd/formula-engine.md` are verified.
- All Logic and Integration stories have passing test files under `tests/`.
- All Visual/Feel and UI stories have evidence docs with sign-off under `production/qa/evidence/`.
- Any Godot 4.6.2 behavior named by the governing ADRs is verified against `docs/engine-reference/godot/`.

## Stories

| # | Story | Type | Status | ADR |
|---|-------|------|--------|-----|
| 001 | [结果为 `15.0`](story-001-15-0.md) | Config/Data | Done | ADR-0013 |
| 002 | [多余变量被忽略，结果正确](story-002-002-config-data.md) | Config/Data | Done | ADR-0013 |
| 003 | [返回 `0.0`，打印警告；再次调用返回 `0.0` 不重复解析](story-003-0-0-0-0.md) | Config/Data | Done | ADR-0013 |
| 004 | [结果为 `1.0`（布尔 true → float）](story-004-1-0-true-float.md) | Config/Data | Done | ADR-0013 |
| 005 | [结果为 `120.0`](story-005-120-0.md) | Logic | Done | ADR-0013 |
| 006 | [结果为 `50.0`](story-006-50-0.md) | Logic | Done | ADR-0013 |
| 007 | [结果为 `30.0`](story-007-30-0.md) | Logic | Done | ADR-0013 |
| 008 | [缓存清空，后续调用触发重新解析](story-008-008-config-data.md) | Config/Data | Done | ADR-0013 |
| 009 | [结果为 `-7.0`（负数允许）](story-009-7-0.md) | Config/Data | Done | ADR-0013 |
| 010 | [threshold 钳位到 `1.0`，打印警告](story-010-threshold-1-0.md) | Logic | Done | ADR-0013 |

## Next Step

Run `/story-readiness production/epics/formula-engine/story-001-*.md` before implementing the first story in this epic.
