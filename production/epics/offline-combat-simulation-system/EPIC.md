# Epic: 离线战斗模拟系统

> **Layer**: Simulation
> **GDD**: design/gdd/offline-combat-simulation-system.md
> **Architecture Module**: `OfflineCombatSimulation` (服务)
> **Status**: Done
> **Stories**: Created (2 stories)

## Overview

离线战斗模拟系统是"睡觉期间也在刷怪"的具体执行者。它从离线模拟内核获得 offline context，从挂机探索系统读取 active zone，从 SemiAutoCombat/CombatCalculator 合同获取战斗能力，批量估算胜利次数、失败次数、战斗耗时和掉落草案。它不直接写资源；结果交给 Offline Reward Settlement。

Architecture ownership: `OfflineCombatSimulation` owns 离线批量战斗.

## Governing ADRs

| ADR | Decision Summary | Engine Risk |
|-----|------------------|-------------|
| ADR-0009: 在线/离线战斗路径统一 | Both online and offline combat use the same `CombatCalculator` for attack resolution and the same `LootSystem` for rewards. SemiAutoCombatSystem manages live encounter cadence and event publication. OfflineCombatSimulation uses snapshots and copied RNG states to run batched encounters, producing a draft consumed by OfflineRewardSettlement. | LOW |
| ADR-0015: 离线模拟 tick 粒度 | Use fixed MVP offline simulation granularity: clamp total offline delta through TimeManager, then split into chunks up to `MAX_CHUNK_SECONDS` (GDD example: 1800 seconds). Within each chunk, simulators use 1-second logical tick semantics or closed-form aggregation if they can prove equivalence. OfflineSimulationCore merges partial results into an `OfflineSimulationDraft`; OfflineRewardSettlement is the only system that writes rewards to ResourceSystem. | LOW |
| ADR-0004: 确定性随机数架构 | Implement `RNGManager` as an Autoload with a 64-bit master seed and independent `RandomNumberGenerator` instances for `COMBAT`, `LOOT`, `EVENT`, and `AFFIX`, plus optional named extension streams. Derive stream seeds from master seed using FNV-1a. Offline simulations operate on saved state copies and discard them after settlement. | MEDIUM |

## GDD Requirements

| TR-ID | Requirement | ADR Coverage |
|-------|-------------|--------------|
| TR-offline-combat-001 | OfflineCombatSimulation reuses the online combat calculation path with copied RNG state and returns partial results. | ADR-0009, ADR-0015, ADR-0004 |

**Untraced requirements**: 0 known in `docs/architecture/tr-registry.yaml`; the registry currently exposes one stable system-level TR for this GDD.

## Engine Risk

**MEDIUM** — highest governing ADR knowledge risk. Engine baseline: Godot 4.6.2.

## Cross-Epic Dependencies

- Upstream: 离线模拟内核, 半自动战斗系统
- Downstream: 离线收益结算系统

## Definition of Done

This epic is complete when:
- All stories are implemented, reviewed, and closed via `/story-done`.
- All acceptance criteria from `design/gdd/offline-combat-simulation-system.md` are verified.
- All Logic and Integration stories have passing test files under `tests/`.
- All Visual/Feel and UI stories have evidence docs with sign-off under `production/qa/evidence/`.
- Any Godot 4.6.2 behavior named by the governing ADRs is verified against `docs/engine-reference/godot/`.

## Stories

| # | Story | Type | Status | ADR |
|---|-------|------|--------|-----|
| 001 | [encounter count is 360](story-001-encounter-count-is-360.md) | Integration | Done | ADR-0009 |
| 002 | [mode switches to expected and records degradation](story-002-mode-switches-to-expected-and-records-degradation.md) | Integration | Done | ADR-0009 |

## Next Step

Run `/story-readiness production/epics/offline-combat-simulation-system/story-001-*.md` before implementing the first story in this epic.
