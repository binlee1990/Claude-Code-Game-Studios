# Story 005: Map Variant Pack — 生成式战术地图数据包

> **Epic**: Map / Coordinates
> **Status**: Done
> **Layer**: Foundation / Content Extension
> **Type**: Data + Validation
> **Manifest Version**: N/A

## Context

MVP 只有 `assets/data/maps/test_map.csv` 一张 16x12 测试地图。下一步不应先引入装饰性美术，而应把 `$generate2dmap` 的 pipeline 用在本项目真正需要的地方：生成更多可验证的战术布局数据，同时保持默认 debug/programmer-art 视觉不变。

`$generate2dmap` 在本项目中的推荐落点：
- `visual_model`: `tilemap`
- `runtime_object_model`: `none`
- `collision_model`: project-native CSV tile states
- `engine_target`: Godot `TileMapLayer` + `assets/data/maps/*.csv`
- `visual_asset_source`: existing debug tiles / procedural preview only, not final decorative art

`$generate2dsprite` 不进入本 story。单位仍使用当前 `Unit.tscn` 的 debug visual；sprite skin 另立未来 story。

## Acceptance Criteria

- [x] 新增 3 张地图 CSV，位于 `assets/data/maps/`，全部遵守现有格式：第一行 `cols,rows`，后续只使用 `.`, `#`, `O`。
- [x] 每张地图尺寸在 `[8,32]` 范围内，保持 16x12 以适配当前窗口和 HUD。
- [x] 每张地图提供一组标准 spawn 坐标：2 个 Player、2 个 Enemy，且全部落在 walkable tile 上。
- [x] 每张地图保证双方至少存在一条可达路径，不因 blocked/obstacle 布局造成硬锁。
- [x] 默认 runner 加入地图数据验证测试，覆盖 CSV 可加载、spawn 合法、路径连通、blocked/obstacle 不可站立。
- [x] 不替换默认 `test_map.csv`。
- [x] 不引入 baked raster / layered raster / prop pack / unit sprite 作为默认视觉依赖。

## Implementation Notes

- 优先新增地图数据与验证，不修改 Map 公开接口。
- 如需要地图选择，先从测试层验证数据包；不要急于加主菜单或运行时选图 UI。
- 可选新增一个 `assets/data/maps/<map_name>.json` 或测试 fixture 记录 spawn 点，但只有在 CSV 本身不足以表达测试需求时才引入。
- 任何生成式地图草案都必须转换为项目原生 CSV，而不是绕过 `Map.initialize(grid_space, map_name)`。

## Out of Scope

- 手绘或 AI 生成的装饰性地图背景。
- layered raster props、y-sort props、foreground occluders。
- 单位 spritesheet、角色动画、攻击特效。
- 主菜单、地图选择 UI、存档记录当前地图。

## QA Test Cases

- **CSV load**: 每张新地图都能由 `Map.initialize(grid_space, map_name)` 加载，且 rows/cols 与 header 一致。
- **Spawn validity**: 每个 spawn 坐标都在 bounds 内，tile state 为 WALKABLE，且不重复。
- **Connectivity**: 至少一个 Player spawn 到至少一个 Enemy spawn 存在 BFS 可达路径。
- **Obstacle integrity**: `#` 与 `O` tile 对 `is_walkable()` 均返回 false。
- **Regression**: 默认 `test_map` 行为不变，现有 movement / occupancy / AI tests 继续通过。

## Test Evidence

**Required evidence**:
- `tests/unit/map/map_variant_pack_test.gd`
- `assets/data/maps/map_variants.json`
- `assets/data/maps/crossroads.csv`
- `assets/data/maps/central_choke.csv`
- `assets/data/maps/split_lanes.csv`
- Default runner clean: `Total Passed: 297`

## Dependencies

- Depends on: Story 001-004 Map foundation, Movement BFS tests.
- Unlocks: 后续可选的地图选择、地形类型、AI 地图适应性测试。
