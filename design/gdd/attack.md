# Attack

> **Status**: In Design
> **Author**: binlee1990 + Claude
> **Last Updated**: 2026-04-29
> **Implements Pillar**: Pillar 2 — System Orthogonality (damage formula reads Unit stats, returns result; Attack owns no state)

## Overview

Attack 是 SRPG 骨架中「Move+Attack」打包动作的后半部分 —— 也是玩家的决策兑现时刻。一个单位移动（或跳过移动）后, 系统读取其 `RNG` 属性, 在棋盘上高亮所有可攻击的敌方单位; 玩家悬停目标预览伤害数字, 点击确认, 伤害公式 `max(ATK − DEF, 1)` 立即结算 —— HP 减少, 若归零则单位死亡。整个过程是确定性的: 无命中率、无暴击、无反击。Attack 系统本身不持有任何状态 —— 它从 Unit 读取属性, 通过 Map 验证距离, 执行纯数学判定, 然后将结果写回 Unit 的 `take_damage()` 接口。没有 Attack 系统, 棋盘上的两个阵营将永远无法消灭对方 —— 移动失去了战略意义, 胜利条件永远无法触发。

## Player Fantasy

Attack 是「Move+Attack」打包动作的 **兑现时刻**。Movement 回答了"我去哪里?" — Attack 回答"谁死?" 

悬停一个在射程内的敌方目标, 伤害数字立刻浮现在单位上方。没有骰子, 没有祈祷, 没有隐藏数学 —— 只有 `ATK − DEF`, 在你悬停之前就可以心算出来。数字是一个承诺。点击让它成真。HP 下降。如果数字足够大, 单位从棋盘上消失。你为此做了定位。你赢得了这个结果。棋盘更干净了, 因为你的选择是正确的。

锚定时刻: **悬停一个残血敌人, 看到击杀数字出现, 点击, 看着它从棋盘上消失。**

确定性是区分点。在一类被显示命中率背叛了几十年的游戏中, 这个 Attack 系统直接说真话。没有"为什么会这样?"的时刻。情感回报不是兴奋 —— 是兑现。你知道会发生什么, 你让它发生了。

## Detailed Design

### Core Rules

1. **攻击前置条件**: 单位满足以下全部条件时可以攻击:
   - `unit.is_alive == true`
   - `unit.faction == active_faction`（由 Input 系统强制，非 Attack 职责）
   - `unit.action_state in [SELECTED, MOVED]`（参见 Unit GDD 的 `can_attack()`）
   - `unit.has_acted_this_turn == false`

2. **射程**: 攻击射程通过攻击者瓦片到目标瓦片的 Manhattan 距离计算:
   
   `in_range(attacker_pos, target_pos) = |attacker.row − target.row| + |attacker.col − target.col| ≤ attacker.rng`
   
   攻击者自身所在瓦片（距离 0）被排除 —— 单位不能攻击自身。RNG=1 表示 4 个相邻瓦片（N/S/E/W）。RNG=2 表示 12 个瓦片。RNG=3 表示 24 个瓦片。这与 Movement 的 BFS 4-邻域空间隐喻一致。

3. **目标验证**: 一个瓦片包含有效攻击目标，当且仅当以下所有条件同时满足:
   - `Map.get_unit_at(tile) != null` —— 该瓦片上存在单位
   - `target.is_alive == true` —— 目标未死亡
   - `target.faction != attacker.faction` —— 仅限敌对阵营
   - `manhattan(attacker.grid_position, target.grid_position) ≤ attacker.rng` —— 在射程内

4. **伤害公式**: `damage = max(attacker.atk − target.def, 1)` —— 确定性，无随机数，无暴击，保底 1 点。通过 `target.take_damage(damage)` 施加。公式全部定义见 D 节（Formulas）。

5. **攻击执行**: 玩家对一个有效目标确认攻击时:
   - 通过 `max(attacker.atk − target.def, 1)` 计算伤害
   - 调用 `target.take_damage(damage)`
   - 设置 `attacker.has_acted_this_turn = true`
   - 设置 `attacker.action_state = ACTED`（Unit GDD 状态机）
   - 以上四步均为同步操作 —— MVP 阶段无动画延迟

6. **攻击流程 — 直接攻击（从 SELECTED）**: 玩家在单位处于 SELECTED 状态时点击射程内的敌方单位:
   - 单位跳过移动（等价于 skip-move，Movement GDD Rule 5）
   - 攻击立即按 Rule 5 执行
   - 单位状态: SELECTED → ACTED（通过攻击执行触发）
   - 这是标准的"不移动直接攻击"的 SRPG 行为

7. **攻击流程 — 移动后攻击（从 MOVED）**: 单位进入 MOVED 状态后（Movement GDD Rule 6），Input 系统自动转入攻击瞄准模式:
   - `AttackRangeResolver` 计算 `get_valid_targets(unit, map)` —— 射程内所有敌方单位的列表
   - UI 高亮有效目标瓦片（颜色与移动高亮区分）
   - 玩家悬停有效目标 → 显示伤害预览
   - 玩家点击有效目标 → 按 Rule 5 执行攻击
   - 玩家右键或按 Escape → 跳过攻击，单位进入 ACTED 但不造成伤害（Rule 8）

8. **跳过攻击**: 处于攻击瞄准模式（SELECTED 或 MOVED）的单位可以选择不攻击:
   - 右键或 Escape 清除攻击高亮
   - `unit.has_acted_this_turn = true` —— 行动仍被消耗
   - `unit.action_state = ACTED` —— 单位回合结束
   - 不造成任何伤害，不需要目标

9. **无反攻（MVP）**: 单位攻击时，防御方**不会**反击。这是根据 game-concept.md 的 MVP 范围做出的刻意排除。反攻的接口槽位已预留 —— Attack 在执行后发出 `damage_dealt(attacker, target, damage)` 信号；未来 Tier 2 系统可以连接此信号触发反攻，无需修改 Attack 内部代码。

10. **Attack 是纯计算**: `AttackResolver` 是一个 `RefCounted`，具有单一入口点 `execute_attack(attacker: Unit, target: Unit) -> AttackResult`。它不持有状态、不持有引用、除通过 `target.take_damage()` 施加伤害外不产生任何副作用。`AttackResult` 是不可变 RefCounted，包含 `{damage: int, killed: bool, attacker: Unit, target: Unit}`。遵循与 Movement 的 `MovementResult` 和 Map 的 `GridSpace` 相同的模式。

