# Story BOND-UI-001: Character Detail Bond Summary

> **Title**: Character detail Bond summary
> **Epic**: Bond System MVP
> **Layer**: Feature
> **Priority**: Should Have
> **Status**: Complete
> **Sprint**: Sprint-006
> **Type**: UI + Integration
> **TR-ID**: TR-bond-004
> **ADR References**: ADR-001, ADR-002
> **Review Mode**: solo — QL-STORY-READY skipped
> **Estimate**: 0.25 day

## Context

**GDD**: `design/gdd/bond-system.md`
**Sprint source**: `production/sprints/sprint-006.md` / BOND-UI-001
**QA plan**: `production/qa/qa-plan-sprint-6.md`

Sprint-006 exposes Bond data to the player only as a compact character-detail summary. It must not add tavern interactions, clickable bond events, or combo skill flows.

## Acceptance Criteria

- [x] Character management shows each selected unit's top three bond entries when data exists.
- [x] Each entry includes partner, rank, bond type, and current affinity.
- [x] Empty state is localized for `zh_CN` and `en_US`.
- [x] UI remains responsive with zero, one, three, and five active bonds.
- [x] Summary is read-only; no tavern/dialogue interaction is available in this story.

## Definition of Done

- [x] Character management integration test covers non-empty and empty Bond summary states.
- [x] Localization key parity remains green.
- [x] Screenshot/walkthrough evidence is added only if UI layout changes are visually significant.
- [x] No BOND-003 tavern behavior is implemented.

## Implementation Notes

- Reuse existing character detail panel patterns.
- Keep the display dense and non-clickable; Sprint-007 owns tavern/dialogue interaction.
- Do not let UI own Bond state; it should read from the Bond data/model layer.

## Test Evidence

**Required**: extend `tests/integration/ui/character_management_test.gd`
**Optional advisory**: `production/qa/evidence/sprint-006-bond-summary.md`
**Gate**: BLOCKING for integration behavior, ADVISORY for visual sign-off

## Dependencies

- Depends on: BOND-DATA-001, localization catalog, character management UI
- Unlocks: player-facing readiness for future tavern/Bond dialogue stories

## Next Step

Run `/story-readiness production/epics/bond-system/story-004-character-summary.md` after BOND-DATA-001 is ready.

## Completion Notes

Completed 2026-04-27 in Sprint-006. Evidence: src/, 	ests/, production/qa/qa-plan-sprint-6.md, production/sprints/sprint-006.md, and packaged smoke PACKAGED_PLAYTHROUGH_SMOKE PASS with Bond/Base/Equipment coverage.
