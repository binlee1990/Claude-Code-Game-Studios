# Story 002: VictoryChecker — 回合上限 + 存活数判定

> **Epic**: Victory | **Status**: Ready | **Layer**: Feature | **Type**: Logic

## Context
**GDD**: `design/gdd/victory.md` | **Requirement**: `TR-vic-002`, `TR-vic-005`
**ADR**: ADR-0009: Victory System | **Engine**: Godot 4.6.2 | **Risk**: LOW

## Acceptance Criteria
- [ ] determine_winner() 三参数接口（units, turn_number, turn_cap）正确
- [ ] turn_number > turn_cap→回合上限触发
- [ ] 回合上限下存活数比较：PLAYER 多→PLAYER 胜；ENEMY 多→ENEMY 胜
- [ ] 存活数相等→winner=NONE（平局/DRAW）
- [ ] reason="turn_cap" 仅在回合上限路径中返回
- [ ] 歼灭条件优先于回合上限（reason="elimination" 而非 "turn_cap"）

## Implementation Notes
```gdscript
func determine_winner(units: Array[Unit], turn_number: int, turn_cap: int) -> Dictionary:
    # ... 先检查 elimination（见 Story 001）
    if turn_number > turn_cap:
        var p_alive := _alive_count(units, Faction.Type.PLAYER)
        var e_alive := _alive_count(units, Faction.Type.ENEMY)
        if p_alive > e_alive: return {"winner": Faction.Type.PLAYER, "reason": "turn_cap"}
        if e_alive > p_alive: return {"winner": Faction.Type.ENEMY, "reason": "turn_cap"}
        return {"winner": Faction.Type.NONE, "reason": "turn_cap"}  # DRAW
    return {"winner": Faction.Type.NONE, "reason": ""}
```

## Test Evidence: `tests/unit/victory/victory_turn_cap_test.gd`
## Dependencies: Story 001（基础 VictoryChecker）、Turn Epic（turn_number/turn_cap）
