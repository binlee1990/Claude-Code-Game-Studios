# Epic: Victory

> **Layer**: Feature
> **GDD**: design/gdd/victory.md
> **Architecture Module**: VictoryChecker (Feature Layer)
> **Status**: Ready
> **Stories**: 2 stories created

## Stories
| # | Story | Type | Status | ADR |
|---|-------|------|--------|-----|
| 001 | VictoryChecker — 全灭判定 | Logic | Ready | ADR-0009 |
| 002 | VictoryChecker — 回合上限 + 存活数判定 | Logic | Ready | ADR-0009 |

## Overview

实现胜利条件判定系统：VictoryChecker 为 RefCounted 纯函数，接收全部单位列表+回合数+回合上限，返回 `{winner: Faction.Type, reason: String}`。判定逻辑：阵营全灭→胜者为存活方；双方全灭→PLAYER 胜（fallback）；回合上限→按存活单位数判定（多者胜，平则 DRAW）。VictoryChecker 是 end_reason 的单一真相来源——Turn System 委托判定，不自行推导。

## Governing ADRs

| ADR | Decision Summary | Engine Risk |
|-----|-----------------|-------------|
| ADR-0009: Victory System | VictoryChecker 为 RefCounted 纯函数；determine_winner(units, turn_number, turn_cap)→{winner, reason}；双方全灭 fallback→PLAYER；回合上限→存活数比较；对 Turn System 的唯一依赖是接口契约 | LOW |

## GDD Requirements

| TR-ID | Requirement | ADR Coverage |
|-------|-------------|--------------|
| TR-vic-001 | VictoryChecker 为 RefCounted 纯函数（零状态，可测试无场景树） | ADR-0009 ✅ |
| TR-vic-002 | determine_winner(units, turn_number, turn_cap) 3 参数接口 | ADR-0009 ✅ |
| TR-vic-003 | 阵营全灭→胜者为存活方（PLAYER/ENEMY） | ADR-0009 ✅ |
| TR-vic-004 | 双方全灭→PLAYER 胜（fallback，MVP 最公平默认值） | ADR-0009 ✅ |
| TR-vic-005 | 回合上限→按存活单位数判定（多者胜，相等→DRAW） | ADR-0009 ✅ |

## Definition of Done

本 Epic 完成条件：
- 所有 Story 已实现、审查并经由 `/story-done` 关闭
- `design/gdd/victory.md` 中所有验收标准已通过
- 全部 Logic Story 在 `tests/unit/victory/` 中有通过的测试文件

## Next Step

Run `/create-stories victory` 将本 Epic 拆解为可实施的 Story。
