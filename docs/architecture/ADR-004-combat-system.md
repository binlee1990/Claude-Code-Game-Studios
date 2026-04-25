# ADR-004: Combat System Architecture

## Status

Accepted

## Date

2026-04-23

## Decision Makers

技术总监

## Summary

战斗系统采用回合制速度序列框架，CombatSystem 作为核心协调器管理战斗流程、行动顺序和伤害结算。战术机制（克制三角、元素交互、高低差）作为独立子系统通过接口注入，实现战斗规则与战术规则的分离。

## Engine Compatibility

| Field | Value |
|-------|-------|
| **Engine** | Godot 4.6.2 |
| **Domain** | Gameplay / Combat |
| **Knowledge Risk** | MEDIUM — 战斗流程涉及状态机和信号链，需验证帧内多信号顺序 |
| **References Consulted** | `docs/engine-reference/godot/` |
| **Post-Cutoff APIs Used** | None |
| **Verification Required** | 战斗流程端到端测试（3+ 单位，含克制/元素/高低差） |

## ADR Dependencies

| Field | Value |
|-------|-------|
| **Depends On** | ADR-001 (事件架构), ADR-002 (场景管理) |
| **Enables** | ADR-005 (AI Behavior), battle-settlement epic, ui-system epic |
| **Blocks** | 战斗结算、AI系统、回合制模式实现 |
| **Ordering Note** | 战斗系统是 Gameplay 层核心，需在 ADR-001/002 之后、AI 之前实现 |

## Context

### Problem Statement

SRPG 核心战斗需要同时管理：速度序列制回合顺序、多层战术规则（克制/元素/高低差）、伤害计算、MP/冷却资源管理、自动/加速模式。这些规则复杂但必须正确组合，且战斗流程必须可中断（暂停/撤退）。

### Current State

`src/core/combat/` 中已有部分实现：`combat_system.gd`、`damage_calculation.gd`、`auto_battle_controller.gd`。本 ADR 将这些实现规范化并确认架构方向。

### Constraints

- 战斗状态机必须支持暂停/恢复（暂停菜单集成）
- 伤害计算必须在一帧内完成（无异步）
- 战斗中不允许存档（ADR-003 上下文规则）

### Requirements

- 速度序列制：按 AGI 排序行动
- 每单位每回合 1 次行动（移动 + 攻击/技能/待机）
- 克制三角、元素交互、高低差三层战术叠加
- 自动战斗 + 加速模式 (1x/2x/3x)
- 战斗结束条件：全灭 / 撤退

## Decision

### 战斗系统架构

```
CombatSystem (Node, 场景内)
├── TurnManager — 速度序列排序 + 行动调度
├── DamageCalculator — 伤害公式 + 克制/元素/高低差修正
├── TacticalResolver — 克制三角 + 元素交互 + 高低差查表
├── ActionExecutor — 技能/移动/待机执行器
├── AutoBattleController — AI 接管己方单位
└── CombatStateMachine — 战斗流程状态机
```

### 战斗状态机

```
IDLE → INITIALIZING → PLAYER_TURN → EXECUTING → CHECK_END → ENEMY_TURN → EXECUTING → CHECK_END → ...
                                                                          ↓
                                                                     BATTLE_ENDED → SETTLEMENT
```

| 状态 | 职责 | 输入 |
|------|------|------|
| IDLE | 等待战斗触发 | `battle_started` 信号 |
| INITIALIZING | 生成行动顺序，初始化战场 | — |
| PLAYER_TURN | 等待玩家行动选择 | 移动/攻击/技能/待机 |
| EXECUTING | 执行行动动画+结算 | — |
| CHECK_END | 检查胜负条件 | — |
| ENEMY_TURN | AI 决策+执行 | AI 返回行动指令 |
| BATTLE_ENDED | 触发结算流程 | — |

### 伤害计算管线

```
base_damage = weapon_power × (STR / 100)
              ↓ 克制修正
advantage_mod = has_advantage(weapon, target_weapon) ? 1.5 : 1.0
              ↓ 元素修正
element_mod = get_element_interaction(element, terrain_element)
              ↓ 高低差修正
height_mod = height_diff > 0 ? 1.0 + 0.1 × height_diff : 1.0
              ↓ 最终伤害
final_damage = base_damage × advantage_mod × element_mod × height_mod - target_DEF
```

### 与现有代码的对齐

| 现有文件 | 本 ADR 角色 | 变更 |
|----------|------------|------|
| `src/core/combat/combat_system.gd` | CombatSystem 核心 | 重构为状态机模式 |
| `src/core/combat/damage_calculation.gd` | DamageCalculator | 对齐公式到 GDD |
| `src/core/combat/auto_battle_controller.gd` | AutoBattleController | 无变更，已验证 |
| `src/core/autoload/game_events.gd` | GameEvents | 战斗信号已定义 |

## Alternatives Considered

### Alternative 1: 实时战斗系统

- **Rejection Reason**: GDD 明确要求回合制速度序列

### Alternative 2: ECS 模式

- **Description**: 使用 Godot ECS 框架分离数据与逻辑
- **Rejection Reason**: Godot 4.6 无官方 ECS 支持，自建成本高且 GDD 复杂度不需要

## Consequences

### Positive

- 战术规则作为独立子系统，可单独测试和调参
- 状态机清晰，支持暂停/恢复
- 与现有代码对齐，重写成本低

### Negative

- CombatSystem 作为协调器仍有较高复杂度
- 伤害计算管线较长，调试需逐层排查

## Risks

| Risk | Probability | Impact | Mitigation |
|------|------------|--------|------------|
| 伤害公式平衡困难 | 高 | 中 | 调参面板，所有系数外部配置 |
| 状态机转换遗漏 | 中 | 高 | 完整状态机测试覆盖 |
| 克制/元素叠加计算溢出 | 低 | 高 | 边界值测试 |

## Performance Implications

| Metric | Budget | Notes |
|--------|--------|-------|
| 行动结算 | <1ms | 一帧内完成 |
| 伤害计算 | <0.1ms | 纯数学 |
| AI 决策（单个） | <5ms | ADR-005 定义 |

## Validation Criteria

- [ ] 速度序列正确按 AGI 排序
- [ ] 克制三角伤害 ×1.5 验证
- [ ] 高低差修正正确计算
- [ ] 自动战斗正确接管己方
- [ ] 战斗暂停/恢复正常
- [ ] 全灭条件正确判定

## GDD Requirements Addressed

| GDD Document | Requirement | How Addressed |
|-------------|-------------|---------------|
| turn-based-mode.md | 速度序列制行动顺序 | TurnManager.sort_by(AGI) |
| turn-based-mode.md | 行动类型（移动/攻击/技能/待机） | ActionExecutor 多态 |
| turn-based-mode.md | 自动/加速模式 | AutoBattleController |
| tactical-mechanism.md | 克制三角 | TacticalResolver |
| tactical-mechanism.md | 元素交互 | TacticalResolver |
| tactical-mechanism.md | 高低差 | TacticalResolver |
| battle-settlement.md | 结算触发 | CombatStateMachine.BATTLE_ENDED |

## Related

- ADR-001: 事件架构 (GameEvents 战斗信号)
- ADR-002: 场景管理 (BattleArena 场景)
- ADR-005: AI Behavior System

## Acceptance History

| Field | Value |
|-------|-------|
| **Accepted on** | 2026-04-26 |
| **Accepted via** | Sprint-002 governance closure |
| **Reason** | 12 epic Complete 引用本 ADR，需消除合规绕过风险 |
