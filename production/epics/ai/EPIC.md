# Epic: AI

> **Layer**: Feature
> **GDD**: design/gdd/ai.md
> **Architecture Module**: AIController (Feature Layer)
> **Status**: Ready
> **Stories**: 5 stories created

## Stories
| # | Story | Type | Status | ADR |
|---|-------|------|--------|-----|
| 001 | AIController @abstract 基类 + NullAI | Logic | Done | ADR-0008 |
| 002 | WorldState + ActionPlan/ActionList 数据结构 | Logic | Done | ADR-0008 |
| 003 | BasicAI — 最近目标启发式计划生成器 | Logic | Done | ADR-0008 |
| 004 | Runtime ActionList Execution — TurnManager 执行非空 AI 计划 | Integration | Done | ADR-0008 |
| 005 | Runtime AI Mode Selection — Game 可选 NullAI / BasicAI | Integration | Done | ADR-0008 |

## Overview

实现可替换 AI 控制器接口：AIController 为 @abstract RefCounted 基类，定义 `take_turn(units, world_state) → ActionList` 契约。WorldState 封装 Map 拓扑快照和单位状态供 AI 决策。NullAI（MVP 默认实现）返回空 ActionList——热座模式下 ENEMY 回合由玩家手动操控。BasicAI（Tier 2）使用 BFS+伤害公式选择行动；TurnManager 现在可以执行非空 ActionList。默认 Game 场景仍使用 NullAI；BasicAI 可通过 `srpg_mini/enemy_ai_mode=basic` 或命令行 `--enemy-ai=basic` 启用。

## Governing ADRs

| ADR | Decision Summary | Engine Risk |
|-----|-----------------|-------------|
| ADR-0008: AI Controller | AIController 为 @abstract RefCounted；take_turn(units, world_state)→ActionList；WorldState 含 Map 快照+单位列表；NullAI 返回空 ActionList；接口容纳替换链而不修改 Turn System | LOW |

## GDD Requirements

| TR-ID | Requirement | ADR Coverage |
|-------|-------------|--------------|
| TR-ai-001 | @abstract AIController 基类（take_turn 为虚方法） | ADR-0008 ✅ |
| TR-ai-002 | WorldState 数据结构（Map 快照 + 单位状态） | ADR-0008 ✅ |
| TR-ai-003 | ActionPlan/ActionList 数据结构（动作序列容器） | ADR-0008 ✅ |
| TR-ai-004 | NullAI 返回空 ActionList（热座模式下 ENEMY 由玩家操控） | ADR-0008 ✅ |
| TR-ai-005 | BasicAI 接口兼容性（Tier 2 实现） | ADR-0008 ✅ |
| TR-ai-006 | 接口容纳 NullAI+BasicAI 而不修改 Turn System | ADR-0008 ✅ |
| TR-ai-007 | WorldState.clone() 深拷贝（供 AI 模拟使用） | ADR-0008 ✅ |

## Definition of Done

本 Epic 完成条件：
- 所有 Story 已实现、审查并经由 `/story-done` 关闭
- `design/gdd/ai.md` 中所有验收标准已通过
- 全部 Logic Story 在 `tests/unit/ai/` 中有通过的测试文件

## Next Step

Optional next extension: run manual visual QA for automatic ENEMY movement timing in `BasicAI` mode.
