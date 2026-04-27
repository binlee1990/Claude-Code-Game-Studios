# Story CH3-c-002: Ch.3 Battle 2 Pressure and Scoring Skeleton

> **Epic**: Chapter 03 Content
> **Status**: Backlog
> **Layer**: Content
> **Type**: Content + Integration
> **Priority**: Future
> **Sprint**: Sprint-008 Candidate
> **TR-ID**: TR-ch3-002

## Context

**GDD**: `design/gdd/chapter-03.md` §3.3
**QA plan**: `production/qa/qa-plan-sprint-7.md`

This skeleton captures the second Chapter 3 battle handoff. It is intentionally not in Sprint-007 implementation scope.

## Acceptance Criteria

- [ ] Ch.3 battle 2 data consumes Ch.3-1 results as pressure inputs.
- [ ] Beacon defense objective can be represented by battle data or a small controller.
- [ ] B3-N2 behavior scoring can produce ren/yi/zhi deltas.

## QA Test Conditions

- Given Ch.3-1 rescued civilian count is low, when Ch.3-2 starts, then enemy pressure input reflects the GDD rule.
- Given the beacon is held for 2 turns, when victory is evaluated, then the battle can complete.
- Given B3-N2 scoring is calculated, when all civilians are rescued or fast clear occurs, then the correct belief delta is emitted.

## Test Evidence

Future integration test for Ch.3 battle 2 boot, objective, and scoring.

## Next Step

Keep backlog until CH3-c-001 is complete and Sprint-008 scope is selected.
