# QA Plan Sprint 11 — UI Scene Layer

Date: 2026-05-05

Verdict: PASS

## Scope

Sprint 11 validates the real Godot UI scene layer for MVP First Playable:

- RootViewport, screen stack, modal stack, toast layer, drawer layer.
- HUD shell with top strip, left nav, right panel, and status/resource presentation.
- Five MVP screens: cultivation, combat, resources/backpack, save, offline settlement.
- Nice-to-have UI: settings modal and debug console overlay.
- 4K display scaling and user-controlled UI scale for full-screen desktop play.

## Required Gates

| Gate | Evidence | Result |
|------|----------|--------|
| Main scene load + settings resolution/UI scale controls | `scripts/validate_main_scene_load.gd` | PASS: `MAIN_SCENE_LOAD_OK` |
| Settings confirm interaction | `scripts/validate_settings_interaction.gd` | PASS: `SETTINGS_INTERACTION_OK`; GUI run also covers fullscreen-to-windowed resolution Apply |
| Cultivation high-scale layout | `scripts/validate_cultivation_layout.gd` | PASS: `CULTIVATION_LAYOUT_OK`; 1920x1080 at 135% UI scale keeps `应用此姿态` inside `ScreenContainer` |
| Combat high-scale layout | `scripts/validate_combat_layout.gd` | PASS: `COMBAT_LAYOUT_OK`; 1920x1080 at 135% UI scale keeps enemy/player state above the bottom control bar |
| 4K UI scale | `scripts/validate_4k_ui_scale.gd` | PASS: `S11_4K_UI_SCALE_OK` |
| Visual smoke | `production/qa/evidence/sprint-11/first-playable-smoke.md` | PASS |
| Screenshot evidence | `production/qa/evidence/sprint-11/screenshots/` | PASS: 15 screenshots |
| Manual walkthrough | `production/qa/evidence/sprint-11/manual-walkthrough.md` | PASS |
| Asset coverage | `production/qa/evidence/sprint-11/asset-coverage-report.json` | PASS: 108 / 108 |
| GdUnit regression | `reports/report_34/results.xml` | PASS: 137 tests, 0 failures, 0 skipped |
| Godot import | `godot --headless --path . --import --quit` | PASS |

## Story Coverage

| Story Range | Gate |
|-------------|------|
| S11-001..003 | Main load + modal screenshots |
| S11-004..006 | HUD screenshots + asset coverage |
| S11-007 | Toast screenshot |
| S11-008 | Offline drawer screenshot |
| S11-009..013 | Five MVP screen screenshots |
| S11-014 | Debug console screenshot + existing unit tests |
| S11-015 | Settings modal screenshot + resolution selector + UI scale slider + confirm/apply validation |
| S11-016 | First playable smoke + asset coverage + 4K scale check |

## Residual Risk

- Screenshots are deterministic smoke evidence, not a human playtest recording.
- 4K screenshot evidence is captured from Godot's logical content-scale viewport; physical 4K scaling is verified by UIManagerHost-owned `UIScaleSettings`, Settings confirmation validation, and `Window` content-scale assertions.
- Combat UI uses one-encounter settlement through the existing SemiAutoCombatSystem API; deeper combat animation polish remains post-MVP.
