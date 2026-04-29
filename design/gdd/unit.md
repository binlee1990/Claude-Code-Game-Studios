# Unit

> **Status**: In Design
> **Author**: binlee1990 + Claude
> **Last Updated**: 2026-04-29
> **Implements Pillar**: Pillar 1 — Data-Driven (所有单位数据均为外部配置); Pillar 4 — Generic Vocabulary (HP/ATK/DEF/MOV/RNG 为跨品类 SRPG 通用术语)

## Overview

Unit 系统定义了玩家指挥和战斗的游戏棋子：每个单位是一个具名实体，携带五项属性 —— `HP`、`ATK`、`DEF`、`MOV`、`RNG` —— 并属于两个阵营之一（Player 或 Enemy，MVP 阶段内嵌于本系统）。单位以网格坐标放置在 Map 上，按照 Programmer Art Functional 调色板渲染为纯色几何形状并附带 HP 文字抬头显示。Unit 系统是 Core 层的稳定接口：五个下游系统（Turn System、Movement、Attack、Victory、AI）消费 Unit 的公共 API，因此本 GDD 不仅定义了单位*是什么*，更定义了每个系统读取的契约。没有单位就没有行动者 —— 棋盘将是一张空网格，无人可移动、攻击或获胜。

## Player Fantasy

Unit 系统的幻想是**通过决策获得所有权**。单位没有名字、没有背景故事、没有职业 —— 它是你的，因为*你*决定了它站在哪里、何时移动、攻击谁。五个透明的数字 —— HP、ATK、DEF、MOV、RNG —— 是一份承诺：MOV 5 意味着 5 格行动范围，HP 8 意味着 8 点生存值，每一点减少都是已经做出的选择的可见后果。当一个单位倒下，损失的不是叙事性的悲伤，而是战术性的收缩：更少的棋子、更少的选项、更少的威胁投射。幻想存在于悬停在一格上并精确知晓 —— 完全透明 —— 点击后会发生什么的那一刻。没有隐藏修正值，没有骰子。分量在决策本身，不在未知之中。

## Detailed Design

### Core Rules

1. **属性（Stats）**: 每个单位携带五项整数属性。所有属性均为数据驱动 —— 定义在 `UnitStats` 自定义 Resource（`.tres`）中，绝不硬编码。

| Stat | Symbol | Type | Default | Range | Description |
|------|--------|------|---------|-------|-------------|
| Hit Points | `hp` / `max_hp` | int | 10 | 5–20 | 当前和最大生命值。`hp ≤ 0` = 死亡 |
| Attack | `atk` | int | 5 | 3–8 | DEF 减免前的原始伤害 |
| Defense | `def` | int | 2 | 0–5 | 固定伤害减免值 |
| Movement | `mov` | int | 4 | 2–6 | BFS 移动范围半径（格数） |
| Range | `rng` | int | 1 | 1–3 | 攻击目标的曼哈顿距离 |

`hp` 为可变字段（当前生命值）；其余属性在创建后只读。`max_hp` 为恒定上限。

2. **阵营（Faction）**: 每个单位属于且仅属于一个阵营 —— `PLAYER` 或 `ENEMY`。定义为独立 `enum`，位于 `Faction.Type`（单独文件 `src/core/faction.gd`，不嵌套在 Unit 中）。阵营决定：
   - 视觉颜色：Player = `#3B82F6`（蓝色），Enemy = `#EF4444`（红色）
   - 回合资格：仅当前活动阵营的单位可以行动
   - 可攻击性：单位只能以敌方阵营的单位为目标

3. **单位标识（Unit Identity）**: 每个单位在实例化时获得自动生成的 `unit_id: String`（`"unit_0"`、`"enemy_2"` 等）。供 debug 叠加层和未来的存档/读档使用。正常游戏过程中不显示。

4. **Unit 场景结构**: Unit 为 `Node2D` 根场景（`Unit.tscn`），包含两个子节点：
   - `ColorRect`（48×48px，在 64×64 瓦片内居中）—— 阵营颜色的纯色矩形
   - `Label`（偏移 `Vector2(0, -40)`，位于单位中心上方）—— HP 显示，格式为 `"HP: 8/10"`

