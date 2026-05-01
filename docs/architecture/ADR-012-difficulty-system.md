# ADR-012: Difficulty System Architecture

> **Status**: Accepted
> **Date**: 2026-05-01
> **Author**: technical-director
> **Systems Affected**: Difficulty System, Combat System, Battle Settlement, AI System, Resource Economy

---

## Context

Sprint-009 将实现难度系统数据模型与一周目固定曲线集成。GDD `difficulty-system.md` 定义第一周目 4 阶段固定难度曲线（教学 0.7× / 成长 1.0× / 挑战 1.2× / 高潮 1.4×）和多周目成就点数兑换倍率（2×/4×/8×/16×）。Sprint-009 MVP 仅实现一周目固定曲线 + 集成（enemy stat ×倍率 + settlement ×倍率 + AI 策略等级切换），NG+ 难度倍率选择排除在本 sprint 外。

---

## Decision

### 1. DifficultyProfile 作为中央数据模型

```gdscript
class_name BattleDifficultyProfile extends Resource
var phase: int                  # 1=教学 2=成长 3=挑战 4=高潮
var enemy_stat_mult: float      # 敌人属性倍率
var exp_mult: float             # 经验倍率
var resource_mult: float        # 资源/掉落倍率
var ai_strategy_level: int      # 0=基础 1=进阶 2=最优
```

一周目使用固定 phase→multiplier 映射表，不暴露选择 UI。`BattleDifficultyProfile` 在战斗初始化时由章节范围确定 phase 并查表生成。

### 2. 章节→阶段映射表

| 章节 | Phase | 倍率 |
|------|-------|------|
| 1-2 | 1 (教学) | 0.7× |
| 3-5 | 2 (成长) | 1.0× |
| 6-8 | 3 (挑战) | 1.2× |
| 9-10 | 4 (高潮) | 1.4× |

映射表存储在 `assets/data/difficulty/phase_curve.json`，代码只读不写。

### 3. 集成点通过 Autoload 查询接口

`DifficultyManager` 注册为 Autoload，提供只读查询：

```gdscript
func get_profile(chapter: int) -> BattleDifficultyProfile
func scale_enemy_stat(base_value: float) -> float
func get_exp_multiplier() -> float
func get_resource_multiplier() -> float
func get_ai_strategy_level() -> int
```

Combat、Settlement、AI 系统通过 `DifficultyManager` 查询当前倍率，不持有本地缓存。确保所有系统看到一致的倍率快照。

### 4. 不受难度影响的系统白名单

以下系统明确跳过难度倍率查询：
- BondSystem（好感度增益）
- BeliefSystem（信念值阈值）
- AttributeGrowth（潜质和成长公式）
- SaveSystem（存档槽位和功能）

在 `DifficultyManager` 中维护白名单常量，集成时通过白名单检查避免误伤。

### 5. NG+ 扩展点

`BattleDifficultyProfile` 预留 `ng_multiplier: float = 1.0` 字段。一周目固定为 1.0。NG+ 成就点数兑换系统实现时，该字段成为玩家选择的倍率入口。不创建并行数据结构。

---

## Consequences

### Positive

- 中央 DifficultyManager 提供单一真相来源，避免各系统独立解释倍率
- 白名单机制防止倍率泄漏到不应受影响的系统
- 一章目固定曲线无 UI 成本
- NG+ 扩展点预留，不阻塞当前实现

### Negative

- DifficultyManager 作为新的 Autoload 增加启动时的全局节点数量
- 各系统需要在关键计算点添加 `DifficultyManager.xxx()` 调用，存在遗漏风险

---

## Rejected Alternatives

- **在 combat/settlement/AI 中各存一份倍率副本**: 拒绝——分散管理容易不一致，且需要额外的同步机制。
- **一周目也提供难度选择**: 拒绝——GDD 明确 "第一周目不提供难度选择"，设计上的叙事节奏决策。
- **将倍率直接写入每个战斗定义 JSON**: 拒绝——与章节级别映射的设计意图冲突，且不利于全局调整。

---

## Verification Required

- Unit test: DifficultyProfile 按章节正确映射 phase→multiplier
- Unit test: enemy_stat_mult / exp_mult / resource_mult 查表精度
- Integration test: Combat 中 enemy stat 实际应用了倍率
- Integration test: Settlement 中 exp/drop 实际应用了倍率
- Integration test: AI 策略等级随 phase 切换
- Negative test: Bond affinity 不受 difficulty 影响

---

## ADR Dependencies

- **ADR-004** (Combat System): enemy stat 倍率应用点
- **ADR-005** (AI Behavior): AI 策略等级切换接口
- **ADR-008** (Resource Economy): settlement 倍率与资源产出的一致性

---

## Engine Compatibility

| Engine | Godot 4.6.2 |
|--------|-------------|
| Autoload singleton | ✓ |
| `Resource` 子类 `BattleDifficultyProfile` | ✓ |
| JSON 配置文件加载 | ✓ `FileAccess.get_file_as_string()` |

---

## GDD Requirements Addressed

- `design/gdd/difficulty-system.md` — TR-diff-001（一周目固定曲线：4 phase × enemy/exp/resource 倍率）
- `design/gdd/difficulty-system.md` — TR-diff-002（难度集成 combat/settlement/AI）
