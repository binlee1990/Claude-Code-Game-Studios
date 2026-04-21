# Story 002: Character Departure & Recall

> **Epic**: Character Management
> **Status**: Ready
> **Layer**: Feature
> **Type**: Logic
> **Manifest Version**: N/A — manifest not yet created

> **Estimate**: 2-3 hours

## Context

**GDD**: `design/gdd/character-management.md`
**Requirement**: C.2-C.3 (departure types, recall mechanism)

**ADR Governing Implementation**: ADR-001 (Event Architecture)
**Engine**: Godot 4.6.2 | **Risk**: LOW

---

## Acceptance Criteria

- [ ] AC-D1: Story departure removes character from available roster, triggered by narrative event
- [ ] AC-D2: Defeat departure (HP=0) auto-recovers after battle (character returns to roster)
- [ ] AC-D3: Recalled character retains level, equipment, and all progression

---

## Implementation Notes

From GDD C.2: Two departure types — story (narrative trigger, recallable via quest) and defeat (HP=0, auto-recovers). From C.3: Recall via completing specific quest; recalled character keeps all stats/equipment/skills. Story departure marks character as "departed" in roster (not deleted). Defeat is temporary — character available again after battle ends.

---

## Out of Scope

- Narrative/quest content triggering departures
- Departure animation
- Recall quest system

---

## QA Test Cases

- **AC-D1**: Story departure
  - Given: Character in roster, story_departure event fired
  - When: Departure processed
  - Then: Character marked "departed", removed from deployable roster
  - Edge cases: Deployed character receives departure → removed mid-battle (blocked until battle ends)

- **AC-D2**: Defeat auto-recovery
  - Given: Character HP reaches 0 in battle
  - When: Battle ends
  - Then: Character auto-recovers, returns to roster with HP restored
  - Edge cases: All deployed characters defeated → defeat condition (combat flow)

- **AC-D3**: Recall preservation
  - Given: Character departed at level 15 with equipment and skills
  - When: Recall quest completed, character returns
  - Then: Level 15, same equipment, same skills
  - Edge cases: No recall quest available → character stays departed

---

## Test Evidence

**Story Type**: Logic
**Required evidence**: `tests/unit/character/departure_recall_test.gd`
**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: Story 001 (party composition provides roster)
- Unlocks: Story 003 (save/load persists departure state)
