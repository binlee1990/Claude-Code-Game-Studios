# Epic: 自动产出系统

> **Layer**: Feature
> **GDD**: design/gdd/auto-production-system.md
> **Architecture Module**: `AutoProductionSystem` (Autoload)
> **Status**: Done
> **Stories**: Created (2 stories)

## Overview

自动产出系统把"每秒灵气增长"落实为可靠、可节流、可暂停的在线循环。它不定义基础速率，不计算倍率，不持有资源值；这些分别由产出乘数系统和资源系统负责。本系统只控制在线 tick 何时发生、哪些资源参与、如何批量写入，以及时间冻结、满仓、配置缺失时如何降级。

Architecture ownership: `AutoProductionSystem` owns tick 循环, 产出调度.

## Governing ADRs

| ADR | Decision Summary | Engine Risk |
|-----|------------------|-------------|
| ADR-0003: 时间源与双时间体系 | Implement `TimeManager` as an Autoload that owns a dual-time snapshot: real Unix time and derived game time. All gameplay timing uses `TimeManager`, never direct `_process(delta)` as authority. Online ticks use `get_game_delta_since`; offline settlement uses `min(real_now - exit_timestamp, MAX_OFFLINE_SECONDS)` with speed multiplier ignored. | LOW |
| ADR-0007: 修正器叠加顺序 | Use one `ModifierEngine` service with a three-stage pipeline: `base + add_sum`, then same-pool additive percentage multipliers, then cross-pool multiplication. MVP pools are `equipment`, `realm`, `zone`, and `buff`. Targets are strings such as `player.atk` and `lingqi_production`. | LOW |
| ADR-0010: ResourceSystem 不可变 BigNumber 策略 | ResourceSystem stores BigNumber values as immutable value objects. Operations calculate new BigNumber instances and replace the stored value. `add()` returns the actual added amount. `spend()` is atomic per resource. `batch_add()` executes sequential per-resource adds and returns a dictionary of actual additions; it does not roll back earlier successful changes. | LOW |

## GDD Requirements

| TR-ID | Requirement | ADR Coverage |
|-------|-------------|--------------|
| TR-auto-production-001 | AutoProductionSystem uses TimeManager deltas and OutputMultiplierSystem rates to batch-add online passive resource gains. | ADR-0003, ADR-0007, ADR-0010 |

**Untraced requirements**: 0 known in `docs/architecture/tr-registry.yaml`; the registry currently exposes one stable system-level TR for this GDD.

## Engine Risk

**LOW** — highest governing ADR knowledge risk. Engine baseline: Godot 4.6.2.

## Cross-Epic Dependencies

- Upstream: 资源系统, 时间管理器, 产出乘数系统
- Downstream: 修炼系统

## Definition of Done

This epic is complete when:
- All stories are implemented, reviewed, and closed via `/story-done`.
- All acceptance criteria from `design/gdd/auto-production-system.md` are verified.
- All Logic and Integration stories have passing test files under `tests/`.
- All Visual/Feel and UI stories have evidence docs with sign-off under `production/qa/evidence/`.
- Any Godot 4.6.2 behavior named by the governing ADRs is verified against `docs/engine-reference/godot/`.

## Stories

| # | Story | Type | Status | ADR |
|---|-------|------|--------|-----|
| 001 | [ResourceSystem receives lingqi +1](story-001-resourcesystem-receives-lingqi-1.md) | Integration | Done | ADR-0003 |
| 002 | [exp is never requested from OMS](story-002-exp-is-never-requested-from-oms.md) | Config/Data | Done | ADR-0003 |

## Next Step

Run `/story-readiness production/epics/auto-production-system/story-001-*.md` before implementing the first story in this epic.
