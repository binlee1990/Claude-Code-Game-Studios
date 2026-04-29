# Story 002: 射程检查 + AttackRangeResolver

> **Epic**: Attack | **Status**: Ready | **Layer**: Feature | **Type**: Logic

## Context
**GDD**: `design/gdd/attack.md` | **Requirement**: `TR-atk-002`, `TR-atk-004`
**ADR**: ADR-0007: Attack System | **Engine**: Godot 4.6.2 | **Risk**: LOW

## Acceptance Criteria
- [ ] Manhattan 距离射程检查：`|r1-r2| + |c1-c2| ≤ unit.rng`
- [ ] RNG=1→仅邻接；RNG=2→2 格内；超出射程→目标不可攻击
- [ ] AttackRangeResolver.get_valid_targets(unit, units, map)→按距离排序的 Array[Unit]
- [ ] 过滤：仅敌方 + 存活 + 在射程内
- [ ] 射程=0 无有效目标（退化）

## Implementation Notes
```gdscript
class_name AttackRangeResolver extends RefCounted
func get_valid_targets(attacker: Unit, all_units: Array[Unit], map: Map) -> Array[Unit]:
    var targets: Array[Unit] = []
    for u in all_units:
        if u.faction == attacker.faction or not u.is_alive: continue
        if manhattan(attacker.grid_position, u.grid_position) <= attacker.rng:
            targets.append(u)
    targets.sort_custom(func(a,b): return manhattan(attacker.grid_position, a.grid_position) < manhattan(attacker.grid_position, b.grid_position))
    return targets
```

## Test Evidence: `tests/unit/attack/attack_range_test.gd`
## Dependencies: Story 001（damage formula）、Movement Epic（manhattan）
