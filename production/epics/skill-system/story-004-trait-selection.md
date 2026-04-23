# Story 004: Trait Selection

> **Epic**: Skill System
> **Status**: Complete
> **Layer**: Core
> **Type**: Logic
> **Manifest Version**: N/A — manifest not yet created

> **Estimate**: 2-3 hours

## Context

**GDD**: `design/gdd/skill-system.md`
**Requirement**: AC.3.1-3.3 (trait trigger, apply, defer)

**ADR Governing Implementation**: ADR-001 (Event Architecture)
**Engine**: Godot 4.6.2 | **Risk**: LOW

---

## Acceptance Criteria

- [ ] AC.3.1: Skill reaching level 10/20/30 triggers trait selection event
- [ ] AC.3.2: Selected trait correctly modifies skill (damage ×1.2, range +1, etc.)
- [ ] AC.3.3: Deferred trait selection: skill operates without trait bonus until player chooses

---

## Implementation Notes

From GDD C.5: At levels 10/20/30, 2-3 trait options presented, player picks 1 permanent trait. From D.4: Trait effects are multiplicative or additive per description (range+1 = additive, damage×1.2 = multiplicative). From E.2: Player can defer → no trait bonus applied until choice is made. From E.7: Multiple traits stack independently, no conflict resolution needed (each applies separately).

---

## Out of Scope

- Trait selection UI (UI system)
- Trait balance tuning
- Trait visual effects

---

## QA Test Cases

- **AC.3.1**: Trait event trigger
  - Given: Skill at level 9, about to level up to 10
  - When: Level reaches 10
  - Then: Trait selection event emitted with skill_id, level, available_traits
  - Edge cases: Level 20 triggers second trait; level 30 triggers third

- **AC.3.2**: Trait application
  - Given: "Damage +20%" trait selected for Fireball
  - When: Trait applied
  - Then: Fireball trait_multiplier = 1.2 for damage calculation
  - Edge cases: "Range +1" → base_range += 1 (additive, not multiplicative)

- **AC.3.3**: Deferred trait
  - Given: Skill at level 10, trait selection deferred
  - When: Damage calculated
  - Then: No trait bonus applied (trait_multiplier = 1.0)
  - Edge cases: Player later selects trait → retroactively applies from that point

---

## Test Evidence

**Story Type**: Logic
**Required evidence**: `tests/unit/skill/trait_selection_test.gd`
**Status**: [x] `tests/unit/skill/trait_selection_test.gd` created and passing

---

## Dependencies

- Depends on: Story 002 (leveling triggers trait selection), Story 003 (rank boundaries)
- Unlocks: Story 005 (damage formula uses trait_multiplier)
