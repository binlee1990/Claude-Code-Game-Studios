# Victory

> **Status**: Designed (pending review)
> **Author**: binlee1990 + Claude
> **Last Updated**: 2026-04-29
> **Implements Pillar**: Pillar 2 — System Orthogonality; Pillar 3 — Minimum Complete
> **Creative Director Review (CD-GDD-ALIGN)**: SKIPPED — Lean mode (per `production/review-mode.txt`)

## Overview

Victory 系统是比赛终局的判定者：它定义谁赢、为什么赢、以及何时结束。Victory 提供两种结束条件——**阵营全灭**（一方所有单位死亡，另一方获胜）和**回合上限**（达到 `turn_cap` 后按存活单位数判定胜负或平局）——并通过 `VictoryChecker.determine_winner()` 方法暴露给 Turn System 调用。Victory 不主动轮询；它等待 Turn System 在 `FACTION_PHASE_ENDING` 时查询，返回 `{winner, reason}` 结构体。判定结果通过 Turn System 的 `match_ended` 信号广播，最终由 UI / Input 系统渲染为胜/负/平局画面。对于玩家而言，Victory 是每一步决策的锚点：移动、攻击、站位——每一次点击都服务于一个明确的问题：*这步棋让我更接近胜利还是失败？* 没有 Victory，比赛将是一场没有尽头的消耗战：单位会死，但棋盘永远不知道何时可以宣布游戏结束。

## Player Fantasy

Victory 的幻想是双层的：**资源消解为基调，将死时刻为顶点。**

主要感受是**每一步都在消耗对方的存活资源**。一个敌方单位的死亡不是"故事中的损失"——它是棋盘上少了一个威胁、少了一个选项、少了一个需要围住的棋子。PLAYER 的每一次攻击都在缩减 ENEMY 的 `alive_count`，而这个数字的变化是可见的、可数的、不可逆的。胜利不是突如其来的惊喜；它是一局开始时就明确的条件，每一步棋都在沿着同一条箭头推进。当棋盘上最后一个红色方块消失时，结果更像"方程已解"而非"戏剧收场"。

但最后一步值得一个微小的停顿。当玩家点击最终攻击、看到 HP 归零、单位消失、"ENEMY: 0"——那一刻是**将死**：一条逻辑线走到了终点，一个早就可以预见的结局被兑现。这个停顿不需要特效或音效；它只需要 UI 在这一帧确认：*你看见了那条路径，你走完了它。*

这与 Programmer Art Functional 的诚实性一致：Victory 不做氛围，不做张力。它做数学。但数学的完成本身——当一个开发者在控制台看到 `faction_eliminated = true` 时——可以有一种安静的满足感。

## Detailed Design

### Core Rules

1. **VictoryChecker 身份**: `VictoryChecker` 是一个 `RefCounted` 纯函数对象——不持有状态，不发起信号，不主动轮询。由 Game 场景（composition root）创建，依赖注入到 `TurnManager`。对齐 `GridSpace`、`AttackResolver` 等既有模式。

2. **判定接口**: `determine_winner(units: Array[Unit], turn_number: int, turn_cap: int) -> Dictionary`

   返回结构：
   ```
   {
     winner: Faction.Type,   // PLAYER / ENEMY / NONE
     reason: String           // "" (继续) / "elimination" / "turn_cap"
   }
   ```
   `winner == NONE` 当且仅当 `reason == ""`（无终止条件，比赛继续）或 `reason == "turn_cap"` 且存活数相等（平局）。

3. **终止条件优先级**: Elimination > Turn Cap。只要任一阵营 `alive_count == 0`，`reason` 必为 `"elimination"`，`turn_cap` 检查不参与。这在 Turn System 的 `FACTION_PHASE_ENDING` 流程中通过 elimination 先于 turn_cap 检查来保证；VictoryChecker 内部同样遵循此优先级。

