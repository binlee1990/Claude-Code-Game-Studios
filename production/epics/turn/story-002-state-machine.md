# Story 002: 状态机核心 — 4 状态 + 5 转换

> **Epic**: Turn System
> **Status**: Ready
> **Layer**: Core
> **Type**: Logic
> **Manifest Version**: N/A

## Context

**GDD**: `design/gdd/turn.md`
**Requirement**: `TR-turn-002`, `TR-turn-003`, `TR-turn-007`

**ADR Governing Implementation**: ADR-0004: Turn System Architecture
**ADR Decision Summary**: 4 状态状态机: MATCH_NOT_STARTED → FACTION_PHASE_ACTIVE ⇄ FACTION_PHASE_ENDING → MATCH_ENDED。5 个转换: start→active、active→ending(auto/manual)、ending→active(continue)、ending→ended(elim/turn_cap)。end_current_faction_turn() 仅在 FACTION_PHASE_ACTIVE 中有效——其他状态静默忽略（重入守卫）。Auto-advance 条件: 活跃阵营所有存活单位 has_acted==true。

**Engine**: Godot 4.6.2-stable | **Risk**: LOW

---

## Acceptance Criteria

- [ ] **AC-TURN-032** — MATCH_NOT_STARTED → FACTION_PHASE_ACTIVE（start_match）
- [ ] **AC-TURN-033** — ACTIVE → ENDING（auto-advance: 全部已行动）
- [ ] **AC-TURN-034** — ACTIVE → ENDING（手动 end_turn）
- [ ] **AC-TURN-035** — ENDING → ACTIVE（下一阵营，无歼灭/无上限）
- [ ] **AC-TURN-038** — MATCH_ENDED 不接受任何转换（终态吸收）
- [ ] **AC-TURN-001** — 阵营轮转: PLAYER→ENEMY→PLAYER
- [ ] **AC-TURN-002** — 零单位阵营不跳过（空真 auto-advance）
- [ ] **AC-TURN-005** — 最后一个单位行动后 auto-advance 触发
- [ ] **AC-TURN-006** — 空真 auto-advance（存活单位数=0→立即 ENDING）
- [ ] **AC-TURN-007** — 手动 End Turn 放弃剩余行动
- [ ] **AC-TURN-008** — End Turn 重入守卫（ENDING/MATCH_ENDED 中静默忽略）
- [ ] **AC-TURN-011** — PLAYER 阶段结束不递增 turn_number
- [ ] **AC-TURN-012** — ENEMY 阶段结束后 turn_number+1
- [ ] **AC-TURN-013** — 死亡单位排除于 auto-advance 计数

---

## Implementation Notes

```gdscript
enum TurnState { MATCH_NOT_STARTED, FACTION_PHASE_ACTIVE, FACTION_PHASE_ENDING, MATCH_ENDED }

func end_current_faction_turn() -> void:
    if current_state != TurnState.FACTION_PHASE_ACTIVE:
        return  # reentrancy guard
    _transition_to_ending()

func _check_auto_advance() -> void:
    if current_state != TurnState.FACTION_PHASE_ACTIVE:
        return
    for unit in _all_units:
        if unit.faction == active_faction and unit.is_alive and not unit.has_acted_this_turn:
            return  # at least one alive unacted unit
    _transition_to_ending()

func _transition_to_ending() -> void:
    current_state = TurnState.FACTION_PHASE_ENDING
    faction_phase_ended.emit(active_faction)
    _run_ending_sequence()
```

---

## Test Evidence

**Story Type**: Logic
**Required evidence**: `tests/unit/turn/turn_state_machine_test.gd`

**Status**: [ ] Not yet created

## Dependencies

- Depends on: Story 001（初始化 + Config）
- Unlocks: Story 003（Match End）、Story 004（信号）
