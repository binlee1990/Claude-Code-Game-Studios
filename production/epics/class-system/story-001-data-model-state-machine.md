# Story 001: Class Data Model & State Machine

> **Epic**: Class System
> **Status**: Complete
> **Layer**: Core
> **Type**: Logic
> **Manifest Version**: N/A — manifest not yet created

> **Estimate**: 2-3 hours

## Context

**GDD**: `design/gdd/class-system.md`
**Requirement**: AC.1 (class state machine)

**ADR Governing Implementation**: ADR-001: Event Architecture
**ADR Decision Summary**: State changes communicated via GameEvents. Class data exposed through read-only interfaces.

**Engine**: Godot 4.6.2 | **Risk**: LOW

---

## Acceptance Criteria

- [ ] AC.1.1: New character enters BASIC_ACTIVE state, initialized as 战士 (BASIC_WARRIOR)
- [ ] AC.1.2: When CAN_UNLOCK conditions met for advanced class, state transitions to ADVANCED_UNLOCKED
- [ ] AC.1.3: On player confirming class change, state transitions from ADVANCED_UNLOCKED to ADVANCED_ACTIVE
- [ ] AC.1.4: When achievement points sufficient for special class, ADVANCED_ACTIVE transitions to SPECIAL_UNLOCKED
- [ ] AC.1.5: On special class activation, state transitions to SPECIAL_ACTIVE (terminal — no further transitions)

---

## Implementation Notes

From ADR-001: Use enum for CharacterClassState. Expose current state via read-only getter. State transitions are validated — invalid transitions are rejected silently.

From GDD C.1: Three-tier architecture with 6 basic, 6 advanced, 3 special classes. Class IDs are enum constants (BASIC_WARRIOR, ADV_SWORDMASTER, SPC_DRAGONKNIGHT etc.).

---

## Out of Scope

- Story 002: CAN_UNLOCK formula (this story only checks current state)
- Story 004: Class change execution logic
- Story 007: UI for class screen

---

## QA Test Cases

- **AC.1.1**: Initial state
  - Given: A new character is created
  - When: Reading class state
  - Then: State = BASIC_ACTIVE, class_id = BASIC_WARRIOR
  - Edge cases: Verify all 6 basic classes can be initial (future expansion)

- **AC.1.2**: Advanced unlock transition
  - Given: Character in BASIC_ACTIVE with CAN_UNLOCK = TRUE for an advanced class
  - When: Unlock check triggers
  - Then: State transitions to ADVANCED_UNLOCKED
  - Edge cases: Multiple advanced classes unlockable simultaneously — state still ADVANCED_UNLOCKED

- **AC.1.3**: Class change confirmation
  - Given: Character in ADVANCED_UNLOCKED state
  - When: Player confirms class change
  - Then: State transitions to ADVANCED_ACTIVE with new class_id
  - Edge cases: Player chooses to stay — state remains BASIC_ACTIVE (decision recorded)

- **AC.1.4**: Special unlock
  - Given: Character in ADVANCED_ACTIVE with achievement points >= SPC_COST
  - When: Special class conditions met
  - Then: State transitions to SPECIAL_UNLOCKED

- **AC-1.5**: Terminal state
  - Given: Character in SPECIAL_ACTIVE
  - When: Any class change attempt
  - Then: State remains SPECIAL_ACTIVE, transition rejected
  - Edge cases: No path back from terminal state

---

## Test Evidence

**Story Type**: Logic
**Required evidence**: `tests/unit/class/state_machine_test.gd` — must exist and pass
**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: attribute-system Epic (reads attribute values for unlock checks)
- Unlocks: Story 002, 003, 004, 005, 006
