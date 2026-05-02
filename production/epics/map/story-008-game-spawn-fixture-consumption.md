# Story 008: Game Spawn Fixture Consumption — place units from manifest fixtures

> **Epic**: Map / Coordinates
> **Status**: Done
> **Layer**: Composition Root
> **Type**: Integration

## Context

`Game._create_units()` currently hardcodes the default unit positions. Once maps are selectable, unit placement must consume the selected map's spawn fixture from `map_variants.json`.

## Acceptance Criteria

- [x] Default `test_map` still spawns Player at `(5,2)`, `(5,4)` and Enemy at `(5,10)`, `(5,12)`.
- [x] Variant maps spawn units at their manifest-defined coordinates.
- [x] Spawn placement rejects or falls back on invalid spawn coordinates.
- [x] Unit stats and faction assignment remain unchanged.
- [x] Occupancy after placement matches all spawned units.

## Test Evidence

- `tests/unit/ui/game_map_mode_test.gd`
- `tests/integration/ui/e2e_game_flow_test.gd`
- Full runner: `Total Passed: 297`; zero script errors, assertion failures, error lines, or warnings observed.

## Out of Scope

- Per-map unit rosters.
- Unit count changes.
- Save/load selected map.
