# AI / AIController

> **Status**: In Design
> **Author**: binlee1990 + Claude
> **Last Updated**: 2026-04-29
> **Implements Pillar**: Pillar 2 — System Orthogonality (AIController interface admits multiple behaviors without Turn System edits)

## Overview

AI / AIController 是 SRPG 骨架中的**敌方行为驱动器**：它定义了一个可插拔的控制器接口 —— `AIController.take_turn(units, world_state) -> ActionList` —— Turn System 在每个 ENEMY 阶段调用此接口，AI 返回一份动作列表（移动目标 + 攻击目标），Turn System 持有执行权。MVP 仅交付 `NullAI` 实现（空动作列表，因为热座模式下玩家手动控制双方），但接口本身的设计目标是**容纳至少两种互不相同的 AI 行为而不修改 Turn System 的任何代码**。NullAI 证明接口的"零行为"端；Tier 2 的 BasicAI（最近目标启发式）证明接口的"有行为"端。没有 AI 接口，ENEMY 阵营在热座之外的任何场景中都将永久冻结 —— 棋盘上只有棋子，没有对手。AI 让棋盘"活过来"：当玩家结束回合，敌方单位开始思考、移动、攻击 —— 即使 MVP 的思考结果是"什么都不做"，接口的空位本身就是承诺。

## Player Fantasy

AI 系统的幻想是**通过透明性获得对局面的掌控**。AI 没有隐藏权重、没有随机数、没有模拟的"个性"。AI 就是一条规则。

MVP 的规则是"什么也不做"——你已经知道敌人会干什么（不会动）。Tier 2 的规则是"移动到最近的敌方单位，如果射程内有目标则攻击"——你可以在结束自己回合之前数格子，精确预判哪个己方单位下回合会被打。AI 是敌人，但它是一个**明牌**的敌人。

这与 Attack GDD 的确定性承诺对齐：你的回合是**兑现**，敌人的回合是**确认**。`damage = max(ATK - DEF, 1)` 的旁边可以写 `target = nearest(PLAYER_units)`。每一条规则都是透明的。

**锚定时刻**：结束你的回合之前，心算出 AI 下回合会锁定的目标；回合切换，AI 精确地走向并攻击你预测的那个单位。你**知道**它会这么做。它做到了。满足感不来自意外，来自确认。

NullAI 不是"AI 还没做"——它是规则谱系上最简的那条。什么也不做，和"打最近的"，是同一种东西：一条可被读懂的规则。你战胜 AI 的方式不是猜它的行为，而是比它更理解它自己的规则。

## Detailed Design

### Core Rules

1. **AIController 接口定义**: `AIController` 是一个 `@abstract` `RefCounted` 基类，定义单一入口点：

```gdscript
@abstract
class_name AIController extends RefCounted

@abstract
func take_turn(units: Array[Unit], world_state: WorldState) -> ActionList:
    assert(false, "AIController.take_turn() must be overridden")
    return ActionList.new()
```

`@abstract` 装饰器（Godot 4.5+）阻止在基类上调用 `.new()` —— 只能实例化子类（`NullAI`、`BasicAI`）。子类必须覆盖 `take_turn()`，否则编辑器标记错误。

2. **take_turn 契约**: Turn System 在每个 ENEMY 阶段调用 `take_turn(units, world_state)`。`units` 是 **ENEMY 阵营所有 alive 且未行动** 的单位列表（由 Turn 在调用前过滤）。`world_state` 是 AI 决策所需的全部只读数据的快照。AI 返回一个 `ActionList` —— 一组按执行顺序排列的 `ActionPlan`。AI **不修改**任何真实游戏状态 —— 它只返回数据。Turn System 持有执行权。

3. **ActionPlan 数据结构**: `ActionPlan` 是 `RefCounted`，描述一个单位的完整 phase 动作：

| 字段 | 类型 | 描述 |
|------|------|------|
| `unit` | `Unit` | 执行此动作的单位（必填，非 null） |
| `type` | `ActionType` enum | `MOVE_AND_ATTACK` / `MOVE_ONLY` / `ATTACK_ONLY` / `WAIT` |
| `move_target` | `Vector2i` | 移动目标坐标。`MOVE_ONLY` 和 `MOVE_AND_ATTACK` 时必填；`ATTACK_ONLY` 和 `WAIT` 时等于 `unit.grid_position` |
| `attack_target` | `Unit` | 攻击目标。`MOVE_AND_ATTACK` 和 `ATTACK_ONLY` 时必填（非 null）；`MOVE_ONLY` 和 `WAIT` 时为 `null` |

四种 ActionType：
- `MOVE_AND_ATTACK`: 移动到 `move_target`，然后攻击 `attack_target`
- `MOVE_ONLY`: 移动到 `move_target`，跳过攻击（`has_acted` 仍消耗）
- `ATTACK_ONLY`: 原地攻击 `attack_target`（`move_target == unit.grid_position`）
- `WAIT`: 跳过整个 phase（`move_target == unit.grid_position`，`attack_target == null`）

4. **ActionList 数据结构**: `ActionList` 是 `RefCounted`，包装 `Array[ActionPlan]`。暴露方法：
- `add(action: ActionPlan) -> void`
- `get_actions() -> Array[ActionPlan]`（返回防御性拷贝）
- `is_empty() -> bool`
- `size() -> int`

ActionList 中 `ActionPlan` 的顺序 = Turn System 的执行顺序。AI 负责编排：如果先移动单位 A 再移动单位 B 会产生占用冲突，AI 必须在返回前在内部模拟中解决。

