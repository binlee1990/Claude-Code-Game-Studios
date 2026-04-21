# Story 004: Barrier Breakthrough

> **Epic**: Attribute & Growth System
> **Status**: Complete
> **Layer**: Core
> **Type**: Logic
> **Manifest Version**: N/A — manifest not yet created

> **Estimate**: 2-3 hours

## Context

**GDD**: `design/gdd/attribute-growth-system.md`
**Requirement**: AC-7 (breakthrough trigger), AC-8 (breakthrough completion)

**ADR Governing Implementation**: ADR-001: Event Architecture
**ADR Decision Summary**: Barrier state changes should emit events for UI and save system to react.

**Engine**: Godot 4.6.2 | **Risk**: LOW

---

## Acceptance Criteria

- [ ] AC-7.1: When any attribute V reaches barrier threshold (50/100/150) AND barrier not broken, CAN_BREAK returns TRUE
- [ ] AC-7.2: When V < threshold OR barrier already broken, CAN_BREAK returns FALSE
- [ ] AC-8.1: On successful breakthrough, BARRIER_STATE changes to BROKEN for that stage
- [ ] AC-8.2: After breakthrough, growth cap for that stage is removed — V can exceed threshold
- [ ] AC-8.3: Breakthrough is permanent — state persists and cannot be reversed

---

## Implementation Notes

From GDD C.4:
- Barrier thresholds are uniform across all attributes: 50 (stage 1), 100 (stage 2), 150 (stage 3)
- Breakthrough success is 100% (曹操传 mode, deterministic)
- Each attribute tracks its own barrier state per stage independently
- Resource consumption (barrier resource) is managed by resource-economy epic; this story handles the attribute-side state change

---

## Out of Scope

- Resource consumption for breakthrough (resource-economy epic)
- Challenge stage content (game design, not attribute system)
- UI for breakthrough prompt (UI epic)

---

## QA Test Cases

- **AC-7.1**: CAN_BREAK triggers at threshold
  - Given: Character with STR V=50, barrier stage 1 not broken
  - When: Checking CAN_BREAK
  - Then: Returns TRUE
  - Edge cases: V=49 → FALSE; V=50 → TRUE; V=51 with barrier broken → FALSE (already broken)

- **AC-7.2**: CAN_BREAK false when conditions not met
  - Given: Character with STR V=48, barrier stage 1 not broken
  - When: Checking CAN_BREAK
  - Then: Returns FALSE
  - Edge cases: V=100 with only stage 1 broken → FALSE (stage 2 not triggerable at V=100 only if stage 2 threshold met)

- **AC-8.1**: Breakthrough changes state
  - Given: Character with STR V=50, barrier stage 1 UNBROKEN
  - When: Breakthrough is executed
  - Then: Barrier state for STR stage 1 = BROKEN

- **AC-8.2**: Growth cap removed after breakthrough
  - Given: STR barrier stage 1 just broken, V=50, P=S(6)
  - When: apply_level_up_growth called
  - Then: V becomes 56 (no stage 1 cap)

- **AC-8.3**: Breakthrough is permanent
  - Given: STR barrier stage 1 = BROKEN
  - When: Any subsequent operations
  - Then: State remains BROKEN, cannot revert to UNBROKEN

---

## Test Evidence

**Story Type**: Logic
**Required evidence**: `tests/unit/attributes/barrier_breakthrough_test.gd` — must exist and pass
**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: Story 001 (data model), Story 002 (growth formula — barrier cap interaction)
- Unlocks: None (barrier breakthrough is self-contained within attribute system)

## Completion Notes

**Completed**: 2026-04-22
**Criteria**: 5/5 passing (all auto-verified)
**Deviations**: None
**Test Evidence**: Logic — `tests/unit/attributes/barrier_breakthrough_test.gd` (12 test functions)
**Code Review**: Skipped (Solo mode)
