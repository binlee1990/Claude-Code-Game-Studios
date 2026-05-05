# Epic: Content Data Configuration（内容数据配置）

> **Layer**: Config/Data
> **GDD**: design/balance/mvp-content-progression.md · design/gdd/enemy-database.md · design/gdd/zone-system.md · design/gdd/loot-system.md
> **Architecture Module**: DataConfigSystem (RefCounted) (Autoload 持有)
> **Status**: Done
> **Stories**: 6 stories

## Overview

将 mvp-content-progression.md 中定义的 3 区域 15 敌人完整数值配置转化为 Godot DataConfigSystem 可加载的 JSON 数据文件。覆盖所有敌人的属性、掉落表、区域解锁条件、经验曲线和离线倍率参数。全部数据仅含 MVP 必达项（exp / lingshi / herb），不含装备/碎片/稀有材料（Phase 2+）。

## Governing ADRs

| ADR | Decision Summary | Engine Risk |
|-----|------------------|-------------|
| ADR-0005: 数据配置加载策略 | JSON/CSV/Godot Resource 加载，支持角色、怪物、装备、建筑、技能、掉落表 | LOW |
| ADR-0013: FormulaEngine 表达式 DSL 深度 | 所有数值必须可在公式引擎中表达 | LOW |

## GDD Requirements

| TR-ID | Requirement | ADR Coverage |
|-------|-------------|--------------|
| TR-enemy-database-001 | 15 敌人完整属性配置 | ADR-0005 |
| TR-zone-system-001 | 3 区域解锁/毕业条件 + 敌人池 | ADR-0005 |
| TR-loot-system-001 | 15 敌人 × 掉落表（exp/lingshi/herb）| ADR-0005 |

## Cross-Epic Dependencies

- Upstream: 数据配置系统、敌人数据库、区域系统、掉落系统
- Downstream: FTUE Onboarding、半自动战斗系统

## Definition of Done

- [x] enemies.json: 15 敌人完整属性（S12-001..003）
- [x] zones.json: 3 区域解锁/毕业条件 + 敌人池（S12-005）
- [x] loot_tables.json: 15 敌人掉落表（S12-001..003）
- [x] 经验曲线数据配置（S12-004）
- [x] 离线倍率配置（S12-006）
- [x] DataConfigSystem 能成功加载所有新数据
- [x] 数值与 mvp-content-progression.md 一致

## Stories

| # | Story | Type | Status |
|---|-------|------|--------|
| 001 | Zone 1（青丘山林）敌人+掉落 JSON | Config/Data | Done |
| 002 | Zone 2（幽墟灵谷）敌人+掉落 JSON | Config/Data | Done |
| 003 | Zone 3（荒殒战场）敌人+掉落 JSON | Config/Data | Done |
| 004 | 经验曲线 Lv.1-30 JSON | Config/Data | Done |
| 005 | 区域解锁条件 JSON | Config/Data | Done |
| 006 | 离线倍率 + 经济参数 JSON | Config/Data | Done |