4. **判定表**:

   | alive_p | alive_e | cap_breached | winner | reason |
   |---------|---------|-------------|--------|--------|
   | >0 | >0 | false | NONE | "" |
   | >0 | >0 | true, alive_p > alive_e | PLAYER | "turn_cap" |
   | >0 | >0 | true, alive_e > alive_p | ENEMY | "turn_cap" |
   | >0 | >0 | true, alive_p == alive_e | NONE | "turn_cap" |
   | >0 | 0 | — | PLAYER | "elimination" |
   | 0 | >0 | — | ENEMY | "elimination" |
   | 0 | 0 | — | PLAYER | "elimination" |

   `cap_breached = (turn_number > turn_cap)`。`—` 表示不参与判定。

5. **双方同时全灭**: PLAYER 获胜，`reason = "elimination"`。这是对玩家友好的兜底——MVP 无 counter-attack 且无 AoE，此场景几乎不可能自然发生，但接口必须定义。

6. **回合上限平局**: 当 `turn_number > turn_cap` 且 `alive_p == alive_e > 0` 时，`winner = NONE`，`reason = "turn_cap"`。`match_ended` 信号携带 `NONE` 向 UI 表达平局。

7. **end_reason 单一真相源**: Turn System 的 `FACTION_PHASE_ENDING` 路由逻辑直接使用 VictoryChecker 返回的 `reason` 作为 `match_ended` 信号的 `reason`。Turn System 不再自行推导 `end_reason`（Turn GDD F4 公式中 `end_reason` 推导行标记废弃，改为 `end_reason = victory_result.reason`）。消除 Turn GDD 中 F4 与 step 4 的 `end_reason` 来源冲突。

8. **Turn GDD 对齐**: 本 GDD 修正了 Turn GDD 中的以下不一致：
   - Turn GDD F4 `end_reason` 推导逻辑 → 废弃，改为委托 VictoryChecker
   - Turn GDD step 4 "flag faction_eliminated" → 语义修正为"flag has_winner"（因 turn_cap 也可能产生胜者）
   - Turn GDD 第 224 行注释中 `determine_winner(alive_counts, end_reason)` 签名 → 更新为 `determine_winner(units, turn_number, turn_cap)`
   - Turn GDD 第 77 行 "winner may be NONE for draws" → 确认：`NONE` 仅在 reason="turn_cap" + 存活数相等时出现，以及 reason="" 时出现

### States and Transitions

VictoryChecker 是无状态纯函数。不存在内部状态、状态机、或生命周期管理。每次 `determine_winner()` 调用是独立的——给定相同输入，始终返回相同输出。状态变化由 Turn System 管理（`MATCH_NOT_STARTED → FACTION_PHASE_ACTIVE → FACTION_PHASE_ENDING → MATCH_ENDED`）；Victory 仅在 `FACTION_PHASE_ENDING` 步骤中提供判定。

### Interactions with Other Systems

| System | Direction | Data Flow | Interface |
|--------|-----------|-----------|-----------|
| **Turn System** | Upstream (caller) | 在 FACTION_PHASE_ENDING step 4 调用 `determine_winner()` | 传入 `units`, `turn_number`, `turn_cap`；返回 `{winner, reason}` |
| **Turn System** | Downstream (via Turn) | Turn System 使用返回值做路由决策 → emit `match_ended(reason, winner)` | VictoryChecker 不直接发信号；`match_ended` 由 Turn System 发出 |
| **Unit** | Upstream (reads) | 读取 `unit.faction: Faction.Type`，`unit.is_alive: bool` | 只读，不修改 Unit 状态 |
| **UI / Input** | Indirect | 通过 Turn System 的 `match_ended` 信号接收 winner + reason | UI 根据 `winner` 决定胜/负/平画面；根据 `reason` 决定措辞 |

## Formulas

### F1: alive_count

The alive_count formula is defined as:

`alive_count(faction) = |{ u ∈ units : u.faction == faction ∧ u.is_alive }|`

**Variables:**

| Variable | Symbol | Type | Range | Description |
|----------|--------|------|-------|-------------|
| 目标阵营 | faction | enum | {PLAYER, ENEMY} | 要计数的阵营 |
| 已注册单位 | units | Array[Unit] | [0, N] | 比赛中所有单位 |
| 存活数 | result | int | [0, N] | 该阵营存活单位数量 |

**Output Range:** [0, N]，其中 N 为该阵营的初始单位数。永不返回负数。

