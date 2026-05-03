# 掉落系统 (Loot System)

> **Status**: Approved
> **Author**: binlee1990 + agents
> **Last Updated**: 2026-05-04
> **Implements Pillar**: 4.3 刷宝提供惊喜 · 4.10 数据驱动与可扩展
> **Design Review (lean)**: APPROVED 2026-05-04 — required sections, dependency references, acceptance criteria, and cross-GDD contracts checked in this cleanup pass.

## Summary

掉落系统把战斗胜利、区域和敌人掉落表转化为资源/物品奖励包。MVP 只处理资源材料、灵石、药材和战斗经验，不生成复杂装备实例。

> **Quick reference** — Layer: `Feature` · Priority: `MVP` · Key deps: `敌人数据库, 物品/材料系统, 随机数与种子系统`

## Overview

掉落系统是第一条刷宝闭环的奖励裁决者。半自动战斗告诉它"玩家击败了某个敌人"，它读取该敌人的掉落表，用可复现 RNG 结算掉落，验证 item id 是否存在于物品/材料系统，然后返回一个 reward bundle。MVP 中 reward bundle 主要写入 ResourceSystem：`exp`、`lingshi`、`herb`。未来装备、词条、法宝可以接入同一套 loot table 结构，但不进入 MVP。

## Player Fantasy

玩家期待的是"每轮自动战斗都有可能带回东西"。早期掉落不需要复杂，但必须可靠：打怪会给经验，偶尔给药材或灵石，离线回来能看到清楚的收益来源。这个系统给刷宝惊喜打基础，先让小奖励可信，再给未来稀有装备留空间。

## Detailed Design

### Core Rules

1. `LootSystem` 接收 `DropContext`：`enemy_id`、`zone_id`、`combat_result`、`seed_context`、`bonus_tags`。
2. 掉落表从 `loot_tables` 配置读取；enemy definition 通过 `loot_table_id` 指向表。
3. MVP 支持三种 entry type：`resource`、`material`、`currency`；它们最终都以 `{resource_id, amount}` 写入 reward bundle。
4. 每条掉落 entry 包含：`item_id/resource_id`、`weight`、`chance`、`min_qty`、`max_qty`、`tags`、`first_clear_only`。
5. RNG 必须通过 Random Seed System 提供，不调用全局随机。
6. 本系统不直接写资源；半自动战斗、离线战斗模拟或离线结算负责把 reward bundle 应用到 ResourceSystem。
7. 发出 `loot.dropped` 事件用于日志/HUD，payload 包含 bundle 摘要，不包含内部 RNG 状态。

### States and Transitions

| State | Entry Condition | Exit Condition | Behavior |
|-------|----------------|----------------|----------|
| Ready | 配置加载成功 | reload/failure | 正常结算 |
| Degraded | 掉落表缺失或部分 item 无效 | 配置修复 | 返回空 bundle 或跳过无效 entry |
| Settling | 一次掉落结算中 | 结算完成 | 不允许重入修改同一上下文 |

### Interactions with Other Systems

| System | Interface | Contract |
|--------|-----------|----------|
| 敌人数据库 | `loot_table_id` | 指向掉落表 |
| 物品/材料系统 | `has_item/get` | 验证奖励 id 和显示名 |
| 随机数与种子系统 | `roll(seed_context)` | 可复现掉落 |
| 资源系统 | reward bundle consumer | 本系统不直接入账 |
| 半自动战斗系统 | `roll_drops(context)` | 在线战斗胜利后调用 |
| 离线战斗模拟系统 | batch roll or expected roll | 离线使用相同表和 RNG policy |
| HUD/战斗日志 | `loot.dropped` event | 展示掉落摘要 |

## Formulas

The `drop_success` formula is defined as:

`drop_success = random_0_1 < chance * drop_rate_multiplier`

