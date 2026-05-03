# 敌人数据库 (Enemy Database)

> **Status**: Approved
> **Author**: binlee1990 + agents
> **Last Updated**: 2026-05-04
> **Implements Pillar**: 4.10 数据驱动与可扩展 · 4.7 子玩法服务主循环
> **Design Review (lean)**: APPROVED 2026-05-04 — required sections, dependency references, acceptance criteria, and cross-GDD contracts checked in this cleanup pass.

## Summary

敌人数据库是所有敌人模板的只读注册表。它从配置表读取敌人属性、等级、标签、掉落表和区域归属，并为战斗计算器、半自动战斗和区域系统提供稳定的 enemy definition。

> **Quick reference** — Layer: `Feature` · Priority: `MVP` · Key deps: `数据配置系统, 属性系统`

## Overview

敌人数据库把"一个区域会遇到什么怪"从代码中移到数据表。它不执行战斗，不决定掉落结果，也不持有战斗中的当前血量；它只定义敌人模板和实例化所需数据。MVP 需要它来支撑简单自动战斗、区域推进和离线战斗模拟：三者必须消费同一套敌人属性，否则在线/离线战斗会出现结果漂移。

## Player Fantasy

玩家感受到的是每张地图都有不同的修行阻力：新手区的小妖容易清，下一张图的精怪明显更硬但掉落更好。敌人数据库本身不可见，但它让世界层级有了稳定的"怪物生态"，避免所有挂机图只是换了名字的收益表。

## Detailed Design

### Core Rules

1. `EnemyDatabase` 是只读服务，启动时通过 `DataConfig.get_all("enemies")` 加载。
2. 每条 enemy definition 包含：`id`、`name`、`level`、`attribute_set`、`base_attributes`、`loot_table_id`、`zone_tags`、`combat_tags`、`weight`。
3. 属性字段必须能映射到 AttributeSystem 的 MVP 6 属性：`hp_max/atk/def/spd/crit_rate/crit_dmg`。
4. `create_combat_snapshot(enemy_id, instance_id)` 返回战斗用快照；MVP 不把敌人的实时 HP 注册到 AttributeSystem，CombatCalculator 使用战斗局部状态处理当前血量。
5. 本系统不产生随机选择；区域系统根据 enemy ids 和 weights 决定候选池，RNG 由调用方使用。
6. 热重载只允许 debug build；重载后新战斗使用新数据，已进行战斗不被改写。

### States and Transitions

| State | Entry Condition | Exit Condition | Behavior |
|-------|----------------|----------------|----------|
| Unloaded | 服务创建未加载 | `load_all` 完成 | 查询返回空并警告 |
| Loaded | 至少尝试加载一次 | debug reload | 正常只读查询 |
| Degraded | 表缺失或部分记录非法 | 配置修复后 reload | 跳过非法敌人，保留合法敌人 |

### Interactions with Other Systems

| System | Interface | Contract |
|--------|-----------|----------|
| 数据配置系统 | `get_all("enemies")` | 原始敌人定义来源 |
| 属性系统 | attribute id schema | 敌人 base_attributes 必须使用合法属性 |
| 区域系统 | `get_by_zone_tag`, `get(enemy_id)` | 区域构建敌人池 |
| 战斗计算器 | combat snapshot | 使用敌人属性参与战斗公式 |
| 掉落系统 | `loot_table_id` | 战斗胜利后查掉落表 |
| 离线战斗模拟系统 | deterministic definitions | 离线批量模拟使用同一敌人模板 |

## Formulas

The `enemy_power_score` formula is defined as:

`enemy_power_score = (hp_max * 0.35 + atk * 8 + def * 5) * (1 + crit_rate * (crit_dmg - 1)) * spd_factor`

**Variables:**
| Variable | Symbol | Type | Range | Description |
|----------|--------|------|-------|-------------|
| hp_max | H | BigNumber | 1-1e12 | 敌人生命上限 |
| atk | A | BigNumber | 1-1e12 | 敌人攻击 |
| def | D | BigNumber | 0-1e12 | 敌人防御 |
| crit_rate | C | float | 0-1 | 暴击率 |
| crit_dmg | M | float | 1-100 | 暴击倍率 |
| spd_factor | S | float | 0.5-5.0 | `sqrt(spd / 10)` clamped |

**Output Range:** 1 to very large BigNumber-like score for sorting; not player-facing.
**Example:** H=100, A=10, D=5, crit=0.05, crit_dmg=1.5, spd_factor=1 → score 141.0。

## Edge Cases

- **If enemy id is missing**: return empty definition and let caller choose fallback behavior.
- **If `loot_table_id` is missing**: enemy can fight but drops no loot; log warning.
- **If attributes omit a required MVP field**: fill defensive defaults only in debug fixtures; production data should fail validation and skip record.
- **If enemy level is below 1**: clamp to 1 and warn.
- **If zone references an enemy that failed loading**: zone system drops that entry from the pool and reports degraded zone data.

## Dependencies

| System | Direction | Nature |
|--------|-----------|--------|
| 数据配置系统 | Upstream | Loads `enemies` table |
| 属性系统 | Upstream | Defines legal attribute ids and ranges |
| 战斗计算器 | Downstream | Consumes combat snapshots |
| 区域系统 | Downstream | Consumes enemy pools |
| 掉落系统 | Downstream | Consumes loot table references |

## Tuning Knobs

| Parameter | Current Value | Safe Range | Effect of Increase | Effect of Decrease |
|-----------|--------------|------------|-------------------|-------------------|
| `MAX_ENEMIES_PER_ZONE` | 8 | 1-30 | More variety | Easier balancing |
| `enemy_power_weight_hp` | 0.35 | 0.1-2.0 | Values tankiness more | Values damage more |
| `enemy_power_weight_atk` | 8.0 | 1-50 | Values burst threat more | Values survival more |
| `ALLOW_DEGRADED_LOAD` | true | bool | Game boots with partial data | Catches data issues earlier |

## Visual/Audio Requirements

No direct assets. Enemy names, portraits, hit sounds, and VFX are consumed by battle/HUD systems from future art data fields.

## UI Requirements

Debug UI should list loaded enemies, level, power score, loot table id, and zone tags. Player-facing enemy inspection belongs to HUD/combat log.

## Cross-References

| This Document References | Target GDD | Specific Element Referenced | Nature |
|--------------------------|-----------|-----------------------------|--------|
| Attribute ids | `design/gdd/attribute-system.md` | MVP 6 attributes | Rule dependency |
| Data loading | `design/gdd/data-config-system.md` | `enemies` table | Data dependency |
| Combat consumer | `design/gdd/combat-calculator.md` | combat snapshot input | Data dependency |

## Acceptance Criteria

- **GIVEN** `enemies` table contains three valid records, **WHEN** EnemyDatabase loads, **THEN** `get_count() == 3`.
- **GIVEN** enemy has all MVP attributes, **WHEN** `create_combat_snapshot`, **THEN** snapshot contains hp_max, atk, def, spd, crit_rate, crit_dmg.
- **GIVEN** enemy has invalid attribute id, **WHEN** loading, **THEN** that record is skipped and warning includes the id.
- **GIVEN** zone tag `starter`, **WHEN** `get_by_zone_tag("starter")`, **THEN** only enemies tagged starter are returned.
- **GIVEN** debug reload changes enemy atk, **WHEN** new combat snapshot is created, **THEN** it uses the updated value.
