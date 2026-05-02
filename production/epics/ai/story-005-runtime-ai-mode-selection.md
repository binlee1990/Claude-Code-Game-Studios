# Story 005 — Runtime AI Mode Selection

> **Epic**: AI
> **Type**: Integration
> **Status**: Done
> **Date**: 2026-05-03
> **ADR**: ADR-0008

## Goal

Allow the `Game` composition root to select `NullAI` or `BasicAI` at runtime without editing source code, while preserving the default signed-off hotseat baseline.

## Acceptance Criteria

- [x] `project.godot` defines `srpg_mini/enemy_ai_mode="hotseat"` by default.
- [x] `Game` creates `NullAI` for `hotseat` mode.
- [x] `Game` creates `BasicAI` for `basic` mode.
- [x] Command-line `--enemy-ai=basic` overrides the project setting for demo runs.
- [x] Command-line `--enemy-ai hotseat` can force the hotseat baseline.
- [x] Default `src/Game.tscn` scene smoke remains clean.
- [x] `src/Game.tscn -- --enemy-ai=basic` scene smoke is clean.

## Evidence

- `project.godot`
- `src/game.gd`
- `tests/unit/ui/game_ai_mode_test.gd`
- Default runner: `Total Passed: 270`

## Notes

This story provides selection and smoke coverage. It does not replace the signed-off manual visual checklist; automated ENEMY movement timing should still receive a manual visual QA pass before treating BasicAI mode as product-facing.