**Extreme Behavior:**
- 阵营无单位（从未放置）：返回 0 → 触发 elimination
- 阵营所有单位死亡：返回 0 → 触发 elimination

**Example:** 3 PLAYER 单位（U1 alive, U2 dead, U3 alive）+ 2 ENEMY 单位（E1 dead, E2 dead） → `alive_count(PLAYER) = 2`, `alive_count(ENEMY) = 0` → elimination branch，PLAYER 胜。

### F2: cap_breached

The cap_breached formula is defined as:

`cap_breached = (turn_number > turn_cap)`

**Variables:**

| Variable | Symbol | Type | Range | Description |
|----------|--------|------|-------|-------------|
| 当前回合数 | turn_number | int | [1, turn_cap + 1] | Turn System 已递增后的值 |
| 回合上限 | turn_cap | int | [1, 99] | 来自 TurnConfig.tres |
| 上限突破 | cap_breached | bool | {true, false} | 是否超出回合上限 |

**Output Range:** {true, false}。Strict greater-than（`>`），与 Turn GDD F2 的 `new_turn_number > turn_cap` 一致。`turn_number` 永远不超过 `turn_cap + 1`（Turn System 状态机保证）。

**Example:** turn_number = 30, turn_cap = 30 → `30 > 30` = false → 比赛继续。turn_number = 31, turn_cap = 30 → `31 > 30` = true。

### F3: determine_winner

The determine_winner formula is defined as:

```
alive_p = alive_count(PLAYER)
alive_e = alive_count(ENEMY)

if alive_p == 0 or alive_e == 0:
    // Elimination branch (highest priority)
    if alive_p == 0 and alive_e == 0:  winner = PLAYER
    else if alive_p == 0:              winner = ENEMY
    else:                              winner = PLAYER
    reason = "elimination"

else if cap_breached:
    // Turn cap branch
    if alive_p > alive_e:       winner = PLAYER
    else if alive_e > alive_p:  winner = ENEMY
    else:                       winner = NONE
    reason = "turn_cap"

else:
    // No end condition met
    winner = NONE
    reason = ""
```

**Variables:**

| Variable | Symbol | Type | Range | Description |
|----------|--------|------|-------|-------------|
| PLAYER 存活 | alive_p | int | [0, N] | F1 输出 |
| ENEMY 存活 | alive_e | int | [0, N] | F1 输出 |
| 上限突破 | cap_breached | bool | {true, false} | F2 输出 |
| 胜者 | winner | enum | {PLAYER, ENEMY, NONE} | 胜利阵营；NONE = 平局或未结束 |
| 原因 | reason | String | {"", "elimination", "turn_cap"} | 终止原因；空串 = 比赛继续 |

**Output Range:** 7 种有效组合，见 Section C 判定表。语义约束：`reason` 非空 ⇔ 比赛已结束；`winner == NONE` 且 `reason != ""` → 平局。

**Example 1:** alive_p=3, alive_e=0 → `{PLAYER, "elimination"}` — PLAYER 全灭敌人。

**Example 2:** alive_p=3, alive_e=1, turn_number=31, turn_cap=30 → `{PLAYER, "turn_cap"}` — 回合上限到达，PLAYER 存活数多。

**Example 3:** alive_p=2, alive_e=2, turn_number=31, turn_cap=30 → `{NONE, "turn_cap"}` — 回合上限到达，存活数相等，平局。

**Example 4:** alive_p=0, alive_e=0 → `{PLAYER, "elimination"}` — 双方全灭，PLAYER 胜（兜底规则）。

> **与 Turn GDD 的边界**: F2（cap_breached）复述了 Turn GDD F2（turn increment）中的比较逻辑，以便 VictoryChecker 可独立计算。Turn System 可在调用前预先计算 `turn_cap_reached` 作为优化，但 VictoryChecker 不依赖此预计算——它以 `turn_number` 和 `turn_cap` 为输入自行判断。
>
> **end_reason 归属**: Turn GDD F4 中 `end_reason` 的推导逻辑标记废弃。`end_reason` 的唯一来源是 VictoryChecker 返回的 `reason` 字段。Turn System 的 FACTION_PHASE_ENDING 路由逻辑改为：`victory = victory_checker.determine_winner(...); should_end_match = (victory.winner != NONE); end_reason = victory.reason`。

