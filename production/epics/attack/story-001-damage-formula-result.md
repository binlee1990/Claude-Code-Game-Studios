# Story 001: 伤害公式 + AttackResult

> **Epic**: Attack | **Status**: Ready | **Layer**: Feature | **Type**: Logic

## Context
**GDD**: `design/gdd/attack.md` | **Requirement**: `TR-atk-001`, `TR-atk-005`, `TR-atk-007`
**ADR**: ADR-0007: Attack System | **Engine**: Godot 4.6.2 | **Risk**: LOW

## Acceptance Criteria
- [ ] 伤害公式 `damage = max(atk - def, 1)` 正确（最小伤害=1）
- [ ] ATK=5, DEF=2 → damage=3；ATK=5, DEF=7 → damage=1（最小伤害守卫）
- [ ] AttackResult 不可变数据对象（attacker, target, damage, lethal）
- [ ] resolve_damage(atk, def) 静态方法供 UI 预览
- [ ] 伤害≥目标 HP→lethal=true

## Implementation Notes
```gdscript
class_name AttackResult extends RefCounted
var attacker: Unit; var target: Unit; var damage: int; var lethal: bool

static func resolve_damage(atk: int, def: int) -> int:
    return maxi(atk - def, 1)

func execute(attacker: Unit, target: Unit) -> AttackResult:
    var dmg := resolve_damage(attacker.atk, target.def)
    target.take_damage(dmg)
    return AttackResult.new(attacker, target, dmg, dmg >= target.hp)
```

## Test Evidence: `tests/unit/attack/attack_damage_test.gd`
## Dependencies: Map Epic、Unit Epic（atk/def/hp/take_damage）
