# Sprint 8 — Runtime Map Selection

**Start**: 2026-05-03
**End**: 2026-05-03

## Sprint Goal

Make the Sprint 7 map variant pack playable through the `Game` composition root without adding menu UI or changing the default baseline. This sprint is sized for AI execution: multiple related stories share one verification surface and can be proven by one runner pass plus scene smokes.

## Tasks

| ID | Story | Epic | Type | Status |
|----|-------|------|------|--------|
| 1-6 | MapVariantManifest — load/query map names and spawn fixtures | map | Data + Logic | Done |
| 1-7 | Runtime Map Selection — project setting + command-line map override | map | Integration | Done |
| 1-8 | Game Spawn Fixture Consumption — place units from manifest fixtures | map | Integration | Done |
| 1-9 | Multi-map Runtime Smoke — default/hotseat/BasicAI across variants | map | QA + Integration | Done |

## Definition of Done

- [x] `Game` still defaults to `test_map` with the current hotseat baseline unchanged.
- [x] Runtime map selection supports a project setting, for example `srpg_mini/map_name="test_map"`.
- [x] Command-line map override works for smoke/demo runs, for example `--map=crossroads` and `--map split_lanes`.
- [x] Unit spawn positions come from `assets/data/maps/map_variants.json` instead of hardcoded coordinates when a manifest entry exists.
- [x] Invalid map names fall back safely to `test_map` without crashing.
- [x] Automated tests cover manifest parsing, map resolution, spawn fixture use, invalid-map fallback, and default behavior.
- [x] Scene smokes cover default `test_map`, one variant map in hotseat mode, and one variant map with `--enemy-ai=basic`.
- [x] No map-selection menu, decorative raster map, prop pack, unit sprite, or save/load state is added in this sprint.
- [x] Default runner remains clean.

## AI Sprint Sizing

This sprint intentionally batches 4 stories because they share the same integration boundary:

- manifest data contract
- `Game` composition root
- map/spawn selection
- scene smoke verification

Do not split these into human-sized tickets unless implementation reveals a real architecture boundary or product decision.

## Scope Boundary

This sprint makes existing map variants playable by configuration. It does not create more maps, add a menu, add map thumbnails, persist selected maps, or change the visual style.

## Verification Evidence

- Full runner: `Total Passed: 297`; zero script errors, assertion failures, error lines, or warnings observed.
- Scene smoke: default `src/Game.tscn` clean.
- Scene smoke: `--map=crossroads` clean.
- Scene smoke: `--map=split_lanes --enemy-ai=basic` clean.

## Next Step

Sprint 8 is complete. The next coherent sprint can expose map choice to players through a small in-game selector, or start integrating generated sprite assets while keeping the current project-native map data path intact.
