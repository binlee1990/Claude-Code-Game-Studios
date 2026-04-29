# Turn System

> **Status**: In Design
> **Author**: binlee1990 + Claude
> **Last Updated**: 2026-04-29
> **Implements Pillar**: Pillar 2 — System Orthogonality（Turn 状态机对外暴露信号，不暴露内部状态）

## Overview

Turn System 是驱动"谁行动、何时行动"的阵营轮转状态机。系统在两个阵营之间循环 —— PLAYER → ENEMY → PLAYER —— 管理当前活跃阵营，当活跃阵营的所有单位均已行动后自动推进，并暴露一个手动"End Turn"覆盖入口。Turn System 自身不持有任何玩法状态：它从 Unit 系统读取 `faction` 和 `has_acted_this_turn`，在回合边界发射信号（`turn_started`、`faction_activated`、`turn_ended`），并在新阵营回合开始时对所有单位调用 `reset_action_state()`。一个可配置的回合上限作为僵局守卫终止比赛。Turn System 是一个纯粹的协调者 —— 它告诉每个其他系统"轮到你了"或"还没轮到你"，仅此而已。没有它，就没有结构：单位将冻结在棋盘上，没有推进行动的机制，没有行动顺序的约束，比赛除了歼灭之外无法结束。

## Player Fantasy

Turn System 赋予比赛一个心跳 —— 每个阵营阶段的边界都是一个自然的停顿：审视棋盘、评估威胁、做出计划。没有它，棋盘是冻结的；有了它，比赛在呼吸。在节奏之下是一份保证：双方阵营遵循同一个时钟，每轮一次回合，没有隐藏的优先级把戏。玩家始终知道自己处于循环的哪个位置，当每个单位都已行动后，系统自动推进 —— 没有被遗忘的单位，没有歧义。

## Detailed Design

### Core Rules

1. **阵营轮转顺序**：固定的双阵营循环：`PLAYER → ENEMY → PLAYER → ...`。循环永不跳过任何阵营 —— 即使某阵营存活单位数为零，阶段转换仍然发生（按规则 3 立即 auto-advance）。

2. **回合流程**：当某个阵营阶段开始时，该阵营所有单位的 `has_acted_this_turn == false`（由 `reset_action_state()` 重置）。玩家逐个选择活跃阵营的单位；每个单位可移动并随后攻击（一次打包动作），完成后 `has_acted_this_turn` 被置为 `true`。阶段持续直到 (a) 活跃阵营所有存活单位的 `has_acted == true`（规则 3），或 (b) 玩家按下 End Turn（规则 4）。

3. **Auto-Advance**：每次单位完成行动后以及每次 `unit_died` 信号后，Turn System 轮询"全部已行动"条件：对于所有满足 `u.faction == active_faction AND u.is_alive` 的单位 `u`，检查 `u.has_acted_this_turn == true`。当此条件成立，Turn System 立即转换到 `FACTION_PHASE_ENDING`。这包括活跃阵营在阶段开始时存活单位数为零的平凡情况。

4. **手动 End Turn**：在 MVP 阶段，End Turn 在任何阵营阶段期间均可用（PLAYER 和 ENEMY 均可，因为热座模式下双方均由玩家控制）。按下 End Turn 会转换到 `FACTION_PHASE_ENDING`；活跃阵营中尚未行动的存活单位将丧失本阶段的行动机会。当 Tier 2 BasicAI 替换 NullAI 时，AI 通过 `AIController` 自主发出完成信号；届时 ENEMY 阶段的 End Turn 可通过 `TurnConfig` 中的 `end_turn_allowed_during_phase: Dictionary[Faction.Type, bool]` 配置。End Turn 在阶段转换期间受重入调用保护。

5. **回合上限**：比赛有一个可配置的 `turn_cap`，存储在 `TurnConfig.tres`（一个自定义 Resource）中，满足 Pillar 1（数据驱动）。默认值：30。范围：[1, 99]。当 ENEMY 阶段结束后 `turn_number > turn_cap` 时，比赛以 `turn_cap_reached` 原因终止。Victory 系统根据最终棋盘状态判定胜者/平局。

6. **回合计数**：一个"回合" = 一个完整的阵营循环（PLAYER 阶段 + ENEMY 阶段）。`turn_number` 在比赛开始时从 `1` 起算。每次 ENEMY 阶段结束时加 1。在 HUD 中显示为"Turn X/Y"。

7. **阶段中单位死亡**：当单位在阶段中途死亡时，该单位被排除在"全部已行动"检查之外（仅计入 `is_alive` 的单位）。如果死亡导致"全部已行动"条件成立，auto-advance 立即触发。此外：如果单位死亡导致整个阵营被歼灭（存活单位数为零），阶段立即结束 —— 被歼灭阵营剩余未行动单位被跳过，比赛转换到 `MATCH_ENDED`。

8. **比赛开始**：始终由 PLAYER 阵营先手。`turn_number = 1`。初始化期间对所有单位（双方阵营）调用 `reset_action_state()`。

9. **架构**：`TurnManager` 是一个 `RefCounted` 实例，由 Game 场景（composition root）创建并通过依赖注入传递给所有消费者（Input、Victory、AI、UI）。它直接发射信号 —— MVP 阶段不使用 SignalBus Autoload。这匹配 Map GDD 建立的 `GridSpace` 模式，并满足项目"依赖注入优于单例"的标准。`TurnManager` 在比赛初始化时通过 `start_match(all_units: Array[Unit])` 接收单位列表；它不从场景树中发现单位。

### States and Transitions

**States:**

| State | 含义 | 玩家可见？ |
|-------|------|-----------|
| `MATCH_NOT_STARTED` | 比赛尚未开始。无阵营活跃。输入被屏蔽。 | 是 —— 赛前界面 |
| `FACTION_PHASE_ACTIVE` | 某阵营正在行动。`active_faction` 的单位可被选择。 | 是 —— 正常玩法 |
| `FACTION_PHASE_ENDING` | 阵营阶段之间的过渡。处理中：单位重置、回合递增、胜利检查。输入被屏蔽。 | 短暂 —— MVP 阶段为同步；预留给未来的过渡动画 |
| `MATCH_ENDED` | 比赛结束。不再接受任何输入。终态。 | 是 —— 结果界面 |

**Transition Table:**

