# Movement

> **Status**: In Design
> **Author**: binlee1990 + Claude
> **Last Updated**: 2026-04-29
> **Implements Pillar**: Pillar 2 — System Orthogonality（BFS 在 Map 网格上计算，读取 Unit 属性，输出结果集）

## Overview

Movement 是 SRPG 骨架中玩家的核心操作动词：点击单位，蓝色可达瓦片高亮从单位位置向外扩散；悬停目标瓦片，精确的 von Neumann 路径预览浮现；再次点击确认。系统读取 `unit.mov` 作为 BFS 半径，查询 Map 的瓦片可行走性和占用状态，计算出精确的可达瓦片集合和到每个瓦片的最短路径。移动采用瞬移方式 —— 单位的 `grid_position` 即时更新，与 MVP 的"无动画"立场一致。每一个高亮的瓦片都是一个保证：如果是蓝色，你就能在 ≤ MOV 步数内到达。没有 Movement，棋盘只是一幅静态的立体模型 —— 单位无法换位、无法拉近距离、无法侧翼包抄。Movement 是 Turn System 所管辖的每个行动的前半部分。

## Player Fantasy

Movement 是骨架中最具触感的交互。点击单位，棋盘做出回应 —— 蓝色瓦片向外扩散，每步 MOV 一圈，每个瓦片都是一个保证：如果是蓝色，你就能到达。悬停目标瓦片，精确的 von Neumann 路径立即浮现。再次点击，单位瞬间就位。没有动画，没有等待 —— 棋盘以鼠标的速度响应。点击、看到、确认。

## Detailed Design

### Core Rules

1. **BFS 范围计算**：Movement 通过广度优先搜索（BFS）从 `unit.grid_position` 出发计算可达瓦片。每一步扩展调用 `Map.get_neighbors(coord)`（4 邻域 von Neumann），通过 `Map.is_walkable(coord)` 过滤，并以 `unit.mov` 为最大深度。MVP 中所有瓦片的移动代价均为 1（无地形效果）。BFS 使用 `Dictionary[Vector2i, Vector2i]` 作为父节点映射，使用 `Dictionary[Vector2i, int]` 作为距离映射。起始瓦片特殊处理：在扩展前加入已访问集合，因为单位自身占用的瓦片 `is_walkable()` 会返回 false。BFS 结果以不可变的 `MovementResult` RefCounted 返回。

2. **可达集**：`{通过可行走瓦片、在 ≤ MOV 步数内的瓦片}`。包含起始瓦片（0 步，依据 Rule 1 的特殊处理）。排除阻挡瓦片、障碍物瓦片及其他单位占用的瓦片（依据 `Map.is_walkable()`）。死亡单位原先占用的瓦片变为可行走 —— 死亡单位在下一次 BFS 运行前已从占用表中移除。

3. **路径计算**：对于任意可达瓦片，路径从 BFS 父节点映射中惰性重建：从目标回溯父节点指针到起点，然后反转结果。由于 BFS 按距离递增顺序访问瓦片，第一个记录的父节点是若干条等长最短路径中的一条。返回的路径为 `Array[Vector2i]`，从起点到目标（含两端）。路径重建复杂度为 O(path_length) ≤ O(MOV) ≤ 6 次字典查找，实际为 O(1)。

4. **移动执行**：当玩家确认目标瓦片时，Input 调用 `Map.move_unit(unit, from, to)`。这是 Map 的原子方法（见 Map Edge Cases OQ3），在单次操作中更新 `_occupancy` 和 `unit.grid_position`。Movement 不执行移动 —— 它只计算可达性。Input 是协调者。

5. **原地移动（0 步）**：点击单位自身的瓦片（起始瓦片，距离 0）是合法移动。单位进入 MOVED 状态但位置不变，随后进入攻击瞄准阶段。这实现了"原地攻击"——SRPG 的标准行为。

