# Quick Spec: Difficulty Phase Transition

> **Status**: Accepted
> **Date**: 2026-05-02
> **Related**: ADR-012, `design/gdd/difficulty-system.md`, Sprint-009 DIFF-001/002

## Decision

Difficulty phase is evaluated when a battle profile is created or refreshed from chapter context. A battle already in progress keeps its current profile until the next battle load or explicit story transition refresh.

## Context

The design review batch found an edge case: phase boundaries can occur between chapters, but the GDD did not say whether an in-progress battle should change difficulty immediately.

## Scope

Included:

- Chapter-to-phase mapping for new battle loads.
- Save/load restoration of the already selected battle context.
- Explicit story transition refresh before the next battle definition loads.

Excluded:

- Mid-turn difficulty mutation.
- Player-facing NG+ difficulty selection.
- Dynamic encounter scaling inside one battle.

## Acceptance

- `DifficultyManager.get_profile(chapter)` remains deterministic for the same chapter.
- Existing battle save/load tests are not required to mutate profile mid-battle.
- Future battle-level difficulty E2E tests should assert profile selection at battle start, not mid-turn mutation.
