# Story 002: Action System

> **Epic**: Turn-Based Mode
> **Status**: Ready
> **Layer**: Core
> **Type**: Logic
> **Manifest Version**: N/A — manifest not yet created

> **Estimate**: 2-3 hours

## Context

**GDD**: `design/gdd/turn-based-mode.md`
**Requirement**: AC.2.1-2.3 (per-turn actions, MP recovery, depletion)

**ADR Governing Implementation**: ADR-001 (Event Architecture)
**Engine**: Godot 4.6.2 | **Risk**: LOW

---

## Acceptance Criteria

- [ ] AC.2.1: Each unit gets 1 action per turn
- [ ] AC.2.2: Action options: move + attack/skill, or standby (no resource cost)
- [ ] AC.2.3: MP depleted → only basic attack or standby available

---

## Implementation Notes

From GDD C.3: Action types — basic attack (no MP, triggers cooldown), skill attack (MP + cooldown), heal skill (MP + cooldown), standby (no cost). From D.2: `mp_recovered = max_mp × 0.1` per turn. Battle starts at 100% MP. From E.3: MP=0 → skills show "MP insufficient", only basic attack or standby. Each unit acts once per round, then marked as "acted" until next round.

---

## Out of Scope

- Movement calculations (Story 003)
- Combat flow (Story 004)
- Skill damage calculation (skill-system epic)

---

## QA Test Cases

- **AC.2.1**: One action per turn
  - Given: Unit has not acted this turn
  - When: Unit executes any action
  - Then: Unit marked as "acted", cannot act again this round
  - Edge cases: Standby also counts as "acted"

- **AC.2.2**: Action options available
  - Given: Unit at full MP, skills off cooldown
  - When: Action menu presented
  - Then: Options = [move, attack, skill_1, skill_2, standby]
  - Edge cases: All skills on cooldown → only [move, attack, standby]

- **AC.2.3**: MP depletion
  - Given: Unit MP=0, skills cost MP
  - When: Action menu presented
  - Then: Skills disabled, only [basic_attack, standby] available
  - Edge cases: MP exactly equals skill cost → usable; MP = cost-1 → disabled

---

## Test Evidence

**Story Type**: Logic
**Required evidence**: `tests/unit/turn/action_system_test.gd`
**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: Story 001 (turn order determines who acts)
- Unlocks: Story 004 (combat flow uses action system)