6. **移动后状态**：`Map.move_unit()` 成功后，Input 将 `unit.action_state` 设为 MOVED（Unit GDD 状态机：SELECTED → MOVED）。Movement 不设置 `has_acted_this_turn` —— 该标记在完整的移动+攻击动作完成后由 Input / Turn System 设置。

7. **悬停预览**：当玩家悬停在可达集内的瓦片上时，Input 调用 `MovementResult.get_path_to(tile)` 获取路径。UI 以不同的高亮颜色（例如更亮的蓝色或青色）渲染路径瓦片。当光标离开可达集时，Input 清除预览。Movement 仅提供数据；UI / Input 负责渲染。

8. **高亮显示**：所有可达瓦片以蓝色高亮显示（Programmer Art Functional 调色板）。起始瓦片以不同方式渲染（例如深蓝色）。路径预览瓦片使用第三种颜色（例如青色）。高亮渲染完全由 UI / Input 负责 —— Movement 仅提供 `MovementResult` 数据对象。

9. **约束条件**：
   - 单位必须处于 SELECTED 状态才能开始移动（来自 Unit GDD 的 `can_move()` 前置条件）。
   - 单位必须存活（`is_alive == true`）。
   - 单位必须属于当前行动阵营（由 Input 而非 Movement 强制执行）。
   - 移动不能穿过阻挡、障碍物或已占用的瓦片。BFS 通过 `Map.is_walkable()` 确保此约束。
   - Movement 计算是纯函数 —— 不产生对 Map、Unit 或任何其他系统的副作用。

### Movement Flow

```
1. 玩家点击单位
   → Input 检查 unit.can_be_selected()
   → unit.action_state = SELECTED

2. 计算可达区域
   → result = MovementResolver.compute_reachable(unit, map)
   → 返回 MovementResult（可达瓦片 + 父节点映射）

3. 高亮可达瓦片
   → UI 读取 result.get_reachable_tiles()
   → 将所有瓦片渲染为蓝色

4. 玩家悬停瓦片
   → 若瓦片在可达集中：path = result.get_path_to(tile)
   → UI 高亮路径瓦片

5. 玩家点击可达瓦片
   → Input 调用 Map.move_unit(unit, unit.grid_position, clicked_tile)
   → unit.action_state = MOVED
   → UI 清除所有高亮

6. 取消（取消选中）
   → 玩家按 Escape 或右键
   → Input 将 unit.action_state 重置为 IDLE
   → Input 清除高亮（MovementResult 丢弃）
```

### MovementResult API

`MovementResult` 是由 `MovementResolver.compute_reachable()` 返回的不可变 RefCounted：

| Method | Returns | Description |
|--------|---------|-------------|
| `get_reachable_tiles()` | `Array[Vector2i]` | MOV 步数内所有可达瓦片。含起始瓦片。 |
| `get_path_to(target: Vector2i)` | `Array[Vector2i]` | 从起点到目标的最短路径（起点 → ... → 目标，含两端）。目标不可达时返回空数组。 |
| `get_distance_to(target: Vector2i)` | `int` | 到达目标的步数。目标不可达时返回 -1。 |
| `get_start_tile()` | `Vector2i` | 单位的起始位置。 |

### Interactions with Other Systems

