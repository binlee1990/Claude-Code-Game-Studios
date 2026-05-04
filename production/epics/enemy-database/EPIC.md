# Epic: 敌人数据库

> **Layer**: Feature
> **GDD**: design/gdd/enemy-database.md
> **Architecture Module**: `EnemyDatabase` (Autoload)
> **Status**: Ready
> **Stories**: Created (2 stories)

## Overview

敌人数据库把"一个区域会遇到什么怪"从代码中移到数据表。它不执行战斗，不决定掉落结果，也不持有战斗中的当前血量；它只定义敌人模板和实例化所需数据。MVP 需要它来支撑简单自动战斗、区域推进和离线战斗模拟：三者必须消费同一套敌人属性，否则在线/离线战斗会出现结果漂移。

Architecture ownership: `EnemyDatabase` owns 敌人模板查询.

## Governing ADRs

| ADR | Decision Summary | Engine Risk |
|-----|------------------|-------------|
| ADR-0005: 数据配置加载策略 | Implement `DataConfig` as a `RefCounted` service held by an Autoload host. It scans JSON files under `res://assets/data/`, parses them with Godot JSON APIs, stores raw dictionaries in memory, and returns raw values to consumers. BigNumber conversion is performed by consumers according to their schemas. | MEDIUM |

## GDD Requirements

| TR-ID | Requirement | ADR Coverage |
|-------|-------------|--------------|
| TR-enemy-database-001 | EnemyDatabase exposes static enemy template data from DataConfig without owning combat-local mutable state. | ADR-0005 |

**Untraced requirements**: 0 known in `docs/architecture/tr-registry.yaml`; the registry currently exposes one stable system-level TR for this GDD.

## Engine Risk

**MEDIUM** — highest governing ADR knowledge risk. Engine baseline: Godot 4.6.2.

## Cross-Epic Dependencies

- Upstream: 数据配置系统, 属性系统
- Downstream: 掉落系统, 半自动战斗系统, 区域系统

## Definition of Done

This epic is complete when:
- All stories are implemented, reviewed, and closed via `/story-done`.
- All acceptance criteria from `design/gdd/enemy-database.md` are verified.
- All Logic and Integration stories have passing test files under `tests/`.
- All Visual/Feel and UI stories have evidence docs with sign-off under `production/qa/evidence/`.
- Any Godot 4.6.2 behavior named by the governing ADRs is verified against `docs/engine-reference/godot/`.

## Stories

| # | Story | Type | Status | ADR |
|---|-------|------|--------|-----|
| 001 | [`get_count() == 3`](story-001-get-count-3.md) | Config/Data | Ready | ADR-0005 |
| 002 | [only enemies tagged starter are returned](story-002-only-enemies-tagged-starter-are-returned.md) | Integration | Ready | ADR-0005 |

## Next Step

Run `/story-readiness production/epics/enemy-database/story-001-*.md` before implementing the first story in this epic.
