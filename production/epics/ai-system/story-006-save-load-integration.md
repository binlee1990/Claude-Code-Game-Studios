# Story 006: AI Save/Load Integration

> **Epic**: AI System
> **Status**: Ready
> **Layer**: Core
> **Type**: Integration
> **Manifest Version**: N/A — manifest not yet created

> **Estimate**: 2-3 hours

## Context

**GDD**: `design/gdd/ai-system.md`
**Requirement**: Full AI state persistence

**ADR Governing Implementation**: ADR-001, ADR-003 (Save System)
**Engine**: Godot 4.6.2 | **Risk**: LOW

---

## Acceptance Criteria

- [ ] AC-S1: Threat/hate tables correctly saved and restored
- [ ] AC-S2: AI type configuration and current behavior mode persisted
- [ ] AC-S3: Boss phase state (current phase, enrage active) survives round-trip
- [ ] AC-S4: Multiple save/load cycles produce identical AI state

---

## Implementation Notes

From ADR-003: AI state stored per unit in save data. Each AI unit persists: AI type, current threat table, boss phase (if applicable), skill cooldowns. Threat tables are serialized as {target_id: threat_value} maps.

---

## Out of Scope

- Save UI
- Auto-save triggering

---

## QA Test Cases

- **AC-S1**: Threat table round-trip
  - Given: Three enemies with threat values {A: 15.0, B: 8.0, C: 3.0}
  - When: Save → Load
  - Then: All threat values match exactly

- **AC-S2**: AI type persistence
  - Given: Aggressive AI, defensive AI, support AI units on field
  - When: Save → Load
  - Then: Each unit's AI type and decision weights restored correctly

- **AC-S3**: Boss state persistence
  - Given: Boss at 50% HP, enrage active, phase 2 skills unlocked
  - When: Save → Load
  - Then: Boss phase=2, enrage=true, unlocked skills list intact
  - Edge cases: Boss at 90% HP → phase=1, enrage=false

- **AC-S4**: Double round-trip
  - Given: Complex AI state with mixed units and boss
  - When: Save → Load → Save → Load
  - Then: Final state = state after first load

---

## Test Evidence

**Story Type**: Integration
**Required evidence**: `tests/integration/ai/save_load_integration_test.gd`
**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: Stories 001-005 (all AI state must be defined before serialization)
