# 半自动战斗系统 (Semi-Auto Combat System)

> **Status**: Approved
> **Author**: binlee1990 + agents
> **Last Updated**: 2026-05-04
> **Implements Pillar**: 4.2 放置不是无操作 · 4.3 刷宝提供惊喜 · 4.7 子玩法服务主循环
> **Design Review (lean)**: APPROVED 2026-05-04 — required sections, dependency references, acceptance criteria, and cross-GDD contracts checked in this cleanup pass.

## Summary

半自动战斗系统是在线刷怪循环的编排者。它选择当前区域敌人，调用战斗计算器结算，调用掉落系统生成奖励，并把经验/材料奖励交给资源和等级相关系统。

> **Quick reference** — Layer: `Feature Integration` · Priority: `MVP` · Key deps: `战斗计算器, 敌人数据库, 掉落系统, 等级系统`

## Overview

半自动战斗系统把"战斗计算"变成持续刷怪玩法。玩家不逐帧操作技能，而是选择区域和队伍配置后让系统自动遭遇、结算、拾取和进入下一轮。本系统不定义伤害公式，不定义敌人模板，不定义掉落概率；它只负责在线战斗生命周期、调用顺序和失败/冷却处理。离线战斗模拟必须复用同一 CombatCalculator 和 LootSystem 合同。

## Player Fantasy

玩家感受到的是"我的队伍在自动历练"。战斗日志不断滚动、偶尔掉落材料、经验条推进；玩家介入的时机是换区域、调整 Build、处理失败，而不是每秒点攻击。

## Detailed Design

### Core Rules

1. 玩家选择当前战斗区域后，系统进入 `Seeking`，从 ZoneSystem 敌人池中按权重选敌。
2. 生成 player/enemy combat snapshots，调用 `CombatCalculator.simulate_encounter`。
3. 胜利时调用 LootSystem，返回 reward bundle；再将 `exp` 交由 LevelSystem 相关路径处理或写入 ResourceSystem 后由 LevelSystem 消费。
4. 失败时不掉落，进入 cooldown，并向 HUD/瓶颈诊断暴露失败原因：伤害不足、防御不足、超时。
5. 背包/自动拾取 MVP 简化：所有 resource_material 直接进入 reward bundle，受 ResourceSystem/StorageLimit cap 约束。
6. 每场战斗发布 `combat.encounter_started`、`combat.encounter_finished` 事件。
7. 本系统不模拟离线时间；离线战斗模拟系统按相同接口批量调用。

### States and Transitions

| State | Entry Condition | Exit Condition | Behavior |
|-------|----------------|----------------|----------|
| Idle | 未选择区域或战斗暂停 | 选择有效区域 | 不生成遭遇 |
| Seeking | 有区域且可战斗 | 敌人选定 | 从区域敌人池取敌 |
| Resolving | 敌人和玩家快照已准备 | CombatResult 返回 | 调 CombatCalculator |
| Rewarding | 战斗胜利 | 奖励结算完成 | 调 LootSystem 并应用 bundle |
| Cooldown | 战斗失败或配置阻塞 | cooldown 结束/玩家换区 | 降低日志噪音，等待下一轮 |

### Interactions with Other Systems

| System | Interface | Contract |
|--------|-----------|----------|
| 区域系统 | current zone enemy pool | 提供敌人候选 |
| 敌人数据库 | enemy snapshot | 提供敌人属性和 loot table |
| 属性系统 | player snapshot | 读取玩家最终属性 |
| 战斗计算器 | `simulate_encounter` | 唯一战斗数学 |
| 掉落系统 | `roll_drops` | 胜利奖励 |
| 等级系统 | `gain_exp` path | 经验推进 |
| 战斗日志/HUD | combat events | 显示摘要 |

## Formulas

The `encounter_cycle_time` formula is defined as:

`encounter_cycle_time = combat_duration + reward_delay + next_encounter_delay`

