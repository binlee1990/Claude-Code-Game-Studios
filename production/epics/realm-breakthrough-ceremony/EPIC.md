# Epic: Realm Breakthrough Ceremony（境界突破仪式）

> **Layer**: Presentation/Visual
> **GDD**: design/experience/player-journey-map.md §1.4 · design/narrative/world-skeleton.md §2
> **Architecture Module**: LevelSystem + HUD (现有)
> **Status**: Done
> **Stories**: 2 stories

## Overview

实现玩家境界突破时的仪式化视觉反馈：凡人→炼气（Lv.10）金色印章动画 + 属性跳变 + 新姿态解锁提示；炼气→筑基（Lv.30）MVP 终局突破 + Phase 2+ 路线图预告。对标 player-journey-map.md §1.4 描述的"峰值体验 1"。

## Governing ADRs

| ADR | Decision Summary | Engine Risk |
|-----|------------------|-------------|
| ADR-0002: 事件总线架构 | realm.advanced 信号触发仪式动画 | LOW |

## Cross-Epic Dependencies

- Upstream: 等级系统、HUD 系统、FTUE Onboarding
- Downstream: 无

## Definition of Done

- [x] 凡人→炼气 金色印章 3s 收缩动画
- [x] 突破后属性面板自动刷新显示新值
- [x] 新姿态解锁提示（Condense）
- [x] 炼气→筑基 MVP 终局突破 + Phase 2+ 预告

## Stories

| # | Story | Type | Status |
|---|-------|------|--------|
| 001 | 凡人→炼气突破仪式 | Visual/UI | Done |
| 002 | 炼气→筑基突破仪式 | Visual/UI | Done |
