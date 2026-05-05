# Sprint 11 4K UI Scale Evidence

Date: 2026-05-05

Verdict: PASS

## Issue

On a 3840x2160 display, UI buttons and shell controls felt too small because the UI was effectively using fixed logical Control sizes without a project-level stretch baseline.

## Fix

- `UIManagerHost` creates and owns `UIScaleSettings`, avoiding a fragile extra `project.godot` autoload entry.
- `UIScaleSettings` applies a 1280x720 design baseline with `canvas_items` stretch and `expand` aspect handling, then applies persisted `window_width` / `window_height` and `ui_scale_multiplier` preferences at startup.
- The Settings modal includes a real `分辨率` selector, a `UI 缩放` slider with live percent feedback, and `应用` / `确认` / `关闭` action buttons.
- `RootViewport` now decides initial left-nav collapse from the physical window size, so a 4K screen is not treated as a 1280px narrow layout after canvas scaling.
- `UIManagerHost` now retries post-initialization until `RootViewport` exists, avoiding autoload/main-scene ordering warnings in script-driven validation.

## Evidence

- Script: `scripts/validate_4k_ui_scale.gd`
- Expected output: `S11_4K_UI_SCALE_OK`
- Screenshot: `production/qa/evidence/sprint-11/screenshots/4k_ui_scale.png`
- Settings control: `scripts/validate_main_scene_load.gd` opens Settings, selects `1280x720`, moves `UIScaleSlider` to 125%, clicks `确认`, verifies the window size changes, and verifies `content_scale_factor` changes while the `1280x720` layout canvas is preserved.
- Fullscreen control: `scripts/validate_4k_ui_scale.gd` now enters `WINDOW_MODE_FULLSCREEN` and verifies fullscreen keeps `content_scale_size == 1280x720` with `content_scale_factor == 1.0` before restoring the prior window mode.
- Interaction control: `scripts/validate_settings_interaction.gd` verifies selection/slider changes stay pending until `确认`, then apply together.

## Notes

The screenshot capture is saved from Godot's content-scaled viewport. On a 3840x2160 physical window, the 1280x720 canvas baseline scales UI controls by 3x at 100%; choosing 125% raises `content_scale_factor` without shrinking the layout canvas, so the UI gets larger without clipping the shell.
