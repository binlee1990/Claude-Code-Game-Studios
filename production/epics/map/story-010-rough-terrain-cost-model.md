# Story 010: Rough Terrain Cost Model — `R` tile and movement cost API

> **Epic**: Map / Coordinates
> **Status**: Done
> **Layer**: Foundation / Content Extension
> **Type**: Data + Logic

## Context

Tier 2 terrain requires one walkable-but-costly tile type without changing the default `test_map` baseline. Map owns tile parsing and therefore owns the movement-cost lookup consumed by Movement.

## Acceptance Criteria

- [x] CSV maps accept `R` as rough terrain.
- [x] Rough terrain is walkable.
- [x] Rough terrain costs 2 movement points to enter.
- [x] Normal walkable terrain remains cost 1.
- [x] Blocked, obstacle, and out-of-bounds tiles remain non-walkable and expose an invalid movement cost.
- [x] Existing occupancy and movement execution guards still reject non-walkable destinations.

## Test Evidence

- `tests/unit/map/map_loading_test.gd`
- `tests/unit/map/map_variant_pack_test.gd`
- Full runner: `Total Passed: 297`; zero script errors, assertion failures, error lines, or warnings observed.

## Out of Scope

- Terrain defense/evasion/damage modifiers.
- Terrain UI labels or tooltips.
- New tile art.