5. **单位数据（Unit Data）**: `UnitStats` 自定义 Resource（`.tres`）持有原型属性块。Unit 在 `_ready()` 时读取其 `.tres`。这实现了数据与表现的分离 —— 同一个 `soldier.tres` 可应用于多个 Unit 实例。

6. **网格位置（Grid Position）**: Unit 拥有 `grid_position: Vector2i`（row, col）。世界像素坐标通过 Map 的 `tile_center(grid_position)` 推导。Unit 不在内部计算像素位置。

7. **行动状态（Action State）**: Unit 追踪 `has_acted_this_turn: bool`。单位完成移动+攻击动作后设为 `true`。由 Turn System 在下个阵营回合开始时通过 `reset_action_state()` 重置为 `false`。

8. **死亡（Death）**: 当 `hp` 降至 ≤ 0 时：
   - Unit 发出 `unit_died(unit)` 信号。
   - Map（监听者）调用 `remove_unit(coord)` 和 `queue_free()`。
   - Turn System 和 Victory（监听者）处理死亡事件以推进回合流程和胜负判定。
   - Unit 从不自我调用 `queue_free()`。

9. **视觉状态映射**:
   - Normal（idle、存活、尚未行动）：完整阵营颜色、完整不透明度
   - Acted（本回合已行动）：去饱和 —— modulate 为 `Color.GRAY`、50% 透明度

### States and Transitions

| State | Meaning | Valid Transitions |
|-------|---------|-------------------|
| `IDLE` | 存活、未被选中、可能已行动或未行动 | → SELECTED（玩家点击单位） |
| `SELECTED` | 当前为输入选中的活跃选择 | → MOVED（移动确认），→ ATTACK_TARGETING（移动后选择攻击） |
| `MOVED` | 单位已移动；正在选择攻击目标或跳过 | → ACTED（攻击确认或跳过） |
| `ACTED` | 移动+攻击已消耗；`has_acted = true` | → IDLE（Turn System 在新阵营回合时重置） |
| `DEAD` | `hp ≤ 0`；已从棋盘移除 | 终结状态 —— 单位已被 `queue_free()` |

状态转换由 Input 系统驱动（click → select，click → move/attack）。Unit 将当前状态存储为 `action_state: enum`，并暴露前置条件检查：
- `can_be_selected()` → `is_alive AND faction == active_faction AND NOT has_acted`
- `can_move()` → `action_state in [SELECTED]`
- `can_attack()` → `action_state in [SELECTED, MOVED] AND rng ≥ distance_to_target`

### Interactions with Other Systems

| Downstream System | What Unit Exposes | Data Direction |
|---|---|---|
| **Turn System** | `faction`、`has_acted_this_turn`、`reset_action_state()`、`unit_died` 信号 | Turn → Unit（重置）；Unit → Turn（死亡信号） |
| **Movement** | `mov`、`grid_position`、`set_grid_position()` | Movement → Unit（位置写入） |
| **Attack** | `atk`、`def`、`rng`、`hp`、`take_damage(amount)`、`is_alive` | Attack → Unit（HP 写入） |
| **Victory** | `faction`、`is_alive`、`unit_died` 信号 | Unit → Victory（轮询 + 信号） |
| **AI** | 所有属性、`grid_position`、等价于 `can_be_selected()` 的接口 | AI → Unit（通过 Movement/Attack 代理） |
| **UI / Input** | `hp`/`max_hp`、`faction`、`grid_position`、`has_acted_this_turn`、`action_state` | Unit → UI（只读） |

## Formulas

### F1: take_damage

`hp = clamp(hp - amount, 0, max_hp)`

| Variable | Symbol | Type | Range | Description |
|----------|--------|------|-------|-------------|
| Current HP | hp | int | [0, max_hp] | 可变当前生命值 |
| Damage amount | amount | int | [1, ∞) | DEF 减免后的原始伤害（由 Attack 计算） |
| Max HP | max_hp | int | [5, 20] | 恒定上限 |

