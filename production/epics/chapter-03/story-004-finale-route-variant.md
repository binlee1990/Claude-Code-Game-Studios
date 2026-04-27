# Story CH3-c-004: Ch.3 Finale Route Variant

> **Epic**: Chapter 03 Content
> **Status**: Complete
> **Layer**: Content
> **Type**: Content + Integration
> **Priority**: Should Have
> **Sprint**: Sprint-008
> **TR-ID**: TR-ch3-004

## Context

**GDD**: `design/gdd/chapter-03.md` §3.5
**QA plan**: `production/qa/qa-plan-sprint-8.md`

This story implements the finale battle variants driven by B3-GATE and reuses the existing boss phase controller pattern for a three-phase Chapter 3 boss.

## Acceptance Criteria

- [x] Finale battle reads B3-GATE dominant route.
- [x] Ren route changes civilian evacuation pressure.
- [x] Yi route changes boss guard/elite pressure.
- [x] Zhi route changes interactable mechanisms and turn pressure.

## QA Test Conditions

- Given `dominant_route=ren`, when finale data loads, then civilian evacuation variant is selected.
- Given `dominant_route=yi`, when finale data loads, then boss guard variant is selected.
- Given `dominant_route=zhi`, when finale data loads, then interactable/turn-pressure variant is selected.
- Given no B3-GATE state exists, when finale data loads, then fallback behavior is deterministic and non-crashing.

## Test Evidence

- `src/ui/combat/battle_definitions/chapter_03_finale.json`
- `src/ui/combat/battle_arena.gd`
- `tests/unit/chapter03/finale_route_variant_test.gd`
- `tests/integration/chapter03/finale_boot_test.gd`

## Next Step

Closed in Sprint-008. Future finale polish can add authored art/audio without changing the B3-GATE route schema.
