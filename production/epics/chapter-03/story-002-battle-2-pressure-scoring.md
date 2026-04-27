# Story CH3-c-002: Ch.3 Battle 2 Pressure and Scoring

> **Epic**: Chapter 03 Content
> **Status**: Complete
> **Layer**: Content
> **Type**: Content + Integration
> **Priority**: Must Have
> **Sprint**: Sprint-008
> **TR-ID**: TR-ch3-002

## Context

**GDD**: `design/gdd/chapter-03.md` §3.3
**QA plan**: `production/qa/qa-plan-sprint-8.md`

This story implements the second Chapter 3 battle handoff: prior Ch.3-1 outcomes shape pressure inputs, B3-N2 scoring writes belief deltas, and victory routes into B3-GATE/finale progression.

## Acceptance Criteria

- [x] Ch.3 battle 2 data consumes Ch.3-1 results as pressure inputs.
- [x] Beacon defense objective can be represented by battle data or a small controller.
- [x] B3-N2 behavior scoring can produce ren/yi/zhi deltas.

## QA Test Conditions

- Given Ch.3-1 rescued civilian count is low, when Ch.3-2 starts, then enemy pressure input reflects the GDD rule.
- Given the beacon is held for 2 turns, when victory is evaluated, then the battle can complete.
- Given B3-N2 scoring is calculated, when all civilians are rescued or fast clear occurs, then the correct belief delta is emitted.

## Test Evidence

- `src/ui/combat/battle_definitions/chapter_03_act_b.json`
- `src/core/chapter03/chapter_03_pressure_model.gd`
- `tests/unit/chapter03/battle_2_pressure_test.gd`
- `tests/integration/prototypes/chapter_03_battle_2_entry_test.gd`

## Next Step

Closed in Sprint-008. Follow-up runtime systems should use the same battle-definition pressure metadata instead of hardcoding Ch.3-only rules in UI code.
