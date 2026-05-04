# Epic: 数据配置系统

> **Layer**: Core Data
> **GDD**: design/gdd/data-config-system.md
> **Architecture Module**: `DataConfig` (RefCounted) (Autoload 持有)
> **Status**: Ready
> **Stories**: Created (6 stories)

## Overview

数据配置系统是游戏的统一数据加载、缓存和查询服务。所有游戏内容——角色、怪物、装备、技能、掉落表、区域、建筑、配方、公式——均通过外部配置文件定义，由本系统在启动时加载到内存，并提供 `table_name + record_id` 的查询接口。

Architecture ownership: `DataConfig (RefCounted)` owns JSON 配置表缓存, 加载/热重载.

## Governing ADRs

| ADR | Decision Summary | Engine Risk |
|-----|------------------|-------------|
| ADR-0005: 数据配置加载策略 | Implement `DataConfig` as a `RefCounted` service held by an Autoload host. It scans JSON files under `res://assets/data/`, parses them with Godot JSON APIs, stores raw dictionaries in memory, and returns raw values to consumers. BigNumber conversion is performed by consumers according to their schemas. | MEDIUM |
| ADR-0008: Autoload 初始化顺序 | Use explicit Autoload order in `project.godot`: | MEDIUM |

## GDD Requirements

| TR-ID | Requirement | ADR Coverage |
|-------|-------------|--------------|
| TR-data-config-001 | DataConfig loads MVP JSON tables, keeps a schema-agnostic memory cache, and exposes read-only table/record/query access. | ADR-0005, ADR-0008 |

**Untraced requirements**: 0 known in `docs/architecture/tr-registry.yaml`; the registry currently exposes one stable system-level TR for this GDD.

## Engine Risk

**MEDIUM** — highest governing ADR knowledge risk. Engine baseline: Godot 4.6.2.

## Cross-Epic Dependencies

- Upstream: 大数值系统
- Downstream: 存档系统, 资源系统, 属性系统, 物品/材料系统, 产出乘数系统, 调试控制台, 等级系统, 敌人数据库, 区域系统

## Definition of Done

This epic is complete when:
- All stories are implemented, reviewed, and closed via `/story-done`.
- All acceptance criteria from `design/gdd/data-config-system.md` are verified.
- All Logic and Integration stories have passing test files under `tests/`.
- All Visual/Feel and UI stories have evidence docs with sign-off under `production/qa/evidence/`.
- Any Godot 4.6.2 behavior named by the governing ADRs is verified against `docs/engine-reference/godot/`.

## Stories

| # | Story | Type | Status | ADR |
|---|-------|------|--------|-----|
| 001 | [返回 `{"name": "史莱姆", "hp": "100"}`](story-001-name-hp-100.md) | Config/Data | Done | ADR-0005 |
| 002 | [返回含 3 个键的 Dictionary](story-002-3-dictionary.md) | Config/Data | Done | ADR-0005 |
| 003 | [该表为空，其他表正常加载，打印错误含文件路径](story-003-003-config-data.md) | Config/Data | Done | ADR-0005 |
| 004 | [后者覆盖前者，打印警告](story-004-004-config-data.md) | Config/Data | Done | ADR-0005 |
| 005 | [无操作](story-005-005-config-data.md) | Config/Data | Done | ADR-0005 |
| 006 | [`tags` 为 `\["beast", "slime"\]`（Array 类型）](story-006-tags-beast-slime-array.md) | Config/Data | Ready | ADR-0005 |

## Next Step

Run `/story-readiness production/epics/data-config-system/story-001-*.md` before implementing the first story in this epic.
