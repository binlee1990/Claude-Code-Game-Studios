# 存储上限系统 (Storage Limit System)

> **Status**: Designed
> **Author**: binlee1990 + agents
> **Last Updated**: 2026-05-04
> **Implements Pillar**: 4.1 数字增长就是快乐 · 4.2 放置不是无操作
> **Creative Director Review (CD-GDD-ALIGN)**: Deferred — batch GDD authoring; run independent `/design-review` in a fresh session.

## Summary

存储上限系统计算并维护可封顶资源与物品堆叠的容量边界。它不持有资源数量，而是把当前上限写入资源系统，并把"即将满仓/已经满仓"的状态提供给 HUD、自动产出和离线结算使用。

> **Quick reference** — Layer: `Feature` · Priority: `MVP` · Key deps: `物品/材料系统, 资源系统`

## Overview

存储上限系统负责回答"还能装多少"。MVP 中 `lingqi` 与 `herb` 这类有上限资源会因挂机和离线收益不断接近上限；如果没有明确的容量系统，玩家离开后回来看到收益丢失会无法判断是系统错误还是自己仓储不足。本系统统一计算每个 capped resource 的 `cap`，调用 `ResourceSystem.set_max(id, cap)` 写入权威账本，并提供容量压力查询给 HUD 和离线收益结算系统。

## Player Fantasy

它服务的是"丹田与仓廪有边界"的修仙感。玩家看到灵气快满时，不是觉得系统在惩罚自己，而是自然理解为"丹田已盈，需要扩容或突破"。这种边界把纯数字增长变成低频决策：继续挂机会浪费，升级储物、切换区域、消耗资源或突破境界都会变得有意义。

## Detailed Design

### Core Rules

1. `StorageLimitSystem` 是 Autoload 服务，只计算上限，不存储当前资源值。
2. MVP 管辖 `has_cap=true` 的资源：`lingqi`、`herb`；`xiuwei`、`lingshi`、`exp` 默认无上限。
3. 上限来源按池合成：配置基础容量、境界容量加成、建筑/仓储加成、临时事件加成。MVP 可只启用基础容量 + 境界加成，建筑加成作为配置字段预留。
4. 每次上限变化都调用 `ResourceSystem.set_max(resource_id, new_cap)`；实际截断和 overflow 事件仍由 ResourceSystem 负责。
5. 提供 `get_capacity_state(id)`：返回 `{current, cap, fill_ratio, state}`，其中 state 为 `safe | warning | full | uncapped`。
6. 不做自动扩容、不扣除升级费用、不决定玩家是否购买仓库；这些属于建筑/宗门系统或 UI 操作层。

### States and Transitions

| State | Entry Condition | Exit Condition | Behavior |
|-------|----------------|----------------|----------|
| Uncapped | `has_cap=false` | 配置改为 capped | 返回 `cap=BigNumber.MAX`，不触发警告 |
| Safe | fill_ratio < warning_threshold | 达到 warning_threshold | 正常产出 |
| Warning | warning_threshold <= fill_ratio < 1.0 | 低于阈值或到达 full | HUD 可提示"将满" |
| Full | fill_ratio >= 1.0 | 消耗资源或上限提高 | 后续 add 会由 ResourceSystem 截断并发 overflow |

### Interactions with Other Systems

| System | Interface | Contract |
|--------|-----------|----------|
| 资源系统 | `set_max`, `get_value`, `get_max` | 资源系统持有权威 current/cap；本系统只写 cap |
| 物品/材料系统 | `get(id)` metadata | 读取 stackable/stack_limit 元数据用于未来背包槽位显示 |
| 等级系统 | `realm.advanced` event | 境界变化后重算容量倍率 |
| 自动产出系统 | `get_capacity_state` | 产出系统可在 full 状态降低无效 tick 频率或记录浪费 |
| 离线收益结算系统 | `get_remaining_capacity` | 离线结算计算可入账量和损失量 |
| HUD 系统 | capacity state query/events | 显示资源条、满仓提示和离线浪费原因 |

## Formulas

The `resource_cap` formula is defined as:

`resource_cap = base_cap * realm_cap_multiplier * storage_cap_multiplier`

**Variables:**
| Variable | Symbol | Type | Range | Description |
|----------|--------|------|-------|-------------|
| base_cap | B | BigNumber | 100-1e30 | 配置表基础容量 |
| realm_cap_multiplier | R | float | 1.0-100.0 | 境界带来的容量倍率 |
| storage_cap_multiplier | S | float | 1.0-1000.0 | 仓储建筑/扩容项倍率，MVP 默认 1.0 |