| From | To | Trigger | Actions |
|------|----|---------|---------|
| `MATCH_NOT_STARTED` | `FACTION_PHASE_ACTIVE` | `start_match(units)` | 设置 `active_faction = PLAYER`。设置 `turn_number = 1`。对所有单位调用 `reset_action_state()`。依次发射 `match_started`、`turn_started(1)`、`faction_activated(PLAYER)`。 |
| `FACTION_PHASE_ACTIVE` | `FACTION_PHASE_ENDING` | Auto-advance 条件满足 或 收到 `end_turn_requested` | 防止重入调用。发射 `faction_phase_ended(active_faction)`。执行结束序列（见下方）。 |
| `FACTION_PHASE_ENDING` | `FACTION_PHASE_ACTIVE` | 结束序列完成 且 比赛未结束 | `active_faction = next_faction`。发射 `faction_activated(next)`。若 `next == PLAYER`：发射 `turn_started(turn_number)`。 |
| `FACTION_PHASE_ENDING` | `MATCH_ENDED` | 结束序列完成 且（回合上限达到 或 阵营被歼灭） | 发射 `match_ended(reason, winner)`。禁用所有输入。 |
| `MATCH_ENDED` | （无） | 终态 | — |

**FACTION_PHASE_ENDING 处理序列**（同步执行）：

1. 确定下一个阵营：`next = (active_faction == PLAYER) ? ENEMY : PLAYER`
2. 重置进入方单位：对所有满足 `u.faction == next` 的 `u`：调用 `u.reset_action_state()`
3. 若结束方为 ENEMY：`turn_number += 1`。若 `turn_number > turn_cap`：标记 `turn_cap_reached`
4. 通过 `VictoryChecker.determine_winner(units, turn_number, turn_cap)` 进行胜利检查：返回 `{winner: Faction.Type, reason: String}`。若 `winner != NONE`：设置 `has_winner = true`。（此前读取 `flag faction_eliminated`，现已重命名 —— 因为 turn_cap 也能在无歼灭的情况下产生胜者。）
5. 路由：若 `has_winner` → 转换到 `MATCH_ENDED`，携带 `match_ended(victory.reason, victory.winner)`。否则 → 转换到 `FACTION_PHASE_ACTIVE`，携带 `active_faction = next`。

> **注意**：`end_reason` 不再由 Turn System 推导。唯一可信来源是 VictoryChecker 的 `victory.reason`。Turn System F4 的 `end_reason` 推导行已被废弃 —— 参见 Victory GDD F3 边界注释。

### Signals

| Signal | 发射时机 | 消费者 |
|--------|---------|--------|
| `match_started()` | 比赛初始化完成 | UI、Victory |
| `turn_started(turn_number: int)` | 每次 PLAYER 阶段开始时（新回合开始） | UI/HUD —— 回合计数器 |
| `faction_activated(faction: Faction.Type)` | 某阵营开始其阶段 | UI/HUD —— 回合指示器；Input —— 按阵营启用/禁用单位选择；AI —— `take_turn()` 入口点（Tier 2） |
| `faction_phase_ended(faction: Faction.Type)` | 某阵营阶段结束 | UI —— 过渡；Input —— 清除选择 + 高亮 |
| `match_ended(reason: String, winner: Faction.Type)` | 比赛终止 | UI —— 结果界面；Input —— 禁用所有交互；AI —— 取消（Tier 2） |

`reason` 取值：`"elimination"` 或 `"turn_cap"`。`winner` 可能为 `PLAYER`、`ENEMY` 或 `Faction.Type.NONE`。`NONE` 仅在 `reason = "turn_cap"` 且双方阵营存活数相等（平局）时出现；否则 `winner` 为非 NONE。对于互相歼灭（双方阵营存活数均为 0），VictoryChecker 按 Victory GDD 返回 `{PLAYER, "elimination"}`。

### Interactions with Other Systems

| System | 方向 | 数据流 | 接口 |
|--------|------|--------|------|
| **Unit** | 上行（读取） | Turn System 读取单位状态 | `unit.faction`、`unit.has_acted_this_turn`、`unit.is_alive` |
| **Unit** | 下行（写入） | Turn System 重置单位 | `unit.reset_action_state()` —— 比赛开始时对所有单位调用，每个阶段开始时对进入阵营的单位调用 |
| **Unit** | 上行（信号） | 单位死亡通知 | 监听所有已注册单位的 `unit.unit_died(unit)`。收到后：重新评估 auto-advance 和阵营歼灭 |
| **AI** | 下行（调用，Tier 2） | Turn System 在 ENEMY 阶段调用 AI | `AIController.take_turn(units, world_state) -> ActionList`。Turn System 持有返回动作的执行权。MVP 阶段：AI 为 `NullAI` —— `faction_activated(ENEMY)` 由 Input 系统消费，用于热座控制 |
| **Victory** | 下行（信号） | Turn System 通知比赛结束 | 发射 `match_ended(reason, winner)`。Victory 系统通过 `VictoryChecker.determine_winner()` 持有胜者/平局判定逻辑 |
| **Victory** | 上行（调用） | Turn System 查询胜者 | `VictoryChecker.determine_winner(units, turn_number, turn_cap) -> Dictionary{winner, reason}`。在 FACTION_PHASE_ENDING 步骤 4 中调用 |
| **UI / Input** | 下行（数据） | Turn System 暴露 HUD 状态 | `active_faction: Faction.Type`、`turn_number: int`、`turn_cap: int`、`current_state: TurnState` —— 由 HUD 读取，用于回合指示器和 End Turn 按钮可见性 |
| **UI / Input** | 上行（调用） | 玩家触发 End Turn | `end_current_faction_turn()` —— 由 Input 系统在 End Turn 按钮按下时调用。有守卫：若 `current_state != FACTION_PHASE_ACTIVE` 或正在转换中则忽略 |
| **Movement / Attack** | 间接 | Turn System 仅门控输入 | Turn System 不直接调用 Movement 或 Attack。它暴露 `active_faction` 和 `current_state`；Input 系统使用这些属性强制"仅活跃阵营的单位可被选择" |

## Formulas

### F1: Auto-Advance 条件

auto-advance 公式定义为：

`auto_advance = ∀ u ∈ units : (u.faction == active_faction ∧ u.is_alive) → u.has_acted`

**Variables:**

| Variable | Symbol | Type | Range | Description |
|----------|--------|------|-------|-------------|
| Auto-advance 标志 | auto_advance | bool | {true, false} | 活跃阵营阶段是否应结束 |
| 活跃阵营 | active_faction | enum | {PLAYER, ENEMY} | 当前执行阶段的阵营 |
| 已注册单位 | units | Array[Unit] | [0, N] | 比赛中的所有单位 |
| 单位阵营 | u.faction | enum | {PLAYER, ENEMY} | 单位所属阵营 |
| 单位存活 | u.is_alive | bool | {true, false} | hp > 0 |
| 单位已行动 | u.has_acted | bool | {true, false} | 单位本阶段已完成移动+攻击 |

**Output Range:** 当活跃阵营所有存活单位均已行动（或没有存活单位 —— 空真）时为 `true`。当活跃阵营至少有一个存活单位尚未行动时为 `false`。