5. **WorldState 数据结构**: `WorldState` 是 `RefCounted`，为 AI 提供决策所需的全部只读数据：

| 字段 | 类型 | 描述 |
|------|------|------|
| `all_units` | `Array[Unit]` | 棋盘上所有 alive 单位（双方阵营）。只读引用 —— AI 不修改 Unit 状态 |
| `map` | `Map` | 指向真实 Map 的只读引用 —— 用于 `get_neighbors()`、`is_walkable()`、`get_unit_at()` |
| `_occupancy_snapshot` | `Dictionary[Vector2i, Unit]` | 内部占用快照。AI 在规划时修改此快照（模拟移动结果），不写入真实 Map |

WorldState 提供 `clone() -> WorldState` 方法（深度拷贝占用快照），用于 AI 内部的分支规划 —— 例如比较"单位 A 先动 vs 单位 B 先动"两种方案。

6. **NullAI 规范**: `NullAI` 继承 `AIController`。`take_turn()` 始终返回空 `ActionList`（`is_empty() == true`）。

```gdscript
class_name NullAI extends AIController

func take_turn(units: Array[Unit], world_state: WorldState) -> ActionList:
    return ActionList.new()
```

Turn System 收到空 ActionList 时：所有 ENEMY 单位的 `has_acted_this_turn` 仍为 `false`（Turn 不修改未出现在 ActionList 中的单位）。热座模式下，Input 系统消费 `faction_activated(ENEMY)` 信号，玩家手动操作敌方单位 —— NullAI 的职责是"什么都不做"，Turn 仅提供一个空 ActionList 作为形式上的 AI 响应。

7. **执行模型**: Turn System 遍历 ActionList，对每个 `ActionPlan` 执行：

```
1. 验证 unit.has_acted_this_turn == false 且 unit.is_alive == true 且 unit.faction == active_faction（否则跳过）
2. 若 move_target != unit.grid_position：调用 Map.move_unit(unit, unit.grid_position, move_target)
   - 失败（瓦片占用/不可通行）→ push_warning，跳过攻击，设置 has_acted = true，continue
3. 若 attack_target != null 且 attack_target.is_alive：调用 AttackResolver.execute_attack(unit, attack_target)
   - AttackResult.INVALID（同阵营/已死亡/超出射程）→ push_warning
4. 设置 unit.has_acted_this_turn = true，unit.action_state = ACTED
5. 重新评估 auto-advance 条件（Turn GDD Rule 3）—— 若所有 ENEMY 单位已行动，提前退出循环
```

执行是**顺序的、同步的**。动作 N+1 在动作 N 执行后的更新状态上运行。若动作 N 击杀了一个单位，该死亡会影响动作 N+1 的结果（例如该单位不再作为目标）。

8. **AI 一致性责任**: AI 负责在返回 ActionList 前验证其计划的内部一致性。具体而言：
- 同一个单位在 ActionList 中最多出现一次
- 多个单位不能移动到同一瓦片（AI 应在 WorldState 模拟中检测）
- `attack_target` 必须是敌对阵营的 alive 单位
- `move_target` 必须在 `unit.mov` 的 BFS 范围内
- 每个 `ActionPlan.unit` 必须属于 ENEMY 阵营且 `has_acted == false`

若 AI 返回不一致的 ActionList，Turn System 的逐项验证（Rule 7）会在执行时逐一拒绝无效项 —— 不会崩溃，但会消耗 `has_acted`。AI 的行为是"best effort"；Turn System 是安全网。

9. **AIController 定位**: AIController 是纯函数对象 —— 无内部状态、无信号、无回调。不持有 Map/Unit 引用超过 `take_turn()` 调用生命周期。遵循项目既有的 `RefCounted + DI` 模式（对齐 `VictoryChecker`、`AttackResolver`、`MovementResolver`）。由 Game 场景（composition root）创建，依赖注入到 `TurnManager`。

10. **BasicAI 行为规约（Tier 2，但接口必须容纳）**: 为证明 AIController 接口的正确性，此处定义 BasicAI 的预期行为（不实现，仅作接口验证）：

> 对于 `units` 中的每个单位（按任意顺序）：
> 1. 调用 `AttackRangeResolver.get_valid_targets(unit, map)` —— 若结果非空，选择列表中的第一个（最近，同距离时最低 HP） → 生成 `ATTACK_ONLY` ActionPlan
> 2. 若无直接攻击目标：调用 `MovementResolver.compute_reachable(unit, map)` 获取可达瓦片
> 3. 对每个可达瓦片按距离排序，找到最近的一个瓦片，使得该瓦片在 `unit.rng` 范围内有至少一个敌方单位 → 生成 `MOVE_AND_ATTACK` ActionPlan（目标为该敌方单位）
> 4. 若无可达瓦片满足攻击条件：生成 `MOVE_ONLY` ActionPlan，向最近敌方单位方向移动
> 5. 若无可移动瓦片：生成 `WAIT` ActionPlan

唯一允许此行为规约"存在"的理由：**证明 AIController 接口确实容纳了 NullAI 和 BasicAI 两种互不相同的实现，且 Turn System 无需任何修改。** BasicAI 的完整 GDD 属于 Tier 2。

### States and Transitions

AIController 本身**无状态、无状态机**。它是纯函数 —— `take_turn()` 每次调用独立，相同输入产生相同输出。

