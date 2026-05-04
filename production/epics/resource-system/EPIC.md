# Epic: 资源系统

> **Layer**: Core Gameplay
> **GDD**: design/gdd/resource-system.md
> **Architecture Module**: `ResourceSystem` (RefCounted) (Autoload 持有)
> **Status**: Done
> **Stories**: Created (13 stories)

## Overview

资源系统是游戏中所有"数字资产"的统一存储、读写与变更通知服务。游戏世界的状态——你修了多久、你有多少灵石、矿石、药材、丹药——全部以"资源 ID → BigNumber 数值"的映射形式存放在这里。它不创造资源（产出由自动产出系统负责）、不计算资源倍率（由产出乘数系统/修正器引擎负责）、不消费资源（由战斗、修炼、合成等业务系统通过本系统的 API 触发）；它只回答四个问题：**你有多少？你的上限是多少？你能/不能扣这个数？我帮你加/扣完了，谁需要被通知？**

Architecture ownership: `ResourceSystem (RefCounted)` owns 资源 ID→BigNumber CRUD, 变更事件.

## Governing ADRs

| ADR | Decision Summary | Engine Risk |
|-----|------------------|-------------|
| ADR-0010: ResourceSystem 不可变 BigNumber 策略 | ResourceSystem stores BigNumber values as immutable value objects. Operations calculate new BigNumber instances and replace the stored value. `add()` returns the actual added amount. `spend()` is atomic per resource. `batch_add()` executes sequential per-resource adds and returns a dictionary of actual additions; it does not roll back earlier successful changes. | LOW |
| ADR-0001: BigNumber 实现策略 | Implement `BigNumber` as an immutable `RefCounted` GDScript value type using `mantissa: float` and `exponent: int`. Normalized non-zero values keep `mantissa` in `[1.0, 10.0)` and `exponent` in `[0, 308]`. Zero is `{0.0, 0}`. Overflow saturates to `MAX`; negative or sub-unit absolute results clamp to `ZERO`. | HIGH |
| ADR-0002: 事件总线架构 | Use a global `EventBus` Autoload Node with string event names and `Dictionary` payloads. The bus dispatches events synchronously in the current frame. Exact subscriptions are the production path. Prefix pattern subscriptions exist only for debug tooling such as `event watch resource`. Coalesced events are allowed only for display refreshes where latest-state wins. | HIGH |

## GDD Requirements

| TR-ID | Requirement | ADR Coverage |
|-------|-------------|--------------|
| TR-resource-system-001 | ResourceSystem owns resource CRUD, BigNumber balances, caps, overflow events, reset scopes, batch_add, snapshot, and restore. | ADR-0010, ADR-0001, ADR-0002 |

**Untraced requirements**: 0 known in `docs/architecture/tr-registry.yaml`; the registry currently exposes one stable system-level TR for this GDD.

## Engine Risk

**HIGH** — highest governing ADR knowledge risk. Engine baseline: Godot 4.6.2.

## Cross-Epic Dependencies

- Upstream: 大数值系统, 事件总线, 数据配置系统
- Downstream: 调试控制台, 等级系统, 存储上限系统, 自动产出系统, 修炼系统, HUD 系统

## Definition of Done

This epic is complete when:
- All stories are implemented, reviewed, and closed via `/story-done`.
- All acceptance criteria from `design/gdd/resource-system.md` are verified.
- All Logic and Integration stories have passing test files under `tests/`.
- All Visual/Feel and UI stories have evidence docs with sign-off under `production/qa/evidence/`.
- Any Godot 4.6.2 behavior named by the governing ADRs is verified against `docs/engine-reference/godot/`.

## Stories

| # | Story | Type | Status | ADR |
|---|-------|------|--------|-----|
| 001 | [Core CRUD 1](story-001-core-crud-1.md) | Config/Data | Done | ADR-0010 |
| 002 | [Core CRUD 2](story-002-core-crud-2.md) | Logic | Done | ADR-0001 |
| 003 | [Core CRUD 3](story-003-core-crud-3.md) | Integration | Done | ADR-0002 |
| 004 | [Core CRUD 4](story-004-core-crud-4.md) | Integration | Done | ADR-0002 |
| 005 | [Events 1](story-005-events-1.md) | Integration | Done | ADR-0002 |
| 006 | [Events 2](story-006-events-2.md) | Integration | Done | ADR-0002 |
| 007 | [set_max 1](story-007-set-max-1.md) | Integration | Done | ADR-0002 |
| 008 | [set_max 2](story-008-set-max-2.md) | Logic | Done | ADR-0001 |
| 009 | [Reset 1](story-009-reset-1.md) | Integration | Done | ADR-0002 |
| 010 | [Reset 2](story-010-reset-2.md) | Logic | Done | ADR-0001 |
| 011 | [Snapshot / Restore](story-011-snapshot-restore.md) | Config/Data | Done | ADR-0010 |
| 012 | [Edge Cases](story-012-edge-cases.md) | Logic | Done | ADR-0001 |
| 013 | [Performance / Memory](story-013-performance-memory.md) | Integration | Done | ADR-0002 |

## Next Step

Run `/story-readiness production/epics/resource-system/story-001-*.md` before implementing the first story in this epic.
