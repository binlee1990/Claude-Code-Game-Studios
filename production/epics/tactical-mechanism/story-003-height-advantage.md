# Story 003: Height Advantage

> **Epic**: Tactical Mechanism
> **Status**: Ready
> **Layer**: Core
> **Type**: Logic
> **Manifest Version**: N/A — manifest not yet created

> **Estimate**: 2-3 hours

## Context

**GDD**: `design/gdd/tactical-mechanism.md`
**Requirement**: AC.3.1-3.4 (height advantage system)

**ADR Governing Implementation**: ADR-001 (Event Architecture)
**Engine**: Godot 4.6.2 | **Risk**: LOW

---

## Acceptance Criteria

- [ ] AC.3.1: High attacks low → range +1 per level, hit +10% per level
- [ ] AC.3.2: Low attacks high → range -1 per level, hit -10% per level
- [ ] AC.3.3: Same level → no modifiers
- [ ] AC.3.4: Height difference affects ranged attacks (bow/magic) range and hit

---

## Implementation Notes

From GDD C.3: 3 height levels — lowland(0), plain(1), highland(2). From D.4: `effective_range = base_range + height_diff` where `height_diff = attacker_height - defender_height`. From D.5: `hit_modifier = height_diff × 10%`. Height affects range and hit only, NOT damage. Obstacles block high-ground attacks (E.5) — height bonus does not compensate for obstacle blocking.

---

## Out of Scope

- Terrain rendering / visual height representation
- Weapon triangle (Story 002)
- Elemental interactions (Story 004)

---

## QA Test Cases

- **AC.3.1**: High→low advantage
  - Given: Attacker height=2, defender height=0, base range=3
  - When: get_height_modifier(2, 0) called
  - Then: range modifier = +2, effective range = 5; hit modifier = +20%

- **AC.3.2**: Low→high penalty
  - Given: Attacker height=0, defender height=2, base range=3
  - When: get_height_modifier(0, 2) called
  - Then: range modifier = -2, effective range = 1; hit modifier = -20%

- **AC.3.3**: Same level
  - Given: Attacker height=1, defender height=1, base range=3
  - When: get_height_modifier(1, 1) called
  - Then: range modifier = 0, effective range = 3; hit modifier = 0%

- **AC.3.4**: Ranged weapon height effect
  - Given: Bow (base range=4) on highland(2), target on plain(1)
  - When: Attack calculated
  - Then: effective range = 4 + (2-1) = 5; hit modifier = +10%
  - Edge cases: Magic same calculation; effective range can go below 1 (attack impossible at range 0)

---

## Test Evidence

**Story Type**: Logic
**Required evidence**: `tests/unit/tactical/height_advantage_test.gd`
**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: Story 001 (terrain data model provides height values)
- Unlocks: Story 005 (save/load)
