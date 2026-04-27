# Story EQUIP-ENH-003: Enhancement Round-Trip + Failure UI

> **Title**: Enhancement round-trip + failure UI closeout
> **Epic**: Equipment System
> **Layer**: Feature
> **Priority**: Should Have
> **Status**: Complete
> **Sprint**: Sprint-006
> **Type**: UI + Integration
> **TR-ID**: TR-equip-010
> **ADR References**: ADR-001, ADR-002, ADR-003, ADR-009
> **Review Mode**: solo — QL-STORY-READY skipped
> **Estimate**: 0.5 day

## Context

**GDD**: `design/gdd/equipment-system.md`, `design/gdd/resource-economy.md`  
**Sprint source**: `production/sprints/sprint-006.md` / EQUIP-ENH-003  
**QA plan**: `production/qa/qa-plan-sprint-6.md`

This Should Have story closes the player feedback and persistence loop around enhancement after EQUIP-ENH-001/002. It focuses on success/failure messaging and save/load round-trip, not expanding enhancement scope.

## Acceptance Criteria

- [x] Enhancement success shows a localized toast or hint-bar message.
- [x] Enhancement blocked/failure states use localized hint-bar feedback.
- [x] A +5 enhanced equipped item persists through save/load.
- [x] Returning to the equipment panel after reload shows the same enhancement level.
- [x] Failure messaging exists for blocked Sprint-006 states without enabling +6+ risk-zone execution.

## Definition of Done

- [x] Integration test covers +5 enhancement round-trip through SaveData.
- [x] UI test covers success feedback and one blocked/insufficient-resource feedback state.
- [x] Localization key parity remains green.
- [x] Packaged smoke remains PASS if this story is included before sprint closure.

## Implementation Notes

- Use the existing hint bar/toast pattern; do not add a new notification framework.
- Persist enhancement state through existing equipment save/load paths.
- Keep +6 risk-zone execution outside Sprint-006 even if warning text exists.

## Test Evidence

**Required / completed**: `tests/integration/ui/character_management_test.gd`; existing `tests/integration/equipment/save_load_integration_test.gd` remains green; packaged smoke covers +5
**Gate**: BLOCKING for round-trip behavior, ADVISORY for screenshot polish

## Dependencies

- Depends on: EQUIP-ENH-001, EQUIP-ENH-002
- Unlocks: stronger Sprint-006 packaged smoke and Sprint-007 +6 risk-zone handoff

## Next Step

Run `/story-readiness production/epics/equipment-system/story-010-enhancement-round-trip.md` after EQUIP-ENH-001/002 are implemented.

## Completion Notes

Completed 2026-04-27 in Sprint-006. Evidence: src/, 	ests/, production/qa/qa-plan-sprint-6.md, production/sprints/sprint-006.md, and packaged smoke PACKAGED_PLAYTHROUGH_SMOKE PASS with Bond/Base/Equipment coverage.

