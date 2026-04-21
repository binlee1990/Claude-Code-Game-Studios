# Story 003: Target & Skill Selection

> **Epic**: AI System
> **Status**: Complete
> **Layer**: Core
> **Type**: Logic
> **Manifest Version**: N/A — manifest not yet created

> **Estimate**: 2-3 hours

## Context

**GDD**: `design/gdd/ai-system.md`
**Requirement**: AC.3.1-3.3 (target selection priority, restraint preference, skill fallback)

**ADR Governing Implementation**: ADR-001 (Event Architecture)
**Engine**: Godot 4.6.2 | **Risk**: LOW

---

## Acceptance Criteria

- [ ] AC.3.1: AI prioritizes killable targets with lowest HP
- [ ] AC.3.2: Among equal conditions, AI prefers targets it can restraint (×1.5 weight)
- [ ] AC.3.3: When all skills on cooldown, AI selects basic attack or waits

---

## Implementation Notes

From GDD C.4: Target selection priority: (1) threat ≥ threshold → highest threat, (2) killable → lowest HP, (3) none killable → lowest HP, (4) restraint target gets ×1.5 priority weight. From C.5: Skill selection evaluates expected value per skill (D.2), considers cooldown/MP, and applies AI type weights. From E.3: All skills on cooldown → use basic attack; if basic attack unavailable → wait. From E.6: No killable target → evaluate high-cost burst skills or reposition.

---

## Out of Scope

- Position scoring (Story 004)
- Boss AI phases (Story 005)
- AI decision delay timing (D.4)

---

## QA Test Cases

- **AC.3.1**: Killable target priority
  - Given: Enemy A (HP=20, killable), Enemy B (HP=80, not killable), Enemy C (HP=15, killable)
  - When: AI selects target
  - Then: Selects Enemy C (lowest HP among killable targets)
  - Edge cases: No killable targets → selects lowest HP regardless

- **AC.3.2**: Restraint preference
  - Given: Two equal-HP targets, AI weapon restrains one
  - When: AI selects target
  - Then: Selects restrainable target (×1.5 weight)
  - Edge cases: Restraint target has much higher HP → HP priority wins

- **AC.3.3**: Skill cooldown fallback
  - Given: All skills on cooldown
  - When: AI selects action
  - Then: Selects basic attack
  - Edge cases: Basic attack also unavailable (silenced) → AI waits

---

## Test Evidence

**Story Type**: Logic
**Required evidence**: `tests/unit/ai/target_skill_selection_test.gd`
**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: Story 001 (threat values), Story 002 (AI type weights)
- Unlocks: Story 004 (position depends on target), Story 005 (Boss AI)
