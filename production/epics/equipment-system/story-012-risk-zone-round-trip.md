# Story EQUIP-RISK-002: Risk-Zone Round-Trip Tests

> **Epic**: Equipment System
> **Status**: Complete
> **Layer**: Feature
> **Type**: Save/Load Integration
> **Priority**: Should Have
> **Sprint**: Sprint-007
> **TR-ID**: TR-equip-012
> **ADR References**: ADR-003, ADR-009
> **Estimate**: 0.25 day

## Context

**GDD**: `design/gdd/equipment-system.md` C.4, D.4
**Sprint source**: `production/sprints/sprint-007.md` / EQUIP-RISK-002
**QA plan**: `production/qa/qa-plan-sprint-7.md`

Harden save/load around the new risk-zone behavior. This story is a focused QA implementation story and should run after EQUIP-RISK-001.

## Acceptance Criteria

- [x] +6, +8, and +10 enhancement states round-trip through save/load.
- [x] Failed enhancement downgrade persists without negative or impossible levels.
- [x] Protection symbol consumption persists through save/load.
- [x] No failure path leaves partially mutated equipment/resource state.

## QA Test Conditions

- Given a +6 item is saved and loaded, then the enhancement level remains +6.
- Given a +10 item fails and downgrades to +5, when saved and loaded, then level remains +5.
- Given protection is consumed on failure, when saved and loaded, then protection count remains decremented.
- Given a failure occurs during a save boundary, then no item has negative level and resources do not duplicate.

## Test Evidence

**Completed**: `tests/integration/equipment/save_load_integration_test.gd` extension.
**Gate**: PASS

## Dependencies

- Depends on: EQUIP-RISK-001
- Unlocks: Sprint-007 regression hardening closeout

## Next Step

Complete 2026-04-27.