**输出范围**: hp ∈ [0, max_hp]。**示例**: 一个 hp=8、max_hp=10 的单位受到 `take_damage(5)` → hp 变为 3。`take_damage(12)` → hp 变为 0，发出 `unit_died` 信号。

### F2: is_alive / is_dead

`is_alive = (hp > 0)` / `is_dead = (hp ≤ 0)`

| Variable | Type | Range | Description |
|----------|------|-------|-------------|
| hp | int | [0, max_hp] | 当前生命值 |

布尔检查，供 Turn System、Movement（不能移动已死亡单位）、Victory（阵营全灭判定）和 UI/HUD 消费。

### F3: clamp_hp

`hp = clamp(hp, 0, max_hp)`

每次 HP 修改后强制执行 —— 包括伤害和治疗。任何超出范围的 HP 都不会被可见。

### F4: stat validation（`.tres` 加载时验证）

对于 `{max_hp: [5,20], atk: [3,8], def: [0,5], mov: [2,6], rng: [1,3]}` 中的每个属性 `S`：在 `.tres` 加载时断言 `S` 在允许范围内。超出范围的数据为硬失败 —— 错误数据是 bug，不静默修正。

### F5: heal（预留接口，MVP 未使用）

`hp = clamp(hp + amount, 0, max_hp)`

已声明但 MVP 阶段未接入。使未来的治疗系统无需修改 Unit 内部实现。

> **属于其他系统的内容**: `damage = max(ATK - DEF, 1)` 属于 Attack GDD（Module 5）。距离计算（曼哈顿距离）属于 Movement。阵营全灭计数属于 Victory。

## Edge Cases

- **若对已死亡单位调用 `take_damage(amount)`**: 立即返回，不发出信号。入口处以 `if not is_alive: return` 守卫。

- **若传入 `take_damage` 的 `amount ≤ 0`**: 断言 `amount > 0`。负伤害绕过了未接入的 `heal()` 接口 —— 不允许。

- **若恰好击杀（`amount == hp`）**: hp 变为 0，`is_alive` → false，`unit_died` 发出一次。无需特殊处理 —— `clamp` 自然产生 0。

- **若 `.tres` 属性超出声明范围**: `_ready()` 时 `assert(false)`，消息中注明文件名、属性名、值和允许范围。Unit 不进入场景树。

- **若 `.tres` 文件丢失或损坏**: `ResourceLoader` 返回 null。Unit 记录错误并在进入场景树前 `queue_free()`。

- **若玩家点击处于 SELECTED 或 ACTED 状态的单位**: `can_be_selected()` 额外检查 `action_state == IDLE`。非 IDLE 状态的单位拒绝选中。

- **若玩家尝试以同阵营单位作为攻击目标**: `can_attack()` 包含 `target.faction != self.faction`。同阵营目标被拒绝。

- **若 Turn System 对仍处于 SELECTED/MOVED 状态的单位调用 `reset_action_state()`**: 状态被强制设为 IDLE，无论当前状态如何。回合转换覆盖任何进行中的动作。

- **若外部代码直接设置 `action_state` 或只读属性**: 写入时断言失败。仅 `hp`、`grid_position`、`has_acted_this_turn` 和 `action_state`（通过定义的流程）可变。

- **若 `max_hp` 意外为 0**: 属性验证在加载时拒绝（下限为 5）。正常操作中不可能出现。

- **若 `unit_id` 冲突**: 自动生成使用单调递增计数器，非随机生成。同一帧内实例化的两个单位仍获得唯一 ID。

- **若两个单位被放置在同一瓦片上**: Map 的 `place_unit()` 通过占用检查拒绝 —— Unit 信任 Map，不自我验证同格单位。

- **若 `grid_position` 设置在 Map 边界外**: Map 拒绝。Unit 从不自我定位或自我验证 Map 边界。

- **若运行时修改阵营（faction）**: 不存在 setter。阵营仅可在初始化时设定。写入时断言失败。

