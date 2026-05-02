# Story 011: Rough Pass Map Variant — validated terrain fixture

> **Epic**: Map / Coordinates
> **Status**: Done
> **Layer**: Foundation / Content Extension
> **Type**: Data + Validation

## Context

Weighted terrain needs a project-native fixture that can be loaded by runtime map selection and validated by the default runner. The fixture should prove rough terrain without introducing new art or menu UI.

## Acceptance Criteria

- [x] `assets/data/maps/rough_pass.csv` exists.
- [x] `rough_pass` is listed in `assets/data/maps/map_variants.json`.
- [x] Manifest dimensions match the CSV dimensions.
- [x] Player and Enemy spawns are unique, in bounds, and on normal walkable tiles.
- [x] The map contains rough terrain and remains connected from Player spawns to Enemy spawns.
- [x] Runtime map selection can boot `--map=rough_pass`.

## Test Evidence

- `tests/unit/map/map_variant_pack_test.gd`
- `tests/unit/map/map_variant_manifest_test.gd`
- Scene smoke: `src/Game.tscn --map=rough_pass` clean.
- Full runner: `Total Passed: 297`; zero script errors, assertion failures, error lines, or warnings observed.

## Out of Scope

- More terrain maps.
- Map thumbnails.
- Map-selection UI.
