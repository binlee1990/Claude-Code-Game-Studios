# Story 004: 信号发射 + AIController 接口

> **Epic**: Turn System
> **Status**: Ready
> **Layer**: Core
> **Type**: Logic
> **Manifest Version**: N/A

## Context

**GDD**: `design/gdd/turn.md`
**Requirement**: `TR-turn-005`, `TR-turn-008`

**ADR Governing Implementation**: ADR-0004: Turn System Architecture
**ADR Decision Summary**: TurnManager 发射 5 个信号: match_started、turn_started(N)、faction_activated(faction)、faction_phase_ended(faction)、match_ended(reason, winner)。AIController 接口槽位存在——ENEMY 阶段通过 faction_activated(ENEMY) 信号触发 MVP 热座模式（NullAI 返回空 ActionList）。延迟连接消费者通过只读属性(current_state/active_faction/turn_number)轮询初始化。

**Engine**: Godot 4.6.2-stable | **Risk**: LOW

---

## Acceptance Criteria

- [ ] **AC-TURN-039** — match_started 信号: start_match 后恰好发射一次
- [ ] **AC-TURN-040** — turn_started(N): 新 PLAYER 阶段开始时发射
- [ ] **AC-TURN-041** — faction_activated(faction): 阵营阶段开始转换完成时发射
- [ ] **AC-TURN-042** — faction_phase_ended(faction): ACTIVE→ENDING 转换时发射
- [ ] **AC-TURN-043** — match_ended("elimination", PLAYER): 歼灭结束
- [ ] **AC-TURN-044** — match_ended("turn_cap", winner): 回合上限结束
- [ ] **AC-TURN-045** — match_ended("elimination", NONE): 双方同时歼灭（平局）
- [ ] **AC-TURN-003** — 阶段开始时 has_acted 重置（Integration）
- [ ] **AC-TURN-053** — 延迟连接消费者轮询状态（Integration）
- [ ] **AIController 接口**: take_turn(units, world_state)→ActionList 方法签名存在; MVP NullAI 返回空 ActionList

---

## Implementation Notes

```gdscript
signal match_started()
signal turn_started(turn_number: int)
signal faction_activated(faction: Faction.Type)
signal faction_phase_ended(faction: Faction.Type)
signal match_ended(reason: String, winner: Faction.Type)

# In start_match():
    _reset_all_units()
    match_started.emit()
    turn_started.emit(turn_number)
    faction_activated.emit(active_faction)

# In _run_ending_sequence() continue branch:
    if active_faction == Faction.Type.PLAYER:
        turn_started.emit(turn_number)
    faction_activated.emit(active_faction)

# AIController interface (in AI Epic, referenced here)
# class_name AIController extends RefCounted
# func take_turn(units: Array[Unit], world_state: WorldState) -> ActionList:
#     return ActionList.new()  # NullAI default
```

- 信号发射顺序: match_started → turn_started(1) → faction_activated(PLAYER)
- 延迟连接: current_state/active_faction/turn_number 为公开只读属性

---

## Test Evidence

**Story Type**: Logic
**Required evidence**: `tests/unit/turn/turn_signals_test.gd`

**Status**: [ ] Not yet created

## Dependencies

- Depends on: Story 001（初始化）、Story 002（状态机）、Story 003（Match End——match_ended 信号在此实现）
- Unlocks: Movement/Attack/Victory/AI/UI Epics（全部通过 Turn 信号驱动）
