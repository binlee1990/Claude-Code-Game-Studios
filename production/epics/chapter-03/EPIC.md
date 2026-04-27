# Epic: Chapter 03 Content

> **Layer**: Content
> **GDD**: `design/gdd/chapter-03.md`
> **Status**: Sprint-007 Battle 1 Complete
> **Created**: 2026-04-27
> **Sprint Source**: Sprint-007 / CH3-EPIC-001

## Goal

Turn the Chapter 3 GDD into implementable production stories, beginning with the first playable battle slice in Sprint-007 and leaving the later battle/gate content as explicit follow-up stories.

## Scope Boundary

Sprint-007 implements Ch.3 battle 1 only. Ch.3 battle 2, B3-GATE runtime branching, and the finale remain story skeletons unless Sprint-007 explicitly expands scope.

## Governing References

| Source | Relevance |
|---|---|
| `design/gdd/chapter-03.md` | Chapter structure, battle 1 map/enemy data, B3-N1/B3-GATE rules |
| `design/narrative/belief-branching.md` | Belief route context and B2/B3 gate vocabulary |
| ADR-001 | Event/signal interactions |
| ADR-003 | Save/load of story progress |
| ADR-004 | Battle flow constraints |

## Stories

| ID | Title | Type | Priority | Status |
|---|---|---|---|---|
| CH3-c-001 | Ch.3 battle 1 implementation | Config/Data + Integration | Must Have | Complete |
| CH3-c-002 | Ch.3 battle 2 pressure/scoring skeleton | Content + Integration | Future | Backlog |
| CH3-c-003 | B3-GATE soft-lock evaluator skeleton | Logic + Save/Load | Future | Backlog |
| CH3-c-004 | Ch.3 finale route variant skeleton | Content + Integration | Future | Backlog |

## MVP Acceptance Criteria

- Chapter 3 epic folder exists with four story files.
- Ch.3 battle 1 story can be picked up by `/dev-story` without needing to infer acceptance criteria from the GDD.
- Future battle/gate stories are present as bounded handoff shells, not hidden scope.
- Epic index references the Chapter 3 epic.

## Out of Scope

- Ch.3 battle 2 runtime
- Ch.3 finale runtime
- B3-GATE hard-lock behavior
- Fog-of-war
- New art/audio requirements

## QA Plan

`production/qa/qa-plan-sprint-7.md`

## Next Step

Run `/dev-story production/epics/chapter-03/story-001-battle-1-implementation.md`.

## Completion Notes

Created 2026-04-27 as the first Sprint-007 dev-story cadence step. This completes CH3-EPIC-001 setup for Chapter 03 story pickup.
