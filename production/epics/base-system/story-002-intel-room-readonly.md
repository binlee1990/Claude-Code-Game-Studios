# Story BASE-INTEL-001: Intel Room Read-Only Briefing

> **Title**: Intel Room read-only briefing
> **Epic**: Base System Phase 1
> **Layer**: Feature
> **Priority**: Should Have
> **Status**: Complete
> **Sprint**: Sprint-006
> **Type**: UI + Config/Data
> **TR-ID**: TR-base-002
> **ADR References**: ADR-001, ADR-002, ADR-008
> **Review Mode**: solo — QL-STORY-READY skipped
> **Estimate**: 0.5 day

## Context

**GDD**: `design/gdd/base-system.md` Intel Room function area  
**Sprint source**: `production/sprints/sprint-006.md` / BASE-INTEL-001  
**QA plan**: `production/qa/qa-plan-sprint-6.md`

The Intel Room gives players a read-only preparation surface for current chapter context and next battle preview. Sprint-006 does not implement Ch.3 combat or B3-GATE runtime; this story should only expose existing/skeleton data.

## Acceptance Criteria

- [x] Base hub has an Intel tab or equivalent route.
- [x] Intel screen shows current chapter title/briefing.
- [x] Intel screen shows next battle preview sourced from chapter/battle data where available.
- [x] Viewing Intel consumes 0 AP.
- [x] Missing or placeholder chapter data degrades to a localized "briefing unavailable" state.
- [x] No Ch.3 battle implementation, branch runtime, or world map exploration is added.

## Definition of Done

- [x] Base hub integration test covers Intel tab routing.
- [x] Config/data smoke verifies missing-data fallback.
- [x] Localization key parity remains green for empty/fallback states.
- [x] Existing Base MVP tests remain green.

## Implementation Notes

- Read from existing chapter JSON or `design/gdd/chapter-03.md`-derived placeholders only if those are already represented in runtime data.
- Do not make Intel Room responsible for campaign progression.
- Do not consume AP for read-only briefing.

## Test Evidence

**Required**: extend `tests/integration/ui/base_hub_test.gd`; config parse/fallback assertion  
**Gate**: ADVISORY for config/data, BLOCKING if UI route becomes part of sprint closure

## Dependencies

- Depends on: BASE-AP-001, `design/gdd/chapter-03.md`, Sprint-004 Base MVP
- Unlocks: Sprint-007 Ch.3 battle implementation briefing route

## Next Step

Run `/story-readiness production/epics/base-system/story-002-intel-room-readonly.md` after BASE-AP-001 is ready.

## Completion Notes

Completed 2026-04-27 in Sprint-006. Evidence: src/, 	ests/, production/qa/qa-plan-sprint-6.md, production/sprints/sprint-006.md, and packaged smoke PACKAGED_PLAYTHROUGH_SMOKE PASS with Bond/Base/Equipment coverage.

