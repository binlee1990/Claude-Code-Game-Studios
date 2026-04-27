# Story BOND-DATA-001: Bond Data Model + SaveData Payload

> **Title**: Bond data model + SaveData payload
> **Epic**: Bond System MVP
> **Layer**: Feature
> **Priority**: Must Have
> **Status**: Complete
> **Sprint**: Sprint-006
> **Type**: Logic + Integration
> **TR-ID**: TR-bond-001
> **ADR References**: ADR-001, ADR-003
> **Review Mode**: solo — QL-STORY-READY skipped
> **Estimate**: 0.5 day

## Context

**GDD**: `design/gdd/bond-system.md`
**Sprint source**: `production/sprints/sprint-006.md` / BOND-DATA-001
**QA plan**: `production/qa/qa-plan-sprint-6.md`

Sprint-006 needs the smallest persistent Bond data layer before event hooks or UI summaries can be implemented. Existing `SaveData.story_progress.bond_levels` must become or remain compatible with a pair-keyed registry that stores affinity, support rank, and bond type without breaking old saves.

## Acceptance Criteria

- [x] Stable bond pair keys are deterministic regardless of unit order where the relationship is symmetric.
- [x] Affinity value, support rank, and bond type serialize into `SaveData`.
- [x] Missing bond data in old saves defaults to an empty bond registry.
- [x] Rank thresholds from `design/gdd/bond-system.md` are centralized and testable.
- [x] Save/load round-trip preserves at least one bond pair and one empty registry case.

## Definition of Done

- [x] Logic unit tests cover creation, update, rank threshold, deserialize, and old-save default.
- [x] Integration test covers SaveData round-trip.
- [x] No combo skills, tavern UI, or Ch.3 dialogue implementation is added.
- [x] Story evidence is linked from the completion notes before `/story-done`.

## Implementation Notes

- Use `design/gdd/bond-system.md` rank thresholds as initial constants.
- Respect ADR-003: persisted data only; no logic callbacks inside saved payloads.
- If a migration helper is required, keep it local to save/bond load code and cover old-save fallback.

## Test Evidence

**Required / completed**: `tests/unit/bond/bond_data_model_test.gd` and `tests/integration/bond/affinity_event_hooks_test.gd`
**Gate**: BLOCKING

## Dependencies

- Depends on: `design/gdd/bond-system.md`, `src/core/save/save_data.gd`
- Unlocks: BOND-EVT-001, BOND-UI-001, future BOND-003 tavern dialogue

## Next Step

Run `/story-readiness production/epics/bond-system/story-001-data-model-save.md`, then `/dev-story` if READY.

## Completion Notes

Completed 2026-04-27 in Sprint-006. Evidence: src/, 	ests/, production/qa/qa-plan-sprint-6.md, production/sprints/sprint-006.md, and packaged smoke PACKAGED_PLAYTHROUGH_SMOKE PASS with Bond/Base/Equipment coverage.
