# 自动产出系统 (Auto Production System)

> **Status**: Designed
> **Author**: binlee1990 + agents
> **Last Updated**: 2026-05-04
> **Implements Pillar**: 4.1 数字增长就是快乐 · 4.8 自动化是成长奖励
> **Creative Director Review (CD-GDD-ALIGN)**: Deferred — batch GDD authoring; run independent `/design-review` in a fresh session.

## Summary

自动产出系统是在线挂机 tick 编排者。它从时间管理器取得游戏时间差，向产出乘数系统请求每个被动资源的 tick 入账量，再通过资源系统写入结果。

> **Quick reference** — Layer: `Feature` · Priority: `MVP` · Key deps: `资源系统, 时间管理器, 产出乘数系统`

## Overview

自动产出系统把"每秒灵气增长"落实为可靠、可节流、可暂停的在线循环。它不定义基础速率，不计算倍率，不持有资源值；这些分别由产出乘数系统和资源系统负责。本系统只控制在线 tick 何时发生、哪些资源参与、如何批量写入，以及时间冻结、满仓、配置缺失时如何降级。

## Player Fantasy

玩家感受到的是"我不点也在修行"。自动产出让修仙者进入打坐状态后，灵气和修为持续跳动；玩家偶尔回来检查，看到数字稳稳上涨，理解为角色一直在运转。它是早期放置承诺的第一根支柱。

## Detailed Design

### Core Rules

1. `AutoProductionSystem` 在在线状态下按固定逻辑 tick，推荐 `tick_interval_seconds = 1.0`。
2. 每次 tick 使用 `TimeManager.get_game_delta_since(last_tick_game_time)`；冻结或 delta<=0 时跳过。
3. MVP 被动资源列表：`lingqi`、`xiuwei`、`lingshi`、`herb`；`exp` 不走自动产出。
4. 对每个资源调用 `OutputMultiplierSystem.get_tick_amount(resource_id, delta)`，返回非 ZERO 时调用 `ResourceSystem.add(resource_id, amount)`。
5. 多资源写入通过 `ResourceSystem.batch_add` 批量提交；批量语义沿用资源系统的非原子约定。
6. 本系统不读取 UI，也不主动弹提示；overflow、changed 事件由资源系统发给 HUD。
7. 离线期间不运行本系统；离线收益由 Offline Simulation Core 和 Offline Reward Settlement 处理。

### States and Transitions

| State | Entry Condition | Exit Condition | Behavior |
|-------|----------------|----------------|----------|
| Disabled | 系统未解锁或初始化失败 | 配置加载成功且系统解锁 | 不 tick |
| Running | 在线、未冻结 | freeze / pause / shutdown | 正常按时间差产出 |
| Paused | 手动暂停或时间冻结 | unpause / unfreeze | 记录新基准时间，不补发暂停期间收益 |
| Degraded | 某资源配置缺失 | 配置恢复 | 跳过该资源并报警，其他资源继续 |

### Interactions with Other Systems

| System | Interface | Contract |
|--------|-----------|----------|
| 时间管理器 | `get_game_delta_since` | 唯一在线 delta 来源 |
| 产出乘数系统 | `get_tick_amount` | 负责速率、倍率和亚单位 carry |
| 资源系统 | `batch_add` | 权威入账、cap、overflow |
| 存储上限系统 | `get_capacity_state` optional | 可用于调试和产出浪费统计，不阻塞入账 |
| 修炼系统 | enable/disable focus modes | 修炼可改变参与资源或加成来源，但不接管 tick |
| HUD 系统 | reads events from ResourceSystem | 本系统不直接驱动 HUD |

## Formulas

The `tick_due` formula is defined as:

`tick_due = game_time_now - last_tick_game_time >= tick_interval_seconds`

**Variables:**
| Variable | Symbol | Type | Range | Description |
|----------|--------|------|-------|-------------|
| game_time_now | Tn | float | >=0 | 当前游戏时间 |
| last_tick_game_time | Tl | float | >=0 | 上次产出 tick 时间 |
| tick_interval_seconds | I | float | 0.25-5.0 | tick 间隔 |