AI 与 Turn System 状态机的交互是**间接的**：
- Turn System 在 `FACTION_PHASE_ACTIVE` 状态中，`active_faction == ENEMY` 时调用 `take_turn()`
- AI 返回 ActionList 后，Turn System 在 `FACTION_PHASE_ACTIVE` 中逐项执行动作
- 执行完成后 auto-advance 触发 `FACTION_PHASE_ENDING` → 下一状态

AI 不感知 Turn System 的 `current_state` 枚举。它仅响应 `take_turn()` 调用并返回数据。

### Interactions with Other Systems

| System | Direction | Data Flow | Interface |
|--------|-----------|-----------|-----------|
| **Turn System** | Upstream (caller) | Turn 在 ENEMY 阶段调用 `take_turn()` | 传入 `units: Array[Unit]`（ENEMY alive 未行动单位）+ `world_state: WorldState`；返回 `ActionList` |
| **Turn System** | Downstream (via Turn) | Turn 遍历 ActionList 执行动作 | Turn 调用 `Map.move_unit()` 和 `AttackResolver.execute_attack()` —— AI 不直接调用这些 |
| **Map** | Upstream (reads via WorldState) | AI 在 WorldState 中读取 Map 拓扑 | `map.get_neighbors(coord)`、`map.is_walkable(coord)`、`map.get_unit_at(coord)` —— 用于 BFS 和占用查询 |
| **Unit** | Upstream (reads) | AI 读取单位属性做决策 | `unit.faction`、`unit.is_alive`、`unit.grid_position`、`unit.mov`、`unit.rng`、`unit.atk`、`unit.def`、`unit.hp` —— 只读，AI 不写 |
| **Movement** | Upstream (reads, Tier 2) | BasicAI 调用 MovementResolver 计算可达瓦片 | `MovementResolver.compute_reachable(unit, map) -> MovementResult` —— 纯查询，无副作用 |
| **Attack** | Upstream (reads, Tier 2) | BasicAI 调用 AttackRangeResolver 获取可攻击目标 | `AttackRangeResolver.get_valid_targets(unit, map) -> Array[Unit]` —— 纯查询 |
| **UI / Input** | Indirect (MVP) | NullAI 返回空 ActionList 时，UI/Input 消费 `faction_activated(ENEMY)` 实现热座 | AI 不直接与 UI/Input 交互 |

## Formulas

> AI 系统主要消费来自其他系统的数学公式：Attack F1（`max(atk-def, 1)`）、Movement F1（BFS 可达集）、Movement F2（曼哈顿距离）、Turn F1（auto-advance 条件）。AI 自身的"公式"是逻辑谓词 —— 描述 ActionList 必须满足什么条件。以下使用与 Turn GDD F1 一致的谓词风格。

### F1: ActionList 一致性谓词

`valid_action_list` 公式定义如下：

`valid_action_list(plans, units, world_state) = R1 ∧ R2 ∧ R3 ∧ R4 ∧ R5 ∧ R6`

| 子规则 | 谓词 | 含义 |
|--------|------|------|
| **R1** | `∀ p ∈ plans: p.unit ∈ units` | 每个 ActionPlan 引用的 unit 必须是 Turn 传入的 ENEMY 单位 |
| **R2** | `∀ i ≠ j: plans[i].unit ≠ plans[j].unit` | 同一单位最多出现一次 —— 无重复计划 |
| **R3** | `∀ p where p.attack_target ≠ null: p.attack_target.faction ≠ p.unit.faction ∧ p.attack_target.is_alive` | 攻击目标必须是敌对阵营的 alive 单位 |
| **R4** | `∀ p: manhattan(p.unit.grid_position, p.move_target) ≤ p.unit.mov` | 移动目标必须在 unit.mov 的曼哈顿距离内（必要但不充分 —— BFS 完全验证是 AI 内部责任） |
| **R5** | `∀ i ≠ j where plans[i].move_target ≠ plans[i].unit.grid_position: plans[i].move_target ≠ plans[j].move_target` | 两个单位不能移动到同一瓦片（排除 skip-move，因为 unit 的原地不动不冲突） |
| **R6** | `∀ p: p.type 对应的必填字段均已填充` | 字段完整性 —— 参见 Core Rule 3 中的 ActionPlan 字段表 |

**变量：**

| Variable | Symbol | Type | Range | Description |
|----------|--------|------|-------|-------------|
| Action 列表 | plans | Array[ActionPlan] | [0, N] | AI 返回的计划列表，N = alive ENEMY 单位数 |
| 己方单位集 | units | Array[Unit] | [0, N] | Turn 传入的 ENEMY alive 未行动单位 |
| World State | world_state | WorldState | — | AI 决策快照（含 Map 引用 + 占用快照） |
| 一致性结果 | result | bool | {true, false} | 所有子规则同时满足 |

**输出范围：** `true` 当所有 6 个子规则同时满足。`false` 当任一子规则被违反。

**极端行为：**
- `plans` 为空数组 `[]`（NullAI）：所有 ∀ 量化对空集为 vacuously true → `valid_action_list = true`。空 ActionList 始终一致 —— 正确行为。
- `units` 为空数组：AI 收到零单位时，`plans` 必须为 `[]`（R1：不存在 p.unit ∈ ∅ → 任何非空 plans 违反 R1）。
- 所有单位选择 skip-move（`WAIT`，`move_target == unit.grid_position`）：R5 视为不同坐标的不冲突（因为 R5 只检查 `move_target != unit.grid_position` 的情况）。一致。

