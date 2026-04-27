# Story BASE-AP-001: Action Point Model + Save

> **Title**: Action Point model + save
> **Epic**: Base System Phase 1
> **Layer**: Feature
> **Priority**: Must Have
> **Status**: Complete
> **Sprint**: Sprint-006
> **Type**: Logic + Integration + UI
> **TR-ID**: TR-base-001
> **ADR References**: ADR-001, ADR-003, ADR-008
> **Review Mode**: solo — QL-STORY-READY skipped
> **Estimate**: 0.75 day

## Context

**GDD**: `design/gdd/base-system.md` rule 4 and F2  
**Sprint source**: `production/sprints/sprint-006.md` / BASE-AP-001  
**QA plan**: `production/qa/qa-plan-sprint-6.md`

Sprint-004 delivered Base MVP without pacing. Sprint-006 adds a small Action Point model that gates training but keeps market and equipment operations free, preserving ADR-008's market boundary.

## Acceptance Criteria

- [x] Action points reset to 5 at chapter start or equivalent chapter reset boundary.
- [x] Training consumes 1 AP.
- [x] Market buy/sell consumes 0 AP and remains usable when AP is 0.
- [x] AP state persists through save/load.
- [x] Base UI top/status area displays current AP.
- [x] Attempting AP-gated training at 0 AP is rejected with localized feedback.

## Definition of Done

- [x] Unit tests cover reset, consume, insufficient AP, and AP-free action behavior.
- [x] Save/load integration test covers AP round-trip.
- [x] Base hub UI integration test covers AP display and training consumption.
- [x] Existing Sprint-004 base hub market/training tests remain green.

## Implementation Notes

- Prefer a base module or ActionPoints helper over scattered UI counters.
- Keep market AP-free per ADR-008.
- Do not add tavern, world map, or base upgrade UI in this story.
- Follow ADR-003 for persisted state shape and migration defaults.

## Test Evidence

**Required**: `tests/unit/base/action_points_test.gd`; extend `tests/integration/ui/base_hub_test.gd`; save/load round-trip test  
**Gate**: BLOCKING for logic/integration, ADVISORY for visual display

## Dependencies

- Depends on: Sprint-004 Base MVP, `design/gdd/base-system.md`, ADR-003, ADR-008
- Unlocks: BASE-INTEL-001 and future BOND-003 tavern dialogue AP consumption

## Next Step

Run `/story-readiness production/epics/base-system/story-001-action-points-save.md`, then `/dev-story` if READY.

## Completion Notes

Completed 2026-04-27 in Sprint-006. Evidence: src/, 	ests/, production/qa/qa-plan-sprint-6.md, production/sprints/sprint-006.md, and packaged smoke PACKAGED_PLAYTHROUGH_SMOKE PASS with Bond/Base/Equipment coverage.