## Edge Cases

- **If `units` 为空数组**: `alive_p = 0, alive_e = 0` → elimination branch → `{PLAYER, "elimination"}`。比赛在同帧开始并结束——有效退化行为，与 Turn GDD AC-TURN-046 一致。

- **If ENEMY 从未被放置（alive_e = 0）**: elimination branch → `{PLAYER, "elimination"}`。Turn System 的 vacuous truth auto-advance 触发此路径。PLAYER 立即获胜。

- **If PLAYER 从未被放置（alive_p = 0）**: elimination branch → `{ENEMY, "elimination"}`。PLAYER 立即失败。地图设计者应在布局时收到警告（非 VictoryChecker 职责）。

- **If turn_number = 31, turn_cap = 30**: `31 > 30` → cap_breached = true。若双方均有存活 → turn_cap branch 按存活数判定；若任一方全灭 → elimination branch 优先。

- **If elimination 与 turn_cap 同时满足**（例如最后一个 ENEMY 被击杀后 turn_number 递增越过上限）: elimination 优先，`reason = "elimination"`，而非 `"turn_cap"`。与 Turn GDD F4 优先级一致。

- **If cap_breached = true 且 alive_p == alive_e > 0**: `{NONE, "turn_cap"}` → 平局。`match_ended` 信号携带 `NONE` 向 UI 表达平局画面。

- **If cap_breached = true, alive_p > alive_e**: `{PLAYER, "turn_cap"}`。**If alive_e > alive_p**: `{ENEMY, "turn_cap"}`。存活多者胜，回合上限作为触发原因。

- **If turn_cap = 1, 双方均有存活单位**: Turn 1 → PLAYER phase 结束（不递增）→ ENEMY phase 结束 → turn_number 递增至 2 > 1 → turn_cap branch 按存活数判定。PLAYER 只有一个 phase 的行动机会。适用于快速测试。

- **If Turn System 在 MATCH_ENDED 状态下再次调用 determine_winner**: VictoryChecker 作为纯函数不感知调用方状态——仅根据输入计算。Turn GDD AC-TURN-038 确保 MATCH_ENDED 后不再次调用。VictoryChecker 不重复守卫此条件。

- **If units 中包含已 `queue_free()` 的单位引用**: VictoryChecker 使用 `is_instance_valid(u)` 守卫，已释放的单位在计数时跳过。这是 GDScript 特有的安全网——正常路径下 Turn System 在 `unit_died` 时从 `_all_units` 中移除引用，此守卫仅防御绕过信号路径的异常情况。

- **If units 中存在 faction 非 PLAYER/ENEMY 的单位**（未来扩展）: 当前 Faction.Type 仅有 PLAYER 和 ENEMY 两值。若 Tier 2 引入第三方阵营，`alive_count()` 需要对未知 faction 返回 0 或被显式传入。VictoryChecker 的判定逻辑（基于两阵营比较）不可直接扩展到三方。此边缘情况记录为设计约束——三方阵营需要重写判定逻辑，而非修补。

- **If `turn_number` 传入值 < 1**（输入校验）: `determine_winner()` 前置条件: `turn_number >= 1`。由 Turn System 保证（match 从 turn_number=1 开始，永不递减）。若传入 0 或负数，当前逻辑 `0 > turn_cap` = false，无终止条件，等效于比赛继续——对调用方是静默错误。VictoryChecker 内部加 `assert(turn_number >= 1)` 守卫。

- **If `turn_cap` 传入值 < 1**（输入校验）: `determine_winner()` 前置条件: `turn_cap >= 1`。由 TurnConfig.tres 的 [1, 99] 范围保证。若传入 0，`turn_number=1, turn_cap=0` → `1 > 0` = true，cap_breached 在 turn 1 即触发。VictoryChecker 内部加 `assert(turn_cap >= 1)` 守卫。

## Dependencies

### Upstream Dependencies

