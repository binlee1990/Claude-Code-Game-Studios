# Story 003: 公共接口 + action_state 状态机 + Faction

> **Epic**: Unit
> **Status**: Ready
> **Layer**: Core
> **Type**: Logic
> **Manifest Version**: N/A

## Context

**GDD**: `design/gdd/unit.md`
**Requirement**: `TR-unit-002`, `TR-unit-003`, `TR-unit-007`, `TR-unit-009`

**ADR Governing Implementation**: ADR-0003: Unit Public Interface Contract
**ADR Decision Summary**: Unit 暴露面向 5 个下游系统的只读公共接口。action_state 为 5 状态机: IDLE→SELECTED→MOVED→ACTED→DEAD。Faction enum 位于独立文件 `src/core/faction.gd`。unit_id 使用单调递增计数器生成（"unit_0"、"unit_1"...），确保无冲突。has_acted_this_turn 由 reset_action_state() 重置（Turn System 在回合开始时调用）。

**Engine**: Godot 4.6.2-stable | **Risk**: LOW
**Engine Notes**: enum、static 计数器、状态机逻辑。零 post-cutoff API。

---

## Acceptance Criteria

- [ ] **AC-C3 — unit_id 单调递增**: 连续实例化 3 个 Unit → unit_id 依次为 "unit_0"、"unit_1"、"unit_2"，无冲突。
- [ ] **AC-C6 — grid_position 所属权**: unit.grid_position→Vector2i(2,3)（由 Map place_unit 设置）。Unit 不含像素运算——世界坐标通过 Map 推导。
- [ ] **AC-C7 — has_acted 生命周期**: 新 Unit→false。移动+攻击完成→true。reset_action_state()→false。
- [ ] **AC-S1 — can_be_selected**: alive AND faction==active_faction AND NOT has_acted AND action_state==IDLE → true。任一条件不满足 → false。
- [ ] **AC-S2 — can_move / can_attack**: SELECTED→can_move() true。SELECTED 或 MOVED + 敌方目标在 rng 范围→can_attack() true。同阵营目标 → false。
- [ ] **AC-S3 — reset_action_state 覆盖**: SELECTED/MOVED 状态→强制设为 IDLE。

---

## Implementation Notes

```gdscript
# src/core/faction.gd
class_name Faction

enum Type { PLAYER, ENEMY }
```

```gdscript
# Unit public interface (from ADR-0003)
var unit_id: String                        # "unit_N"
var unit_name: String                      # from UnitStats
var faction: Faction.Type                  # immutable after _ready()
var grid_position: Vector2i                # set by Map.place_unit()
var action_state: ActionState              # IDLE/SELECTED/MOVED/ACTED/DEAD
var has_acted_this_turn: bool              # reset by TurnManager

func can_be_selected(active_faction: Faction.Type) -> bool:
    return is_alive and faction == active_faction and not has_acted_this_turn and action_state == ActionState.IDLE

func can_move() -> bool:
    return action_state == ActionState.SELECTED

func can_attack(target: Unit) -> bool:
    return target != null and target.faction != faction and action_state in [ActionState.SELECTED, ActionState.MOVED]

func reset_action_state() -> void:
    action_state = ActionState.IDLE
    has_acted_this_turn = false
```

- unit_id 使用 `static var _next_id: int = 0` + `unit_id = "unit_%d" % _next_id; _next_id += 1`
- Faction enum 位于独立文件以支持 Tier 2 提取（零逻辑变更移动）

---

## Out of Scope

- Story 001: UnitStats .tres 加载
- Story 002: 场景结构、ColorRect、Label
- Story 004: take_damage()/heal()/unit_died 信号

---

## QA Test Cases

- **AC-C3**: unit_id 单调递增
  - Given: 无现有 Unit
  - When: Unit.new() × 3
  - Then: unit_a.unit_id=="unit_0"、unit_b=="unit_1"、unit_c=="unit_2"
  - Edge cases: 即使在同一帧内创建，所有 ID 仍唯一

- **AC-S1**: can_be_selected 完整条件
  - Given: is_alive=true, faction=PLAYER, has_acted=false, action_state=IDLE
  - When: can_be_selected(PLAYER)
  - Then: true
  - Edge cases: has_acted=true → false; action_state=ACTED → false; faction=ENEMY, active=PLAYER → false

- **AC-S3**: reset_action_state 覆盖
  - Given: action_state=SELECTED, has_acted=false
  - When: reset_action_state()
  - Then: action_state=IDLE, has_acted=false
  - Edge cases: MOVED→IDLE; ACTED→IDLE（回合转换覆盖一切进行中的动作）

---

## Test Evidence

**Story Type**: Logic
**Required evidence**: `tests/unit/unit/unit_interface_test.gd` — must exist and pass

**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: Story 001（UnitStats——需要 is_alive 判定）
- Unlocks: Story 004（HP 系统——take_damage 可能需要检查 action_state 守卫）
