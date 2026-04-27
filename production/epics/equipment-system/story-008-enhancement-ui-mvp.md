# Story EQUIP-ENH-001: Equipment Enhancement UI MVP

> **Title**: Equipment enhancement UI for equipped items
> **Epic**: Equipment System
> **Layer**: Feature
> **Priority**: Must Have
> **Status**: Complete
> **Sprint**: Sprint-006
> **Type**: UI + Integration
> **TR-ID**: TR-equip-008
> **ADR References**: ADR-001, ADR-002, ADR-003, ADR-008, ADR-009
> **Review Mode**: solo — QL-STORY-READY skipped
> **Estimate**: 0.75 day

## Context

**GDD**: `design/gdd/equipment-system.md`, `design/gdd/resource-economy.md`  
**Sprint source**: `production/sprints/sprint-006.md` / EQUIP-ENH-001  
**QA plan**: `production/qa/qa-plan-sprint-6.md`

The equipment system already has enhancement logic, but players cannot access it from the management UI. Sprint-006 exposes a narrow Enhancement MVP for currently equipped items only, using existing character/equipment management surfaces and existing save/resource systems.

## Acceptance Criteria

- [x] Character management Equipment tab allows selecting an equipped item and opening an enhancement panel.
- [x] Panel shows current enhancement level, target level, success/safe-zone state, gold cost, and material cost.
- [x] +1 through +5 safe-zone enhancement is available and deterministic.
- [x] Successful enhancement immediately updates the equipped item and final displayed stats.
- [x] Enhanced item state writes back through existing SaveData/equipment persistence.
- [x] UI remains keyboard navigable and does not bypass the existing tab structure.

## Definition of Done

- [x] Integration test covers an equipped item enhanced from +0 to at least +1.
- [x] Automated coverage includes the +1 to +5 safe-zone path or a deterministic representative path with boundary assertions.
- [x] Existing equipment save/load tests remain green.
- [x] No affix reroll, decomposition UI, set crafting, sockets, or +6 risk-zone flow is implemented.
- [x] Evidence is linked before `/story-done`.

## Implementation Notes

- Reuse existing enhancement logic; do not reimplement formula tables in UI code.
- Enhancement UI should read costs from the resource/economy layer defined by EQUIP-ENH-002.
- Follow ADR-002: UI nodes must not own gameplay state.
- Respect ADR-009 first-slice constraint: equipped items only.

## Test Evidence

**Required / completed**: `tests/integration/ui/character_management_test.gd` and packaged smoke +5 path
**Supporting**: existing `tests/unit/equipment/enhancement_test.gd`, `tests/integration/equipment/save_load_integration_test.gd`  
**Gate**: BLOCKING for functional integration, ADVISORY for screenshots

## Dependencies

- Depends on: equipment-system stories 001/003/006/007, ADR-008, ADR-009, Sprint-004 management UI
- Unlocks: EQUIP-ENH-002, EQUIP-ENH-003, Sprint-006 end-to-end cultivation loop

## Next Step

Run `/story-readiness production/epics/equipment-system/story-008-enhancement-ui-mvp.md`, then `/dev-story` if READY.

## Completion Notes

Completed 2026-04-27 in Sprint-006. Evidence: src/, 	ests/, production/qa/qa-plan-sprint-6.md, production/sprints/sprint-006.md, and packaged smoke PACKAGED_PLAYTHROUGH_SMOKE PASS with Bond/Base/Equipment coverage.