| System | Direction | Data Flow | Interface |
|--------|-----------|-----------|-----------|
| **Map** | Upstream（读取） | Movement 查询网格拓扑 | `Map.get_neighbors(coord)`, `Map.is_walkable(coord)` —— BFS 边界扩展和过滤 |
| **Map** | Upstream（写入，经由 Input） | Input 执行移动 | `Map.move_unit(unit, from, to)` —— 原子占用 + 位置更新。由 Input 而非 Movement 调用 |
| **Unit** | Upstream（读取） | Movement 读取单位状态 | `unit.mov: int` —— BFS 半径。`unit.grid_position: Vector2i` —— BFS 起点。`unit.is_alive: bool` —— 死亡单位不可移动。`unit.action_state` —— 必须为 SELECTED |
| **Unit** | Downstream（写入，经由 Input） | Input 更新单位状态 | `unit.grid_position = to`（在 `Map.move_unit()` 内部）。`unit.action_state = MOVED`（移动成功后由 Input 设置） |
| **UI / Input** | Downstream（数据） | Movement 提供计算结果 | `MovementResult` —— 可达瓦片、路径、距离。UI 读取用于高亮渲染 |
| **UI / Input** | Upstream（调用） | Input 调用计算 | `MovementResolver.compute_reachable(unit, map) -> MovementResult` —— 单位进入 SELECTED 时调用 |
| **Turn System** | Indirect | Movement 受回合状态约束 | Input 在允许移动前强制检查 `active_faction` 匹配和 `current_state == FACTION_PHASE_ACTIVE`。Movement 不直接引用 Turn System |
| **Attack** | Indirect | Movement 触发攻击阶段入口 | 单位进入 MOVED 状态后，Input 转换到攻击瞄准阶段。Movement 与 Attack 无直接依赖 |

## Formulas

### F1: BFS 可达集

BFS 可达集公式定义为：

`reachable = BFS(start = unit.grid_position, max_depth = unit.mov, neighbors_fn = Map.get_neighbors, walkable_fn = Map.is_walkable)`

**Variables:**

| Variable | Symbol | Type | Range | Description |
|----------|--------|------|-------|-------------|
| 起始瓦片 | start | Vector2i | 地图范围内的瓦片 | unit.grid_position |
| 移动半径 | mov | int | [2, 6] | 来自 UnitStats 的 unit.mov |
| 边界队列 | queue | Array[Vector2i] | [1, ~85] | BFS 扩展队列，最大尺寸 = von Neumann 菱形面积 |
| 父节点映射 | parent | Dictionary[Vector2i, Vector2i] | [0, ~85] 条目 | 瓦片 → 父瓦片，用于路径重建 |
| 距离映射 | dist | Dictionary[Vector2i, int] | [0, ~85] 条目 | 瓦片 → 距起点的步数 |

**Output:** `MovementResult`，包含所有 `dist[tile] ≤ mov` 且 `is_walkable(tile) == true` 的瓦片。起始瓦片豁免可行走性检查（单位占用了自己的瓦片）。

**Performance:** 32×32 开阔网格上 MOV=6 的最坏情况：约 85 个瓦片被访问，约 340 次邻域查询。在 GDScript 中预期 <0.5ms —— 远在 16.6ms 帧预算之内。

**Example:** 单位在 (5, 5)，MOV=4，开阔地图上 → 可达集为半径 4 的 von Neumann 菱形，包含 `2×4×(4+1) + 1 = 41` 个瓦片。

### F2: Manhattan 距离

Manhattan 距离公式定义为：

`manhattan(a, b) = |a.row − b.row| + |a.col − b.col|`

**Variables:**

| Variable | Symbol | Type | Range | Description |
|----------|--------|------|-------|-------------|
| 瓦片 A | a | Vector2i | 在地图范围内 | 第一个瓦片坐标 |
| 瓦片 B | b | Vector2i | 在地图范围内 | 第二个瓦片坐标 |
| 距离 | result | int | [0, map_cols + map_rows] | 以瓦片步数为单位的 Manhattan 距离 |

**Output Range:** 矩形地图上为 [0, map_cols + map_rows − 2]。

**Usage:** 悬停路径计算前的快速越界排除。若 `manhattan(unit_pos, hovered_tile) > unit.mov`，该瓦片必定不可达（必要条件，非充分 —— 阻挡瓦片可能进一步限制可达性）。

**Example:** 单位在 (5, 5)，悬停瓦片在 (5, 9) → `manhattan = |5−5| + |9−5| = 4`。因为 MOV ≥ 4，该瓦片可能可达（由 BFS 确认）。

### F3: 路径步数

路径步数公式定义为：

`path_length(target) = dist[target]`

其中 `dist` 是 F1 的 BFS 距离映射。

**Variables:**