**Extreme Behavior:**
- 活跃阵营存活单位数为零：空真 → `auto_advance = true`，阶段立即转换。
- 活跃阵营有 ≥1 个存活、未行动单位：`auto_advance = false`。
- 所有存活单位均已行动：`auto_advance = true`。

**示例：** active_faction = PLAYER。3 个玩家单位：U1（存活，未行动），U2（存活，已行动），U3（存活，未行动）。首次检查命中 U1 → `has_acted == false` → 立即返回 `false`。玩家必须操作 U1 和 U3，或按下 End Turn。

### F2: 回合递增

回合递增公式定义为：

```
if ending_faction == ENEMY:
    new_turn_number = turn_number + 1
    turn_cap_reached = (new_turn_number > turn_cap)
else:
    new_turn_number = turn_number
    turn_cap_reached = false
```

**Variables:**

| Variable | Symbol | Type | Range | Description |
|----------|--------|------|-------|-------------|
| 结束方阵营 | ending_faction | enum | {PLAYER, ENEMY} | 阶段刚刚结束的阵营 |
| 当前回合 | turn_number | int | [1, turn_cap] | 递增前的回合计数 |
| 新回合 | new_turn_number | int | [1, turn_cap + 1] | 递增后的回合计数 |
| 回合上限 | turn_cap | int | [1, 99] | 每场比赛最大回合数（来自 TurnConfig.tres，默认 30） |
| 上限达到 | turn_cap_reached | bool | {true, false} | 回合上限是否已被超过 |

**Output Range:** `new_turn_number ∈ [1, turn_cap + 1]`。不会超过 `turn_cap + 1` —— 一旦超过，比赛结束且不再递增。

**Extreme Behavior:**
- `turn_cap = 1`：首次 ENEMY 阶段结束 → `turn_cap_reached = true`。
- `turn_cap = 99`：正常递增，极不可能触发。
- PLAYER 阶段结束：`turn_number` 不变，`turn_cap_reached` 始终为 `false`。

**示例：** turn_number = 5，turn_cap = 30，ending_faction = ENEMY → `new_turn_number = 6`，`6 > 30` → `false`，比赛继续。若 turn_number = 30，ending_faction = ENEMY → `new_turn_number = 31`，`31 > 30` → `true`，比赛结束。

### F3: 下一个阵营

下一个阵营公式定义为：

`next_faction = (active_faction == PLAYER) ? ENEMY : PLAYER`

**Variables:**

| Variable | Symbol | Type | Range | Description |
|----------|--------|------|-------|-------------|
| 活跃阵营 | active_faction | enum | {PLAYER, ENEMY} | 阶段正在结束的阵营 |
| 下一个阵营 | next_faction | enum | {PLAYER, ENEMY} | 下一个开始阶段的阵营 |

**Output Range:** {PLAYER, ENEMY}。始终是 `active_faction` 的对立面。

**示例：** active_faction = PLAYER → next_faction = ENEMY。active_faction = ENEMY → next_faction = PLAYER。确定性，无边界情况。

### F4: 比赛结束条件

比赛结束条件公式定义为：

```
faction_eliminated = (alive_count(PLAYER) == 0) OR (alive_count(ENEMY) == 0)
should_end_match = turn_cap_reached OR faction_eliminated
end_reason = faction_eliminated ? "elimination" : (turn_cap_reached ? "turn_cap" : "")
```

> ⚠️ **已废弃（2026-04-29）**：`end_reason` 推导行已被废弃。根据 Victory GDD F3 边界注释，`end_reason` 的唯一可信来源是 `VictoryChecker.determine_winner()` 的 `victory.reason`。Turn System 的 FACTION_PHASE_ENDING 路由（步骤 5）现在直接使用 `victory.winner` 和 `victory.reason`。此公式保留用于解释完整性，但实现不得独立推导 `end_reason` —— 必须委托给 VictoryChecker。

**Variables:**

| Variable | Symbol | Type | Range | Description |
|----------|--------|------|-------|-------------|
| 阵营被歼灭 | faction_eliminated | bool | {true, false} | 至少一个阵营存活单位数为零 |
| 回合上限达到 | turn_cap_reached | bool | {true, false} | F2 的输出 |
| 比赛应结束 | should_end_match | bool | {true, false} | 是否路由到 MATCH_ENDED？ |
| 结束原因 | end_reason | String | {"", "elimination", "turn_cap"} | 比赛为何结束 |

**Output Range:** `should_end_match ∈ {true, false}`。`end_reason` 非空当且仅当 `should_end_match == true`。

**Extreme Behavior:**
- 双方阵营同时被歼灭：`faction_eliminated = true`，`end_reason = "elimination"`。胜者由 VictoryChecker 判定。
- `turn_cap_reached` 和 `faction_eliminated` 同时成立：在 FACTION_PHASE_ENDING 序列中，`faction_eliminated` 优先被评估；`end_reason = "elimination"`。

**示例 1：** PLAYER 存活 = 3，ENEMY 存活 = 0 → `faction_eliminated = true` → `should_end_match = true`，`end_reason = "elimination"`。

**示例 2：** `turn_cap_reached = true`，双方阵营均有存活单位 → `should_end_match = true`，`end_reason = "turn_cap"`。VictoryChecker 按单位数判定胜者。

**示例 3：** `turn_cap_reached = false`，`faction_eliminated = false` → `should_end_match = false`。路由到下一个 FACTION_PHASE_ACTIVE。

### F5: 阵营存活计数

阵营存活计数公式定义为：

`alive_count(faction) = |{ u ∈ units : u.faction == faction ∧ u.is_alive }|`

**Variables:**

| Variable | Symbol | Type | Range | Description |
|----------|--------|------|-------|-------------|
| 目标阵营 | faction | enum | {PLAYER, ENEMY} | 需要计数的阵营 |
| 已注册单位 | units | Array[Unit] | [0, N] | 比赛中的所有单位 |
| 存活计数 | result | int | [0, N] | 目标阵营中存活单位的数量 |

**Output Range:** [0, N]，其中 N 为该阵营初始单位数。永不为负。

**Extreme Behavior:**
- 阵营无单位（没有放置）：返回 0 → F1 空真 auto-advance，F4 faction_eliminated。
- 阵营所有单位死亡：返回 0 → `faction_eliminated = true`。

**示例：** 3 个 PLAYER 单位（U1 存活，U2 死亡，U3 存活）→ `alive_count(PLAYER) = 2`。2 个 ENEMY 单位（E1 死亡，E2 死亡）→ `alive_count(ENEMY) = 0` → F4 `faction_eliminated = true`。

