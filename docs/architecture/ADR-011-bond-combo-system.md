# ADR-011: Bond Combo Skill Architecture

> **Status**: Accepted
> **Date**: 2026-05-01
> **Author**: technical-director
> **Systems Affected**: Bond System, Combat System, Action System, Battle HUD, Save System

---

## Context

Sprint-009 将实现羁绊组合技系统 MVP。GDD `bond-system.md` 已定义 4 种羁绊类型的组合技效果（战友/师徒/宿敌/恋人）、触发门槛（曼哈顿距离 ≤3、双方存活未撤退、A 级羁绊）、消耗模型（主动型消耗行动点、反应型消耗反应次数）和冷却管理。系统需复用现有 BondRegistry pair key 和 battle unit id，不引入未落地的公共接口。

---

## Decision

### 1. ComboSkill 作为独立数据资源

组合技定义为 `ComboSkillData` Resource，不硬编码在脚本中：

```gdscript
class_name ComboSkillData extends Resource
var skill_id: String           # "combo_comrade_strike" etc.
var bond_type: int             # BondType enum
var skill_type: int            # DAMAGE / TEMP_SKILL / BUFF / GUARD
var ap_cost: int               # 行动点消耗
var cooldown_turns: int        # 冷却回合数
var range_max: int = 3         # 曼哈顿距离上限
var effect_params: Dictionary  # 类型特定参数
```

**理由**: 与技能系统、装备系统一致的数据驱动模式，方便调参和扩展。

### 2. 冷却管理在 battle_state 上

冷却按 `pair_key + skill_id` 存储在 `battle_state.combo_cooldowns: Dictionary`，不写入永久 SaveData。

**理由**: 冷却属于战术层临时状态（与 speed_controller cooldown 同级），跨战斗存档恢复后冷却清零是预期行为（GDD 明确）。

### 3. 触发流程通过 game_events 信号解耦

```
UI Button Press → GameEvents.combo_skill_requested.emit(pair_key, skill_id)
  → ComboValidator.check_thresholds() [距离/AP/冷却/存活/控制]
    → ComboExecutor.execute() [消耗 → 效果 → 冷却写入]
      → GameEvents.combo_skill_executed.emit(result)
```

不新增 `trigger_combo_skill` 全局方法，全部走信号链。Battle HUD 监听 `combo_skill_executed` 刷新状态。

### 4. MVP 仅玩家可主动触发

AI 不触发组合技。`bond-system.md` GDD 已明确 "Sprint-009 MVP 仅玩家可主动触发；敌方/AI 羁绊组合技需单独 story"。ComboValidator 在调用方传入 `is_player: bool` 进行 gating。

### 5. 4 种效果类型的实现策略

| 类型 | 实现方式 |
|------|---------|
| 伤害型（协力一击） | 复用现有 damage pipeline，乘以 1.5 系数 + 无视 20% 防御 |
| 临时技能型（技能传授） | 在 unit status_effects 中写入临时技能引用，持续 3 回合后自动移除 |
| 增益型（竞争觉醒） | 写入 attack_bonus status_effect，持续 2 回合 |
| 防护型（誓约守护） | 注册 `before_fatal_damage` 拦截器，消耗 30% HP 抵消致命伤害 |

所有效果通过现有 status_effect / combat modifier 管线实现，不新建并行的 buff 系统。

---

## Consequences

### Positive

- 与现有技能/状态效果管线一致，实现量可控
- 信号链解耦 UI 触发和逻辑执行，双方便于独立测试
- 冷却不污染永久存档
- 4 种效果类型复用现有管线，无额外架构成本

### Negative

- 依赖 BondRegistry 已有 pair key 生成逻辑，如 pair key 格式变更会影响组合技查找
- 距离校验（曼哈顿 ≤3）在 25×25 战斗网格上需要扫描双方位置，实现时需缓存 unit position lookup

---

## Rejected Alternatives

- **将 combo skill 作为普通 Skill 子类处理**: 拒绝——组合技涉及双人消耗、类型特定逻辑、冷却 pair-scoped，与单人 Skill 模型差异大。
- **ComboExecutor 直接调用 damage/status 模块而非通过信号**: 拒绝——信号链提供统一的日志/测试钩子。
- **AI 同时实现 combo skill**: 推迟——GDD 明确 Sprint-009 仅玩家触发。

---

## Verification Required

- Unit test: ComboValidator 门槛检查（距离/AP/冷却/存活/控制）
- Unit test: 4 种 combo 类型的 effect_params 正确性
- Integration test: 完整 trigger→execute→cooldown→HUD refresh 链路
- Edge case: 任一门槛不满足时按钮禁用 + 短文本原因提示

---

## ADR Dependencies

- **ADR-004** (Combat System): damage pipeline 复用
- **ADR-003** (Save System): 冷却不写入永久存档（battle_state 级别）
- **ADR-001** (Event Architecture): combo_skill_requested / combo_skill_executed 信号
- **ADR-006** (Attribute Data Model): combo bonus 不绕过属性系统加成规则

---

## Engine Compatibility

| Engine | Godot 4.6.2 |
|--------|-------------|
| `Resource` 子类 `ComboSkillData` | ✓ |
| `Dictionary` 存储 pair-scoped cooldowns | ✓ |
| 信号链在 `game_events` Autoload 中注册 | ✓ |

---

## GDD Requirements Addressed

- `design/gdd/bond-system.md` — TR-bond-005（组合技触发：曼哈顿 ≤3、AP 消耗、冷却、4 种 bond-type 效果）
- `design/gdd/bond-system.md` — TR-bond-006（组合技战斗 UI + 玩家主动触发 MVP）
