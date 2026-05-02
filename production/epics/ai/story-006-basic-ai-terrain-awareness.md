# Story 006: BasicAI Terrain Awareness — cost-aware movement through MovementResolver

> **Epic**: AI
> **Status**: Done
> **Layer**: Feature
> **Type**: Logic

## Context

BasicAI should benefit from weighted movement without learning terrain-specific rules. Its decision space must come from `MovementResolver`, preserving AI as a planner over public movement and attack contracts.

## Acceptance Criteria

- [x] BasicAI continues to use `MovementResolver.compute_reachable()`.
- [x] BasicAI does not import or branch on terrain tile names.
- [x] BasicAI chooses a lower-cost move-and-attack position when rough terrain makes the direct route too expensive.
- [x] Existing direct-attack, move-toward, wait, missing-world-state, and immutability behavior remains unchanged.

## Test Evidence

- `tests/unit/ai/basic_ai_test.gd`
- Scene smoke: `src/Game.tscn --map=rough_pass --enemy-ai=basic` clean.
- Full runner: `Total Passed: 297`; zero script errors, assertion failures, error lines, or warnings observed.

## Out of Scope

- Tactical terrain evaluation beyond movement cost.
- Terrain-specific AI scoring.
- New AI mode.
