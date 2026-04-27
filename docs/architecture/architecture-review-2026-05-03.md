# Architecture Review - Sprint-007 Full Mode

| Field | Value |
|---|---|
| Review target | Sprint-007 full-mode closeout |
| Executed | 2026-04-27 |
| Sprint filename target | 2026-05-03 |
| Engine | Godot 4.6.2 |
| Verdict | PASS |

## Scope

Reviewed the Sprint-007 implementation against the active GDD/ADR set used by the sprint:

- Chapter 3 battle 1 route and data shape
- Bond Tavern MVP
- Base Tavern and Base Upgrade UI
- Equipment +6 through +10 risk-zone behavior
- ADR-001 follow-up signal registration
- ADR-008/ADR-009 resource and equipment constraints
- Sprint-005 review follow-ups F-1/F-2/F-3

## Findings

No blocking architecture gaps remain for Sprint-007 closure.

| ID | Finding | Resolution |
|---|---|---|
| F-1 | `equipment_enhanced(item_id, level, success)` existed in `GameEvents.gd` but was not recorded in ADR-001 | Added to ADR-001 signal list |
| F-2 | Equipment risk-zone UI needed AccessKit/keyboard-friendly acceptance coverage | Added to Sprint-007 QA plan and verified through UI button/focus-accessible paths |
| F-3 | `architecture.md` top-level event list was stale | Updated architecture document version and equipment signal list |

## Compatibility Notes

- No new dependencies were introduced.
- Base Upgrade consumes the existing `assets/data/economy/base-upgrade-costs.json` data table instead of hardcoding upgrade costs in UI.
- Chapter 3 battle data stays on the existing `src/ui/combat/battle_definitions/*.json` schema to avoid parallel routing infrastructure.
- B3-GATE is represented only as placeholder/progress fields; no runtime branch system was added.
- Equipment UI is intentionally capped at +10 for Sprint-007; +11+ extreme-risk scope remains deferred.

## Verification Evidence

- `godot --headless --check-only project.godot`: PASS
- GUT runner: 849 total, 849 pass, 0 fail
- Windows export: `builds/windows/SRPG.exe`
- Packaged smoke: PASS with `chapter3_battle=chapter_03_act_a`, `tavern_affinity=25`, `risk_enhanced_level=7`

## Residual Risks

- Manual screenshot/playtest evidence remains in `production/sprints/sprint-人工.md` and is not a Sprint-007 release blocker.
- Chapter 3 battle 2/3, B3-GATE runtime branching, Bond linked skills, and +11+ equipment scope remain Sprint-008+ candidates.
