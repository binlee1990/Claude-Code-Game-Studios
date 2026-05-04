# Epic: 半自动战斗系统

> **Layer**: Feature Integration
> **GDD**: design/gdd/semi-auto-combat-system.md
> **Architecture Module**: `SemiAutoCombatSystem` (Autoload)
> **Status**: Done
> **Stories**: Created (2 stories)

## Overview

半自动战斗系统把"战斗计算"变成持续刷怪玩法。玩家不逐帧操作技能，而是选择区域和队伍配置后让系统自动遭遇、结算、拾取和进入下一轮。本系统不定义伤害公式，不定义敌人模板，不定义掉落概率；它只负责在线战斗生命周期、调用顺序和失败/冷却处理。离线战斗模拟必须复用同一 CombatCalculator 和 LootSystem 合同。

Architecture ownership: `SemiAutoCombatSystem` owns 在线战斗循环.

## Governing ADRs

| ADR | Decision Summary | Engine Risk |
|-----|------------------|-------------|
| ADR-0009: 在线/离线战斗路径统一 | Both online and offline combat use the same `CombatCalculator` for attack resolution and the same `LootSystem` for rewards. SemiAutoCombatSystem manages live encounter cadence and event publication. OfflineCombatSimulation uses snapshots and copied RNG states to run batched encounters, producing a draft consumed by OfflineRewardSettlement. | LOW |
| ADR-0002: 事件总线架构 | Use a global `EventBus` Autoload Node with string event names and `Dictionary` payloads. The bus dispatches events synchronously in the current frame. Exact subscriptions are the production path. Prefix pattern subscriptions exist only for debug tooling such as `event watch resource`. Coalesced events are allowed only for display refreshes where latest-state wins. | HIGH |

## GDD Requirements

| TR-ID | Requirement | ADR Coverage |
|-------|-------------|--------------|
| TR-semi-auto-combat-001 | SemiAutoCombatSystem orchestrates online encounter loops through CombatCalculator, EnemyDatabase, LootSystem, LevelSystem, and EventBus. | ADR-0009, ADR-0002 |

**Untraced requirements**: 0 known in `docs/architecture/tr-registry.yaml`; the registry currently exposes one stable system-level TR for this GDD.

## Engine Risk

**HIGH** — highest governing ADR knowledge risk. Engine baseline: Godot 4.6.2.

## Cross-Epic Dependencies

- Upstream: 战斗计算器, 敌人数据库, 掉落系统, 等级系统
- Downstream: 挂机探索系统, 离线战斗模拟系统

## Definition of Done

This epic is complete when:
- All stories are implemented, reviewed, and closed via `/story-done`.
- All acceptance criteria from `design/gdd/semi-auto-combat-system.md` are verified.
- All Logic and Integration stories have passing test files under `tests/`.
- All Visual/Feel and UI stories have evidence docs with sign-off under `production/qa/evidence/`.
- Any Godot 4.6.2 behavior named by the governing ADRs is verified against `docs/engine-reference/godot/`.

## Stories

| # | Story | Type | Status | ADR |
|---|-------|------|--------|-----|
| 001 | [loot is rolled and combat finished event includes victory](story-001-loot-is-rolled-and-combat-finished-event-includes-victor.md) | Integration | Done | ADR-0009 |
| 002 | [no crash and HUD can show a zone data error](story-002-no-crash-and-hud-can-show-a-zone-data-error.md) | UI | Done | ADR-0002 |

## Next Step

Run `/story-readiness production/epics/semi-auto-combat-system/story-001-*.md` before implementing the first story in this epic.
