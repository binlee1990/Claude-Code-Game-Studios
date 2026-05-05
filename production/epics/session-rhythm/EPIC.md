# Epic: Session Rhythm（会话节奏）

> **Layer**: Feature — Experience
> **GDD**: design/experience/session-loop.md · design/gdd/offline-reward-settlement-system.md
> **Architecture Module**: OfflineSettlementScreen + HUD (现有)
> **Status**: Done
> **Stories**: 2 stories

## Overview

实现 session-loop.md 定义的离线结算三层递进（Toast→Drawer→全屏摘要）和会话退出"期待锚点"（退出前展示"下次回来你会得到..."预估）。完善 MVP 玩家"回来→看到→做→退出→期待回来"的完整体验闭环。

## Governing ADRs

| ADR | Decision Summary | Engine Risk |
|-----|------------------|-------------|
| ADR-0015: 离线模拟 tick 粒度 | 离线结算使用时间戳差值批量结算 | LOW |

## Cross-Epic Dependencies

- Upstream: 离线收益结算系统、FTUE Onboarding、Progressive UI Unlock
- Downstream: 无

## Definition of Done

- [x] 离线回归 Toast→Drawer→全屏 三层递进正确
- [x] 收益数字展示动画与 visual-design-sprint-11.md 对齐
- [x] 退出前"期待锚点"正确计算并展示

## Stories

| # | Story | Type | Status |
|---|-------|------|--------|
| 001 | 离线结算三层递进 | UI | Done |
| 002 | 会话退出"期待锚点" | UI | Done |
