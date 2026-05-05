# Epic: FTUE Onboarding（新手引导）

> **Layer**: Feature — Experience
> **GDD**: design/experience/onboarding-flow.md · design/experience/player-journey-map.md
> **Architecture Module**: FTUEStateMachine (RefCounted) (新 Autoload)
> **Status**: Done
> **Stories**: 6 stories

## Overview

实现 MVP 6 阶段新手引导：Stage 0（标题→修炼）→ Stage 1（灵气积累→战斗解锁）→ Stage 2（首次战斗循环）→ Stage 3（区域理解）→ Stage 4（首次突破）→ Stage 5（首次离线回归）。全程无教程弹窗、无箭头指示、无强制点击路径。玩家通过"做"而非"读"来学习。

## Governing ADRs

| ADR | Decision Summary | Engine Risk |
|-----|------------------|-------------|
| ADR-0002: 事件总线架构 | FTUE 状态转换通过 EventBus 信号触发，各系统订阅解锁事件 | LOW |
| ADR-0008: Autoload 初始化顺序 | FTUEStateMachine 在所有服务 Autoload 之后初始化 | LOW |

## GDD Requirements

无独立 GDD — 需求来自 3 份设计文档：
- `design/experience/onboarding-flow.md` §2（6 阶段引导流程）
- `design/experience/screen-flow.md` §3（渐进 UI 解锁序列）
- `design/experience/player-journey-map.md` §1.1–§1.5（体验路径时间线）

## Cross-Epic Dependencies

- Upstream: 修炼系统、战斗系统、资源系统、等级系统、事件总线
- Downstream: Progressive UI Unlock、Session Rhythm

## Definition of Done

- [x] FTUEStateMachine 实现 6 阶段状态转换
- [x] 每阶段触发条件与 onboarding-flow.md 完全对齐
- [x] 每阶段解锁事件通过 EventBus 正确广播
- [x] FTUE 阶段在存档中持久化
- [x] HUD 渐进解锁（4→12 字段）正确运行
- [x] 首次战斗护航（必胜保证）正确运行

## Stories

| # | Story | Type | Status |
|---|-------|------|--------|
| 001 | FTUE 状态机核心 | Logic | Done |
| 002 | Stage 0–1: 标题→修炼→战斗解锁 | UI | Done |
| 003 | Stage 2–3: 战斗循环→区域理解 | UI | Done |
| 004 | Stage 4: 首次突破引导 | UI | Done |
| 005 | Stage 5: 首次离线回归 | UI | Done |
| 006 | HUD 渐进解锁（4→12 字段） | UI | Done |