> **边界注释**：胜者判定（`VictoryChecker.determine_winner(units, turn_number, turn_cap) -> {winner, reason}`）由 Victory GDD（Module 6）所有。Turn System 检测终止条件并委托"谁赢了"的问题。此签名已从早期 `determine_winner(alive_counts, end_reason)` 草案修正 —— 三参数接口是 Victory GDD 中定义的绑定契约。

## Edge Cases

### 初始化与配置

- **若 `start_match()` 以空单位数组调用**：双方阵营存活单位数为零。PLAYER 阶段开始，F1 空真触发立即 auto-advance → FACTION_PHASE_ENDING → PLAYER 阶段结束（turn_number 保持 1，因为结束方是 PLAYER 而非 ENEMY）→ VictoryChecker 看到双方阵营 alive_count=0 → faction_eliminated → MATCH_ENDED，winner=NONE（平局）。比赛在一帧内开始并结束。这是空棋盘的有效退化行为。

- **若 `start_match()` 仅以一个阵营的单位调用**：PLAYER 阶段在有 PLAYER 单位时正常进行，若 PLAYER 为零则立即 auto-advance。当 FACTION_PHASE_ENDING 运行时，空阵营触发 faction_eliminated → MATCH_ENDED。空阵营永远不会得到阶段。有效行为；地图设计者应在放置时收到警告（非 Turn System 的职责）。

- **若 `start_match()` 被第二次调用**（current_state != MATCH_NOT_STARTED）：拒绝。`push_error("start_match() called while match already in progress")`。无状态变更。防止意外重新初始化导致 turn_number 和单位列表被重置。

- **若 `TurnConfig.tres` 缺失或加载失败**：`start_match()` 断言 `turn_config != null`，消息中包含预期的文件路径。比赛不启动。不静默回退到硬编码默认值 —— 坏数据就是 bug，与 Unit GDD 的 `.tres` 验证哲学一致。

- **若 `turn_cap` 超出 [1, 99]**（0、负数或 >99）：TurnConfig `@export` 验证在加载时断言，消息中包含文件名、无效值和允许范围。比赛不启动。与 Unit GDD F4（`.tres` 加载时的属性值验证）一致。

- **若 `start_match()` 调用时 `VictoryChecker` 为 null**：`start_match()` 断言 `victory_checker != null`。TurnManager 没有它无法判定胜者；拒绝是硬失败。与依赖注入契约一致。

### 状态转换守卫

- **若 `end_current_faction_turn()` 在 FACTION_PHASE_ENDING 或 MATCH_ENDED 期间被调用**：静默忽略。该方法守卫 `current_state == FACTION_PHASE_ACTIVE`。MVP 阶段转换是同步的，因此正常游玩中不可达；该守卫为未来的异步转换（Tier 2+ 的动画/音效）而存在。

- **若 `end_current_faction_turn()` 从信号处理函数内部被调用**（同一次信号分发期间的重入调用）：`current_state` 守卫将其拒绝 —— 当任何信号处理函数运行时，状态已经是 FACTION_PHASE_ENDING。不会无限递归。

- **若 `unit_died` 信号在 FACTION_PHASE_ENDING 期间触发**（MVP 阶段为理论情况 —— 没有延迟伤害来源）：信号处理函数守卫 `current_state == FACTION_PHASE_ACTIVE`。转换期间的死亡被忽略；歼灭已在结束序列步骤 4 中被检查。

### 数据完整性

- **若 TurnManager 持有已被 `queue_free()` 的单位的引用**：TurnManager 监听 `unit_died` 并在收到后将该单位从内部 `_all_units` 数组中移除：`_all_units.erase(dead_unit)`。单位由 Map 在信号之后释放；TurnManager 不再持有引用。所有单位迭代上的 `is_instance_valid()` 守卫为被绕过的信号路径提供 GDScript 特有的安全网。

- **若外部代码直接设置 `unit.has_acted_this_turn`（绕过定义的流程）**：auto-advance 条件读取任何被设置的值。Turn System 持有 `reset_action_state()`（设为 false）；Movement/Attack 完成持有设为 true。外部写入会产生未定义的 auto-advance 时机。不在运行时守卫 —— 通过代码审查中的 Forbidden Patterns 强制执行。

### 歼灭与回合上限交互

- **若活跃阵营最后一个未行动单位歼灭了一个阵营**（auto-advance 和歼灭同时成立）：`unit_died` 处理函数首先检查歼灭（faction_eliminated = true → 立即 MATCH_ENDED）。auto-advance 被跳过。被歼灭阵营剩余未行动单位无关紧要 —— 比赛已结束。

- **若 `turn_cap_reached` 和 `faction_eliminated` 在同一个 FACTION_PHASE_ENDING 序列中同时成立**：歼灭优先。`end_reason = "elimination"`。当最终的 ENEMY 阶段击杀同时也跨越了回合上限阈值时发生。歼灭是比超时更强的信号。

- **若 `turn_cap = 1` 且一个阵营起始单位数为零**：PLAYER 阶段 → auto-advance（若 PLAYER 为空）或正常游玩 → FACTION_PHASE_ENDING → 结束方为 PLAYER（turn_number 保持 1，不递增 —— 只有 ENEMY 阶段结束才递增）→ 检测到 faction_eliminated → MATCH_ENDED。回合上限从未被检查，因为歼灭首先触发且回合从未递增。有效的退化行为。

### 信号连接生命周期

- **若消费者在 `start_match()` 已触发之后连接 TurnManager 信号**（例如，延迟实例化的 UI 元素）：消费者错过了初始的 `match_started` 和首个 `faction_activated(PLAYER)` 信号。缓解方案：TurnManager 将 `current_state`、`active_faction` 和 `turn_number` 作为公开只读属性暴露。延迟连接的消费者轮询这些属性来初始化其显示。这是文档化的契约，而非 bug。

## Dependencies

### 上行依赖

| System | Type | 消费的接口 | Notes |
|--------|------|-----------|-------|
| **Unit** | Hard | `unit.faction`、`unit.has_acted_this_turn`、`unit.is_alive`、`unit.reset_action_state()`、`unit.unit_died` 信号 | 接口由 Unit GDD 锁定。没有 Unit，Turn System 没有可迭代的对象。 |
| **TurnConfig.tres** | Data | `ResourceLoader.load()` → `turn_cap: int` | 自定义 Resource，位于 `assets/data/`。Pillar 1 合规。 |
| **VictoryChecker** | Hard | `determine_winner(units, turn_number, turn_cap) -> {winner, reason}` | 注入的 RefCounted。在 `start_match()` 之前必须非 null（断言守卫）。 |

### 下行依赖

