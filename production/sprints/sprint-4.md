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
- [x] Current runner is clean: `Total Passed: 275`

## Scope Boundary

This sprint itself validated the pure BasicAI planner. Runtime ActionList execution was completed afterward in Sprint 5, while the default Game scene remains `NullAI` hotseat.

## Next Step

Sprint 5 completed runtime AI ActionList execution. The remaining optional product step is a runtime/demo toggle for selecting `NullAI` vs `BasicAI`.