| Variable | Symbol | Type | Range | Description |
|----------|--------|------|-------|-------------|
| 目标瓦片 | target | Vector2i | 在地图范围内且可达 | 目标瓦片 |
| 距离 | dist[target] | int | [0, mov] | 从起点到目标的步数 |

**Output Range:** [0, mov]。起始瓦片为 0。最远可达瓦片最大为 `mov`。

**目标不可达时的行为:** `dist[target]` 未定义（键不在字典中）。`MovementResult.get_distance_to()` 返回 -1。

**Example:** 单位在 (5, 5)，目标在 (5, 9)，在开阔地形上通过 4 步向东移动到达 → `path_length = 4`。

> **归属说明**：Manhattan 距离公式（F2）作为工具函数归属于 Movement 系统，但"Manhattan 距离"概念也被 Attack 系统所使用（目标射程验证）。Attack GDD 可以引用此公式或定义自己的射程计算 —— 由 Attack GDD 编写时确定该公式的最终归属。Movement GDD 在此定义 F2 用于路径排除目的。

## Edge Cases

### 前置条件违规

- **对死亡单位调用 `compute_reachable()`**：返回空 `MovementResult`。`get_reachable_tiles()` 返回 `[]`。`get_start_tile()` 返回哨兵值 `Vector2i(-1, -1)`。不崩溃 —— 调用方负责在调用前检查 `unit.is_alive`。

- **`map` 引用为 null**：返回空 `MovementResult`。不崩溃。调用方（Input）确保 Map 在移动开始前已加载。

- **`unit.grid_position` 超出地图边界**：BFS 信任 `Map.get_neighbors()` 的边界过滤 —— 越界起始坐标产生 0 个邻域。结果：`{start}`（仅该瓦片）。Movement 不重复做边界检查；Map 是权威来源。

- **在 `unit.action_state != SELECTED` 时调用**：Movement 是纯函数 —— 它计算可达性而不关心单位状态。调用方（Input）负责前置条件执行。若状态错误，结果有效但被忽略。

### BFS 退化结果

- **仅起始瓦片可达**（所有邻域被阻挡，或 MOV 太低无法到达任何可行走邻域）：可达集 = `{start_tile}`。单位仍可确认原地移动（0 步，Core Rule 5）。路径预览仅显示起始瓦片。这不是错误 —— 是有效的战术情况（例如单位被困在角落）。

### TOCTOU 竞争

- **目标瓦片在 BFS 计算与移动执行之间被占用**：`Map.move_unit()` 拒绝本次移动（Map Edge Case —— 已占用的坐标返回 false）。Movement 不检测也不处理此情况 —— 这是已记录的交界点。Input 必须重新计算 BFS 或向玩家显示"瓦片已占用"反馈。

### API 边界情况

- **对起始瓦片调用 `get_path_to(start_tile)`**：返回 `[start_tile]`（单元素数组），非空。距离 = 0。

- **对起始瓦片调用 `get_distance_to(start_tile)`**：返回 `0`，非 `-1`。

### 边界条件

- **单位位于 8×8 地图（最小）的角落瓦片，MOV=6**：BFS 自然地受地图边缘约束。在 `(0,0)` 处，最大可达瓦片数 ≈36（被两条边界裁剪的半菱形）。`get_neighbors()` 对角落瓦片返回 2 —— BFS 自然适应。无需特殊处理。

## Dependencies

### Upstream Dependencies

| System | Type | Interface Consumed | Notes |
|--------|------|--------------------|-------|
| **Map** | Hard | `get_neighbors(coord)`, `is_walkable(coord)`, `move_unit(unit, from, to)` | BFS 拓扑查询 + 占用过滤。`move_unit()` 在 Movement 计算之后由 Input 调用，不由 Movement 直接调用。`move_unit()` 在 Map Edge Cases OQ3 中记录为必需的原子方法。 |
| **Unit** | Hard | `unit.mov: int`, `unit.grid_position: Vector2i`, `unit.is_alive: bool`, `unit.action_state` | BFS 半径 + 起始位置。接口由 Unit GDD 锁定。 |

