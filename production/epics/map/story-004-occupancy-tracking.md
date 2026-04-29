# Story 004: 占用追踪 — place / remove / get_unit_at

> **Epic**: Map / Coordinates
> **Status**: Ready
> **Layer**: Foundation
> **Type**: Logic
> **Manifest Version**: N/A（control-manifest.md 尚未创建）

## Context

**GDD**: `design/gdd/map.md`
**Requirement**: `TR-map-003`, `TR-map-006`, `TR-map-009`
*(Requirement text lives in `docs/architecture/tr-registry.yaml` — read fresh at review time)*

**ADR Governing Implementation**: ADR-0005: Map CSV Loading Format & Occupancy Tracking
**ADR Decision Summary**: Map 持有 `Dictionary[Vector2i, Unit]` 用于 O(1) 反向查找。暴露原子 `move_unit(unit, from, to) → bool`（禁止分离调用 place+remove 造成不同步窗口）、`place_unit(coord)/remove_unit(coord) → bool`（含越界/不可通行/已占用/空瓦片校验）、`get_unit_at(coord) → Unit`（空时 null）、`is_walkable(coord) → bool`（瓦片状态==WALKABLE 且未被占用）。

**Engine**: Godot 4.6.2-stable | **Risk**: LOW
**Engine Notes**: Dictionary[Vector2i, Unit] 类型化字典自 Godot 4.0 起稳定。Vector2i 作为字典 key 使用值语义——坐标相同的两个 Vector2i 视为同一个 key。

**Control Manifest Rules (this layer)**:
- Required: 原子 move_unit()——不在 Map 外部执行分离的 place+remove
- Forbidden: Movement 系统直接操作 `_occupancy` 字典（通过 Map 公开方法访问）
- Guardrail: 所有写入操作返回 bool 表示成功/失败——调用方必须检查返回值

---

## Acceptance Criteria

*From GDD `design/gdd/map.md` AC-C8, AC-C10, AC-C11:*

- [ ] **AC-C8 — is_walkable 双重检查**: 空的可通行瓦片→true。place_unit 成功后→false。blocked 或 obstacle 瓦片→false（无论占用状态）。
- [ ] **AC-C10 — place_unit 拒绝**: 越界/不可通行/已占用坐标 → 返回 false，占用不变。
- [ ] **AC-C11 — remove_unit 空瓦片**: 空瓦片 → push_warning() 并返回 false。
- [ ] **move_unit 原子性**: move_unit(unit, from, to) 在一帧内完成 remove(from)+place(to)，不存在中间状态。
- [ ] **get_unit_at 查询**: 占用瓦片→Unit；空瓦片→null。

---

## Implementation Notes

*Derived from ADR-0005:*

```gdscript
var _occupancy: Dictionary  # Dictionary[Vector2i, Unit]

func is_walkable(coord: Vector2i) -> bool:
    if not is_coord_in_bounds(coord):
        return false
    if _tile_states[coord.x][coord.y] != TILE_WALKABLE:
        return false
    return not _occupancy.has(coord)

func place_unit(unit: Unit, coord: Vector2i) -> bool:
    if not is_walkable(coord):
        return false
    _occupancy[coord] = unit
    unit.grid_position = coord
    return true

func remove_unit(coord: Vector2i) -> bool:
    if not _occupancy.has(coord):
        push_warning("remove_unit on empty tile: ", coord)
        return false
    _occupancy.erase(coord)
    return true

func move_unit(unit: Unit, from: Vector2i, to: Vector2i) -> bool:
    if not _occupancy.has(from) or _occupancy[from] != unit:
        return false
    if not is_walkable(to):
        return false
    _occupancy.erase(from)
    _occupancy[to] = unit
    unit.grid_position = to
    return true

func get_unit_at(coord: Vector2i) -> Unit:
    return _occupancy.get(coord, null)
```

- `_tile_states` 字典在 Story 002 的 CSV 加载期间填充
- `_occupancy` 在 CSV 加载后初始化为空字典
- Unit 死亡时（unit_died 信号），Movement 或 Turn 系统负责调用 `remove_unit()`

---

## Out of Scope

- Story 001: GridSpace 坐标转换
- Story 002: CSV 加载 + TileMapLayer 渲染
- Story 003: get_neighbors()、is_coord_in_bounds()
- Unit 死亡清理逻辑：属于 Unit Epic

---

## QA Test Cases

- **AC-C8**: is_walkable 双重检查
  - Given: walkable 瓦片 (3,4)，无单位
  - When: is_walkable(Vector2i(3,4))
  - Then: true
  - When: place_unit(unit, Vector2i(3,4)) 成功后，再次 is_walkable(Vector2i(3,4))
  - Then: false
  - Edge cases: blocked 瓦片→false（无论是否 occupied）

- **AC-C10**: place_unit 拒绝条件
  - Given: 坐标 (-1,0)（越界）、blocked 瓦片 (5,5)、已占用瓦片
  - When: place_unit(unit, 各坐标)
  - Then: 全部返回 false，_occupancy.size() 不变
  - Edge cases: obstacle 瓦片→同 blocked

- **AC-C11**: remove_unit 空瓦片警告
  - Given: 空瓦片 (3,4)
  - When: remove_unit(Vector2i(3,4))
  - Then: push_warning 被调用，返回 false
  - Edge cases: 移除后再次 remove → 同样警告

- **move_unit 原子性**:
  - Given: unit 在 (3,4)，目标 (3,5) 为空且 walkable
  - When: move_unit(unit, Vector2i(3,4), Vector2i(3,5))
  - Then: 返回 true，(3,4) 为空，(3,5) 有 unit，unit.grid_position==(3,5)
  - Edge cases: from 不匹配 unit → 返回 false；to 不可通行 → 返回 false，from 的 unit 未被移除

---

## Test Evidence

**Story Type**: Logic
**Required evidence**: `tests/unit/map/occupancy_test.gd` — must exist and pass

**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: Story 002（CSV 加载——_tile_states 字典）、Story 003（is_coord_in_bounds）
- Unlocks: Movement Epic（Movement System 是 _occupancy 的主要消费者）