| System | Type | Interface Consumed | Notes |
|--------|------|--------------------|-------|
| **Unit** | Hard | `unit.faction: Faction.Type`, `unit.is_alive: bool` | 只读。VictoryChecker 仅需这两个字段判定胜负。接口由 Unit GDD 锁定 |
| **Turn System** | Hard (caller) | 调用 `determine_winner(units, turn_number, turn_cap)` | Turn System 在 FACTION_PHASE_ENDING step 4 发起调用。传入当前单位列表、已递增的回合数、回合上限 |
| **TurnConfig.tres** | Data (indirect) | `turn_cap: int` | VictoryChecker 通过参数接收 `turn_cap`，不直接加载 TurnConfig。Turn System 持有 TurnConfig 并在调用时传入 |

### Downstream Dependencies

| System | Type | Interface Exposed | Notes |
|--------|------|-------------------|-------|
| **Turn System** | Hard | 返回 `Dictionary{winner: Faction.Type, reason: String}` | Turn System 使用返回值做路由决策（继续 → FACTION_PHASE_ACTIVE；终止 → MATCH_ENDED）和信号参数 |
| **UI / Input** | Indirect | 通过 Turn System 的 `match_ended(reason, winner)` 信号接收 | UI 根据 `winner` 显示胜/负/平画面；根据 `reason` 选择措辞 |

### External Dependencies

| Dependency | Type | Notes |
|------------|------|-------|
| `VictoryChecker` (RefCounted) | Code | 纯函数对象。由 Game 场景创建，依赖注入到 TurnManager。匹配 GridSpace / AttackResolver 模式 |
| `Faction.Type` enum | Code | 定义在 `src/core/faction.gd`（Unit GDD 所有）。VictoryChecker 读取，不拥有。包括 `NONE` 值用于平局表达 |

## Tuning Knobs

| Knob | Location | Safe Range | What Happens If Too Low | What Happens If Too High | Notes |
|------|----------|------------|------------------------|------------------------|-------|
| `turn_cap` | TurnConfig.tres（Turn System 所有） | [1, 99] | 1: match 在 1 个完整 cycle 后结束——几乎不可玩，仅用于快速测试 | 99: 回合上限几乎永不触发，失去 deadlock guard 意义 | 由 Turn GDD 定义和维护。VictoryChecker 通过参数接收此值，不拥有。默认 30 |

VictoryChecker 本身没有任何自有可调参数。判定逻辑（elimination 优先、对称存活数比较、双方全灭 → PLAYER 胜）是硬编码规则——Pillar 3（Minimum Complete）下不需要可配置的胜利条件。若 Tier 2+ 引入"得分胜利"或"护送目标"等替代条件，届时需将判定逻辑重构为可插拔的 `VictoryCondition` 接口。

## Visual/Audio Requirements

N/A — Victory 是纯逻辑判定系统，不拥有渲染节点，不产生视觉或音频输出。胜利/失败/平局的画面渲染由 UI / Input 系统根据 `match_ended(reason, winner)` 信号负责。

## UI Requirements

Victory 不直接渲染 UI，但通过 Turn System 的 `match_ended` 信号向 UI 系统提供以下数据：

| 信号参数 | 类型 | UI 用途 |
|----------|------|---------|
| `reason` | String | 决定结束画面措辞："elimination" → "敌方全灭" / "我方全灭"；"turn_cap" → "回合上限到达" |
| `winner` | Faction.Type | 决定画面类型：PLAYER → 胜利画面；ENEMY → 失败画面；NONE → 平局画面 |

UI / Input GDD (Module 8) 负责定义具体的 win/lose/draw 画面布局、文字、按钮（重新开始）。Victory 仅保证 `match_ended` 信号携带正确的判定结果。

> **📌 UX Flag — Victory**: Victory 的输出是 UI / Input 系统的上游数据源。在 Phase 4 (Pre-Production)，`/ux-design` 应引用 `match_ended` 信号的 `winner` 和 `reason` 字段作为胜利/失败/平局画面的数据契约。注意在 systems index 中为 UI / Input 系统记录此依赖。

## Acceptance Criteria

### A. 判定表覆盖 (Core Rules 2-4)

