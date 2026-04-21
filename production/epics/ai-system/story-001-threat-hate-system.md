# Story 001: Threat/Hate System

> **Epic**: AI System
> **Status**: Ready
> **Layer**: Core
> **Type**: Logic
> **Manifest Version**: N/A — manifest not yet created

> **Estimate**: 2-3 hours

## Context

**GDD**: `design/gdd/ai-system.md`
**Requirement**: AC.2.1-2.4 (threat calculation, hate updates, target switching)

**ADR Governing Implementation**: ADR-001 (Event Architecture)
**Engine**: Godot 4.6.2 | **Risk**: LOW

---

## Acceptance Criteria

- [ ] AC.2.1: Each time damage is dealt, threat value correctly updates (damage × 10%)
- [ ] AC.2.2: Each time healing is applied, threat increases (heal amount × 20%)
- [ ] AC.2.3: AI prioritizes attacking the highest-threat target
- [ ] AC.2.4: When hate target dies, AI switches to next highest-threat target

---

## Implementation Notes

From GDD C.3: `threat_score = base_threat + damage_dealt_recent + skill_threat + position_threat`. base_threat = 100/current_HP (inverse). damage_dealt_recent = recent damage × 10%. skill_threat = {0 (none), 5 (damage), 10 (control), 15 (buff), 20 (heal)}. position_threat = {0 (low), 5 (plain), 10 (high)}. Threat updates: deal damage → +damage×10%, receive damage → -damage×5%, heal ally → +heal×20%, buff → +10 fixed. From E.1: Target dies → immediate re-evaluation, pick next highest. From E.8: Threat cannot be trivially manipulated — must combine with real damage.

---

## Out of Scope

- AI type decision weights (Story 002)
- Skill selection logic (Story 003)
- Position scoring (Story 004)

---

## QA Test Cases

- **AC.2.1**: Damage threat update
  - Given: Unit A deals 50 damage to enemy
  - When: Threat recalculated
  - Then: A's threat to that enemy += 50 × 0.1 = 5.0
  - Edge cases: Multiple damage instances accumulate

- **AC.2.2**: Healing threat update
  - Given: Unit B heals ally for 30 HP
  - When: Threat recalculated
  - Then: B's threat to enemies += 30 × 0.2 = 6.0
  - Edge cases: Buff gives +10 fixed threat regardless of buff power

- **AC.2.3**: Highest threat targeting
  - Given: Three enemies with threat values 15.0, 8.0, 3.0
  - When: AI selects target
  - Then: Selects enemy with threat 15.0

- **AC.2.4**: Target death switching
  - Given: Current target (threat=15.0) dies, remaining targets have threat 8.0 and 3.0
  - When: Target re-evaluation triggered
  - Then: Switches to target with threat 8.0
  - Edge cases: All targets dead → AI ends turn

---

## Test Evidence

**Story Type**: Logic
**Required evidence**: `tests/unit/ai/threat_system_test.gd`
**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: None (foundational AI story)
- Unlocks: Story 002, 003, 005 (all AI decisions use threat values)