**示例 1 (NullAI)：** `units = [E1, E2]`，`plans = []` → R1–R6 全部 vacuously true → `valid_action_list = true`。

**示例 2 (Valid BasicAI)：** `units = [E1]`，`plans = [ActionPlan(E1, MOVE_AND_ATTACK, (3,4), P1)]`，其中 `manhattan(E1.grid, (3,4)) ≤ E1.mov`，`P1.faction == PLAYER`，`P1.is_alive == true` → 所有子规则满足 → `valid_action_list = true`。

**示例 3 (Invalid — 同阵营目标)：** `plans = [ActionPlan(E1, ATTACK_ONLY, E1.grid, E2)]`，`E2.faction == ENEMY` → R3 失败（`attack_target.faction == p.unit.faction`）→ `valid_action_list = false`。

**实现说明：** 此谓词的核心子规则由 Turn System 在执行时逐项验证（Core Rule 7）。AI 在返回前应满足全部子规则；Turn 的验证是安全网而非主要执行者。

## Edge Cases

### 接口合约

- **If `take_turn()` is called with empty `units` array**: NullAI 返回空 ActionList。BasicAI 检测到空输入 → 返回空 ActionList。Turn 处理空列表（零次遍历），auto-advance 因 vacuous truth 触发。行为正确且一致 —— F1 的 extreme behavior 已覆盖。

- **If `take_turn()` is called with `world_state == null` or `world_state.map == null`**: NullAI 不读取参数 → 安全。BasicAI 调用 `MovementResolver.compute_reachable()` 或 `AttackRangeResolver.get_valid_targets()` 时遇到 null Map → 各系统按自身 GDD 约定返回空结果 → BasicAI 应降级为对每个单位生成 `WAIT`。BasicAI 实现中需在每个 `compute_reachable()` / `get_valid_targets()` 调用前断言或守卫 world_state 有效性。

- **If `take_turn()` 返回后、Turn 执行前，`units` 中的单位被外部修改**: MVP 的同步执行模型不可达（Turn 调用 take_turn() 后立即同步遍历 ActionList）。Turn 的 step 1 `is_alive` 和 `has_acted` 检查是安全网。

### 数据完整性

- **If `ActionPlan.unit` 为 null**: Turn Rule 7 step 1 访问 `unit.has_acted_this_turn` → GDScript null 引用崩溃。F1-R6 要求 unit 非 null，但 Turn 执行循环缺少 null 防御。→ Turn System 应在执行循环中添加 `unit != null` 守卫（或 AI GDD 记录：null unit 导致崩溃，AI 负责确保非 null）。

- **If `ActionPlan.type` 枚举值与 `move_target` / `attack_target` 不一致**（例如 `type == WAIT` 但 `attack_target` 非 null）: Turn 执行循环**不读取 type 字段** —— 行为完全由 `move_target != unit.grid_position` 和 `attack_target != null` 字段值决定。`type` 是纯咨询性标签（debug/日志用途）。AI 实现者必须理解：type 不影响执行，它是人类可读的意图声明。

- **If AI 返回的 ActionList 未覆盖 `units` 中的所有单位**（部分单位无计划）: 未出现在 ActionList 中的单位保持 `has_acted == false` → auto-advance 永不触发 → ENEMY 阶段卡死，需手动 End Turn 推进。AI 必须为每个传入单位生成恰好一个 ActionPlan（F1-R1 + R2）。

### WorldState 一致性

- **If AI 在传入的 WorldState 上直接模拟（而非 clone）**: WorldState 传入对象被污染 —— 后续使用者（或 Turn）看到错误的占用数据。Core Rule 5 要求 AI 不修改传入的 WorldState。若需模拟移动结果（BasicAI），必须在 `world_state.clone()` 的副本上操作。禁止直接修改传入的 WorldState 对象。

- **If `WorldState.clone()` 实现为浅拷贝**（克隆后的两个 WorldState 共享同一个 `_occupancy_snapshot` Dictionary）: 分支规划产生交叉污染 —— 修改分支 A 的快照会影响分支 B。`clone()` 必须深度拷贝 `_occupancy_snapshot`（`_occupancy_snapshot.duplicate()`）。

- **If AI 持有 WorldState 引用超过 `take_turn()` 调用生命周期**（存储在成员变量中供下次调用使用）: 违反 Core Rule 9（无状态）。下一次 `take_turn()` 基于过期数据决策 → 可能产生无效 ActionPlan。AI 子类禁止跨调用缓存状态。

### 执行失败

- **If Turn 拒绝了 ActionList 中的每一个动作**（所有移动/攻击均无效）: 每个动作执行后 `has_acted` 仍被置为 true（Core Rule 7）。所有 ENEMY 单位回合被消耗 → auto-advance 触发。敌方阵营的本回合被"浪费" —— 正确行为。AI 产生垃圾数据，Turn 保护了游戏状态，阵营付出了代价。

- **If Action N 的攻击击杀了 Action N+1 的 `attack_target`**: Turn step 3 检查目标存活 → 已死亡目标被跳过 → `push_warning` → `has_acted` 消耗。这是正常恢复路径，非 bug。AI 在规划时不模拟战斗结果（AI 模拟占用冲突，但不预估谁会被杀）—— Turn 的执行守卫兜底。

