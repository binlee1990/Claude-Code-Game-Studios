# 区域系统 (Zone System)

> **Status**: Approved
> **Author**: binlee1990 + agents
> **Last Updated**: 2026-05-04
> **Implements Pillar**: 4.2 放置不是无操作 · 4.7 子玩法服务主循环
> **Design Review (lean)**: APPROVED 2026-05-04 — required sections, dependency references, acceptance criteria, and cross-GDD contracts checked in this cleanup pass.

## Summary

区域系统定义挂机地图的静态数据：敌人池、掉落倍率、推荐等级、解锁条件和区域标签。它是战斗、挂机探索、地图推进和 HUD 当前区域显示的共同数据源。

> **Quick reference** — Layer: `Feature Integration` · Priority: `MVP` · Key deps: `敌人数据库, 数据配置系统`

## Overview

区域系统让"去哪里挂机"成为早期最重要的低频选择。区域不是单纯背景名，而是敌人强度、奖励结构、解锁门槛和产出倾向的集合。玩家换区时，半自动战斗获得新的敌人池，掉落系统获得区域上下文，HUD 展示风险和收益。MVP 至少需要 3 个普通挂机区域，对应 game-concept 的最小闭环。

## Player Fantasy

玩家感受到的是从村外小妖到更危险秘境的推进。每个新区域都意味着更高风险、更好收益和新的目标，而不是数字表里的下一行。

## Detailed Design

### Core Rules

1. `ZoneSystem` 从 `zones` 配置加载区域定义。
2. 每个 zone 包含：`id`、`name`、`order`、`recommended_level`、`unlock_conditions`、`enemy_pool`、`loot_modifiers`、`production_modifiers`、`tags`。
3. `enemy_pool` 只引用 EnemyDatabase 已加载 enemy id，并带 encounter weight。
4. `get_current_zone()` 返回玩家当前选择；实际存档由 SaveSystem provider 保存。
5. 区域系统不主动推进地图；地图推进系统负责解锁/完成状态。
6. 区域切换发布 `zone.changed`，payload 包含 old/new zone id。
7. 区域产出/掉落倍率通过上下文传给 OMS/LootSystem，不在本系统内部计算资源。

### States and Transitions

| State | Entry Condition | Exit Condition | Behavior |
|-------|----------------|----------------|----------|
| Locked | unlock 条件未满足 | MapProgression 解锁 | 不能选择 |
| Available | 已解锁未选择 | 玩家选择 | 可展示收益与风险 |
| Active | 当前挂机区域 | 玩家切换/区域失效 | 供战斗和探索消费 |
| Invalid | 配置缺敌人或非法 | 配置修复 | 不可选择，报告数据错误 |

### Interactions with Other Systems

| System | Interface | Contract |
|--------|-----------|----------|
| 数据配置系统 | `get_all("zones")` | 加载区域定义 |
| 敌人数据库 | enemy references | 验证敌人池 |
| 半自动战斗系统 | current enemy pool | 在线战斗选敌 |
| 挂机探索系统 | zone modifiers | 计算探索效率 |
| 地图推进系统 | lock/complete state | 决定是否可选 |
| HUD 系统 | current zone display | 显示区域名、推荐等级、收益倾向 |

## Formulas

The `zone_threat_score` formula is defined as:

`zone_threat_score = weighted_average(enemy_power_score, enemy_weight)`

**Variables:**
| Variable | Symbol | Type | Range | Description |
|----------|--------|------|-------|-------------|
| enemy_power_score | P_i | float | >=0 | EnemyDatabase 计算的敌人强度 |
| enemy_weight | W_i | float | >0 | 区域内遭遇权重 |

**Output Range:** 0 to high score; used for sorting and warnings.
**Example:** two enemies 100/200 with equal weights → 150。

The `zone_reward_bias` formula is defined as:

`zone_reward_bias(resource) = base_zone_multiplier(resource) * difficulty_bonus`

**Variables:**
| Variable | Symbol | Type | Range | Description |
|----------|--------|------|-------|-------------|
| base_zone_multiplier | B | float | 0-100 | 区域配置倍率 |
| difficulty_bonus | D | float | 1-10 | 高难区域奖励补偿 |

**Output Range:** 0 to 1000.
**Example:** herb base 1.5, difficulty 1.2 → 1.8。

## Edge Cases

- **If zone references missing enemy**: drop that enemy from pool and mark zone degraded.
- **If all enemies invalid**: zone state becomes Invalid and cannot be active.
- **If current active zone becomes locked after data reload**: move player to the highest available earlier zone.
- **If recommended level is missing**: derive from enemy average level and warn.
- **If loot modifier references unknown resource**: ignore that modifier and continue.

## Dependencies

| System | Direction | Nature |
|--------|-----------|--------|
| 敌人数据库 | Upstream | Enemy definitions and power score |
| 数据配置系统 | Upstream | Zone table |
| 地图推进系统 | Downstream | Unlock/completion state |
| 半自动战斗系统 | Downstream | Current enemy pool |
| HUD 系统 | Downstream | Current zone display |

## Tuning Knobs

| Parameter | Current Value | Safe Range | Effect of Increase | Effect of Decrease |
|-----------|--------------|------------|-------------------|-------------------|
| `MVP_ZONE_COUNT` | 3 | 3-10 | More early variety | Less content burden |
| `MAX_ENEMY_POOL_SIZE` | 8 | 1-30 | More varied encounters | Easier balance |
| `difficulty_bonus_per_order` | 0.15 | 0-1 | Stronger reward scaling | Flatter zones |
| `fallback_zone_id` | first zone | valid zone | Safer data reload | Stricter failures |

## Visual/Audio Requirements

Zone background thumbnails and ambient labels are desirable but not required for MVP. HUD should show region identity clearly.

## UI Requirements

Requires a zone picker/list with lock reason, recommended level, expected reward tags, current selection, and risk indicator.

## Cross-References

| This Document References | Target GDD | Specific Element Referenced | Nature |
|--------------------------|-----------|-----------------------------|--------|
| Enemy pool | `design/gdd/enemy-database.md` | enemy definitions | Data dependency |
| Unlock state | `design/gdd/map-progression-system.md` | zone unlocked/completed | State trigger |
| Battle consumption | `design/gdd/semi-auto-combat-system.md` | current zone enemy pool | Data dependency |

## Acceptance Criteria

- **GIVEN** three valid zone records, **WHEN** ZoneSystem loads, **THEN** all are queryable by id and sorted by order.
- **GIVEN** zone references a missing enemy but has other valid enemies, **WHEN** loaded, **THEN** zone remains available but degraded warning is recorded.
- **GIVEN** player selects an unlocked zone, **WHEN** selection succeeds, **THEN** `zone.changed` is emitted.
- **GIVEN** player tries to select locked zone, **WHEN** selection is attempted, **THEN** current zone does not change and lock reason is returned.
- **GIVEN** active zone has enemy weights, **WHEN** SemiAutoCombat requests pool, **THEN** pool contains only valid enemy ids and weights.
