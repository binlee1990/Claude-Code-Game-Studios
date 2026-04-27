# Story ECON-CFG-001: Base Upgrade Cost Config

> **Title**: Base upgrade cost data table
> **Epic**: Resource Economy
> **Layer**: Core
> **Priority**: Should Have
> **Status**: Complete
> **Sprint**: Sprint-006
> **Type**: Config/Data + Documentation
> **TR-ID**: TR-resource-007
> **ADR References**: ADR-003, ADR-008
> **Review Mode**: solo — QL-STORY-READY skipped
> **Estimate**: 0.5 day

## Context

**GDD**: `design/gdd/base-system.md` F1, `design/gdd/resource-economy.md` base upgrade integration notes  
**Sprint source**: `production/sprints/sprint-006.md` / ECON-CFG-001  
**QA plan**: `production/qa/qa-plan-sprint-6.md`

Sprint-006 does not implement Base Upgrade UI, but it needs a data-owned cost table so Sprint-007+ can consume base upgrade values without hardcoding prices in UI code.

## Acceptance Criteria

- [x] A base upgrade cost data file exists at `assets/data/economy/base-upgrade-costs.json`.
- [x] Data covers Lv1->Lv2 through Lv4->Lv5 upgrade costs from `design/gdd/base-system.md`.
- [x] Schema separates gold, basic material, and rare material requirements.
- [x] The file is parseable by Godot or by a lightweight config smoke check.
- [x] No Base Upgrade UI or purchase mutation flow is implemented.

## Definition of Done

- [x] Config file exists and is referenced from this story's completion notes.
- [x] Config smoke or parse check passes.
- [x] ADR-008 data-driven price ownership remains intact.
- [x] Future Base Upgrade UI handoff names the data path.

## Implementation Notes

- Prefer JSON if `.tres` authoring would require editor-only manual setup.
- Keep values aligned with `design/gdd/base-system.md` F1 unless the GDD is revised first.
- Do not add runtime upgrade UI or payment logic in this story.

## Test Evidence

**Required**: config parse/smoke evidence and `godot --headless --check-only project.godot`  
**Gate**: ADVISORY

## Dependencies

- Depends on: ADR-008, `design/gdd/base-system.md`, resource-economy config ownership
- Unlocks: Sprint-007+ Base Upgrade UI and economy tuning

## Next Step

Run `/story-readiness production/epics/resource-economy/story-007-base-upgrade-cost-config.md` before authoring the config file.

## Completion Notes

Completed 2026-04-27 in Sprint-006. Evidence: src/, 	ests/, production/qa/qa-plan-sprint-6.md, production/sprints/sprint-006.md, and packaged smoke PACKAGED_PLAYTHROUGH_SMOKE PASS with Bond/Base/Equipment coverage.