## Dependencies

### Upstream Dependencies

| System | Type | Interface Consumed | Notes |
|--------|------|--------------------|-------|
| **Map / Coordinates** | Hard | `grid_to_world()`、`tile_center()`、`place_unit()`、`remove_unit()`、`is_walkable()` | 没有 Map，Unit 无法存在于棋盘上 |

### Downstream Dependencies（依赖 Unit 的系统）

| System | Type | Interface Exposed | Notes |
|--------|------|-------------------|-------|
| **Turn System** | Hard | `faction`、`has_acted_this_turn`、`reset_action_state()`、`is_alive`、`unit_died` 信号 | 按阵营遍历单位，重置行动状态 |
| **Movement** | Hard | `mov`、`grid_position`、`set_grid_position()`、`is_alive` | BFS 范围半径，位置写入 |
| **Attack** | Hard | `atk`、`def`、`rng`、`hp`、`take_damage()`、`is_alive`、`faction` | 伤害计算，目标验证 |
| **Victory** | Hard | `faction`、`is_alive`、`unit_died` 信号 | 阵营全灭轮询 |
| **AI** | Hard | 所有属性、`grid_position`、`faction`、`is_alive`、`has_acted_this_turn` | AI 读取单位状态以决策行动 |
| **UI / Input** | Hard | `hp`/`max_hp`、`faction`、`grid_position`、`action_state`、`has_acted_this_turn`、`unit_id` | 渲染、HP 标签、选择、debug 叠加层 |

所有六个下游依赖均为 **hard** —— 没有 Unit，任何下游系统都无法运作。

### External Dependencies

| Dependency | Type | Notes |
|------------|------|-------|
| `UnitStats` Resource (.tres) | Data | 位于 `assets/data/units/` 的按原型属性块。符合 Pillar 1。 |
| `Unit.tscn` | Scene | Node2D 根场景模板。视觉结构与属性数据解耦。 |
| `Faction.Type` enum | Code | 独立文件 `src/core/faction.gd`。不嵌套在 Unit 中 —— 支持 Tier 2 提取。 |

## Tuning Knobs

| Knob | Location | Safe Range | What Happens If Too Low | What Happens If Too High | Notes |
|------|----------|------------|------------------------|------------------------|-------|
| `max_hp` | UnitStats.tres | [5, 20] | 单位被任何攻击者一击击杀 —— 没有战术深度 | 单位变成子弹海绵，对局拖沓 | 默认 10 在面对 ATK 5 时提供 2-3 次被击存活 |
| `atk` | UnitStats.tres | [3, 8] | 低于 3: DEF 2 的单位只受 1 点伤害 —— 战斗感觉徒劳 | 高于 8: 对 HP 10 的单位可一击击杀 | 默认 5 在面对 HP 10、DEF 2 时造成 2-3 次攻击击杀 |
| `def` | UnitStats.tres | [0, 5] | 0 DEF: ATK = 原始伤害，无减免层 | 5 DEF: 仅 ATK ≥ 7 能造成超过 2 点伤害 —— 防御主导 | 默认 2 吸收默认 ATK 5 的 40% |
| `mov` | UnitStats.tres | [2, 6] | 2 格: 单位几乎无法重新站位，地图感觉幽闭 | 6 格: 单位在 2 回合内穿越默认 16×12 地图，距离失去意义 | 默认 4 是标准的 SRPG 移动值 |
| `rng` | UnitStats.tres | [1, 3] | 1: 仅近战 —— 单位必须相邻才能攻击 | 3: 从中心可攻击半张棋盘 —— 站位变得无关紧要 | MVP 默认 1（近战）；rng 2–3 的远程原型属于 Tier 2 |

