# Story 013: Decompose and Affix Reroll UI

> **Epic**: Equipment System
> **Status**: Complete
> **Layer**: Feature
> **Type**: UI + Integration
> **Priority**: Must Have
> **Sprint**: Sprint-008
> **TR-ID**: TR-equip-013

## Context

**GDD**: `design/gdd/equipment-system.md`
**QA plan**: `production/qa/qa-plan-sprint-8.md`

Sprint-008 exposes the already-designed equipment decomposition loop and a bounded single-affix reroll flow in the character-management equipment panel. It does not add set crafting, sockets, +11 risk-zone behavior, or new equipment qualities.

## Acceptance Criteria

- [x] Equipment rows expose a decomposition action that removes the item and grants deterministic material rewards.
- [x] Equipment rows expose a reroll action for items with affixes.
- [x] Reroll consumes the resource-economy-owned gold/material cost and preserves enhancement level.
- [x] Insufficient resource and no-affix cases produce user-facing feedback and do not mutate equipment.
- [x] UI changes emit the existing equipment update signal so SaveData round-trips reflect the result.

## QA Test Conditions

- Given a blue item, when it is decomposed, then base materials are granted and the item leaves inventory/loadout.
- Given an item with an affix and enough resources, when reroll is clicked, then one legal affix is regenerated and enhancement level is unchanged.
- Given insufficient resources, when reroll is requested, then the operation fails without negative resource balances.
- Given an item has no affixes, when the equipment row renders, then reroll is disabled.

## Test Evidence

- `src/core/equipment/equipment_component.gd`
- `src/core/resource/resource_formulas.gd`
- `src/ui/management/character_management.gd`
- `src/core/localization/srpg_localization.gd`
- `tests/unit/equipment/decomp_reroll_test.gd`
- `tests/integration/equipment/decomp_reroll_ui_test.gd`

## Next Step

Closed in Sprint-008. Sprint-009 may extend the equipment loop into +11+ extreme-risk tuning, but should not change the Sprint-008 decompose/reroll SaveData contract without adding migration tests.
