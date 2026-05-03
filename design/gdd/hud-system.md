# HUD 系统 (HUD System)

> **Status**: Designed
> **Author**: binlee1990 + agents
> **Last Updated**: 2026-05-04
> **Implements Pillar**: 4.1 数字增长就是快乐 · 4.2 放置不是无操作 · 4.6 渐进叙事展开
> **Creative Director Review (CD-GDD-ALIGN)**: Deferred — batch GDD authoring; run independent `/design-review` in a fresh session.

## Summary

HUD 系统是玩家第一屏的信息仪表盘：资源、修为/等级、当前区域、战斗状态、通知入口和离线收益入口。它只展示和发出玩家命令，不拥有玩法状态。

> **Quick reference** — Layer: `Presentation` · Priority: `MVP` · Key deps: `UI 框架, 数值格式化系统, 资源系统, 区域系统`

## Overview

HUD 是 MVP 闭环能否被玩家理解的关键。资源系统、等级系统、战斗系统、区域系统和离线结算都已经产生数据；HUD 把它们整理成可扫读的状态：我有多少资源、当前在哪里、战斗是否顺利、离线获得了什么、下一步为什么被卡住。HUD 不应成为所有逻辑的 God Object，它只订阅事件、查询只读 API、调用明确 command。

## Player Fantasy

玩家回到游戏时，HUD 应该在几秒内回答三个问题：我变强了吗？现在卡在哪里？下一步能做什么？数字跳动、区域名、战斗日志和离线摘要共同传达"世界仍在运转"。

## Detailed Design

### Core Rules

1. HUD 由 UI Framework 承载，默认常驻。
2. 顶栏显示 MVP 资源：`lingqi/xiuwei/lingshi/herb/exp`，使用 NumberFormattingSystem。
3. Capped resources 显示 current/cap/fill bar；uncapped 显示当前值和变化速率。
4. 显示等级/境界：订阅 `level.changed` 与 `realm.advanced`，查询 LevelSystem。
5. 显示当前区域和战斗状态：订阅 `zone.changed`、`combat.encounter_finished`。
6. 显示离线入口：收到 `offline.settled` 后打开/标记离线收益摘要。
7. 资源/属性高频刷新必须 coalesce，避免每次事件重建整个 HUD。
8. HUD 不直接写 ResourceSystem；所有按钮调用对应系统 command。

### States and Transitions

| State | Entry Condition | Exit Condition | Behavior |
|-------|----------------|----------------|----------|
| Loading | UI 初始化或 save load | 数据源 ready | 显示骨架/占位 |
| Normal | 数据可用 | 警告/离线摘要/错误 | 常规显示 |
| Warning | 满仓、失败、可解锁等 | 条件解除 | 高亮相关模块 |
| OfflineSummaryReady | `offline.settled` received | 玩家查看/关闭 | 显示入口或弹窗 |
| Degraded | 某数据源缺失 | 恢复 | 显示错误而非崩溃 |

### Interactions with Other Systems

| System | Interface | Contract |
|--------|-----------|----------|
| UI 框架 | components/navigation | HUD 宿主 |
| 数值格式化系统 | format BigNumber | 所有资源数字 |
| 资源系统 | events/query | 资源 current/cap |
| 区域系统 | current zone | 区域显示 |
| 等级系统 | events/query | 等级/境界显示 |
| 半自动战斗系统 | combat events/query | 战斗状态和日志 |
| 离线收益结算系统 | `offline.settled` | 离线摘要 |
| 物品/材料系统 | rarity/item metadata | 掉落/资源 tooltip |

## Formulas

The `resource_alert_severity` formula is defined as:

`resource_alert_severity = max(fill_ratio, recent_lost_ratio)`

**Variables:**
| Variable | Symbol | Type | Range | Description |
|----------|--------|------|-------|-------------|
| fill_ratio | F | float | 0-1 | 当前容量占比 |
| recent_lost_ratio | L | float | 0-1 | 最近离线/在线溢出损失比例 |

**Output Range:** 0.0 to 1.0.
**Example:** fill 0.86, lost 0.2 → severity 0.86。

The `hud_refresh_interval` formula is defined as:

