# Story 001: VictoryChecker — 全灭判定

> **Epic**: Victory | **Status**: Ready | **Layer**: Feature | **Type**: Logic

## Context
**GDD**: `design/gdd/victory.md` | **Requirement**: `TR-vic-001`, `TR-vic-003`, `TR-vic-004`
**ADR**: ADR-0009: Victory System | **Engine**: Godot 4.6.2 | **Risk**: LOW

## Acceptance Criteria
- [ ] VictoryChecker 为 RefCounted 纯函数（零状态）
- [ ] determine_winner(units, turn_number, turn_cap)→{winner: Faction.Type, reason: String}
- [ ] 仅 PLAYER 存活→winner=PLAYER, reason="elimination"
- [ ] 仅 ENEMY 存活→winner=ENEMY, reason="elimination"
- [ ] 双方全灭→winner=PLAYER（fallback）, reason="elimination"
- [ ] 双方均有存活→winner=NONE（未结束）

## Implementation Notes
```gdscript
class_name VictoryChecker extends RefCounted
func determine_winner(units: Array[Unit], turn_number: int, turn_cap: int) -> Dictionary:
    var p_alive := _alive_count(units, Faction.Type.PLAYER)
    var e_alive := _alive_count(units, Faction.Type.ENEMY)
    if p_alive == 0 and e_alive == 0: return {"winner": Faction.Type.PLAYER, "reason": "elimination"}
    if p_alive == 0: return {"winner": Faction.Type.ENEMY, "reason": "elimination"}
    if e_alive == 0: return {"winner": Faction.Type.PLAYER, "reason": "elimination"}
    return {"winner": Faction.Type.NONE, "reason": ""}  # match continues
```

## Test Evidence: `tests/unit/victory/victory_elimination_test.gd`
## Dependencies: Unit Epic（faction/is_alive）
