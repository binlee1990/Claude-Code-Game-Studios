# Story 002: Class Unlock Judgment (CAN_UNLOCK)

> **Epic**: Class System
> **Status**: Complete
> **Layer**: Core
> **Type**: Logic
> **Manifest Version**: N/A — manifest not yet created

> **Estimate**: 2-3 hours

## Context

**GDD**: `design/gdd/class-system.md`
**Requirement**: AC.2.1-2.4 (unlock formula)

**ADR Governing Implementation**: ADR-001: Event Architecture
**Engine**: Godot 4.6.2 | **Risk**: LOW

---

## Acceptance Criteria

- [ ] AC.2.1: CAN_UNLOCK returns TRUE when: primary_attr >= threshold AND secondary_attr >= threshold AND class_exp >= experience_required
- [ ] AC.2.2: Basic classes always return TRUE (default unlock, no conditions)
- [ ] AC.2.3: Special classes additionally check: achievement_points >= SPC_COST (2000 or 3000)
- [ ] AC.2.4: When CAN_UNLOCK returns FALSE, provides specific reason (which condition failed)

---

## Implementation Notes

From GDD D.1: Formula is `CAN_UNLOCK = (V_pa >= θ_p) AND (V_sa >= θ_s) AND (E_c >= E_req)`. Uses attribute system's `get_attribute_value()` interface. Class thresholds stored in config data, not hardcoded.

Advanced class thresholds: θ_p=50, θ_s=40, E_req=500. Special class costs: 2000 or 3000 achievement points.

---

## Out of Scope

- Story 004: Executing the class change (this story only evaluates eligibility)
- UI display of progress bars

---

## QA Test Cases

- **AC.2.1**: Three-condition AND logic
  - Given: Character STR=52, AGI=45, class_exp=600
  - When: CAN_UNLOCK(ADV_SWORDMASTER) checked
  - Then: Returns TRUE (STR>=50 ✓, AGI>=40 ✓, exp>=500 ✓)
  - Edge cases: STR=50 exactly → TRUE; STR=49 → FALSE with reason "STR needs 1 more"

- **AC.2.1**: Partial failure
  - Given: Character INT=48, STR=42, class_exp=500
  - When: CAN_UNLOCK(ADV_BATTLEMAGE) checked
  - Then: Returns FALSE, reason = "INT needs 2 more"
  - Edge cases: Two conditions failing — report all failures

- **AC.2.2**: Basic class always TRUE
  - Given: Any character, any state
  - When: CAN_UNLOCK(BASIC_WARRIOR) checked
  - Then: Returns TRUE regardless of attributes or experience

- **AC.2.3**: Special class achievement check
  - Given: Character meeting attribute/exp conditions with achievement_points=1500
  - When: CAN_UNLOCK(SPC_DRAGONKNIGHT) checked
  - Then: Returns FALSE, reason = "Achievement points insufficient (1500/2000)"

---

## Test Evidence

**Story Type**: Logic
**Required evidence**: `tests/unit/class/unlock_judgment_test.gd` — must exist and pass
**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: Story 001 (state machine), attribute-system Epic (reads attribute values)
- Unlocks: Story 004 (class change uses CAN_UNLOCK validation)
