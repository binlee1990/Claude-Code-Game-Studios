# S11-002 Modal Stack Z-Order

Status: Done.

Implementation:
- RootViewport owns a dedicated ModalLayer above ToastLayer and DrawerLayer.
- Confirm critical, settings, and stance select modals instantiate through UIManagerHost and close cleanly.

Evidence:
- `production/qa/evidence/sprint-11/screenshots/modal_confirm_critical.png`
- `production/qa/evidence/sprint-11/screenshots/modal_settings.png`
- `production/qa/evidence/sprint-11/screenshots/modal_stance_select.png`
- `scripts/validate_main_scene_load.gd`

Assets: `res://assets/ui/theme.tres`, `res://assets/ui/frames/panel_elevated.png`.
