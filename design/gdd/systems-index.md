# Systems Index: SRPG_MINI — Generic Tactics RPG Skeleton

> **Status**: Draft (lean mode — director sign-off skipped)
> **Created**: 2026-04-28
> **Last Updated**: 2026-04-28
> **Source Concept**: `design/gdd/game-concept.md`

> **Creative Director Sign-Off (CD-SYSTEMS)**: SKIPPED — Lean mode (per `production/review-mode.txt`).
> **Technical Director Sign-Off (TD-SYSTEM-BOUNDARY)**: SKIPPED — Lean mode.
> **Producer Sign-Off (PR-SCOPE)**: SKIPPED — Lean mode.

---

## Overview

SRPG_MINI 是一个通用战棋 RPG 骨架：由 8 个正交系统组成，共同构成通用 SRPG 内核（grid · unit · faction-rotation turn · move · range-attack · pluggable AI · victory check · input/HUD）。系统集合受项目 Anti-Pillars 约束——**不是带主题的 SRPG**、**不是故事系统**、**不是音频**——因此索引结构异常扁平：没有成长层、没有经济层、没有叙事层、没有音频层。每个系统直接服务于核心循环。支柱原则 **System Orthogonality** 约束这 8 个系统之间的交互方式：一个系统的变更不得导致另一个系统需要修改，这迫使所有依赖关系通过显式接口而非内部调用来表达。

---

## Systems Enumeration

| # | System Name | Category | Priority | Status | Design Doc | Depends On |
|---|-------------|----------|----------|--------|------------|------------|
| 1 | Map / Coordinates | Core | MVP | Designed | `design/gdd/map.md` | (none) |
| 2 | Unit *(includes Faction enum at MVP)* | Core | MVP | Designed | `design/gdd/unit.md` | Map |
| 3 | Turn System | Core | MVP | Designed | `design/gdd/turn.md` | Unit |
| 4 | Movement | Gameplay | MVP | Designed | `design/gdd/movement.md` | Map, Unit |
| 5 | Attack | Gameplay | MVP | Designed | `design/gdd/attack.md` | Map, Unit |
| 6 | Victory | Gameplay | MVP | Designed | `design/gdd/victory.md` | Unit |
| 7 | AI *(AIController interface + NullAI default)* | Gameplay | MVP | Designed | `design/gdd/ai.md` | Turn System, Movement, Attack |
| 8 | UI / Input | UI | MVP | Not Started | — | Map, Unit, Turn System, Movement, Attack, Victory |
| — | Faction *(extracted)* | Core | Tier 2 | Pre-registered | — | (none) |
| — | BasicAI | Gameplay | Tier 2 | Pre-registered | — | AI (interface), Map, Unit, Movement, Attack |
| — | Terrain (one type) | Gameplay | Tier 2 | Pre-registered | — | Map, Movement |
| — | Class Triangle | Gameplay | Tier 2 | Pre-registered | — | Unit, Attack |
| — | Save / Load | Persistence | Tier 3 | Pre-registered | — | All MVP gameplay systems |
| — | Main Menu | UI | Tier 3 | Pre-registered | — | (none) |
| — | Multi-Level | Gameplay | Tier 3 | Pre-registered | — | All MVP + Save/Load |
| — | XP / Level-up | Progression | Tier 3 | Pre-registered | — | Unit, Attack, Victory |

> **推断与显式声明说明**：所有 8 个 MVP 系统均显式来源于 `game-concept.md` 的 Module Decisions。Faction 拆分已在 Tier 2 预注册，因为用户选择了"MVP 阶段嵌入，Tier 2 提取"——在 MVP 阶段，Faction 是定义在 Unit GDD 内部的枚举/Resource。

---

## Categories Used

