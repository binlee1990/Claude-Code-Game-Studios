# Story 005: Class Stat Bonuses

> **Epic**: Class System
> **Status**: Ready
> **Layer**: Core
> **Type**: Logic
> **Manifest Version**: N/A — manifest not yet created

> **Estimate**: 2-3 hours

## Context

**GDD**: `design/gdd/class-system.md`
**Requirement**: AC.5.1-5.3 (stat bonuses)

**ADR Governing Implementation**: ADR-001: Event Architecture
**Engine**: Godot 4.6.2 | **Risk**: LOW

---

## Acceptance Criteria

- [ ] AC.5.1: `get_class_bonus(character_id)` returns correct stat bonus table for current class; final_attr = base_value + class_bonus + equipment_bonus
- [ ] AC.5.2: After class change, equipment feasibility is flagged for revalidation (emit signal for equipment system)
- [ ] AC.5.3: When current attribute (with class bonus) drops below class threshold, class bonus is temporarily suspended but class state is NOT revoked

---

## Implementation Notes

From GDD C.5: Complete bonus table for all 15 classes (6 basic + 6 advanced + 3 special). Bonuses are flat integer additions to base attributes. Negative bonuses exist (e.g., MAGE CON -5). The calculation order is fixed: base → class_bonus → equipment_bonus.

---

## Out of Scope

- Equipment system's actual revalidation (equipment epic)
- UI display of class bonuses

---

## QA Test Cases

- **AC.5.1**: Bonus table application
  - Given: Character as BASIC_MAGE with base INT=45
  - When: Reading effective INT
  - Then: effective_INT = 45 + 15 (mage INT bonus) = 60
  - Edge cases: Negative bonuses — mage CON = base - 5

- **AC.5.1**: Calculation order
  - Given: Character as BASIC_WARRIOR, base STR=50, class_bonus=+10, equipment_bonus=+5
  - When: Reading effective STR
  - Then: effective_STR = 50 + 10 + 5 = 65

- **AC.5.3**: Bonus suspension below threshold
  - Given: ADVANCED_ACTIVE Swordmaster (requires STR>=50), but STR drops to 48 (equipment removed)
  - When: Reading effective STR
  - Then: Class bonus (+15) is suspended, effective_STR = 48 + 0 = 48; class state remains ADVANCED_ACTIVE

---

## Test Evidence

**Story Type**: Logic
**Required evidence**: `tests/unit/class/stat_bonuses_test.gd` — must exist and pass
**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: Story 001 (state machine — know current class), attribute-system Epic (base values)
- Unlocks: Equipment system can consume class bonus data