11. **AttackRangeResolver**: 配套的 RefCounted，入口点为 `get_valid_targets(unit: Unit, map: Map) -> Array[Unit]`。遍历所有存活的敌方单位（`target.faction != unit.faction AND target.is_alive`），按 Manhattan 距离 ≤ `unit.rng` 过滤。返回列表按距离升序排列（最近的在前），相同距离时按 HP 最低优先（作为并列的打破规则）。排序后的列表使得 UI 可以优先显示顺序，并使未来的 BasicAI 可以轻松选择"最佳"目标。

12. **伤害预览（resolve_damage）**: `AttackResolver.resolve_damage(atk: int, def: int) -> int` 是一个纯静态方法，计算 `max(atk − def, 1)` 但不执行攻击。由 UI / Input 用于悬停伤害预览。接受裸数值，而非 Unit 引用 —— 无副作用，不读取或写入任何状态。

13. **约束条件**:
    - 攻击者必须存活。死亡单位不能攻击。
    - 目标必须存活。死亡单位不能被选为目标（其瓦片根据 Map 占用规则为空 —— `Map.get_unit_at()` 返回 null，因此 Rule 3 自然捕获此情况）。
    - 同阵营目标被 Rule 3 的阵营检查拒绝。
    - 射程仅使用 Manhattan 距离 —— MVP 无对角线攻击、无视距检查。
    - 攻击不能超出地图边界（Manhattan 距离使用地图内的坐标；地图外的单位不存在）。
    - MVP 仅支持单目标攻击 —— 无 AOE / 多目标。

### States and Transitions

Attack 系统在 Unit GDD 状态机中运行，新增了 SELECTED → ACTED 的直接路径:

| From | Trigger | To | Effect |
|------|---------|----|--------|
| `SELECTED` | 玩家点击射程内的有效敌方目标 | `ACTED` | 直接攻击 —— 伤害施加，`has_acted = true`，发出 `damage_dealt` 信号 |
| `SELECTED`（瞄准中） | 玩家右键或按 Escape | `ACTED` | 从 SELECTED 跳过攻击 —— 无移动、无攻击，行动已消耗 |
| `MOVED`（瞄准中） | 玩家点击射程内的有效敌方目标 | `ACTED` | 移动后攻击 —— 伤害施加，`has_acted = true`，发出 `damage_dealt` 信号 |
| `MOVED`（瞄准中） | 玩家右键或按 Escape | `ACTED` | 跳过攻击 —— 无伤害，`has_acted = true` |

瞄准模式不是状态机中的正式状态 —— 它是当单位处于 SELECTED 或 MOVED 且至少有一个有效目标时进入的 UI 模式。正式状态仍为 IDLE / SELECTED / MOVED / ACTED / DEAD，如 Unit GDD 定义。

> 注意: Unit GDD 状态机表目前仅显示 IDLE → SELECTED → MOVED → ACTED。SELECTED → ACTED 直接路径（不移动攻击）和瞄准取消路径为新增内容。Unit GDD 的状态机表应更新以反映这些内容 —— 已在 Open Questions 中标记。

Turn System 自动推进读取 `unit.has_acted_this_turn`（由 Attack Rule 5/8 设置），而非 `action_state`。Attack 无需通知 Turn System —— Turn 在每个动作后轮询此标志。

### Interactions with Other Systems

| System | Direction | Data Flow | Interface |
|--------|-----------|-----------|-----------|
| **Map** | 上游（读取） | Attack 查询单位位置 | `Map.get_unit_at(coord) → Unit` —— 目标验证。Attack 不调用 `get_neighbors()` —— 射程基于 Manhattan，不是 BFS。 |
| **Unit** | 上游（读取） | Attack 读取攻击者和防御者属性 | `attacker.atk: int`、`attacker.rng: int`、`attacker.grid_position: Vector2i`、`attacker.faction: Faction.Type`、`attacker.is_alive: bool`、`attacker.action_state`；目标对应字段（`def`、`hp`、`faction`、`is_alive`） |
| **Unit** | 下游（写入） | Attack 施加伤害 | `target.take_damage(damage: int)` —— 伤害由 Attack 计算，通过 Unit 接口施加 |
| **Unit** | 下游（写入） | Attack 标记行动已消耗 | `attacker.has_acted_this_turn = true`，`attacker.action_state = ACTED` |
| **Turn System** | 间接 | Attack 完成触发自动推进 | Turn 在每个动作后轮询 `unit.has_acted_this_turn`。Attack 不直接调用 Turn。 |
| **UI / Input** | 下游（数据） | Attack 提供目标列表和伤害预览 | `AttackRangeResolver.get_valid_targets(unit, map) → Array[Unit]` —— 用于高亮渲染。`AttackResolver.resolve_damage(atk, def) → int` —— 用于悬停伤害预览（不执行攻击，纯计算） |
| **UI / Input** | 上游（调用） | Input 触发攻击执行 | Input 在点击确认时调用 `AttackResolver.execute_attack(attacker, target)`。Input 拥有点击处理和悬停预览。 |
| **Movement** | 间接 | 攻击阶段在移动阶段之后 | 单位移动后进入 MOVED 状态 → Input 自动进入攻击瞄准。Movement 对 Attack 没有直接依赖 —— Input 是协调者。 |
| **Victory** | 间接（信号） | 死亡触发胜利检查 | `target.take_damage()` 在 HP ≤ 0 时发出 `unit_died`。Turn System 监听并评估阵营消灭。Victory 监听 `match_ended`。Attack 不直接调用 Victory。 |
| **AI** | 预留（Tier 2） | AI 选择攻击目标 | `AttackRangeResolver.get_valid_targets()` 提供目标列表。`AttackResolver.execute_attack()` 执行。AI GDD 将定义选择策略。 |

> **设计注记 — Map GDD 勘误**: Map GDD 的交互表当前将 `get_neighbors()` —— "射程环计算" 列为 Attack 对 Map 的依赖。这是在确认 Manhattan 距离之前做出的早期推断。Attack 使用 Manhattan 距离（纯坐标数学，公式由 Movement GDD F2 持有）+ `get_unit_at()`（点查询），而非邻居扩展。此勘误应在下一次一致性检查通过时在 Map GDD 中修正。

## Formulas

### F1: 伤害公式

伤害公式定义如下:

`damage = max(attacker.atk − target.def, 1)`

**变量:**