| System | Type | 暴露的接口 | Notes |
|--------|------|-----------|-------|
| **AI / AIController** | Hard（Tier 2） | 在 ENEMY 阶段调用 `take_turn(units, world_state) -> ActionList` | MVP 阶段：AI 为 `NullAI` —— Turn System 发射 `faction_activated(ENEMY)`，由 Input 系统消费用于热座控制。接口槽位存在，MVP 阶段未接线。 |
| **Victory** | Hard | 发射 `match_ended(reason, winner)`；调用 `VictoryChecker.determine_winner()` | Turn System 检测终止条件；Victory 持有胜者逻辑。双向契约。 |
| **UI / Input** | Hard | 暴露 `active_faction`、`turn_number`、`turn_cap`、`current_state`（只读）；接收 `end_current_faction_turn()` 调用 | HUD 读取状态用于回合指示器 + End Turn 按钮。Input 系统按 `active_faction` 门控单位选择。 |

### 外部依赖

| Dependency | Type | Notes |
|------------|------|-------|
| `TurnConfig` Resource（.tres） | Data | 每场比赛的回合上限配置，位于 `assets/data/`。Pillar 1 合规。 |
| `TurnManager`（RefCounted） | Code | 由 Game 场景（composition root）创建，DI 注入到消费者。匹配 GridSpace 模式。 |
| `Faction.Type` enum | Code | 定义在 `src/core/faction.gd`（Unit GDD）。Turn System 读取，不持有。 |

## Tuning Knobs

| Knob | 位置 | 安全范围 | 过低会怎样 | 过高会怎样 | Notes |
|------|------|---------|-----------|-----------|-------|
| `turn_cap` | TurnConfig.tres | [1, 99] | 1：一个完整循环后比赛结束 —— 几乎无法游玩，仅适用于测试 | 99：单位数量多时比赛可能超过 30 分钟，超出会话预算（5-15 分钟）。>50 时警告。 | 默认 30。每方约 4 个单位时，30 回合约 10-15 分钟。 |
| `end_turn_allowed_during_phase` | TurnConfig.tres（预留） | MVP 阶段 `{PLAYER: true, ENEMY: true}` | N/A —— 预留给 Tier 2 | N/A | 当 BasicAI（Tier 2）替换 NullAI 时，ENEMY → false，由 AI 发出完成信号。定义为 `Dictionary[Faction.Type, bool]`。 |

**Knob 交互**：`turn_cap` 与单位数量交互 —— 每方更多单位意味着更长的阶段，在会话预算内能容纳的总回合数更少。如果 MVP 扩展到每方 6+ 个单位，考虑将 `turn_cap` 降至约 20。

## Visual/Audio Requirements

N/A —— Turn System 是纯逻辑状态机。它不持有渲染节点，不产生音频。回合指示器和 End Turn 按钮的视觉由 UI / Input GDD 持有。`faction_activated` 和 `match_ended` 信号是 UI 用于触发任何视觉转换的钩子。

## UI Requirements

Turn System 不直接渲染 UI，但暴露以下数据供 HUD 消费：

| Data | Type | HUD 用途 |
|------|------|---------|
| `active_faction` | Faction.Type | 回合指示器显示 —— "Player Turn" / "Enemy Turn" |
| `turn_number` | int | "Turn X / Y" 计数器 |
| `turn_cap` | int | "Turn X / Y" 计数器 |
| `current_state` | TurnState | End Turn 按钮可见性（仅在 FACTION_PHASE_ACTIVE 中显示；在 MATCH_ENDED 和 MATCH_NOT_STARTED 中隐藏） |

输入绑定：End Turn 按钮触发 `end_turn` InputMap 动作，该动作路由到 `TurnManager.end_current_faction_turn()`。Input 系统持有按钮控件和点击处理；Turn System 仅接收方法调用。

> **UX 标记 —— Turn System**：此系统贡献 HUD 数据但没有独立界面。在 Phase 4（Pre-Production）中，HUD 的 `/ux-design` 应将 `TurnManager` 的暴露属性引用为回合指示器和 End Turn 按钮的数据源。在 systems index 中为 UI / Input 系统记录此事项。

## Acceptance Criteria

### A. Core Rules

**AC-TURN-001 — 阵营轮转顺序（规则 1）** [Logic]
GIVEN 比赛已开始，`active_faction = PLAYER` 且至少有一个 PLAYER 单位存活，WHEN PLAYER 阶段结束（所有 PLAYER 单位均已行动），THEN `active_faction` 转换为 `ENEMY`，ENEMY 阶段结束后 `active_faction` 转换回 `PLAYER`。

**AC-TURN-002 — 零单位阵营不被跳过（规则 1）** [Logic]
GIVEN 比赛 PLAYER 存活单位数为零、ENEMY 有至少一个存活单位，WHEN 调用 `start_match()`，THEN PLAYER 阶段仍然发生（按 F1 空真立即 auto-advance），ENEMY 阶段开始 —— 循环永不跳过。

**AC-TURN-003 — 阶段开始时单位行动状态重置（规则 2）** [Integration]
GIVEN 某阵营阶段刚刚结束、下一阵营阶段即将开始，WHEN `FACTION_PHASE_ENDING` 处理运行步骤 2（重置进入方单位），THEN 进入方阵营的每个存活单位的 `has_acted_this_turn == false`。

**AC-TURN-004 — 行动后 has_acted 置位（规则 2）** [Integration]
GIVEN 活跃阵营中一个本阶段尚未行动的单位，WHEN 该单位完成其移动+攻击动作，THEN `unit.has_acted_this_turn` 为 `true`。

**AC-TURN-005 — 最后一个单位行动后 Auto-Advance 触发（规则 3）** [Logic]
GIVEN 处于 `FACTION_PHASE_ACTIVE` 状态，活跃阵营恰好有一个存活单位的 `has_acted == false`，该阵营所有其他存活单位的 `has_acted == true`，WHEN 该最后一个未行动单位设置 `has_acted = true`，THEN Turn System 转换到 `FACTION_PHASE_ENDING`。

**AC-TURN-006 — 空真 Auto-Advance（规则 3）** [Logic]
GIVEN 处于 `FACTION_PHASE_ACTIVE` 状态，活跃阵营存活单位数为零，WHEN 阶段开始（`faction_activated` 发射后立即），THEN Turn System 无需任何玩家输入即转换到 `FACTION_PHASE_ENDING`。

**AC-TURN-007 — 手动 End Turn 放弃剩余行动（规则 4）** [Logic]
GIVEN 处于 `FACTION_PHASE_ACTIVE` 状态，3 个 PLAYER 单位存活且仅 1 个已行动，WHEN 调用 `end_current_faction_turn()`，THEN 阶段转换到 `FACTION_PHASE_ENDING`；2 个未行动单位本阶段无法行动。

