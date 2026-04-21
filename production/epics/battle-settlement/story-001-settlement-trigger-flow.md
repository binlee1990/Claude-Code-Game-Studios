# Story 001: Settlement Trigger & Flow

> **Epic**: Battle Settlement
> **Status**: Ready
> **Layer**: Feature
> **Type**: Logic
> **Manifest Version**: N/A — manifest not yet created

> **Estimate**: 2-3 hours

## Context

**GDD**: `design/gdd/battle-settlement.md`
**Requirement**: AC.1.1-1.3 (victory/defeat/retreat settlement triggers)

**ADR Governing Implementation**: ADR-001 (Event Architecture)
**Engine**: Godot 4.6.2 | **Risk**: LOW

---

## Acceptance Criteria

- [ ] AC.1.1: Victory (all enemies HP=0) triggers victory settlement with full rewards
- [ ] AC.1.2: Defeat (all allies HP=0) triggers defeat settlement (no EXP, no gold, small material reward)
- [ ] AC.1.3: Retreat triggers retreat settlement (treated as defeat)

---

## Implementation Notes

From GDD C.1: Settlement triggered by combat flow end conditions. Victory: full reward pipeline (EXP, gold, materials, evaluation). Defeat: 0 EXP, 0 gold, small material reward, no achievement trigger. Retreat = defeat. Settlement produces a result struct used by downstream systems.

---

## Out of Scope

- Reward calculation details (Stories 002-004)
- Settlement UI display
- Combat flow state machine (turn-based epic)

---

## QA Test Cases

- **AC.1.1**: Victory settlement
  - Given: All enemy units dead, 3 player units alive
  - When: Settlement triggered
  - Then: Result type = victory, reward pipeline activated
  - Edge cases: Last enemy killed by counterattack → still victory

- **AC.1.2**: Defeat settlement
  - Given: All player units dead
  - When: Settlement triggered
  - Then: Result type = defeat, EXP=0, gold=0, small material reward
  - Edge cases: Last player dies and last enemy dies same action → victory (enemies checked first)

- **AC.1.3**: Retreat settlement
  - Given: Player initiates retreat
  - When: Settlement triggered
  - Then: Result type = retreat, treated identically to defeat
  - Edge cases: Retreat not available (no retreat skill/item) → cannot trigger

---

## Test Evidence

**Story Type**: Logic
**Required evidence**: `tests/unit/settlement/settlement_trigger_test.gd`
**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: None (receives combat result from turn-based epic)
- Unlocks: Stories 002-005
