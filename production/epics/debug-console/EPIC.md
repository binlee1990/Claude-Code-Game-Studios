# Epic: 调试控制台

> **Layer**: Core Gameplay
> **GDD**: design/gdd/debug-console.md
> **Architecture Module**: `DebugConsole` (Autoload) (CanvasLayer overlay)
> **Status**: Ready
> **Stories**: Created (14 stories)

## Overview

调试控制台是 MVP 开发阶段的统一诊断入口——开发者在游戏运行时按 `~` 键呼出一个覆盖层，输入文本命令（或从命令面板选择），即时查看任意系统的内部状态：资源当前值、事件流日志、配置表内容、已注册的 modifier 列表、实体属性快照、产出速率分解。它不替代 Godot 内置的 `@tool` 脚本编辑器或 `print()` 调试——而是把"运行时看一眼就知道系统在做什么"的体验集中到一个入口，避免开发者在多个 Godot dock 面板之间反复切换。

Architecture ownership: `DebugConsole (Autoload)` owns 命令解析, 日志缓冲.

## Governing ADRs

| ADR | Decision Summary | Engine Risk |
|-----|------------------|-------------|
| ADR-0012: DebugConsole 发布构建排除 | Register `DebugConsole` as an Autoload, but make `_ready()` begin with: | HIGH |
| ADR-0002: 事件总线架构 | Use a global `EventBus` Autoload Node with string event names and `Dictionary` payloads. The bus dispatches events synchronously in the current frame. Exact subscriptions are the production path. Prefix pattern subscriptions exist only for debug tooling such as `event watch resource`. Coalesced events are allowed only for display refreshes where latest-state wins. | HIGH |
| ADR-0008: Autoload 初始化顺序 | Use explicit Autoload order in `project.godot`: | MEDIUM |
| ADR-0011: UI 屏幕管理架构 | Implement UI with Godot `Control` scene files managed by `UIManager` Autoload. UIManager owns screen registration, navigation stack, modal stack, and progressive unlock state. Screens subscribe to EventBus and query read-only APIs. Player commands are sent through explicit command methods on owning systems. | HIGH |

## GDD Requirements

| TR-ID | Requirement | ADR Coverage |
|-------|-------------|--------------|
| TR-debug-console-001 | DebugConsole provides debug-only runtime commands, event watching, pause-safe overlay behavior, and release-build self-removal. | ADR-0012, ADR-0002, ADR-0008, ADR-0011 |

**Untraced requirements**: 0 known in `docs/architecture/tr-registry.yaml`; the registry currently exposes one stable system-level TR for this GDD.

## Engine Risk

**HIGH** — highest governing ADR knowledge risk. Engine baseline: Godot 4.6.2.

## Cross-Epic Dependencies

- Upstream: 事件总线, 数据配置系统, 资源系统, 属性系统, 修正器/倍率引擎, 产出乘数系统, 时间管理器, 存档系统, 数值格式化系统, 大数值系统
- Downstream: None listed in `systems-index.md`

## Definition of Done

This epic is complete when:
- All stories are implemented, reviewed, and closed via `/story-done`.
- All acceptance criteria from `design/gdd/debug-console.md` are verified.
- All Logic and Integration stories have passing test files under `tests/`.
- All Visual/Feel and UI stories have evidence docs with sign-off under `production/qa/evidence/`.
- Any Godot 4.6.2 behavior named by the governing ADRs is verified against `docs/engine-reference/godot/`.

## Stories

| # | Story | Type | Status | ADR |
|---|-------|------|--------|-----|
| 001 | [the node calls `queue_free()` and returns immediately, leaving zero re](story-001-the-node-calls-queue-free-and-returns-immediately-leavin.md) | UI | Ready | ADR-0011 |
| 002 | [`CanvasLayer.visible` becomes `true`, `get_tree().paused` becomes `tru](story-002-canvaslayer-visible-becomes-true-get-tree-paused-becomes.md) | UI | Ready | ADR-0011 |
| 003 | [`LineEdit.release_focus()` is called instead of restoring the freed no](story-003-lineedit-release-focus-is-called-instead-of-restoring-th.md) | UI | Ready | ADR-0011 |
| 004 | [`EventBus.subscribe_pattern("resource", <callable>)` is called exactly](story-004-eventbus-subscribe-pattern-resource-callable-is-called-e.md) | Integration | Ready | ADR-0002 |
| 005 | [the second invocation outputs `\[WARN\] Already watching 'resource'. No-](story-005-the-second-invocation-outputs-warn-already-watching-reso.md) | UI | Ready | ADR-0011 |
| 006 | [each record in the `enemies` table is output as a single-line compact](story-006-each-record-in-the-enemies-table-is-output-as-a-single-l.md) | Config/Data | Ready | ADR-0012 |
| 007 | [the output lists all entity IDs registered in `AttributeSystem`](story-007-the-output-lists-all-entity-ids-registered-in-attributes.md) | Logic | Ready | ADR-0012 |
| 008 | [the output displays `real_time`, `game_time`, `effective_speed`, and `](story-008-the-output-displays-real-time-game-time-effective-speed.md) | UI | Ready | ADR-0011 |
| 009 | [`SaveManager.save_game()` is called and the output confirms the save w](story-009-savemanager-save-game-is-called-and-the-output-confirms.md) | Config/Data | Ready | ADR-0012 |
| 010 | [the output displays exactly the `event` command's full help text: `eve](story-010-the-output-displays-exactly-the-event-command-s-full-hel.md) | UI | Ready | ADR-0011 |
| 011 | [the output displays `\[ERROR\] Command handler unavailable: {command}` i](story-011-the-output-displays-error-command-handler-unavailable-co.md) | UI | Ready | ADR-0011 |
| 012 | [the `LineEdit` content does not change and no error or exception is pr](story-012-the-lineedit-content-does-not-change-and-no-error-or-exc.md) | UI | Ready | ADR-0011 |
| 013 | [Test Strategy Notes 1](story-013-test-strategy-notes-1.md) | UI | Ready | ADR-0011 |
| 014 | [Test Strategy Notes 2](story-014-test-strategy-notes-2.md) | Integration | Ready | ADR-0002 |

## Next Step

Run `/story-readiness production/epics/debug-console/story-001-*.md` before implementing the first story in this epic.
