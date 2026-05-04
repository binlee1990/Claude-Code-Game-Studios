# Epic: 地图推进系统

> **Layer**: Feature Integration
> **GDD**: design/gdd/map-progression-system.md
> **Architecture Module**: `MapProgressionSystem` (服务)
> **Status**: Ready
> **Stories**: Created (2 stories)

## Overview

地图推进系统给 MVP 的三张普通挂机图提供进度结构。区域系统定义地图数据，半自动战斗提供胜负结果，等级系统提供玩家成长；本系统记录哪些区域已解锁、哪些已首通、下一张图需要什么条件，并在满足条件时发布解锁事件。它不选择敌人、不算战斗、不发奖励。

Architecture ownership: `MapProgressionSystem` owns 区域解锁逻辑.

## Governing ADRs

| ADR | Decision Summary | Engine Risk |
|-----|------------------|-------------|
| ADR-0013: FormulaEngine 表达式 DSL 深度 | Implement a bounded expression evaluator, not a general-purpose DSL. It supports arithmetic, variables, selected safe functions, boolean-to-float comparisons, simple ternary-style conditionals where specified by GDD, and formula caching. The evaluator returns `float`; systems convert to/from BigNumber where appropriate. | LOW |
| ADR-0002: 事件总线架构 | Use a global `EventBus` Autoload Node with string event names and `Dictionary` payloads. The bus dispatches events synchronously in the current frame. Exact subscriptions are the production path. Prefix pattern subscriptions exist only for debug tooling such as `event watch resource`. Coalesced events are allowed only for display refreshes where latest-state wins. | HIGH |
| ADR-0005: 数据配置加载策略 | Implement `DataConfig` as a `RefCounted` service held by an Autoload host. It scans JSON files under `res://assets/data/`, parses them with Godot JSON APIs, stores raw dictionaries in memory, and returns raw values to consumers. BigNumber conversion is performed by consumers according to their schemas. | MEDIUM |

## GDD Requirements

| TR-ID | Requirement | ADR Coverage |
|-------|-------------|--------------|
| TR-map-progression-001 | MapProgressionSystem unlocks and advances zones based on ZoneSystem, LevelSystem, and combat progression events. | ADR-0013, ADR-0002, ADR-0005 |

**Untraced requirements**: 0 known in `docs/architecture/tr-registry.yaml`; the registry currently exposes one stable system-level TR for this GDD.

## Engine Risk

**HIGH** — highest governing ADR knowledge risk. Engine baseline: Godot 4.6.2.

## Cross-Epic Dependencies

- Upstream: 区域系统, 等级系统
- Downstream: None listed in `systems-index.md`

## Definition of Done

This epic is complete when:
- All stories are implemented, reviewed, and closed via `/story-done`.
- All acceptance criteria from `design/gdd/map-progression-system.md` are verified.
- All Logic and Integration stories have passing test files under `tests/`.
- All Visual/Feel and UI stories have evidence docs with sign-off under `production/qa/evidence/`.
- Any Godot 4.6.2 behavior named by the governing ADRs is verified against `docs/engine-reference/godot/`.

## Stories

| # | Story | Type | Status | ADR |
|---|-------|------|--------|-----|
| 001 | [next zone becomes unlocked](story-001-next-zone-becomes-unlocked.md) | UI | Ready | ADR-0002 |
| 002 | [selection fails with lock reason](story-002-selection-fails-with-lock-reason.md) | Integration | Ready | ADR-0002 |

## Next Step

Run `/story-readiness production/epics/map-progression-system/story-001-*.md` before implementing the first story in this epic.
