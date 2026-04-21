# Story 004: Class Change Flow

> **Epic**: Class System
> **Status**: Ready
> **Layer**: Core
> **Type**: Logic
> **Manifest Version**: N/A — manifest not yet created

> **Estimate**: 2-3 hours

## Context

**GDD**: `design/gdd/class-system.md`
**Requirement**: AC.4.1-4.6 (class change execution)

**ADR Governing Implementation**: ADR-001: Event Architecture
**Engine**: Godot 4.6.2 | **Risk**: LOW

---

## Acceptance Criteria

- [ ] AC.4.1: After class change, attribute V and potential P are completely preserved
- [ ] AC.4.2: After class change, new class experience resets to 0
- [ ] AC.4.3: After class change, other class experiences (if any) are preserved
- [ ] AC.4.4: New class stat bonuses apply immediately after change
- [ ] AC.4.5: Class change triggers threshold reward check (re-evaluate attribute thresholds)
- [ ] AC.4.6: Class change emits `class_changed(character_id, old_class, new_class)` signal via GameEvents

---

## Implementation Notes

From GDD C.4: Class change is a transactional operation — all effects apply atomically. The `class_changed` signal notifies skill system (unlock/lock class skills) and equipment system (revalidate equipment feasibility). The signal must contain enough context for consumers to react without additional queries.

---

## Out of Scope

- Story 005: Stat bonus calculation details
- Skill system response to class_changed (skill epic)
- Equipment revalidation logic (equipment epic)
- UI for class change confirmation screen

---

## QA Test Cases

- **AC.4.1**: Attributes preserved
  - Given: Warrior with STR=52, AGI=45, all potentials intact
  - When: Class change to Swordmaster executes
  - Then: STR=52, AGI=45, all potentials unchanged

- **AC.4.2**: New class exp resets
  - Given: Warrior with 600 warrior exp
  - When: Class change to Swordmaster
  - Then: Swordmaster exp = 0

- **AC.4.3**: Other class exp preserved
  - Given: Character with warrior exp=800
  - When: Class change to Swordmaster
  - Then: Warrior exp still = 800 (not reset)

- **AC.4.4**: Bonuses apply immediately
  - Given: Character with base STR=52 (no warrior bonus), changes to Swordmaster (+15 STR bonus)
  - When: Reading effective STR after class change
  - Then: Effective STR = 52 + 15 = 67

- **AC.4.6**: Signal emitted
  - Given: Character id=5 changes from BASIC_WARRIOR to ADV_SWORDMASTER
  - When: Class change executes
  - Then: GameEvents.class_changed emitted with (5, "BASIC_WARRIOR", "ADV_SWORDMASTER")

---

## Test Evidence

**Story Type**: Logic
**Required evidence**: `tests/unit/class/class_change_test.gd` — must exist and pass
**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: Story 001 (state machine), Story 002 (CAN_UNLOCK validation)
- Unlocks: Skill system and equipment system can respond to class_changed signal
