# Epic: 数值格式化系统

> **Layer**: Core Data
> **GDD**: design/gdd/number-formatting-system.md
> **Architecture Module**: `NumberFormatter` (工具类)
> **Status**: Done
> **Stories**: Created (8 stories)

## Overview

数值格式化系统是游戏所有数值显示的统一出口。它将大数值系统的内部表示 `{mantissa, exponent}` 转换为玩家可读的显示字符串，支持三个格式层级：

Architecture ownership: `NumberFormatter` owns 格式化规则, 缩写映射.

## Governing ADRs

| ADR | Decision Summary | Engine Risk |
|-----|------------------|-------------|
| ADR-0014: NumberFormatter 缩写映射策略 | Implement `NumberFormatter` as a utility service with a hard-coded MVP Chinese unit table: `万, 亿, 兆, 京, 垓, 秭, 穰, 沟, 涧, 正, 载, 极`. Values above `10^48` use scientific notation. This table stays code-owned for MVP; DataConfig-driven formatting can be revisited Post-MVP if localization or content scale requires it. | LOW |

## GDD Requirements

| TR-ID | Requirement | ADR Coverage |
|-------|-------------|--------------|
| TR-number-formatting-001 | NumberFormatter provides the single formatting path for BigNumber display using direct, Chinese-unit, and scientific notation ranges. | ADR-0014 |

**Untraced requirements**: 0 known in `docs/architecture/tr-registry.yaml`; the registry currently exposes one stable system-level TR for this GDD.

## Engine Risk

**LOW** — highest governing ADR knowledge risk. Engine baseline: Godot 4.6.2.

## Cross-Epic Dependencies

- Upstream: 大数值系统
- Downstream: 调试控制台, HUD 系统

## Definition of Done

This epic is complete when:
- All stories are implemented, reviewed, and closed via `/story-done`.
- All acceptance criteria from `design/gdd/number-formatting-system.md` are verified.
- All Logic and Integration stories have passing test files under `tests/`.
- All Visual/Feel and UI stories have evidence docs with sign-off under `production/qa/evidence/`.
- Any Godot 4.6.2 behavior named by the governing ADRs is verified against `docs/engine-reference/godot/`.

## Stories

| # | Story | Type | Status | ADR |
|---|-------|------|--------|-----|
| 001 | [返回 `"0"`](story-001-0.md) | Logic | Done | ADR-0014 |
| 002 | [返回 `"9,999"`](story-002-9-999.md) | Logic | Done | ADR-0014 |
| 003 | [返回 `"567万"`](story-003-567.md) | Logic | Done | ADR-0014 |
| 004 | [返回 `"1234极"`](story-004-1234.md) | Logic | Done | ADR-0014 |
| 005 | [返回 `"MAX"`](story-005-max.md) | Logic | Done | ADR-0014 |
| 006 | [返回 `"1.00亿"`（舍入跨单位）](story-006-1-00.md) | Logic | Done | ADR-0014 |
| 007 | [返回 `"万"`](story-007-007-ui.md) | UI | Done | ADR-0014 |
| 008 | [总耗时 < 1ms](story-008-1ms.md) | Logic | Done | ADR-0014 |

## Next Step

Run `/story-readiness production/epics/number-formatting-system/story-001-*.md` before implementing the first story in this epic.
