# 挂机探索系统 (Idle Exploration System)

> **Status**: Approved
> **Author**: binlee1990 + agents
> **Last Updated**: 2026-05-04
> **Implements Pillar**: 4.1 数字增长就是快乐 · 4.2 放置不是无操作
> **Design Review (lean)**: APPROVED 2026-05-04 — required sections, dependency references, acceptance criteria, and cross-GDD contracts checked in this cleanup pass.

## Summary

挂机探索系统管理玩家当前的长期探索指派：选择区域、记录探索效率、汇总在线/离线探索产出。它让"我去哪里挂机"成为可保存、可离线结算的明确状态。

> **Quick reference** — Layer: `Simulation` · Priority: `MVP` · Key deps: `半自动战斗系统, 区域系统`

## Overview

挂机探索系统位于区域、在线战斗和离线模拟之间。区域系统提供地图数据，半自动战斗负责在线遭遇，离线战斗模拟负责批量战斗；本系统保存玩家选择的探索目标、探索策略和近期效率，供在线与离线两条路径使用同一个"当前挂机意图"。它不重新实现战斗，不直接发奖励。

## Player Fantasy

玩家睡前选择"今晚挂东海"，醒来看到东海探索报告：打了多少轮、掉了什么、浪费了多少容量、是否建议换图。这种"我离开前的安排被执行了"是放置游戏的核心信任体验。

## Detailed Design

### Core Rules

1. `IdleExplorationSystem` 持有 `active_zone_id`、`strategy`、`started_at_game_time`、`recent_efficiency`。
2. `strategy` MVP 支持：`balanced`、`safe_farm`、`push_progress`；它只影响推荐和区域选择，不改 CombatCalculator 公式。
3. 在线时，SemiAutoCombat 读取 active zone；离线时，OfflineCombatSimulation 读取同一 active zone。
4. 本系统记录探索 session summary：encounters、wins、losses、gross rewards、lost rewards、duration。
5. 切换探索目标发布 `exploration.target_changed`。
6. 若当前区域锁定/失效，则进入 Blocked 并请求 MapProgression 提供 fallback。
7. 本系统不持有背包，不写资源；奖励应用由 Reward Settlement 或在线战斗编排完成。

### States and Transitions

| State | Entry Condition | Exit Condition | Behavior |
|-------|----------------|----------------|----------|
| Unassigned | 玩家尚未选择区域 | 选择有效区域 | 不探索 |
| Exploring | active_zone_id 有效 | 暂停/区域失效 | 在线/离线均消费此目标 |
| Blocked | 区域锁定、无敌人或配置错误 | 选择 fallback | 暂停战斗，显示原因 |
| Returning | 离线结果待展示 | 玩家确认结算 | 保留 summary 供 UI 展示 |

### Interactions with Other Systems

| System | Interface | Contract |
|--------|-----------|----------|
| 半自动战斗系统 | active zone query | 在线战斗目标 |
| 区域系统 | zone validation | 确认区域可选和敌人池有效 |
| 地图推进系统 | lock/fallback state | 处理锁定/推进 |
| 离线模拟内核 | registered exploration context | 离线读取探索目标 |
| 离线战斗模拟系统 | active exploration context | 批量战斗 |
| HUD 系统 | summary and state | 展示当前挂机安排 |

## Formulas

The `exploration_efficiency` formula is defined as:

`exploration_efficiency = recent_win_rate * reward_rate_per_second * capacity_factor`

**Variables:**
| Variable | Symbol | Type | Range | Description |
|----------|--------|------|-------|-------------|
| recent_win_rate | W | float | 0-1 | 最近战斗胜率 |
| reward_rate_per_second | R | BigNumber | >=0 | 单秒平均奖励价值 |
| capacity_factor | C | float | 0-1 | 剩余容量对收益的保留比例 |

**Output Range:** 0 to high reward score.
**Example:** win 0.9, reward 10/s, capacity 0.8 → 7.2 score/s。

The `capacity_factor` formula is defined as:

`capacity_factor = claimable_rewards / max(generated_rewards, 1)`

**Variables:**
| Variable | Symbol | Type | Range | Description |
|----------|--------|------|-------|-------------|
| claimable_rewards | A | BigNumber | >=0 | 可入账奖励 |
| generated_rewards | G | BigNumber | >=0 | 生成奖励 |

**Output Range:** 0.0 to 1.0.
**Example:** generated 100 herb, claimable 60 → 0.6。

## Edge Cases

- **If active zone becomes locked after reset**: move to Blocked and keep last valid zone in history.
- **If player has no active zone on first launch**: choose first unlocked zone as recommended but do not silently start if UI requires confirmation.
- **If online combat is paused**: exploration remains assigned but not progressing online.
- **If offline simulation returns no rewards**: summary still records duration and reason.
- **If capacity factor is 0 for repeated sessions**: HUD should recommend storage/cultivation action.

## Dependencies

| System | Direction | Nature |
|--------|-----------|--------|
| 半自动战斗系统 | Upstream/Peer | Online encounter executor |
| 区域系统 | Upstream | Zone validation |
| 地图推进系统 | Upstream | Lock/fallback state |
| 离线战斗模拟系统 | Downstream | Offline execution |
| HUD 系统 | Downstream | Exploration display |

## Tuning Knobs

| Parameter | Current Value | Safe Range | Effect of Increase | Effect of Decrease |
|-----------|--------------|------------|-------------------|-------------------|
| `efficiency_window_minutes` | 10 | 1-120 | Stable estimates | Faster feedback |
| `default_strategy` | balanced | enum | Safer start | More aggressive if changed |
| `blocked_retry_seconds` | 30 | 5-300 | Less spam | Faster recovery |
| `auto_select_first_zone` | true | bool | Smoother onboarding | More explicit control |

## Visual/Audio Requirements

No direct assets. HUD should show current exploration target and offline-return summary.

## UI Requirements

Requires a compact exploration assignment panel: current zone, strategy, estimated efficiency, blocked reason, and last session summary.

## Cross-References

| This Document References | Target GDD | Specific Element Referenced | Nature |
|--------------------------|-----------|-----------------------------|--------|
| Active zone | `design/gdd/zone-system.md` | zone id and validity | Data dependency |
| Online executor | `design/gdd/semi-auto-combat-system.md` | combat loop target | Ownership handoff |
| Offline batch | `design/gdd/offline-combat-simulation-system.md` | active exploration context | Data dependency |

## Acceptance Criteria

- **GIVEN** first unlocked zone exists, **WHEN** exploration initializes, **THEN** recommended target is available.
- **GIVEN** player changes active zone, **WHEN** assignment succeeds, **THEN** `exploration.target_changed` emits.
- **GIVEN** active zone becomes invalid, **WHEN** validation runs, **THEN** state becomes Blocked with reason.
- **GIVEN** offline combat returns summary, **WHEN** player returns, **THEN** exploration stores session summary for HUD.
- **GIVEN** capacity factor is below threshold, **WHEN** summary is generated, **THEN** recommendation includes capacity pressure.
