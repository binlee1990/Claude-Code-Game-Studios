# Story BASE-UPGRADE-001: Base Upgrade Tab

> **Epic**: Base System Phase 1
> **Status**: Complete
> **Layer**: Feature
> **Type**: Logic + UI + Config/Data
> **Priority**: Must Have
> **Sprint**: Sprint-007
> **TR-ID**: TR-base-004
> **ADR References**: ADR-003, ADR-008
> **Estimate**: 0.75 day

## Context

**GDD**: `design/gdd/base-system.md`
**Cost data**: `assets/data/economy/base-upgrade-costs.json`
**Sprint source**: `production/sprints/sprint-007.md` / BASE-UPGRADE-001
**QA plan**: `production/qa/qa-plan-sprint-7.md`

Expose the Sprint-006 base upgrade cost table through a player-facing Upgrade tab. This story owns cost display, affordability checks, resource deduction, unlock application, and save/load state.

## Acceptance Criteria

- [x] Base Hub includes an Upgrade tab or equivalent route.
- [x] Upgrade UI reads cost/unlock data from `base-upgrade-costs.json`.
- [x] Resource preview shows gold/material cost and shortages.
- [x] Successful upgrade deducts resources, increments base level, and applies unlocks.
- [x] Base level and unlocks persist through save/load.

## QA Test Conditions

- Given cost data exists, when the upgrade model loads it, then schema version, levels, costs, and unlocks parse without hardcoded UI prices.
- Given resources are sufficient, when upgrading Lv1 to Lv2, then 500 gold and 20 base materials are deducted and Tavern unlocks.
- Given resources are insufficient, when viewing the Upgrade tab, then the upgrade action is disabled and shortage feedback is localized.
- Given an upgraded base is saved and reloaded, then level and unlock state round-trip.

## Test Evidence

**Completed**: `tests/unit/base/base_upgrade_model_test.gd` and `tests/integration/ui/base_hub_test.gd`.
**Gate**: PASS

## Dependencies

- Depends on: Sprint-006 ECON-CFG-001, Inventory/resource ownership
- Unlocks: Base Tavern availability and later base progression tuning

## Next Step

Complete 2026-04-27.
