# Epic: 修炼系统

> **Layer**: Feature Integration
> **GDD**: design/gdd/cultivation-system.md
> **Architecture Module**: `CultivationSystem` (服务)
> **Status**: Done
> **Stories**: Created (2 stories)

## Overview

修炼系统定义玩家如何从静态资源增长进入修仙主题。自动产出系统负责 tick，产出乘数系统负责每秒速率，资源系统负责入账；修炼系统负责玩家选择的修炼姿态、手动点击加速、灵气凝练为修为的规则，以及何时提示玩家"可以突破/应该换目标"。MVP 不实现完整境界突破，但修炼必须提供足够的 `lingqi/xiuwei` 增长，支撑等级和早期资源循环。

Architecture ownership: `CultivationSystem` owns 修炼姿态, 凝练逻辑.

## Governing ADRs

| ADR | Decision Summary | Engine Risk |
|-----|------------------|-------------|
| ADR-0003: 时间源与双时间体系 | Implement `TimeManager` as an Autoload that owns a dual-time snapshot: real Unix time and derived game time. All gameplay timing uses `TimeManager`, never direct `_process(delta)` as authority. Online ticks use `get_game_delta_since`; offline settlement uses `min(real_now - exit_timestamp, MAX_OFFLINE_SECONDS)` with speed multiplier ignored. | LOW |
| ADR-0007: 修正器叠加顺序 | Use one `ModifierEngine` service with a three-stage pipeline: `base + add_sum`, then same-pool additive percentage multipliers, then cross-pool multiplication. MVP pools are `equipment`, `realm`, `zone`, and `buff`. Targets are strings such as `player.atk` and `lingqi_production`. | LOW |
| ADR-0010: ResourceSystem 不可变 BigNumber 策略 | ResourceSystem stores BigNumber values as immutable value objects. Operations calculate new BigNumber instances and replace the stored value. `add()` returns the actual added amount. `spend()` is atomic per resource. `batch_add()` executes sequential per-resource adds and returns a dictionary of actual additions; it does not roll back earlier successful changes. | LOW |

## GDD Requirements

| TR-ID | Requirement | ADR Coverage |
|-------|-------------|--------------|
| TR-cultivation-system-001 | CultivationSystem uses resource, auto-production, and time services to orchestrate cultivation stance and progress. | ADR-0003, ADR-0007, ADR-0010 |

**Untraced requirements**: 0 known in `docs/architecture/tr-registry.yaml`; the registry currently exposes one stable system-level TR for this GDD.

## Engine Risk

**LOW** — highest governing ADR knowledge risk. Engine baseline: Godot 4.6.2.

## Cross-Epic Dependencies

- Upstream: 资源系统, 自动产出系统, 时间管理器
- Downstream: None listed in `systems-index.md`

## Definition of Done

This epic is complete when:
- All stories are implemented, reviewed, and closed via `/story-done`.
- All acceptance criteria from `design/gdd/cultivation-system.md` are verified.
- All Logic and Integration stories have passing test files under `tests/`.
- All Visual/Feel and UI stories have evidence docs with sign-off under `production/qa/evidence/`.
- Any Godot 4.6.2 behavior named by the governing ADRs is verified against `docs/engine-reference/godot/`.

## Stories

| # | Story | Type | Status | ADR |
|---|-------|------|--------|-----|
| 001 | [lingqi increases by `manual_lingqi_gain`](story-001-lingqi-increases-by-manual-lingqi-gain.md) | UI | Done | ADR-0003 |
| 002 | [no resource changes occur](story-002-no-resource-changes-occur.md) | Integration | Done | ADR-0003 |

## Next Step

Run `/story-readiness production/epics/cultivation-system/story-001-*.md` before implementing the first story in this epic.