**AC-TURN-008 — End Turn 重入守卫（规则 4）** [Logic]
GIVEN Turn System 处于 `FACTION_PHASE_ENDING` 状态，WHEN 调用 `end_current_faction_turn()`，THEN 调用被静默忽略；不发生状态变更，不产生错误。

**AC-TURN-009 — Turn Config 默认值（规则 5）** [Integration]
GIVEN 一个 `TurnConfig.tres` 资源，`turn_cap = 30`（默认），WHEN `start_match()` 加载配置，THEN `turn_cap` 为 `30`。

**AC-TURN-010 — Turn Cap 范围验证（规则 5）** [Logic]
GIVEN 一个 `TurnConfig.tres` 资源，`turn_cap` 设置为 [1, 99] 之外的值（如 0 或 100），WHEN 资源被加载，THEN 断言失败，消息中包含文件名、无效值和允许范围；比赛不启动。

**AC-TURN-011 — 仅在 ENEMY 阶段后递增回合（规则 6）** [Logic]
GIVEN 比赛 `turn_number = 1`，WHEN PLAYER 阶段结束且 `FACTION_PHASE_ENDING` 处理，THEN `turn_number` 保持 `1`（不递增）。

**AC-TURN-012 — 完整循环后回合递增（规则 6）** [Logic]
GIVEN 比赛 `turn_number = 1`，WHEN ENEMY 阶段结束且 `FACTION_PHASE_ENDING` 处理，THEN `turn_number` 变为 `2`。

**AC-TURN-013 — 死亡单位排除于 Auto-Advance 之外（规则 7）** [Logic]
GIVEN 处于 `FACTION_PHASE_ACTIVE` 状态，活跃阵营有 2 个存活单位（均未行动）和 1 个死亡单位，WHEN 一个存活单位行动（设置 `has_acted = true`），THEN auto-advance 不触发 —— 死亡单位不计入，仍有 1 个存活未行动单位。

**AC-TURN-014 — 歼灭立即结束比赛（规则 7）** [Logic]
GIVEN 处于 `FACTION_PHASE_ACTIVE` 状态，ENEMY 阵营恰好有 1 个存活单位，PLAYER 单位仍有未行动单位，WHEN 一个 PLAYER 单位击杀该最后一个 ENEMY 单位（`unit_died` 信号触发），THEN 比赛直接转换到 `MATCH_ENDED`，`reason = "elimination"`；剩余未行动 PLAYER 单位被跳过。

**AC-TURN-015 — 比赛以 PLAYER 先手开始，turn_number=1（规则 8）** [Logic]
GIVEN 一个有效的 `TurnManager` 实例，所有依赖已注入，WHEN 调用 `start_match(units)`，THEN `active_faction == PLAYER` 且 `turn_number == 1`。

**AC-TURN-016 — 架构：RefCounted，DI，无 Autoload（规则 9）** [Logic/Structural]
GIVEN Turn System 实现，WHEN 代码审查检查 `TurnManager`，THEN `TurnManager` 继承 `RefCounted`（而非 `Node`），不使用 `Autoload` 或 `SignalBus`，通过构造函数或方法注入接收所有依赖（`units`、`turn_config`、`victory_checker`）。由代码审查和静态分析验证，非自动化测试执行。

### B. Formulas

**AC-TURN-017 — F1: 全部已行动 → Auto-Advance True** [Logic]
GIVEN 3 个 PLAYER 单位，全部存活，全部 `has_acted == true`；`active_faction = PLAYER`，WHEN 评估 auto-advance 条件，THEN `auto_advance == true`。

**AC-TURN-018 — F1: 一个未行动 → Auto-Advance False** [Logic]
GIVEN 3 个 PLAYER 单位，全部存活，2 个 `has_acted == true`，1 个 `has_acted == false`；`active_faction = PLAYER`，WHEN 评估 auto-advance 条件，THEN `auto_advance == false`。

**AC-TURN-019 — F1: 空真 — 活跃阵营零存活** [Logic]
GIVEN 0 个存活 PLAYER 单位；`active_faction = PLAYER`，WHEN 评估 auto-advance 条件，THEN `auto_advance == true`（空真："所有存活单位均已行动"的条件平凡满足）。

**AC-TURN-020 — F2: PLAYER 阶段结束不递增** [Logic]
GIVEN `turn_number = 5`，`turn_cap = 30`，`ending_faction = PLAYER`，WHEN 评估 F2，THEN `new_turn_number = 5`，`turn_cap_reached = false`。

**AC-TURN-021 — F2: ENEMY 阶段结束递增** [Logic]
GIVEN `turn_number = 5`，`turn_cap = 30`，`ending_faction = ENEMY`，WHEN 评估 F2，THEN `new_turn_number = 6`，`turn_cap_reached = false`。

**AC-TURN-022 — F2: 回合上限达到** [Logic]
GIVEN `turn_number = 30`，`turn_cap = 30`，`ending_faction = ENEMY`，WHEN 评估 F2，THEN `new_turn_number = 31`，`turn_cap_reached = true`。

**AC-TURN-023 — F3: PLAYER → ENEMY** [Logic]
GIVEN `active_faction = PLAYER`，WHEN 评估 F3，THEN `next_faction = ENEMY`。

**AC-TURN-024 — F3: ENEMY → PLAYER** [Logic]
GIVEN `active_faction = ENEMY`，WHEN 评估 F3，THEN `next_faction = PLAYER`。

**AC-TURN-025 — F4: 歼灭结束比赛** [Logic]
GIVEN `alive_count(PLAYER) = 3`，`alive_count(ENEMY) = 0`，WHEN 评估 F4，THEN `should_end_match = true`，`end_reason = "elimination"`。

**AC-TURN-026 — F4: 回合上限结束比赛** [Logic]
GIVEN `turn_cap_reached = true`，`alive_count(PLAYER) > 0`，`alive_count(ENEMY) > 0`，WHEN 评估 F4，THEN `should_end_match = true`，`end_reason = "turn_cap"`。

**AC-TURN-027 — F4: 歼灭优先于回合上限** [Logic]
GIVEN `turn_cap_reached = true` 且 `faction_eliminated = true` 同时成立，WHEN FACTION_PHASE_ENDING 路由决策（步骤 5）被执行，THEN `end_reason = "elimination"`（歼灭优先于回合上限）。

**AC-TURN-028 — F4: 两条件均不满足 → 继续** [Logic]
GIVEN `turn_cap_reached = false`，`faction_eliminated = false`，WHEN 评估 F4，THEN `should_end_match = false`，路由继续到下一个 `FACTION_PHASE_ACTIVE`。

**AC-TURN-029 — F5: 存活计数 — 混合死亡/存活** [Logic]
GIVEN 3 个 PLAYER 单位：U1（存活），U2（死亡），U3（存活），WHEN 评估 `alive_count(PLAYER)`，THEN 结果为 `2`。

