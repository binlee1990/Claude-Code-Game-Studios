# Epic: Chapter 03 Content

> **Layer**: Content
> **GDD**: `design/gdd/chapter-03.md`
> **Status**: Complete / Sprint-008 Ch.3 Playable Path Complete
> **Created**: 2026-04-27
> **Sprint Source**: Sprint-007 / CH3-EPIC-001

## Goal

Turn the Chapter 3 GDD into implementable production stories and close the Chapter 3 playable path: battle 1, battle 2, B3-GATE runtime branching, and the finale boss route variants.

## Scope Boundary

Sprint-008 completes the remaining Ch.3 content path. Bond combo skills, fog-of-war runtime, Ch.4, NG+, formal playtest notes, and new art/audio remain outside this epic.

## Governing References

| Source | Relevance |
|---|---|
| `design/gdd/chapter-03.md` | Chapter structure, battle 1 map/enemy data, B3-N1/B3-GATE rules |
| `design/narrative/belief-branching.md` | Belief route context and B2/B3 gate vocabulary |
| ADR-001 | Event/signal interactions |
| ADR-003 | Save/load of story progress |
| ADR-004 | Battle flow constraints |
| ADR-007 | Belief branch system and B3-GATE route persistence |

## Stories

| ID | Title | Type | Priority | Status |
|---|---|---|---|---|
| CH3-c-001 | Ch.3 battle 1 implementation | Config/Data + Integration | Must Have | Complete |
| CH3-c-002 | Ch.3 battle 2 pressure/scoring | Content + Integration | Must Have | Complete |
| CH3-c-003 | B3-GATE soft-lock evaluator | Logic + Save/Load | Must Have | Complete |
| CH3-c-004 | Ch.3 finale route variant | Content + Integration | Should Have | Complete |

## MVP Acceptance Criteria

- Chapter 3 epic folder exists with four complete story files.
- Ch.3 battle 1 boots and routes to Ch.3 battle 2.
- Ch.3 battle 2 consumes prior story progress, applies pressure/scoring, and records B3-GATE output.
- Finale battle selects deterministic route variants from B3-GATE and drives a three-phase boss.
- Epic index references the Chapter 3 epic as complete.

## Out of Scope

- B3-GATE hard-lock behavior
- Fog-of-war
- New art/audio requirements

## QA Plan

`production/qa/qa-plan-sprint-8.md`

## Next Step

Sprint-009 handoff can build on this path for Bond combo runtime, fog-of-war MVP, and Ch.4 planning.

## Completion Notes

Created 2026-04-27 as the first Sprint-007 dev-story cadence step. This completes CH3-EPIC-001 setup for Chapter 03 story pickup.

Sprint-008 completed the remaining playable Chapter 3 path:

- `src/ui/combat/battle_definitions/chapter_03_act_b.json`
- `src/core/chapter03/chapter_03_pressure_model.gd`
- `src/core/belief/b3_gate_evaluator.gd`
- `src/ui/combat/battle_definitions/chapter_03_finale.json`
- `tests/unit/chapter03/`
- `tests/integration/chapter03/`
- `tests/integration/prototypes/chapter_03_battle_2_entry_test.gd`
