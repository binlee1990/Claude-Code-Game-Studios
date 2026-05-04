# Epic: 离线收益结算系统

> **Layer**: Simulation
> **GDD**: design/gdd/offline-reward-settlement-system.md
> **Architecture Module**: `OfflineRewardSettlement` (服务)
> **Status**: Ready
> **Stories**: Created (2 stories)

## Overview

离线收益结算系统是离线链路唯一可以写入资源的终点。Offline Simulation Core 和各模拟器只生成草案；本系统负责按资源合并、检查容量、调用 ResourceSystem.batch_add、记录实际入账和损失、发布 `offline.settled`。它保证离线收益可解释、可审计、不会绕过 ResourceSystem 的 cap/overflow 规则。

Architecture ownership: `OfflineRewardSettlement` owns 离线奖励应用.

## Governing ADRs

| ADR | Decision Summary | Engine Risk |
|-----|------------------|-------------|
| ADR-0009: 在线/离线战斗路径统一 | Both online and offline combat use the same `CombatCalculator` for attack resolution and the same `LootSystem` for rewards. SemiAutoCombatSystem manages live encounter cadence and event publication. OfflineCombatSimulation uses snapshots and copied RNG states to run batched encounters, producing a draft consumed by OfflineRewardSettlement. | LOW |
| ADR-0015: 离线模拟 tick 粒度 | Use fixed MVP offline simulation granularity: clamp total offline delta through TimeManager, then split into chunks up to `MAX_CHUNK_SECONDS` (GDD example: 1800 seconds). Within each chunk, simulators use 1-second logical tick semantics or closed-form aggregation if they can prove equivalence. OfflineSimulationCore merges partial results into an `OfflineSimulationDraft`; OfflineRewardSettlement is the only system that writes rewards to ResourceSystem. | LOW |
| ADR-0010: ResourceSystem 不可变 BigNumber 策略 | ResourceSystem stores BigNumber values as immutable value objects. Operations calculate new BigNumber instances and replace the stored value. `add()` returns the actual added amount. `spend()` is atomic per resource. `batch_add()` executes sequential per-resource adds and returns a dictionary of actual additions; it does not roll back earlier successful changes. | LOW |
| ADR-0002: 事件总线架构 | Use a global `EventBus` Autoload Node with string event names and `Dictionary` payloads. The bus dispatches events synchronously in the current frame. Exact subscriptions are the production path. Prefix pattern subscriptions exist only for debug tooling such as `event watch resource`. Coalesced events are allowed only for display refreshes where latest-state wins. | HIGH |

## GDD Requirements

| TR-ID | Requirement | ADR Coverage |
|-------|-------------|--------------|
| TR-offline-settlement-001 | OfflineRewardSettlement applies claimable offline rewards through ResourceSystem and reports gross, claimed, lost, and warnings. | ADR-0009, ADR-0015, ADR-0010, ADR-0002 |

**Untraced requirements**: 0 known in `docs/architecture/tr-registry.yaml`; the registry currently exposes one stable system-level TR for this GDD.

## Engine Risk

**HIGH** — highest governing ADR knowledge risk. Engine baseline: Godot 4.6.2.

## Cross-Epic Dependencies

- Upstream: 离线战斗模拟系统, 离线模拟内核
- Downstream: None listed in `systems-index.md`

## Definition of Done

This epic is complete when:
- All stories are implemented, reviewed, and closed via `/story-done`.
- All acceptance criteria from `design/gdd/offline-reward-settlement-system.md` are verified.
- All Logic and Integration stories have passing test files under `tests/`.
- All Visual/Feel and UI stories have evidence docs with sign-off under `production/qa/evidence/`.
- Any Godot 4.6.2 behavior named by the governing ADRs is verified against `docs/engine-reference/godot/`.

## Stories

| # | Story | Type | Status | ADR |
|---|-------|------|--------|-----|
| 001 | [ResourceSystem receives 100 lingqi](story-001-resourcesystem-receives-100-lingqi.md) | Integration | Ready | ADR-0009 |
| 002 | [warning appears and other rewards still apply](story-002-warning-appears-and-other-rewards-still-apply.md) | Integration | Ready | ADR-0009 |

## Next Step

Run `/story-readiness production/epics/offline-reward-settlement-system/story-001-*.md` before implementing the first story in this epic.