- **If Action N 移动到某瓦片后，Action N+1 恰好要移动到同一瓦片**: 若 AI 在 WorldState 模拟中正确更新了占用快照，此冲突应在 AI 内部被检测和解决（F1-R5）。若 AI 未模拟内部占用顺序，`Map.move_unit()` 拒绝冲突移动 → `push_warning` → `has_acted` 消耗。安全网生效但体验差。

### NullAI 专属

- **If NullAI 在非热座模式中被使用**（即 ENEMY 阶段无人类玩家操作）: NullAI 返回空 ActionList → 所有 ENEMY 单位保持 `has_acted == false` → auto-advance 永不触发 → 比赛卡死在 ENEMY 阶段。系统应在游戏模式配置层检测：如果 `mode != hotseat AND ai == NullAI`，发出警告或阻止启动。这是配置校验的职责，非 AI 运行时检测。

### AIController 生命周期

- **If 子类未覆盖 `take_turn()`**（`@abstract` 保护被绕过）: 基类的 `assert(false)` 在 debug 构建中触发崩溃。Release 构建中（断言禁用）返回空 ActionList。`@abstract` 是编辑器级保护（Godot 4.5+），运行时不强制 —— debug assert 是第二道防线。

- **If `take_turn()` 内部抛出异常**（例如 BasicAI 中 MovementResolver 因异常状态崩溃）: Turn 的执行流程无 try-catch —— 异常向上传播可能导致比赛状态损坏。→ Turn System 应在调用 `take_turn()` 外包裹 try-catch，捕获异常后为所有未行动 ENEMY 单位生成 `WAIT` ActionPlan 作为兜底。

### Turn 纵深防御缺口

- **If AI 错误地将 PLAYER 单位放入 ActionList**: AI GDD R1 要求 `unit ∈ units`（Turn 传入的是 ENEMY 单位）。Turn 的执行循环 step 1 已增加 `unit.faction == active_faction` 守卫（2026-04-30 修复 —— `/review-all-gdds` 阻塞项）。若此缺口被绕过，Turn 会在 ENEMY 阶段执行 PLAYER 单位的动作 → 纵深防御守卫拒绝执行。

### BasicAI 预留 (Tier 2)

- **If BasicAI 的最近目标选择遇到距离和 HP 均相同的多个敌人**: `AttackRangeResolver.get_valid_targets()` 的排序是 distance → HP，同分时由 `Array` 迭代顺序决定（非确定性）。Tier 2 BasicAI GDD 应添加第三级 tiebreaker（例如单位 ID 或棋盘坐标顺序）。

- **If BasicAI 的可达瓦片中没有能攻击到任何敌人的瓦片，且最近敌人被障碍物完全隔开**: "向最近敌方单位方向移动"在障碍物地图上有歧义 —— 最近曼哈顿距离 ≠ 最近可达距离。Tier 2 BasicAI GDD 应明确：选择"曼哈顿距离最小的可达瓦片"作为移动目标。

## Dependencies

### 上游依赖

| System | Type | Interface Consumed | Notes |
|--------|------|--------------------|-------|
| **Turn System** | Hard (caller) | 调用 `take_turn(units, world_state) -> ActionList`；遍历返回的 ActionList 并执行动作 | turn.md 已定义此接口（OQ2）。without Turn，AI 无调用入口 |
| **Unit** | Hard | `unit.faction`、`unit.is_alive`、`unit.grid_position`、`unit.mov`、`unit.rng`、`unit.atk`、`unit.def`、`unit.hp` —— 全部只读 | 接口由 Unit GDD 锁定。AI 不写 Unit 状态 |
| **Map** | Hard | `map.get_neighbors(coord)`、`map.is_walkable(coord)`、`map.get_unit_at(coord)` —— 通过 WorldState.map 访问，全部只读 | 接口由 Map GDD 锁定 |
| **Movement** | Hard (Tier 2) | `MovementResolver.compute_reachable(unit, map) -> MovementResult` —— 纯查询 | MVP NullAI 不调用；Tier 2 BasicAI 需要。接口由 Movement GDD 锁定 |
| **Attack** | Hard (Tier 2) | `AttackRangeResolver.get_valid_targets(unit, map) -> Array[Unit]`；`AttackResolver.resolve_damage(atk, def) -> int`（可选，用于模拟伤害评估）—— 全部纯查询 | MVP NullAI 不调用；Tier 2 BasicAI 需要。接口由 Attack GDD 锁定 |

### 下游依赖

| System | Type | Interface Exposed | Notes |
|--------|------|-------------------|-------|
| **Turn System** | Hard | `ActionList` 返回值 —— Turn 依赖其结构执行 ENEMY 阶段动作 | Turn 必须知道如何遍历 ActionList 和解释 ActionPlan 字段 |
| **BasicAI** (Tier 2) | Hard | `AIController` 基类 + `ActionPlan` / `ActionList` / `WorldState` 类型 | BasicAI 通过继承 AIController 实现新的行为。接口必须无需修改即容纳 |
| **UI / Input** | Indirect (MVP) | NullAI 返回空 ActionList 时，Input 消费 `faction_activated(ENEMY)` 实现热座 | AI 不直接与 UI/Input 交互 |

### 外部依赖