**Variables:**
| Variable | Symbol | Type | Range | Description |
|----------|--------|------|-------|-------------|
| random_0_1 | r | float | [0,1) | RNG 输出 |
| chance | C | float | 0-1 | entry 基础概率 |
| drop_rate_multiplier | M | float | 0-100 | 区域/活动/未来装备掉落倍率，MVP 默认 1 |

**Output Range:** boolean.
**Example:** r=0.24, chance=0.30, M=1 → success true。

The `drop_quantity` formula is defined as:

`drop_quantity = floor(lerp(min_qty, max_qty, random_0_1))`

**Variables:**
| Variable | Symbol | Type | Range | Description |
|----------|--------|------|-------|-------------|
| min_qty | Qmin | int | 0-1e9 | 最小数量 |
| max_qty | Qmax | int | Qmin-1e9 | 最大数量 |
| random_0_1 | r | float | [0,1) | RNG 输出 |

**Output Range:** min_qty to max_qty.
**Example:** min 1, max 3, r=0.7 → 2。

## Edge Cases

- **If enemy has no loot table**: return empty bundle and log warning.
- **If chance is 0**: never drops; if chance >=1, always drops after multiplier clamp.
- **If min_qty > max_qty**: swap values in debug mode and warn; production data should fail validation.
- **If item id is unknown to ItemRegistry**: skip entry and emit a data warning.
- **If RNG seed context is missing**: use a deterministic fallback seed derived from combat id and mark bundle as degraded.

## Dependencies

| System | Direction | Nature |
|--------|-----------|--------|
| 敌人数据库 | Upstream | Supplies `loot_table_id` |
| 物品/材料系统 | Upstream | Validates reward ids |
| 随机数与种子系统 | Upstream | Supplies deterministic randomness |
| 半自动战斗系统 | Downstream | Requests online drops |
| 离线战斗模拟系统 | Downstream | Requests batch drops |
| HUD 系统 | Downstream | Displays `loot.dropped` |

## Tuning Knobs

| Parameter | Current Value | Safe Range | Effect of Increase | Effect of Decrease |
|-----------|--------------|------------|-------------------|-------------------|
| `base_exp_per_enemy` | table-driven | 1-1e9 | Faster leveling | Slower leveling |
| `base_lingshi_chance` | 0.25 | 0-1 | More currency flow | More scarcity |
| `base_herb_chance` | 0.10 | 0-1 | More crafting material | More material bottleneck |
| `MAX_DROPS_PER_KILL` | 5 | 1-20 | Richer rewards | Simpler logs/performance |

## Visual/Audio Requirements

No direct assets. HUD/combat log should distinguish common resource drops from notable drops; future rare drops should trigger stronger visual/audio feedback.

## UI Requirements

Reward bundle must expose display-ready item ids, quantities, rarity, and source enemy/zone so battle log and offline settlement can summarize rewards.

## Cross-References

| This Document References | Target GDD | Specific Element Referenced | Nature |
|--------------------------|-----------|-----------------------------|--------|
| Item validation | `design/gdd/item-material-system.md` | `has_item`, rarity enum | Data dependency |
| RNG determinism | `design/gdd/random-seed-system.md` | seeded roll policy | Rule dependency |
| Loot event | `design/gdd/event-bus.md` | `loot.dropped` | State trigger |

## Acceptance Criteria

- **GIVEN** enemy with loot table containing exp chance 1.0, **WHEN** drops roll after victory, **THEN** bundle includes exp.
- **GIVEN** fixed seed and same DropContext, **WHEN** roll runs twice, **THEN** both bundles are identical.
- **GIVEN** entry references unknown item id, **WHEN** roll runs, **THEN** that entry is skipped and valid entries still settle.
- **GIVEN** max drops per kill is 5, **WHEN** table has 20 successful entries, **THEN** output is capped deterministically to 5 entries.
- **GIVEN** bundle has any reward, **WHEN** roll completes, **THEN** one `loot.dropped` event is emitted.
