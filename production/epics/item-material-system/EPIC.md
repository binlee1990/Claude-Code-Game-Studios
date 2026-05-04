# Epic: 物品/材料系统

> **Layer**: Core Gameplay
> **GDD**: design/gdd/item-material-system.md
> **Architecture Module**: `ItemRegistry` (RefCounted) (Autoload 持有)
> **Status**: Ready
> **Stories**: Created (17 stories)

## Overview

物品/材料系统是游戏中所有物品（material、equipment、consumable、quest_item……）元数据的统一注册和查询服务。它在游戏启动时通过数据配置系统加载 `items.json`，把所有物品定义（中文名、图标路径、稀有度、分类标签、本地化 key 等）存入内存索引，并对外提供 `ItemRegistry.get(item_id)`、`query_by_item_class(cat)`、`query_by_tag(tag)` 等类型化查询 API。任何系统拿到一个 `item_id` 字符串后，**通过本系统把它翻译成"这是什么、怎么显示、属于哪类"**——这是物品体系跨系统通信的语义桥梁。

Architecture ownership: `ItemRegistry (RefCounted)` owns 静态物品定义查询.

## Governing ADRs

| ADR | Decision Summary | Engine Risk |
|-----|------------------|-------------|
| ADR-0005: 数据配置加载策略 | Implement `DataConfig` as a `RefCounted` service held by an Autoload host. It scans JSON files under `res://assets/data/`, parses them with Godot JSON APIs, stores raw dictionaries in memory, and returns raw values to consumers. BigNumber conversion is performed by consumers according to their schemas. | MEDIUM |

## GDD Requirements

| TR-ID | Requirement | ADR Coverage |
|-------|-------------|--------------|
| TR-item-material-001 | ItemRegistry loads immutable item/material definitions from DataConfig and exposes query-only metadata APIs. | ADR-0005 |

**Untraced requirements**: 0 known in `docs/architecture/tr-registry.yaml`; the registry currently exposes one stable system-level TR for this GDD.

## Engine Risk

**MEDIUM** — highest governing ADR knowledge risk. Engine baseline: Godot 4.6.2.

## Cross-Epic Dependencies

- Upstream: 数据配置系统, 大数值系统
- Downstream: 存储上限系统, 掉落系统

## Definition of Done

This epic is complete when:
- All stories are implemented, reviewed, and closed via `/story-done`.
- All acceptance criteria from `design/gdd/item-material-system.md` are verified.
- All Logic and Integration stories have passing test files under `tests/`.
- All Visual/Feel and UI stories have evidence docs with sign-off under `production/qa/evidence/`.
- Any Godot 4.6.2 behavior named by the governing ADRs is verified against `docs/engine-reference/godot/`.

## Stories

| # | Story | Type | Status | ADR |
|---|-------|------|--------|-----|
| 001 | [A. 加载与配置（11 条） 1](story-001-a-11-1.md) | Config/Data | Ready | ADR-0005 |
| 002 | [A. 加载与配置（11 条） 2](story-002-a-11-2.md) | Config/Data | Ready | ADR-0005 |
| 003 | [A. 加载与配置（11 条） 3](story-003-a-11-3.md) | Config/Data | Ready | ADR-0005 |
| 004 | [A. 加载与配置（11 条） 4](story-004-a-11-4.md) | Config/Data | Ready | ADR-0005 |
| 005 | [B. 查询 API（12 条） 1](story-005-b-api-12-1.md) | Logic | Ready | ADR-0005 |
| 006 | [B. 查询 API（12 条） 2](story-006-b-api-12-2.md) | Logic | Ready | ADR-0005 |
| 007 | [B. 查询 API（12 条） 3](story-007-b-api-12-3.md) | UI | Ready | ADR-0005 |
| 008 | [B. 查询 API（12 条） 4](story-008-b-api-12-4.md) | Logic | Ready | ADR-0005 |
| 009 | [C. 拷贝陷阱（4 条）](story-009-c-4.md) | Logic | Ready | ADR-0005 |
| 010 | [D. 启动时序（2 条）](story-010-d-2.md) | UI | Ready | ADR-0005 |
| 011 | [E. 热重载（4 条） 1](story-011-e-4-1.md) | UI | Ready | ADR-0005 |
| 012 | [E. 热重载（4 条） 2](story-012-e-4-2.md) | Config/Data | Ready | ADR-0005 |
| 013 | [F. 性能（6 条） 1](story-013-f-6-1.md) | Config/Data | Ready | ADR-0005 |
| 014 | [F. 性能（6 条） 2](story-014-f-6-2.md) | Config/Data | Ready | ADR-0005 |
| 015 | [G. Lifecycle 事件（2 条）](story-015-g-lifecycle-2.md) | Config/Data | Ready | ADR-0005 |
| 016 | [H. 跨系统边界（1 条）](story-016-h-1.md) | Integration | Ready | ADR-0005 |
| 017 | [I. 内部一致性（1 条）](story-017-i-1.md) | Logic | Ready | ADR-0005 |

## Next Step

Run `/story-readiness production/epics/item-material-system/story-001-*.md` before implementing the first story in this epic.
