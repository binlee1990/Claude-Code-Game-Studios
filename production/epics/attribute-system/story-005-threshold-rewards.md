# Story 005: Threshold Rewards

> **Epic**: Attribute & Growth System
> **Status**: Complete
> **Layer**: Core
> **Type**: Logic
> **Manifest Version**: N/A — manifest not yet created

> **Estimate**: 2-3 hours

## Context

**GDD**: `design/gdd/attribute-growth-system.md`
**Requirement**: AC-9 (threshold trigger), AC-10 (no repeat), AC-15 (hidden attrs excluded)

**ADR Governing Implementation**: ADR-001: Event Architecture
**ADR Decision Summary**: Threshold reward events should be emitted as blocking signals. Downstream systems (skill, class) listen for these events.

**Engine**: Godot 4.6.2 | **Risk**: LOW

---

## Acceptance Criteria

- [ ] AC-9.1: When any normal attribute (STR/AGI/CON/INT/CHA) first reaches threshold 50/100/150, a reward event is triggered
- [ ] AC-9.2: Reward event includes character_id, attribute_name, and threshold level
- [ ] AC-10.1: Same character + same attribute + same threshold never triggers twice (first_reach flag)
- [ ] AC-15.1: Hidden attributes (LUK/WIL/RES/SOU) reaching any threshold do NOT trigger reward events

---

## Implementation Notes

From GDD C.5:
- Only normal attributes trigger rewards in MVP
- Each character tracks which threshold levels they've reached per attribute (first_reach tracking)
- Reward event is "blocking" — UI pauses to ensure player notices
- The REWARD CONTENT is defined by downstream systems (class/skill); this story only handles the TRIGGER

---

## Out of Scope

- Actual reward content (defined by class/skill systems)
- UI display of reward popup (UI epic)
- Reward event consumer logic (downstream systems)

---

## QA Test Cases

- **AC-9.1**: Threshold triggers at 50/100/150
  - Given: Character with STR V=49
  - When: STR increases to 50 (via level-up or other means)
  - Then: Threshold reward event fires for STR at threshold 50
  - Edge cases: V jumping from 48 to 52 (crosses 50) — still triggers at 50

- **AC-9.2**: Event includes correct context
  - Given: Character id=5, INT reaches 100 for first time
  - When: Threshold reward event fires
  - Then: Event contains {character_id: 5, attribute: "INT", threshold: 100}

- **AC-10.1**: No repeat trigger
  - Given: Character with STR already triggered at 50 (first_reach=FALSE)
  - When: STR value changes but remains >= 50
  - Then: No reward event fires
  - Edge cases: STR drops below 50 then rises back — still no repeat (first_reach is permanent)

- **AC-15.1**: Hidden attributes excluded
  - Given: Character with LUK V=50
  - When: LUK reaches 50 for first time
  - Then: No reward event fires
  - Edge cases: LUK at 100, 150 — no events for any threshold

---

## Test Evidence

**Story Type**: Logic
**Required evidence**: `tests/unit/attributes/threshold_rewards_test.gd` — must exist and pass
**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: Story 001 (data model), Story 002 (growth triggers threshold checks)
- Unlocks: None (threshold events are consumed by downstream systems)

## Completion Notes

**Completed**: 2026-04-22
**Criteria**: 4/4 passing (all auto-verified)
**Deviations**: None
**Test Evidence**: Logic — `tests/unit/attributes/threshold_rewards_test.gd` (11 test functions)
**Code Review**: Skipped (Solo mode)