### Downstream Dependencies

| System | Type | Interface Exposed | Notes |
|--------|------|-------------------|-------|
| **UI / Input** | Hard | `MovementResult`（可达瓦片、路径、距离）；`MovementResolver.compute_reachable()` | UI 读取 `MovementResult` 用于高亮渲染。Input 在单位进入 SELECTED 时调用 `compute_reachable()`，在点击确认时调用 `map.move_unit()`。 |
| **Attack** | Indirect | 进入 MOVED 后的触发 | 单位进入 MOVED 状态（成功移动或原地移动后）启用攻击瞄准。Movement 不直接调用 Attack。 |
| **Turn System** | Indirect | Input 门控 | Input 在允许移动前强制检查 `active_faction` 匹配和 `current_state == FACTION_PHASE_ACTIVE`。Movement 不直接引用 Turn System。 |

### External Dependencies

| Dependency | Type | Notes |
|------------|------|-------|
| `MovementResolver` (RefCounted) | Code | 纯 BFS 计算，无副作用。由 Game 场景创建，DI 注入到 Input。 |
| `MovementResult` (RefCounted) | Code | 不可变结果包装器。从 BFS 父节点映射惰性路径重建。 |

## Tuning Knobs

| Knob | Location | Safe Range | What Happens If Too Low | What Happens If Too High | Notes |
|------|----------|------------|------------------------|------------------------|-------|
| `unit.mov` | UnitStats.tres | [2, 6] | 2：单位几乎无法换位 —— 战术深度崩溃，侧翼包抄不可能 | 6：单位约 3 回合穿越默认 16×12 地图 —— 走位变得毫无意义 | 由 Unit GDD 定义。Movement 读取但不拥有。默认值 4。 |

**可调参数交互**：`unit.mov` 是 MVP 唯一的移动可调参数。地形代价（Tier 2）将引入按瓦片类型的代价乘数，与 MOV 交互 —— 一个 MOV 4 的单位在代价 2 的地形上实际可达距离相当于 MOV 2。此交互将在 Terrain GDD（Tier 2）中定义。

## Visual/Audio Requirements

N/A —— Movement 不拥有任何渲染节点。高亮颜色在此指定供参考，但由 UI / Input 系统负责渲染：

| Visual Element | Color | Owner |
|---------------|-------|-------|
| 可达瓦片高亮 | 蓝色（`#3B82F6`，Programmer Art Functional 玩家阵营蓝） | UI / Input |
| 起始瓦片高亮 | 深蓝色或特殊边框 | UI / Input |
| 路径预览高亮 | 青色或更亮的蓝色 | UI / Input |

无音频。移动是瞬时的（传送式）—— MVP 阶段无脚步声或滑动音效。

> **资源规范**：Movement 本身无需视觉资源。高亮渲染使用 TileMapLayer 上的纯色叠加层 —— 属于 UI / Input 系统的资源规范，非 Movement 的。

## UI Requirements

Movement 不直接渲染 UI。它通过 `MovementResult` 暴露数据供 UI 消费：

| Data | Method | UI Usage |
|------|--------|----------|
| 可达瓦片 | `get_reachable_tiles()` | 所有可达瓦片上的蓝色高亮叠加层 |
| 到达悬停瓦片的路径 | `get_path_to(tile)` | 悬停时的路径预览高亮（青色） |
| 到达瓦片的距离 | `get_distance_to(tile)` | 可选：悬停时显示步数 |
| 起始瓦片 | `get_start_tile()` | 特殊的起始瓦片高亮 |

Input 处理流程：
- **点击单位**（SELECTED 状态）→ UI 调用 `MovementResolver.compute_reachable()` → 渲染高亮
- **悬停瓦片** → UI 调用 `MovementResult.get_path_to(tile)` → 渲染路径预览
- **点击可达瓦片** → UI 调用 `Map.move_unit()` → 清除高亮 → 单位进入 MOVED
- **右键 / Escape**（取消）→ UI 清除高亮 → 单位回到 IDLE

