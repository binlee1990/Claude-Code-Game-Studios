# Story EQUIP-RISK-001: Equipment +6 Risk-Zone Enhancement

> **Epic**: Equipment System
> **Status**: Complete
> **Layer**: Feature
> **Type**: Logic + UI + Integration
> **Priority**: Must Have
> **Sprint**: Sprint-007
> **TR-ID**: TR-equip-011
> **ADR References**: ADR-001, ADR-003, ADR-008, ADR-009
> **Estimate**: 0.75 day

## Context

**GDD**: `design/gdd/equipment-system.md` C.4, D.3, D.4, E.2, E.3
**Sprint source**: `production/sprints/sprint-007.md` / EQUIP-RISK-001
**QA plan**: `production/qa/qa-plan-sprint-7.md`

Extend the Sprint-006 safe-zone enhancement UI into the +6 risk zone. This story must consume the GDD success table, apply downgrade/protection rules, and surface risk feedback without adding affix reroll, decomposition UI, or +11 extreme-risk scope.

## Acceptance Criteria

- [x] Enhancement UI exposes +6+ risk-zone entry for eligible equipped items.
- [x] +6 through +10 success rates follow the GDD C.4 table.
- [x] Failure without protection downgrades the item by 5 levels.
- [x] Failure with protection preserves level and consumes one protection symbol.
- [x] UI communicates failure/protection result through localized feedback.
- [x] +11 and above remain out of scope unless explicitly enabled by later stories.

## QA Test Conditions

- Given an equipped item is +5 and resources are sufficient, when +6 is attempted, then the risk-zone path uses the C.4 success rate rather than safe-zone 100%.
- Given a deterministic failure at +8 without protection, when the result resolves, then the item becomes +3.
- Given a deterministic failure at +6 with protection, when the result resolves, then the item remains +5 and protection count decreases by 1.
- Given protection count is 0, when protected enhancement is selected, then it is disabled or explicitly routes to unprotected risk.
- Given a +10 item is tested, when success/failure paths run, then boundaries match GDD D.3/D.4.

## Test Evidence

**Completed**: `tests/unit/equipment/enhancement_test.gd`; `tests/integration/ui/character_management_test.gd`.
**Gate**: PASS

## Dependencies

- Depends on: Sprint-006 EQUIP-ENH-001 through EQUIP-ENH-003
- Unlocks: EQUIP-RISK-002 round-trip hardening

## Next Step

Complete 2026-04-27.
