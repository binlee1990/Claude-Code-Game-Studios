# Story CH3-c-004: Ch.3 Finale Route Variant Skeleton

> **Epic**: Chapter 03 Content
> **Status**: Backlog
> **Layer**: Content
> **Type**: Content + Integration
> **Priority**: Future
> **Sprint**: Sprint-008 Candidate
> **TR-ID**: TR-ch3-004

## Context

**GDD**: `design/gdd/chapter-03.md` §3.5
**QA plan**: `production/qa/qa-plan-sprint-7.md`

This skeleton captures the finale battle variants driven by B3-GATE. It is not a Sprint-007 implementation target.

## Acceptance Criteria

- [ ] Finale battle reads B3-GATE dominant route.
- [ ] Ren route changes civilian evacuation pressure.
- [ ] Yi route changes boss guard/elite pressure.
- [ ] Zhi route changes interactable mechanisms and turn pressure.

## QA Test Conditions

- Given `dominant_route=ren`, when finale data loads, then civilian evacuation variant is selected.
- Given `dominant_route=yi`, when finale data loads, then boss guard variant is selected.
- Given `dominant_route=zhi`, when finale data loads, then interactable/turn-pressure variant is selected.
- Given no B3-GATE state exists, when finale data loads, then fallback behavior is deterministic and non-crashing.

## Test Evidence

Future integration tests for route variant selection and finale boot.

## Next Step

Keep backlog until B3-GATE evaluator is complete.
