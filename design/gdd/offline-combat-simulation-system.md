# 离线战斗模拟系统 (Offline Combat Simulation System)

> **Status**: Approved
> **Author**: binlee1990 + agents
> **Last Updated**: 2026-05-04
> **Implements Pillar**: 4.1 数字增长就是快乐 · 4.3 刷宝提供惊喜
> **Design Review (lean)**: APPROVED 2026-05-04 — required sections, dependency references, acceptance criteria, and cross-GDD contracts checked in this cleanup pass.

## Summary

离线战斗模拟系统把离线时长、当前挂机区域和战斗能力转化为批量战斗结果草案。它复用战斗计算器和掉落表，确保离线收益与在线战斗逻辑同源。

> **Quick reference** — Layer: `Simulation` · Priority: `MVP` · Key deps: `离线模拟内核, 半自动战斗系统`

## Overview

离线战斗模拟系统是"睡觉期间也在刷怪"的具体执行者。它从离线模拟内核获得 offline context，从挂机探索系统读取 active zone，从 SemiAutoCombat/CombatCalculator 合同获取战斗能力，批量估算胜利次数、失败次数、战斗耗时和掉落草案。它不直接写资源；结果交给 Offline Reward Settlement。

## Player Fantasy

玩家回来时看到的不只是"经验 +N"，而是"东海探索 8 小时，战斗 1432 场，胜利 1390 场，药材 +84，灵石 +311"。这让离线奖励像真实发生过的历练，而不是登录补偿。

## Detailed Design

### Core Rules

1. 注册到 OfflineSimulationCore，priority 在 passive production 之后、reward settlement 之前。
2. 输入：offline_seconds、active_zone_id、player_snapshot、zone enemy pool、seed_context。
3. MVP 默认使用 hybrid 策略：短离线逐场模拟，长离线使用采样后的 expected values。
4. 所有伤害/胜负仍通过 CombatCalculator 或其采样结果产生；不另写伤害公式。
5. 掉落使用 LootSystem；长离线可按固定样本估计平均掉落，再保留关键稀有掉落为逐次 roll（MVP 无稀有装备）。
6. 输出 `OfflineCombatResultDraft`：encounters, wins, losses, generated_rewards, duration_used, warnings。
7. 不应用 storage caps；Settlement 统一处理 claimable/lost。

### States and Transitions

| State | Entry Condition | Exit Condition | Behavior |
|-------|----------------|----------------|----------|
| Waiting | 无离线请求 | Core 调用 | 空闲 |
| Preparing | 收到 context | 快照/区域验证完成 | 收集输入 |
| Simulating | 输入有效 | 达到离线时长或预算 | 批量模拟 |
| Completed | 草案生成 | Core 合并 | 返回结果 |
| Degraded | 区域/敌人无效 | 返回空结果 | 附原因 |

### Interactions with Other Systems

| System | Interface | Contract |
|--------|-----------|----------|
| 离线模拟内核 | simulator registration | 提供离线 context |
| 挂机探索系统 | active zone | 当前离线目标 |
| 区域系统 | enemy pool | 敌人候选 |
| 战斗计算器 | simulate/estimate | 胜负和耗时 |
| 掉落系统 | roll or expected drops | 奖励草案 |
| 离线收益结算系统 | result draft | 统一应用奖励 |

## Formulas

The `offline_encounter_count` formula is defined as:

`offline_encounter_count = floor(offline_seconds / average_cycle_time)`

**Variables:**
| Variable | Symbol | Type | Range | Description |
|----------|--------|------|-------|-------------|
| offline_seconds | T | float | 0-MAX_OFFLINE_SECONDS | 离线时长 |
| average_cycle_time | C | float | 0.1-300 | 平均战斗周期 |

**Output Range:** 0 to large int.
**Example:** 3600s / 10s → 360 encounters。

The `offline_expected_wins` formula is defined as:

`offline_expected_wins = encounter_count * estimated_win_rate`

**Variables:**
| Variable | Symbol | Type | Range | Description |
|----------|--------|------|-------|-------------|
| encounter_count | N | int | >=0 | 离线遭遇次数 |
| estimated_win_rate | P | float | 0-1 | 采样胜率 |

**Output Range:** 0 to encounter_count.
**Example:** 360 encounters, win_rate 0.9 → 324 wins。

## Edge Cases

- **If no active zone**: return zero rewards with `no_active_zone`.
- **If average cycle time is zero or invalid**: use safe fallback and warn.
- **If player loses all sampled fights**: generated rewards are zero except possible consolation is not in MVP.
- **If offline duration is shorter than one encounter**: return zero encounters but include elapsed duration.
- **If simulation exceeds CPU budget**: switch from per-encounter to expected-value mode and record degradation.

## Dependencies

| System | Direction | Nature |
|--------|-----------|--------|
| 离线模拟内核 | Upstream | Calls simulator |
| 半自动战斗系统 | Upstream | Shares online combat contract |
| 战斗计算器 | Upstream | Combat math |
| 掉落系统 | Upstream | Reward tables |
| 离线收益结算系统 | Downstream | Applies result |

## Tuning Knobs

| Parameter | Current Value | Safe Range | Effect of Increase | Effect of Decrease |
|-----------|--------------|------------|-------------------|-------------------|
| `per_encounter_threshold_seconds` | 600 | 60-3600 | More exact rolls | Faster expected mode |
| `sample_fight_count` | 20 | 5-200 | Better estimate | Less CPU |
| `max_offline_combat_ms` | 8.0 | 1-100 | More exact simulation | Less frame impact |
| `minimum_cycle_time` | 0.5s | 0.1-10 | Caps exploit speed | Allows faster farming |

## Visual/Audio Requirements

No direct assets. Settlement UI should summarize battles, wins, losses, and notable drops.

## UI Requirements

Output must include display fields: zone name, duration, encounters, win rate, generated rewards, lost rewards after settlement, and warnings.

## Cross-References

| This Document References | Target GDD | Specific Element Referenced | Nature |
|--------------------------|-----------|-----------------------------|--------|
| Online contract | `design/gdd/semi-auto-combat-system.md` | encounter cycle | Rule dependency |
| Combat math | `design/gdd/combat-calculator.md` | CombatResult | Data dependency |
| Settlement | `design/gdd/offline-reward-settlement-system.md` | reward draft | Ownership handoff |

## Acceptance Criteria

- **GIVEN** offline 3600s and average cycle 10s, **WHEN** simulation runs in expected mode, **THEN** encounter count is 360.
- **GIVEN** no active zone, **WHEN** simulation runs, **THEN** result has zero rewards and warning.
- **GIVEN** same context and seed, **WHEN** short offline simulation runs twice, **THEN** outputs match.
- **GIVEN** CPU budget exceeded, **WHEN** simulation continues, **THEN** mode switches to expected and records degradation.
- **GIVEN** generated rewards exist, **WHEN** simulation completes, **THEN** no ResourceSystem writes have occurred.
