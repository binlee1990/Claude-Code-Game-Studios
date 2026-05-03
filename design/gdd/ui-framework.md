# UI 框架 (UI Framework)

> **Status**: Designed
> **Author**: binlee1990 + agents
> **Last Updated**: 2026-05-04
> **Implements Pillar**: 4.2 放置不是无操作 · 4.6 渐进叙事展开 · 4.10 数据驱动与可扩展
> **Creative Director Review (CD-GDD-ALIGN)**: Deferred — batch GDD authoring; run independent `/design-review` in a fresh session.

## Summary

UI 框架提供 Godot 4 下所有界面共用的页面注册、导航、弹窗、列表、提示框、数据绑定和刷新节流能力。它不拥有玩法状态，只把各系统的状态稳定呈现给玩家。

> **Quick reference** — Layer: `Presentation` · Priority: `MVP` · Key deps: `事件总线`

## Overview

本项目是 2D UI 驱动的半放置 RPG，核心交互是配置、管理、筛选和规划。UI 框架必须先建立统一的页面/弹窗/列表/提示基础，否则 HUD、区域选择、离线结算和调试界面会各自实现刷新逻辑，导致信息密度不可控。MVP 框架重点是稳定、清晰、可扩展，而不是华丽动画。

## Player Fantasy

玩家面对的是一个越来越大的修仙世界，但界面不能变成菜单地狱。UI 框架的情绪目标是"复杂但可管理"：新系统逐步出现，旧信息保持可扫读，玩家始终知道当前资源、当前目标和下一步入口在哪里。

## Detailed Design

### Core Rules

1. UI 框架由 Godot `Control` 场景集合 + `UIManager` Autoload 组成。
2. 页面通过 `register_screen(screen_id, scene_path, unlock_condition)` 注册。
3. 导航栈支持 `open_screen`、`close_screen`、`replace_screen`、`open_modal`。
4. UI 只订阅 EventBus 和查询只读 API，不直接修改核心系统，玩家命令通过明确 command 方法发送。
5. 高频数据刷新使用 coalesced UI refresh 或本地节流；不得每帧轮询全部系统。
6. 列表组件支持基础虚拟化，避免后期背包/日志/图鉴大量条目卡顿。
7. 所有数字显示通过 Number Formatting System；UI 不自行格式化 BigNumber。
8. 渐进解锁由 `system.{system_name}.unlocked` 或进度查询驱动。

### States and Transitions

| State | Entry Condition | Exit Condition | Behavior |
|-------|----------------|----------------|----------|
| Bootstrapping | UIManager 初始化 | 首屏 ready | 注册基础屏幕 |
| Ready | 可正常导航 | 打开 modal/transition | 处理事件刷新 |
| Transitioning | 页面切换中 | 动画/加载完成 | 禁止重复导航 |
| ModalOpen | 弹窗打开 | 弹窗关闭 | 背景页面保持只读 |
| Degraded | screen scene missing | 配置修复 | 显示错误占位 |

### Interactions with Other Systems

| System | Interface | Contract |
|--------|-----------|----------|
| 事件总线 | subscriptions | UI 主要刷新通道 |
| HUD 系统 | component host | HUD 使用 UI 组件 |
| 数值格式化系统 | format APIs | 所有 BigNumber 文本 |
| 设置系统 future | accessibility options | 字号、动画、色弱等 |
| 存档系统 | save/load events | 加载完成后全量刷新 |

## Formulas

The `ui_refresh_budget` formula is defined as:

`ui_refresh_budget_ms = frame_budget_ms * ui_budget_ratio`

**Variables:**
| Variable | Symbol | Type | Range | Description |
|----------|--------|------|-------|-------------|
| frame_budget_ms | F | float | 16.6 | 60fps 单帧预算 |
| ui_budget_ratio | R | float | 0.05-0.35 | UI 刷新可占比例 |

