# Epic: Turn System

> **Layer**: Core
> **GDD**: design/gdd/turn.md
> **Architecture Module**: TurnManager (Core Layer)
> **Status**: Ready
> **Stories**: 4 stories created — see below

## Stories

| # | Story | Type | Status | ADR |
|---|-------|------|--------|-----|
| 001 | TurnManager 初始化 + TurnConfig | Logic | Ready | ADR-0004 |
| 002 | 状态机核心 — 4 状态 + 5 转换 | Logic | Ready | ADR-0004 |
| 003 | Match End + VictoryChecker 集成 | Logic | Ready | ADR-0004 |
| 004 | 信号发射 + AIController 接口 | Logic | Ready | ADR-0004 |

## Overview

实现驱动阵营轮转的回合状态机：PLAYER ↔ ENEMY 循环，4 个状态（MATCH_NOT_STARTED / FACTION_PHASE_ACTIVE / FACTION_PHASE_ENDING / MATCH_ENDED），5 个转换。TurnManager 为 RefCounted，通过 DI 注入 VictoryChecker 和 AIController，通过 5 个信号向外广播回合事件。当活跃阵营所有存活单位均已行动时自动推进，同时暴露手动 End Turn 按钮入口。可配置回合上限作为僵局守卫。Turn System 是纯粹的协调者——不持有玩法状态，只转发信号、重置行动状态、统计存活单位。

## Governing ADRs

| ADR | Decision Summary | Engine Risk |
|-----|-----------------|-------------|
| ADR-0004: Turn System | TurnManager 为 RefCounted 4 状态状态机；PLAYER 先手、turn_number 从 1 起；auto-advance + manual End Turn；turn_cap 数据驱动；VictoryChecker 和 AIController 均为注入；5 信号广播回合事件；MATCH_ENDED 为末端吸收态 | LOW |

## GDD Requirements

| TR-ID | Requirement | ADR Coverage |
|-------|-------------|--------------|
| TR-turn-001 | TurnManager 为 RefCounted + DI，禁止 Autoload | ADR-0004 ✅ |
| TR-turn-002 | 4 状态状态机含 5 个转换 | ADR-0004 ✅ |
| TR-turn-003 | 自动推进：活跃阵营所有存活单位均已行动 | ADR-0004 ✅ |
| TR-turn-004 | VictoryChecker 注入 + determine_winner() 契约 | ADR-0004 ✅ |
| TR-turn-005 | AIController 注入 + take_turn() 契约 | ADR-0004 ✅ |
| TR-turn-006 | TurnConfig.tres 数据驱动（turn_cap [1,99]） | ADR-0004 ✅ |
| TR-turn-007 | End Turn 重入守卫 | ADR-0004 ✅ |
| TR-turn-008 | 信号契约（5 信号，消费者义务） | ADR-0004 ✅ |
| TR-turn-009 | 阵营全灭 → 立即 MATCH_ENDED | ADR-0004 ✅ |
| TR-turn-010 | end_reason 单一真相来源（VictoryChecker） | ADR-0004 ✅ |

## Definition of Done

本 Epic 完成条件：
- 所有 Story 已实现、审查并经由 `/story-done` 关闭
- `design/gdd/turn.md` 中所有验收标准已通过
- 全部 Logic 和 Integration Story 在 `tests/` 中有通过的测试文件
- 全部 Visual/Feel 和 UI Story 在 `production/qa/evidence/` 中有签核证据文档

## Next Step

Run `/create-stories turn` 将本 Epic 拆解为可实施的 Story。