**AC-VICTORY-001 — 无终止条件，比赛继续** [Logic]
GIVEN 2 PLAYER alive, 2 ENEMY alive, turn_number=5, turn_cap=30, WHEN `determine_winner(units, turn_number, turn_cap)`, THEN returns `{winner: NONE, reason: ""}`.

**AC-VICTORY-002 — Turn cap, PLAYER 存活多** [Logic]
GIVEN 3 PLAYER alive, 1 ENEMY alive, turn_number=31, turn_cap=30, WHEN `determine_winner(units, turn_number, turn_cap)`, THEN returns `{winner: PLAYER, reason: "turn_cap"}`.

**AC-VICTORY-003 — Turn cap, ENEMY 存活多** [Logic]
GIVEN 1 PLAYER alive, 4 ENEMY alive, turn_number=31, turn_cap=30, WHEN `determine_winner(units, turn_number, turn_cap)`, THEN returns `{winner: ENEMY, reason: "turn_cap"}`.

**AC-VICTORY-004 — Turn cap, 存活数相等，平局** [Logic]
GIVEN 2 PLAYER alive, 2 ENEMY alive, turn_number=31, turn_cap=30, WHEN `determine_winner(units, turn_number, turn_cap)`, THEN returns `{winner: NONE, reason: "turn_cap"}`.

**AC-VICTORY-005 — Elimination, ENEMY 全灭** [Logic]
GIVEN 3 PLAYER alive, 0 ENEMY alive, turn_number=10, turn_cap=30, WHEN `determine_winner(units, turn_number, turn_cap)`, THEN returns `{winner: PLAYER, reason: "elimination"}`.

**AC-VICTORY-006 — Elimination, PLAYER 全灭** [Logic]
GIVEN 0 PLAYER alive, 2 ENEMY alive, turn_number=10, turn_cap=30, WHEN `determine_winner(units, turn_number, turn_cap)`, THEN returns `{winner: ENEMY, reason: "elimination"}`.

**AC-VICTORY-007 — 双方同时全灭，PLAYER 胜（兜底规则）** [Logic]
GIVEN 0 PLAYER alive, 0 ENEMY alive, turn_number=any, turn_cap=any, WHEN `determine_winner(units, turn_number, turn_cap)`, THEN returns `{winner: PLAYER, reason: "elimination"}`.

### B. 公式 F1: alive_count

**AC-VICTORY-010 — 基础计数（混合 alive/dead）** [Logic]
GIVEN units = [P1(alive), P2(dead), P3(alive), E1(dead), E2(alive)], WHEN 内部计算 alive_count(PLAYER) 和 alive_count(ENEMY), THEN alive_p = 2, alive_e = 1.

**AC-VICTORY-011 — 阵营无单位（空数组）** [Logic]
GIVEN units = []（空数组）, WHEN 内部计算 alive_count(PLAYER) 和 alive_count(ENEMY), THEN alive_p = 0, alive_e = 0.

**AC-VICTORY-012 — 单方布阵，另一方零单位** [Logic]
GIVEN units = [P1(alive), P2(alive)]（仅有 PLAYER 单位）, WHEN 内部计算 alive_count(ENEMY), THEN alive_e = 0, 触发 elimination → PLAYER 胜.

**AC-VICTORY-013 — 全部死亡** [Logic]
GIVEN units = [P1(dead), P2(dead), E1(dead)], WHEN 内部计算 alive_count, THEN alive_p = 0, alive_e = 0 → elimination branch → PLAYER 胜.

### C. 公式 F2: cap_breached

**AC-VICTORY-014 — 未突破上限：边界值 (turn_number == turn_cap)** [Logic]
GIVEN turn_number=30, turn_cap=30, WHEN 计算 cap_breached = (turn_number > turn_cap), THEN cap_breached = false.

**AC-VICTORY-015 — 突破上限 (turn_number == turn_cap + 1)** [Logic]
GIVEN turn_number=31, turn_cap=30, WHEN 计算 cap_breached = (turn_number > turn_cap), THEN cap_breached = true.

**AC-VICTORY-016 — 远未突破上限** [Logic]
GIVEN turn_number=1, turn_cap=30, WHEN 计算 cap_breached = (turn_number > turn_cap), THEN cap_breached = false.