**Output Range:** 0.83ms to 5.81ms.
**Example:** 16.6 * 0.2 → 3.32ms。

The `visible_list_items` formula is defined as:

`visible_list_items = ceil(viewport_height / row_height) + overscan_rows * 2`

**Variables:**
| Variable | Symbol | Type | Range | Description |
|----------|--------|------|-------|-------------|
| viewport_height | H | int | 100-4000 | 列表可视高度 |
| row_height | R | int | 16-128 | 单行高度 |
| overscan_rows | O | int | 0-20 | 上下预渲染行数 |

**Output Range:** 1 to a few hundred.
**Example:** 600/32 + 4*2 → 27 rows。

## Edge Cases

- **If a registered scene path is missing**: show UI error panel and log screen id.
- **If event arrives before screen ready**: cache latest payload or request full refresh after ready.
- **If modal stack is non-empty**: gameplay commands behind modal are blocked unless modal opts out.
- **If text overflows compact controls**: component must wrap or shrink within defined min/max, not overlap.
- **If EventBus emits high-frequency resource changes**: HUD/UI uses coalesced refresh rather than rebuilding layout every event.

## Dependencies

| System | Direction | Nature |
|--------|-----------|--------|
| 事件总线 | Upstream | Refresh/event source |
| HUD 系统 | Downstream | Uses framework components |
| 数值格式化系统 | Downstream/Peer | Formatting dependency for components |
| 设置系统 | Future downstream | Accessibility preferences |

## Tuning Knobs

| Parameter | Current Value | Safe Range | Effect of Increase | Effect of Decrease |
|-----------|--------------|------------|-------------------|-------------------|
| `ui_budget_ratio` | 0.20 | 0.05-0.35 | More UI work per frame | Less UI stutter risk |
| `default_transition_ms` | 120 | 0-300 | More polish | Snappier UI |
| `overscan_rows` | 4 | 0-20 | Smoother scroll | Lower memory |
| `max_modal_depth` | 3 | 1-10 | More nested flows | Simpler UX |

## Visual/Audio Requirements

UI should be dense, restrained, and work-focused: clear hierarchy, compact panels, readable tables, restrained motion, no decorative clutter. Audio is limited to confirm/error/rare reward hooks provided by audio system.

## UI Requirements

Required MVP components: top-level screen host, tab/side navigation, modal manager, tooltip, resource row, data table, virtual list, segmented control, icon button, empty/error state, offline summary panel shell.

## Cross-References

| This Document References | Target GDD | Specific Element Referenced | Nature |
|--------------------------|-----------|-----------------------------|--------|
| Event refresh | `design/gdd/event-bus.md` | exact and coalesced events | Data dependency |
| Big number text | `design/gdd/number-formatting-system.md` | number format APIs | Data dependency |
| HUD host | `design/gdd/hud-system.md` | HUD component composition | Ownership handoff |

## Acceptance Criteria

- **GIVEN** a screen is registered and unlocked, **WHEN** `open_screen(id)` is called, **THEN** the scene is loaded and becomes active.
- **GIVEN** screen path missing, **WHEN** opened, **THEN** error state appears and app does not crash.
- **GIVEN** 1000 log rows, **WHEN** list renders, **THEN** only visible rows plus overscan are instantiated.
- **GIVEN** resource events emit 50 times in one frame, **WHEN** HUD refreshes, **THEN** layout rebuild is coalesced.
- **GIVEN** modal open, **WHEN** background command button is clicked, **THEN** command is blocked unless modal allows passthrough.

## Open Questions

| Question | Owner | Deadline | Resolution |
|----------|-------|----------|------------|
| Exact navigation pattern: left rail vs top tabs | UX | UX spec | Recommended for MVP: left rail on desktop, compact top tabs for narrow layout |
| Whether UI framework is pure Control scenes or includes custom theme plugin | Engineer/UX | Implementation plan | Start with Control scenes + Theme resource |
