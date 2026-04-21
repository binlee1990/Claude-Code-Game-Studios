# Story 002: Proficiency & Leveling

> **Epic**: Skill System
> **Status**: Ready
> **Layer**: Core
> **Type**: Logic
> **Manifest Version**: N/A — manifest not yet created

> **Estimate**: 2-3 hours

## Context

**GDD**: `design/gdd/skill-system.md`
**Requirement**: AC.1.1-1.3 (proficiency gain, level-up, overflow)

**ADR Governing Implementation**: ADR-001 (Event Architecture)
**Engine**: Godot 4.6.2 | **Risk**: LOW

---

## Acceptance Criteria

- [ ] AC.1.1: After battle, skill proficiency correctly calculated using formula D.1
- [ ] AC.1.2: When proficiency >= max_proficiency, skill levels up
- [ ] AC.1.3: On level-up, proficiency resets to overflow, max_proficiency updates via D.2

---

## Implementation Notes

From GDD D.1: `proficiency_gained = base_proficiency × (1 + synergy_bonus + talent_bonus)` where base_proficiency ∈ [10, 50], synergy_bonus ∈ [0.0, 0.5], talent_bonus ∈ [0.0, 0.3]. From D.2: `max_proficiency = base_cost × (level ^ 1.5)` where base_cost ∈ [100, 500]. On level-up: level += 1, proficiency = overflow (excess after reaching threshold), max_proficiency recalculated. From E.8: Overflow can trigger multiple consecutive level-ups.

---

## Out of Scope

- Rank ceiling checks (Story 003)
- Trait selection triggers (Story 004)
- Damage calculation (Story 005)

---

## QA Test Cases

- **AC.1.1**: Proficiency gain calculation
  - Given: base_proficiency=30, synergy_bonus=0.2, talent_bonus=0
  - When: Proficiency calculated after battle
  - Then: proficiency_gained = 30 × 1.2 = 36
  - Edge cases: Max case: 50 × 1.5 = 75

- **AC.1.2**: Level-up trigger
  - Given: Skill level 5, proficiency=150, max_proficiency=200 (base_cost=100, level^1.5=11.18→1118)
  - When: Gained 60 proficiency (total 210 > 200)
  - Then: Level becomes 6, proficiency resets

- **AC.1.3**: Overflow handling
  - Given: Skill level 5, proficiency=190, max_proficiency=200, gaining 220
  - When: Proficiency applied (190+220=410 vs 200 needed)
  - Then: Level 6, overflow=210, check again → if 210 >= new max, another level-up
  - Edge cases: Single gain triggering 3+ level-ups

---

## Test Evidence

**Story Type**: Logic
**Required evidence**: `tests/unit/skill/proficiency_leveling_test.gd`
**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: Story 001 (skill data model)
- Unlocks: Story 003 (rank ceiling gates leveling)
