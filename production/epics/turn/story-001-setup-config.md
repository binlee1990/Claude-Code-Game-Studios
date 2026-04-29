# Story 001: TurnManager 初始化 + TurnConfig

> **Epic**: Turn System
> **Status**: Ready
> **Layer**: Core
> **Type**: Logic
> **Manifest Version**: N/A

## Context

**GDD**: `design/gdd/turn.md`
**Requirement**: `TR-turn-001`, `TR-turn-006`

**ADR Governing Implementation**: ADR-0004: Turn System Architecture
**ADR Decision Summary**: TurnManager 为 RefCounted（非 Node/非 Autoload），通过 DI 接收 units、turn_config、victory_checker。PLAYER 先手，turn_number 从 1 起。TurnConfig.tres 为数据驱动 Resource（turn_cap [1,99]，默认 30）。start_match() 以空单位数组调用→立即平局；二次调用→push_error 拒绝；null 依赖→assert 失败。

**Engine**: Godot 4.6.2-stable | **Risk**: LOW
**Engine Notes**: RefCounted、Resource、assert() 自 4.0 起稳定。TurnConfig 使用 `class_name TurnConfig extends Resource` + `@export var turn_cap: int = 30`。

---

## Acceptance Criteria

- [ ] **AC-TURN-015 — PLAYER 先手**: start_match(units) → active_faction=PLAYER, turn_number=1。
- [ ] **AC-TURN-016 — RefCounted + DI**: TurnManager extends RefCounted，无 Autoload，依赖通过构造/方法注入。
- [ ] **AC-TURN-009 — Config 默认值**: TurnConfig.tres turn_cap=30（默认）。
- [ ] **AC-TURN-010 — turn_cap 范围验证**: turn_cap 在 [1,99] 外 → assert 失败；比赛不启动。
- [ ] **AC-TURN-046 — 空单位数组**: start_match([]) → 一帧内 MATCH_ENDED，winner=NONE。
- [ ] **AC-TURN-047 — 二次 start_match 拒绝**: current_state!=MATCH_NOT_STARTED → push_error + 无状态变更。
- [ ] **AC-TURN-048 — TurnConfig null**: turn_config==null → start_match() assert 失败。
- [ ] **AC-TURN-049 — VictoryChecker null**: victory_checker==null → start_match() assert 失败。

---

## Implementation Notes

```gdscript
# assets/data/turn_config.tres
[resource]
script = preload("res://src/turn/turn_config.gd")
turn_cap = 30

# src/turn/turn_config.gd
class_name TurnConfig extends Resource
const VALID_RANGE := [1, 99]
@export var turn_cap: int = 30:
    set(v):
        assert(v >= VALID_RANGE[0] and v <= VALID_RANGE[1],
            "TurnConfig: turn_cap=%d not in [%d,%d]" % [v, VALID_RANGE[0], VALID_RANGE[1]])
        turn_cap = v

# src/turn/turn_manager.gd
class_name TurnManager extends RefCounted
var turn_config: TurnConfig
var victory_checker: RefCounted  # VictoryChecker
var current_state: TurnState = TurnState.MATCH_NOT_STARTED
var active_faction: Faction.Type
var turn_number: int = 1
var _all_units: Array[Unit] = []

func start_match(units: Array[Unit]) -> void:
    assert(current_state == TurnState.MATCH_NOT_STARTED, "start_match() called while match already in progress")
    assert(turn_config != null, "TurnConfig is null")
    assert(victory_checker != null, "VictoryChecker is null")
    _all_units = units.duplicate()
    current_state = TurnState.FACTION_PHASE_ACTIVE
    active_faction = Faction.Type.PLAYER
    turn_number = 1
    # ... signal emission (Story 004)
```

---

## Test Evidence

**Story Type**: Logic
**Required evidence**: `tests/unit/turn/turn_setup_test.gd`

**Status**: [ ] Not yet created

## Dependencies

- Depends on: Map Epic、Unit Epic（需要 Faction.Type enum + Unit 类定义）
- Unlocks: Story 002（状态机）、Story 003（Match End）、Story 004（信号）
