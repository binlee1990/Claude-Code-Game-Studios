# Story BOND-003: Base Tavern Dialogue Trigger MVP

> **Epic**: Bond System MVP
> **Status**: Complete
> **Type**: UI/Integration
> **Sprint**: Sprint-007
> **TR-ID**: TR-bond-003
> **QA plan**: `production/qa/qa-plan-sprint-7.md`

## Acceptance Criteria

- [x] Base tavern can list available support conversations.
- [x] Triggering a conversation consumes the configured base action point if that rule is active.
- [x] Dialogue completion grants affinity and records completion.
- [x] UI degrades gracefully if the tavern is not unlocked.

## QA Test Conditions

- Given Tavern is unlocked and AP is available, when the player triggers an available support conversation, then AP decreases by 1 and the pair affinity increases.
- Given a conversation has already completed, when the Tavern list is rebuilt, then the completed conversation cannot grant affinity again.
- Given Tavern is locked or AP is 0, when the player attempts a conversation, then the action is blocked with localized feedback and no affinity mutation occurs.
- Given dialogue completion is saved and loaded, then completion state and affinity remain present.

## Test Evidence

**Completed**: `tests/integration/bond/affinity_event_hooks_test.gd`; `tests/integration/ui/base_hub_test.gd` Tavern extension.
**Gate**: PASS

## Notes

Depends on Base full phase 1. This should not block Ch.3 route-only implementation.