**Output Range:** 100 to 1e33 under MVP-safe tuning.
**Example:** `lingqi` base 1000, realm x2, storage x1.5 → cap 3000。

The `fill_ratio` formula is defined as:

`fill_ratio = current / cap`

**Variables:**
| Variable | Symbol | Type | Range | Description |
|----------|--------|------|-------|-------------|
| current | C | BigNumber | 0-cap | ResourceSystem 当前数量 |
| cap | M | BigNumber | 1-MAX | ResourceSystem 当前上限 |

**Output Range:** 0.0 to 1.0 after clamping; uncapped resources return 0.0.
**Example:** current 850, cap 1000 → fill_ratio 0.85。

## Edge Cases

- **If cap calculation returns zero or negative**: keep the previous valid cap and print a warning.
- **If current exceeds a newly lowered cap**: call `ResourceSystem.set_max`; ResourceSystem clamps current and emits `cap_changed`, `changed`, and `overflow` in its defined order.
- **If a resource is not registered in ResourceSystem**: skip the cap update and report a configuration warning.
- **If `has_cap=false`**: never emit capacity warnings, even if values are large.
- **If offline rewards exceed remaining capacity**: Offline Reward Settlement applies the cap and records the lost amount; this system only reports remaining capacity.

## Dependencies

| System | Direction | Nature |
|--------|-----------|--------|
| 物品/材料系统 | Upstream | Supplies item metadata and future stack-limit fields |
| 资源系统 | Upstream | Owns current values and authoritative cap storage |
| HUD 系统 | Downstream | Displays capacity state and warnings |
| 离线收益结算系统 | Downstream | Uses remaining capacity to split claimable/lost rewards |

## Tuning Knobs

| Parameter | Current Value | Safe Range | Effect of Increase | Effect of Decrease |
|-----------|--------------|------------|-------------------|-------------------|
| `warning_threshold` | 0.85 | 0.70-0.95 | Warns later, less noise | Warns earlier, more guidance |
| `lingqi_base_cap` | 1000 | 100-1e8 | Longer unattended sessions | More frequent cap pressure |
| `herb_base_cap` | 200 | 50-1e6 | Less material loss | Weakens storage decisions |
| `storage_cap_multiplier_max` | 1000.0 | 10-1e6 | Supports long-term growth | Forces more frequent resets/upgrades |

## Visual/Audio Requirements

No direct visual or audio assets. HUD should render capped resources with a fill bar, warning color at threshold, and a distinct "full" state.

## UI Requirements

Expose current/cap/fill ratio, a compact warning reason, and the last overflow amount. Detailed upgrade UI belongs to future building/sect systems.

## Cross-References

| This Document References | Target GDD | Specific Element Referenced | Nature |
|--------------------------|-----------|-----------------------------|--------|
| Writes resource cap | `design/gdd/resource-system.md` | `set_max`, overflow event ordering | Data dependency |
| Uses item stack metadata | `design/gdd/item-material-system.md` | `stackable`, `stack_limit` | Data dependency |
| Shows cap warnings | `design/gdd/hud-system.md` | resource display contract | Ownership handoff |

## Acceptance Criteria

- **GIVEN** `lingqi` base cap 1000 and no modifiers, **WHEN** storage limits initialize, **THEN** `ResourceSystem.get_max("lingqi") == 1000`.
- **GIVEN** `lingqi` current 900 and cap 1000, **WHEN** `get_capacity_state("lingqi")`, **THEN** state is `warning` and fill_ratio is 0.9.
- **GIVEN** `lingshi` is uncapped, **WHEN** `get_capacity_state("lingshi")`, **THEN** state is `uncapped` and no warning is emitted.
- **GIVEN** a realm multiplier changes from 1.0 to 2.0, **WHEN** storage limits recompute, **THEN** capped resources receive doubled cap through ResourceSystem.
- **GIVEN** a new cap below current value, **WHEN** `set_max` is called, **THEN** ResourceSystem performs clamping and overflow reporting.

## Open Questions

| Question | Owner | Deadline | Resolution |
|----------|-------|----------|------------|
| Whether storage upgrades are unlocked through buildings or realm milestones | Designer | Building/Sect GDD | Pending future system |
| Whether item stack slots share this system or a future backpack system owns them | Designer | Backpack/Bank GDD | MVP only exposes metadata |
