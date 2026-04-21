# Story 002: Weapon Triangle

> **Epic**: Tactical Mechanism
> **Status**: Ready
> **Layer**: Core
> **Type**: Logic
> **Manifest Version**: N/A — manifest not yet created

> **Estimate**: 2-3 hours

## Context

**GDD**: `design/gdd/tactical-mechanism.md`
**Requirement**: AC.1.1-1.4 (weapon restraint triangle)

**ADR Governing Implementation**: ADR-001 (Event Architecture)
**Engine**: Godot 4.6.2 | **Risk**: LOW

---

## Acceptance Criteria

- [ ] AC.1.1: Sword attacks Spear → damage × 1.5
- [ ] AC.1.2: Spear attacks Axe → damage × 1.5
- [ ] AC.1.3: Axe attacks Sword → damage × 1.5
- [ ] AC.1.4: Restraint + crush triggered simultaneously → multiplier stacks to × 2.25

---

## Implementation Notes

From GDD C.1: Restraint triangle is sword>axe>spear>sword. Bow, magic, and fist/claw have no restraint advantage. Restraint gives 50% damage bonus. The restrained side receives no extra penalty — only the attacker gets the bonus. From GDD D.1: `final_damage_multiplier = base_multiplier × crush_multiplier` where base_multiplier is {1.0, 1.5} and crush_multiplier is {1.0, 1.5}. From E.8: Chain lightning hops independently check restraint — each hop applies restraint if the weapon types match.

---

## Out of Scope

- Elemental interactions (Story 004)
- Height advantage (Story 003)
- UI for restraint indicator

---

## QA Test Cases

- **AC.1.1**: Sword vs Spear
  - Given: Attacker weapon = sword, defender weapon = spear, base damage = 100
  - When: get_triangle_modifier(sword, spear) called
  - Then: Returns 1.5; final damage = 150

- **AC.1.2**: Spear vs Axe
  - Given: Attacker weapon = spear, defender weapon = axe, base damage = 100
  - When: get_triangle_modifier(spear, axe) called
  - Then: Returns 1.5; final damage = 150

- **AC.1.3**: Axe vs Sword
  - Given: Attacker weapon = axe, defender weapon = sword, base damage = 100
  - When: get_triangle_modifier(axe, sword) called
  - Then: Returns 1.5; final damage = 150

- **AC.1.4**: Restraint + crush stacking
  - Given: Sword attacks spear, crush condition also met, base damage = 100
  - When: Multipliers calculated
  - Then: 1.5 × 1.5 = 2.25; final damage = 225
  - Edge cases: No restraint + no crush = 1.0; restraint only = 1.5; crush only = 1.5

---

## Test Evidence

**Story Type**: Logic
**Required evidence**: `tests/unit/tactical/weapon_triangle_test.gd`
**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: None (standalone logic, no terrain dependency)
- Unlocks: Story 005 (save/load)