## Acceptance Criteria

### Core Rules

**AC-MOVE-001 — 开阔网格上的 BFS 可达区域（Rule 1, F1）** [Logic]
GIVEN 一个 5×5 全可行走地图，单位在 (2,2)，MOV=2，WHEN 调用 `MovementResolver.compute_reachable(unit, map)`，THEN 可达集恰好包含 13 个瓦片 —— 所有 Manhattan 距离 ≤ 2 且在地图范围内的瓦片，通过 4 邻域 BFS 找到。

**AC-MOVE-002 — BFS 正确避开阻挡/被占用瓦片（Rule 1）** [Logic]
GIVEN 一个 3×3 全可行走地图，其中瓦片 (1,1) 被敌方单位占用，己方单位在 (1,0)，MOV=2，WHEN 调用 `compute_reachable()`，THEN (1,1) 和 (1,2) 不在可达集中 —— 到达 (1,2) 的唯一 2 步路径经过已被占用的 (1,1)。

**AC-MOVE-003 — 起始瓦片始终在可达集中（Rule 2）** [Logic]
GIVEN 任意有效地图，单位在任意可行走瓦片上，WHEN 调用 `compute_reachable()`，THEN 单位的当前 `grid_position` 始终在可达集中，即使 MOV 为最小值。起始瓦片特殊处理（单位自身占用该瓦片）。

**AC-MOVE-004 — 路径重建返回最短路径（Rule 3, F3）** [Logic]
GIVEN 一个 5×5 全可行走地图，BFS 从 (0,0) 到 (2,1)，WHEN 调用 `MovementResult.get_path_to((2,1))`，THEN 返回的数组长度为 4（起点 + 3 步），每对相邻瓦片满足 4 邻域邻接关系，路径上所有瓦片均可行走。

**AC-MOVE-005 — Map.move_unit() 完整移动（Rule 4）** [Integration]
GIVEN 单位在 (0,0)，目标 (0,1) 为空且可行走，WHEN 调用 `Map.move_unit(unit, (0,0), (0,1))`，THEN unit.grid_position 变为 (0,1)，Map 原子更新占用表（释放旧瓦片，占用新瓦片），操作返回 `true`。

**AC-MOVE-006 — 原地移动（0 步）（Rule 5）** [Logic]
GIVEN 单位在 (2,3) 处于 SELECTED 状态，WHEN 玩家确认移动到 (2,3)（同一瓦片），THEN 视为合法移动：移动阶段被消耗，单位进入 MOVED 状态但位置不变。

**AC-MOVE-007 — 移动后状态：SELECTED → MOVED（Rule 6）** [Integration]
GIVEN 单位在 (0,0) 处于 SELECTED 状态，目标 (0,2) 确认有效，WHEN `Map.move_unit()` 完成，THEN 单位 `action_state` 为 MOVED，后续 `can_move()` 返回 `false`。

**AC-MOVE-008 — 悬停预览暴露路径数据（Rule 7）** [Integration]
GIVEN 单位处于 SELECTED 状态且可达集已计算，WHEN UI 对可达瓦片查询 `MovementResult.get_path_to(tile)`，THEN 返回有效的路径数组，且 `get_distance_to(tile)` 返回对应步数。若瓦片不可达，两者分别返回空数组和 -1。

**AC-MOVE-009 — 约束：死亡或状态错误的单位不可移动（Rule 9）** [Logic]
GIVEN 单位满足 `is_alive() == false` 或 `action_state != SELECTED`，WHEN 调用 `compute_reachable()`，THEN 结果为空可达集。不崩溃，无副作用。

### Formulas

**AC-MOVE-010 — F1：开阔网格上的 BFS 距离层** [Logic]
GIVEN 一个 8×8 全可行走地图，单位在 (4,4)，MOV=3，WHEN BFS 运行，THEN 每个距离层 d ∈ [0,3] 恰好包含满足 `|r−4| + |c−4| = d` 的瓦片数量：d=0 → 1，d=1 → 4，d=2 → 8，d=3 → 12，总计 25 个瓦片。所有瓦片均可证明在 ≤ 3 步内通过 4 邻域 BFS 到达。

