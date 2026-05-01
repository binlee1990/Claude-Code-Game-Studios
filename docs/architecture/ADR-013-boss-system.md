# ADR-013: Boss System Architecture

> **Status**: Accepted
> **Date**: 2026-05-01
> **Author**: technical-director
> **Systems Affected**: Boss System, AI System, Combat System, Save System, Battle Settlement, HP System

---

## Context

Sprint-009 将创建 Boss 系统 Epic 并落地数据模型（5 类型分类 + 检查点规范 + 失败恢复策略）。GDD `boss-system.md` 定义教学/叙事/能力测试/巅峰/隐藏 5 种 Boss 类型、多阶段检查点机制、血量阈值阶段切换（50%/25%）、失败后血量保留 15%、资源消耗兜底公式。Sprint-009 MVP 聚焦于数据模型和 action pattern 规格，具体阶段切换逻辑和检查点系统推至后续实现 story。

---

## Decision

### 1. Boss 数据模型分层定义

```gdscript
class_name BossProfile extends Resource
var boss_type: int              # BossType enum: TUTORIAL/NARRATIVE/APTITUDE/PEAK/HIDDEN
var phases: Array[BossPhase]    # 阶段定义
var action_patterns: Array[BossActionPattern]  # 行动模式池
var checkpoint: BossCheckpoint  # 检查点数据
```

`BossProfile` 从 battle_definition JSON 的 `boss` 节加载，不硬编码。

### 2. BossType 枚举决定默认行为参数

| BossType | 默认阶段数 | 默认检查点 | ActionPattern 复杂度 | 提示级别 |
|----------|-----------|-----------|---------------------|---------|
| TUTORIAL | 1-2 | Phase start | 简单（2 pattern） | 明确文字提示 |
| NARRATIVE | 2 | Phase start | 中等（3 pattern） | 弱提示 |
| APTITUDE | 2-3 | Phase start | 中等（3 pattern） | 无提示 |
| PEAK | 3+ | Phase start | 复杂（4 pattern） | 无提示 |
| HIDDEN | 多阶段 | Phase start | 最复杂 | 无提示 |

默认值可通过 `BossProfile` 字段覆盖。

### 3. BossPhase 与 BossActionPattern

```gdscript
class_name BossPhase extends Resource
var phase_index: int
var hp_threshold: float         # 触发下一阶段的 HP%（0.50, 0.25）
var active_patterns: Array[int] # 本阶段可用的 action pattern indices
var on_enter_effects: Array[Dictionary]  # 阶段切换时触发的效果

class_name BossActionPattern extends Resource
var pattern_id: String
var telegraph_duration: float = 0.7   # 前兆动画时长（秒）
var range_indicator: int              # 范围指示类型 enum
var element_type: int                 # 元素属性 enum
var cooldown_turns: int = 2           # 最小冷却回合
var targets: int                      # SINGLE / ROW / CROSS / AREA enum
```

### 4. 检查点数据独立于 BossProfile

```gdscript
class_name BossCheckpoint extends Resource
var phase_index: int
var boss_hp_at_checkpoint: int
var retained_hp_ratio: float = 0.15   # 失败后保留血量比例
var free_retries: int = 2             # 免费重试次数
var pattern_hints_revealed: bool = false
```

检查点数据在阶段切换时写入 `battle_state.boss_checkpoint`。与 SaveData 持久化分离——检查点是战术层临时数据，随战斗结束销毁。

### 5. 阶段跨越处理

当单次攻击跨越多个阈值（HP 55%→20%），按顺序依次触发所有跨越的阶段转换。每个阶段的 `on_enter_effects` 立即生效一次，进入最终对应阶段。此逻辑在 BossPhaseController 中实现，不依赖战斗系统的特殊分支。

---

## Consequences

### Positive

- Resource-based 数据模型与技能/装备/难度系统一致
- BossType 枚举提供合理的默认值，减少每个 Boss 的配置量
- 检查点独立于 SaveData 避免 save/load 的检查点语义混淆
- ActionPattern 的 telegraph + range 字段为 BOSS-002 visual feedback 提供数据支撑

### Negative

- BossPhaseController 的阶段跨越逻辑是复杂的 switch-case，需要充分的 edge case 测试
- BossActionPattern 的 5 个枚举字段增加了 battle_definition JSON 的配置复杂度

---

## Rejected Alternatives

- **将 Boss 检查点写入永久存档**: 拒绝——GDD 明确 "失败后从当前阶段重开"，检查点是战术临时状态，不应跨战斗持久化。永久存档存储的是战前状态。
- **用普通 Enemy AI + 特殊权重来实现 Boss 行为**: 拒绝——Boss 的阶段切换、action pattern 轮转、telegraph 需要独立的状态机，附加到通用 AI 上会使 AI 系统过度复杂。
- **阶段阈值使用绝对值而非百分比**: 拒绝——百分比与 DifficultySystem 的 HP 倍率兼容（Difficulty × Boss HP 后百分比阈值仍然有效）。

---

## Verification Required

- Unit test: BossProfile 加载 JSON→Resource 正确性
- Unit test: BossPhase 阈值 50%/25% 切换逻辑
- Unit test: ActionPattern telegraph_duration / cooldown 字段完整性
- Unit test: 单次攻击跨多阶段按序触发
- Integration test: BossProfile 与 DifficultySystem 倍率交互（HP×倍率后百分比阈值仍有效）

---

## ADR Dependencies

- **ADR-012** (Difficulty System): Boss HP/ATK 受 difficulty multiplier 影响
- **ADR-005** (AI Behavior): Boss 使用独立 AI 策略，非通用 enemy AI
- **ADR-004** (Combat System): 阶段切换在 combat tick 中检测
- **ADR-003** (Save System): 检查点不写入永久存档

---

## Engine Compatibility

| Engine | Godot 4.6.2 |
|--------|-------------|
| `Resource` 子类 `BossProfile`/`BossPhase`/`BossActionPattern` | ✓ |
| JSON→Resource 反序列化 | ✓ |
| 阶段切换在 `_process` 中检测（≤16.6ms budget） | ✓ |

---

## GDD Requirements Addressed

- `design/gdd/boss-system.md` — TR-boss-001（Boss 类型分类 5 types + 检查点规范）
- `design/gdd/boss-system.md` — TR-boss-002（Boss action pattern: telegraph + range indicator + cooldown）