| Variable | Symbol | Type | Range | Description |
|----------|--------|------|-------|-------------|
| 攻击者 ATK | atk | int | [3, 8] | 攻击者的 Attack 属性，来自 UnitStats |
| 防御者 DEF | def | int | [0, 5] | 防御者的 Defense 属性，来自 UnitStats |
| 原始差值 | raw | int | [-5, 8] | 中间值: atk − def，在保底截断之前 |
| 最终伤害 | damage | int | [1, 8] | 最终造成的伤害。保底 1 保证了每次攻击都有进度。 |

**输出范围:** MVP 属性上限下为 [1, 8]。原则上无上界 —— 若 Tier 2 提高 ATK/DEF 上限，范围将扩展，但保底始终为 1。

**极端行为:**
- **ATK ≤ DEF**（例如 ATK 3 vs DEF 5）: `raw = -2`，`damage = 1`。每次攻击恰好造成 1 点伤害 —— 保底防止了僵局。
- **ATK >> DEF**（例如 ATK 8 vs DEF 0）: `damage = 8`。最大击杀能力 —— 可秒杀任何 HP ≤ 8 的单位。
- **DEF = 0**（无减伤）: `damage = atk`。裸攻击值无修正穿透。

**示例:**

| Scenario | ATK | DEF | Raw | Damage | Note |
|----------|-----|-----|-----|--------|------|
| 低攻高防 | 3 | 5 | -2 | **1** | 保底阻止零伤害 |
| 默认对抗 | 5 | 2 | 3 | **3** | 对 HP 10 约需 4 次击杀 |
| 玻璃大炮 | 8 | 0 | 8 | **8** | 秒杀 HP ≤ 8 的单位 |
| 坦克互耗 | 4 | 4 | 0 | **1** | ATK = DEF 被截断为 1 |
| 脆皮互殴 | 3 | 0 | 3 | **3** | 双方均脆弱 |

**HTK 矩阵**（按 ATK vs DEF 的伤害值；HTK = `ceil(max_hp / damage)`）:

```
       DEF: 0  1  2  3  4  5
ATK 3:      3  2  1  1  1  1
ATK 4:      4  3  2  1  1  1
ATK 5:      5  4  3  2  1  1
ATK 6:      6  5  4  3  2  1
ATK 7:      7  6  5  4  3  2
ATK 8:      8  7  6  5  4  3
```

对于 HP=10（默认）: HTK 范围从 **2**（ATK 8 vs DEF 0）到 **10**（ATK 3 vs DEF 5）。默认属性线（ATK 5, DEF 2, HP 10）产生伤害 3 → HTK 4 —— 健康的中间值。

**退化组合（设计师知晓即可，非代码修复项）:**
- ATK 3 vs DEF 3+: 1 点伤害，HP=10 时 HTK ≥ 10。两个这样的单位对打可能触及回合上限。设计师应避免将最大 DEF 单位与最小 ATK 单位配对。
- ATK 8 vs DEF ≤ 2, HP ≤ 8: HTK=1。战术游戏中快速击杀可接受，但部署多个 ATK 8 的玻璃大炮可能将对局缩短到 5 分钟底线以下。

### F2: 射程检查（Manhattan 距离）

射程检查公式定义如下:

`in_range = |attacker.row − target.row| + |attacker.col − target.col| ≤ attacker.rng`

**变量:**

| Variable | Symbol | Type | Range | Description |
|----------|--------|------|-------|-------------|
| 攻击者位置 | (a_r, a_c) | Vector2i | 地图内瓦片 | 攻击者的 grid_position |
| 目标位置 | (t_r, t_c) | Vector2i | 地图内瓦片 | 目标的 grid_position |
| Manhattan 距离 | dist | int | [1, map_cols + map_rows] | 两瓦片间的网格距离 |
| 攻击射程 | rng | int | [1, 3] | 攻击者的 RNG 属性，来自 UnitStats |

**输出范围:** 当距离 ≤ RNG 且 ≥ 1 时返回 `true`。攻击者自身瓦片（距离 0）始终返回 `false` —— 单位不能攻击自身。

**极端行为:**
- RNG=1，相邻目标: `|1−0| + |0−0| = 1 ≤ 1` → `true`。
- RNG=1，对角线目标: `|1−0| + |1−0| = 2 > 1` → `false`。RNG=1 时不能对角线攻击。
- RNG=3，地图另一端目标: 检查 Manhattan ≤ 3。

**示例:** 攻击者在 (5, 3)，RNG=2。目标在 (5, 5): `|5−5| + |5−3| = 2 ≤ 2` → `true`。目标在 (3, 5): `|3−5| + |5−3| = 4 > 2` → `false`。

> **所有权**: Manhattan 距离（`|dr| + |dc|`）在 Movement GDD F2 中定义。Attack 引用它，不重新定义。射程检查 `≤ rng` 是 Attack 自身的添加。

### F3: 有效目标瓦片数（per tile）

从给定位置在给定 RNG 下的攻击可达瓦片数定义如下:

`attackable_tiles(rng) = 2 × rng × (rng + 1)` —— 适用于开放场地（无地图边界裁剪）

| RNG | 最大瓦片数（开放场） | 16×12 Map 典型值（中心） | 8×8 Map 上（角落） |
|-----|------------------|------------------------------|---------------------|
| 1 | 4 | 4 | 2 |
| 2 | 12 | 12 | 5 |
| 3 | 24 | 23 | 10 |

以上为**潜在**可攻击瓦片数。实际有效目标为这些瓦片中包含存活敌方单位的子集 —— 通常远少于此。每帧 UI 高亮开销由 ≤24 个瓦片多边形控制，远在预算内。

### F4: resolve_damage（预览）

`resolve_damage(atk: int, def: int) = max(atk − def, 1)`

纯静态函数。与 F1 相同但接受裸整数而非 Unit 引用。由 UI 用于悬停伤害预览 —— 计算伤害**将是什么**而不执行攻击。无副作用，不读写任何状态。使玩家在提交前能看到伤害。

### F5: HTK 估计（分析用）

`htk = ceil(target.hp / max(attacker.atk − target.def, 1))`

不是正式的 API 方法 —— 供设计师对属性组合做理性检验的分析公式。给定 HP=10，ATK=5，DEF=2: `htk = ceil(10 / 3) = 4`。理性检验应成立: 对所有部署的模板，`htk < turn_cap` —— 如果任何一个单位需要的击杀回合数超过回合上限，单靠该对局无法解决比赛。

## Edge Cases

### 伤害结算

