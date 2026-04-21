# Story 006: Class Skills

> **Epic**: Skill System
> **Status**: Ready
> **Layer**: Core
> **Type**: Logic
> **Manifest Version**: N/A — manifest not yet created

> **Estimate**: 2-3 hours

## Context

**GDD**: `design/gdd/skill-system.md`
**Requirement**: AC.4.1-4.3 (class skill unlock, retain, availability)

**ADR Governing Implementation**: ADR-001 (Event Architecture)
**Engine**: Godot 4.6.2 | **Risk**: LOW

---

## Acceptance Criteria

- [ ] AC.4.1: After class change, new class skills correctly unlocked
- [ ] AC.4.2: Original class skills retained but cannot level up further
- [ ] AC.4.3: New class skills are immediately usable after class change

---

## Implementation Notes

From GDD C.6: 12 class-specific skills mapped to 12 classes. From C.7: Normal skills learned at training hall (gold cost), class skills auto-unlock on class change. From E.6: Old class skills retained (frozen level, no proficiency gain), new class skills start at level 1. Passive skills from old class that have new-class versions need re-learning.

---

## Out of Scope

- Training hall UI
- Skill learning cost calculation (resource economy)
- Special class unlock conditions

---

## QA Test Cases

- **AC.4.1**: New class skill unlock
  - Given: Character changes from Warrior to Sword Saint
  - When: Class change completes
  - Then: "Sword Qi" (Sword Saint skill) unlocked at Lv1
  - Edge cases: Character already has the skill → no duplicate

- **AC.4.2**: Old skill retention
  - Given: Character has Warrior "Heavy Strike" at Lv8
  - When: Changes to Sword Saint
  - Then: Heavy Strike remains at Lv8, proficiency frozen (no further gain)
  - Edge cases: Shared skill between old and new class → continues leveling

- **AC.4.3**: Immediate availability
  - Given: Character just changed to Sword Saint, "Sword Qi" unlocked
  - When: Battle starts
  - Then: Sword Qi available in skill bar with MP cost and cooldown
  - Edge cases: Skill requires weapon not yet equipped → available but cannot execute

---

## Test Evidence

**Story Type**: Logic
**Required evidence**: `tests/unit/skill/class_skills_test.gd`
**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: Story 001 (data model)
- Cross-epic: Class system (class change event triggers skill unlock)
- Unlocks: Story 007 (save/load)
