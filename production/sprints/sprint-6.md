# Sprint 6 — Runtime AI Mode Selection

**Start**: 2026-05-03
**End**: 2026-05-03

## Sprint Goal

Expose a minimal demo/runtime configuration for selecting `NullAI` vs `BasicAI` without editing the `Game` composition root.

## Tasks

| ID | Story | Epic | Type | Status |
|----|-------|------|------|--------|
| 7-5 | Runtime AI Mode Selection — Game 可选 NullAI / BasicAI | ai | Integration | Done |

## Definition of Done

- [x] `srpg_mini/enemy_ai_mode` defaults to `hotseat` in `project.godot`.
- [x] `Game` resolves the configured mode and instantiates the matching `AIController`.
- [x] Command-line `--enemy-ai=basic` and `--enemy-ai hotseat` override project settings for demo runs.
- [x] Unit tests cover project-setting and command-line selection.
- [x] Default runner is clean: `Total Passed: 275`.
- [x] Default scene smoke is clean.
- [x] BasicAI-mode scene smoke is clean.

## Scope Boundary

This sprint only exposes selection. It does not add in-game menus, HUD indicators for the selected AI mode, or visual polish features for automatic ENEMY movement timing. CP11 is covered by AI/automated verification in `production/qa/visual-verification-checklist.md`.

## Next Step

Sprint 7 completed a verified Map Variant Pack using `$generate2dmap` as a project-native tactical-map data workflow. Optional next extension: runtime map selection after spawn-fixture consumption is designed.