- **若目标 HP 因伤害达到 0**: `take_damage()` 处理死亡 —— 发出 `unit_died`，Map 移除占用。Attack 不需要特殊处理。`attacker.has_acted` 仍设为 `true`。`AttackResult.killed = true`。

- **若伤害恰好等于目标剩余 HP**: `take_damage(amount)` 其中 `amount == hp` → hp 通过 `clamp(hp − amount, 0, max_hp)` 变为 0。发出 `unit_died`。`AttackResult.killed = true`。不需要特殊处理 —— `clamp` 自然产生 0。

- **若伤害超过剩余 HP（溢出）**: `clamp` 在 0 处截底。溢出量被丢弃。`AttackResult.damage` 记录原始伤害值，而非实际扣除的 HP。击杀有效。无需特殊处理。

- **若伤害计算结果为 0（保底检查）**: `max(..., 1)` 保底保证伤害 ≥ 1。即使 ATK 3 vs DEF 5 也产生伤害 1。MVP 中零伤害不可能发生。

### 目标验证守卫

- **若对无单位或已死亡单位的瓦片试图攻击**: `Map.get_unit_at(tile)` 对死亡单位返回 `null`（Map 在 death 信号时移除占用）。目标验证 Rule 3 拒绝 `null` 目标。`execute_attack()` 以断言 `target != null` 作为第二道防线。

- **若对同阵营单位试图攻击**: 目标验证 Rule 3 拒绝（`target.faction != attacker.faction`）。Input 应永不为同阵营单位提供目标。`execute_attack()` 作为纵深防御守卫此条件: 若被绕过，攻击被拒绝并返回 `AttackResult.INVALID`。

- **若攻击者本回合已行动**: `has_acted_this_turn == true` → 前置条件不满足。Input 不应为已行动单位进入攻击瞄准。`execute_attack()` 在入口守卫，若被绕过则返回 `AttackResult.INVALID`。

### MVP 不可能发生（预留守卫）

- **若攻击者在目标选择与执行之间死亡**: MVP 中不可能 —— 无延迟伤害、无陷阱、无反应技能。攻击执行是同步的。若 Tier 2 引入这些机制，在 `execute_attack()` 入口添加 `if not attacker.is_alive: return AttackResult.INVALID`。

- **若目标在选择与执行之间位置改变**: MVP 中不可能 —— 无强制移动、无击退、无传送。若 Tier 2 引入位移，`execute_attack()` 应在执行时重新验证 Manhattan 距离。

### 退化输入状态

- **若无有效目标（空目标列表）**: `AttackRangeResolver.get_valid_targets()` 返回 `[]`。UI 应立即过渡到 ACTED 而不进入瞄准模式 —— 无需展示空的攻击选项。这避免了死 UI 状态。

- **若对已行动单位调用 `get_valid_targets()`**: 仍然返回射程内的敌方单位列表。`get_valid_targets()` 不检查 `has_acted` —— Input 拥有前置条件执行权。resolver 是纯查询，与"纯计算"模式一致。

- **若在射程内无目标时触发跳过攻击**: 有效。单位即使有目标也可以选择不攻击，或在无目标时跳过（尽管空列表自动跳过使后者为 no-op）。`has_acted` 无论哪种方式均被消耗。

### 数据完整性

- **若以超范围属性调用 `resolve_damage()`**: 无条件返回 `max(atk − def, 1)` —— 纯数学，无验证。若调用者传入 ATK=999 或 DEF=-5，函数正确计算。属性范围验证是 Unit 的职责（Unit GDD F4）。

- **若 `execute_attack()` 收到 null 攻击者或目标**: 断言两者非 null，带描述性消息（`"execute_attack: attacker is null"` / `"execute_attack: target is null"`）。在 release 构建中返回 `AttackResult.INVALID`。不崩溃，不静默失败。

- **若 Manhattan 距离计算溢出**: 不可能。地图边界 [8, 32] 每轴 → 最大 Manhattan 距离 = `(32−1) + (32−1) = 62`。轻松适配 `int`。

## Dependencies

### 上游依赖

| System | Type | Interface Consumed | Notes |
|--------|------|--------------------|-------|
| **Map** | Hard | `get_unit_at(coord) → Unit` | 目标验证 —— 确认目标瓦片存在单位。Attack 不调用 `get_neighbors()` —— 射程基于 Manhattan，不是 BFS。 |
| **Unit** | Hard | `atk: int`、`def: int`、`rng: int`、`hp: int`、`max_hp: int`、`faction`、`is_alive`、`has_acted_this_turn`、`action_state`、`grid_position`、`take_damage(amount)`、`unit_died` 信号 | 读取属性用于伤害计算和目标验证。通过 `take_damage()`、`has_acted`、`action_state` 写入。 |
| **Movement** | Indirect | Manhattan 距离公式 F2 | Manhattan 距离在 Movement GDD F2 中定义。Attack 引用它用于射程计算（F2），不重新定义。Attack 对 MovementResolver 无运行时依赖。 |

### 下游依赖

| System | Type | Interface Exposed | Notes |
|--------|------|-------------------|-------|
| **UI / Input** | Hard | `AttackRangeResolver.get_valid_targets(unit, map) → Array[Unit]`；`AttackResolver.resolve_damage(atk, def) → int`；`AttackResolver.execute_attack(attacker, target) → AttackResult` | UI 读取目标列表用于高亮渲染和伤害预览。Input 在点击确认时调用 `execute_attack()`。 |
| **AI** | Hard（Tier 2） | 与 UI/Input 相同的接口 | AI GDD 将使用相同的 `get_valid_targets()` 列表定义目标选择策略。接口设计为无需修改即可同时支持人类和 AI 消费者。 |
| **Turn System** | Indirect | `unit.has_acted_this_turn` 开关 | Turn 轮询此标志用于自动推进。Attack 在执行或跳过时将其设为 `true`。Attack 不直接调用 Turn。 |
| **Victory** | Indirect | `unit_died` 信号链 | `take_damage()` → `unit_died` → Turn System 评估消灭 → `match_ended` → Victory 处理胜者。Attack 与 Victory 间隔三层。 |

### 外部依赖

