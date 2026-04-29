# Story 002: CSV 地图加载 + TileMapLayer 渲染

> **Epic**: Map / Coordinates
> **Status**: Ready
> **Layer**: Foundation
> **Type**: Logic
> **Manifest Version**: N/A（control-manifest.md 尚未创建）

## Context

**GDD**: `design/gdd/map.md`
**Requirement**: `TR-map-002`, `TR-map-004`, `TR-map-008`
*(Requirement text lives in `docs/architecture/tr-registry.yaml` — read fresh at review time)*

**ADR Governing Implementation**: ADR-0005: Map CSV Loading Format & Occupancy Tracking
**ADR Decision Summary**: Map 从 `assets/data/maps/` 中的 CSV 文件加载网格数据。CSV 第一行为 `cols,rows` header，后续行每格一个字符（`.` walkable / `#` blocked / `O` obstacle）。Map 场景包含空 TileMapLayer 节点，在 `_ready()` 中对每个瓦片调用 `set_cell()`。加载时校验维度范围 [8,32]、行列数匹配、仅含合法字符。

**Engine**: Godot 4.6.2-stable | **Risk**: LOW
**Engine Notes**: TileMapLayer API 自 Godot 4.3 起稳定。FileAccess 返回类型在 4.4 有变更——使用 `FileAccess.open()` 返回的 FileAccess 对象前检查 `null`。CSV 解析使用纯 GDScript 字符串操作，无外部依赖。

**Control Manifest Rules (this layer)**:
- Required: 地图数据驱动（CSV 外部文件，非场景预置）；fail-fast 校验
- Forbidden: 场景文件中预置瓦片；跳过 CSV 校验
- Guardrail: 地图加载失败时输出具体错误消息（不是静默失败或崩溃）

---

## Acceptance Criteria

*From GDD `design/gdd/map.md` AC-C1, AC-C6, AC-C7, AC-C12:*

- [ ] **AC-C1 — 网格边界**: CSV header 为 `16,12` → 网格 16×12。header 维度超出 [8,32] → 加载失败并输出含范围与实际值的错误消息。
- [ ] **AC-C6 — CSV 字符映射**: `.` → walkable、`#` → blocked、`O` → obstacle。
- [ ] **AC-C7 — 空 TileMapLayer + _ready 填充**: Map 场景的 TileMapLayer 零预置瓦片。`_ready()` 对每个 CSV 单元格调用一次 `set_cell()`。
- [ ] **AC-C12 — CSV 校验错误**: 行列数不匹配 / 未知字符 / 文件缺失 → 加载失败并输出标识问题的具体错误消息（含行列位置或文件路径）。

---

## Implementation Notes

*Derived from ADR-0005 Implementation Guidelines:*

- Map 场景结构:
  ```
  Map (Node2D)
  ├── TileMapLayer (named "TileMapLayer")
  └── GridSpace (RefCounted, created in _ready())
  ```

- CSV 格式（`assets/data/maps/default.csv`）:
  ```
  16,12
  ................
  ................
  ........##......
  ........##......
  ................
  ................
  ......##OO##....
  ......##OO##....
  ................
  ................
  ................
  ................
  ```

- 加载流程:
  1. FileAccess.open(csv_path, FileAccess.READ) → null check
  2. 读取首行 → 解析 cols,rows（int 转换 + 范围校验 [8,32]）
  3. 逐行读取，验证长度匹配 cols、仅含 `.` `#` `O`
  4. 对每个单元格调用 `tile_map_layer.set_cell(row, col, tile_id, atlas_coords)`
  5. 初始化 `_tile_states[row][col]` 字典和 `_occupancy` 字典

- TileSet: 创建包含 3 个 atlas tiles 的 TileSet 资源，颜色来自 art-bible §4.3

---

## Out of Scope

- Story 001: GridSpace 坐标转换
- Story 003: get_neighbors()、is_coord_in_bounds()
- Story 004: 占用追踪（place/remove/get_unit_at/is_walkable）

---

## QA Test Cases

- **AC-C1**: 网格维度加载
  - Given: CSV header `16,12`，后跟 12 行 16 列数据
  - When: Map 加载 CSV
  - Then: map_cols=16、map_rows=12
  - Edge cases: header `7,12` → 失败（cols<8）；header `33,12` → 失败（cols>32）

- **AC-C6**: 字符→瓦片状态映射
  - Given: CSV 行 ".#O"
  - When: Map 加载
  - Then: (0,0)=WALKABLE、(0,1)=BLOCKED、(0,2)=OBSTACLE
  - Edge cases: 字符 'X' → 校验失败，消息含 "(0,3)" 位置

- **AC-C12**: 缺失文件
  - Given: CSV 路径指向不存在的文件
  - When: Map 尝试加载
  - Then: 返回 false，push_error 含文件路径和 OS 错误

---

## Test Evidence

**Story Type**: Logic
**Required evidence**: `tests/unit/map/map_loader_test.gd` — must exist and pass

**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: Story 001（GridSpace）— Map._ready() 创建 GridSpace 实例
- Unlocks: Story 003（网格拓扑）、Story 004（占用追踪）
