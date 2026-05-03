# 修炼系统 (Cultivation System)

> **Status**: Approved
> **Author**: binlee1990 + agents
> **Last Updated**: 2026-05-04
> **Implements Pillar**: 4.1 数字增长就是快乐 · 4.2 放置不是无操作
> **Design Review (lean)**: APPROVED 2026-05-04 — required sections, dependency references, acceptance criteria, and cross-GDD contracts checked in this cleanup pass.

## Summary

修炼系统是开局核心玩法：玩家通过自动打坐、手动凝气和闭关姿态让灵气与修为增长。它把自动产出、资源系统和时间管理器连接成"不战斗也在变强"的基础循环。

> **Quick reference** — Layer: `Feature Integration` · Priority: `MVP` · Key deps: `资源系统, 自动产出系统, 时间管理器`

## Overview

修炼系统定义玩家如何从静态资源增长进入修仙主题。自动产出系统负责 tick，产出乘数系统负责每秒速率，资源系统负责入账；修炼系统负责玩家选择的修炼姿态、手动点击加速、灵气凝练为修为的规则，以及何时提示玩家"可以突破/应该换目标"。MVP 不实现完整境界突破，但修炼必须提供足够的 `lingqi/xiuwei` 增长，支撑等级和早期资源循环。

## Player Fantasy

玩家开局从凡人闭关开始，最先看到的是灵气一点点汇聚、修为一点点沉淀。修炼系统的情绪目标是"我什么也不做也在变强，但我偶尔操作能让这次闭关更有效"。手动点击不是长期体力劳动，而是早期建立投入感，随后逐渐退为短时加速仪式。

## Detailed Design

### Core Rules

1. `CultivationSystem` 持有玩家当前修炼姿态：`idle | meditate | condense | closed_door`。
2. `meditate` 姿态偏向灵气产出；`condense` 姿态把部分灵气转为修为；`closed_door` 是未来闭关长时段模式，MVP 可作为高倍率自动姿态预留。
3. 自动产出系统仍负责 tick；修炼系统通过启用姿态 modifier 或在 tick 后执行凝练消费来改变结果。
4. 手动点击 `manual_cultivate()` 立即尝试增加少量灵气，并受点击冷却保护。
5. 凝练修为路径：检查 `ResourceSystem.can_afford("lingqi", cost)`，成功则 `spend("lingqi", cost)` 后 `add("xiuwei", gain)`。
6. 本系统不修改等级；LevelSystem 消费 `exp`，不是 `xiuwei`。`xiuwei` 在 MVP 作为修仙长期资源和未来突破输入。
7. 所有姿态变化发布 `cultivation.stance_changed` 事件，HUD 用于刷新状态。

### States and Transitions

| State | Entry Condition | Exit Condition | Behavior |
|-------|----------------|----------------|----------|
| Idle | 系统未解锁或玩家暂停 | 选择姿态 | 无额外修炼逻辑 |
| Meditate | 默认开局姿态 | 切换姿态 | 维持自动灵气/修为产出 |
| Condense | 玩家选择凝练 | 灵气不足或切换 | 每 tick 后尝试灵气转修为 |
| Closed Door | 达到配置门槛 | 手动结束或资源不足 | 长时段高倍率预留，MVP 可不开启 |

### Interactions with Other Systems

| System | Interface | Contract |
|--------|-----------|----------|
| 资源系统 | `add/spend/can_afford` | 读写 `lingqi` 和 `xiuwei` |
| 自动产出系统 | online cadence | 提供 tick 运行时机 |
| 时间管理器 | pause/freeze behavior | 冻结时修炼不推进 |
| 产出乘数系统 | stance source modifiers | 姿态可注册生产倍率来源 |
| 存储上限系统 | capacity state | 灵气满时提示改变姿态或消耗 |
| HUD 系统 | cultivation events/query | 显示当前姿态、每秒收益和手动冷却 |

## Formulas

The `manual_lingqi_gain` formula is defined as:

`manual_lingqi_gain = base_click_gain * click_multiplier`

**Variables:**
| Variable | Symbol | Type | Range | Description |
|----------|--------|------|-------|-------------|
| base_click_gain | B | BigNumber | 1-1e12 | 手动点击基础灵气 |
| click_multiplier | M | float | 1-100 | 由境界/设置/未来天赋提供 |

