# Story 001: UnitStats — 数据驱动属性 + .tres 校验

> **Epic**: Unit
> **Status**: Ready
> **Layer**: Core
> **Type**: Logic
> **Manifest Version**: N/A

## Context

**GDD**: `design/gdd/unit.md`
**Requirement**: `TR-unit-001`, `TR-unit-008`

**ADR Governing Implementation**: ADR-0003: Unit Public Interface Contract
**ADR Decision Summary**: Unit 的所有属性（HP/ATK/DEF/MOV/RNG）由外部 `UnitStats.tres` Resource 驱动。加载时 fail-fast 校验：超出范围的属性→`assert(false)`+文件名/属性名/值/范围；缺失/损坏的 .tres→错误+`queue_free()`。每个 Unit 独立持有可变 hp（构造时从 max_hp 复制），不共享 Resource 引用。

**Engine**: Godot 4.6.2-stable | **Risk**: LOW
**Engine Notes**: ResourceLoader.load() 自 4.0 起稳定。typed Resource 需 `class_name UnitStats extends Resource` 和 `@export var` 注解。

---

## Acceptance Criteria

- [ ] **AC-C1 — 属性数据驱动**: UnitStats.tres (max_hp=10, atk=5, def=2, mov=4, rng=1) 加载后 hp==10 且全部 5 项属性匹配 .tres。无硬编码默认值。
- [ ] **AC-C5 — .tres 实例隔离**: 两个 Unit 加载同一个 soldier.tres，Unit A take_damage(4) 后 hp 6，Unit B hp 仍为 10。
- [ ] **AC-F4 — .tres 校验**: atk=12（超出 [3,8]）→ 断言失败含文件名/属性/值/范围。缺失/损坏 .tres → 错误 + queue_free()。

---

## Implementation Notes

```gdscript
# assets/data/units/soldier.tres
[resource]
script = preload("res://src/core/unit_stats.gd")
unit_name = "Soldier"
max_hp = 10
atk = 5
def = 2
mov = 4
rng = 1

# src/core/unit_stats.gd
class_name UnitStats extends Resource

@export var unit_name: String = ""
@export var max_hp: int = 10
@export var atk: int = 5
@export var def: int = 2
@export var mov: int = 4
@export var rng: int = 1

const VALID_RANGES := {
    "max_hp": [5, 20],
    "atk": [3, 8],
    "def": [0, 5],
    "mov": [2, 6],
    "rng": [1, 3],
}

func validate() -> bool:
    for prop in VALID_RANGES:
        var value = get(prop)
        var range_arr = VALID_RANGES[prop]
        if value < range_arr[0] or value > range_arr[1]:
            assert(false, "UnitStats validation failed: %s=%d not in [%d,%d]" % [prop, value, range_arr[0], range_arr[1]])
            return false
    return true
```

- Unit._ready() 中：`stats = ResourceLoader.load(path) as UnitStats` → null check → `stats.validate()` → `hp = stats.max_hp`

---

## Out of Scope

- Story 002: Unit 场景结构（ColorRect + Label）、视觉表现
- Story 003: 公共接口、action_state 状态机、Faction enum
- Story 004: take_damage()/heal()/unit_died 信号

---

## QA Test Cases

- **AC-C1**: 属性从 .tres 加载
  - Given: soldier.tres (max_hp=10, atk=5, def=2, mov=4, rng=1)
  - When: Unit._ready() 加载此 .tres
  - Then: unit.hp==10, unit.max_hp==10, unit.atk==5, unit.def==2, unit.mov==4, unit.rng==1
  - Edge cases: 切换为 archer.tres (max_hp=7, rng=2) → 全部属性反映 archer 值

- **AC-C5**: 实例隔离
  - Given: 两个 Unit 加载同一 soldier.tres
  - When: unit_a.take_damage(4) → hp 10→6
  - Then: unit_b.hp==10（不受影响）
  - Edge cases: unit_a 死亡 → unit_b 仍存活，hp 不变

- **AC-F4**: 校验拒绝无效数据
  - Given: UnitStats.tres atk=12（超出 [3,8]）
  - When: stats.validate()
  - Then: assert(false)，消息含 "atk"、"12"、"[3,8]"
  - Edge cases: def=-1、mov=10 —— 各自触发所属属性的断言

---

## Test Evidence

**Story Type**: Logic
**Required evidence**: `tests/unit/unit/unit_stats_test.gd` — must exist and pass

**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: Map Epic Story 001（GridSpace — Unit 构造函数接收 GridSpace 用于 tile_center 放置）
- Unlocks: Story 002（场景结构）、Story 003（公共接口）、Story 004（HP 系统）
