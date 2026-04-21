# Story 006: Resource Save/Load Integration

> **Epic**: Resource Economy
> **Status**: Ready
> **Layer**: Core
> **Type**: Integration
> **Manifest Version**: N/A — manifest not yet created

> **Estimate**: 2-3 hours

## Context

**GDD**: `design/gdd/resource-economy.md`
**Requirement**: Full resource state persistence

**ADR Governing Implementation**: ADR-001, ADR-003 (Save System)
**Engine**: Godot 4.6.2 | **Risk**: LOW

---

## Acceptance Criteria

- [ ] AC-S1: All囤积 resources (gold, materials, fruits, rare materials, protection symbols, barrier resources) correctly saved and restored
- [ ] AC-S2: Achievement points correctly persisted across sessions
- [ ] AC-S3: Stack limit state preserved (no post-load overflow)
- [ ] AC-S4: Multiple save/load cycles produce identical resource state

---

## Implementation Notes

From ADR-003: Resource data stored in ItemSaveData array within SaveData. Each entry has item_id, quantity, enchantments. Achievement points stored as top-level field on SaveData.

---

## Out of Scope

- Save UI
- Auto-save triggering

---

## QA Test Cases

- **AC-S1**: Full inventory round-trip
  - Given: gold=5000, basic_materials=300, STR_fruits=5, rare_materials=10, protect_symbols=2, barrier_resources=1
  - When: Save → Load
  - Then: All values match exactly

- **AC-S2**: Achievement points round-trip
  - Given: achievement_points=3500
  - When: Save → Load
  - Then: achievement_points=3500

- **AC-S4**: Double round-trip integrity
  - Given: Complex inventory state
  - When: Save → Load → Save → Load
  - Then: Final state = state after first load

---

## Test Evidence

**Story Type**: Integration
**Required evidence**: `tests/integration/resource/save_load_integration_test.gd`
**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: Stories 001-005 (all resource state must be defined before serialization)