| Dependency | Type | Notes |
|------------|------|-------|
| `AttackResolver`（RefCounted） | Code | 纯伤害计算 + 执行。由 Game 场景（组合根）创建，DI 注入到 Input。遵循 GridSpace / MovementResolver 模式。 |
| `AttackRangeResolver`（RefCounted） | Code | 射程内敌方单位查询。迭代单位，按阵营 + 距离过滤。由 Game 场景创建，DI 注入到 Input。 |
| `AttackResult`（RefCounted） | Code | 不可变结果包装: `{damage: int, killed: bool, attacker: Unit, target: Unit}`。遵循 MovementResult 模式。 |
| `Faction.Type` enum | Code | 定义在 `src/core/faction.gd`（Unit GDD）。Attack 读取用于目标验证。 |

## Tuning Knobs

大多数影响 Attack 的可调值由 Unit GDD（UnitStats.tres）持有。此处列出供交叉引用，非重复定义。

### Attack 自持调节项

| Knob | Location | Safe Range | 过低的影响 | 过高的影响 | Notes |
|------|----------|------------|------------------------|------------------------|-------|
| `damage_floor` | AttackResolver（常量） | {0, 1} | 0: DEF 可完全抵消 ATK —— ATK ≤ DEF 造成 0 伤害，产生无解对局 | N/A —— 上限为 1 | MVP 锁定为 1。floor=0 预留给 Tier 2，若引入独立的"穿透"机制。 |
| `rng_metric` | AttackResolver（常量） | {manhattan, chebyshev} | N/A | N/A | MVP 锁定为 `manhattan`。与 Movement 的 4-邻域 BFS 保持一致。预留给 Tier 2，若引入对角线攻击。 |

### Unit 持有调节项（Attack 消费方）

| Knob | Location | Safe Range | 对 Attack 的影响 | Notes |
|------|----------|------------|------------------|-------|
| `unit.atk` | UnitStats.tres | [3, 8] | DEF 削减前的原始伤害。每 +1 ATK = 对相同 DEF +1 伤害。 | 定义在 Unit GDD。全局提高 ATK 会使 DEF 意义减弱。 |
| `unit.def` | UnitStats.tres | [0, 5] | 固定伤害减免。每 +1 DEF 抵消 1 ATK。 | 定义在 Unit GDD。DEF=5 时，仅 ATK ≥ 7 造成 >2 伤害。 |
| `unit.rng` | UnitStats.tres | [1, 3] | 攻击范围（Manhattan 瓦片数）。RNG=1: 仅 4 个相邻瓦片。RNG=3: 24 个瓦片。 | 定义在 Unit GDD。从中心 RNG=3 几乎覆盖 7×7 菱形区域。 |
| `unit.max_hp` | UnitStats.tres | [5, 20] | 生存上限。决定 HTK，参见 F1 伤害矩阵。 | 定义在 Unit GDD。HP=5 遇 ATK 8 → HTK=1。HP=20 遇 ATK 3 vs DEF 5 → HTK=20。 |

### 调节项交互

- **击杀效率**: `HTK = ceil(max_hp / max(atk − def, 1))`。提高 `atk` 或降低 `def` 均减少 HTK。设计师必须检查最不利对抗中的最短 HTK 是否不为 1（非意图秒杀），且最长 HTK 是否不 ≥ `turn_cap`（无法解决的对局）。
- **威胁半径**: `threat = mov + rng`。一个 MOV 6 + RNG 3 的单位投射 9 个瓦片威胁 —— 几乎覆盖整个 16×12 地图宽度。在 Unit GDD 中注明；Attack 的角色是 `rng` 组件。
- **damage_floor vs DEF 堆叠**: floor=1 意味着即使 ATK 3 vs DEF 5 也造成 1 点伤害。若 Tier 2 引入 DEF 堆叠超过 5，保底防止真正无敌。将保底提高到 2 会使低 ATK 单位对坦克过于有效。

## Visual/Audio Requirements

根据 Programmer Art Functional 锚点。MVP 无音频。

### 攻击瞄准高亮

| Element | Color | Description |
|---------|-------|-------------|
| 有效目标高亮 | 红色（`#EF4444`，敌方阵营红） | 包含有效攻击目标的瓦片高亮。使用敌方阵营颜色 —— 自然关联: 红色 = 敌对 = 可攻击。 |
| 光标/悬停目标 | 更亮的红色或红色带边框 | 与非悬停目标区分。标示"这是当前选中的目标。" |

### 伤害预览（悬停）

| Element | Specification | Description |
|---------|--------------|-------------|
| 文本格式 | `"-N"`（例如 `"-3"`） | 前缀减号，无"+"，无"HP"标签。紧凑且无歧义。 |
| 位置 | `Vector2(0, -60)` 目标单位中心上方 | 在 HP 标签上方的偏移（HP 在 -40，伤害在 -60 —— 垂直堆叠）。 |
| 字体 | Godot 默认 | MVP 不使用自定义字体。 |
| 颜色（普通） | `#F59E0B`（琥珀/黄色） | 暖中性色 —— 与 HP 白色、阵营蓝/红、以及移动蓝色区分。 |
| 颜色（击杀） | `#EF4444`（敌方红） | 当 `damage ≥ target.hp` 时，伤害数字切换为红色 —— "这一击将击杀。" 一个额外的颜色 token。 |

### 伤害结算（点击后）

| Element | Specification | Description |
|---------|--------------|-------------|
| 伤害数字停留 | 悬停位置持续 600ms | 伤害数字在点击后在目标上方保持 600ms，然后淡出。给玩家一个确认结果的节拍。 |
| HP 标签更新 | 即时 | 目标的 HP 标签立即更新为 `"HP: N/M"`（例如 `"HP: 7/10"`）。无补间 —— 即时数值变更。 |
| 存活目标视觉 | HP 数字变更，伤害数字停留中 | 单位保持完全透明度和阵营颜色。 |
| 死亡 | 即时 `queue_free()` | 单位节点在 `unit_died` 信号后立即从场景树移除。无尸体、无淡出、无缩放补间 —— 与 Programmer Art Functional "调试可视化器" 理念一致。 |

### 颜色 Token（新增）

| Token | Hex | Usage |
|-------|-----|-------|
| `DAMAGE_PREVIEW` | `#F59E0B`（琥珀） | 悬停伤害数字 —— 普通（非击杀） |
| `DAMAGE_LETHAL` | `#EF4444`（红色） | 悬停伤害数字 —— 击杀（将杀死目标） |
| `TARGET_HIGHLIGHT` | `#EF4444`（红色，与敌方阵营相同） | 有效攻击目标瓦片高亮 |

