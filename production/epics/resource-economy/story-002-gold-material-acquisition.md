# Story 002: Gold & Material Acquisition

> **Epic**: Resource Economy
> **Status**: Ready
> **Layer**: Core
> **Type**: Logic
> **Manifest Version**: N/A — manifest not yet created

> **Estimate**: 2-3 hours

## Context

**GDD**: `design/gdd/resource-economy.md`
**Requirement**: AC.2.1-2.2 (gold and material formulas)

**ADR Governing Implementation**: ADR-001 (Event Architecture)
**Engine**: Godot 4.6.2 | **Risk**: LOW

---

## Acceptance Criteria

- [ ] AC.2.1: `calculate_gold_reward(base_reward, damage_dealt, kill_bonus)` returns gold = base_reward + floor(damage_dealt * 0.1) + kill_bonus (boss=20, normal=0)
- [ ] AC.2.2: `calculate_material_reward(enemy_tier)` returns materials = enemy_tier * random(1,3)
- [ ] AC.2.3: Zero-damage battle still awards base gold (base_reward component)

---

## Implementation Notes

From GDD D.1: base_reward range [50, 200] depends on map difficulty. kill_bonus only applies to boss kills (20) — normal enemies give 0. From GDD D.2: enemy_tier {1=normal, 2=elite, 3=hard, 4=boss}. Output range: gold [50, ~2000], materials [1, 12].

---

## Out of Scope

- Story 003: Fruit and rare drops
- Battle system integration (battle system calls calculate_rewards)

---

## QA Test Cases

- **AC.2.1**: Normal battle gold
  - Given: base_reward=50, damage=300, kill_bonus=0 (no boss)
  - When: calculate_gold_reward called
  - Then: gold = 50 + floor(300*0.1) + 0 = 80

- **AC.2.1**: Boss battle gold
  - Given: base_reward=100, damage=800, kill_bonus=20 (boss kill)
  - When: calculate_gold_reward called
  - Then: gold = 100 + floor(800*0.1) + 20 = 200

- **AC.2.1**: Zero damage battle
  - Given: base_reward=50, damage=0, kill_bonus=0
  - When: calculate_gold_reward called
  - Then: gold = 50

- **AC.2.2**: Material drops by tier
  - Given: enemy_tier=1 (normal)
  - When: calculate_material_reward called
  - Then: Returns 1-3 materials (random in range)
  - Edge cases: tier=4 (boss) → 4-12 materials

---

## Test Evidence

**Story Type**: Logic
**Required evidence**: `tests/unit/resource/gold_material_acquisition_test.gd`
**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: Story 001 (inventory model to receive resources)
- Unlocks: Story 006 (save/load)