### D. 公式 F3: determine_winner 结构验证

**AC-VICTORY-017 — 返回结构完整性** [Logic]
GIVEN 任意合法输入, WHEN determine_winner(...) 被调用, THEN 返回 Dictionary 包含且仅包含 key `winner` (Faction.Type) 和 `reason` (String).

**AC-VICTORY-018 — reason 非空 ⇔ 比赛结束** [Logic]
GIVEN 遍历所有 7 个判定表行, WHEN 检查每个输出的 reason 和 winner, THEN reason != "" 当且仅当 winner == PLAYER 或 winner == ENEMY 或 (winner == NONE 且 reason == "turn_cap"). reason == "" 当且仅当 winner == NONE（比赛继续）.

**AC-VICTORY-019 — 纯函数确定性** [Logic]
GIVEN 相同输入调用 3 次, WHEN determine_winner(units, turn_number, turn_cap) 重复调用, THEN 3 次返回完全相同的 Dictionary（值相等，非引用相等）.

### E. 核心边缘情况

**AC-VICTORY-020 — Elimination 优先于 Turn Cap** [Logic]
GIVEN alive_p=2, alive_e=0, turn_number=31, turn_cap=30（同时满足 elimination 和 cap_breached）, WHEN determine_winner(units, turn_number, turn_cap), THEN returns `{winner: PLAYER, reason: "elimination"}` — elimination 优先级高于 turn_cap.

**AC-VICTORY-021 — turn_cap = 1 快速结束** [Logic]
GIVEN alive_p=1, alive_e=1, turn_number=2, turn_cap=1, WHEN determine_winner(units, turn_number, turn_cap), THEN cap_breached=true, alive_p==alive_e → `{winner: NONE, reason: "turn_cap"}`.

**AC-VICTORY-022 — is_instance_valid 守卫：已释放单位被跳过** [Logic]
GIVEN units 数组包含 1 个已 queue_free() 的 PLAYER 单位引用 + 1 个 alive ENEMY 单位, WHEN determine_winner(units, turn_number=1, turn_cap=30), THEN alive_p 计数跳过已释放单位 → alive_p=0, alive_e=1 → `{winner: ENEMY, reason: "elimination"}`.

**AC-VICTORY-023 — is_instance_valid 守卫：所有单位均已释放** [Logic]
GIVEN units 数组所有元素均为已 queue_free() 的引用, WHEN determine_winner(units, turn_number=1, turn_cap=30), THEN alive_p=0, alive_e=0 → `{winner: PLAYER, reason: "elimination"}`.

**AC-VICTORY-024 — 比赛刚开始无终止条件** [Logic]
GIVEN alive_p=2, alive_e=2, turn_number=1, turn_cap=30, WHEN determine_winner(units, turn_number, turn_cap), THEN `{winner: NONE, reason: ""}`.

**AC-VICTORY-025 — turn_cap 边界：safe range 上限 (99)** [Logic]
GIVEN alive_p=5, alive_e=3, turn_number=100, turn_cap=99, WHEN determine_winner(units, turn_number, turn_cap), THEN cap_breached=true → `{winner: PLAYER, reason: "turn_cap"}`.

**AC-VICTORY-026 — 未知 faction 不计入任一 alive_count** [Logic]
GIVEN units 包含一个 faction = NONE（或未知枚举值）的 alive 单位 + 1 PLAYER alive + 1 ENEMY alive, WHEN 内部计算 alive_count(PLAYER) 和 alive_count(ENEMY), THEN faction 非 PLAYER/ENEMY 的单位不计入任一 alive_count.

**AC-VICTORY-027 — 单一存活单位 + Turn Cap 平局** [Logic]
GIVEN alive_p=1, alive_e=1, turn_number=31, turn_cap=30, WHEN determine_winner(units, turn_number, turn_cap), THEN `{winner: NONE, reason: "turn_cap"}`.

**AC-VICTORY-028 — 存活数差异为 1 + Turn Cap，最小优势判定** [Logic]
GIVEN alive_p=2, alive_e=1, turn_number=31, turn_cap=30, WHEN determine_winner(units, turn_number, turn_cap), THEN `{winner: PLAYER, reason: "turn_cap"}`.