**Knob 交互关系**:
- `atk` vs `def`: damage = `max(atk − def, 1)`。全局提升 `def` 使 `atk` 失去意义。全局提升 `atk` 使 `def` 无关紧要。两者共同定义杀伤力曲线。
- `mov` vs `rng`: 威胁半径 = `mov + rng`。一个 MOV 6 + RNG 3 的单位从起始位置投射 9 格威胁 —— 几乎覆盖整个地图宽度。
- `max_hp` vs `atk − def`: 击杀所需命中次数 = `ceil(max_hp / max(atk − def, 1))`。调整 HP 而不检查此比例可能产生不死单位或玻璃大炮。

## Visual/Audio Requirements

按 Programmer Art Functional 锚点。无音频。

- **单位身体**: 48×48px `ColorRect`，在 64×64 瓦片内居中。阵营颜色纯色矩形 —— Player `#3B82F6`（蓝色），Enemy `#EF4444`（红色）。
- **HP 标签**: `Label` 节点偏移 `Vector2(0, -40)`，位于单位中心上方。格式: `"HP: 8/10"`。字体: Godot 默认字体（MVP 无自定义字体）。
- **行动状态视觉表现**: 已行动单位 → modulate 为 `Color.GRAY`、50% 透明度。
- **死亡**: 无尸体，无死亡动画。`unit_died` 信号后单位被 `queue_free()`。
- **选中高亮**: 推迟至 UI / Input GDD（高亮叠加层属于该系统的范围）。

> 📌 **资源规格** —— 视觉需求已定义。在美术圣经批准后运行 `/asset-spec system:unit` 以生成每个单位的视觉描述和生成提示。

## UI Requirements

本系统不拥有任何 UI。单位选中、HP 显示叠加层和行动菜单由 UI / Input GDD 所有。HP Label 子节点是 Unit 拥有的渲染元素，非 UI 屏幕。

## Acceptance Criteria

### Core Rules

**AC-C1 — 属性数据驱动**（Logic）
GIVEN 一个 UnitStats.tres，其中 max_hp=10, atk=5, def=2, mov=4, rng=1，WHEN Unit 在 `_ready()` 时加载它，THEN hp==max_hp==10 且所有五项属性完全匹配 `.tres`。无硬编码默认值残留。

**AC-C2 — 阵营颜色**（Visual）
GIVEN 一个 PLAYER Unit，THEN ColorRect.modulate 为蓝色（`#3B82F6`）。GIVEN 一个 ENEMY Unit，THEN 红色（`#EF4444`）。

**AC-C3 — unit_id 单调递增**（Logic）
GIVEN 零个现有单位，WHEN 实例化三个 Unit，THEN unit_id 依次为 `"unit_0"`、`"unit_1"`、`"unit_2"` —— 单调递增，无冲突。

**AC-C4 — 场景结构**（Visual）
GIVEN 在编辑器中打开 Unit.tscn，WHEN 检查场景树，THEN 根节点为 Node2D，恰好有两个子节点: 一个 ColorRect（48×48）和一个位于中心上方的偏移 Label。

**AC-C5 — .tres 实例隔离**（Logic）
GIVEN 两个 Unit 均加载同一个 soldier.tres，WHEN Unit A 受到 `take_damage(4)` 导致 hp 10→6，THEN Unit B 的 hp 仍为 10。每个 Unit 独立持有可变 hp。

**AC-C6 — grid_position 所属权**（Logic）
GIVEN 一个 Unit 放置在网格 (2,3) 处，WHEN 读取 `unit.grid_position`，THEN `Vector2i(2,3)`。Unit 不包含任何像素运算 —— 世界坐标完全通过 Map 推导。

**AC-C7 — has_acted 生命周期**（Logic）
GIVEN 一个新创建的 Unit，THEN `has_acted_this_turn == false`。移动+攻击完成后，THEN `true`。Turn System 调用 `reset_action_state()` 后，THEN `false`。

**AC-C8 — 死亡链**（Integration）
GIVEN 一个 hp=1 的 Unit，WHEN `take_damage(3)`，THEN hp→0，`unit_died` 恰好发出一次，Map 移除占用，随后 `queue_free()`。信号在节点释放前发出。

