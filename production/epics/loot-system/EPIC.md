# Epic: 掉落系统

> **Layer**: Feature
> **GDD**: design/gdd/loot-system.md
> **Architecture Module**: `LootSystem` (服务)
> **Status**: Ready
> **Stories**: Created (2 stories)

## Overview

掉落系统是第一条刷宝闭环的奖励裁决者。半自动战斗告诉它"玩家击败了某个敌人"，它读取该敌人的掉落表，用可复现 RNG 结算掉落，验证 item id 是否存在于物品/材料系统，然后返回一个 reward bundle。MVP 中 reward bundle 主要写入 ResourceSystem：`exp`、`lingshi`、`herb`。未来装备、词条、法宝可以接入同一套 loot table 结构，但不进入 MVP。

Architecture ownership: `LootSystem` owns 掉落表解析, 加权结算.

## Governing ADRs

| ADR | Decision Summary | Engine Risk |
|-----|------------------|-------------|
| ADR-0004: 确定性随机数架构 | Implement `RNGManager` as an Autoload with a 64-bit master seed and independent `RandomNumberGenerator` instances for `COMBAT`, `LOOT`, `EVENT`, and `AFFIX`, plus optional named extension streams. Derive stream seeds from master seed using FNV-1a. Offline simulations operate on saved state copies and discard them after settlement. | MEDIUM |
| ADR-0005: 数据配置加载策略 | Implement `DataConfig` as a `RefCounted` service held by an Autoload host. It scans JSON files under `res://assets/data/`, parses them with Godot JSON APIs, stores raw dictionaries in memory, and returns raw values to consumers. BigNumber conversion is performed by consumers according to their schemas. | MEDIUM |
| ADR-0009: 在线/离线战斗路径统一 | Both online and offline combat use the same `CombatCalculator` for attack resolution and the same `LootSystem` for rewards. SemiAutoCombatSystem manages live encounter cadence and event publication. OfflineCombatSimulation uses snapshots and copied RNG states to run batched encounters, producing a draft consumed by OfflineRewardSettlement. | LOW |

## GDD Requirements

| TR-ID | Requirement | ADR Coverage |
|-------|-------------|--------------|
| TR-loot-system-001 | LootSystem resolves weighted drops using DataConfig, ItemRegistry, EnemyDatabase, and the LOOT RNG stream. | ADR-0004, ADR-0005, ADR-0009 |

**Untraced requirements**: 0 known in `docs/architecture/tr-registry.yaml`; the registry currently exposes one stable system-level TR for this GDD.

## Engine Risk

**MEDIUM** — highest governing ADR knowledge risk. Engine baseline: Godot 4.6.2.

## Cross-Epic Dependencies

- Upstream: 敌人数据库, 物品/材料系统, 随机数与种子系统
- Downstream: 半自动战斗系统

## Definition of Done

This epic is complete when:
- All stories are implemented, reviewed, and closed via `/story-done`.
- All acceptance criteria from `design/gdd/loot-system.md` are verified.
- All Logic and Integration stories have passing test files under `tests/`.
- All Visual/Feel and UI stories have evidence docs with sign-off under `production/qa/evidence/`.
- Any Godot 4.6.2 behavior named by the governing ADRs is verified against `docs/engine-reference/godot/`.

## Stories

| # | Story | Type | Status | ADR |
|---|-------|------|--------|-----|
| 001 | [bundle includes exp](story-001-bundle-includes-exp.md) | Config/Data | Ready | ADR-0005 |
| 002 | [output is capped deterministically to 5 entries](story-002-output-is-capped-deterministically-to-5-entries.md) | Config/Data | Ready | ADR-0005 |

## Next Step

Run `/story-readiness production/epics/loot-system/story-001-*.md` before implementing the first story in this epic.
