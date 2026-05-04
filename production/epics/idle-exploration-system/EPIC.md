# Epic: 挂机探索系统

> **Layer**: Simulation
> **GDD**: design/gdd/idle-exploration-system.md
> **Architecture Module**: `IdleExplorationSystem` (服务)
> **Status**: Ready
> **Stories**: Created (2 stories)

## Overview

挂机探索系统位于区域、在线战斗和离线模拟之间。区域系统提供地图数据，半自动战斗负责在线遭遇，离线战斗模拟负责批量战斗；本系统保存玩家选择的探索目标、探索策略和近期效率，供在线与离线两条路径使用同一个"当前挂机意图"。它不重新实现战斗，不直接发奖励。

Architecture ownership: `IdleExplorationSystem` owns 在线挂机循环.

## Governing ADRs

| ADR | Decision Summary | Engine Risk |
|-----|------------------|-------------|
| ADR-0009: 在线/离线战斗路径统一 | Both online and offline combat use the same `CombatCalculator` for attack resolution and the same `LootSystem` for rewards. SemiAutoCombatSystem manages live encounter cadence and event publication. OfflineCombatSimulation uses snapshots and copied RNG states to run batched encounters, producing a draft consumed by OfflineRewardSettlement. | LOW |
| ADR-0002: 事件总线架构 | Use a global `EventBus` Autoload Node with string event names and `Dictionary` payloads. The bus dispatches events synchronously in the current frame. Exact subscriptions are the production path. Prefix pattern subscriptions exist only for debug tooling such as `event watch resource`. Coalesced events are allowed only for display refreshes where latest-state wins. | HIGH |

## GDD Requirements

| TR-ID | Requirement | ADR Coverage |
|-------|-------------|--------------|
| TR-idle-exploration-001 | IdleExplorationSystem coordinates selected zone exploration through semi-auto combat and zone state. | ADR-0009, ADR-0002 |

**Untraced requirements**: 0 known in `docs/architecture/tr-registry.yaml`; the registry currently exposes one stable system-level TR for this GDD.

## Engine Risk

**HIGH** — highest governing ADR knowledge risk. Engine baseline: Godot 4.6.2.

## Cross-Epic Dependencies

- Upstream: 半自动战斗系统, 区域系统
- Downstream: None listed in `systems-index.md`

## Definition of Done

This epic is complete when:
- All stories are implemented, reviewed, and closed via `/story-done`.
- All acceptance criteria from `design/gdd/idle-exploration-system.md` are verified.
- All Logic and Integration stories have passing test files under `tests/`.
- All Visual/Feel and UI stories have evidence docs with sign-off under `production/qa/evidence/`.
- Any Godot 4.6.2 behavior named by the governing ADRs is verified against `docs/engine-reference/godot/`.

## Stories

| # | Story | Type | Status | ADR |
|---|-------|------|--------|-----|
| 001 | [recommended target is available](story-001-recommended-target-is-available.md) | Integration | Ready | ADR-0009 |
| 002 | [exploration stores session summary for HUD](story-002-exploration-stores-session-summary-for-hud.md) | UI | Ready | ADR-0002 |

## Next Step

Run `/story-readiness production/epics/idle-exploration-system/story-001-*.md` before implementing the first story in this epic.