**AC-C9 — 视觉去饱和**（Visual）
GIVEN 一个尚未行动的 Unit，THEN 完整阵营颜色 + 完整不透明度。GIVEN `has_acted_this_turn == true`，THEN 去饱和（`Color.GRAY`，50% 透明度）。

### State Machine

**AC-S1 — can_be_selected 完整前置条件**（Logic）
GIVEN 一个满足 `is_alive AND faction==active_faction AND NOT has_acted AND action_state==IDLE` 的 Unit，WHEN `can_be_selected()`，THEN `true`。缺失任一条件 → `false`。

**AC-S2 — can_move / can_attack**（Logic）
GIVEN 处于 SELECTED 的 Unit，THEN `can_move()` → `true`。GIVEN 处于 SELECTED 或 MOVED + 敌方目标在 `rng` 范围内，THEN `can_attack()` → `true`。GIVEN 同阵营目标，THEN 无论何种状态均为 `false`。

**AC-S3 — reset_action_state 覆盖**（Logic）
GIVEN 处于 SELECTED 或 MOVED 的 Unit，WHEN `reset_action_state()`，THEN 状态强制设为 IDLE。

### Formulas

**AC-F1 — take_damage clamp + 死亡守卫**（Logic）
GIVEN hp=8 max_hp=10，WHEN `take_damage(5)` → hp=3。WHEN 在 hp=3 时 `take_damage(12)` → hp=0 + `unit_died`。GIVEN hp=0，WHEN `take_damage(any)`，THEN 立即返回，不发出信号。

**AC-F2 — is_alive / is_dead**（Logic）
GIVEN hp=5，THEN `is_alive()==true`，`is_dead()==false`。GIVEN hp=0，THEN 相反。hp=1 存活；hp=0 死亡。无歧义。

**AC-F3 — clamp_hp 强制执行**（Logic）
GIVEN hp=8 max_hp=10，WHEN `heal(5)`，THEN hp=10（已封顶，非 13）。任何 HP 修改后，hp ∈ [0, max_hp]。

**AC-F4 — .tres 验证**（Logic）
GIVEN UnitStats.tres 中 atk=12（超出 [3,8] 范围），WHEN 加载时，THEN 断言失败，消息中注明文件名/属性名/值/范围。GIVEN 缺失/损坏的 .tres，THEN 记录错误 + `queue_free()`。

**AC-F5 — heal() 预留**（Logic）
GIVEN Unit 类，WHEN 检查源码，THEN `heal(amount: int)` 方法存在，实现为 `hp = clamp(hp+amount, 0, max_hp)`，但未接入任何 MVP 调用者。

### Edge Case Guards

**AC-E1 — 只读属性修改守卫**（Logic）
GIVEN 一个存活 Unit，WHEN 外部代码尝试直接设置 atk/def/mov/rng/max_hp/faction，THEN 断言失败。仅 hp、grid_position、has_acted 和 action_state 可写。

**AC-E2 — 负/零伤害拒绝**（Logic）
GIVEN `take_damage(0)` 或 `take_damage(-3)`，THEN 断言失败: "amount must be > 0"。

## Open Questions

- **OQ1 — UnitStats.tres 字段命名**: `.tres` 是否应将 `max_hp`（常量）作为导出字段名，在 `_ready()` 时初始化 `hp`？→ 留待实现阶段确定。
- **OQ2 — Faction 提取时机**: MVP 阶段 Faction enum 内嵌于 Unit。Tier 2 提取为独立 Faction 系统需要移动 `src/core/faction.gd` —— 这是一次零逻辑变更的移动。提取是否应在任何 Tier 2 GDD 编写之前完成？→ 推迟至 Tier 2 规划。
- **OQ3 — heal() 接入**: `heal(amount)` 接口已预留但 MVP 未接入。哪个 Tier 2/3 系统首先使用它？→ 推迟至未来 GDD（可能是 Class Triangle 或 XP/Level-up）。
- **OQ4 — unit_id 计数器持久化**: 当前为每会话单调递增计数器。若存档/读档（Tier 3）需要持久化 ID，计数器必须变为存档感知。→ 推迟至 Save/Load GDD。
