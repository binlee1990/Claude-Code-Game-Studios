# Story 006: MapVariantManifest — load/query map names and spawn fixtures

> **Epic**: Map / Coordinates
> **Status**: Done
> **Layer**: Foundation / Content Extension
> **Type**: Data + Logic

## Context

Sprint 7 created `assets/data/maps/map_variants.json`, but the runtime has no typed query boundary for map names and spawn fixtures. Sprint 8 should add a small data boundary so `Game` does not parse manifest dictionaries ad hoc.

## Acceptance Criteria

- [x] Manifest loads from `res://assets/data/maps/map_variants.json`.
- [x] `default_map` resolves to `test_map`.
- [x] Query by map name returns dimensions and 2 Player / 2 Enemy spawn coordinates.
- [x] Unknown map query has an explicit safe result for fallback handling.
- [x] Spawn coordinates are exposed as `Vector2i(row, col)` without reversing axes.

## Test Evidence

- `tests/unit/map/map_variant_manifest_test.gd`
- Full runner: `Total Passed: 292`; zero script errors, assertion failures, error lines, or warnings observed.

## Out of Scope

- Changing map CSV schema.
- Runtime map selection.
- UI or menu work.
