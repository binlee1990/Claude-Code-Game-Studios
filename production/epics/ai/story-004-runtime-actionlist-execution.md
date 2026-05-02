# Story 004 — Runtime ActionList Execution

> **Epic**: AI
> **Type**: Integration
> **Status**: Done
> **Date**: 2026-05-02
> **ADR**: ADR-0008

## Goal

Allow `TurnManager` to execute non-empty AI `ActionList` values during ENEMY phases while preserving `NullAI` hotseat behavior.

## Acceptance Criteria

- [x] `TurnManager` calls `AIController.take_turn()` when ENEMY becomes active.
- [x] `NullAI` returns an empty `ActionList` and leaves ENEMY phase available for manual hotseat control.
- [x] Non-empty BasicAI plans move, attack, consume unit action, and advance back to PLAYER when all ENEMY units have acted.
- [x] AI receives active alive ENEMY units plus a `WorldState` containing the map and alive units.
- [x] Wrong-faction ActionPlans are rejected without mutating PLAYER units.
- [x] `Game` injects `Map` and the shared `AttackResolver` into `TurnManager`; default scene behavior remains `NullAI`.

## Evidence

- `src/turn/ai_action_executor.gd`
- `src/turn/turn_manager.gd`
- `tests/unit/turn/turn_ai_execution_test.gd`
- Default runner: `Total Passed: 292`

## Notes

`BasicAI` is runtime-executable through dependency injection, but the main `Game` scene still uses `NullAI` to preserve the signed-off MVP hotseat baseline.
