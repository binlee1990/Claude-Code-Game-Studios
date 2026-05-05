# HUD Real Layout Epic

Status: Done on 2026-05-05 via Sprint 11 completion pass.

## Scope

Replace the temporary HUD skeleton with a production shell: top strip, left nav, right panel, status indicators, resource warning states, and progressive unlock placeholders.

## Stories

| Story | Status | Evidence |
|-------|--------|----------|
| S11-004-hud-real-layout | Done | `screenshots/cultivation.png`, `screenshots/combat.png` |
| S11-005-hud-real-layout | Done | Top strip reserves status/icon positions and subscribes unlock/state events |
| S11-006-hud-real-layout | Done | Overflow status icon and warning toast/drawer evidence |

## Verification

- Visual smoke generated 12 screenshots under `production/qa/evidence/sprint-11/screenshots/`.
- Asset coverage: `production/qa/evidence/sprint-11/asset-coverage-report.json` (108/108).