> Token 理据: `DAMAGE_PREVIEW` 琥珀色选择为与阵营蓝（#3B82F6）、阵营红（#EF4444）、路径青（Movement GDD）、可达蓝（Movement GDD）以及瓦片状态区分。`DAMAGE_LETHAL` 使用已有的敌方阵营红 —— 危险的东西是红色的，一致的认知模型。

### Audio

**无。** 根据 game-concept.md 反支柱和 MVP 范围明确排除。无攻击音效、无击杀音效、无 UI 音效。`damage_dealt` 信号和 `unit_died` 信号是未来音频系统可以连接、无需修改 Attack 代码的钩子。

> 📌 **Asset Spec** — Visual/Audio 需求已定义。在 art bible 批准后，运行 `/asset-spec system:attack` 以生成每个美术资源的视觉描述、尺寸和生成提示词。

---

## UI Requirements

### 悬停伤害预览

当玩家悬停有效攻击目标时，UI 调用 `AttackResolver.resolve_damage(attacker.atk, target.def)` 并按上方 Visual/Audio 规范渲染结果。预览纯粹是信息性的 —— 无承诺，无状态变更。

### 目标高亮渲染

UI 读取 `AttackRangeResolver.get_valid_targets(unit, map)` 并在每个返回的瓦片上渲染高亮覆盖层。高亮颜色: 敌方阵营红（#EF4444）。悬停目标使用更亮变体或红带边框以区分选择。

### 攻击确认

- **左键** 点击高亮目标: UI 调用 `AttackResolver.execute_attack(attacker, target)`。显示停留的伤害数字。更新所有 HP 标签。
- **右键 / Escape** 在瞄准中: UI 清除高亮。单位通过 skip-attack 过渡到 ACTED。

### 攻击后清理

攻击执行（或 skip-attack）后，UI 清除:
- 所有攻击目标高亮。
- 所有移动可达高亮（如果移动阶段还有残留）。
- 伤害预览文本（在停留持续时间后）。

### 端到端 UI 流程

```
1. 单位进入 SELECTED → 移动范围高亮（蓝色）
2. 玩家点击射程内的敌人 → 直接攻击（跳过移动）→ ACTED
3. 或: 玩家点击移动目标 → 单位移动 → MOVED → 自动进入攻击瞄准
4. 攻击瞄准 → 有效目标高亮（红色）
5. 玩家悬停目标 → 伤害预览数字出现
6. 玩家点击目标 → 伤害停留 600ms → HP 更新 → 单位死亡或存活
7. 玩家 Esc/右键 → 跳过攻击 → ACTED
8. 行动后 → 所有高亮清除
```

> 📌 **UX 标记 — Attack**: 本系统提供攻击瞄准高亮和伤害预览显示。这些 UI 元素应在 `design/ux/hud.md` 中作为战斗 HUD 层的一部分进行规范。在 Phase 4（Pre-Production）中，对 HUD 运行 `/ux-design`，引用 `AttackRangeResolver` 和 `AttackResolver` 作为这些 UI 元素的数据源。

## Acceptance Criteria

### A. 核心规则

**AC-C01 — 所有前置条件满足 → 允许攻击**（Logic）
GIVEN 一个单位满足 `is_alive==true`、`faction == active_faction`、`action_state == SELECTED`、`has_acted==false`，且存在射程内的有效敌方目标，WHEN `execute_attack(attacker, target)` 被调用，THEN 攻击成功并返回有效的 `AttackResult`。

**AC-C02 — 死亡攻击者被拒绝**（Logic）
GIVEN 一个 `is_alive == false` 的单位，WHEN `execute_attack()` 被调用，THEN 返回 `AttackResult.INVALID`。不造成伤害。

**AC-C03 — 已行动攻击者被拒绝**（Logic）
GIVEN 一个 `has_acted_this_turn == true` 的单位，WHEN `execute_attack()` 被调用，THEN 返回 `AttackResult.INVALID`。

**AC-C04 — 错误的 action_state 被拒绝**（Logic）
GIVEN 一个 `action_state == IDLE` 的单位，WHEN `execute_attack()` 被调用，THEN 返回 `AttackResult.INVALID`。

**AC-C05 — 射程检查: 在 Manhattan 距离内**（Logic）
GIVEN 攻击者在 (5,3) 且 RNG=2，目标在 (5,5)，WHEN 射程被评估，THEN `manhattan = |5−5| + |5−3| = 2 ≤ 2` → `in_range == true`。

**AC-C06 — 射程检查: 在 Manhattan 距离外**（Logic）
GIVEN 攻击者在 (5,3) 且 RNG=2，目标在 (3,5)，WHEN 射程被评估，THEN `manhattan = 4 > 2` → `in_range == false`。

**AC-C07 — 射程检查: 自身瓦片被排除**（Logic）
GIVEN 攻击者在 (5,3) 且 RNG=2，目标在 (5,3)（同一瓦片），WHEN 射程被评估，THEN `manhattan = 0` → `in_range == false`（不能攻击自身）。

**AC-C08 — 目标验证: null / 死亡目标**（Logic）
GIVEN 有效的攻击者，WHEN 目标瓦片的 `Map.get_unit_at(tile) == null` 或 `target.is_alive == false`，THEN 攻击被拒绝。

**AC-C09 — 目标验证: 同阵营被拒绝**（Logic）
GIVEN 一个 PLAYER 攻击者，WHEN 目标也是 PLAYER 阵营，THEN `execute_attack()` 返回 `AttackResult.INVALID`。阵营检查是 `execute_attack()` 内的纵深防御守卫，不仅限于 `get_valid_targets()`。

**AC-C10 — 攻击执行: 完整状态变更**（Integration）
GIVEN 攻击者在 (5,3)，目标在 (5,4) 且 HP=10、ATK=5、DEF=2，WHEN `execute_attack(attacker, target)` 被调用，THEN damage=3，`target.hp` 变为 7（take_damage 被调用），`attacker.has_acted_this_turn` 变为 `true`，`attacker.action_state` 变为 `ACTED`。

**AC-C11 — 从 SELECTED 直接攻击: 无移动**（Integration）
GIVEN 单位在 SELECTED 位于 (2,2)，敌人在 (2,3) 在 RNG=1 范围内，WHEN 玩家点击敌人，THEN 攻击执行，unit.grid_position 保持 (2,2)，状态变为 ACTED。

**AC-C12 — 从 MOVED 移动后攻击**（Integration）
GIVEN 单位移动到 (4,4)，现在处于 MOVED 状态，敌人在 (4,5) 在 RNG=1 范围内，WHEN 玩家点击敌人，THEN 攻击执行，状态变为 ACTED。

