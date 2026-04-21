# ADR-001: 事件架构

## Status

Accepted

## Date

2026-04-20

## Last Verified

2026-04-20

## Decision Makers

技术总监

## Summary

游戏各系统通过Godot信号（Signal）进行解耦通信，采用去中心化事件总线模式，避免单点故障和中央总线瓶颈。信号作为系统间唯一耦合点，实现"发布-订阅"解耦。

## Engine Compatibility

| Field | Value |
|-------|-------|
| **Engine** | Godot 4.6.2 |
| **Domain** | Scripting / Core |
| **Knowledge Risk** | LOW — 信号系统是Godot核心机制，文档完善 |
| **References Consulted** | `docs/engine-reference/godot/` |
| **Post-Cutoff APIs Used** | None |
| **Verification Required** | None |

## ADR Dependencies

| Field | Value |
|-------|-------|
| **Depends On** | None |
| **Enables** | ADR-002 (场景管理), ADR-003 (存档系统) |
| **Blocks** | 所有GDD系统实现 |
| **Ordering Note** | 最先实现的ADR，所有其他系统基于此架构 |

## Context

### Problem Statement

游戏有23个独立系统（属性、战斗、AI、羁绊、装备等），这些系统需要相互通信但不能形成紧耦合。紧耦合会导致：修改一个系统影响其他系统、难以独立测试、难以扩展。

### Current State

项目初期，无现有实现。需要从零建立通信规范。

### Constraints

- Godot 4.6.2的信号系统是核心语言特性
- GDScript单线程执行，无需考虑线程安全
- 需要支持编辑器内信号调试

### Requirements

- 系统间通信必须解耦
- 信号必须可追踪、可调试
- 必须支持编辑器和运行时两种调试模式
- 性能开销必须<0.1ms/信号发送

## Decision

### 架构：去中心化信号总线

```
[GameEvents (Autoload)]
    │
    ├── signal health_changed(unit_id: int, old_hp: int, new_hp: int)
    ├── signal unit_died(unit_id: int)
    ├── signal skill_executed(unit_id: int, skill_id: String)
    ├── signal item_equipped(unit_id: int, item_id: String, slot: String)
    ├── signal buff_added(unit_id: int, buff_id: String)
    ├── signal buff_removed(unit_id: int, buff_id: String)
    ├── signal turn_started(unit_id: int)
    ├── signal turn_ended(unit_id: int)
    └── signal battle_started(battle_id: String)
    └── signal battle_ended(battle_id: String, victory: bool)
    └── signal game_saved(slot: int)
    └── signal game_loaded(slot: int)

[各系统]
    ├── PlayerStats — 发出 health_changed, unit_died
    ├── SkillSystem — 监听 health_changed, 发出 skill_executed
    ├── CombatSystem — 监听 skill_executed, unit_died, 发出 turn_started, turn_ended, battle_started, battle_ended
    ├── EquipmentSystem — 监听 unit_died, 发出 item_equipped
    ├── BuffSystem — 监听 item_equipped, 发出 buff_added, buff_removed
    └── SaveSystem — 监听所有持久化相关信号, 发出 game_saved, game_loaded
```

### 核心原则

1. **Autoload单例承载全局信号** — `GameEvents.gd`作为全局事件总线
2. **系统只发出自己领域的信号** — 不代理其他系统的信号
3. **信号参数包含充分上下文** — 让监听者无需查询即可决策
4. **避免信号嵌套** — 信号处理器中禁止发出同一总线的其他信号
5. **信号命名：snake_case + 过去式** — `health_changed`, `unit_died`

### 信号设计规范

