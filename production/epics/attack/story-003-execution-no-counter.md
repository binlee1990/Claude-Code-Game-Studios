# Story 003: AttackResolver 执行 + 无反击 + 集成

> **Epic**: Attack | **Status**: Ready | **Layer**: Feature | **Type**: Integration

## Context
**GDD**: `design/gdd/attack.md` | **Requirement**: `TR-atk-003`, `TR-atk-006`
**ADR**: ADR-0007: Attack System | **Engine**: Godot 4.6.2 | **Risk**: LOW

## Acceptance Criteria
- [ ] AttackResolver 为 RefCounted 纯函数，无状态
- [ ] execute_attack(attacker, target)→AttackResult（含 damage+lethal）
- [ ] 攻击后 attacker.has_acted=true、action_state=ACTED
- [ ] 目标死亡→unit_died 信号发出、Map 占用清理
- [ ] MVP 无反击：counter_attack 信号槽位已预留（声明但不发射）
- [ ] 敌方死亡→单位数变化被 Turn System 正确消费

## Implementation Notes
```gdscript
class_name AttackResolver extends RefCounted
signal counter_attack(attacker: Unit, target: Unit)  # Reserved, not emitted in MVP

func execute_attack(attacker: Unit, target: Unit) -> AttackResult:
    var result := AttackResult.new()
    result.damage = AttackResult.resolve_damage(attacker.atk, target.def)
    result.lethal = result.damage >= target.hp
    target.take_damage(result.damage)
    attacker.has_acted_this_turn = true
    attacker.action_state = ActionState.ACTED
    return result
```

## Test Evidence: `tests/integration/attack/attack_execution_test.gd`
## Dependencies: Story 001+002、Unit Epic（take_damage/unit_died）、Map Epic（占用清理）