**AC-C13 — 跳过攻击: 行动已消耗，无伤害**（Logic）
GIVEN 单位在 SELECTED 或 MOVED 且瞄准激活中，WHEN 玩家按 Escape 或右键，THEN `has_acted_this_turn == true`，`action_state == ACTED`，不对任何单位调用 `take_damage()`，高亮清除。

**AC-C14 — damage_dealt 信号被发出**（Logic）
GIVEN 一次成功的攻击且 damage=3，WHEN `execute_attack()` 完成，THEN 信号 `damage_dealt(attacker, target, 3)` 被恰好发出一次，参数正确。

**AC-C15 — AttackResult 字段完整性**（Logic）
GIVEN 一次成功的攻击，WHEN `execute_attack()` 返回，THEN `AttackResult.damage` 等于计算出的伤害，`AttackResult.killed` 等于 `true` 当且仅当目标 HP 达到 0，`AttackResult.attacker` 和 `AttackResult.target` 引用正确的单位。

**AC-C16 — AttackResolver 架构**（Logic）
GIVEN `AttackResolver` 类，WHEN 被检查，THEN 它继承 `RefCounted`，调间不持有实例状态，`execute_attack()` 不产生 `take_damage()` 和单位状态写入之外的副作用。

**AC-C17 — 无反攻**（Logic）
GIVEN 攻击者 HP=10 且目标 ATK=5，WHEN 攻击者对目标执行攻击，THEN 攻击者的 HP 保持 10 —— 攻击者不受到任何伤害。

**AC-C18 — 仅单目标**（Logic）
GIVEN 攻击者在 (5,3)，两个敌人在 (5,4) 和 (5,5) 均在射程内，WHEN 攻击者攻击 (5,4)，THEN 只有该目标的 HP 变化；(5,5) 处的单位不受影响。

### B. AttackRangeResolver

**AC-C19 — 仅返回有效敌人**（Logic）
GIVEN 一张地图上有 3 个 PLAYER 单位和 2 个 ENEMY 单位（均存活），攻击者是位于 (5,5) 的 PLAYER 且 RNG=3，WHEN `get_valid_targets(attacker, map)` 被调用，THEN 仅返回 Manhattan 距离 ≤ 3 以内的 2 个 ENEMY 单位。同阵营和死亡单位被排除。

**AC-C20 — 按距离排序，同距离按 HP 排序**（Logic）
GIVEN 攻击者在 (0,0) 且 RNG=3，Enemy A 在 (0,2) HP=8，Enemy B 在 (0,1) HP=10，Enemy C 在 (0,2) HP=5，WHEN `get_valid_targets()` 被调用，THEN 顺序为: [B(d=1), C(d=2, HP=5), A(d=2, HP=8)]。最近的在前；同等距离 → HP 最低优先。

**AC-C21 — 空目标列表**（Logic）
GIVEN 一个单位且地图上无敌方单位，WHEN `get_valid_targets()` 被调用，THEN 返回 `[]`。

**AC-C22 — 对已行动单位的纯查询**（Logic）
GIVEN 一个 `has_acted==true` 的单位，WHEN `get_valid_targets()` 被调用，THEN 仍然返回射程内的敌人 —— 该函数不以 `has_acted` 为门槛。调用者（Input）拥有门槛控制权。

### C. 公式

**AC-F01 — F1: 标准伤害**（Logic）
GIVEN ATK=5, DEF=2，WHEN F1 被评估，THEN `damage = max(5−2, 1) = 3`。

**AC-F02 — F1: 保底为 1（ATK ≤ DEF）**（Logic）
GIVEN ATK=3, DEF=5，WHEN F1 被评估，THEN `damage = max(3−5, 1) = 1`。保底防止零伤害。对属性范围内全部 10 个 ATK ≤ DEF 组合验证通过。

**AC-F03 — F1: 最大伤害**（Logic）
GIVEN ATK=8, DEF=0，WHEN F1 被评估，THEN `damage = max(8−0, 1) = 8`。

**AC-F04 — F2: 射程检查 Manhattan**（Logic）
GIVEN 攻击者在 (0,0) 且 RNG=2，WHEN 对 (0,1)、(0,2)、(1,0)、(1,1) 处目标检查射程，THEN `in_range` 对全部四个为 `true`。WHEN 对 (0,3) 和 (2,2) 检查，THEN `false`。

**AC-F05 — F4: resolve_damage 纯静态**（Logic）
GIVEN ATK=5, DEF=2，WHEN `resolve_damage(5, 2)` 被调用，THEN 返回 `3`。WHEN 以相同参数调用两次，THEN 返回相同值。无状态读取，无副作用。该函数接受裸整数，而非 Unit 引用。

### D. 边界情况

**AC-E01 — 击杀: HP 达到 0**（Integration）
GIVEN 目标 HP=1，攻击者 ATK=5，目标 DEF=2，WHEN `execute_attack()` 造成 damage=3，THEN `target.take_damage(3)` 被调用，目标 HP 变为 0，`unit_died` 信号由 Unit 发出，`AttackResult.killed == true`。

**AC-E02 — 精确击杀 vs 溢出击杀**（Logic）
GIVEN 目标 HP=3，ATK=5，DEF=2（damage=3），WHEN 攻击执行: `damage == hp` → 精确击杀，HP=0，`killed=true`。GIVEN 目标 HP=2（damage=3），WHEN 攻击执行: `damage > hp` → 溢出击杀，HP=0，`killed=true`。两者产生相同结果 —— 溢出量被 `take_damage()` 中的 `clamp()` 丢弃。

**AC-E03 — 空目标列表 → 不进入瞄准模式**（Logic）
GIVEN 一个单位且 `get_valid_targets()` 返回 `[]`，WHEN Input 检查目标列表，THEN 单位直接跳到 ACTED —— 不进入瞄准模式，不渲染高亮。

**AC-E04 — null 攻击者/目标守卫**（Logic / Instrumented）
GIVEN `execute_attack(null, target)` 或 `execute_attack(attacker, null)`，WHEN 被调用，THEN 在 debug 构建中: 断言以描述性消息触发。在 release 构建中: 返回 `AttackResult.INVALID`。需要分别的测试配置。

