# Story 004: Set Bonus System

> **Epic**: Equipment System
> **Status**: Ready
> **Layer**: Feature
> **Type**: Logic
> **Manifest Version**: N/A — manifest not yet created

> **Estimate**: 2-3 hours

## Context

**GDD**: `design/gdd/equipment-system.md`
**Requirement**: AC.3.1-3.3 (2pc/4pc activation, cross-set stacking)

**ADR Governing Implementation**: ADR-001 (Event Architecture)
**Engine**: Godot 4.6.2 | **Risk**: LOW

---

## Acceptance Criteria

- [ ] AC.3.1: Equipping 2 pieces of same set activates 2-piece bonus
- [ ] AC.3.2: Equipping 4 pieces of same set activates 4-piece bonus
- [ ] AC.3.3: Different set bonuses stack independently

---

## Implementation Notes

From GDD C.5: 4 sets defined — Warrior's Power (STR+10, HP+100 / 20% double damage), Mage's Wisdom (INT+10, MP+50 / skill damage +15%), Archer's Precision (AGI+10, crit+5% / crit damage +30%), Knight's Glory (CON+10, def+20 / 10% reflect). From E.4: Same set bonus does NOT stack (one 4pc effect only). Different set bonuses DO stack. Bonus activation is automatic on equip/unequip.

---

## Out of Scope

- Set bonus UI display
- Set collection tracking

---

## QA Test Cases

- **AC.3.1**: 2-piece activation
  - Given: Equipping 2nd piece of Warrior's Power set
  - When: Equipment slot updated
  - Then: 2-piece bonus activates: STR+10, HP+100
  - Edge cases: Unequipping 1 piece → bonus deactivates

- **AC.3.2**: 4-piece activation
  - Given: Equipping 4th piece of Mage's Wisdom set
  - When: Equipment slot updated
  - Then: 4-piece bonus activates: skill damage +15%
  - Edge cases: Equipping only 3 pieces → only 2-piece bonus active

- **AC.3.3**: Cross-set stacking
  - Given: 2 pieces of Warrior's Power + 2 pieces of Archer's Precision
  - When: Bonuses calculated
  - Then: Both 2-piece bonuses active simultaneously
  - Edge cases: 4 of one set + 2 of another → both bonuses active

---

## Test Evidence

**Story Type**: Logic
**Required evidence**: `tests/unit/equipment/set_bonus_test.gd`
**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: Story 001 (equipment data model with set_id)
- Unlocks: Story 006 (set bonuses feed into attribute calculation)
