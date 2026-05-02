# Sprint 9 — Weighted Terrain Movement

**Start**: 2026-05-03
**End**: 2026-05-03

## Sprint Goal

Add one Tier 2 terrain rule without changing the default baseline: rough terrain is walkable but costs 2 movement points to enter. This sprint keeps the SRPG skeleton data-driven and lets Movement, BasicAI, and generated map variants share the same terrain-cost contract.

## Tasks

| ID | Story | Epic | Type | Status |
|----|-------|------|------|--------|
| 2-1 | Rough Terrain Cost Model — `R` tile and movement cost API | map | Data + Logic | Done |
| 2-2 | Weighted Movement Resolver — cost-aware reachability and paths | movement | Logic | Done |
| 2-3 | Rough Pass Map Variant — validated terrain fixture | map | Data + Validation | Done |
| 2-4 | BasicAI Terrain Awareness — choose cost-aware movement targets | ai | Logic | Done |
| 2-5 | Rough Terrain Runtime Smoke — default and BasicAI scene coverage | qa | QA + Integration | Done |

## Definition of Done

- [x] `.` remains movement cost 1.
- [x] `R` is walkable and movement cost 2.
- [x] `#` and `O` remain non-walkable and have no valid movement cost.
- [x] Existing all-walkable maps preserve prior movement behavior.
- [x] Movement reachability uses total movement cost, not raw step count.
- [x] Path reconstruction uses the lowest-cost known path.
- [x] BasicAI automatically uses weighted movement through `MovementResolver`, without importing terrain-specific logic.
- [x] A `rough_pass` map variant is listed in `assets/data/maps/map_variants.json`.
- [x] Default runner remains clean.
- [x] Scene smokes cover default map and rough terrain with `--enemy-ai=basic`.

## AI Sprint Sizing

This sprint intentionally batches 5 linked stories because they share one verification surface:

- map tile parsing and cost lookup
- movement reachability
- AI target selection
- map variant validation
- scene smoke verification

Do not split this into human-sized tickets unless future terrain work adds multiple terrain types, UI explanation, or per-unit terrain affinities.

## Scope Boundary

This sprint adds only one mechanical terrain type. It does not add terrain defense, evasion, damage modifiers, tile tooltips, new tile art, map-selection UI, or per-class terrain rules.

## Verification Evidence

- Full runner: `Total Passed: 297`; zero script errors, assertion failures, error lines, or warnings observed.
- Scene smoke: default `src/Game.tscn` clean.
- Scene smoke: `--map=rough_pass` clean.
- Scene smoke: `--map=rough_pass --enemy-ai=basic` clean.

## Next Step

Sprint 9 completes the Tier 2 terrain rule. The next coherent rules sprint is a minimal class/advantage layer, but only after defining neutral vocabulary that does not import genre flavor.
