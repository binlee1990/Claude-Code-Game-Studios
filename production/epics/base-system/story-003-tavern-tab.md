# Story BASE-TAVERN-001: Base Tavern Tab

> **Epic**: Base System Phase 1
> **Status**: Complete
> **Layer**: Feature
> **Type**: UI + Integration
> **Priority**: Must Have
> **Sprint**: Sprint-007
> **TR-ID**: TR-base-003
> **ADR References**: ADR-001, ADR-002, ADR-003, ADR-008
> **Estimate**: 0.5 day

## Context

**GDD**: `design/gdd/base-system.md`
**Sprint source**: `production/sprints/sprint-007.md` / BASE-TAVERN-001
**QA plan**: `production/qa/qa-plan-sprint-7.md`

Add a Tavern tab to Base Hub so Bond dialogue can attach to a visible, testable base function area. This story owns the tab route, locked/empty state, and conversation list shell. BOND-003 owns affinity mutation and completion recording.

## Acceptance Criteria

- [x] Base Hub includes a Tavern tab or equivalent tab route.
- [x] Tavern tab shows a locked/empty state when Tavern is not unlocked.
- [x] Tavern tab lists available conversations when Tavern is unlocked.
- [x] BOND-003 can consume the visible list without duplicating UI state.
- [x] Keyboard/controller tab cycling can reach Tavern.

## QA Test Conditions

- Given Tavern is locked, when the tab is selected, then locked/empty copy renders and no action mutates AP or affinity.
- Given Tavern is unlocked and conversations exist, when the tab is selected, then conversation rows render with stable IDs.
- Given focus navigation cycles through Base tabs, when Tavern is reached, then focus does not get trapped or skipped.
- Given localization is switched, when Tavern text renders, then zh/en keys remain present.

## Test Evidence

**Completed**: `tests/integration/ui/base_hub_test.gd` covers Tavern tab route, locked state, unlock flow, AP consumption, affinity mutation, and completion persistence.
**Gate**: PASS

## Dependencies

- Depends on: Sprint-006 `ActionPoints`, Base Hub tab pattern
- Unlocks: BOND-003 Tavern dialogue MVP

## Next Step

Complete 2026-04-27.