**Variables:**
| Variable | Symbol | Type | Range | Description |
|----------|--------|------|-------|-------------|
| combat_duration | C | float | 0.1-120 | CombatResult 耗时 |
| reward_delay | R | float | 0-5 | 奖励展示/内部冷却 |
| next_encounter_delay | N | float | 0-10 | 下次遭遇间隔 |

**Output Range:** 0.1s to 135s.
**Example:** 8s combat + 0.5s reward + 1s delay → 9.5s。

The `online_reward_rate` formula is defined as:

`online_reward_rate = reward_per_win * win_rate / encounter_cycle_time`

**Variables:**
| Variable | Symbol | Type | Range | Description |
|----------|--------|------|-------|-------------|
| reward_per_win | W | BigNumber | >=0 | 单胜利平均奖励 |
| win_rate | P | float | 0-1 | 当前区域近期胜率 |
| encounter_cycle_time | T | float | >0 | 单轮周期 |

**Output Range:** 0 to high BigNumber per second.
**Example:** 10 exp, win_rate 1, cycle 10s → 1 exp/s。

## Edge Cases

- **If no valid current zone**: stay Idle and expose `no_zone_selected`.
- **If enemy pool is empty**: enter Cooldown with `zone_has_no_enemies`.
- **If CombatCalculator returns Invalid**: stop current encounter and report data issue.
- **If reward bundle contains capped resources**: ResourceSystem/OfflineSettlement reports actual vs lost; combat itself remains victory.
- **If player loses repeatedly**: after threshold, pause auto-advance and surface recommendation to change zone/build.

## Dependencies

| System | Direction | Nature |
|--------|-----------|--------|
| 战斗计算器 | Upstream | Combat result math |
| 敌人数据库 | Upstream | Enemy definitions |
| 掉落系统 | Upstream | Victory rewards |
| 等级系统 | Upstream/Downstream | Exp consumption and level events |
| 区域系统 | Upstream | Current zone enemy pool |
| HUD 系统 | Downstream | Battle status and log |

## Tuning Knobs

| Parameter | Current Value | Safe Range | Effect of Increase | Effect of Decrease |
|-----------|--------------|------------|-------------------|-------------------|
| `next_encounter_delay` | 1.0s | 0-10s | Slower farming, readable logs | Faster farming |
| `failure_cooldown_seconds` | 5.0s | 0-60s | Less repeated failure spam | Faster retry |
| `failure_pause_threshold` | 5 losses | 1-50 | More persistence | Earlier intervention |
| `reward_delay` | 0.5s | 0-3s | More readable feedback | Faster loop |

## Visual/Audio Requirements

Needs battle log entries, hit/crit indicators, victory/failure markers, and notable loot feedback. Actual assets and layout are owned by HUD/UI.

## UI Requirements

HUD must show current enemy, current zone, latest result, recent drops, and clear failure reason. Player controls: start/pause combat and change zone.

## Cross-References

| This Document References | Target GDD | Specific Element Referenced | Nature |
|--------------------------|-----------|-----------------------------|--------|
| Combat math | `design/gdd/combat-calculator.md` | CombatResult | Data dependency |
| Rewards | `design/gdd/loot-system.md` | reward bundle | Data dependency |
| Current area | `design/gdd/zone-system.md` | enemy pool | Data dependency |

## Acceptance Criteria

- **GIVEN** current zone has valid enemies and player wins, **WHEN** encounter resolves, **THEN** loot is rolled and combat finished event includes victory.
- **GIVEN** player loses, **WHEN** encounter resolves, **THEN** no loot is rolled and failure cooldown starts.
- **GIVEN** same seed context and same snapshots, **WHEN** online combat and offline combat call calculator, **THEN** result parity is possible.
- **GIVEN** enemy pool empty, **WHEN** combat tries to seek, **THEN** no crash and HUD can show a zone data error.
- **GIVEN** five consecutive failures, **WHEN** threshold is met, **THEN** system exposes a recommendation state instead of silently looping forever.
