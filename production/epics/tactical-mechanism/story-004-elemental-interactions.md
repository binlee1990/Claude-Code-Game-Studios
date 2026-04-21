# Story 004: Elemental Interactions

> **Epic**: Tactical Mechanism
> **Status**: Ready
> **Layer**: Core
> **Type**: Logic
> **Manifest Version**: N/A — manifest not yet created

> **Estimate**: 2-3 hours

## Context

**GDD**: `design/gdd/tactical-mechanism.md`
**Requirement**: AC.2.1-2.5 (elemental interaction system)

**ADR Governing Implementation**: ADR-001 (Event Architecture)
**Engine**: Godot 4.6.2 | **Risk**: LOW

---

## Acceptance Criteria

- [ ] AC.2.1: Fire + oil triggers burn, range 3×3, 30% base damage/turn, lasts 2 turns
- [ ] AC.2.2: Wind + fire enhances burn range to 5×5
- [ ] AC.2.3: Electric + water triggers chain lightning, max 3 hops, -20% damage per hop
- [ ] AC.2.4: Water + sand triggers mud, AGI -50%, lasts 1 turn
- [ ] AC.2.5: Element interaction correctly changes terrain state (consumed terrain becomes normal)

---

## Implementation Notes

From GDD C.2: 4 elements — fire, water, wind, earth. Interactions: fire+oil=burn (3×3, 30%/turn, 2 turns), wind+fire=enhanced burn (5×5), electric+water=chain (3 hops, -20%/hop), water+sand=mud (AGI -50%, 1 turn). From D.2: `burn_damage = base_skill_damage × 0.3`. From D.3: Chain damage 100%→80%→64%. From E.7: Burn damage is affected by target defense: `burn_damage = floor(base × 0.3 × (100 / (100 + target_defense)))`. From E.2: Terrain consumed after interaction — becomes normal terrain. From E.3: Chain breaks if no adjacent units.

---

## Out of Scope

- VFX for element interactions (Visual/Feel)
- AI using terrain info for decisions (AI system)
- Sound effects for element triggers

---

## QA Test Cases

- **AC.2.1**: Fire + oil burn
  - Given: Oil terrain cell, fire skill base_damage=100
  - When: apply_element_interaction(fire, oil_position) called
  - Then: Burn triggered, range 3×3, burn_damage=30/turn, duration=2 turns
  - Edge cases: Burn damage affected by target defense (E.7)

- **AC.2.2**: Wind enhances burn
  - Given: Active burn area (3×3), wind element applied
  - When: Wind interaction triggered on burning area
  - Then: Burn range expands to 5×5
  - Edge cases: Wind on non-burning fire has no enhanced effect

- **AC.2.3**: Electric + water chain lightning
  - Given: Water puddle terrain, 3 adjacent units, electric skill base_damage=80
  - When: Chain lightning triggered
  - Then: Target 1: 80 damage, Target 2: 64 damage, Target 3: 51 damage (floor)
  - Edge cases: No adjacent units → chain breaks (E.3); only 2 adjacent units → only 2 hops

- **AC.2.4**: Water + sand mud
  - Given: Sand terrain, water element applied
  - When: Mud interaction triggered
  - Then: Terrain becomes mud, AGI -50%, lasts 1 turn, then restores
  - Edge cases: Already muddy terrain → no double application

- **AC.2.5**: Terrain state change
  - Given: Oil terrain after burn completes
  - When: Burn duration expires
  - Then: Terrain becomes normal (not restored to oil)
  - Edge cases: Water puddle after chain lightning → becomes normal

---

## Test Evidence

**Story Type**: Logic
**Required evidence**: `tests/unit/tactical/elemental_interactions_test.gd`
**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: Story 001 (terrain data model provides element terrain types)
- Unlocks: Story 005 (save/load)
