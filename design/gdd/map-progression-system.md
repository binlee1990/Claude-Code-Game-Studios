# 地图推进系统 (Map Progression System)

> **Status**: Approved
> **Author**: binlee1990 + agents
> **Last Updated**: 2026-05-04
> **Implements Pillar**: 4.2 放置不是无操作 · 4.6 渐进叙事展开
> **Design Review (lean)**: APPROVED 2026-05-04 — required sections, dependency references, acceptance criteria, and cross-GDD contracts checked in this cleanup pass.

## Summary

地图推进系统管理区域解锁、首通、当前最高推进点和下一目标提示。它把等级、战斗胜率和区域顺序转化为"该不该去下一张图"的低频决策。

> **Quick reference** — Layer: `Feature Integration` · Priority: `MVP` · Key deps: `区域系统, 等级系统`

## Overview

地图推进系统给 MVP 的三张普通挂机图提供进度结构。区域系统定义地图数据，半自动战斗提供胜负结果，等级系统提供玩家成长；本系统记录哪些区域已解锁、哪些已首通、下一张图需要什么条件，并在满足条件时发布解锁事件。它不选择敌人、不算战斗、不发奖励。

## Player Fantasy

玩家感受到的是"闭关和刷怪真的推开了更大的世界"。当等级达标、上一图稳定通过时，新区域自然亮起，玩家获得一个明确的新目标：要不要承担更高风险去更高收益区。

## Detailed Design

### Core Rules

1. `MapProgressionSystem` 持有 per-save 的 zone progress：`locked | unlocked | cleared | farmable`。
2. 解锁条件由 zone 配置声明，MVP 支持：最低等级、前置区域 cleared、最近胜率、手动首通挑战。
3. 战斗胜利/失败结果通过 `combat.encounter_finished` 事件更新近期胜率窗口。
4. `evaluate_unlocks()` 在 level.changed、zone cleared、save.loaded 后运行。
5. 首通奖励不由本系统发放；它只发 `zone.first_cleared` 事件，奖励由后续奖励系统或 LootSystem context 处理。
6. 自动切换到新区域默认关闭；玩家确认后改变当前 zone，避免无意进入失败循环。

### States and Transitions

| State | Entry Condition | Exit Condition | Behavior |
|-------|----------------|----------------|----------|
| Locked | 条件未满足 | `evaluate_unlocks` 通过 | 不可选择，显示 lock reason |
| Unlocked | 条件满足未首通 | 玩家挑战并胜利 | 可选择，显示新标记 |
| Cleared | 首次胜利达成 | farmability 条件满足 | 记录首通 |
| Farmable | 胜率/效率达到稳定阈值 | 胜率下降 | 推荐为挂机点 |

### Interactions with Other Systems

| System | Interface | Contract |
|--------|-----------|----------|
| 区域系统 | zone list/conditions | 本系统不定义静态区域 |
| 等级系统 | `level.changed` | 触发解锁评估 |
| 半自动战斗系统 | `combat.encounter_finished` | 更新胜率和首通 |
| 存档系统 | provider | 保存区域进度 |
| HUD 系统 | progress queries/events | 显示地图进度和下一目标 |

## Formulas

The `recent_win_rate` formula is defined as:

`recent_win_rate = wins_in_window / max(1, encounters_in_window)`

**Variables:**
| Variable | Symbol | Type | Range | Description |
|----------|--------|------|-------|-------------|
| wins_in_window | W | int | 0-window | 最近窗口胜利数 |
| encounters_in_window | N | int | 0-window | 最近窗口战斗数 |

**Output Range:** 0.0 to 1.0.
**Example:** 8 wins / 10 encounters → 0.8。

The `unlock_ready` formula is defined as:

`unlock_ready = level >= required_level AND prerequisite_cleared AND recent_win_rate >= required_win_rate`

**Variables:**
| Variable | Symbol | Type | Range | Description |
|----------|--------|------|-------|-------------|
| level | L | int | >=1 | 玩家等级 |
| required_level | R | int | >=1 | 区域最低等级 |
| prerequisite_cleared | P | bool | true/false | 前置区域是否首通 |
| recent_win_rate | W | float | 0-1 | 前一区域近期胜率 |
| required_win_rate | T | float | 0-1 | 解锁要求 |

**Output Range:** boolean.
**Example:** level 10 >= 8, prereq true, win_rate 0.75 >= 0.7 → ready。

## Edge Cases

- **If combat events arrive for unknown zone**: ignore and warn.
- **If player level drops after reset**: keep historical cleared flags but mark higher zones temporarily not farmable until conditions recover.
- **If prerequisite chain has a cycle**: data validation should reject; runtime breaks cycle by locking affected zones.
- **If no current zone after load**: select first unlocked zone, otherwise first zone.
- **If recent window has zero encounters**: win rate is 0 for unlock purposes.

## Dependencies

| System | Direction | Nature |
|--------|-----------|--------|
| 区域系统 | Upstream | Static zone list and conditions |
| 等级系统 | Upstream | Player level and level events |
| 半自动战斗系统 | Upstream | Encounter outcomes |
| 存档系统 | Upstream | Persistence provider |
| HUD 系统 | Downstream | Map progress UI |

## Tuning Knobs

| Parameter | Current Value | Safe Range | Effect of Increase | Effect of Decrease |
|-----------|--------------|------------|-------------------|-------------------|
| `win_rate_window_size` | 10 | 3-100 | Smoother confidence | More reactive |
| `required_win_rate_to_unlock` | 0.7 | 0-1 | Safer unlocks | Faster progression |
| `required_win_rate_to_farm` | 0.85 | 0-1 | Stronger farm recommendation | More permissive |
| `auto_switch_new_zone` | false | bool | Less friction | More player control |

## Visual/Audio Requirements

Unlocking a new zone should trigger a clear but lightweight HUD notification. Full map art is optional for MVP.

## UI Requirements

Needs map list/progression strip: locked reason, unlocked badge, cleared marker, farmability recommendation, and current zone selector.

## Cross-References

| This Document References | Target GDD | Specific Element Referenced | Nature |
|--------------------------|-----------|-----------------------------|--------|
| Zone definitions | `design/gdd/zone-system.md` | unlock conditions | Data dependency |
| Level events | `design/gdd/level-system.md` | `level.changed` | State trigger |
| Battle outcomes | `design/gdd/semi-auto-combat-system.md` | `combat.encounter_finished` | State trigger |

## Acceptance Criteria

- **GIVEN** player reaches required level and prerequisite zone is cleared, **WHEN** unlock evaluation runs, **THEN** next zone becomes unlocked.
- **GIVEN** player wins first encounter in an unlocked zone, **WHEN** event is processed, **THEN** zone state becomes cleared and `zone.first_cleared` emits once.
- **GIVEN** recent win rate exceeds farm threshold, **WHEN** HUD queries zone state, **THEN** zone is marked farmable.
- **GIVEN** a locked zone is selected, **WHEN** selection is attempted, **THEN** selection fails with lock reason.
- **GIVEN** save/load roundtrip, **WHEN** progress restores, **THEN** unlocked/cleared states match saved data.
