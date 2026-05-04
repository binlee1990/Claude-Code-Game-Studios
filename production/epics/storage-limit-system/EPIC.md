# Epic: 存储上限系统

> **Layer**: Feature
> **GDD**: design/gdd/storage-limit-system.md
> **Architecture Module**: `StorageLimitSystem` (Autoload)
> **Status**: Ready
> **Stories**: Created (2 stories)

## Overview

存储上限系统负责回答"还能装多少"。MVP 中 `lingqi` 与 `herb` 这类有上限资源会因挂机和离线收益不断接近上限；如果没有明确的容量系统，玩家离开后回来看到收益丢失会无法判断是系统错误还是自己仓储不足。本系统统一计算每个 capped resource 的 `cap`，调用 `ResourceSystem.set_max(id, cap)` 写入权威账本，并提供容量压力查询给 HUD 和离线收益结算系统。

Architecture ownership: `StorageLimitSystem` owns 上限计算公式.

## Governing ADRs

| ADR | Decision Summary | Engine Risk |
|-----|------------------|-------------|
| ADR-0010: ResourceSystem 不可变 BigNumber 策略 | ResourceSystem stores BigNumber values as immutable value objects. Operations calculate new BigNumber instances and replace the stored value. `add()` returns the actual added amount. `spend()` is atomic per resource. `batch_add()` executes sequential per-resource adds and returns a dictionary of actual additions; it does not roll back earlier successful changes. | LOW |
| ADR-0005: 数据配置加载策略 | Implement `DataConfig` as a `RefCounted` service held by an Autoload host. It scans JSON files under `res://assets/data/`, parses them with Godot JSON APIs, stores raw dictionaries in memory, and returns raw values to consumers. BigNumber conversion is performed by consumers according to their schemas. | MEDIUM |

## GDD Requirements

| TR-ID | Requirement | ADR Coverage |
|-------|-------------|--------------|
| TR-storage-limit-001 | StorageLimitSystem computes resource caps and applies them through ResourceSystem ownership boundaries. | ADR-0010, ADR-0005 |

**Untraced requirements**: 0 known in `docs/architecture/tr-registry.yaml`; the registry currently exposes one stable system-level TR for this GDD.

## Engine Risk

**MEDIUM** — highest governing ADR knowledge risk. Engine baseline: Godot 4.6.2.

## Cross-Epic Dependencies

- Upstream: 物品/材料系统, 资源系统
- Downstream: None listed in `systems-index.md`

## Definition of Done

This epic is complete when:
- All stories are implemented, reviewed, and closed via `/story-done`.
- All acceptance criteria from `design/gdd/storage-limit-system.md` are verified.
- All Logic and Integration stories have passing test files under `tests/`.
- All Visual/Feel and UI stories have evidence docs with sign-off under `production/qa/evidence/`.
- Any Godot 4.6.2 behavior named by the governing ADRs is verified against `docs/engine-reference/godot/`.

## Stories

| # | Story | Type | Status | ADR |
|---|-------|------|--------|-----|
| 001 | [`ResourceSystem.get_max("lingqi") == 1000`](story-001-resourcesystem-get-max-lingqi-1000.md) | Integration | Ready | ADR-0010 |
| 002 | [capped resources receive doubled cap through ResourceSystem](story-002-capped-resources-receive-doubled-cap-through-resourcesys.md) | Integration | Ready | ADR-0010 |

## Next Step

Run `/story-readiness production/epics/storage-limit-system/story-001-*.md` before implementing the first story in this epic.
