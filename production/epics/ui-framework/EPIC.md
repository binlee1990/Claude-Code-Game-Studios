# Epic: UI 框架

> **Layer**: Presentation
> **GDD**: design/gdd/ui-framework.md
> **Architecture Module**: `UIManager` (Autoload) + Control scenes (屏幕管理)
> **Status**: Done
> **Stories**: Created (2 stories)

## Overview

本项目是 2D UI 驱动的半放置 RPG，核心交互是配置、管理、筛选和规划。UI 框架必须先建立统一的页面/弹窗/列表/提示基础，否则 HUD、区域选择、离线结算和调试界面会各自实现刷新逻辑，导致信息密度不可控。MVP 框架重点是稳定、清晰、可扩展，而不是华丽动画。

Architecture ownership: `UIManager (Autoload) + Control scenes` owns 导航栈, 屏幕切换.

## Governing ADRs

| ADR | Decision Summary | Engine Risk |
|-----|------------------|-------------|
| ADR-0011: UI 屏幕管理架构 | Implement UI with Godot `Control` scene files managed by `UIManager` Autoload. UIManager owns screen registration, navigation stack, modal stack, and progressive unlock state. Screens subscribe to EventBus and query read-only APIs. Player commands are sent through explicit command methods on owning systems. | HIGH |
| ADR-0002: 事件总线架构 | Use a global `EventBus` Autoload Node with string event names and `Dictionary` payloads. The bus dispatches events synchronously in the current frame. Exact subscriptions are the production path. Prefix pattern subscriptions exist only for debug tooling such as `event watch resource`. Coalesced events are allowed only for display refreshes where latest-state wins. | HIGH |
| ADR-0014: NumberFormatter 缩写映射策略 | Implement `NumberFormatter` as a utility service with a hard-coded MVP Chinese unit table: `万, 亿, 兆, 京, 垓, 秭, 穰, 沟, 涧, 正, 载, 极`. Values above `10^48` use scientific notation. This table stays code-owned for MVP; DataConfig-driven formatting can be revisited Post-MVP if localization or content scale requires it. | LOW |

## GDD Requirements

| TR-ID | Requirement | ADR Coverage |
|-------|-------------|--------------|
| TR-ui-framework-001 | UIFramework uses UIManager and Control scenes for screen registration, navigation, modals, events, read-only queries, and command routing. | ADR-0011, ADR-0002, ADR-0014 |

**Untraced requirements**: 0 known in `docs/architecture/tr-registry.yaml`; the registry currently exposes one stable system-level TR for this GDD.

## Engine Risk

**HIGH** — highest governing ADR knowledge risk. Engine baseline: Godot 4.6.2.

## Cross-Epic Dependencies

- Upstream: 事件总线
- Downstream: HUD 系统

## Definition of Done

This epic is complete when:
- All stories are implemented, reviewed, and closed via `/story-done`.
- All acceptance criteria from `design/gdd/ui-framework.md` are verified.
- All Logic and Integration stories have passing test files under `tests/`.
- All Visual/Feel and UI stories have evidence docs with sign-off under `production/qa/evidence/`.
- Any Godot 4.6.2 behavior named by the governing ADRs is verified against `docs/engine-reference/godot/`.

## Stories

| # | Story | Type | Status | ADR |
|---|-------|------|--------|-----|
| 001 | [the scene is loaded and becomes active](story-001-the-scene-is-loaded-and-becomes-active.md) | UI | Done | ADR-0011 |
| 002 | [layout rebuild is coalesced](story-002-layout-rebuild-is-coalesced.md) | UI | Done | ADR-0011 |

## Next Step

Run `/story-readiness production/epics/ui-framework/story-001-*.md` before implementing the first story in this epic.