| Dependency | Type | Notes |
|------------|------|-------|
| `AIController` (RefCounted, @abstract) | Code | 基类定义在 `src/ai/ai_controller.gd`。由 Game 场景创建并 DI 注入到 TurnManager |
| `NullAI` (RefCounted) | Code | `src/ai/null_ai.gd`。继承 AIController。MVP 默认实现 |
| `ActionPlan` (RefCounted) | Code | `src/ai/action_plan.gd`。单个单位动作计划数据对象 |
| `ActionList` (RefCounted) | Code | `src/ai/action_list.gd`。包装 ActionPlan 数组 |
| `WorldState` (RefCounted) | Code | `src/ai/world_state.gd`。AI 决策快照 |
| `ActionType` enum | Code | `src/ai/action_type.gd`。MOVE_AND_ATTACK / MOVE_ONLY / ATTACK_ONLY / WAIT |
| `Faction.Type` enum | Code | 定义在 `src/core/faction.gd`（Unit GDD 所有）。AI 读取用于目标验证 |

## Tuning Knobs

AI 系统在 MVP 无可调数值参数。`AIController` 是纯接口 —— 行为变化通过替换实现类（`NullAI` → `BasicAI` → 自定义子类）完成，而非调整参数值。

| Knob | Location | Safe Range | Notes |
|------|----------|------------|-------|
| `ai_controller` (实现类引用) | Game 场景 / TurnManager DI | `NullAI` / `BasicAI` / 任何 AIController 子类 | 通过依赖注入替换 —— 切换 AI 行为无需修改 Turn 代码。MVP 固定为 `NullAI` |

**Tier 2 预留**: BasicAI 可引入以下可调参数（由 BasicAI GDD 在 Tier 2 定义）：
- 目标选择优先级权重（距离 vs HP 的排序偏好）
- 移动侵略性（偏好向敌方移动的距离阈值）

这些参数当前不属于 AI GDD 的范畴 —— AI GDD 只定义接口，不定义具体行为的参数空间。

## Visual/Audio Requirements

N/A — AI 是纯逻辑系统，不拥有渲染节点，不产生视觉或音频输出。`faction_activated(ENEMY)` 信号是 UI 用于触发敌方回合视觉提示的钩子（由 Turn System 发出，AI 不参与）。BasicAI（Tier 2）不引入新的视觉/音频需求 —— 其单位移动和攻击的视觉效果由 Movement 和 Attack 系统已有的视觉规范覆盖。

## UI Requirements

AI 系统不直接渲染 UI。NullAI 返回空 ActionList 时，ENEMY 阶段的交互完全由 UI / Input 系统通过消费 `faction_activated(ENEMY)` 信号实现（热座模式）。Tier 2 BasicAI 不引入新的 UI 元素 —— 敌方单位自动行动时，移动范围和攻击目标的视觉高亮由 Movement 和 Attack 系统已有的 UI 规范覆盖。

AI 的 debug 透明度（Optional，Tier 2+）：若未来需要可视化 AI 的决策过程（例如显示"此敌人下回合将攻击你的哪个单位"），应由 UI / Input 系统读取 `ActionList` 的内容并渲染相应覆盖层。AI GDD 不定义此 UI 行为。

## Acceptance Criteria

### A. 核心规则

**AC-AI-001 — AIController @abstract cannot instantiate** [Structural]
GIVEN AIController class with @abstract decorator in Godot 4.6 editor, WHEN any code attempts `AIController.new()`, THEN the editor raises an error. Only subclasses (NullAI, BasicAI) can be instantiated. Verified by manual editor inspection, not automated test.

**AC-AI-002 — NullAI.take_turn() returns empty ActionList** [Logic]
GIVEN a NullAI instance, any units array (empty or non-empty), any WorldState (valid or null), WHEN `take_turn(units, world_state)` is called, THEN returns ActionList with `is_empty() == true`, `size() == 0`, `get_actions()` returns `[]`.

**AC-AI-003 — ActionPlan field integrity (MOVE_AND_ATTACK)** [Logic]
GIVEN ActionPlan constructed with type=MOVE_AND_ATTACK, unit=E1, move_target=(3,4), attack_target=P1, WHEN fields are read, THEN unit==E1, type==MOVE_AND_ATTACK, move_target==(3,4), attack_target==P1.

**AC-AI-004 — ActionPlan field integrity (MOVE_ONLY)** [Logic]
GIVEN ActionPlan constructed with type=MOVE_ONLY, unit=E1, move_target=(3,4), attack_target=null, WHEN fields are read, THEN unit==E1, type==MOVE_ONLY, move_target==(3,4), attack_target==null.

**AC-AI-005 — ActionPlan field integrity (ATTACK_ONLY)** [Logic]
GIVEN ActionPlan constructed with type=ATTACK_ONLY, unit=E1, move_target==E1.grid_position, attack_target=P1, WHEN fields are read, THEN unit==E1, type==ATTACK_ONLY, move_target==E1.grid_position, attack_target==P1.

**AC-AI-006 — ActionPlan field integrity (WAIT)** [Logic]
GIVEN ActionPlan constructed with type=WAIT, unit=E1, WHEN fields are read, THEN move_target == E1.grid_position and attack_target == null.

**AC-AI-007 — ActionPlan null unit rejected** [Logic]
GIVEN ActionPlan construction attempt with unit=null, WHEN constructed, THEN an assertion fails with descriptive message naming the field. In release builds, ActionPlan is not added to any ActionList.

**AC-AI-008 — ActionList ordering preserved** [Logic]
GIVEN ActionList with 3 ActionPlans added [A, B, C] in that order, WHEN `get_actions()` is called, THEN returned array is [A, B, C] in insertion order.

**AC-AI-009 — ActionList.is_empty() on empty list** [Logic]
GIVEN a newly created ActionList, WHEN `is_empty()` is called, THEN returns `true`.

