# Story 007: Turn-Based Save/Load Integration

> **Epic**: Turn-Based Mode
> **Status**: Ready
> **Layer**: Core
> **Type**: Integration
> **Manifest Version**: N/A — manifest not yet created

> **Estimate**: 2-3 hours

## Context

**GDD**: `design/gdd/turn-based-mode.md`
**Requirement**: Full turn-based state persistence

**ADR Governing Implementation**: ADR-001, ADR-003 (Save System)
**Engine**: Godot 4.6.2 | **Risk**: LOW

---

## Acceptance Criteria

- [ ] AC-S1: Turn order and current turn index correctly saved and restored
- [ ] AC-S2: All unit states (HP, MP, position, acted status) persisted mid-battle
- [ ] AC-S3: Auto-battle and speed-up mode settings survive round-trip
- [ ] AC-S4: Multiple save/load cycles produce identical battle state

---

## Implementation Notes

From ADR-003: Battle state stored per encounter. Includes: turn_order[], current_turn_index, unit_states[{id, hp, mp, position, acted, cooldowns}], auto_battle_enabled, speed_tier. Loading restores the exact mid-battle state, resuming from where the save occurred.

---

## Out of Scope

- Save UI
- Auto-save triggering
- Battle scene recreation (ADR-002)

---

## QA Test Cases

- **AC-S1**: Turn order round-trip
  - Given: Turn order [Unit_A, Unit_B, Unit_C], current index = 1 (Unit_B acting)
  - When: Save → Load
  - Then: Same order, same current index = 1

- **AC-S2**: Unit state persistence
  - Given: Unit_A (HP=80, MP=30, pos=(3,4), acted=false), Unit_B (HP=0, dead)
  - When: Save → Load
  - Then: All unit states match exactly

- **AC-S3**: Mode settings
  - Given: Auto-battle ON, speed = 2×
  - When: Save → Load
  - Then: Auto-battle still ON, speed still 2×

- **AC-S4**: Double round-trip
  - Given: Mid-battle state with 4 units
  - When: Save → Load → Save → Load
  - Then: Final state = state after first load

---

## Test Evidence

**Story Type**: Integration
**Required evidence**: `tests/integration/turn/save_load_integration_test.gd`
**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: Stories 001-006 (all turn-based state must be defined before serialization)
