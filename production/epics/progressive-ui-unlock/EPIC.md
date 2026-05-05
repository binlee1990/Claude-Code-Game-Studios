# Epic: Progressive UI Unlock（渐进 UI 解锁）

> **Layer**: Presentation/UI
> **GDD**: design/experience/screen-flow.md · design/gdd/ui-framework.md
> **Architecture Module**: LeftNav / UIManager (现有)
> **Status**: Done
> **Stories**: 3 stories

## Overview

实现 screen-flow.md §3-4 定义的 LEFT NAV 可见性状态机（VISIBLE+ACTIVE / LOCKED / HIDDEN 三态）和屏幕渐进解锁序列。修炼屏→战斗屏→资源屏→离线结算屏→存档屏的解锁由境界/灵气阈值/首次离线回归等事件触发，每个解锁伴随叙事文本。

## Governing ADRs

| ADR | Decision Summary | Engine Risk |
|-----|------------------|-------------|
| ADR-0011: UI 屏幕管理架构 | ScreenStack 平级切换，Modal Stack Z-Order ≤ 3 层 | LOW |

## Cross-Epic Dependencies

- Upstream: FTUE Onboarding、UI 框架
- Downstream: Session Rhythm

## Definition of Done

- [x] LEFT NAV 三态状态机正确运行
- [x] 5 Tab 解锁序列与 screen-flow.md §3 对齐
- [x] 每个解锁触发正确的叙事文本
- [x] RIGHT PANEL 根据当前主屏正确切换内容

## Stories

| # | Story | Type | Status |
|---|-------|------|--------|
| 001 | LEFT NAV 可见性状态机 | UI | Done |
| 002 | 屏幕渐进解锁序列 | UI | Done |
| 003 | RIGHT PANEL 上下文切换 | UI | Done |
