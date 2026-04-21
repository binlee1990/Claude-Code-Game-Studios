# Story 003: Rank System

> **Epic**: Skill System
> **Status**: Ready
> **Layer**: Core
> **Type**: Logic
> **Manifest Version**: N/A — manifest not yet created

> **Estimate**: 2-3 hours

## Context

**GDD**: `design/gdd/skill-system.md`
**Requirement**: AC.2.1-2.3 (rank ceilings, advancement, effect unlocking)

**ADR Governing Implementation**: ADR-001 (Event Architecture)
**Engine**: Godot 4.6.2 | **Risk**: LOW

---

## Acceptance Criteria

- [ ] AC.2.1: Skill cannot level up beyond current rank ceiling (Basic=10, Intermediate=20, Advanced=30)
- [ ] AC.2.2: When advancement conditions met, rank correctly advances
- [ ] AC.2.3: Rank advancement unlocks new skill effects/vfx

---

## Implementation Notes

From GDD C.4: Four ranks — Basic (max Lv10, default), Intermediate (max Lv20, requires Lv10 + hidden attr), Advanced (max Lv30, requires Lv20 + hidden attr), Master (max Lv99, requires Lv30 + advancement challenge). From E.1: At rank ceiling without meeting advancement → blocked, UI shows missing conditions. Rank advancement keeps current level, unlocks new visual effects. Each rank has specific advancement conditions stored in rank_up_condition.

---

## Out of Scope

- Trait selection (Story 004)
- Advancement challenge content (gameplay content)
- VFX for rank advancement

---

## QA Test Cases

- **AC.2.1**: Rank ceiling enforcement
  - Given: Basic rank skill at level 10, proficiency >= max_proficiency
  - When: Level-up attempted
  - Then: Level stays at 10, proficiency does not overflow
  - Edge cases: Intermediate ceiling at 20, Advanced at 30

- **AC.2.2**: Rank advancement
  - Given: Basic skill at Lv10, hidden attribute meets threshold
  - When: Advancement triggered
  - Then: Rank changes to Intermediate, max level becomes 20
  - Edge cases: Conditions partially met → advancement blocked

- **AC.2.3**: Effect unlocking
  - Given: Skill advances from Basic to Intermediate
  - When: Rank changes
  - Then: New skill effect entry unlocked in skill data
  - Edge cases: Master rank unlocks all effects

---

## Test Evidence

**Story Type**: Logic
**Required evidence**: `tests/unit/skill/rank_system_test.gd`
**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: Story 001 (data model), Story 002 (leveling blocked by rank ceiling)
- Unlocks: Story 004 (traits at rank boundary levels)