**Output Range:** boolean.
**Example:** now 12.0, last 11.0, interval 1.0 → due true。

The `batch_tick_amount` formula is defined as:

`batch_tick_amount(resource) = OMS.get_tick_amount(resource, delta_seconds)`

**Variables:**
| Variable | Symbol | Type | Range | Description |
|----------|--------|------|-------|-------------|
| resource | r | string | configured resources | 被动资源 ID |
| delta_seconds | d | float | 0-MAX_DELTA | 本次结算时间差 |

**Output Range:** BigNumber.ZERO or positive BigNumber.
**Example:** lingqi rate 3/s, delta 2s → 6 lingqi。

## Edge Cases

- **If delta is extremely large while online**: clamp to `MAX_ONLINE_DELTA_SECONDS` and log; true offline is handled elsewhere.
- **If ResourceSystem rejects a resource id**: skip that id and continue the batch.
- **If OMS returns ZERO because of fractional carry**: do not call ResourceSystem for that id.
- **If TimeManager is frozen**: transition to Paused and do not compensate missed time after unfreeze.
- **If a resource is full**: ResourceSystem handles clamping and overflow; AutoProduction still records attempted output in debug counters.

## Dependencies

| System | Direction | Nature |
|--------|-----------|--------|
| 资源系统 | Upstream | Receives produced BigNumber amounts |
| 时间管理器 | Upstream | Supplies online game delta |
| 产出乘数系统 | Upstream | Computes per-resource tick amount |
| 修炼系统 | Downstream/Peer | Uses this loop for passive cultivation cadence |
| 离线收益结算系统 | Peer | Owns offline path; no shared runtime loop |

## Tuning Knobs

| Parameter | Current Value | Safe Range | Effect of Increase | Effect of Decrease |
|-----------|--------------|------------|-------------------|-------------------|
| `tick_interval_seconds` | 1.0 | 0.25-5.0 | Fewer writes, less responsive | More frequent number updates |
| `MAX_ONLINE_DELTA_SECONDS` | 10.0 | 2.0-60.0 | Handles hitches smoothly | Avoids accidental burst after pause |
| `passive_resource_ids` | 4 resources | 1-20 ids | Adds more automated resources | Reduces MVP scope |
| `debug_waste_tracking` | true | bool | Better balancing data | Less overhead/logging |

## Visual/Audio Requirements

No direct visual or audio assets. Resource changes are visualized through HUD subscriptions to ResourceSystem events.

## UI Requirements

Expose debug-only production status: enabled, last tick, per-resource attempted/actual added, and lost amount. Player-facing toggle belongs to future automation settings.

## Cross-References

| This Document References | Target GDD | Specific Element Referenced | Nature |
|--------------------------|-----------|-----------------------------|--------|
| Online delta | `design/gdd/time-manager.md` | game-time delta and freeze semantics | Data dependency |
| Tick amount | `design/gdd/output-multiplier-system.md` | `get_tick_amount` and fractional carry | Data dependency |
| Resource write | `design/gdd/resource-system.md` | `batch_add` non-atomic semantics | Rule dependency |

## Acceptance Criteria

- **GIVEN** TimeManager reports delta 1.0s and OMS returns lingqi 1, **WHEN** auto production ticks, **THEN** ResourceSystem receives lingqi +1.
- **GIVEN** OMS returns ZERO for herb due to fractional carry, **WHEN** tick runs, **THEN** ResourceSystem is not called for herb.
- **GIVEN** TimeManager is frozen, **WHEN** tick update runs, **THEN** no resources are added.
- **GIVEN** exp is configured as non-passive, **WHEN** tick runs, **THEN** exp is never requested from OMS.
- **GIVEN** one resource id is invalid, **WHEN** batch production runs, **THEN** valid resources still settle.

## Open Questions

| Question | Owner | Deadline | Resolution |
|----------|-------|----------|------------|
| Whether player-facing auto-production toggles are MVP or settings-system scope | Designer | Settings GDD | MVP keeps always-on after unlock |
| Whether manual click production shares this loop or remains in cultivation | Designer | Cultivation implementation | Manual click belongs to CultivationSystem |
