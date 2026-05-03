# 离线模拟内核 (Offline Simulation Core)

> **Status**: Approved
> **Author**: binlee1990 + agents
> **Last Updated**: 2026-05-04
> **Implements Pillar**: 4.1 数字增长就是快乐 · 4.8 自动化是成长奖励
> **Design Review (lean)**: APPROVED 2026-05-04 — required sections, dependency references, acceptance criteria, and cross-GDD contracts checked in this cleanup pass.

## Summary

离线模拟内核是离线收益的批处理框架。它接收时间管理器给出的离线秒数，切分为可控批次，调用已注册的业务模拟器，产出统一的离线结果草案。

> **Quick reference** — Layer: `Simulation` · Priority: `MVP` · Key deps: `时间管理器`

## Overview

离线模拟内核不计算具体收益。它是一个调度器：TimeManager 告诉它玩家离线了多久，它决定是否结算、如何分块、按什么顺序调用生产/战斗/探索模拟器、如何合并结果、如何把结果交给 Offline Reward Settlement。这样可以避免每个系统自己读离线时间，造成重复收益或顺序不一致。

## Player Fantasy

玩家回来时看到的是"离开期间世界认真运转过"。这个内核的任务是让这种运转可信：八小时不是一笔随便发的奖励，而是被拆成生产、战斗、探索等可解释部分。

## Detailed Design

### Core Rules

1. `OfflineSimulationCore` 监听 `time.offline_delta` 或在 `save.loaded` 后由启动流程显式调用。
2. 提供 `register_simulator(id, priority, simulate_fn)`；业务系统注册离线模拟函数。
3. 模拟函数签名：`simulate_fn(context) -> OfflinePartialResult`，context 包含离线秒数、chunk size、seed、当前存档摘要。
4. 内核只合并 partial results，不写 ResourceSystem。
5. 模拟顺序按 priority：生产 → 战斗 → 探索 → 其他；同 priority 按注册顺序。
6. 离线时间先 clamp 到 TimeManager 的最大离线秒数，再按 `MAX_CHUNK_SECONDS` 切块。
7. 结果交给 Offline Reward Settlement 统一应用和展示。

### States and Transitions

| State | Entry Condition | Exit Condition | Behavior |
|-------|----------------|----------------|----------|
| Idle | 无待结算离线时间 | 收到 offline delta | 等待 |
| Planning | delta 有效 | chunks/simulators ready | 建立模拟计划 |
| Simulating | 开始调用模拟器 | 全部返回或失败 | 收集 partial results |
| Completed | 草案生成 | Settlement 接收 | 发出 `offline.simulation_completed` |
| Failed | 核心数据非法 | 手动恢复/跳过 | 不应用奖励 |

### Interactions with Other Systems

| System | Interface | Contract |
|--------|-----------|----------|
| 时间管理器 | `time.offline_delta` | 唯一离线时间来源 |
| 离线战斗模拟系统 | registered simulator | 产出战斗奖励草案 |
| 挂机探索系统 | registered simulator | 产出探索奖励草案 |
| 自动产出/修炼 | registered simulator or production adapter | 产出 passive resources |
| 离线收益结算系统 | `settle(draft)` | 唯一应用奖励方 |
| 存档系统 | `save.loaded` sequencing | 确保恢复后再模拟 |

## Formulas

The `offline_chunk_count` formula is defined as:

`offline_chunk_count = ceil(offline_seconds / MAX_CHUNK_SECONDS)`

**Variables:**
| Variable | Symbol | Type | Range | Description |
|----------|--------|------|-------|-------------|
| offline_seconds | T | float | 0-MAX_OFFLINE_SECONDS | 离线时长 |
| MAX_CHUNK_SECONDS | C | float | 60-3600 | 单模拟块最大时长 |

**Output Range:** 0 to `ceil(MAX_OFFLINE_SECONDS / C)`.
**Example:** 7200s / 1800s → 4 chunks。

The `simulation_budget` formula is defined as:

`simulation_budget_ms = frame_budget_ms * offline_budget_ratio`

**Variables:**
| Variable | Symbol | Type | Range | Description |
|----------|--------|------|-------|-------------|
| frame_budget_ms | F | float | 16.6 | 60fps 帧预算 |
| offline_budget_ratio | R | float | 0.05-0.5 | 离线结算可占比例 |

**Output Range:** 0.83ms to 8.3ms per frame if spread across frames.
**Example:** 16.6 * 0.25 → 4.15ms。

## Edge Cases

- **If offline_seconds <= 0**: do not simulate and do not emit completion.
- **If no simulators registered**: emit empty draft with a warning, settlement shows no rewards.
- **If one simulator fails**: include failure in draft, continue other simulators unless marked critical.
- **If offline delta exceeds cap**: use capped value and record truncated seconds.
- **If save is still loading**: defer simulation until `save.loaded` sequence completes.

## Dependencies

| System | Direction | Nature |
|--------|-----------|--------|
| 时间管理器 | Upstream | Offline delta authority |
| 存档系统 | Upstream | Load sequencing |
| 离线战斗模拟系统 | Downstream | Registered simulator |
| 挂机探索系统 | Downstream | Registered simulator |
| 离线收益结算系统 | Downstream | Applies result draft |

## Tuning Knobs

| Parameter | Current Value | Safe Range | Effect of Increase | Effect of Decrease |
|-----------|--------------|------------|-------------------|-------------------|
| `MAX_CHUNK_SECONDS` | 1800 | 60-3600 | Fewer chunks | Finer simulation |
| `offline_budget_ratio` | 0.25 | 0.05-0.5 | Faster settlement | Less frame impact |
| `critical_simulators` | settlement only | list | More strict failures | More graceful degradation |
| `emit_empty_result` | true | bool | Clearer no-reward feedback | Less UI noise |

## Visual/Audio Requirements

No direct assets. Settlement UI should show that simulation is processing if it spans frames.

## UI Requirements

Expose summary draft fields: offline seconds used, truncated seconds, simulator result groups, failures, and settlement status.

## Cross-References

| This Document References | Target GDD | Specific Element Referenced | Nature |
|--------------------------|-----------|-----------------------------|--------|
| Offline delta | `design/gdd/time-manager.md` | `time.offline_delta` | State trigger |
| Reward application | `design/gdd/offline-reward-settlement-system.md` | settlement draft input | Ownership handoff |
| Battle batch | `design/gdd/offline-combat-simulation-system.md` | registered simulator | Data dependency |

## Acceptance Criteria

- **GIVEN** offline delta 7200s and chunk size 1800s, **WHEN** plan builds, **THEN** it contains 4 chunks.
- **GIVEN** two registered simulators, **WHEN** offline simulation runs, **THEN** both are called in priority order.
- **GIVEN** one non-critical simulator fails, **WHEN** simulation completes, **THEN** draft includes failure and successful simulator output.
- **GIVEN** delta is 0, **WHEN** simulation is requested, **THEN** no settlement draft is emitted.
- **GIVEN** save.loaded has not completed, **WHEN** offline delta arrives, **THEN** simulation is deferred.
