# Story 007: Runtime Map Selection — project setting + command-line map override

> **Epic**: Map / Coordinates
> **Status**: Done
> **Layer**: Composition Root
> **Type**: Integration

## Context

`Game` currently hardcodes `test_map`. Sprint 8 should make map selection configurable while preserving the default baseline, matching the existing `--enemy-ai` override pattern.

## Acceptance Criteria

- [x] `project.godot` defines a default map setting, for example `srpg_mini/map_name="test_map"`.
- [x] `Game` resolves map name from project setting.
- [x] Command-line `--map=crossroads` overrides project setting.
- [x] Command-line `--map split_lanes` overrides project setting.
- [x] Invalid map name falls back to `test_map` safely.
- [x] Default launch behavior remains unchanged.

## Test Evidence

- `tests/unit/ui/game_map_mode_test.gd`
- Default scene smoke: `src/Game.tscn` clean.
- Full runner: `Total Passed: 297`; zero script errors, assertion failures, error lines, or warnings observed.

## Out of Scope

- Map selection menu.
- Persisting selected map.
- Generating new maps.
