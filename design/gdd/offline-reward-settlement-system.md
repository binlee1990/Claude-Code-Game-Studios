# 离线收益结算系统 (Offline Reward Settlement System)

> **Status**: Approved
> **Author**: binlee1990 + agents
> **Last Updated**: 2026-05-04
> **Implements Pillar**: 4.1 数字增长就是快乐 · 4.2 放置不是无操作
> **Design Review (lean)**: APPROVED 2026-05-04 — required sections, dependency references, acceptance criteria, and cross-GDD contracts checked in this cleanup pass.

## Summary

离线收益结算系统把离线模拟草案变成实际入账和可读报告。它合并生产、战斗、探索结果，应用存储上限，写入资源系统，并生成玩家返回时看到的收益摘要。

> **Quick reference** — Layer: `Simulation` · Priority: `MVP` · Key deps: `离线战斗模拟系统, 离线模拟内核`

## Overview

离线收益结算系统是离线链路唯一可以写入资源的终点。Offline Simulation Core 和各模拟器只生成草案；本系统负责按资源合并、检查容量、调用 ResourceSystem.batch_add、记录实际入账和损失、发布 `offline.settled`。它保证离线收益可解释、可审计、不会绕过 ResourceSystem 的 cap/overflow 规则。

## Player Fantasy

玩家回来后看到一张清晰的闭关报告：获得了什么，哪些因满仓损失了，下一次如何减少浪费。这种报告把"挂机收益"转化为下一步决策，而不是一串无法追溯的数字。

## Detailed Design

### Core Rules

1. 输入 `OfflineSimulationDraft`，包含多个 simulator partial results。
2. 按 resource id 合并所有 generated rewards。
3. 对每个 capped resource 查询 StorageLimit/ResourceSystem 剩余容量，计算 claimable 和 lost。
4. 调用 `ResourceSystem.batch_add(claimable_rewards)`；以 ResourceSystem 返回的 actual_added 为最终入账事实。
5. 生成 `OfflineSettlementSummary`：gross、claimed、lost、simulator breakdown、duration、warnings。
6. 发布 `offline.settled`，payload 使用 summary 的轻量版本。
7. 不自动打开 UI；HUD/UI 框架根据事件展示离线结算面板。

### States and Transitions

| State | Entry Condition | Exit Condition | Behavior |
|-------|----------------|----------------|----------|
| Waiting | 无草案 | Core 提交 draft | 空闲 |
| Merging | 收到 draft | reward map 完成 | 合并 partial results |
| Applying | claimable 已计算 | ResourceSystem 返回 | 写入资源 |
| Summarized | summary 生成 | 玩家确认 | 供 UI 展示 |
| Failed | draft 无效或写入严重失败 | 重试/跳过 | 不重复入账 |

### Interactions with Other Systems

| System | Interface | Contract |
|--------|-----------|----------|
| 离线模拟内核 | draft input | 提供所有 partial results |
| 离线战斗模拟系统 | partial result | 战斗奖励来源 |
| 资源系统 | `batch_add` | 唯一资源写入 |
| 存储上限系统 | capacity query | 预估 claimable/lost |
| HUD/UI 框架 | `offline.settled` | 展示报告 |
| 存档系统 | load sequence | settlement after restore |

## Formulas

The `claimable_reward` formula is defined as:

`claimable_reward = min(generated_reward, remaining_capacity)`

**Variables:**
| Variable | Symbol | Type | Range | Description |
|----------|--------|------|-------|-------------|
| generated_reward | G | BigNumber | >=0 | 模拟生成量 |
| remaining_capacity | C | BigNumber | 0-MAX | 当前可容纳量；uncapped 为 MAX |

**Output Range:** 0 to generated_reward.
**Example:** generated 500 herb, capacity 120 → claimable 120。

The `lost_reward` formula is defined as:

`lost_reward = generated_reward - actual_added`

**Variables:**
| Variable | Symbol | Type | Range | Description |
|----------|--------|------|-------|-------------|
| generated_reward | G | BigNumber | >=0 | 模拟生成量 |
| actual_added | A | BigNumber | 0-G | ResourceSystem 实际入账 |

**Output Range:** 0 to generated_reward.
**Example:** generated 500, actual 120 → lost 380。

## Edge Cases

- **If draft is empty**: emit summary with zero rewards and no ResourceSystem writes.
- **If ResourceSystem actual_added differs from precomputed claimable**: trust ResourceSystem and update lost accordingly.
- **If one simulator reports failure**: include warning; do not block other rewards.
- **If settlement is requested twice for same draft id**: reject second request to prevent duplicate rewards.
- **If save/load has not completed**: defer settlement until all providers restored.

## Dependencies

| System | Direction | Nature |
|--------|-----------|--------|
| 离线战斗模拟系统 | Upstream | Combat reward draft |
| 离线模拟内核 | Upstream | Draft orchestration |
| 资源系统 | Upstream | Writes actual rewards |
| 存储上限系统 | Upstream | Capacity estimate |
| HUD 系统 | Downstream | Settlement panel |

## Tuning Knobs

| Parameter | Current Value | Safe Range | Effect of Increase | Effect of Decrease |
|-----------|--------------|------------|-------------------|-------------------|
| `dedupe_history_size` | 5 drafts | 1-50 | Safer duplicate prevention | Less memory |
| `show_zero_reward_summary` | true | bool | Clear no-reward reason | Less UI interruption |
| `max_summary_rows` | 12 | 3-50 | More detail | More compact |
| `trust_resource_actuals` | true | bool | Stronger source of truth | Risk mismatch |

## Visual/Audio Requirements

Settlement panel should have a clear "gained/lost" visual distinction; large gains can use a soft chime. Owned by HUD/UI/audio systems.

## UI Requirements

Requires offline summary modal or panel with duration, rewards by source, actual added, lost due to capacity, warnings, and close/inspect actions.

## Cross-References

| This Document References | Target GDD | Specific Element Referenced | Nature |
|--------------------------|-----------|-----------------------------|--------|
| Draft source | `design/gdd/offline-simulation-core.md` | `OfflineSimulationDraft` | Data dependency |
| Resource application | `design/gdd/resource-system.md` | `batch_add` actual_added | Rule dependency |
| Capacity | `design/gdd/storage-limit-system.md` | remaining capacity | Data dependency |

## Acceptance Criteria

- **GIVEN** draft generated 100 lingqi and lingqi has enough capacity, **WHEN** settlement runs, **THEN** ResourceSystem receives 100 lingqi.
- **GIVEN** draft generated 500 herb but capacity remains 120, **WHEN** settlement runs, **THEN** actual added is 120 and lost is 380.
- **GIVEN** same draft id is settled once, **WHEN** settlement is requested again, **THEN** second request is rejected.
- **GIVEN** one simulator failed, **WHEN** summary is generated, **THEN** warning appears and other rewards still apply.
- **GIVEN** settlement completes, **WHEN** event bus is checked, **THEN** exactly one `offline.settled` event is emitted.
