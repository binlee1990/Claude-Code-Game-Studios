# Story CH3-c-003: B3-GATE Soft-Lock Evaluator Skeleton

> **Epic**: Chapter 03 Content
> **Status**: Backlog
> **Layer**: Content
> **Type**: Logic + Save/Load
> **Priority**: Future
> **Sprint**: Sprint-008 Candidate
> **TR-ID**: TR-ch3-003

## Context

**GDD**: `design/gdd/chapter-03.md` §3.4, §4 F1
**QA plan**: `production/qa/qa-plan-sprint-7.md`

B3-GATE evaluates the dominant belief route after Ch.3 battle 2 and records only a soft-lock candidate.

## Acceptance Criteria

- [ ] Dominant route is the max of ren/yi/zhi.
- [ ] `soft_lock_candidate` is true only when the dominant value leads the second value by at least 20.
- [ ] Missing or tied values fallback to `zhi` without hard-locking the player.
- [ ] Result persists in `story_progress.b3_gate`.

## QA Test Conditions

- Given ren=50, yi=25, zhi=10, when B3-GATE evaluates, then dominant route is `ren` and soft lock is true.
- Given ren=30, yi=25, zhi=20, when B3-GATE evaluates, then dominant route is `ren` and soft lock is false.
- Given all values are missing or tied, when B3-GATE evaluates, then fallback route is `zhi` and no crash occurs.
- Given result is saved and loaded, then `dominant_route`, `margin`, and `soft_lock_candidate` round-trip.

## Test Evidence

Future unit test for gate formula plus save/load integration.

## Next Step

Keep backlog until Ch.3 battle 2 scoring exists.
