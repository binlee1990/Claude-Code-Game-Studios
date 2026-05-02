# Sprint 5 — Runtime AI ActionList Execution

**Start**: 2026-05-02
**End**: 2026-05-02

## Sprint Goal

Close the gap between AI planning and runtime behavior by letting `TurnManager` execute non-empty `ActionList` values without breaking `NullAI` hotseat mode.

## Tasks

| ID | Story | Epic | Type | Status |
|----|-------|------|------|--------|
| 7-4 | Runtime ActionList Execution — TurnManager 执行非空 AI 计划 | ai | Integration | Done |

## Definition of Done

- [x] `TurnManager` calls `AIController.take_turn()` on ENEMY activation.
- [x] `AIActionExecutor` interprets move, attack, move+attack, and wait plans through existing `Map` and `AttackResolver` APIs.
- [x] `NullAI` empty ActionList preserves manual ENEMY hotseat phase.
- [x] `BasicAI` can move and attack at runtime when injected.
- [x] Invalid wrong-faction plans are rejected defensively.
- [x] Default runner is clean: `Total Passed: 266`.

## Scope Boundary

This sprint does not change the default `Game` scene from `NullAI` to `BasicAI`. Runtime BasicAI is available through dependency injection; exposing it as a player-facing mode or demo toggle is a separate product decision.

## Next Step

Optional: add a small runtime/demo configuration for selecting `NullAI` vs `BasicAI`, then run manual visual QA for automated ENEMY movement timing.
