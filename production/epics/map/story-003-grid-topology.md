# Story 003: 网格拓扑 — 邻接查询 + 边界检查

> **Epic**: Map / Coordinates
> **Status**: Ready
> **Layer**: Foundation
> **Type**: Logic
> **Manifest Version**: N/A（control-manifest.md 尚未创建）

## Context

**GDD**: `design/gdd/map.md`
**Requirement**: `TR-map-005`
*(Requirement text lives in `docs/architecture/tr-registry.yaml` — read fresh at review time)*

**ADR Governing Implementation**: ADR-0005: Map CSV Loading Format & Occupancy Tracking
**ADR Decision Summary**: Map 暴露 `get_neighbors(coord) → Array[Vector2i]`——对 4 个 von Neumann 偏移进行界内过滤，**不**过滤可通行性（由调用方管理 visited 集合）。同时暴露 `is_coord_in_bounds(coord) → bool` 供外部校验。

**Engine**: Godot 4.6.2-stable | **Risk**: LOW
**Engine Notes**: 纯数组操作 + 整数比较。零 post-cutoff API 使用。Dictionary 用于 O(1) 邻接查找（可选优化，非必需）。

**Control Manifest Rules (this layer)**:
- Required: get_neighbors() 仅返回界内坐标，不滤可通行性
- Forbidden: 对角线邻接；越界坐标悄无声息返回
- Guardrail: 角落瓦片返回 2 个邻居，边缘瓦片返回 3 个，内部瓦片返回 4 个

---

## Acceptance Criteria

*From GDD `design/gdd/map.md` AC-C3, AC-C9, AC-F4, AC-F5:*

- [ ] **AC-C3 — von Neumann 邻接**: get_neighbors(row,col) 结果恰好包含 4 个 cardinal 方向，零对角线。
- [ ] **AC-C9 — 边界邻居**: 角落 (0,0) → 2 个邻居（下+右），均在界内。blocked 邻居**包含在内**（不滤可通行性）。
- [ ] **AC-F4 — is_coord_in_bounds**: 16×12 地图上：(0,0)→true、(15,11)→true、(-1,0)→false、(0,12)→false。
- [ ] **AC-F5 — NEIGHBOR_OFFSETS**: 常量值恰好为 `[(-1,0),(1,0),(0,-1),(0,1)]`。

---

## Implementation Notes

*Derived from ADR-0005 + Map GDD:*

```gdscript
const NEIGHBOR_OFFSETS: Array[Vector2i] = [
    Vector2i(-1, 0),  # 上
    Vector2i(1, 0),   # 下
    Vector2i(0, -1),  # 左
    Vector2i(0, 1),   # 右
]

func is_coord_in_bounds(coord: Vector2i) -> bool:
    return coord.x >= 0 and coord.x < map_rows and coord.y >= 0 and coord.y < map_cols

func get_neighbors(coord: Vector2i) -> Array[Vector2i]:
    var result: Array[Vector2i] = []
    for offset in NEIGHBOR_OFFSETS:
        var neighbor := coord + offset
        if is_coord_in_bounds(neighbor):
            result.append(neighbor)
    return result
```

- `map_rows` 和 `map_cols` 在 CSV 加载后（Story 002）设置
- `get_neighbors()` 不访问 `_tile_states` 或 `_occupancy`——纯拓扑函数

---

## Out of Scope

- Story 001: GridSpace 坐标转换
- Story 002: CSV 加载 + TileMapLayer 渲染
- Story 004: is_walkable()（需要占用追踪）；占用字典操作
- Movement: BFS 实现属于 Movement Epic，不在此 Story

---

## QA Test Cases

- **AC-C3**: von Neumann 邻接方向
  - Given: 16×12 地图，坐标 (5,5)
  - When: get_neighbors(Vector2i(5, 5))
  - Then: [Vector2i(4,5), Vector2i(6,5), Vector2i(5,4), Vector2i(5,6)]（上、下、左、右）
  - Edge cases: 无对角线 (4,4)、(4,6)、(6,4)、(6,6)

- **AC-C9**: 角落瓦片邻居数
  - Given: 16×12 地图
  - When: get_neighbors(Vector2i(0, 0))
  - Then: 恰好 2 个——Vector2i(1,0)、Vector2i(0,1)
  - Edge cases: (15,11)→2 个；(0,5)→3 个（edge）

- **AC-F4**: is_coord_in_bounds 边界值
  - Given: map_rows=12, map_cols=16
  - When: is_coord_in_bounds(Vector2i(-1, 0))
  - Then: false
  - Edge cases: (12, 0)→false、(0, 16)→false

---

## Test Evidence

**Story Type**: Logic
**Required evidence**: `tests/unit/map/grid_topology_test.gd` — must exist and pass

**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: Story 002（CSV 加载——需要 map_rows/map_cols 已设置）
- Unlocks: Story 004（占用追踪——is_walkable 依赖 get_neighbors 不滤可通行性的设计）
