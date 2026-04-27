# Story BOND-EVT-001: Affinity Gain Event Hooks

> **Title**: Affinity gain event hooks
> **Epic**: Bond System MVP
> **Layer**: Feature
> **Priority**: Must Have
> **Status**: Complete
> **Sprint**: Sprint-006
> **Type**: Integration
> **TR-ID**: TR-bond-002
> **ADR References**: ADR-001, ADR-003, ADR-004
> **Review Mode**: solo — QL-STORY-READY skipped
> **Estimate**: 0.5 day

## Context

**GDD**: `design/gdd/bond-system.md`
**Sprint source**: `production/sprints/sprint-006.md` / BOND-EVT-001
**QA plan**: `production/qa/qa-plan-sprint-6.md`

After BOND-DATA-001 creates persistent bond pairs, Sprint-006 needs one narrow, deterministic event path that can add affinity and emit a traceable signal. The target is a small hook from battle settlement or camp/base interaction, not a broad combat rewrite.

## Acceptance Criteria

- [x] At least one battle or camp/base event can add affinity to an existing or newly created bond pair.
- [x] Event application is deterministic and testable without random or time-dependent assertions.
- [x] Affinity gains clamp to the designed maximum.
- [x] Post-event affinity persists through save/load.
- [x] A `bond_level_up` or equivalent bond-domain signal is emitted only when a rank threshold is crossed.

## Definition of Done

- [x] Integration test covers an affinity gain event.
- [x] Save/load test proves post-event affinity survives round-trip.
- [x] Event signal payload includes enough context for UI/listeners.
- [x] No decorative UI, tavern dialogue system, or combo skill logic is introduced.

## Implementation Notes

- Prefer a narrow hook such as camp dialogue completion or adjacent assist.
- Follow ADR-001 signal rules: `snake_case`, sufficient context, no nested same-bus signal chains.
- Use BOND-DATA-001 APIs rather than editing saved dictionaries directly from event code.

## Test Evidence

**Required**: `tests/integration/bond/affinity_event_hooks_test.gd`
**Gate**: BLOCKING

## Dependencies

- Depends on: BOND-DATA-001, ADR-001 GameEvents, battle settlement or base/camp event surface
- Unlocks: BOND-UI-001 and future Ch.3 bond dialogue conditions

## Next Step

Run `/story-readiness production/epics/bond-system/story-002-affinity-event-hooks.md`, then `/dev-story` if READY.

## Completion Notes

Completed 2026-04-27 in Sprint-006. Evidence: src/, 	ests/, production/qa/qa-plan-sprint-6.md, production/sprints/sprint-006.md, and packaged smoke PACKAGED_PLAYTHROUGH_SMOKE PASS with Bond/Base/Equipment coverage.
