# Epic: 事件总线 (EventBus)

> **Layer**: Foundation
> **GDD**: design/gdd/event-bus.md
> **Architecture Module**: EventBus (Autoload, 全局单例)
> **Status**: Done
> **Sprint Target**: Pre-Production Sprint 1（Foundation Core，与 BigNumber 并行）
> **Stories**: Created (10 stories)
> **PR-EPIC Verdict (2026-05-04)**: CONCERNS（Godot 4.6 GDScript 生命周期 HIGH risk，需 spike 先行）

## Overview

EventBus 提供跨系统解耦通信：精确事件 publish/subscribe、debug 前缀监听、生命周期清理、coalesced 显示刷新。**所有 Autoload 启动链的第一个**（ADR-0008）。承载 ResourceSystem / LevelSystem / SaveManager / HUD / 半自动战斗等系统的事件流。Godot 4.6 GDScript 生命周期变化（4.5 引入的弱引用语义 + 4.6 的清理时机）使本 epic 的实现路径成为 Foundation 层最高风险项。

## Governing ADRs

| ADR | Decision Summary | Engine Risk |
|-----|-----------------|-------------|
| ADR-0002: 事件总线架构 | Autoload 单例；Callable 订阅表；emit / emit_coalesced / subscribe / subscribe_once / unsubscribe / pattern 订阅；deferred cleanup 防止生命周期悬挂 | **HIGH** (GDScript 4.5/4.6 lifecycle) |
| ADR-0008: Autoload 初始化顺序 | EventBus 必须**第一**初始化；其他 Autoload 通过 `has_node()` / `is_instance_valid()` 惰性引用 | LOW |

## GDD Requirements

| TR-ID | Requirement | ADR Coverage |
|-------|-------------|--------------|
| TR-event-bus-001 | EventBus provides decoupled exact event publish/subscribe, debug prefix watch, lifecycle cleanup, and coalesced display refresh. | ADR-0002 ✅ + ADR-0008 ✅ |

**Untraced requirements**: 0

## Engine Risk

**HIGH** — Godot 4.6 GDScript 生命周期变更（4.5 弱引用、4.6 清理时机）影响 Callable 订阅的有效性判定。`docs/architecture/architecture.md` HIGH RISK Domains 显式列出 EventBus 受此影响。

## Cross-Epic Dependencies

- **Downstream consumers**: TimeManager, RNGManager, 后续所有 Autoload 与 UI 框架
- **Upstream blockers**: 无（EventBus 是依赖链顶端）

## Definition of Done

### Standard DoD
- 所有 stories 实现完成、通过 `/code-review`、走完 `/story-done` 关闭
- `design/gdd/event-bus.md` 全部 acceptance criteria 验证通过
- Logic / Integration stories 在 `tests/unit/event_bus/` 与 `tests/integration/event_bus/` 有通过的测试文件

### PR-EPIC 追加要求（Producer 2026-05-04 sign-off 附加）

- **本 epic Story #1 必须是"Godot 4.6 信号生命周期 spike"**，独立 story、独立验证证据，**先于其他 EventBus stories 实现**。spike 输出：(a) 4.6 GDScript Callable 弱引用 / 强引用语义实测报告；(b) deferred cleanup vs. weak ref 方案对比；(c) ADR-0002 实施路径最终决策（如 spike 推翻 ADR，必须更新 ADR-0002 至 Superseded 并起草新 ADR）
- **Autoload 启动顺序自动化测试**：必须在 `tests/integration/event_bus/autoload_order_test.gd` 中守护 ADR-0008 启动顺序（EventBus → RNGManager → TimeManager → ...），未来新增 Autoload 时该测试将立刻报错
- **下游系统集成自测**：本 epic 末尾的 acceptance test 必须包含至少一次跨系统事件流（从 ResourceSystem 模拟事件 → EventBus → mock UI 订阅者）的端到端验证，证明 ADR-0002 在真实链路下不悬挂、不漏发

### 折叠自 gate-check watchlist 的项

| Watchlist 项 | DoD 要求 |
|---|---|
| ADR-0002 验证证据 | spike 报告 + autoload 顺序测试 + 跨系统事件流测试 |
| ADR-0008 验证证据 | autoload_order_test.gd 守护 |

## Stories

| # | Story | Type | Status | ADR |
|---|-------|------|--------|-----|
| 001 | [Godot 4.6 Callable lifecycle spike](story-001-godot-4-6-callable-lifecycle-spike.md) | Integration | Done | ADR-0002 |
| 002 | [获得同一个全局单例实例](story-002-002-integration.md) | Integration | Done | ADR-0002 |
| 003 | [后续 emit 不再触发该 callable](story-003-emit-callable.md) | Integration | Done | ADR-0002 |
| 004 | [第 1 和第 3 个订阅者正常收到事件，第 2 个订阅记录被移除，控制台打印无效 callable 警告](story-004-1-3-2-callable.md) | Integration | Done | ADR-0002 |
| 005 | [递归 emit 被忽略，控制台打印警告](story-005-emit.md) | Integration | Done | ADR-0002 |
| 006 | [无错误、无副作用](story-006-006-integration.md) | Integration | Done | ADR-0002 |
| 007 | [该订阅被移除，后续 emit 不再触发该 callable](story-007-emit-callable.md) | Integration | Done | ADR-0002 |
| 008 | [callable 被触发一次，第一个参数等于 `"resource.lingqi.changed"`，第二个参数等于 emit 的 payl](story-008-callable-resource-lingqi-changed-emit-payl.md) | Integration | Done | ADR-0002 |
| 009 | [cb1 与 cb2 均被触发；cb1 收到一个参数（payload），cb2 收到两个参数（event_name + payload）](story-009-cb1-cb2-cb1-payload-cb2-event-name-payload.md) | Integration | Done | ADR-0002 |
| 010 | [订阅者只收到 1 次 `ui.hud.refresh`，payload 等于第 10 次调用的 payload](story-010-1-ui-hud-refresh-payload-10-payload.md) | UI | Done | ADR-0002 |

## Next Step

Run `/story-readiness production/epics/event-bus/story-001-*.md` before implementing the first story in this epic.
