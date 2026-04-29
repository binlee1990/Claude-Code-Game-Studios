# Epic: Unit

> **Layer**: Core
> **GDD**: design/gdd/unit.md
> **Architecture Module**: Unit (Core Layer)
> **Status**: Ready
> **Stories**: 4 stories created — see below

## Stories

| # | Story | Type | Status | ADR |
|---|-------|------|--------|-----|
| 001 | UnitStats — 数据驱动属性 + .tres 校验 | Logic | Ready | ADR-0003 |
| 002 | Unit Scene — 场景结构 + 视觉表现 | Visual/Feel | Ready | ADR-0003 |
| 003 | 公共接口 + action_state 状态机 + Faction | Logic | Ready | ADR-0003 |
| 004 | HP 系统 — 伤害/治疗/死亡链 | Logic | Ready | ADR-0003 |

## Overview

实现 SRPG 的游戏棋子系统：每个 Unit 是一个携带五项属性（HP/ATK/DEF/MOV/RNG）的具名实体，归属于 Player 或 Enemy 阵营，以纯色几何形状 + HP Label 渲染在网格上。Unit 提供稳定的公共接口供全部 5 个下游系统消费（Turn、Movement、Attack、Victory、AI），所有数值由 `UnitStats.tres` Resource 外部驱动。包含 action_state 状态机、伤害/治疗写入授权、death 信号契约，以及 `.tres` 数据文件加载时 fail-fast 校验。

## Governing ADRs

| ADR | Decision Summary | Engine Risk |
|-----|-----------------|-------------|
| ADR-0003: Unit Interface | Unit 为 Node2D 场景，数据由 UnitStats.tres 驱动；通过公共方法暴露只读状态；take_damage/heal 为写入守门；unit_died 信号仅触发一次；action_state 为 5 状态机；.tres 校验 fail-fast | LOW |

## GDD Requirements

| TR-ID | Requirement | ADR Coverage |
|-------|-------------|--------------|
| TR-unit-001 | UnitStats 作为 .tres Resource（数据驱动，5 属性） | ADR-0003 ✅ |
| TR-unit-002 | Faction enum 位于独立文件（src/core/faction.gd） | ADR-0003 ✅ |
| TR-unit-003 | 面向 5 个下游消费者的稳定公共接口 | ADR-0003 ✅ |
| TR-unit-004 | 写入授权（take_damage、heal、reset_action_state） | ADR-0003 ✅ |
| TR-unit-005 | unit_died 信号契约（仅触发一次，在 queue_free 之前） | ADR-0003 ✅ |
| TR-unit-006 | Unit 场景结构（Node2D + ColorRect + Label） | ADR-0003 ✅ |
| TR-unit-007 | action_state 状态机（IDLE/SELECTED/MOVED/ACTED/DEAD） | ADR-0003 ✅ |
| TR-unit-008 | .tres 校验 fail-fast（数据异常时 validate()） | ADR-0003 ✅ |
| TR-unit-009 | 单调递增 unit_id 生成 | ⚠️ No ADR — 实现细节，Story 内直接解决 |
| TR-unit-010 | 视觉状态映射（已行动 = gray + 50% alpha） | ⚠️ Visual/Feel — Story 内直接解决 |

## Definition of Done

本 Epic 完成条件：
- 所有 Story 已实现、审查并经由 `/story-done` 关闭
- `design/gdd/unit.md` 中所有验收标准已通过
- 全部 Logic 和 Integration Story 在 `tests/` 中有通过的测试文件
- 全部 Visual/Feel 和 UI Story 在 `production/qa/evidence/` 中有签核证据文档

## Next Step

Run `/create-stories unit` 将本 Epic 拆解为可实施的 Story。
