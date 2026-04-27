# Story CH3-c-003: B3-GATE Soft-Lock Evaluator

> **Epic**: Chapter 03 Content
> **Status**: Complete
> **Layer**: Content
> **Type**: Logic + Save/Load
> **Priority**: Must Have
> **Sprint**: Sprint-008
> **TR-ID**: TR-ch3-003

## Context

**GDD**: `design/gdd/chapter-03.md` §3.4, §4 F1
**QA plan**: `production/qa/qa-plan-sprint-8.md`

B3-GATE evaluates the dominant belief route after Ch.3 battle 2 and records only a soft-lock candidate.

## Acceptance Criteria

- [x] Dominant route is the max of ren/yi/zhi.
- [x] `soft_lock_candidate` is true only when the dominant value leads the second value by at least 20.
- [x] Missing or tied values fallback to `zhi` without hard-locking the player.
- [x] Result persists in `story_progress.b3_gate`.

## QA Test Conditions

- Given ren=50, yi=25, zhi=10, when B3-GATE evaluates, then dominant route is `ren` and soft lock is true.
- Given ren=30, yi=25, zhi=20, when B3-GATE evaluates, then dominant route is `ren` and soft lock is false.
- Given all values are missing or tied, when B3-GATE evaluates, then fallback route is `zhi` and no crash occurs.
- Given result is saved and loaded, then `dominant_route`, `margin`, and `soft_lock_candidate` round-trip.

## Test Evidence

- `src/core/belief/b3_gate_evaluator.gd`
- `src/core/belief/belief_system.gd`
- `src/ui/combat/battle_arena.gd`
- `tests/unit/chapter03/b3_gate_evaluator_test.gd`
- `tests/integration/chapter03/b3_gate_persistence_test.gd`

## Next Step

Closed in Sprint-008. The evaluator records a soft-lock candidate only; it does not remove player agency or implement hard-lock routing.
