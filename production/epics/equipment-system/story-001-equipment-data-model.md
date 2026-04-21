# Story 001: Equipment Data Model

> **Epic**: Equipment System
> **Status**: Ready
> **Layer**: Feature
> **Type**: Logic
> **Manifest Version**: N/A — manifest not yet created

> **Estimate**: 2-3 hours

## Context

**GDD**: `design/gdd/equipment-system.md`
**Requirement**: AC.1.1-1.3 (6 slots, quality tiers, base attributes)

**ADR Governing Implementation**: ADR-001 (Event Architecture)
**Engine**: Godot 4.6.2 | **Risk**: LOW

---

## Acceptance Criteria

- [ ] AC.1.1: Equipment has 6 slots (weapon, armor, helmet, legs, boots, accessory); only 1 item per slot
- [ ] AC.1.2: Quality tier determines affix count: White=1, Green=2, Blue=3, Purple=4, Gold=4+set
- [ ] AC.1.3: Base attributes correctly generated based on quality tier

---

## Implementation Notes

From GDD C.1: 6 equipment slots — weapon (sword/spear/axe/bow/staff/fist), armor (light/medium/heavy), helmet, legs, boots, accessory (ring/necklace/charm). From C.2: 5 quality tiers with color coding, affix counts, base attribute ranges, and enhancement caps (White +5, Green +10, Blue +15, Purple +20, Gold +25). Each equipment instance stores: id, name, slot, quality, enhancement_level, affixes[], set_id (if applicable).

---

## Out of Scope

- Affix generation logic (Story 002)
- Enhancement mechanics (Story 003)
- Set bonus calculation (Story 004)

---

## QA Test Cases

- **AC.1.1**: Slot constraint
  - Given: Character with weapon slot occupied
  - When: Equipping another weapon
  - Then: Old weapon unequipped, new weapon equipped
  - Edge cases: Accessory slot separate from weapon; 6 independent slots

- **AC.1.2**: Quality-affix mapping
  - Given: White quality equipment
  - When: Affix count queried
  - Then: Returns 1
  - Edge cases: Gold = 4 affixes + set_id assigned

- **AC.1.3**: Quality-base attribute
  - Given: Blue quality weapon
  - When: Base attribute generated
  - Then: Value in "high" range per quality tier table
  - Edge cases: Gold = "extremely high" range

---

## Test Evidence

**Story Type**: Logic
**Required evidence**: `tests/unit/equipment/equipment_data_model_test.gd`
**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: None (foundational story)
- Unlocks: Stories 002-007
