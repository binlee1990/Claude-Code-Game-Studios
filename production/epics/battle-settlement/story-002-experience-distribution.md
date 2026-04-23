# Story 002: Experience Distribution

> **Epic**: Battle Settlement
> **Status**: Complete
> **Layer**: Feature
> **Type**: Logic
> **Manifest Version**: 2026-04-23-v1

> **Estimate**: 2-3 hours

## Context

**GDD**: `design/gdd/battle-settlement.md`
**Requirement**: AC.2.1, D.1, D.2 (EXP split, evaluation bonus, overflow)

**ADR Governing Implementation**: ADR-001 (Event Architecture)
**Engine**: Godot 4.6.2 | **Risk**: LOW

---

## Acceptance Criteria

- [x] AC.2.1: EXP distributed equally among surviving player units
- [x] AC-E1: Evaluation bonus multiplies final EXP (perfect=×1.5, excellent=×1.2, normal=×1.0)
- [x] AC-E2: EXP overflow carries into next level (consecutive level-ups possible)

---

## Implementation Notes

From GDD D.1: `exp_per_unit = total_exp / surviving_unit_count` (integer division). From D.2: `final_exp = base_exp × (1 + evaluation_bonus)`. Evaluation bonus applied before distribution. Enemy EXP values: normal=50, elite=150, hard=300, boss=1000. From E.4: Overflow carries forward; may trigger consecutive level-ups.

---

## Out of Scope

- Battle evaluation logic (Story 003)
- Gold/material calculation (Story 004)
- Level-up side effects (attribute growth)

---

## QA Test Cases

- **AC.2.1**: EXP distribution
  - Given: Total EXP = 1000, 3 surviving units
  - When: EXP distributed
  - Then: Each unit receives 333 EXP (floor division)
  - Edge cases: 1 survivor → gets all 1000; 4 survivors → 250 each

- **AC-E1**: Evaluation bonus
  - Given: Base EXP per unit = 333, evaluation = perfect (+50%)
  - When: Final EXP calculated
  - Then: 333 × 1.5 = 499 (floor)
  - Edge cases: Normal evaluation → ×1.0, no change

- **AC-E2**: EXP overflow
  - Given: Unit at Lv9 with 900/1000 EXP, receives 500 EXP
  - When: EXP applied
  - Then: Level 10 (1000 reached), overflow 400 applied to Lv10 progression
  - Edge cases: Large overflow triggering 2+ level-ups

---

## Test Evidence

**Story Type**: Logic
**Required evidence**: `tests/unit/settlement/experience_distribution_test.gd`
**Status**: [x] Created 2026-04-23 (18 tests — AC.2.1, AC-E1, AC-E2)

---

## Dependencies

- Depends on: Story 001 (settlement trigger), Story 003 (evaluation bonus input)
- Unlocks: Story 005 (save/load)
