# Story 002: Per-Level Growth Formula

> **Epic**: Attribute & Growth System
> **Status**: Ready
> **Layer**: Core
> **Type**: Logic
> **Manifest Version**: N/A — manifest not yet created

> **Estimate**: 2-3 hours

## Context

**GDD**: `design/gdd/attribute-growth-system.md`
**Requirement**: AC-2 (growth formula), AC-3 (barrier cap), AC-14 (hard cap 999)

**ADR Governing Implementation**: ADR-001: Event Architecture
**ADR Decision Summary**: Attribute changes emit `attribute_changed` signal via GameEvents.

**Engine**: Godot 4.6.2 | **Risk**: LOW

---

## Acceptance Criteria

- [ ] AC-2.1: `apply_level_up_growth(character_id)` correctly calculates V_new = V_old + P_current for all 9 attributes
- [ ] AC-3.1: Before barrier breakthrough, V_new = min(V_old + P, BARRIER_LIMIT). Excess discarded silently.
- [ ] AC-3.2: After barrier breakthrough, V_new = min(V_old + P, 999)
- [ ] AC-14.1: V_new never exceeds 999. Excess growth discarded silently.

---

## Implementation Notes

From ADR-001:
- Emit `attribute_changed` for each attribute that actually changes during level-up
- Growth is deterministic — no RNG (per GDD C.2: "第一周目确定成长，无RNG")

From GDD Formulas:
- D.1: V_new = V_old + P_current
- Barrier limits: Stage 1=50, Stage 2=100, Stage 3=150
- 999 hard cap applies after barrier cap check

---

## Out of Scope

- Story 004: Barrier breakthrough state transitions (this story only checks current barrier state)
- Story 007: Save/load persistence of growth state

---

## QA Test Cases

- **AC-2.1**: Basic growth formula
  - Given: Character with STR V=48, P=C(3), barrier 1 broken
  - When: apply_level_up_growth is called
  - Then: STR V becomes 51
  - Edge cases: P=E(1) gives minimum growth; P=S(6) gives maximum growth

- **AC-3.1**: Growth capped by barrier
  - Given: Character with STR V=48, P=S(6), barrier 1 NOT broken (limit=50)
  - When: apply_level_up_growth is called
  - Then: STR V becomes 50 (48+6=54, capped at 50), 4 points discarded
  - Edge cases: V already at barrier limit (50+1=50, no growth)

- **AC-3.2**: Growth after barrier breakthrough
  - Given: Character with STR V=50, P=S(6), barrier 1 broken
  - When: apply_level_up_growth is called
  - Then: STR V becomes 56 (no cap except 999)

- **AC-14.1**: Hard cap at 999
  - Given: Character with INT V=997, P=S(6)
  - When: apply_level_up_growth is called
  - Then: INT V becomes 999, excess (+4) discarded
  - Edge cases: V already at 999 — no change

---

## Test Evidence

**Story Type**: Logic
**Required evidence**: `tests/unit/attributes/growth_formula_test.gd` — must exist and pass
**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: Story 001 (data model must exist)
- Unlocks: Story 004 (barrier breakthrough affects growth cap)
