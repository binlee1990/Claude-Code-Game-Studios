# UI Scene Foundation Epic

Status: Done on 2026-05-05 via Sprint 11 completion pass.

## Scope

Connect the existing UIManager service to real Godot scene instances, modal routing, and the RootViewport scene tree.

## Stories

| Story | Status | Evidence |
|-------|--------|----------|
| S11-001-ui-scene-foundation | Done | `MAIN_SCENE_LOAD_OK`, `reports/report_21/results.xml` |
| S11-002-ui-scene-foundation | Done | `screenshots/modal_confirm_critical.png`, `modal_settings.png`, `modal_stance_select.png` |
| S11-003-ui-scene-foundation | Done | `screenshots/cultivation.png`, `scripts/validate_main_scene_load.gd` |

## Verification

- Main scene loading: `scripts/validate_main_scene_load.gd`.
- Full regression: `reports/report_21/results.xml` (137 tests, 0 failures, 0 skipped, 0 flaky).
- Visual smoke: `production/qa/evidence/sprint-11/first-playable-smoke.md`.
