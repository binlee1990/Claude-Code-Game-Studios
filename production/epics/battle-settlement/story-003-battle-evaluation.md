# Story 003: Battle Evaluation

> **Epic**: Battle Settlement
> **Status**: Ready
> **Layer**: Feature
> **Type**: Logic
> **Manifest Version**: N/A — manifest not yet created

> **Estimate**: 2-3 hours

## Context

**GDD**: `design/gdd/battle-settlement.md`
**Requirement**: AC.2.4, AC.3.1-3.3 (battle rating system)

**ADR Governing Implementation**: ADR-001 (Event Architecture)
**Engine**: Godot 4.6.2 | **Risk**: LOW

---

## Acceptance Criteria

- [ ] AC.3.1: No deaths → Excellent rating (+20% EXP)
- [ ] AC.3.2: No deaths AND zero damage taken → Perfect rating (+50% EXP)
- [ ] AC.3.3: Any death → Normal rating (+0% EXP)

---

## Implementation Notes

From GDD C.5: Four ratings — Perfect (no death, 0 damage), Excellent (no death), Normal (has death), Fail (defeat). Evaluation feeds into D.2 formula for EXP bonus. Perfect requires tracking total damage received across all player units during the entire battle. Evaluation is calculated at battle end.

---

## Out of Scope

- Evaluation UI display
- EXP distribution (Story 002)

---

## QA Test Cases

- **AC.3.1**: Excellent rating
  - Given: 4 player units, 0 deaths, some damage taken
  - When: Evaluation calculated
  - Then: Rating = Excellent, bonus = +20%
  - Edge cases: 1 damage taken → still Excellent

- **AC.3.2**: Perfect rating
  - Given: 4 player units, 0 deaths, 0 total damage taken
  - When: Evaluation calculated
  - Then: Rating = Perfect, bonus = +50%
  - Edge cases: Healed damage still counts as "damage taken" if HP was reduced

- **AC.3.3**: Normal rating
  - Given: 1 player unit died during battle (revived or not)
  - When: Evaluation calculated
  - Then: Rating = Normal, bonus = +0%
  - Edge cases: All 4 died but still won (impossible normally, but if mechanic allows → Normal)

---

## Test Evidence

**Story Type**: Logic
**Required evidence**: `tests/unit/settlement/battle_evaluation_test.gd`
**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: Story 001 (settlement trigger)
- Unlocks: Story 002 (evaluation bonus feeds EXP calculation)
