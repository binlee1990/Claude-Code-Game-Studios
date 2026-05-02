# Epic: Movement

> **Layer**: Feature
> **GDD**: design/gdd/movement.md
> **Architecture Module**: MovementResolver (Feature Layer)
> **Status**: Ready
> **Stories**: 4 stories created

## Stories
| # | Story | Type | Status | ADR |
|---|-------|------|--------|-----|
| 001 | BFS 可达范围 + Manhattan 距离 | Logic | Done | ADR-0006 |
| 002 | MovementResult + 路径重建 | Logic | Done | ADR-0006 |
| 003 | 移动执行 + Map 集成 | Integration | Done | ADR-0006 |
| 004 | Weighted Terrain Movement — cost-aware reachability and paths | Logic | Done | ADR-0006 |

## Overview

实现移动范围计算系统：MovementResolver 为 RefCounted 纯函数，输入单位位置+移动力+Map 拓扑，输出 MovementResult 不可变数据对象（可达瓦片集合 + 父映射供路径重建）。MVP 的全普通地形行为仍等价于 BFS；Sprint 9 在内部升级为 cost-aware 搜索，以支持 rough terrain cost=2。Manhattan 距离公式归属于本系统（`|r1-r2| + |c1-c2|`）。Map.move_unit() 原子写入保证占用一致性。本系统消费 Map.get_neighbors()/is_walkable()/get_movement_cost()，向 UI（高亮渲染）和 AI（决策空间）输出可达范围。

## Governing ADRs

| ADR | Decision Summary | Engine Risk |
|-----|-----------------|-------------|
| ADR-0006: Movement BFS | MovementResolver 为 RefCounted 纯函数；在 Map 网格上计算可达瓦片，受 mov 属性限制；MovementResult 为不可变数据对象；Manhattan 距离公式归属于本系统。Sprint 9 保持接口并将内部搜索升级为 movement-cost aware。 | LOW |

## GDD Requirements

| TR-ID | Requirement | ADR Coverage |
|-------|-------------|--------------|
| TR-mov-001 | BFS 可达瓦片计算（在 Map 网格上，按 mov 属性限制步数） | ADR-0006 ✅ |
| TR-mov-002 | MovementResult 不可变数据对象（reachable: Array[Vector2i], parents: Dictionary） | ADR-0006 ✅ |
| TR-mov-003 | MovementResolver 为 RefCounted 纯函数（无状态，可测试无场景树） | ADR-0006 ✅ |
| TR-mov-004 | Map.move_unit() 原子要求（place+remove 在单次调用中完成） | ADR-0006 ✅ |
| TR-mov-005 | Manhattan 距离公式所有权：`\|r1-r2\| + \|c1-c2\|` | ADR-0006 ✅ |
| TR-mov-006 | BFS 父映射路径重建（从目标瓦片回溯到起点） | ADR-0006 ✅ |

## Definition of Done

本 Epic 完成条件：
- 所有 Story 已实现、审查并经由 `/story-done` 关闭
- `design/gdd/movement.md` 中所有验收标准已通过
- 全部 Logic Story 在 `tests/unit/movement/` 中有通过的测试文件

## Current Extension Status

Sprint 9 completed weighted terrain movement. Current evidence: `Total Passed: 297`; `tests/unit/movement/movement_bfs_test.gd` covers rough terrain budget limits and lower-cost path reconstruction.