**AC-AI-010 — ActionList.get_actions() returns defensive copy** [Logic]
GIVEN ActionList with one ActionPlan, WHEN caller modifies the array returned by `get_actions()`, THEN ActionList's internal array is unchanged. Subsequent `get_actions()` returns the original unmodified array.

**AC-AI-011 — WorldState provides Map topology access** [Integration]
GIVEN WorldState initialized with a valid Map reference and units, WHEN `world_state.map.get_neighbors(coord)` or `world_state.map.is_walkable(coord)` is called, THEN returns the same results as calling Map directly.

**AC-AI-012 — WorldState.clone() produces independent occupancy snapshot** [Logic]
GIVEN WorldState with 3 units in _occupancy_snapshot: {(0,0):E1, (0,1):E2, (1,0):E3}, WHEN `clone()` is called, THEN clone._occupancy_snapshot contains exactly the same 3 entries. WHEN the clone's snapshot is modified (e.g., adding (0,2):E4), THEN the original WorldState's snapshot still has exactly 3 entries.

**AC-AI-013 — AI does not modify passed-in WorldState** [Logic]
GIVEN any AIController implementation (NullAI or compliant BasicAI), world_state with known all_units array and map reference, WHEN `take_turn()` completes and returns, THEN `world_state.all_units` and `world_state.map` are unchanged from before the call. Verified by comparing reference identity before/after.

**AC-AI-014 — Base AIController.take_turn() assert in debug** [Logic]
GIVEN a subclass that does NOT override take_turn() (or a direct AIController instance in release bypassing @abstract), WHEN `take_turn()` is called in debug build, THEN `assert(false)` fires with message "AIController.take_turn() must be overridden". In release build (assert disabled), returns empty ActionList.

**AC-AI-015 — AI does not cache state across take_turn() calls** [Logic]
GIVEN AIController implementation, 1st call: units=[E1], world_state_A with E1 at (0,0). 2nd call: units=[E2], world_state_B with E2 at (5,5). WHEN 2nd call returns, THEN the returned ActionList reflects E2's position (5,5), not E1's position (0,0). AI holds no mutable state across calls.

### B. AIController 接口验证

**AC-AI-016 — Interface admits NullAI** [Structural]
GIVEN src/ai/null_ai.gd, WHEN inspected, THEN NullAI extends AIController, overrides take_turn(), and does NOT import or reference Turn System (TurnManager), Movement, or Attack classes. Verified by import-grep, not automated test.

**AC-AI-017 — Interface admits BasicAI stub** [Structural]
GIVEN a BasicAI stub (extends AIController, overrides take_turn()), WHEN source is inspected, THEN BasicAI imports only: AIController, ActionPlan, ActionList, WorldState, MovementResolver, AttackRangeResolver. Does NOT import TurnManager. Verified by import-grep — proves the interface admits a non-trivial implementation without Turn System edits.

**AC-AI-018 — AIController has no scene tree dependencies** [Structural]
GIVEN AIController base class and NullAI source, WHEN inspected, THEN neither class contains `_ready()`, `_process()`, `@onready` vars, signal declarations, or `Node`/`Node2D` references. Both extend `RefCounted`. Verified by code review.

### C. 公式 F1 — 一致性谓词

**AC-AI-019 — F1-R1: Unit membership** [Logic]
GIVEN units=[E1, E2] (ENEMY, alive, unacted), ActionPlan for E1, WHEN R1 (∀ p: p.unit ∈ units) is evaluated, THEN `E1 ∈ [E1, E2]` → true. GIVEN ActionPlan for non-member unit P1, THEN `P1 ∉ [E1, E2]` → false.

**AC-AI-020 — F1-R2: No duplicate units** [Logic]
GIVEN ActionList with ActionPlan(E1) + ActionPlan(E1), WHEN R2 is evaluated (∀ i≠j: plans[i].unit ≠ plans[j].unit), THEN `plans[0].unit == plans[1].unit` → false. GIVEN ActionList with ActionPlan(E1) + ActionPlan(E2), THEN all unit pairs distinct → true.

**AC-AI-021 — F1-R3: Target faction + alive** [Logic]
GIVEN ActionPlan with attack_target=P1 (PLAYER, alive), unit=E1 (ENEMY), WHEN R3 is evaluated, THEN `P1.faction ≠ E1.faction ∧ P1.is_alive` → true. GIVEN attack_target=E2 (same faction), THEN `E2.faction == E1.faction` → false. GIVEN attack_target=null (skip attack), THEN R3 is vacuously true (∀ quantifier over empty condition set — no attack target to validate).

**AC-AI-022 — F1-R4: Move target within Manhattan distance** [Logic]
GIVEN unit at (0,0) with MOV=4, ActionPlan with move_target=(0,3), manhattan=3 ≤ 4, WHEN R4 is evaluated, THEN true. GIVEN move_target=(0,5), manhattan=5 > 4, THEN false.

**AC-AI-023 — F1-R5: No occupancy conflict** [Logic]
GIVEN two ActionPlans with move targets (3,4) and (5,6), both ≠ their units' grid_positions, WHEN R5 is evaluated, THEN `(3,4) ≠ (5,6)` → true. GIVEN both with move_target=(3,4), THEN conflict → false.