**AC-MOVE-011 — F2：Manhattan 距离** [Logic]
GIVEN 点 (0,0) 和 (3,4)，WHEN 计算 Manhattan 距离，THEN 结果 = `|3−0| + |4−0| = 7`。对称：`d(a,b) == d(b,a)`。若 `manhattan(start, tile) > unit.mov`，该瓦片必定不可达（必要条件）。

**AC-MOVE-012 — F3：路径步数** [Logic]
GIVEN 路径数组 `[(0,0), (0,1), (1,1), (2,1), (2,2)]`，WHEN 计算 `path_length`（`len(path) − 1`），THEN 结果 = 4。GIVEN 单元素路径 `[(0,0)]`，THEN 步数 = 0（原地移动）。空路径返回 0，不崩溃。

### Edge Cases

**AC-MOVE-013 — 边界：拒绝死亡单位** [Logic]
GIVEN 单位 `is_alive() == false` 处于有效坐标，WHEN 尝试调用 `compute_reachable()`、`get_path_to()` 或执行移动，THEN 方法立即返回空结果/错误。无计算、无副作用、无异常。

**AC-MOVE-014 — 边界：拒绝 null Map** [Logic]
GIVEN 有效单位但 `map == null`，WHEN 调用 `compute_reachable()`，THEN 方法返回空 `MovementResult`。不崩溃。

**AC-MOVE-015 — 边界：越界起始位置** [Logic]
GIVEN 单位在超出地图边界的坐标（如 (-1, 5)），WHEN 调用 `compute_reachable()`，THEN 结果为空集 —— BFS 无法从越界位置扩展。

**AC-MOVE-016 — 边界：退化 BFS —— MOV=0** [Logic]
GIVEN 单位在 (2,3)，MOV=0，在一个 5×5 全可行走地图上，WHEN 调用 `compute_reachable()`，THEN 结果为 `{(2,3)}` —— 仅起始瓦片。`get_path_to((2,3))` 返回 `[(2,3)]`，步数 = 0。

**AC-MOVE-017 — 边界：退化 BFS —— 所有邻域被阻挡** [Logic]
GIVEN 单位在一个可行走瓦片上，其 4 个邻域全部被阻挡（`is_walkable` 对 4 个邻域均返回 false），WHEN 调用 `compute_reachable()`，THEN 即使 MOV > 0，可达集仅为 `{start_tile}` —— BFS 边界在 d=0 后耗尽。

**AC-MOVE-018 — 边界：TOCTOU —— BFS 后目标被占用** [Logic]
GIVEN 计算路径时目标为空，但在 `Map.move_unit()` 执行前目标瓦片变为被占用，WHEN 调用 `move_unit()`，THEN Map 拒绝本次移动并返回 `false`。单位留在原位。无部分移动。通过 `move_unit()` 实现原子性。

**AC-MOVE-019 — 边界：移动到阻挡/被占用瓦片** [Integration]
GIVEN 单位在 (0,0)，目标 (0,1) 被阻挡或被敌方占用，WHEN 调用 `Map.move_unit(unit, (0,0), (0,1))`，THEN 返回 `false`，unit.grid_position 保持 (0,0)，占用表不变。

**AC-MOVE-020 — 边界：已处于 MOVED 状态时重复移动到同一瓦片** [Logic]
GIVEN 单位已完成移动（状态 = MOVED），WHEN 尝试再次调用 `execute_move()` 到同一瓦片，THEN 方法被拒绝 —— 状态守卫阻止重复消耗。单位保持原位。