**AC-TURN-030 — F5: 存活计数 — 全部死亡** [Logic]
GIVEN 2 个 ENEMY 单位：全部死亡，WHEN 评估 `alive_count(ENEMY)`，THEN 结果为 `0` → 按 F4 触发 `faction_eliminated = true`。

**AC-TURN-031 — F5: 存活计数 — 阵营中零单位** [Logic]
GIVEN 比赛没有放置 ENEMY 单位（该阵营为空数组），WHEN 评估 `alive_count(ENEMY)`，THEN 结果为 `0`。

### C. 状态机转换

**AC-TURN-032 — 转换: MATCH_NOT_STARTED → FACTION_PHASE_ACTIVE** [Logic]
GIVEN `current_state = MATCH_NOT_STARTED`，WHEN 以有效输入调用 `start_match(units)`，THEN `current_state` 变为 `FACTION_PHASE_ACTIVE`，`active_faction = PLAYER`，`turn_number = 1`，信号 `match_started`、`turn_started(1)`、`faction_activated(PLAYER)` 按此顺序发射。

**AC-TURN-033 — 转换: FACTION_PHASE_ACTIVE → FACTION_PHASE_ENDING（auto-advance）** [Logic]
GIVEN `current_state = FACTION_PHASE_ACTIVE`，活跃阵营所有存活单位均已行动，WHEN 最后一个单位完成其行动，THEN `current_state` 转换到 `FACTION_PHASE_ENDING`，发射 `faction_phase_ended(active_faction)`。

**AC-TURN-034 — 转换: FACTION_PHASE_ACTIVE → FACTION_PHASE_ENDING（手动 end turn）** [Logic]
GIVEN `current_state = FACTION_PHASE_ACTIVE`，WHEN 调用 `end_current_faction_turn()`，THEN `current_state` 转换到 `FACTION_PHASE_ENDING`，发射 `faction_phase_ended(active_faction)`。

**AC-TURN-035 — 转换: FACTION_PHASE_ENDING → FACTION_PHASE_ACTIVE（下一阵营）** [Logic]
GIVEN `current_state = FACTION_PHASE_ENDING`，结束序列完成，无歼灭，回合上限未达到，WHEN 结束序列路由到"继续"，THEN `current_state` 变为 `FACTION_PHASE_ACTIVE`，`active_faction = next_faction`；发射 `faction_activated(next)`；若 `next == PLAYER`，同时发射 `turn_started(turn_number)`。

**AC-TURN-036 — 转换: FACTION_PHASE_ENDING → MATCH_ENDED（歼灭）** [Logic]
GIVEN `current_state = FACTION_PHASE_ENDING`，`faction_eliminated = true`，WHEN 结束序列到达步骤 5（路由），THEN `current_state` 变为 `MATCH_ENDED`；发射 `match_ended("elimination", winner)`。

**AC-TURN-037 — 转换: FACTION_PHASE_ENDING → MATCH_ENDED（回合上限）** [Logic]
GIVEN `current_state = FACTION_PHASE_ENDING`，`turn_cap_reached = true`，`faction_eliminated = false`，WHEN 结束序列到达步骤 5（路由），THEN `current_state` 变为 `MATCH_ENDED`；发射 `match_ended("turn_cap", winner)`。

**AC-TURN-038 — 终态: MATCH_ENDED 不接受任何转换** [Logic]
GIVEN `current_state = MATCH_ENDED`，WHEN 任何会改变状态的方法被调用（`end_current_faction_turn()`，或死亡信号到达，或单位完成行动），THEN 不发生状态变更；所有此类调用被静默忽略。

### D. 信号发射

**AC-TURN-039 — match_started 信号** [Logic]
GIVEN 一个 `TurnManager` 实例，信号观察者已连接到 `match_started`，WHEN 调用 `start_match(units)`，THEN `match_started` 恰好发射一次，在所有单位上调用 `reset_action_state()` 之后。

**AC-TURN-040 — turn_started 信号** [Logic]
GIVEN 比赛进行中，`turn_number = N`，WHEN 新的 PLAYER 阶段开始（从 FACTION_PHASE_ENDING 转换），THEN `turn_started(N)` 以当前 `turn_number` 值发射。

**AC-TURN-041 — faction_activated 信号** [Logic]
GIVEN 某阵营阶段即将开始，WHEN 到 `FACTION_PHASE_ACTIVE` 的转换完成，THEN `faction_activated(faction)` 以进入方阵营的正确 `Faction.Type` 值发射。

**AC-TURN-042 — faction_phase_ended 信号** [Logic]
GIVEN 某阵营阶段正在结束（auto-advance 或手动 end turn），WHEN 到 `FACTION_PHASE_ENDING` 的转换发生，THEN `faction_phase_ended(faction)` 以阶段刚刚结束的阵营发射。

**AC-TURN-043 — match_ended 信号（歼灭）** [Logic]
GIVEN 比赛所有 ENEMY 单位已死亡，WHEN 比赛转换到 `MATCH_ENDED`，THEN 发射 `match_ended("elimination", PLAYER)`。

**AC-TURN-044 — match_ended 信号（回合上限）** [Logic]
GIVEN 比赛 `turn_cap_reached = true` 且双方阵营均有存活单位，WHEN 比赛转换到 `MATCH_ENDED`，THEN 发射 `match_ended("turn_cap", winner)`，其中 `winner` 由 `VictoryChecker` 判定。

**AC-TURN-045 — match_ended 信号（平局）** [Logic]
GIVEN 双方阵营同时被歼灭（互相毁灭），WHEN 比赛转换到 `MATCH_ENDED`，THEN 发射 `match_ended("elimination", Faction.Type.NONE)`。

### E. 关键边界情况

**AC-TURN-046 — 边界: 空单位数组 → 立即平局** [Logic]
GIVEN `start_match()` 以空单位数组 `[]` 调用，WHEN 比赛初始化，THEN 比赛在同一帧内开始和结束：PLAYER 阶段 auto-advance（空真），FACTION_PHASE_ENDING 检测到双方阵营被歼灭，发射 MATCH_ENDED，`winner = NONE`，`reason = "elimination"`。

**AC-TURN-047 — 边界: start_match 二次调用被拒绝** [Logic]
GIVEN `start_match()` 已被调用且 `current_state != MATCH_NOT_STARTED`，WHEN `start_match()` 被第二次调用，THEN 调用 `push_error()`，消息指示比赛已在进行中；不发生状态变更；现有比赛状态被保留。

