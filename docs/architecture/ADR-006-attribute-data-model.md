# ADR-006: Attribute Data Model

## Status

Accepted

## Date

2026-04-23

## Decision Makers

技术总监

## Summary

属性数据模型采用 Resource 类封装，9 维属性（5 普通 + 4 隐藏）各维护独立的属性值 (V) 和潜质值 (P)。属性数据作为只读数据源向所有下游系统提供查询接口。果子系统和壁障突破作为属性修改器，通过事件通知变更。

## Engine Compatibility

| Field | Value |
|-------|-------|
| **Engine** | Godot 4.6.2 |
| **Domain** | Core / Data |
| **Knowledge Risk** | LOW — Resource 和 Dictionary 是 Godot 核心机制 |
| **References Consulted** | `docs/engine-reference/godot/` |
| **Post-Cutoff APIs Used** | None |
| **Verification Required** | 属性成长公式 + 果子使用 + 壁障突破 端到端测试 |

## ADR Dependencies

| Field | Value |
|-------|-------|
| **Depends On** | ADR-001 (事件架构), ADR-003 (存档系统) |
| **Enables** | ADR-004 (Combat), class-system, skill-system, equipment-system |
| **Blocks** | 所有依赖属性数据的系统 |
| **Ordering Note** | 属性系统是最基础的 Gameplay 数据层，需最先实现 |

## Context

### Problem Statement

SRPG 所有系统（职业、战斗、AI、装备、技能）都依赖角色属性数据。属性系统必须：提供统一查询接口、支持果子/壁障/门槛三种修改机制、确保属性变更可追溯（事件通知）、与存档系统集成。

### Current State

`src/core/attributes/` 中已有实现。本 ADR 规范化数据模型。

### Constraints

- 属性值为整数 [0, 999]
- 潜质值为枚举 [E, D, C, B, A, S] 对应 [1, 2, 3, 4, 5, 6]
- 成长无 RNG（第一周目确定成长）
- 属性系统是只读数据源（下游系统不直接修改属性）

### Requirements

- 9 维属性结构
- 果子系统（消耗果子提升潜质）
- 壁障突破（阈值 + 资源消耗）
- 门槛奖励（属性达到特定值触发奖励）
- 属性碾压（差距超过阈值触发效果）
- 存档持久化

## Decision

### 数据模型

```gdscript
class_name AttributeData
extends Resource

const NORMAL_ATTRS := ["strength", "agility", "physique", "intelligence", "charisma"]
const HIDDEN_ATTRS := ["luck", "willpower", "anomaly_resist", "soul_strength"]
const POTENTIAL_MAP := {E=1, D=2, C=3, B=4, A=5, S=6}

@export var values: Dictionary  # attr_name → int [0, 999]
@export var potentials: Dictionary  # attr_name → int [1, 6]
@export var barrier_broken: Dictionary  # attr_name → bool
```

### 成长公式

```
V_new = V_old + P_current
```

- 每次升级，每个属性增加对应潜质值
- 潜质不因升级改变（仅果子改变潜质）

### 果子系统

```
fruit_use(unit, attr, fruit_id):
    P_new = min(P_old + fruit_bonus, S)  # 最高 S 级
    emit attribute_potential_changed(unit, attr, P_old, P_new)
```

### 壁障突破

```
barrier_check(unit, attr):
    threshold = get_barrier_threshold(attr)  # 从配置读取
    if V[attr] >= threshold and not barrier_broken[attr]:
        if has_required_resource(unit):
            consume_resource(unit)
            barrier_broken[attr] = true
            emit barrier_broken(unit, attr)
```

### 门槛奖励

```
threshold_check(unit, attr):
    for reward in threshold_rewards[attr]:
        if V[attr] >= reward.threshold and not reward.claimed:
            reward.claimed = true
            apply_reward(unit, reward)
            emit threshold_reward(unit, attr, reward)
```

### 属性碾压

```
crush_check(attacker_attr, defender_attr):
    diff = attacker_attr - defender_attr
    if diff >= CRUSH_THRESHOLD:  # 配置值
        return CRUSH_DAMAGE_MULTIPLIER  # 配置值
    return 1.0
```

### 存档集成

属性数据通过 ADR-003 的 `UnitSaveData.attributes` 和 `UnitSaveData.potential` 持久化。

## Alternatives Considered

### Alternative 1: 每属性独立 Resource

- **Rejection Reason**: 9 个独立 Resource 管理开销过大，Dictionary 足够

### Alternative 2: 原生数组存储

- **Rejection Reason**: 可读性差，Dictionary 允许按属性名直接查询

## Consequences

### Positive

- Resource 封装直接与存档系统集成
- 事件驱动通知所有下游
- 配置驱动的阈值和奖励

### Negative

- Dictionary 类型在 GDScript 中不如强类型安全
- 潜质枚举需要手动映射

## Risks

| Risk | Probability | Impact | Mitigation |
|------|------------|--------|------------|
| 属性成长不平衡 | 高 | 高 | 所有成长参数外部配置 |
| 壁障阈值过难过易 | 中 | 中 | Tuning Knobs 可调 |
| 果子资源过度集中 | 中 | 中 | 果子获取量可配 |

## Performance Implications

| Metric | Budget | Notes |
|--------|--------|-------|
| 属性查询 | <0.01ms | Dictionary lookup |
| 升级成长计算 | <0.1ms | 9 次加法 |

## Validation Criteria

- [ ] 9 维属性初始化正确
- [ ] 成长公式 `V_new = V_old + P` 验证
- [ ] 果子使用提升潜质，上限 S
- [ ] 壁障突破在阈值触发
- [ ] 门槛奖励在属性达标触发
- [ ] 属性碾压效果正确计算
- [ ] 存档/读档属性数据完整恢复

## GDD Requirements Addressed

| GDD Document | Requirement | How Addressed |
|-------------|-------------|---------------|
| attribute-growth-system.md | 5普通+4隐藏属性 | NORMAL_ATTRS + HIDDEN_ATTRS |
| attribute-growth-system.md | 果子系统 | fruit_use() |
| attribute-growth-system.md | 壁障突破 | barrier_check() |
| attribute-growth-system.md | 门槛奖励 | threshold_check() |
| attribute-growth-system.md | 属性碾压 | crush_check() |
| class-system.md | 属性门槛解锁职业 | 查询 values[attr] |
| equipment-system.md | 装备需求/加成 | 查询 + 修改 values |
| ai-system.md | AI 引用属性 | 只读查询 |

## Related

- ADR-001: 事件架构 (attribute_changed 信号)
- ADR-003: 存档系统 (UnitSaveData)
- ADR-004: Combat System (伤害计算引用属性)

## Acceptance History

| Field | Value |
|-------|-------|
| **Accepted on** | 2026-04-26 |
| **Accepted via** | Sprint-002 governance closure |
| **Reason** | 12 epic Complete 引用本 ADR，需消除合规绕过风险 |
