# Cross-GDD Review Report

**日期**: 2026-04-29
**已审阅 GDD**: 8
**系统覆盖**: Map、Unit、Turn System、Movement、Attack、Victory、AI、UI/Input

---

## 一致性议题

### 阻塞项（架构开始前必须解决）

**🔴 Map GDD §Interactions 过时引用 — Attack 的 Map 依赖**

Attack GDD 明确声明**不使用** `Map.get_neighbors()` 来计算射程 —— 它使用 Manhattan 距离 + `Map.get_unit_at()`。但 Map GDD 的 Interactions 表仍将 `get_neighbors()` 列为 Attack 用于 "射程环计算" 的依赖项。

- **来源 GDD**: attack.md §Interactions（"Attack 不调用 `get_neighbors()`——射程基于 Manhattan，不是 BFS"）
- **冲突 GDD**: map.md §Interactions（第 68 行: `Attack | Hard | get_neighbors() —— 射程环计算`）
- **解决**: 更新 Map GDD 将 `get_neighbors()` 替换为 `get_unit_at()`。Attack GDD OQ1 已标记此处。

**🔴 Turn System 执行循环缺少 faction 守卫**

AI GDD 标记了一个纵深防御缺口：Turn System 的 ActionList 执行循环（AI GDD Rule 7 步骤 1）仅检查 `has_acted` 和 `is_alive`，**不**检查 `unit.faction == active_faction`。若某 AI 实现错误地将 PLAYER 单位放入 ActionList 并在 ENEMY 阶段返回，Turn 会执行 PLAYER 单位动作。

- **来源 GDD**: ai.md §Edge Cases
- **冲突 GDD**: turn.md Core Rule 7 缺少此守卫
- **解决**: 在 Turn GDD Core Rule 7 执行循环中增加 `unit.faction == active_faction` 检查。AI GDD OQ2 已标记。

---

### 警告项（应解决，但不阻塞）

**⚠️ 依赖不对称 — Map GDD 下游列表缺失 AI**

AI 系统通过 `WorldState.map` 消费 Map 的 `get_neighbors()`、`is_walkable()`、`get_unit_at()` —— 但 Map GDD 的 Downstream Dependencies 表未列出 AI（仅列出 Unit、Movement、Attack、UI）。AI GDD 将 Map 列为 Hard 上游依赖。

- **解决**: map.md §Dependencies → Downstream 表增加 AI（含注释: "通过 WorldState 间接访问"）

**⚠️ Unit GDD 状态机表缺少 SELECTED → ACTED 路径**

Attack GDD 新增了从 SELECTED 直接攻击（不移动）的能力 —— `SELECTED → ACTED`。Unit GDD 状态机表当前仅显示 `IDLE → SELECTED → MOVED → ACTED`。`can_attack()` 已正确支持 `[SELECTED, MOVED]`，但文档不完整。

- **解决**: unit.md §States and Transitions 表增加 SELECTED → ACTED 行

**⚠️ Manhattan 距离所有权已解决但 Movement GDD F2 注记待更新**

Movement GDD OQ2 询问 Manhattan 距离的归属。Attack GDD OQ3 已确认: Movement GDD F2 持有公式定义，Attack GDD F2 引用它。Movement GDD F2 的边界注记可据此更新。

- **解决**: movement.md F2 节更新注记为 "Manhattan 距离由 Movement GDD 所有；Attack 系统引用但不重定义"

---

## 游戏设计议题

### 阻塞项
无。

### 警告项

**⚠️ 认知负荷 — UI/Input 是单一巨系统**

UI/Input GDD 合并了 7 个上游系统的全部渲染和输入逻辑，共 65 条 AC（远超其他 GDD 的 25-41 条）。建议分段实现:

1. HUD 层（回合指示器 + End Turn 按钮）
2. 交互流程（选中 → 移动 → 攻击）
3. 覆盖层（胜/负/平画面 + 调试叠加层）

**⚠️ NullAI 耦合热座假设 — 配置时无防护**

NullAI 在非热座模式下会导致 ENEMY 阶段冻结（空 ActionList → auto-advance 永不触发）。AI GDD Edge Cases 记录了此问题，但 Game 场景初始化时无配置守卫。建议在 Game 场景组合时添加一条 `push_warning("NullAI requires hotseat mode")`。

---

## 跨系统场景议题

### 已走查场景

1. **Move+Attack 完整组合动作**（Movement + Attack + Unit + Map + Turn + UI）
2. **单位死亡级联**（Attack → Unit → Map → Turn → Victory → UI）
3. **回合转换 — ENEMY 阶段结束**（Turn → Victory → AI → Input → UI）

### 阻塞项
无。

### 警告项

**⚠️ 场景 1 — BFS 计算与移动执行之间的 TOCTOU 窗口**

Movement GDD Edge Cases 已记录此窗口。缓解方案: `Map.move_unit()` 原子拒绝，但 Input 尚无明确的重新计算/反馈策略。需确认: `Map.move_unit()` 返回 false 时 UI 是否重新触发 BFS。

**⚠️ 场景 3 — NullAI + 热座模式的信号流分散在三个 GDD 中**

ENEMY 阶段热座操作流程涉及 Turn（发射 `faction_activated(ENEMY)`）、AI（NullAI 空 ActionList）、UI/Input（消费信号操作 ENEMY）。三段描述分散在三个 GDD 中，建议在 Turn GDD §Interactions AI 行添加统一的信号流注记。

---

## 需修订的 GDD

| GDD | 原因 | 类型 | 优先级 |
|-----|------|------|--------|
| map.md | Attack 依赖接口过时（`get_neighbors()` → `get_unit_at()`） | 一致性 | 阻塞 |
| turn.md | 执行循环缺少 faction 守卫（AI GDD 缺口） | 一致性 | 阻塞 |
| map.md | 下游依赖表缺失 AI | 一致性 | 警告 |
| unit.md | 状态机表缺失 SELECTED → ACTED 路径 | 一致性 | 警告 |
| movement.md | F2 归属注记待更新（Manhattan 所有权已解决） | 一致性 | 警告 |

---

## 优点（无问题领域）

- **所有 8 个系统均与 4 个设计支柱对齐**，无支柱漂移，无反支柱违规
- **玩家幻想高度统一**: 所有 GDD 共享"透明、确定性、可预测"的核心主题
- **依赖图为 DAG**，无循环依赖 —— 已验证 systems-index
- **公式兼容性**: 所有上游公式输出范围与下游输入范围匹配（damage [1,8] → take_damage [1,∞); BFS 可达集 → MovementResult API; VictoryChecker → match_ended）
- **经济循环**: MVP 无经济系统 —— 不存在来源/消耗失衡风险
- **无竞争进阶循环**: MVP 无 XP / 等级 / 成长系统 —— 不存在优先权冲突
- **认知负荷**: 核心循环中 4 个活跃系统（选择、移动、攻击、End Turn）—— 在 3-4 的舒适范围内
- **无主导策略**: 确定性伤害、对称阵营、无 RNG 确保无"明显正确"的选择

---

## 裁定: CONCERNS

2 个阻塞项需在架构开始前解决。无设计理论阻塞项。所有警告项可在实现阶段增量处理。

### 继续 `/create-architecture` 前必须完成的动作:

1. **Map GDD**: 修正 Attack 的 Map 依赖从 `get_neighbors()` 改为 `get_unit_at()`
2. **Turn GDD**: 在执行循环中增加 `unit.faction == active_faction` 守卫
