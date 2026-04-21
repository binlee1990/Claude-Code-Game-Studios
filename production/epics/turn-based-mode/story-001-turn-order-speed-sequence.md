# Story 001: Turn Order & Speed Sequence

> **Epic**: Turn-Based Mode
> **Status**: Ready
> **Layer**: Core
> **Type**: Logic
> **Manifest Version**: N/A — manifest not yet created

> **Estimate**: 2-3 hours

## Context

**GDD**: `design/gdd/turn-based-mode.md`
**Requirement**: AC.1.1-1.2 (speed-sequence ordering, tie-breaking)

**ADR Governing Implementation**: ADR-001 (Event Architecture)
**Engine**: Godot 4.6.2 | **Risk**: LOW

---

## Acceptance Criteria

- [ ] AC.1.1: All units sorted by AGI value descending (highest AGI acts first)
- [ ] AC.1.2: Same AGI units randomized in order (fair tie-breaking)
- [ ] AC.1.3: After all units act, turn order re-sorted for next round

---

## Implementation Notes

From GDD C.1: `turn_order = units.sort_by(agi_value, descending)`. Same AGI → random order. Each unit gets 1 action per round. After all units act, re-sort for next round. From E.1: Multiple units with identical AGI → each round re-randomizes ties (not fixed across rounds).

---

## Out of Scope

- Action execution (Story 002)
- Movement (Story 003)
- Visual action order bar (UI)

---

## QA Test Cases

- **AC.1.1**: AGI-based sorting
  - Given: 4 units with AGI {100, 80, 60, 40}
  - When: Turn order generated
  - Then: Order = [100, 80, 60, 40]
  - Edge cases: Single unit → order = [that unit]

- **AC.1.2**: Same AGI tie-breaking
  - Given: 3 units all with AGI 80
  - When: Turn order generated
  - Then: All 3 in random order; re-generating produces different order sometimes
  - Edge cases: 2 units same AGI → 50/50 chance each order; verify fairness over 1000 runs

---

## Test Evidence

**Story Type**: Logic
**Required evidence**: `tests/unit/turn/turn_order_test.gd`
**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: None (foundational story)
- Unlocks: Stories 002-007 (all turn-based stories consume turn order)
