# Epic: 离线模拟内核

> **Layer**: Simulation
> **GDD**: design/gdd/offline-simulation-core.md
> **Architecture Module**: `OfflineSimCore` (服务)
> **Status**: Done
> **Stories**: Created (2 stories)

## Overview

离线模拟内核不计算具体收益。它是一个调度器：TimeManager 告诉它玩家离线了多久，它决定是否结算、如何分块、按什么顺序调用生产/战斗/探索模拟器、如何合并结果、如何把结果交给 Offline Reward Settlement。这样可以避免每个系统自己读离线时间，造成重复收益或顺序不一致。

Architecture ownership: `OfflineSimCore` owns 批量模拟框架, tick 步进.

## Governing ADRs

| ADR | Decision Summary | Engine Risk |
|-----|------------------|-------------|
| ADR-0015: 离线模拟 tick 粒度 | Use fixed MVP offline simulation granularity: clamp total offline delta through TimeManager, then split into chunks up to `MAX_CHUNK_SECONDS` (GDD example: 1800 seconds). Within each chunk, simulators use 1-second logical tick semantics or closed-form aggregation if they can prove equivalence. OfflineSimulationCore merges partial results into an `OfflineSimulationDraft`; OfflineRewardSettlement is the only system that writes rewards to ResourceSystem. | LOW |
| ADR-0003: 时间源与双时间体系 | Implement `TimeManager` as an Autoload that owns a dual-time snapshot: real Unix time and derived game time. All gameplay timing uses `TimeManager`, never direct `_process(delta)` as authority. Online ticks use `get_game_delta_since`; offline settlement uses `min(real_now - exit_timestamp, MAX_OFFLINE_SECONDS)` with speed multiplier ignored. | LOW |

## GDD Requirements

| TR-ID | Requirement | ADR Coverage |
|-------|-------------|--------------|
| TR-offline-sim-core-001 | OfflineSimulationCore converts capped offline delta into ordered chunked simulator runs and emits settlement drafts. | ADR-0015, ADR-0003 |

**Untraced requirements**: 0 known in `docs/architecture/tr-registry.yaml`; the registry currently exposes one stable system-level TR for this GDD.

## Engine Risk

**LOW** — highest governing ADR knowledge risk. Engine baseline: Godot 4.6.2.

## Cross-Epic Dependencies

- Upstream: 时间管理器
- Downstream: 离线战斗模拟系统, 离线收益结算系统

## Definition of Done

This epic is complete when:
- All stories are implemented, reviewed, and closed via `/story-done`.
- All acceptance criteria from `design/gdd/offline-simulation-core.md` are verified.
- All Logic and Integration stories have passing test files under `tests/`.
- All Visual/Feel and UI stories have evidence docs with sign-off under `production/qa/evidence/`.
- Any Godot 4.6.2 behavior named by the governing ADRs is verified against `docs/engine-reference/godot/`.

## Stories

| # | Story | Type | Status | ADR |
|---|-------|------|--------|-----|
| 001 | [it contains 4 chunks](story-001-it-contains-4-chunks.md) | UI | Done | ADR-0015 |
| 002 | [no settlement draft is emitted](story-002-no-settlement-draft-is-emitted.md) | Integration | Done | ADR-0015 |

## Next Step

Run `/story-readiness production/epics/offline-simulation-core/story-001-*.md` before implementing the first story in this epic.
