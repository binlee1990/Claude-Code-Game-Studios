# Story 005: Skill Damage Calculation

> **Epic**: Skill System
> **Status**: Ready
> **Layer**: Core
> **Type**: Logic
> **Manifest Version**: N/A — manifest not yet created

> **Estimate**: 2-3 hours

## Context

**GDD**: `design/gdd/skill-system.md`
**Requirement**: D.3 (skill damage formula)

**ADR Governing Implementation**: ADR-001 (Event Architecture)
**Engine**: Godot 4.6.2 | **Risk**: LOW

---

## Acceptance Criteria

- [ ] AC-DM1: Damage = base_damage × level_multiplier × trait_multiplier × (1 + attribute_bonus)
- [ ] AC-DM2: Level multiplier = 1 + (level - 1) × 0.1
- [ ] AC-DM3: Attribute bonus correctly sourced from character stats (INT for magic, STR for physical)

---

## Implementation Notes

From GDD D.3: `final_damage = base_damage × level_multiplier × trait_multiplier × (1 + attribute_bonus)`. level_multiplier = 1 + (level-1) × 0.1. trait_multiplier comes from Story 004 (default 1.0). attribute_bonus is percentage from character attributes — INT for magic skills, STR for physical skills. Level multiplier range: [1.0 (Lv1) to 10.8 (Lv99)].

---

## Out of Scope

- Restraint/crush multipliers (tactical mechanism epic)
- Defense mitigation (combat system)
- Critical hits

---

## QA Test Cases

- **AC-DM1**: Full damage formula
  - Given: Fireball Lv10, base_damage=100, trait_multiplier=1.2, attribute_bonus=0.5
  - When: Damage calculated
  - Then: 100 × (1 + 9×0.1) × 1.2 × 1.5 = 100 × 1.9 × 1.2 × 1.5 = 342

- **AC-DM2**: Level multiplier
  - Given: Skill at level 1
  - When: Level multiplier calculated
  - Then: 1 + (1-1) × 0.1 = 1.0
  - Edge cases: Level 20 → 1 + 19×0.1 = 2.9; Level 99 → 1 + 98×0.1 = 10.8

- **AC-DM3**: Attribute bonus source
  - Given: Physical skill, character STR bonus = 0.3; Magic skill, character INT bonus = 0.6
  - When: Damage calculated for each
  - Then: Physical uses STR (1.3 multiplier), Magic uses INT (1.6 multiplier)
  - Edge cases: No attribute bonus → multiplier = 1.0

---

## Test Evidence

**Story Type**: Logic
**Required evidence**: `tests/unit/skill/skill_damage_test.gd`
**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: Story 001 (data model), Story 004 (trait_multiplier)
- Unlocks: Combat system consumes this formula
