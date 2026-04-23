# Story 006: Final Attribute Calculation

> **Epic**: Equipment System
> **Status**: Complete
> **Layer**: Feature
> **Type**: Logic
> **Manifest Version**: 2026-04-23-v1

> **Estimate**: 2-3 hours

## Context

**GDD**: `design/gdd/equipment-system.md`
**Requirement**: D.1 (base + class + equipment + barrier bonuses)

**ADR Governing Implementation**: ADR-001 (Event Architecture)
**Engine**: Godot 4.6.2 | **Risk**: LOW

---

## Acceptance Criteria

- [ ] AC-F1: final_attribute = base_value + class_bonus + equipment_bonus + barrier_bonus
- [ ] AC-F2: Equipment bonus = sum of all affix values from equipped items + set bonus values
- [ ] AC-F3: Attribute recalculation triggered on equip/unequip events

---

## Implementation Notes

From GDD D.1: `final_attribute = base_value + class_bonus + equipment_bonus + barrier_bonus`. Equipment bonus sums all affix values across all 6 equipped items plus active set bonuses. Recalculation must trigger whenever equipment changes.

---

## Out of Scope

- Base value calculation (attribute-system epic)
- Class bonus calculation (class-system epic)
- Barrier bonus calculation (attribute-system epic)

---

## QA Test Cases

- **AC-F1**: Full formula
  - Given: base=100, class_bonus=15, equipment_affix_total=30, barrier_bonus=10
  - When: Final attribute calculated
  - Then: 100 + 15 + 30 + 10 = 155

- **AC-F2**: Equipment bonus aggregation
  - Given: Weapon affix STR+8, Armor affix STR+5, set bonus STR+10
  - When: STR equipment bonus calculated
  - Then: 8 + 5 + 10 = 23
  - Edge cases: Unequipping weapon → bonus drops to 5 + 10 = 15

- **AC-F3**: Recalculation trigger
  - Given: Character with final STR=155
  - When: Weapon with STR+8 unequipped
  - Then: Final STR immediately recalculated to 147

---

## Test Evidence

**Story Type**: Logic
**Required evidence**: `tests/unit/equipment/final_attribute_test.gd`
**Status**: [x] `tests/unit/equipment/final_attribute_test.gd` created and passing

---

## Dependencies

- Depends on: Stories 001-004 (equipment model, affixes, set bonuses)
- Cross-epic: Attribute System (base_value), Class System (class_bonus), Attribute System (barrier_bonus)
