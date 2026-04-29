# Story 004: HP 系统 — 伤害 / 治疗 / 死亡链

> **Epic**: Unit
> **Status**: Ready
> **Layer**: Core
> **Type**: Logic
> **Manifest Version**: N/A

## Context

**GDD**: `design/gdd/unit.md`
**Requirement**: `TR-unit-004`, `TR-unit-005`

**ADR Governing Implementation**: ADR-0003: Unit Public Interface Contract
**ADR Decision Summary**: Unit 暴露 `take_damage(amount: int)` 为唯一的 HP 写入入口——amount 必须 >0，已死亡单位立即返回。`hp = clamp(hp - amount, 0, max_hp)`。当 hp 达 0 时发出 `unit_died` 信号（仅一次，在 queue_free() 之前）。`heal(amount)` 预留但 MVP 未接入。只读属性（atk/def/mov/rng/max_hp/faction）通过 setter 断言守卫。

**Engine**: Godot 4.6.2-stable | **Risk**: LOW

---

## Acceptance Criteria

- [ ] **AC-C8 — 死亡链**: hp=1 的 Unit 受到 take_damage(3)→hp=0、unit_died 恰好发出一次、Map 移除占用、随后 queue_free()。
- [ ] **AC-F1 — take_damage clamp + 死亡守卫**: hp=8 max_hp=10, take_damage(5)→hp=3。hp=3 时 take_damage(12)→hp=0 + unit_died。hp=0 时 take_damage(any)→立即返回，不发出信号。
- [ ] **AC-F2 — is_alive / is_dead**: hp=5→is_alive() true, is_dead() false。hp=0→相反。hp=1 存活；hp=0 死亡。
- [ ] **AC-F3 — clamp_hp 强制执行**: hp=8 max_hp=10, heal(5)→hp=10（已封顶）。任何 HP 修改后 hp∈[0, max_hp]。
- [ ] **AC-F5 — heal() 预留**: heal(amount: int) 方法存在（实现 `hp = clamp(hp+amount, 0, max_hp)`），但 MVP 无调用者。
- [ ] **AC-E1 — 只读属性守卫**: 外部代码尝试设置 atk/def/mov/rng/max_hp/faction → 断言失败。
- [ ] **AC-E2 — 负/零伤害拒绝**: take_damage(0) 或 take_damage(-3) → 断言 "amount must be > 0"。

---

## Implementation Notes

```gdscript
signal unit_died(unit: Unit)

var hp: int
var max_hp: int
var is_alive: bool:
    get: return hp > 0

func take_damage(amount: int) -> void:
    assert(amount > 0, "amount must be > 0")
    if not is_alive:
        return
    hp = clampi(hp - amount, 0, max_hp)
    if hp == 0:
        unit_died.emit(self)
        queue_free()

func heal(amount: int) -> void:
    assert(amount > 0, "amount must be > 0")
    if not is_alive:
        return
    hp = clampi(hp + amount, 0, max_hp)

# Read-only property guards (example)
func set_atk(_v: int) -> void: assert(false, "atk is read-only")
func set_faction(_v: Faction.Type) -> void: assert(false, "faction is read-only")
```

- `unit_died` 信号在 `queue_free()` 之前发出，确保监听方（Map 移除占用、Victory 重新计数）在节点销毁前完成处理
- `clampi()` 是 Godot 4 的整数 clamp（`@GlobalScope.clampi`）

---

## Out of Scope

- Story 001: UnitStats .tres 加载
- Story 002: 视觉更新（HPLabel 文字更新在 take_damage 内调用 _update_visual()）
- Story 003: 状态机守卫（take_damage 可能与 action_state 交互——若需"仅 IDLE/SELECTED/MOVED 可受伤"，由本 Story 实现）

---

## QA Test Cases

- **AC-F1**: take_damage 边界值
  - Given: hp=8, max_hp=10
  - When: take_damage(5)
  - Then: hp==3
  - When: take_damage(12)
  - Then: hp==0, unit_died 信号发出
  - Edge cases: hp=0 后 take_damage(99)→立即返回，信号不再次发出

- **AC-F3**: heal 封顶
  - Given: hp=8, max_hp=10
  - When: heal(5)
  - Then: hp==10（非 13）
  - Edge cases: 对已死亡单位 heal(5)→立即返回，hp 保持 0

- **AC-E2**: 负伤害断言
  - Given: is_alive=true
  - When: take_damage(-3)
  - Then: assert(false), hp 不变
  - Edge cases: take_damage(0)→同断言失败

---

## Test Evidence

**Story Type**: Logic
**Required evidence**: `tests/unit/unit/unit_hp_test.gd` — must exist and pass

**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: Story 001（UnitStats——需要 max_hp）、Story 003（公共接口——is_alive getter 和信号定义）
- Unlocks: Movement/Attack Epics（下游系统通过 take_damage 消费 HP）
