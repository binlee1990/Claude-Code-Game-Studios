# Story 003: Character Save/Load Integration

> **Epic**: Character Management
> **Status**: Ready
> **Layer**: Feature
> **Type**: Integration
> **Manifest Version**: N/A — manifest not yet created

> **Estimate**: 2-3 hours

## Context

**GDD**: `design/gdd/character-management.md`
**Requirement**: Full roster state persistence

**ADR Governing Implementation**: ADR-001, ADR-003 (Save System)
**Engine**: Godot 4.6.2 | **Risk**: LOW

---

## Acceptance Criteria

- [ ] AC-S1: Full roster (available + departed) correctly saved and restored
- [ ] AC-S2: Current party deployment persisted across sessions
- [ ] AC-S3: Multiple save/load cycles produce identical roster state

---

## Implementation Notes

From ADR-003: Roster stored as array of character entries with status (available/deployed/departed). Current party stored as ordered list of character IDs. Departed characters stored with departure_reason for recall quest matching.

---

## Out of Scope

- Save UI
- Auto-save triggering

---

## QA Test Cases

- **AC-S1**: Roster round-trip
  - Given: 4 available, 1 deployed, 1 departed characters
  - When: Save → Load
  - Then: All 6 characters present with correct statuses

- **AC-S2**: Deployment persistence
  - Given: Party = [A, B, C, D]
  - When: Save → Load
  - Then: Party order = [A, B, C, D] exactly

- **AC-S3**: Double round-trip
  - Given: Mixed roster with departed characters
  - When: Save → Load → Save → Load
  - Then: Final state = state after first load

---

## Test Evidence

**Story Type**: Integration
**Required evidence**: `tests/integration/character/save_load_integration_test.gd`
**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: Stories 001-002 (all roster state must be defined before serialization)
