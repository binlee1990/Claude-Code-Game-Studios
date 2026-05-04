# Epic: HUD 系统

> **Layer**: Presentation
> **GDD**: design/gdd/hud-system.md
> **Architecture Module**: HUD (Control scene) (事件订阅)
> **Status**: Ready
> **Stories**: Created (2 stories)

## Overview

HUD 是 MVP 闭环能否被玩家理解的关键。资源系统、等级系统、战斗系统、区域系统和离线结算都已经产生数据；HUD 把它们整理成可扫读的状态：我有多少资源、当前在哪里、战斗是否顺利、离线获得了什么、下一步为什么被卡住。HUD 不应成为所有逻辑的 God Object，它只订阅事件、查询只读 API、调用明确 command。

Architecture ownership: `HUD (Control scene)` owns 资源面板, 战斗状态.

## Governing ADRs

| ADR | Decision Summary | Engine Risk |
|-----|------------------|-------------|
| ADR-0011: UI 屏幕管理架构 | Implement UI with Godot `Control` scene files managed by `UIManager` Autoload. UIManager owns screen registration, navigation stack, modal stack, and progressive unlock state. Screens subscribe to EventBus and query read-only APIs. Player commands are sent through explicit command methods on owning systems. | HIGH |
| ADR-0014: NumberFormatter 缩写映射策略 | Implement `NumberFormatter` as a utility service with a hard-coded MVP Chinese unit table: `万, 亿, 兆, 京, 垓, 秭, 穰, 沟, 涧, 正, 载, 极`. Values above `10^48` use scientific notation. This table stays code-owned for MVP; DataConfig-driven formatting can be revisited Post-MVP if localization or content scale requires it. | LOW |
| ADR-0002: 事件总线架构 | Use a global `EventBus` Autoload Node with string event names and `Dictionary` payloads. The bus dispatches events synchronously in the current frame. Exact subscriptions are the production path. Prefix pattern subscriptions exist only for debug tooling such as `event watch resource`. Coalesced events are allowed only for display refreshes where latest-state wins. | HIGH |

## GDD Requirements

| TR-ID | Requirement | ADR Coverage |
|-------|-------------|--------------|
| TR-hud-system-001 | HUD displays MVP resources, level/realm, zone, combat, and offline summaries using EventBus and NumberFormatter. | ADR-0011, ADR-0014, ADR-0002 |

**Untraced requirements**: 0 known in `docs/architecture/tr-registry.yaml`; the registry currently exposes one stable system-level TR for this GDD.

## Engine Risk

**HIGH** — highest governing ADR knowledge risk. Engine baseline: Godot 4.6.2.

## Cross-Epic Dependencies

- Upstream: UI 框架, 数值格式化系统, 资源系统, 区域系统
- Downstream: None listed in `systems-index.md`

## Definition of Done

This epic is complete when:
- All stories are implemented, reviewed, and closed via `/story-done`.
- All acceptance criteria from `design/gdd/hud-system.md` are verified.
- All Logic and Integration stories have passing test files under `tests/`.
- All Visual/Feel and UI stories have evidence docs with sign-off under `production/qa/evidence/`.
- Any Godot 4.6.2 behavior named by the governing ADRs is verified against `docs/engine-reference/godot/`.

## Stories

| # | Story | Type | Status | ADR |
|---|-------|------|--------|-----|
| 001 | [lingqi text updates using NumberFormattingSystem](story-001-lingqi-text-updates-using-numberformattingsystem.md) | UI | Ready | ADR-0011 |
| 002 | [level badge updates after attributes are already recalculated](story-002-level-badge-updates-after-attributes-are-already-recalcu.md) | UI | Ready | ADR-0011 |

## Next Step

Run `/story-readiness production/epics/hud-system/story-001-*.md` before implementing the first story in this epic.
