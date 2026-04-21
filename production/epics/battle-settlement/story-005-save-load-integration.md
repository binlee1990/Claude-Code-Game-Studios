# Story 005: Settlement Save/Load Integration

> **Epic**: Battle Settlement
> **Status**: Ready
> **Layer**: Feature
> **Type**: Integration
> **Manifest Version**: N/A — manifest not yet created

> **Estimate**: 2-3 hours

## Context

**GDD**: `design/gdd/battle-settlement.md`
**Requirement**: Settlement state persistence

**ADR Governing Implementation**: ADR-001, ADR-003 (Save System)
**Engine**: Godot 4.6.2 | **Risk**: LOW

---

## Acceptance Criteria

- [ ] AC-S1: Post-settlement state (new EXP, new resources, new items) correctly saved
- [ ] AC-S2: Battle history (wins, losses, evaluations) persisted for achievement tracking
- [ ] AC-S3: Multiple save/load cycles produce identical post-settlement state

---

## Implementation Notes

From ADR-003: Settlement results written to save data immediately after reward distribution. Includes: updated unit EXP/levels, new resource quantities, new equipment acquired. Battle history stored as append-only log with battle_id, result, evaluation, rewards.

---

## Out of Scope

- Save UI
- Auto-save triggering

---

## QA Test Cases

- **AC-S1**: Post-settlement state
  - Given: Victory settlement granted 333 EXP, 170 gold, 1 equipment
  - When: Save → Load
  - Then: Unit EXP increased by 333, gold increased by 170, equipment in inventory

- **AC-S2**: Battle history
  - Given: 5 battles fought (3 victory, 1 defeat, 1 retreat)
  - When: Save → Load
  - Then: Battle history log contains 5 entries with correct results and evaluations

- **AC-S3**: Double round-trip
  - Given: Post-settlement state with multiple unit level-ups
  - When: Save → Load → Save → Load
  - Then: Final state = state after first load

---

## Test Evidence

**Story Type**: Integration
**Required evidence**: `tests/integration/settlement/save_load_integration_test.gd`
**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: Stories 001-004 (all settlement data must be defined before serialization)
