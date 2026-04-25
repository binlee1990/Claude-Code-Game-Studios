# ADR-005: AI Behavior System

## Status

Accepted

## Date

2026-04-23

## Decision Makers

技术总监

## Summary

AI 系统采用分层行为树架构，分为战术层（目标选择）、策略层（技能选择）、执行层（位置决策）。每个敌人类型拥有独立 AI 配置文件（JSON/Resource），定义行为倾向、决策权重和攻击模式。Boss AI 在基础架构上增加阶段切换机制。

## Engine Compatibility

| Field | Value |
|-------|-------|
| **Engine** | Godot 4.6.2 |
| **Domain** | Gameplay / AI |
| **Knowledge Risk** | HIGH — AI 行为树复杂度较高，需在 Vertical Slice 中验证 |
| **References Consulted** | `docs/engine-reference/godot/` |
| **Post-Cutoff APIs Used** | None |
| **Verification Required** | 4 种 AI 类型 × 3 种战场场景行为测试 |

## ADR Dependencies

| Field | Value |
|-------|-------|
| **Depends On** | ADR-001 (事件架构), ADR-004 (Combat System) |
| **Enables** | boss-system.md 实现, turn-based-mode 敌方回合 |
| **Blocks** | Boss 系统实现 |
| **Ordering Note** | AI 依赖战斗系统提供行动接口，需在 ADR-004 之后实现 |

## Context

### Problem Statement

SRPG 需要 AI 控制敌方单位在战斗中做出合理决策。AI 必须满足：行为可学习（玩家可预判）、行为有多样性（不同敌人不同个性）、Boss 有阶段变化。同时 AI 不能过于强大（玩家必须能赢）或过于简单（没有挑战）。

### Current State

`src/core/ai/` 中已有部分实现：Boss AI、威胁系统等。本 ADR 规范化现有实现。

### Constraints

- AI 决策在单帧内完成（非异步）
- 每个 AI 类型有可配置的决策权重
- Boss 阶段切换需与 boss-system.md 对齐

### Requirements

- 4 种 AI 类型：攻击型、防御型、支援型、控制型
- 威胁/仇恨系统驱动目标选择
- Boss 阶段切换（HP 阈值触发）
- AI 配置数据驱动（非硬编码）

## Decision

### 分层架构

```
AISystem (Node)
├── AIDecisionEngine — 三层决策协调
│   ├── TacticalLayer — "打什么目标"
│   │   └── ThreatTable — 威胁值计算 + 仇恨排序
│   ├── StrategyLayer — "用什么方式打"
│   │   └── SkillSelector — 技能权重 + 冷却检查
│   └── ExecutionLayer — "具体位置和时机"
│       └── PositionScorer — 地形评分 + 高低差利用
├── AIConfigLoader — 加载 AI 配置文件
└── BossPhaseController — Boss 阶段管理
```

### 威胁值公式

```
threat_score = damage_potential × 1.0
             + proximity_factor × 0.5
             + hp_threat_factor × 0.3
             + role_affinity    × 0.2
```

### AI 配置文件格式

```json
{
  "ai_type": "aggressive",
  "target_weights": { "damage": 1.0, "proximity": 0.5, "hp_threat": 0.3 },
  "skill_preference": { "attack": 0.7, "debuff": 0.2, "buff": 0.1 },
  "position_preference": "offensive",
  "boss_phases": null
}
```

### Boss 阶段切换

| 阶段 | HP 阈值 | 行为变化 |
|------|---------|----------|
| Phase 1 | >70% | 基础攻击模式 |
| Phase 2 | 50-70% | 技能频率增加，使用特殊技能 |
| Phase 3 | <50% | 狂暴模式，伤害 +30%，新技能解锁 |

## Alternatives Considered

### Alternative 1: GOAP (Goal-Oriented Action Planning)

- **Rejection Reason**: 复杂度过高，SRPG 回合制 AI 不需要动态规划

### Alternative 2: 硬编码行为

- **Rejection Reason**: 不可配置，违反数据驱动原则（coding-standards.md）

## Consequences

### Positive

- AI 配置数据驱动，策划可独立调参
- 分层架构便于单独测试各层逻辑
- Boss 阶段机制与 GDD 对齐

### Negative

- 三层决策增加实现复杂度
- 配置文件数量随敌人类型增长

## Risks

| Risk | Probability | Impact | Mitigation |
|------|------------|--------|------------|
| AI 过于聪明/愚蠢 | 高 | 高 | Tuning Knobs 外部配置，实战调参 |
| Boss 阶段切换卡顿 | 低 | 中 | 阶段切换在一帧内完成 |
| 配置文件管理混乱 | 中 | 低 | 命名规范 + CI 校验 |

## Performance Implications

| Metric | Budget | Notes |
|--------|--------|-------|
| 单单位 AI 决策 | <5ms | 含三层评估 |
| Boss 阶段检查 | <0.1ms | HP 阈值比较 |

## Validation Criteria

- [ ] 4 种 AI 类型行为模式可区分
- [ ] 威胁值排序与 GDD 公式一致
- [ ] Boss 阶段在 HP 阈值正确切换
- [ ] AI 配置从文件加载，非硬编码
- [ ] 自动战斗模式使用相同 AI 配置

## GDD Requirements Addressed

| GDD Document | Requirement | How Addressed |
|-------------|-------------|---------------|
| ai-system.md | 分层决策架构 | AIDecisionEngine 三层 |
| ai-system.md | 4 种 AI 类型 | AI 配置文件 ai_type 字段 |
| ai-system.md | 威胁/仇恨系统 | ThreatTable |
| ai-system.md | Boss AI 阶段切换 | BossPhaseController |
| boss-system.md | 阶段 HP 阈值 | 70%/50% 阈值触发 |
| turn-based-mode.md | 自动战斗 AI | 复用 AIDecisionEngine |

## Related

- ADR-001: 事件架构
- ADR-004: Combat System (AI 接收行动接口)

## Acceptance History

| Field | Value |
|-------|-------|
| **Accepted on** | 2026-04-26 |
| **Accepted via** | Sprint-002 governance closure |
| **Reason** | 12 epic Complete 引用本 ADR，需消除合规绕过风险 |