**AC-MOVE-021 — 边界：地图边界裁剪（8×8 角落）** [Logic]
GIVEN 一个 8×8 全可行走地图，单位在角落 (0,0)，MOV=3，WHEN 调用 `compute_reachable()`，THEN 可达集包含所有满足 `r + c ≤ 3` 且在边界内的瓦片 —— BFS 在 r<0 和 c<0 边界处正确裁剪。对对角角落 (0,7) 验证同样正确。

**AC-MOVE-022 — 边界：除起始瓦片外全部被阻挡** [Logic]
GIVEN 一个 3×3 地图，仅 1 个可行走瓦片 (1,1)，其余全部被阻挡，单位在 (1,1)，MOV=6，WHEN 调用 `compute_reachable()`，THEN 结果为 `{(1,1)}` —— BFS 边界无法扩展到任何邻域，但不无限循环也不崩溃。

### Performance

**AC-MOVE-023 — 性能：32×32 网格上 MOV=6 时 BFS < 1ms** [Logic]
GIVEN 一个 32×32 全可行走地图，单位在中心 (16,16)，MOV=6，WHEN 调用 `compute_reachable()`，THEN 总执行时间（含边界检查和队列操作）低于 1 毫秒。可达集大小 ≈85 个瓦片（von Neumann 菱形）。验证 BFS 在 [8, 32] 范围内所有地图尺寸上的可扩展性。

### Integration: End-to-End

**AC-MOVE-024 — 集成：完整移动 → 占用一致性** [Integration]
GIVEN 一个 5×5 地图，有两个己方单位，无敌方单位，WHEN 单位 A 从 (0,0) 移动到 (0,2)（路径已确认），THEN：unit A.grid_position = (0,2)；`Map.get_unit_at((0,0))` 返回 null；`Map.get_unit_at((0,2))` 返回 unit A；unit B 不受影响；`Map.is_walkable((0,0))` 返回 true（已释放）；`Map.is_walkable((0,2))` 返回 false（被 A 占用）。

**AC-MOVE-025 — 集成：移动后启用攻击瞄准** [Integration]
GIVEN 单位处于 SELECTED 状态，从 (1,1) 移动到 (1,3)，WHEN `execute_move` 完成，THEN：unit.action_state = MOVED；`has_acted_this_turn` 为 false（攻击尚未消耗）；单位可进入攻击瞄准阶段；`can_move()` 返回 false；若射程（`rng`）内有目标，`can_attack()` 返回 true。

### Summary

| Category | Count | Logic | Integration | Gate |
|----------|-------|-------|-------------|------|
| Core Rules (9) | 9 | 6 | 3 | BLOCKING |
| Formulas (3) | 3 | 3 | 0 | BLOCKING |
| Edge Cases (10) | 10 | 9 | 1 | BLOCKING |
| Performance (1) | 1 | 1 | 0 | BLOCKING |
| End-to-End (2) | 2 | 0 | 2 | BLOCKING |
| **Total** | **25** | **19** | **6** | — |

全部 25 条验收标准均为 BLOCKING。19 条需要在 `tests/unit/movement/` 中编写自动化单元测试。6 条需要在 `tests/integration/movement/` 中编写集成测试。

## Open Questions

- **OQ1 — `Map.move_unit()` 正式化**：Movement GDD 要求 `Map.move_unit(unit, from, to) -> bool` 作为原子方法。目前在 Map GDD Edge Cases OQ3 中记录为建议。是否应在 Movement 实现前将其提升为 Map GDD Core Rules？→ 推迟到 Map GDD 更新时处理（可作为快速改造完成）。

- **OQ2 — Manhattan 距离的归属**：F2 在 Movement GDD 中定义了 Manhattan 距离，但 Attack 系统（Order 5）也使用 Manhattan 距离做射程验证。公式应该"归"Movement 并由 Attack 引用，还是各系统各自定义？→ 在 Attack GDD 编写时解决。

- **OQ3 — MOV=0 单位原型**：Unit GDD 将 MOV 范围锁定为 [2, 6]。MVP 不支持 MOV=0 的单位（不可移动炮台）。Tier 2 是否应将范围下限降为 0？→ 推迟到 Tier 2 设计。
