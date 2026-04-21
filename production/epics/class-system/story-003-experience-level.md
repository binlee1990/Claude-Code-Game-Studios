# Story 003: Class Experience & Level System

> **Epic**: Class System
> **Status**: Complete
> **Layer**: Core
> **Type**: Logic
> **Manifest Version**: N/A — manifest not yet created

> **Estimate**: 2-3 hours

## Context

**GDD**: `design/gdd/class-system.md`
**Requirement**: AC.3.1-3.5 (experience), AC.6.1-6.3 (level calculation)

**ADR Governing Implementation**: ADR-001: Event Architecture
**Engine**: Godot 4.6.2 | **Risk**: LOW

---

## Acceptance Criteria

- [ ] AC.3.1: `report_damage_dealt(character_id, damage, is_kill, battle_result)` triggers class experience calculation
- [ ] AC.3.2: Exp formula: `exp = min(floor(damage * 0.02), 500) + kill_bonus + battle_bonus`
- [ ] AC.3.3: kill_bonus = 10 on kill, 0 otherwise; only last-hitter gets bonus
- [ ] AC.3.4: battle_bonus = 20 per battle (regardless of win/lose)
- [ ] AC.3.5: 0 damage battle still awards 20 exp (battle_bonus only)
- [ ] AC.6.1: Class level = floor(E_c / CAP_c) + 1
- [ ] AC.6.2: Basic class CAP=1000 (level 2 at 1000 exp)
- [ ] AC.6.3: Advanced/Special class CAP=2000 (level 2 at 2000 exp)

---

## Implementation Notes

From GDD D.2-D.3: Experience is per-class (each class tracks its own exp). On class change, new class starts at 0. Damage cap prevents high-damage characters from gaining excessive exp. Level formula is simple division with floor.

---

## Out of Scope

- Story 004: Class change (which resets new class exp to 0)
- Battle system integration (battle system calls report_damage_dealt)

---

## QA Test Cases

- **AC.3.2**: Standard experience calculation
  - Given: Character dealt 300 damage, killed enemy, battle won
  - When: report_damage_dealt called
  - Then: exp = min(floor(300*0.02), 500) + 10 + 20 = 36
  - Edge cases: 800 damage → exp = min(16, 500) + 0 + 20 = 36 (damage cap at 500 raw)

- **AC.3.3**: Kill bonus
  - Given: Character dealt 100 damage, is_kill=TRUE
  - When: Exp calculated
  - Then: kill_bonus = 10 included

- **AC.3.5**: Zero damage battle
  - Given: Character dealt 0 damage, no kill, battle completed
  - When: Exp calculated
  - Then: exp = 0 + 0 + 20 = 20

- **AC.6.1**: Level calculation
  - Given: Warrior with 1500 class experience
  - When: Reading class level
  - Then: level = floor(1500 / 1000) + 1 = 2

- **AC.6.3**: Advanced class level
  - Given: Swordmaster with 5500 class experience
  - When: Reading class level
  - Then: level = floor(5500 / 2000) + 1 = 3

---

## Test Evidence

**Story Type**: Logic
**Required evidence**: `tests/unit/class/experience_level_test.gd` — must exist and pass
**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: Story 001 (state machine — tracks which class is active)
- Unlocks: Story 004 (class change resets new class exp)
