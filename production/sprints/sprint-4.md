# Sprint 4 — Tier 2 BasicAI Interface Validation

**Start**: 2026-05-02
**End**: 2026-05-02

## Sprint Goal

Validate the highest-risk Tier 2 extension point: `AIController` must admit a non-trivial `BasicAI` implementation without rewriting or importing `TurnManager`.

## Tasks

| ID | Story | Epic | Type | Status |
|----|-------|------|------|--------|
| 7-3 | BasicAI — 最近目标启发式计划生成器 | ai | Logic | Done |

## Definition of Done

- [x] `src/ai/basic_ai.gd` implements a pure `AIController` subclass
- [x] `BasicAI.take_turn()` returns meaningful `ActionPlan` values: `ATTACK_ONLY`, `MOVE_AND_ATTACK`, `MOVE_ONLY`, `WAIT`
- [x] `BasicAI` does not import or reference `TurnManager`
- [x] `BasicAI` does not mutate the passed `WorldState`
- [x] Default runner includes `tests/unit/ai/basic_ai_test.gd`
- [x] Current runner is clean: `Total Passed: 262`

## Scope Boundary

This sprint does **not** wire `BasicAI` into runtime ENEMY turns. Runtime AI execution requires a separate story for `TurnManager` ActionList execution, because that changes game behavior from hotseat-only to optional autonomous ENEMY control.

## Next Step

Create a follow-up story for optional AI runtime integration:

`TurnManager executes non-empty AI ActionList while preserving NullAI hotseat behavior`.
