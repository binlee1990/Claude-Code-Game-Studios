# Story EQUIP-ENH-002: Enhancement Cost Source + Failure Feedback

> **Title**: Enhancement cost source + failure feedback
> **Epic**: Equipment System
> **Layer**: Feature
> **Priority**: Must Have
> **Status**: Complete
> **Sprint**: Sprint-006
> **Type**: Logic + Integration
> **TR-ID**: TR-equip-009
> **ADR References**: ADR-001, ADR-008, ADR-009
> **Review Mode**: solo — QL-STORY-READY skipped
> **Estimate**: 0.5 day

## Context

**GDD**: `design/gdd/resource-economy.md` D.4, `design/gdd/equipment-system.md` C.4/E.1-E.3  
**Sprint source**: `production/sprints/sprint-006.md` / EQUIP-ENH-002  
**QA plan**: `production/qa/qa-plan-sprint-6.md`

EQUIP-ENH-001 exposes the enhancement panel. This story makes the costs and disabled/failure states authoritative by sourcing gold/material/protection information from the resource economy instead of duplicating literals in UI.

## Acceptance Criteria

- [x] Enhancement cost for +1 through +5 is read from the resource/economy source of truth.
- [x] Gold and material shortages show exact missing amounts before mutation.
- [x] Cost payment is atomic: failed affordability checks do not partially consume resources.
- [x] +6 and above risk-zone entry is disabled for Sprint-006 MVP.
- [x] Protection-symbol count is visible or queryable for future risk-zone work, but +6+ execution remains out of scope.

## Definition of Done

- [x] Unit tests cover cost lookup, shortage calculation, and atomic no-op on insufficient resources.
- [x] UI/integration test covers exact shortage messaging through the enhancement panel.
- [x] Existing `tests/unit/resource/consumption_costs_test.gd` remains green.
- [x] No +6+ enhancement execution, protection-symbol consumption, or advanced forge UI is implemented.

## Implementation Notes

- If an `Inventory.peek_cost(level)` helper does not exist, implement the smallest equivalent in the resource/economy boundary, not inside UI.
- Keep ADR-008 ownership clear: resource economy owns affordability and payment, equipment owns enhancement result.
- Reuse existing `resource_changed` / `item_acquired` signals; do not create a second inventory event bus.

## Test Evidence

**Required / completed**: `tests/unit/equipment/enhancement_test.gd` and `tests/integration/ui/character_management_test.gd`
**Gate**: BLOCKING

## Dependencies

- Depends on: EQUIP-ENH-001, ADR-008, resource-economy stories 004/005
- Unlocks: EQUIP-ENH-003 and stable enhancement smoke coverage

## Next Step

Run `/story-readiness production/epics/equipment-system/story-009-enhancement-cost-source.md` after EQUIP-ENH-001 is ready.

## Completion Notes

Completed 2026-04-27 in Sprint-006. Evidence: src/, 	ests/, production/qa/qa-plan-sprint-6.md, production/sprints/sprint-006.md, and packaged smoke PACKAGED_PLAYTHROUGH_SMOKE PASS with Bond/Base/Equipment coverage.

