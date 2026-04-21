# Story 005: Tactical Save/Load Integration

> **Epic**: Tactical Mechanism
> **Status**: Complete
> **Layer**: Core
> **Type**: Integration
> **Manifest Version**: N/A — manifest not yet created

> **Estimate**: 2-3 hours

## Context

**GDD**: `design/gdd/tactical-mechanism.md`
**Requirement**: Full tactical state persistence

**ADR Governing Implementation**: ADR-001, ADR-003 (Save System)
**Engine**: Godot 4.6.2 | **Risk**: LOW

---

## Acceptance Criteria

- [ ] AC-S1: All terrain states (type, height, element status, burn duration) correctly saved and restored
- [ ] AC-S2: Active elemental effects (burning areas, mud zones, chain targets) persisted
- [ ] AC-S3: Multiple save/load cycles produce identical tactical state
- [ ] AC-S4: Weapon triangle state and height modifier configurations survive round-trip

---

## Implementation Notes

From ADR-003: Tactical grid data stored in save system. Each cell's terrain type, height, and element interaction state must be serializable. Active effects (burn timers, mud timers) are stored as part of the battlefield state.

---

## Out of Scope

- Save UI
- Auto-save triggering

---

## QA Test Cases

- **AC-S1**: Terrain round-trip
  - Given: Battlefield with normal(1), highland(2), sand, oil(burning), water puddle, obstacle cells
  - When: Save → Load
  - Then: All terrain types, heights, and element states match exactly

- **AC-S2**: Active effects persistence
  - Given: 3×3 burn area with 1 turn remaining, mud zone with AGI-50% active
  - When: Save → Load
  - Then: Burn area 3×3 with timer=1, mud zone with timer intact

- **AC-S3**: Double round-trip integrity
  - Given: Complex battlefield state with mixed terrain and active effects
  - When: Save → Load → Save → Load
  - Then: Final state = state after first load

---

## Test Evidence

**Story Type**: Integration
**Required evidence**: `tests/integration/tactical/save_load_integration_test.gd`
**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: Stories 001-004 (all tactical state must be defined before serialization)
