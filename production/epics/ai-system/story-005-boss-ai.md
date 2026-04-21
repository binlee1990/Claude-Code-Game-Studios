# Story 005: Boss AI

> **Epic**: AI System
> **Status**: Complete
> **Layer**: Core
> **Type**: Logic
> **Manifest Version**: N/A — manifest not yet created

> **Estimate**: 2-3 hours

## Context

**GDD**: `design/gdd/ai-system.md`
**Requirement**: AC.4.1-4.3 (Boss phase switching, enrage, UI notification)

**ADR Governing Implementation**: ADR-001 (Event Architecture)
**Engine**: Godot 4.6.2 | **Risk**: LOW

---

## Acceptance Criteria

- [ ] AC.4.1: Boss triggers phase switch at 70% HP threshold
- [ ] AC.4.2: Boss enrage state: damage +30%
- [ ] AC.4.3: Boss phase switch triggers animation and UI notification event

---

## Implementation Notes

From GDD C.7: Boss phase switching at HP thresholds (default 70%). Enrage: damage +30%, attack speed +20%. New skills unlocked per phase. Boss prefers AOE skills. From E.5: Phase switch is immediate — triggers animation, changes AI behavior weights, unlocks new skills. Player gets a free action after phase switch to adapt. Phase thresholds are configurable via tuning knobs (60%-80% range).

---

## Out of Scope

- Phase switch animation/VFX (Visual/Feel)
- Boss health bar UI (UI system)
- Boss sound effects

---

## QA Test Cases

- **AC.4.1**: Phase switch trigger
  - Given: Boss HP at 71%, takes damage dropping to 69%
  - When: HP crosses 70% threshold
  - Then: Phase switch triggered, enrage state activated
  - Edge cases: Boss healed back above 70% → phase does NOT revert

- **AC.4.2**: Enrage damage bonus
  - Given: Boss in enrage state, base damage = 100
  - When: Boss attacks
  - Then: Damage = 130 (100 × 1.3)
  - Edge cases: Stacks with restraint/crush multipliers multiplicatively

- **AC.4.3**: Phase switch event
  - Given: Boss phase switch triggered
  - When: State changes
  - Then: Event emitted with boss_id, new_phase, unlocked_skills
  - Edge cases: Multiple phases possible — each threshold emits its own event

---

## Test Evidence

**Story Type**: Logic
**Required evidence**: `tests/unit/ai/boss_ai_test.gd`
**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: Stories 001-004 (Boss uses threat, weights, target/skill selection, position scoring)
- Unlocks: Story 006 (save/load)