**AC-TURN-048 — 边界: TurnConfig 缺失 → 断言失败** [Logic]
GIVEN `turn_config` 为 `null`（资源加载失败或未注入），WHEN 调用 `start_match()`，THEN 断言失败，消息中包含预期的文件路径；比赛不启动。

**AC-TURN-049 — 边界: VictoryChecker Null → 断言失败** [Logic]
GIVEN `victory_checker` 为 `null`（未注入），WHEN 调用 `start_match()`，THEN 断言失败；比赛不启动。

**AC-TURN-050 — 边界: unit_died 在 FACTION_PHASE_ENDING 期间被忽略** [Logic/Instrumented]
GIVEN `current_state = FACTION_PHASE_ENDING`（转换中），WHEN `unit_died` 信号触发（理论情况 —— MVP 阶段无延迟伤害时不可达），THEN 信号处理函数守卫并忽略该死亡；不重新评估歼灭；进行中的转换正常完成。MVP 阶段需要 instrumentation 来测试。

**AC-TURN-051 — 边界: 最后未行动单位歼灭阵营 → 立即结束** [Logic]
GIVEN PLAYER 阶段活跃；ENEMY 有 1 个存活单位；该单位是唯一未行动 PLAYER 单位的攻击目标，WHEN PLAYER 单位攻击并击杀最后一个 ENEMY 单位，THEN `unit_died` 处理函数检测到 `faction_eliminated = true` 并立即路由到 `MATCH_ENDED`；auto-advance 被跳过；任何剩余未行动 PLAYER 单位无法行动。

**AC-TURN-052 — 边界: turn_cap_reached 和 faction_eliminated 同时成立 → 歼灭胜出** [Logic]
GIVEN FACTION_PHASE_ENDING 序列，ending_faction = ENEMY，turn_number = 30，turn_cap = 30，且最终 ENEMY 击杀也歼灭了 ENEMY 阵营，WHEN 结束序列评估步骤 4（胜利检查）和步骤 5（路由），THEN `end_reason = "elimination"`（而非 "turn_cap"）；歼灭优先被强制执行。

**AC-TURN-053 — 边界: 延迟信号连接 — 消费者轮询状态** [Integration]
GIVEN 一个 UI 元素在 `start_match()` 已触发 `match_started` 和 `faction_activated(PLAYER)` 之后被实例化，WHEN 延迟连接的消费者读取 `TurnManager.current_state`、`active_faction` 和 `turn_number`，THEN 这些只读属性返回正确的当前值（分别为 `FACTION_PHASE_ACTIVE`、`PLAYER`、`1`），使消费者无需接收初始信号即可正确初始化其显示。

**AC-TURN-054 — 边界: turn_cap = 1，一个阵营为空 → 立即结束** [Logic]
GIVEN `turn_cap = 1`，PLAYER 有 0 个单位，ENEMY 有 1 个单位，WHEN 调用 `start_match()`，THEN PLAYER 阶段 auto-advance（空真）；FACTION_PHASE_ENDING 检测到 `faction_eliminated = true`；发射 MATCH_ENDED，`reason = "elimination"`；`turn_number` 永不超过 1；回合上限从未达到。

**AC-TURN-055 — 边界: 单位迭代上的 is_instance_valid 守卫** [Logic]
GIVEN `_all_units` 中的某单位引用已被 `queue_free()` 且 `unit_died` 信号未触发（被绕过的信号路径），WHEN Turn System 迭代 `_all_units` 进行 auto-advance 或重置，THEN 已释放单位被跳过（通过 `is_instance_valid()` 检查）；不发生崩溃或空引用错误。

### F. 不可测试 / 需要 Instrumentation

**AC-TURN-056 — 不可测试: 外部 has_acted 写入（数据完整性边界情况）** [UNTESTABLE by design]
GIVEN 外部代码绕过正常的移动+攻击完成流程直接设置 `unit.has_acted_this_turn = true`，WHEN auto-advance 条件被评估，THEN 系统读取外部设置的值，可能在非预期时机触发 auto-advance。此边界情况明确不在运行时守卫 —— 通过代码审查中的 Forbidden Patterns 强制执行。建议：在 `.claude/docs/technical-preferences.md` Forbidden Patterns 中添加："外部代码不得写入 `unit.has_acted_this_turn` —— 只有 Turn System（重置）和 Movement/Attack 完成（设为 true）可以修改此字段。"

**AC-TURN-057 — 需要 Instrumentation: 信号处理函数中的 End Turn（重入守卫）** [Logic/Instrumented]
GIVEN 连接到 `faction_phase_ended` 的信号处理函数调用 `end_current_faction_turn()`，WHEN `faction_phase_ended` 在正常阶段转换期间被发射，THEN 对 `end_current_faction_turn()` 的重入调用被静默忽略；不发生无限递归。需要测试故意创建重入条件（正常 MVP 游玩中不可达）。

### 汇总

| 分类 | 数量 | Logic | Integration | Untestable/Instrumented |
|------|------|-------|-------------|------------------------|
| Core Rules（1-8） | 16 | 10 | 4 | 2 |
| Formulas（F1-F5） | 15 | 15 | 0 | 0 |
| 状态转换 | 7 | 7 | 0 | 0 |
| 信号发射 | 7 | 7 | 0 | 0 |
| 边界情况 | 12 | 9 | 1 | 2 |
| **合计** | **57** | **48** | **5** | **4** |

**Gate 汇总:**
- **BLOCKING（Logic）**：48 条标准 —— 每条需要在 `tests/unit/turn/` 中有自动化单元测试
- **BLOCKING（Integration）**：5 条标准 —— 每条需要集成测试或文档化的 playtest
- **UNTESTABLE / INSTRUMENTED**：上述标记的 4 条标准

## Open Questions

- **OQ1 — turn_cap 默认值**：按 game-concept Q1 决议设为 30（从第一天起即数据驱动）。Tuning Knobs 列出默认 30，安全范围 [1, 99]。在锁定此值之前是否有异议？ → 已解决：确认 30，通过 TurnConfig.tres 数据驱动。
- **OQ2 — AIController 接口**：`take_turn(units, world_state) -> ActionList` 在本 GDD 中定义为暂定接口。确切的 `ActionList` 和 `WorldState` 类型将在 AI GDD（Order 7）中最终确定。Turn System 只需要调用签名，不需要实现。
- **OQ3 — VictoryChecker 契约**：`determine_winner(units, turn_number, turn_cap) -> {winner, reason}` 在本 GDD 中定义为 Turn System 的依赖。Victory GDD（Order 6）必须确认此确切签名。在 Victory GDD 编写之前为暂定。
- **OQ4 — TurnManager 作为 RefCounted 配合 DI**：架构决策（规则 9）。是否应在实现前在 ADR 中正式化？ → 推迟到 GDD 审查后的 `/architecture-decision turn-system`。
