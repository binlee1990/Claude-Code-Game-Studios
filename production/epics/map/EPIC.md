# Epic: Map / Coordinates

> **Layer**: Foundation
> **GDD**: design/gdd/map.md
> **Architecture Module**: Map (Foundation Layer)
> **Status**: Ready
> **Stories**: 4 stories created — see below

## Stories

| # | Story | Type | Status | ADR |
|---|-------|------|--------|-----|
| 001 | GridSpace — 坐标转换边界 | Logic | Ready | ADR-0001 |
| 002 | CSV 地图加载 + TileMapLayer 渲染 | Logic | Ready | ADR-0005 |
| 003 | 网格拓扑 — 邻接查询 + 边界检查 | Logic | Ready | ADR-0005 |
| 004 | 占用追踪 — place/remove/get_unit_at | Logic | Ready | ADR-0005 |

## Overview

实现游戏棋盘的空间拓扑层：一个数据驱动的矩形网格，支持三种瓦片状态（walkable/blocked/obstacle），通过 CSV 加载，以 Godot TileMapLayer 渲染。GridSpace 作为唯一的坐标转换权威（grid↔world），通过 DI 传递给下游系统。Map 持有运行时占用字典，暴露 `is_walkable()`、`get_neighbors()`、`place_unit()`/`remove_unit()` 查询接口。这是整个 SRPG 骨架的地基——所有其他 7 个系统依赖 Map 回答"在哪里"的问题。

## Governing ADRs

| ADR | Decision Summary | Engine Risk |
|-----|-----------------|-------------|
| ADR-0001: GridSpace | GridSpace 为 RefCounted，封装 TILE_SIZE=64，是 grid↔world 转换的唯一权威；禁止任何其他文件内联坐标运算 | LOW |
| ADR-0005: Map CSV | Map 从 CSV 文件加载（`cols,rows` header + `.`/`#`/`O` 字符），持有 `Dictionary[Vector2i, Unit]` 占用追踪，暴露 `get_neighbors()`/`is_walkable()`/`place_unit()`/`remove_unit()`/`get_unit_at()` | LOW |

## GDD Requirements

| TR-ID | Requirement | ADR Coverage |
|-------|-------------|--------------|
| TR-map-001 | GridSpace 作为唯一坐标转换权威：world_to_grid / grid_to_world / tile_center | ADR-0001 ✅ |
| TR-map-002 | TileMapLayer 渲染 + CSV 数据驱动地图加载（cols,rows header + 每格字符 . # O） | ADR-0005 ✅ |
| TR-map-003 | 原子 move_unit(unit, from, to) → bool 确保占用一致性 | ADR-0005 ✅ |
| TR-map-004 | 三种不可变瓦片状态：walkable / blocked / obstacle，以 TileMapLayer atlas tiles 渲染 | ADR-0005 ✅ |
| TR-map-005 | 4-邻接 von Neumann 邻居查询：get_neighbors(coord) → Array[Vector2i]，仅界内，不滤可通行性 | ADR-0005 ✅ |
| TR-map-006 | 运行时占用追踪：Dictionary[Vector2i, Unit] 实现 O(1) 反向查询 via get_unit_at(coord) | ADR-0005 ✅ |
| TR-map-007 | TILE_SIZE=64 常量封装在 GridSpace 中——禁止其他文件引用 TILE_SIZE 或内联 * 64 / / 64 | ADR-0001 ✅ |
| TR-map-008 | CSV 加载时校验：维度在 [8,32] 内，行列数匹配 header，仅含 . # O 字符，文件存在 | ADR-0005 ✅ |
| TR-map-009 | place_unit(coord) / remove_unit(coord) 含校验（越界、不可通行、已占用、空瓦片）返回 bool | ADR-0005 ✅ |

## Definition of Done

本 Epic 完成条件：
- 所有 Story 已实现、审查并经由 `/story-done` 关闭
- `design/gdd/map.md` 中所有验收标准已通过
- 全部 Logic 和 Integration Story 在 `tests/` 中有通过的测试文件
- 全部 Visual/Feel 和 UI Story 在 `production/qa/evidence/` 中有签核证据文档

## Next Step

Run `/create-stories map` 将本 Epic 拆解为可实施的 Story。
