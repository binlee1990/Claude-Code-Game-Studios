# S11-015 Settings

Status: Done.

Implementation:
- Settings modal includes volume, resolution, language, number format, reduced motion, and offline confirmation controls.
- Settings modal includes a persisted resolution selector and UI scale slider from 100% to 150%, committed through `应用` / `确认`.

Evidence:
- `production/qa/evidence/sprint-11/screenshots/modal_settings.png`
- `scripts/validate_main_scene_load.gd`
- `scripts/validate_settings_interaction.gd`
- `scripts/validate_4k_ui_scale.gd`

Assets: `res://assets/ui/theme.tres`.
