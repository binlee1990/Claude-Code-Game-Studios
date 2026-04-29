# Story 003: Match End + VictoryChecker 集成

> **Epic**: Turn System
> **Status**: Ready
> **Layer**: Core
> **Type**: Logic
> **Manifest Version**: N/A

## Context

**GDD**: `design/gdd/turn.md`
**Requirement**: `TR-turn-004`, `TR-turn-009`, `TR-turn-010`

**ADR Governing Implementation**: ADR-0004: Turn System Architecture
**ADR Decision Summary**: FACTION_PHASE_ENDING 序列评估两条件: faction_eliminated (任意阵营 alive_count==0) 和 turn_cap_reached (turn_number > turn_cap)。歼灭立即路由到 MATCH_ENDED。歼灭优先于回合上限。end_reason 的单一真相来源为 VictoryChecker.determine_winner(units, turn_number, turn_cap)→{winner, reason}。回合仅在 ENEMY 阶段结束后递增。

**Engine**: Godot 4.6.2-stable | **Risk**: LOW

---

## Acceptance Criteria

- [ ] **AC-TURN-014** — 歼灭立即 MATCH_ENDED（跳过剩余未行动单位）
- [ ] **AC-TURN-025** — F4: faction_eliminated → should_end_match=true, reason="elimination"
- [ ] **AC-TURN-026** — F4: turn_cap_reached → should_end_match=true, reason="turn_cap"
- [ ] **AC-TURN-027** — 歼灭优先于回合上限（同时成立→"elimination"）
- [ ] **AC-TURN-028** — 两条件均不满足→继续下一阵营
- [ ] **AC-TURN-022** — turn_cap=30, turn_number=30, ENEMY 结束→turn_cap_reached=true
- [ ] **AC-TURN-036** — ENDING→MATCH_ENDED（歼灭路由）
- [ ] **AC-TURN-037** — ENDING→MATCH_ENDED（回合上限路由）
- [ ] **AC-TURN-051** — 最后未行动单位歼灭阵营→立即 MATCH_ENDED
- [ ] **AC-TURN-052** — turn_cap_reached+faction_eliminated 同时→歼灭胜出
- [ ] **AC-TURN-054** — turn_cap=1+空阵营→立即结束（歼灭优先）

---

## Implementation Notes

```gdscript
func _run_ending_sequence() -> void:
    # Step 1: reset entering faction units
    for unit in _all_units:
        if unit.faction == _next_faction() and unit.is_alive:
            unit.reset_action_state()

    # Step 2: increment turn (ENEMY phase only)
    var tc_reached := false
    if active_faction == Faction.Type.ENEMY:
        turn_number += 1
        tc_reached = turn_number > turn_config.turn_cap

    # Step 3: check elimination
    var fac_eliminated := _alive_count(Faction.Type.PLAYER) == 0 or _alive_count(Faction.Type.ENEMY) == 0

    # Step 4: route
    if fac_eliminated:
        _end_match("elimination")
    elif tc_reached:
        _end_match("turn_cap")
    else:
        active_faction = _next_faction()
        current_state = TurnState.FACTION_PHASE_ACTIVE
        faction_activated.emit(active_faction)

func _end_match(reason: String) -> void:
    var result = victory_checker.determine_winner(_all_units, turn_number, turn_config.turn_cap)
    current_state = TurnState.MATCH_ENDED
    match_ended.emit(result.reason, result.winner)

func _alive_count(faction: Faction.Type) -> int:
    var count := 0
    for unit in _all_units:
        if unit.faction == faction and unit.is_alive:
            count += 1
    return count
```

---

## Test Evidence

**Story Type**: Logic
**Required evidence**: `tests/unit/turn/turn_match_end_test.gd`

**Status**: [ ] Not yet created

## Dependencies

- Depends on: Story 001（初始化）、Story 002（状态机——ENDING 序列在此 Story 中实现）
- Unlocks: Story 004（信号——match_ended 信号在此触发）
