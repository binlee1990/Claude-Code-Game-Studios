# Story 001: GridSpace — 坐标转换边界

> **Epic**: Map / Coordinates
> **Status**: Ready
> **Layer**: Foundation
> **Type**: Logic
> **Manifest Version**: N/A（control-manifest.md 尚未创建）

## Context

**GDD**: `design/gdd/map.md`
**Requirement**: `TR-map-001`, `TR-map-007`
*(Requirement text lives in `docs/architecture/tr-registry.yaml` — read fresh at review time)*

**ADR Governing Implementation**: ADR-0001: GridSpace — Coordinate Transform Boundary
**ADR Decision Summary**: GridSpace 为 RefCounted，封装 TILE_SIZE=64 常量，是 grid↔world 坐标转换的唯一权威。任何其他文件不得执行 `* 64` / `/ 64` 运算或定义重复的 TILE_SIZE 常量。

**Engine**: Godot 4.6.2-stable | **Risk**: LOW
**Engine Notes**: 所有使用的 API（Vector2, Vector2i, floori, RefCounted）自 Godot 4.0 起稳定。无 post-cutoff API 使用。

**Control Manifest Rules (this layer)**:
- Required: RefCounted + DI（禁止 Autoload），所有坐标转换通过 GridSpace
- Forbidden: GridSpace 之外的任何文件内联 `* 64` / `/ 64`，重复定义 TILE_SIZE
- Guardrail: GridSpace 为纯函数无状态对象，可在无场景树的情况下进行单元测试

---

## Acceptance Criteria

*From GDD `design/gdd/map.md` AC-C2, AC-C5, AC-F1, AC-F2, AC-F3:*

- [ ] **AC-C2 — 坐标朝向**: grid_to_world(0,0) → Vector2(0,0)。row 增长使 Y 向下，col 增长使 X 向右，各精确 64px。
- [ ] **AC-C5 — GridSpace 转换精度**: world_to_grid(Vector2(215, 150)) → Vector2i(2, 3)；grid_to_world(Vector2i(2, 3)) → Vector2(192, 128)。
- [ ] **AC-F1 — grid_to_world 公式**: grid_to_world(2, 3) → Vector2(192, 128)，即 (col×64, row×64)。
- [ ] **AC-F2 — world_to_grid 公式**: world_to_grid(215, 150) → Vector2i(2, 3)，即 (floor(150/64), floor(215/64))。
- [ ] **AC-F3 — tile_center**: tile_center(2, 3) → Vector2(224, 160)，与 grid_to_world + Vector2(32,32) 一致。
- [ ] **AC-F4 — TILE_SIZE 封装**: 仅 GridSpace 定义 TILE_SIZE=64 常量。其他模块未定义或直接使用此值。

---

## Implementation Notes

*Derived from ADR-0001 Implementation Guidelines:*

```gdscript
# src/core/grid_space.gd
class_name GridSpace extends RefCounted

const TILE_SIZE: int = 64

func world_to_grid(world_pos: Vector2) -> Vector2i:
    return Vector2i(floori(world_pos.y / TILE_SIZE), floori(world_pos.x / TILE_SIZE))

func grid_to_world(grid_pos: Vector2i) -> Vector2:
    return Vector2(grid_pos.y * TILE_SIZE, grid_pos.x * TILE_SIZE)

func tile_center(grid_pos: Vector2i) -> Vector2:
    return grid_to_world(grid_pos) + Vector2(TILE_SIZE / 2.0, TILE_SIZE / 2.0)
```

- GridSpace 由 Map._ready() 创建，存储为成员变量
- 通过 DI 传递给 Unit（用于 tile_center 放置）和 InputHandler（用于 click→grid）
- MovementResolver、AttackResolver、VictoryChecker、TurnManager 接收 GridSpace：**否**——它们操作纯 grid 坐标

---

## Out of Scope

- Story 002: CSV 加载、TileMapLayer 渲染、网格实例化
- Story 003: get_neighbors()、is_coord_in_bounds()、NEIGHBOR_OFFSETS
- Story 004: 占用追踪（place_unit/remove_unit/get_unit_at）

---

## QA Test Cases

- **AC-C2**: grid_to_world 坐标朝向
  - Given: TILE_SIZE=64
  - When: grid_to_world(0,0)、grid_to_world(1,0)、grid_to_world(0,1)
  - Then: Vector2(0,0)、Vector2(0,64)、Vector2(64,0)
  - Edge cases: 最大坐标 grid_to_world(15,11) → Vector2(704,960)

- **AC-C5**: world_to_grid / grid_to_world 往返
  - Given: 像素 (215, 150)
  - When: world_to_grid(Vector2(215, 150))
  - Then: Vector2i(2, 3)
  - Edge cases: 负像素 world_to_grid(Vector2(-10, -10)) → Vector2i(-1, -1)（调用方负责边界检查）

- **AC-F3**: tile_center 返回中点
  - Given: row=2, col=3
  - When: tile_center(Vector2i(2, 3))
  - Then: Vector2(224, 160)
  - Edge cases: tile_center(0,0) → Vector2(32, 32)

---

## Test Evidence

**Story Type**: Logic
**Required evidence**: `tests/unit/map/grid_space_test.gd` — must exist and pass

**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: None（Foundation 层首个 Story）
- Unlocks: Story 002（CSV 加载 + TileMapLayer）、Story 003（网格拓扑）、所有使用坐标的下游 Epic