**AC-VICTORY-029 — turn_number < 1 输入校验** [Logic]
GIVEN turn_number=0, WHEN determine_winner(units, turn_number, turn_cap), THEN assert(turn_number >= 1) 失败，带消息说明非法值.

**AC-VICTORY-030 — turn_cap < 1 输入校验** [Logic]
GIVEN turn_cap=0, WHEN determine_winner(units, turn_number, turn_cap), THEN assert(turn_cap >= 1) 失败，带消息说明非法值.

### F. Integration（集成路径）

**AC-VICTORY-040 — Turn System 在 FACTION_PHASE_ENDING 中正确调用** [Integration]
GIVEN Turn System 处于 FACTION_PHASE_ENDING，ENEMY phase 刚结束，turn_number 已递增, WHEN Turn System 执行 step 4: `victory = victory_checker.determine_winner(units, turn_number, turn_cap)`, THEN 使用 VictoryChecker 返回值做路由决策：winner != NONE → MATCH_ENDED；winner == NONE → FACTION_PHASE_ACTIVE.

**AC-VICTORY-041 — match_ended 信号携带正确的 winner 和 reason** [Integration]
GIVEN 比赛中最后一个 ENEMY 单位被击杀，Turn System 检测到 faction eliminated, WHEN Turn System 过渡到 MATCH_ENDED，emit match_ended(reason, winner), THEN reason = "elimination"，winner = PLAYER.

**AC-VICTORY-042 — end_reason 来源唯一性** [Integration]
GIVEN Turn System 的 F4 公式已废弃 end_reason 推导, WHEN 任意终止条件触发, THEN match_ended 信号的 reason 参数直接取自 victory_result.reason，Turn System 不自行推导。验证方法：grep 确认 Turn System 源码中 `end_reason` 赋值仅来自 `victory_result.reason`.

### Summary

| Category | Count | Logic | Integration |
|----------|-------|-------|-------------|
| 判定表覆盖 (A) | 7 | 7 | 0 |
| 公式 F1: alive_count (B) | 4 | 4 | 0 |
| 公式 F2: cap_breached (C) | 3 | 3 | 0 |
| 公式 F3: 结构验证 (D) | 3 | 3 | 0 |
| 核心边缘情况 (E) | 11 | 11 | 0 |
| Integration (F) | 3 | 0 | 3 |
| **Total** | **31** | **28** | **3** |

**Gate Summary:**
- **BLOCKING (Logic)**: 28 criteria — each requires an automated unit test in `tests/unit/victory/`
- **BLOCKING (Integration)**: 3 criteria — each requires an integration test or documented playtest

**Test file locations:**
- `tests/unit/victory/victory_checker_test.gd` — 28 Logic AC
- `tests/integration/victory/turn_victory_integration_test.gd` — 3 Integration AC

## Open Questions

- **OQ1 — Turn GDD 修正时机**: 本 GDD 修正了 Turn GDD 中的 4 处不一致（end_reason 来源、faction_eliminated 语义、determine_winner 签名描述、NONE 语义）。这些修正应在 Victory GDD 锁定后 retroactively 更新到 Turn GDD。→ 建议在 `/consistency-check` 后统一修正。

- **OQ2 — Tier 2 扩展性**: 本 GDD 的判定逻辑基于两阵营比较（PLAYER vs ENEMY）且 elimination 只有一种形态。若 Tier 2+ 引入第三方阵营、得分胜利、护送目标等替代条件，`VictoryChecker` 的重构方向是将判定逻辑从"硬编码分支"变为"可插拔的 VictoryCondition 接口列表"（每个 condition 返回 `{is_met: bool, winner: Faction.Type, reason: String}`）。这是一个架构决策——是否在 MVP 就预留接口？→ 倾向于 Tier 2 处理；MVP 保持简单。若需要提前锁定，可开 ADR。

- **OQ3 — 投降 / 认输**: 当前没有 concede 路径。若未来需要，Turn System 可新增 `concede(faction)` 方法直接路由到 MATCH_ENDED，VictoryChecker 需新增 `reason = "concede"`。→ 不在 MVP 范围。
