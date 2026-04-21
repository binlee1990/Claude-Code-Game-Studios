# Story 001: Skill Data Model

> **Epic**: Skill System
> **Status**: Ready
> **Layer**: Core
> **Type**: Logic
> **Manifest Version**: N/A — manifest not yet created

> **Estimate**: 2-3 hours

## Context

**GDD**: `design/gdd/skill-system.md`
**Requirement**: C.1-C.2 (skill classification and data structure)

**ADR Governing Implementation**: ADR-001 (Event Architecture)
**Engine**: Godot 4.6.2 | **Risk**: LOW

---

## Acceptance Criteria

- [ ] AC-D1: Skill object contains all required fields (id, name, type, usage, rank, level, proficiency, mp_cost, cooldown, base_damage, effects, traits)
- [ ] AC-D2: Skill classification by source: normal (all classes) vs class-specific
- [ ] AC-D3: Skill classification by usage: active (MP + cooldown) vs passive (no cost)

---

## Implementation Notes

From GDD C.1: Two classification dimensions — source (normal/class) and usage (active/passive). From C.2: Skill data structure includes skill_id, name, type, usage, rank, level, proficiency, max_proficiency, mp_cost, cooldown, base_damage, effects[], unlock_condition, rank_up_condition, traits[]. Rank is an enum: {Basic, Intermediate, Advanced, Master}. Level range [1, 99]. Proficiency range [0, max_proficiency].

---

## Out of Scope

- Proficiency gain formulas (Story 002)
- Damage calculation (Story 005)
- Trait selection UI

---

## QA Test Cases

- **AC-D1**: Skill object creation
  - Given: Skill definition with all fields
  - When: Skill instance created
  - Then: All fields accessible and correctly initialized
  - Edge cases: Default values for optional fields (traits=[], effects=[])

- **AC-D2**: Source classification
  - Given: Normal skill "Defend" and class skill "Fireball"
  - When: Skill type queried
  - Then: Defend = normal, Fireball = class-specific
  - Edge cases: A skill can be both normal and active

- **AC-D3**: Usage classification
  - Given: Active skill "Fireball" (MP=20, cooldown=2) and passive skill "Magic Shield"
  - When: Usage queried
  - Then: Fireball = active (has cost/cooldown), Magic Shield = passive (no cost)
  - Edge cases: Passive skills ignore mp_cost and cooldown

---

## Test Evidence

**Story Type**: Logic
**Required evidence**: `tests/unit/skill/skill_data_model_test.gd`
**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: None (foundational story)
- Unlocks: Stories 002-007 (all skill stories use this data model)