```gdscript
# GameEvents.gd (Autoload)
extends Node

# 战斗相关
signal battle_started(battle_id: String, map_id: String, difficulty: int)
signal battle_ended(battle_id: String, victory: bool, battle_stats: Dictionary)
signal turn_started(actor_id: int, turn_number: int)
signal turn_ended(actor_id: int)

# 单位相关
signal unit_spawned(unit_id: int, unit_type: String, position: Vector2i)
signal unit_died(unit_id: int, killer_id: int)
signal unit_revived(unit_id: int)

# 属性相关
signal health_changed(unit_id: int, old_value: int, new_value: int, cause: String)
signal mana_changed(unit_id: int, old_value: int, new_value: int)
signal attribute_changed(unit_id: int, attribute: String, old_value: float, new_value: float)

# 技能相关
signal skill_executed(unit_id: int, skill_id: String, target_ids: Array[int])
signal skill_learned(unit_id: int, skill_id: String)
signal skill_forgotten(unit_id: int, skill_id: String)

# 装备相关
signal item_equipped(unit_id: int, item_id: String, slot: String, previous_item: String)
signal item_unequipped(unit_id: int, item_id: String, slot: String)

# 羁绊相关
signal bond_level_up(unit_id: int, partner_id: int, old_level: int, new_level: int)
signal bond_effect_triggered(unit_id: int, partner_id: int, effect_type: String)

# 资源相关
signal resource_changed(resource_type: String, old_value: int, new_value: int)
signal item_acquired(item_id: String, quantity: int, source: String)

# 存档相关
signal game_saved(slot: int, timestamp: int)
signal game_loaded(slot: int)
```

### 监听器规范

```gdscript
# 正确的监听方式
func _ready() -> void:
    GameEvents.health_changed.connect(_on_health_changed)

func _on_health_changed(unit_id: int, old_hp: int, new_hp: int, cause: String) -> void:
    if unit_id == player_id and new_hp <= 0:
        _trigger_death_sequence()

# 禁止在信号处理器中发出其他信号（防止嵌套）
func _on_health_changed(unit_id: int, old_hp: int, new_hp: int, cause: String) -> void:
    # 错误示例：这里发出signal会导致嵌套
    # GameEvents.unit_died.emit(unit_id)  # 禁止！
    pass
```

## Alternatives Considered

### Alternative 1: 中央EventBus单例

- **Description**: 创建一个中央EventBus类，所有事件通过它转发
- **Pros**: 便于集中调试，可以添加事件过滤
- **Cons**: 增加一层间接调用，中央单例成为瓶颈
- **Estimated Effort**: 低
- **Rejection Reason**: Godot已有信号系统，中央EventBus是重复造轮子

### Alternative 2: 直接方法调用

- **Description**: 系统间直接调用对方方法
- **Pros**: 简单直接，性能最高
- **Cons**: 紧耦合，修改A系统可能影响B系统
- **Estimated Effort**: 零
- **Rejection Reason**: 紧耦合违背可维护性要求

## Consequences

### Positive

- 系统完全解耦，可独立测试
- 信号命名规范统一，便于grep搜索
- Godot原生调试器支持信号追踪

### Negative

- 信号链追踪需要跨文件阅读
- 信号参数变更需要同步所有监听者

### Neutral

- 需要维护信号列表文档

## Risks

| Risk | Probability | Impact | Mitigation |
|------|------------|--------|------------|
| 信号未文档化 | 中 | 高 | 在GameEvents.gd中强制docstring |
| 循环信号依赖 | 低 | 高 | 代码审查检查信号处理器中的信号发出 |

## Performance Implications

| Metric | Before | Expected After | Budget |
|--------|--------|---------------|--------|
| CPU (frame time) | N/A | <0.1ms/signal | <0.1ms |
| Memory | N/A | <1KB/信号类型 | <1KB |

## Migration Plan

1. 创建`GameEvents.gd` Autoload
2. 将所有跨系统信号迁移至GameEvents
3. 更新所有监听器引用
4. 删除旧的事件调用

**Rollback plan**: 回退到GameEvents.emit()调用，信号作为内部实现

## Validation Criteria

- [ ] GameEvents.gd存在且为Autoload
- [ ] 所有跨系统信号定义在GameEvents中
- [ ] 所有系统通过GameEvents通信，无直接系统间引用（除明确的数据依赖）
- [ ] 信号处理器中无嵌套信号发出

## GDD Requirements Addressed

| GDD Document | System | Requirement | How This ADR Satisfies It |
|-------------|--------|-------------|--------------------------|
| 所有GDD | 所有系统 | 系统间必须解耦通信 | 信号总线实现发布-订阅解耦 |
| Foundational | Foundation | 所有GDD系统的基础通信机制 | 所有GDD系统依赖此架构 |

## Related

- ADR-002: 场景管理架构
- ADR-003: 存档系统架构
