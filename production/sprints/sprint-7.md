# Sprint 7 — Map Variant Pack

**Start**: 2026-05-03
**End**: 2026-05-03

## Sprint Goal

Use the `$generate2dmap` workflow as a tactical data pipeline, not an art pass: add a small pack of verified project-native CSV maps while preserving the debug/programmer-art baseline.

## Tasks

| ID | Story | Epic | Type | Status |
|----|-------|------|------|--------|
| 1-5 | Map Variant Pack — 生成式战术地图数据包 | map | Data + Validation | Done |

## Definition of Done

- [x] Add 2-3 new map CSV files under `assets/data/maps/`.
- [x] Keep each map compatible with the current `Map.initialize(grid_space, map_name)` contract.
- [x] Define spawn fixtures for 2 Player and 2 Enemy units per map.
- [x] Add automated validation for CSV load, spawn legality, path connectivity, and blocked/obstacle behavior.
- [x] Keep `test_map.csv` as the default scene map unless a separate decision changes it.
- [x] Do not add decorative raster maps, prop packs, unit sprites, or map-selection UI in this sprint.
- [x] Default runner remains clean: `Total Passed: 297`.

## Pipeline Decision

Recommended `$generate2dmap` axes for this project:

| Axis | Choice | Reason |
|------|--------|--------|
| `visual_model` | `tilemap` | The engine already uses Godot `TileMapLayer` and project-native CSV data. |
| `runtime_object_model` | `none` | The current tactical board has no props, y-sort, triggers, or interactables. |
| `collision_model` | CSV tile state | Existing `.` / `#` / `O` already drives movement and occupancy. |
| `engine_target` | project-native Godot TileMap | Preserve `Map.gd`, `GridSpace`, and current tests. |
| `visual_asset_source` | existing debug tiles | Art Bible requires board-state legibility over decorative map art. |

`$generate2dsprite` is deliberately out of scope for Sprint 7. Use it later only for an optional `unit_visual_mode` / skin-layer experiment.

## Scope Boundary

This sprint produces content data and validation. It must not turn SRPG_MINI into an art pipeline project. The output should make the tactical skeleton more useful for testing Movement, Attack, Victory, and BasicAI across multiple layouts.

## Next Step

Sprint 8 completed runtime map selection and spawn-fixture consumption. Do not add map-selection UI before a product need exists.
