# Story 006: Class Save/Load Integration

> **Epic**: Class System
> **Status**: Ready
> **Layer**: Core
> **Type**: Integration
> **Manifest Version**: N/A — manifest not yet created

> **Estimate**: 2-3 hours

## Context

**GDD**: `design/gdd/class-system.md`
**Requirement**: AC.7.1-7.3 (persistence)

**ADR Governing Implementation**: ADR-001 (Event Architecture), ADR-003 (Save System)
**Engine**: Godot 4.6.2 | **Risk**: LOW

---

## Acceptance Criteria

- [ ] AC.7.1: Class state, current class_id, all class experiences, and unlocked class list correctly saved and restored
- [ ] AC.7.2: Player's decision to NOT change class is recorded (class_choice_recorded flag)
- [ ] AC.7.3: After load, class state machine resumes from correct state with all data intact

---

## Implementation Notes

From ADR-003: Extend UnitSaveData with class-specific fields: current_class_id, class_state, class_experiences (Dictionary of class_id → exp), unlocked_classes (Array), threshold_flags, choice_records. AttributeComponent serialization pattern from Story 007 of attribute-system epic provides the template.

---

## Out of Scope

- Save UI (save/load screens)
- Auto-save triggering

---

## QA Test Cases

- **AC.7.1**: Full class state round-trip
  - Given: Character as ADV_SWORDMASTER, warrior_exp=800, swordmaster_exp=350, state=ADVANCED_ACTIVE
  - When: Save → Load
  - Then: All values match exactly
  - Edge cases: Character with multiple class experiences preserved

- **AC.7.2**: Decision record persistence
  - Given: Character eligible for class change but chose to stay (class_choice_recorded=TRUE)
  - When: Save → Load
  - Then: class_choice_recorded=TRUE restored correctly

- **AC.7.3**: State machine resumption
  - Given: Character in SPECIAL_ACTIVE state with dragon knight class
  - When: Save → Load
  - Then: State = SPECIAL_ACTIVE, class_id = SPC_DRAGONKNIGHT, no transitions possible

---

## Test Evidence

**Story Type**: Integration
**Required evidence**: `tests/integration/class/save_load_integration_test.gd` — must exist and pass
**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: Stories 001-005 (all class state must be defined before serialization)
- attribute-system Story 007 (save/load pattern reference)
