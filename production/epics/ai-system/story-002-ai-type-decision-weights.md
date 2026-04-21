# Story 002: AI Type Decision Weights

> **Epic**: AI System
> **Status**: Ready
> **Layer**: Core
> **Type**: Logic
> **Manifest Version**: N/A — manifest not yet created

> **Estimate**: 2-3 hours

## Context

**GDD**: `design/gdd/ai-system.md`
**Requirement**: AC.1.1-1.4 (AI personality types and decision weights)

**ADR Governing Implementation**: ADR-001 (Event Architecture)
**Engine**: Godot 4.6.2 | **Risk**: LOW

---

## Acceptance Criteria

- [ ] AC.1.1: Aggressive AI prioritizes highest-damage action (damage weight ×1.5)
- [ ] AC.1.2: Defensive AI prioritizes survival-maximizing action (survival weight ×1.5)
- [ ] AC.1.3: Support AI prioritizes healing/buffing allies (heal/buff weight ×1.5)
- [ ] AC.1.4: Control AI prioritizes highest-control-effect action (control weight ×1.5)

---

## Implementation Notes

From GDD C.2: 5 AI types — aggressive (damage×1.5), defensive (survival×1.5), support (heal/buff×1.5), control (control×1.5), balanced (no modifier). From D.2: `skill_expected_value = base_damage × hit_probability × kill_bonus × type_multiplier`. type_multiplier varies by AI type: aggressive=1.2 for damage skills, control=1.5 for control skills, etc. Each AI config file specifies the type and associated weight multipliers.

---

## Out of Scope

- Threat system (Story 001)
- Target/skill selection algorithm (Story 003)
- Position scoring (Story 004)

---

## QA Test Cases

- **AC.1.1**: Aggressive AI picks highest damage
  - Given: Aggressive AI, two skills available — Skill A (damage=100), Skill B (damage=60, heal=40)
  - When: AI evaluates options
  - Then: Selects Skill A (highest damage ×1.5 weight)
  - Edge cases: Equal damage → use hit_probability as tiebreaker

- **AC.1.2**: Defensive AI picks survival action
  - Given: Defensive AI at 30% HP, heal skill available
  - When: AI evaluates options
  - Then: Selects heal or defensive skill (survival weight ×1.5)
  - Edge cases: Full HP → defensive AI acts like balanced type

- **AC.1.3**: Support AI prioritizes healing
  - Given: Support AI, ally at 50% HP, enemy in range
  - When: AI evaluates options
  - Then: Selects heal ally (heal weight ×1.5) over attack
  - Edge cases: All allies full HP → support AI attacks with normal weights

- **AC.1.4**: Control AI picks control skill
  - Given: Control AI, control skill available, damage skill available
  - When: AI evaluates options
  - Then: Selects control skill (control weight ×1.5)
  - Edge cases: No control skills available → falls back to balanced behavior

---

## Test Evidence

**Story Type**: Logic
**Required evidence**: `tests/unit/ai/ai_type_weights_test.gd`
**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: Story 001 (threat values used in decision scoring)
- Unlocks: Story 003 (target/skill selection uses type weights)
