# Story 007: Skill Save/Load Integration

> **Epic**: Skill System
> **Status**: Complete
> **Layer**: Core
> **Type**: Integration
> **Manifest Version**: N/A — manifest not yet created

> **Estimate**: 2-3 hours

## Context

**GDD**: `design/gdd/skill-system.md`
**Requirement**: Full skill state persistence

**ADR Governing Implementation**: ADR-001, ADR-003 (Save System)
**Engine**: Godot 4.6.2 | **Risk**: LOW

---

## Acceptance Criteria

- [ ] AC-S1: All skill data (level, proficiency, rank, selected traits) correctly saved and restored
- [ ] AC-S2: Skill cooldown state persisted mid-battle
- [ ] AC-S3: Frozen class skills correctly preserved after round-trip
- [ ] AC-S4: Multiple save/load cycles produce identical skill state

---

## Implementation Notes

From ADR-003: Skill data per unit stored in save system. Each skill entry includes: skill_id, level, proficiency, rank, selected_traits[], cooldown_remaining. Frozen skills flagged as frozen=true. Trait selections stored as trait_id references.

---

## Out of Scope

- Save UI
- Auto-save triggering

---

## QA Test Cases

- **AC-S1**: Full skill state round-trip
  - Given: Character with Fireball (Lv15, Intermediate, proficiency=450, trait="Damage+20%")
  - When: Save → Load
  - Then: All fields match exactly

- **AC-S2**: Cooldown persistence
  - Given: Fireball cooldown = 1 turn remaining (mid-battle)
  - When: Save → Load
  - Then: Cooldown = 1 turn remaining

- **AC-S3**: Frozen skill preservation
  - Given: Character with frozen Warrior "Heavy Strike" (Lv8, frozen)
  - When: Save → Load
  - Then: Skill still frozen, level=8, no proficiency gain possible

- **AC-S4**: Double round-trip
  - Given: Complex skill set with mixed ranks and traits
  - When: Save → Load → Save → Load
  - Then: Final state = state after first load

---

## Test Evidence

**Story Type**: Integration
**Required evidence**: `tests/integration/skill/save_load_integration_test.gd`
**Status**: [x] `tests/integration/skill/save_load_integration_test.gd` created and passing

---

## Dependencies

- Depends on: Stories 001-006 (all skill state must be defined before serialization)
