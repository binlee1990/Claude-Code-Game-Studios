# Story 004: Combat Flow State Machine

> **Epic**: Turn-Based Mode
> **Status**: Complete
> **Layer**: Core
> **Type**: Logic
> **Manifest Version**: N/A — manifest not yet created

> **Estimate**: 2-3 hours

## Context

**GDD**: `design/gdd/turn-based-mode.md`
**Requirement**: C.4 (battle flow, end conditions, state transitions)

**ADR Governing Implementation**: ADR-001 (Event Architecture), ADR-002 (Scene Management)
**Engine**: Godot 4.6.2 | **Risk**: LOW

---

## Acceptance Criteria

- [ ] AC-F1: Combat flow follows: init → generate order → loop actions → check end → next unit
- [ ] AC-F2: Victory when all enemy units HP=0
- [ ] AC-F3: Defeat when all player units HP=0
- [ ] AC-F4: Unit killed mid-action → action interrupted immediately

---

## Implementation Notes

From GDD C.4: Flow = init units → sort by AGI → loop: current unit acts → check end conditions → next unit. End conditions: all enemies dead = victory, all allies dead = defeat. From E.2: Unit killed mid-action → action interrupted, killer gets kill reward. From E.4: All units unable to act → draw (no rewards, no penalty).

---

## Out of Scope

- Battle scene setup/teardown (ADR-002 scene management)
- Reward calculation (resource economy epic)
- Victory/defeat UI screens

---

## QA Test Cases

- **AC-F1**: Full combat flow
  - Given: 2 player units, 2 enemy units
  - When: Combat starts
  - Then: Init → sort → unit 1 acts → check end → unit 2 acts → ... → victory/defeat
  - Edge cases: Single unit on each side → 2-unit flow

- **AC-F2**: Victory condition
  - Given: Last enemy unit HP reduced to 0
  - When: End condition checked
  - Then: Combat ends with victory result
  - Edge cases: Multiple enemies die in same AoE → still victory

- **AC-F3**: Defeat condition
  - Given: Last player unit HP reduced to 0
  - When: End condition checked
  - Then: Combat ends with defeat result

- **AC-F4**: Mid-action kill
  - Given: Unit A is acting, counterattack kills Unit A
  - When: Kill registered
  - Then: Unit A's action interrupted, turn passes to next unit
  - Edge cases: Chain kill (AoE kills acting unit) → same interrupt

---

## Test Evidence

**Story Type**: Logic
**Required evidence**: `tests/unit/turn/combat_flow_test.gd`
**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: Stories 001-003 (turn order, actions, movement)
- Unlocks: Stories 005-007 (auto-battle, speed-up, save/load)
