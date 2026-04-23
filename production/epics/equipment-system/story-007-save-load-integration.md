# Story 007: Equipment Save/Load Integration

> **Epic**: Equipment System
> **Status**: Complete
> **Layer**: Feature
> **Type**: Integration
> **Manifest Version**: 2026-04-23-v1

> **Estimate**: 2-3 hours

## Context

**GDD**: `design/gdd/equipment-system.md`
**Requirement**: Full equipment state persistence

**ADR Governing Implementation**: ADR-001, ADR-003 (Save System)
**Engine**: Godot 4.6.2 | **Risk**: LOW

---

## Acceptance Criteria

- [ ] AC-S1: All equipment data (slot, quality, enhancement, affixes, set_id) saved and restored
- [ ] AC-S2: Equipment loadout (which item in which slot) persisted
- [ ] AC-S3: Set bonus activation state survives round-trip
- [ ] AC-S4: Multiple save/load cycles produce identical equipment state

---

## Implementation Notes

From ADR-003: Equipment stored as array of ItemSaveData entries. Each entry: item_id, slot, quality, enhancement_level, affixes[{type, value}], set_id. Loadout stored as {slot: item_id} map. Set bonus state recalculated on load (derived from loadout, not stored separately).

---

## Out of Scope

- Save UI
- Auto-save triggering

---

## QA Test Cases

- **AC-S1**: Equipment data round-trip
  - Given: Blue weapon with enhancement +8, 3 affixes (STR+15, AGI+10, crit+3%)
  - When: Save → Load
  - Then: All fields match exactly

- **AC-S2**: Loadout persistence
  - Given: Sword in weapon slot, heavy armor in armor slot, ring in accessory
  - When: Save → Load
  - Then: Each slot still has correct item

- **AC-S3**: Set bonus restoration
  - Given: 3 pieces of Warrior's Power equipped (2pc bonus active)
  - When: Save → Load
  - Then: 2-piece bonus still active after recalculation

- **AC-S4**: Double round-trip
  - Given: Full equipment set across all 6 slots
  - When: Save → Load → Save → Load
  - Then: Final state = state after first load

---

## Test Evidence

**Story Type**: Integration
**Required evidence**: `tests/integration/equipment/save_load_integration_test.gd`
**Status**: [x] `tests/integration/equipment/save_load_integration_test.gd` created and passing

---

## Dependencies

- Depends on: Stories 001-006 (all equipment state must be defined before serialization)