| Category | Description | This Project's Systems |
|----------|-------------|-----------------------|
| **Core** | 所有其他系统依赖的基础系统 | Map, Unit, Turn System |
| **Gameplay** | 使游戏可玩的系统 | Movement, Attack, Victory, AI |
| **UI** | 面向玩家的信息展示 + 输入 | UI / Input |
| **Persistence** | 存档状态 | (仅 Tier 3) |
| **Progression** | 玩家随时间成长 | (仅 Tier 3) |

> 有意省略的分类：**Audio**、**Narrative**、**Meta**、**Economy**——属于显式 Anti-Pillars 或超出 MVP 范围。

---

## Priority Tiers

| Tier | Definition | Status |
|------|------------|--------|
| **MVP** | 构成通用 SRPG 骨架的 8 个模块。缺少任意一个，核心循环（boot → board → move → attack → victory）将无法端到端运行。 | 当前设计目标 |
| **Tier 2 (Vertical Slice)** | 增量扩展，将 MVP 从"抽象骨架"变为"感觉像 SRPG"：真实 AI、地形、职业三角、Faction 拆分。 | 已预注册，无 GDD |
| **Tier 3 (Alpha)** | 包装系统，将 Tier 2 变为独立产品：菜单、存档、成长、多关卡。 | 已预注册，无 GDD |
| **Full Vision** | 不适用——本项目不承诺特定完整愿景。骨架在 MVP 阶段交付，或后续由带主题的分支在此基础上构建。 | 不适用 |

---

## Dependency Map

### 基础层（无依赖）

1. **Map / Coordinates** — 提供网格拓扑、地块状态，以及 world↔grid 坐标边界，所有其他系统通过此边界读取。服务的支柱原则：System Orthogonality（GridSpace 接口是防止坐标逻辑泄漏到渲染层的防火墙）。

### 核心层（依赖基础层）

1. **Unit** — 依赖：Map（单位放置于网格坐标上）。MVP 阶段嵌入 Faction 枚举。五个下游系统消费 Unit 接口——接口稳定性是设计推进的前置条件。
2. **Turn System** — 依赖：Unit（遍历当前阵营内的单位）。阵营轮换状态机。

### 特性层（依赖核心层；层内可并行设计）

1. **Movement** — 依赖：Map（BFS 拓扑）、Unit（位置 + MOV 属性）。产出可达地块集合 + 路径预览。
2. **Attack** — 依赖：Map（范围计算）、Unit（HP / ATK / DEF / RNG 属性）。产出伤害施加；反击钩子预留但禁用。
3. **Victory** — 依赖：Unit（HP / 死亡状态）。产出阵营消灭 + 回合上限检查。

### 特性层 2（依赖特性层 1）

1. **AI / AIController** — 依赖：Turn System（被调用方）、Movement（选择移动目标）、Attack（选择攻击目标）。MVP 仅交付 `NullAI`（热座模式）。接口本身是设计交付物；实现是平凡的。

### 表现层（依赖所有上游系统）

1. **UI / Input** — 依赖：Map（按美术圣经渲染网格 + 地块状态颜色）、Unit（渲染单位 + HP）、Turn System（回合指示器 + End-Turn 按钮）、Movement（范围/路径高亮）、Attack（范围高亮 + 伤害预览）、Victory（win/lose 画面）。此层聚合所有上游系统；也是最晚设计、最易变动的层。

### 润色层

（MVP 阶段无——调试坐标覆盖属于 UI / Input 基线，不属于润色。）

---

## Recommended Design Order

| Order | System | Priority | Layer | Agent(s) | Est. Effort |
|-------|--------|----------|-------|----------|-------------|
| 1 | Map / Coordinates | MVP | Foundation | game-designer + godot-specialist (TileMap consultation) | S |
| 2 | Unit *(includes Faction enum)* | MVP | Core | game-designer | M |
| 3 | Turn System | MVP | Core | game-designer + systems-designer (state machine) | S |
| 4 | Movement | MVP | Feature | systems-designer (BFS over typed grid) | M |
| 5 | Attack | MVP | Feature | systems-designer (damage formula) | M |
| 6 | Victory | MVP | Feature | game-designer | S |
| 7 | AI *(AIController interface + NullAI)* | MVP | Feature | game-designer + technical-director (interface) | M |
| 8 | UI / Input | MVP | Presentation | ux-designer + ui-programmer (consultation) | L |

