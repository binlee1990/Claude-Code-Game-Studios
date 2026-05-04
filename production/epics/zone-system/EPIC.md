# Epic: 区域系统

> **Layer**: Feature Integration
> **GDD**: design/gdd/zone-system.md
> **Architecture Module**: `ZoneSystem` (Autoload)
> **Status**: Ready
> **Stories**: Created (2 stories)

## Overview

区域系统让"去哪里挂机"成为早期最重要的低频选择。区域不是单纯背景名，而是敌人强度、奖励结构、解锁门槛和产出倾向的集合。玩家换区时，半自动战斗获得新的敌人池，掉落系统获得区域上下文，HUD 展示风险和收益。MVP 至少需要 3 个普通挂机区域，对应 game-concept 的最小闭环。

Architecture ownership: `ZoneSystem` owns 区域数据查询.

## Governing ADRs

| ADR | Decision Summary | Engine Risk |
|-----|------------------|-------------|
| ADR-0005: 数据配置加载策略 | Implement `DataConfig` as a `RefCounted` service held by an Autoload host. It scans JSON files under `res://assets/data/`, parses them with Godot JSON APIs, stores raw dictionaries in memory, and returns raw values to consumers. BigNumber conversion is performed by consumers according to their schemas. | MEDIUM |

## GDD Requirements

| TR-ID | Requirement | ADR Coverage |
|-------|-------------|--------------|
| TR-zone-system-001 | ZoneSystem exposes current and unlocked zone data from DataConfig and coordinates with combat/progression consumers. | ADR-0005 |

**Untraced requirements**: 0 known in `docs/architecture/tr-registry.yaml`; the registry currently exposes one stable system-level TR for this GDD.

## Engine Risk

**MEDIUM** — highest governing ADR knowledge risk. Engine baseline: Godot 4.6.2.

## Cross-Epic Dependencies

- Upstream: 敌人数据库, 数据配置系统
- Downstream: 地图推进系统, 挂机探索系统, HUD 系统

## Definition of Done

This epic is complete when:
- All stories are implemented, reviewed, and closed via `/story-done`.
- All acceptance criteria from `design/gdd/zone-system.md` are verified.
- All Logic and Integration stories have passing test files under `tests/`.
- All Visual/Feel and UI stories have evidence docs with sign-off under `production/qa/evidence/`.
- Any Godot 4.6.2 behavior named by the governing ADRs is verified against `docs/engine-reference/godot/`.

## Stories

| # | Story | Type | Status | ADR |
|---|-------|------|--------|-----|
| 001 | [all are queryable by id and sorted by order](story-001-all-are-queryable-by-id-and-sorted-by-order.md) | Integration | Ready | ADR-0005 |
| 002 | [current zone does not change and lock reason is returned](story-002-current-zone-does-not-change-and-lock-reason-is-returned.md) | Logic | Ready | ADR-0005 |

## Next Step

Run `/story-readiness production/epics/zone-system/story-001-*.md` before implementing the first story in this epic.