**AC-E05 — 零伤害不可能**（Logic）
GIVEN 所有 36 个有效的 ATK×DEF 组合，范围在 [3,8]×[0,5]，WHEN 对每个组合计算 `max(atk−def, 1)`，THEN 每个结果 ≥ 1。抽查 ATK ≤ DEF 的 10 个组合 —— 全部恰好返回 1。

**AC-E06 — resolve_damage 使用超范围属性**（Logic）
GIVEN `resolve_damage(999, -5)`，WHEN 被调用，THEN 返回 `max(999−(−5), 1) = 1004`。该函数不验证属性范围 —— 它是纯数学。属性验证是 Unit 的职责。

### E. 状态机转换

**AC-S01 — SELECTED + 点击射程内敌人 → ACTED**（Logic）
GIVEN 单位在 SELECTED 位于 (2,2)，敌人在射程内的 (2,3)，WHEN 玩家点击敌人，THEN `action_state` 转换 SELECTED → ACTED，`has_acted = true`，伤害施加。

**AC-S02 — SELECTED + Esc → ACTED（跳过）**（Logic）
GIVEN 单位在 SELECTED 且瞄准激活中，WHEN 玩家按 Escape，THEN `action_state` 转换 SELECTED → ACTED，`has_acted = true`，无伤害。

**AC-S03 — MOVED + 点击射程内敌人 → ACTED**（Logic）
GIVEN 单位在 MOVED 位于 (4,4)，敌人在射程内的 (4,5)，WHEN 玩家点击敌人，THEN `action_state` 转换 MOVED → ACTED，`has_acted = true`，伤害施加。

**AC-S04 — MOVED + Esc → ACTED（跳过）**（Logic）
GIVEN 单位在 MOVED 且瞄准激活中，WHEN 玩家按 Escape，THEN `action_state` 转换 MOVED → ACTED，`has_acted = true`，无伤害。

### F. 不可测试 / 预留

**AC-U01 — 攻击者在瞄准中死亡**（UNTESTABLE — RESERVED_TIER2）
GIVEN 攻击瞄准阶段，WHEN 攻击者在选择与执行之间死亡（例如延迟伤害、反应陷阱），THEN `execute_attack()` 以 `if not attacker.is_alive: return AttackResult.INVALID` 守卫生效。MVP 不可测试 —— 无延迟伤害来源。预留守卫；当 Tier 2 引入相关机制时 AC 激活。

**AC-U02 — 目标在瞄准中位置改变**（UNTESTABLE — RESERVED_TIER2）
GIVEN 攻击瞄准阶段，WHEN 目标在选择与执行之间移动（例如强制移动、击退），THEN `execute_attack()` 在执行时重新验证 Manhattan 距离，若超出射程则拒绝。MVP 不可测试 —— 无位移机制。

**AC-U03 — F5 HTK 分析公式**（UNTESTABLE — ANALYTIC_ONLY）
HTK 不在代码中实现 —— 它是面向设计师的电子表格理性检验。在平衡审查期间验证，不通过自动化测试。

**AC-U04 — F3 可攻击瓦片数**（UNTESTABLE — DESIGN_REFERENCE）
`2*rng*(rng+1)` 是 Manhattan 环在开放网格上的数学属性。无运行时代码计算它 —— 它是 UI 容量估计的参考值。可选的手动视觉验证。

### 总结

| Category | Count | Logic | Integration | Gate | UNTESTABLE |
|----------|-------|-------|-------------|------|------------|
| 核心规则（18） | 18 | 15 | 3 | BLOCKING（18） | 0 |
| RangeResolver（4） | 4 | 4 | 0 | BLOCKING（4） | 0 |
| 公式（5） | 5 | 5 | 0 | BLOCKING（5） | 0 |
| 边界情况（6） | 6 | 5 | 1 | BLOCKING（6） | 0 |
| 状态转换（4） | 4 | 4 | 0 | BLOCKING（4） | 0 |
| 不可测试/预留 | 4 | 0 | 0 | ADVISORY | 4 |
| **总计** | **41** | **33** | **4** | — | **4** |

门控: 37 个标准为 BLOCKING，需要自动化测试。4 个在 MVP 阶段为 UNTESTABLE（已记录，不阻塞）。逻辑测试位于 `tests/unit/attack/`。集成测试位于 `tests/integration/attack/`。

## Open Questions

- **OQ1 — Map GDD 勘误（Attack 的 Map 依赖）**: Map GDD 交互表当前将 `get_neighbors()` 列为 "射程环计算" 中 Attack 对 Map 的依赖。本 GDD 确认 Attack 使用 Manhattan 距离 + `get_unit_at()`，而非 `get_neighbors()`。→ 在本 GDD 的 Dependencies 节中标记。Map GDD 修正是 consistency-check 的行动项，非 Attack 阻塞项。

- **OQ2 — Unit GDD 状态机: SELECTED → ACTED 路径**: Unit GDD 状态机表当前仅显示 IDLE → SELECTED → MOVED → ACTED。Attack GDD 新增 SELECTED → ACTED（不移动直接攻击）和瞄准取消路径。→ Unit GDD 的 `can_attack()` 和 Core Rule 7（`action_state` 在 `[SELECTED, MOVED]` 中）已经支持该机制。状态机表是描述性的，非规定性的。consistency-check 应验证双向对齐。

- **OQ3 — Manhattan 距离的所有权**: Movement GDD OQ2 询问 Manhattan 距离应放在 Movement 还是 Attack。→ 已解决: Movement GDD F2 持有公式定义。Attack GDD F2 引用它。Movement GDD 的 F2 边界注记可以更新以记录此解决方案。

- **OQ4 — `damage_floor` = 0 预留给 Tier 2**: 若未来 Tier 2 系统引入 damage floor = 0（允许 DEF 完全抵消 ATK），这应是每个单位的属性、全局常量还是状态效果覆盖？→ 推迟到 Tier 2 设计。`damage_floor` 当前是 `AttackResolver` 中的常量（值: 1），可轻松参数化。

- **OQ5 — 反攻信号接线**: `damage_dealt` 信号由 Attack 发出并预留给 Tier 2 反攻。哪个系统持有反攻逻辑？→ 推迟到 Tier 2 设计。Attack 的职责是以正确参数发出信号。反攻系统连接时无需修改 Attack。

- **OQ6 — `AttackResult.INVALID` 哨兵**: 当前 `AttackResult.INVALID` 是在前置条件失败时返回的独立哨兵值。应该是专用的 `AttackResult.is_valid() -> bool` 方法，还是 null 返回模式？→ 在实现时解决（实现细节，非设计关注点）。