> 工作量：**S** = 1 个会话，**M** = 2-3 个会话，**L** = 4+ 个会话。

> 并行化说明：Movement、Attack、Victory（顺序 4–6）都仅依赖 Map + Unit，彼此独立——如需要可在并行会话中设计。AI（顺序 7）必须等待 Movement 和 Attack 设计完成，因为 AIController 接口需要两者作为参数。

---

## Circular Dependencies

**未发现循环依赖。**

依赖图是一个最大深度为 5 的 DAG（Map → Unit → Turn System → AI → UI / Input）。最接近循环的是 AI ↔ Turn System 关系：Turn System 调用 AIController，但 AIController 必须回调 Turn System 以发出"我的回合结束"信号。解决方案是将 AIController 视为无状态函数 `take_turn(units, world_state) -> ActionList`，返回预期操作列表；Turn System 拥有执行权。**此解决方案具有约束力**——AI GDD 必须明确规定。

---

## High-Risk Systems

| System | Risk Type | Risk Description | Mitigation |
|--------|-----------|------------------|------------|
| **Map / Coordinates** | Technical | World↔grid 坐标转换逻辑泄漏到渲染层（`pixel_position * tile_size` 数学计算散布各模块）。参见 game-concept.md R4。 | GDD 必须指定单一 `GridSpace` 边界，提供 `world_to_grid` / `grid_to_world` 方法；在代码审查中禁止内联坐标转换（Forbidden Patterns）。 |
| **Unit** | Design | Unit 接口被 5 个下游系统消费。后期变更会级联引发 Movement/Attack/Turn/AI/UI 重写。 | GDD 必须显式定义并锁定公共 Unit 接口（属性、方法、信号），在下游设计开始前完成。将变更视为破坏性变更。 |
| **AI / AIController** | Design | 如果 AIController 接口设计错误，每个 Tier 2 AI 实现（BasicAI、未来的启发式 AI）都需要修改 Turn System。参见 game-concept.md R5。 | AI GDD 草案完成后，运行 `/prototype` 同时搭建 `NullAI` 和一个桩 `BasicAI`，以证明接口至少能容纳两种不同行为而无需修改 Turn System。 |
| **UI / Input** | Scope | UI / Input 依赖所有 gameplay 系统；如果上游系统接口晚期变更，UI 必须返工。 | 最后编写 UI / Input（顺序 8），并将其 GDD 视为上游接口的增量差异文档——在上游锁定之前不要过度细化。 |

---

## Progress Tracker

| Metric | Count |
|--------|-------|
| Total systems identified (MVP) | 8 |
| Total systems pre-registered (Tier 2) | 4 |
| Total systems pre-registered (Tier 3) | 4 |
| Design docs started | 5 |
| Design docs reviewed | 0 |
| Design docs approved | 0 |
| MVP systems designed | 7 / 8 |
| Tier 2 systems designed | 0 / 4 |

---

## Next Steps

- [x] 批准本系统索引（本文档）
- [ ] 运行 `/design-system map` 编写第一个 GDD（顺序 1: Map / Coordinates）
- [ ] 按设计顺序编写 MVP GDD（1 → 8）；顺序 4–6 可并行进行
- [ ] 每个 GDD 完成后运行 `/design-review design/gdd/<system>.md`
- [ ] 全部 8 个 MVP GDD 完成后运行 `/review-all-gdds`（跨系统一致性审查）
- [ ] AI GDD 完成后运行 `/prototype ai-controller`，验证 AIController 接口能容纳两种行为（NullAI + BasicAI 桩）
- [ ] 所有 MVP GDD 审查通过后运行 `/gate-check pre-production`