`hud_refresh_interval = max(MIN_REFRESH_INTERVAL, 1 / max(display_rate_hz, 1))`

**Variables:**
| Variable | Symbol | Type | Range | Description |
|----------|--------|------|-------|-------------|
| MIN_REFRESH_INTERVAL | M | float | 0.05-1.0 | 最小刷新间隔 |
| display_rate_hz | H | float | 1-60 | 期望显示刷新率 |

**Output Range:** MIN_REFRESH_INTERVAL to 1s.
**Example:** min 0.1, display 10Hz → 0.1s。

## Edge Cases

- **If ResourceSystem loads after HUD**: HUD shows loading state and performs full refresh on `save.loaded` or resource-ready event.
- **If number formatting fails**: show raw scientific notation fallback and log warning.
- **If resource cap decreases below current**: update cap before current display to match ResourceSystem event order.
- **If event burst occurs in one frame**: keep latest values and refresh once.
- **If current zone is invalid**: show "未选择区域" and disable combat start command.

## Dependencies

| System | Direction | Nature |
|--------|-----------|--------|
| UI 框架 | Upstream | Components and screen host |
| 数值格式化系统 | Upstream | BigNumber display |
| 资源系统 | Upstream | Resource values/events |
| 区域系统 | Upstream | Current zone |
| 等级系统 | Upstream | Level/realm |
| 半自动战斗系统 | Upstream | Combat state |
| 离线收益结算系统 | Upstream | Offline summary |

## Tuning Knobs

| Parameter | Current Value | Safe Range | Effect of Increase | Effect of Decrease |
|-----------|--------------|------------|-------------------|-------------------|
| `display_rate_hz` | 10 | 1-30 | Smoother numbers | Less UI work |
| `MIN_REFRESH_INTERVAL` | 0.1s | 0.05-1.0 | Less CPU | Slower feedback |
| `resource_warning_threshold` | 0.85 | 0.7-0.95 | Later warning | Earlier warning |
| `battle_log_rows` | 8 | 3-50 | More context | Less clutter |
| `offline_auto_popup` | true | bool | Immediate return feedback | Less interruption |

## Visual/Audio Requirements

HUD must be compact and readable: top resource strip, central/current activity status, right or lower battle log depending layout, clear warning colors, and restrained motion. Rare/notable events can use stronger color/audio, but MVP common resource ticks should be subtle.

## UI Requirements

Required elements: resource strip, level/realm badge, current zone selector entry, combat status/log, cultivation stance indicator, offline summary entry, warning/notification stack, settings/debug affordance in development builds.

## Cross-References

| This Document References | Target GDD | Specific Element Referenced | Nature |
|--------------------------|-----------|-----------------------------|--------|
| Components | `design/gdd/ui-framework.md` | HUD host/components | Ownership handoff |
| Resource display | `design/gdd/resource-system.md` | resource events and caps | Data dependency |
| Formatting | `design/gdd/number-formatting-system.md` | BigNumber format | Data dependency |
| Zone display | `design/gdd/zone-system.md` | current zone | Data dependency |

## Acceptance Criteria

- **GIVEN** resource.lingqi.changed emits, **WHEN** HUD refreshes, **THEN** lingqi text updates using NumberFormattingSystem.
- **GIVEN** lingqi fill ratio exceeds threshold, **WHEN** HUD renders, **THEN** resource row shows warning state.
- **GIVEN** `offline.settled` event arrives, **WHEN** HUD handles it, **THEN** offline summary entry becomes visible or modal opens per setting.
- **GIVEN** `level.changed` includes entity_id player, **WHEN** HUD handles it, **THEN** level badge updates after attributes are already recalculated.
- **GIVEN** 50 resource events in one frame, **WHEN** HUD updates, **THEN** only one layout refresh occurs.

## Open Questions

| Question | Owner | Deadline | Resolution |
|----------|-------|----------|------------|
| Exact desktop layout split between battle log and resource panels | UX | UX spec | Recommended: dense dashboard, no marketing-style hero |
| Whether common resource ticks animate every update | UX/Performance | Playtest | Default: text updates only; animate threshold/rare events |
