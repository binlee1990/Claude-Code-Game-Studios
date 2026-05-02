# Story 009: Multi-map Runtime Smoke — default/hotseat/BasicAI across variants

> **Epic**: Map / Coordinates
> **Status**: Done
> **Layer**: QA / Integration
> **Type**: QA + Integration

## Context

Runtime map selection must be proven through both unit tests and scene boot smokes. Because `BasicAI` depends on map topology and spawn distance, at least one selected variant must boot with `--enemy-ai=basic`.

## Acceptance Criteria

- [x] Default runner is clean.
- [x] Default `src/Game.tscn` scene smoke is clean.
- [x] Variant map hotseat scene smoke is clean.
- [x] Variant map + `--enemy-ai=basic` scene smoke is clean.
- [x] No script errors, assertions, `ERROR:` lines, or warnings are emitted.

## Test Evidence

- Full runner: `Total Passed: 297`; zero script errors, assertion failures, error lines, or warnings observed.
- Scene smoke matrix from `production/qa/qa-plan-sprint-8-2026-05-03.md`: default, `--map=crossroads`, and `--map=split_lanes --enemy-ai=basic` all clean.

## Out of Scope

- Manual visual QA unless UI/art changes are introduced.