**AC-AI-024 — F1-R6: Type-to-fields completeness — all 4 types** [Logic]
GIVEN ActionPlan for each of the 4 ActionType values, WHEN R6 is evaluated per the field table in Core Rule 3, THEN:
- MOVE_AND_ATTACK: move_target ≠ unit.grid_position, attack_target ≠ null → true
- MOVE_ONLY: move_target ≠ unit.grid_position, attack_target == null → true
- ATTACK_ONLY: move_target == unit.grid_position, attack_target ≠ null → true
- WAIT: move_target == unit.grid_position, attack_target == null → true
Any type with incorrect field nullity → false.

**AC-AI-025 — F1: Empty ActionList is always valid** [Logic]
GIVEN empty ActionList (plans=[]), any units and world_state, WHEN F1 (R1∧R2∧R3∧R4∧R5∧R6) is evaluated, THEN all 6 sub-rules are vacuously true over empty plans array → result is `true`.

### D. 边角案例

**AC-AI-026 — Edge: take_turn with empty units** [Logic]
GIVEN NullAI (or any valid AI), units=[], any world_state, WHEN `take_turn(units, world_state)` is called, THEN returns ActionList with `is_empty() == true`. No crash, no exception.

**AC-AI-027 — Edge: take_turn with null WorldState** [Logic]
GIVEN NullAI, valid units, world_state=null, WHEN `take_turn(units, null)` is called, THEN returns empty ActionList. NullAI never accesses world_state — trivially safe. (Note: BasicAI must add null guard at start of take_turn() per Core Rule 10; this AC tests NullAI only.)

**AC-AI-028 — Edge: ActionList not covering all units** [Logic]
GIVEN units=[E1, E2, E3], ActionList with only 2 ActionPlans (for E1 and E2), WHEN `get_actions().size()` is compared to `len(units)`, THEN size() = 2 < 3 → AI violated F1-R1 (∀ p ∈ plans: p.unit ∈ units does not cover E3 — E3 has no plan). Partial coverage is a spec violation.

**AC-AI-029 — Edge: type field advisory — Turn ignores it** [Logic]
GIVEN ActionPlan with type=WAIT, move_target=(3,4) where (3,4) ≠ unit.grid_position, attack_target=valid_enemy, WHEN Turn executes this ActionPlan (simulated), THEN the unit moves to (3,4) and attacks the valid enemy, regardless of type field set to WAIT. The type field is a human-readable label; Turn's execution logic follows only the field values move_target and attack_target.

**AC-AI-030 — Edge: WorldState.clone() is deep copy** [Logic]
GIVEN WorldState A with _occupancy_snapshot = {(0,0): E1, (0,1): E2}, WHEN B = A.clone() and B._occupancy_snapshot[(0,2)] = E3, THEN A._occupancy_snapshot has exactly 2 entries: {(0,0): E1, (0,1): E2}. Modifying clone B does not affect original A.

### 汇总

| 类别 | 数量 | Logic | Integration | Structural |
|----------|-------|-------|-------------|------------|
| Core Rules (15) | 15 | 11 | 1 | 3 |
| Interface Verification (3) | 3 | 0 | 0 | 3 |
| Formula F1 (7) | 7 | 7 | 0 | 0 |
| Edge Cases (5) | 5 | 5 | 0 | 0 |
| **Total** | **30** | **23** | **1** | **6** |

**门禁汇总：**
- **BLOCKING (Logic)**: 23 criteria — each requires an automated unit test in `tests/unit/ai/`
- **BLOCKING (Integration)**: 1 criterion — requires Map system + WorldState integration test
- **ADVISORY (Structural)**: 6 criteria — verified by code review, not automated test

## Open Questions

- **OQ1 — AIController 接口原型时机**: Game Concept R5 要求"原型两次再提交"—— scaffold NullAI + BasicAI stub 以证明接口容纳两种互不相同的行为而不修改 Turn。→ 应在 AI GDD 锁定后、Turn System 实现前执行 `/prototype ai-controller`。

- **OQ2 — Turn 执行循环的 faction 守卫缺口**: Edge Cases 标记了 Turn 执行循环不检查 `unit.faction == active_faction` 的缺口。→ **已解决（2026-04-30）**：AI GDD Rule 7 step 1 已增加 `unit.faction == active_faction` 守卫；Turn GDD Interactions AI 行已添加注记。

- **OQ3 — BasicAI GDD 归属**: Core Rule 10 定义了 BasicAI 的行为规约（用于验证接口正确性）。完整的 BasicAI GDD 属于 Tier 2—— 需要细化顺序编排、tiebreaker 规则、障碍物地图上的移动策略。→ 在 MVP 完成后，`/design-system basic-ai` 作为 Tier 2 第一个系统。

- **OQ4 — WorldState 版本号**: Edge Cases 预留了 WorldState 版本号/时间戳供未来异步 AI 使用。MVP 的同步执行模型不需要。→ Tier 2+ 如需异步 AI 规划（`begin_thinking()` / `thinking_complete` 信号），在 WorldState 中添加版本号字段。

- **OQ5 — @abstract 在 release 构建中的可靠性**: `@abstract`（Godot 4.5+）在编辑器中阻止基类实例化，但运行时在 release 构建中不强制。基类的 `assert(false)` 是第二道防线。→ 是否需要额外的运行时检查（例如 `if get_script() == AIController: push_error()`）？

- **OQ6 — AI 与热座模式的耦合**: NullAI 依赖热座假设（Input 消费 `faction_activated(ENEMY)` 让玩家手动操作）。如果未来非热座模式使用 NullAI（错误配置），比赛会在 ENEMY 阶段卡死。→ 配置校验责任在何处？Game 场景初始化时检查，还是 TurnManager 断言？