**Output Range:** 1 to 1e14 under MVP-safe tuning.
**Example:** base 5, multiplier 2 → 10 lingqi。

The `xiuwei_condense_gain` formula is defined as:

`xiuwei_condense_gain = lingqi_spent * condense_rate * stance_multiplier`

**Variables:**
| Variable | Symbol | Type | Range | Description |
|----------|--------|------|-------|-------------|
| lingqi_spent | L | BigNumber | 0-current lingqi | 本次消耗灵气 |
| condense_rate | R | float | 0.01-1.0 | 灵气到修为转换率 |
| stance_multiplier | S | float | 1-100 | 姿态/闭关倍率 |

**Output Range:** 0 to large BigNumber; capped only by available lingqi.
**Example:** spend 100 lingqi, rate 0.1, stance x1 → 10 xiuwei。

## Edge Cases

- **If lingqi is insufficient for condense cost**: skip conversion and keep stance active unless `auto_fallback_to_meditate` is enabled.
- **If manual click occurs during cooldown**: ignore and return remaining cooldown.
- **If ResourceSystem.spend succeeds but xiuwei add overflows future cap**: ResourceSystem handles target resource semantics; MVP `xiuwei` is uncapped.
- **If TimeManager frozen**: no auto conversion and manual click is disabled.
- **If stance modifier registration fails**: stance changes visually but logs degraded multiplier behavior; base resource operations continue.

## Dependencies

| System | Direction | Nature |
|--------|-----------|--------|
| 资源系统 | Upstream | Owns lingqi/xiuwei values |
| 自动产出系统 | Upstream/Peer | Provides online tick loop |
| 时间管理器 | Upstream | Supplies pause/freeze semantics |
| 产出乘数系统 | Upstream | Supports stance production modifiers |
| HUD 系统 | Downstream | Displays stance and gains |

## Tuning Knobs

| Parameter | Current Value | Safe Range | Effect of Increase | Effect of Decrease |
|-----------|--------------|------------|-------------------|-------------------|
| `base_click_gain` | 5 lingqi | 1-1e6 | Stronger early clicking | Less active value |
| `click_cooldown_seconds` | 0.5 | 0.1-3.0 | Less spam | More clicking |
| `condense_cost_lingqi` | 10 | 1-1e9 | Slower conversion chunks | More frequent small conversions |
| `condense_rate` | 0.1 | 0.01-1.0 | Faster xiuwei growth | More lingqi pressure |
| `auto_fallback_to_meditate` | true | bool | Fewer stalled states | More explicit resource shortage |

## Visual/Audio Requirements

HUD should show stance icon, soft pulse on manual gain, and a distinct "灵气不足" feedback when condense fails. Audio can be a quiet tick or chime, owned by HUD/audio systems.

## UI Requirements

Requires a compact stance control with recommended default `Meditate`, a manual cultivate button with cooldown feedback, and per-second lingqi/xiuwei rates.

## Cross-References

| This Document References | Target GDD | Specific Element Referenced | Nature |
|--------------------------|-----------|-----------------------------|--------|
| Resource writes | `design/gdd/resource-system.md` | `add`, `spend`, `can_afford` | Data dependency |
| Online cadence | `design/gdd/auto-production-system.md` | tick loop | Rule dependency |
| Passive rates | `design/gdd/output-multiplier-system.md` | production modifiers | Data dependency |

## Acceptance Criteria

- **GIVEN** player clicks manual cultivate off cooldown, **WHEN** call executes, **THEN** lingqi increases by `manual_lingqi_gain`.
- **GIVEN** player is in Condense and has enough lingqi, **WHEN** tick conversion runs, **THEN** lingqi decreases and xiuwei increases by formula result.
- **GIVEN** player lacks lingqi, **WHEN** Condense tick runs, **THEN** no xiuwei is added and a shortage state is available to HUD.
- **GIVEN** TimeManager is frozen, **WHEN** manual or auto cultivation tries to run, **THEN** no resource changes occur.
- **GIVEN** stance changes from Meditate to Condense, **WHEN** transition succeeds, **THEN** one `cultivation.stance_changed` event is emitted.
