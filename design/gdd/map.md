# Map / Coordinates

> **Status**: In Design
> **Author**: binlee1990 + Claude
> **Last Updated**: 2026-04-29
> **Implements Pillar**: Pillar 2 — System Orthogonality（GridSpace 边界是防止坐标逻辑泄漏到渲染层的防火墙）

## Overview

Map / Coordinates 系统定义了游戏棋盘的空间拓扑：一个由 4-邻接（von Neumann）连接的正方形瓦片网格，每个瓦片处于三种状态之一 —— **walkable**（可通行）、**blocked**（阻塞）或 **obstacle**（障碍物）。一个 `GridSpace` 边界对象拥有网格坐标（整数索引对）与世界像素坐标之间转换的权威实现；其他所有系统通过此接口读取空间数据，且没有任何系统在内部执行内联坐标运算。棋盘通过 Godot 的 `TileMapLayer` 节点渲染，该节点将每种瓦片状态显示为 Programmer Art Functional 调色板中对应的纯色。此系统是基础层 —— Unit 放置、Movement BFS、Attack 范围计算、AI 目标选择以及 UI 高亮显示，都依赖它来回答"在哪里"的问题。没有 Map，就没有棋盘、没有邻接关系，也无法放置或移动任何东西。

## Player Fantasy

Map / Coordinates 系统不服务于直接的玩家情感 —— 而这正是它的成功条件。它的幻想是**透明性**：网格如此可预测，以至于玩家不再思考"网格"，而是开始思考**战术**。看起来可通行的瓦片就是可通行的。点击坐标总是精确解析到那个瓦片，无一例外。邻接关系遵循简单的 von Neumann 规则（上/下/左/右），不含对角线歧义。`GridSpace` 边界保证 Movement 中预览的路径与 Attack 系统评估的瓦片一致。当地图系统引起注意时，说明出了问题。当它不可见时，它已完成使命。

## Detailed Design

### Core Rules

1. **网格**: 一个 `cols × rows` 瓦片的矩形网格。边界：每张地图可配置，每轴范围 `[8, 32]`。MVP 默认地图：`16 × 12`。

2. **坐标系统**: 原点位于左上角。行优先：`(row, col)`，row 向下增长（匹配 Godot 的 Y-down 屏幕坐标）。瓦片大小：64×64 像素（由 art bible 锁定）。

3. **邻接关系**: 仅 4-邻接 von Neumann —— `(r-1, c)`、`(r+1, c)`、`(r, c-1)`、`(r, c+1)`。无对角线邻居。边缘瓦片有 2–3 个邻居。不环绕。

4. **瓦片状态**: 每个瓦片恰好处于三种状态之一，地图加载后不可变：
   - **walkable**: 单位可站立于此。渲染为 `TILE_DEFAULT`（#374151）。
   - **blocked**: 单位不可站立于此。MVP 中功能上与 obstacle 相同。渲染为 `TILE_BLOCKED`（#111827）。
   - **obstacle**: 单位不可站立于此。预留给未来的视线遮挡功能。渲染为 `TILE_OBSTACLE`（#1F2937）。

5. **GridSpace 边界**: `GridSpace` 对象（一个 `RefCounted` 实例，由 Map 场景持有并通过依赖注入传递到下游系统）是坐标转换的唯一权威：
   - `world_to_grid(world_pos: Vector2) → Vector2i` —— 像素位置到瓦片 (row, col)。
   - `grid_to_world(grid_pos: Vector2i) → Vector2` —— 瓦片 (row, col) 到瓦片左上角像素坐标。
   - 任何其他系统不得计算 `position * 64` 或 `position / 64`。在 code review 中强制执行。

6. **地图数据格式**: 每张地图一个 CSV 文件，位于 `assets/data/maps/`。第一行：`cols,rows`。后续行：每格一个字符 —— `.` = walkable，`#` = blocked，`O` = obstacle。便于编辑且 git-diffable。

7. **地图加载**: Map 场景包含一个空的 `TileMapLayer` 节点。在 `_ready()` 中，Map 读取其分配的 CSV，校验边界，并对每个瓦片调用 `TileMapLayer.set_cell()`。TileSet 资源中的三个 atlas tiles 对应三种状态。场景文件中不预置任何瓦片。

8. **占用**: 运行时占用与瓦片状态分开追踪：
   - **Unit** 持有 `grid_position: Vector2i` —— 权威单位位置。
   - **Map** 持有 `_occupancy: Dictionary[Vector2i, Unit]` —— O(1) 反向查找。
   - Map 暴露 `is_walkable(coord: Vector2i) → bool`：当且仅当 `tile_state == WALKABLE AND coord not in _occupancy` 时返回 `true`。
   - Map 暴露 `place_unit(unit, coord)` / `remove_unit(coord)` 用于占用更新。
   - Map 暴露 `get_unit_at(coord: Vector2i) → Unit`（空时返回 `null`）。

9. **邻居查询**: `Map.get_neighbors(coord: Vector2i) → Array[Vector2i]` 返回仅包含界内坐标的 4-邻接排序结果。**不**过滤可通行性 —— 这是调用方的职责（使 BFS 能管理自己的 visited 集合）。

### States and Transitions

**瓦片状态**在运行时不可变。瓦片的 walkable/blocked/obstacle 状态从 CSV 读取，对局过程中永不修改。

**占用状态**可变，由 Movement 管理：
| Transition | Trigger | Effect |
|---|---|---|
| Empty → Occupied | 单位移动到瓦片上 | Map._occupancy[coord] = unit; unit.grid_position = coord |
| Occupied → Empty | 单位移出瓦片 | Map._occupancy.erase(coord) |
| Occupied → Occupied | 单位在瓦片上阵亡 | Map._occupancy.erase(coord); 瓦片保持 walkable |

不存在"被障碍物占用"的状态 —— 障碍物是瓦片状态，不是实体。

### Interactions with Other Systems

| Downstream System | What Map Exposes | Data Direction |
|---|---|---|
| **Unit** | `grid_to_world()` —— 将 unit 场景节点放置到瓦片中心 | Map → Unit |
| **Movement** | `is_walkable(coord)`、`get_neighbors(coord)` —— BFS 前沿扩展；`place_unit()` / `remove_unit()` —— 占用写入 | Map ↔ Movement |
| **Attack** | `get_neighbors(coord)` —— 射程环计算；`get_unit_at(coord)` —— 目标验证 | Map → Attack |
| **UI / Input** | `world_to_grid()` —— 点击→瓦片解析；`grid_to_world()` —— 高亮覆盖层放置；瓦片状态查询 —— 颜色选择 | Map → UI |

Map 不向 Attack 或 UI 暴露写入接口 —— 这些系统是只读消费者。

## Formulas

### F1: grid_to_world

`grid_to_world(row, col) = (col * TILE_SIZE, row * TILE_SIZE)`

| Variable | Symbol | Type | Range | Description |
|----------|--------|------|-------|-------------|
| 行索引 | row | int | [0, map_rows−1] | 瓦片行索引 |
| 列索引 | col | int | [0, map_cols−1] | 瓦片列索引 |
| 瓦片大小 | TILE_SIZE | const int | 64 | 每瓦片边缘像素数（art bible 锁定） |

**输出**: 瓦片左上角在世界像素坐标中的位置。放置单位时，调用方计算中心点：`grid_to_world(r,c) + Vector2(32, 32)`。

**示例**: `grid_to_world(2, 3) = (192, 128)` —— 行 2 列 3 的瓦片左上角位于像素 (192, 128)；中心位于 (224, 160)。

### F2: world_to_grid

`world_to_grid(x, y) = (floor(y / TILE_SIZE), floor(x / TILE_SIZE))`

| Variable | Symbol | Type | Range | Description |
|----------|--------|------|-------|-------------|
| 像素 X | x | float | any | 屏幕/世界空间 X |
| 像素 Y | y | float | any | 屏幕/世界空间 Y |
| 瓦片大小 | TILE_SIZE | const int | 64 | 每瓦片边缘像素数 |

**输出**: 无界 `Vector2i(row, col)`。调用方负责 `is_coord_in_bounds` 检查。floor 处理边界：恰好落在瓦片边缘上的像素解析为更高索引的瓦片。

**示例**: `world_to_grid(215, 150) = (2, 3)`。

### F3: tile_center（便捷封装）

`tile_center(row, col) = grid_to_world(row, col) + Vector2(32, 32)`

**输出**: 用于 unit 场景节点放置的世界像素位置。

**示例**: `tile_center(2, 3) = (224, 160)`。

### F4: is_coord_in_bounds

`is_coord_in_bounds(row, col) = (0 ≤ row < map_rows) AND (0 ≤ col < map_cols)`

**输出**: 当坐标在地图矩形内时为 `true`。被 `get_neighbors` 用于过滤边缘瓦片，被 UI 用于拒绝越界点击。

### F5: neighbor_offsets

`NEIGHBOR_OFFSETS = [(-1, 0), (1, 0), (0, -1), (0, 1)]`

4 个 cardinal von Neumann 偏移量，依次为：上、下、左、右。`get_neighbors(coord)` 将每个偏移加到 `coord` 上，并只保留界内结果。

> **不属于此系统的内容**: 曼哈顿距离（`|r1−r2| + |c1−c2|`）属于 Movement（BFS 启发式）。路径成本属于 Movement。切比雪夫距离不在范围内。

## Edge Cases

- **如果 `world_to_grid` 收到负像素值**: 返回负的 row/col 索引。调用方必须在使⽤前检查 `is_coord_in_bounds` —— 与 F2 的无界输出契约一致。

- **如果 `grid_to_world` 收到越界坐标**: 返回该瓦片若存在时**应当**具有的像素位置（不钳制）。调用方负责边界检查 —— 与 F1 一致。

- **如果 `place_unit(unit, coord)` 收到越界或不可通行的坐标**: 发出错误信号并返回 `false`。占用不变。

- **如果 `place_unit(unit, coord)` 收到已被占用的坐标**: 拒绝并返回 `false`。已有单位不被挤占。

- **如果 `remove_unit(coord)` 在空瓦片上调用**: 通过 `push_warning()` 发出警告并返回 `false`。`Dictionary.erase()` 本身对缺失 key 是无操作的，但警告可暴露调用方的 bug。

- **如果 `unit.grid_position` 与 `_occupancy` 不同步**（例如部分移动失败）: MVP 中无运行时检测。Movement 系统同时持有两边的写入权；Map 上的单一原子 `move_unit(unit, from, to)` 方法消除了不同步窗口。Movement GDD 必须调用此方法而非分别调用 `place`/`remove`。

- **如果像素恰好落在瓦片边界上**（例如 `x = 64.0`）: `floor()` 解析为更高索引的瓦片。在 SRPG 典型坐标范围（< 2048px）内，IEEE 754 在 64 的精确倍数附近的精度是可靠的。

- **如果 `get_neighbors` 在角落瓦片上调用**: 返回 2 个邻居。边缘瓦片返回 3 个。所有 4 个偏移量均经过 `is_coord_in_bounds` 检查。

- **如果 CSV 头部声明的维度超出 [8, 32]**: 地图加载失败，并输出错误消息说明允许的范围和实际值。

- **如果 CSV 的⾏/列数与头部不匹配**: 地图加载失败，并输出错误消息给出预期与实际维度的对比。

- **如果 CSV 包含 `.`、`#`、`O` 之外的字符**: 地图加载失败，并输出错误消息指明无效字符及其位置 (row, col)。

- **如果 CSV 文件缺失或不可读**: 地图加载失败，并输出错误消息指明文件路径和 OS 错误。

- **如果所有瓦片都是 blocked/obstacle**: 地图成功加载（合法的退化状态）。Unit 放置阶段将没有有效位置 —— 这是设计时的地图错误，不是运行时崩溃。Map 系统在数据层不强制"至少一个 walkable 瓦片"。

## Dependencies

Map / Coordinates 是基础层 —— 它没有上游依赖。

### Downstream Dependencies（依赖 Map 的系统）

| System | Dependency Type | Interface Required | Notes |
|--------|----------------|--------------------|-------|
| **Unit** | Hard | `grid_to_world()` | Unit 放置需要从网格坐标到像素位置 |
| **Movement** | Hard | `is_walkable()`、`get_neighbors()`、`place_unit()`、`remove_unit()` | BFS 遍历 + 占用写入 |
| **Attack** | Hard | `get_neighbors()`、`get_unit_at()` | 射程环计算 + 目标验证 |
| **UI / Input** | Hard | `world_to_grid()`、`grid_to_world()`、瓦片状态查询 | 点击→瓦片解析、高亮放置、颜色选择 |

所有四个依赖关系均为 **hard** —— 下游系统没有 Map 则无法运行。

### External Dependencies

| Dependency | Type | Notes |
|------------|------|-------|
| `TileMapLayer`（Godot 4.6） | Engine | 渲染节点。松耦合 —— 可替换而不改变 Map 的逻辑接口。 |
| CSV 地图文件（`assets/data/maps/`） | Data | Pillar 1 合规。Map 从外部数据加载，而非从预置场景。 |
| TileSet 资源（.tres） | Asset | 三个 atlas tiles 对应三种瓦片状态。创建一次，所有地图复用。 |

## Tuning Knobs

| Knob | Location | Safe Range | 过低时的后果 | 过高时的后果 | Notes |
|------|----------|------------|-------------|-------------|-------|
| `map_cols` | CSV header | [8, 32] | 战术深度蒸发 —— 少于 8 列使得侧翼包抄无法实现 | BFS 在 32×32 上仍 <1ms，但屏幕空间超过 2048px（MVP 未实现滚动） | 每张地图可配置 |
| `map_rows` | CSV header | [8, 32] | 同 cols —— 纵向空间过于拥挤 | 同 cols —— 超过 2048px 需纵向滚动 | 每张地图可配置 |
| `TILE_SIZE` | Art bible 常量 | [32, 128] | 低于 32px：瓦片难以精确点击 | 高于 128px：16×12 地图较长轴超 2048px，单位相对瓦片显得过小 | MVP 锁定为 64。修改此值需重建 TileSet 并更新 art bible。 |
| 每瓦片状态 | CSV 网格单元格 | 仅 `.` `#` `O` | N/A | N/A | MVP 仅三种状态。未来地形类型（Tier 2）在此基础上增加字符。 |

**Knob 交互关系**: `map_cols × TILE_SIZE` 决定总像素宽度。若增加 `map_cols`，`TILE_SIZE` 可能需缩小以适应屏幕，反之亦然。这两个 knobs 应针对目标分辨率（MVP：1920×1080）联合调校。

## Visual/Audio Requirements

[待设计]

## UI Requirements

[待设计]

## Acceptance Criteria

### Core Rules

**AC-C1 — 网格边界**
GIVEN 从 CSV 加载的 Map，WHEN CSV 头部行为 `16,12`，THEN 网格为 16×12。WHEN 头部指定维度超出 [8,32]，THEN 地图加载失败并输出错误消息，说明范围与实际值。

**AC-C2 — 坐标朝向**
GIVEN 已加载地图且 TILE_SIZE=64，WHEN 调用 `grid_to_world(0,0)`，THEN 返回 `Vector2(0,0)`。WHEN 调用 `grid_to_world(1,0)` 和 `grid_to_world(0,1)`，THEN row 增长使 Y 向下移动，col 增长使 X 向右移动，各精确 64px。

**AC-C3 — von Neumann 邻接**
GIVEN 一个中心瓦片，WHEN 调用 `get_neighbors(row,col)`，THEN 结果恰好包含四个 cardinal 方向坐标，零个对角线。

**AC-C4 — 瓦片状态不可变性**
GIVEN 已加载地图，WHEN 加载后重新查询任意瓦片的状态，THEN 每个瓦片与其 CSV 值匹配，且不存在修改瓦片状态的公开 API。

**AC-C5 — GridSpace 转换精度**
GIVEN 一个 `GridSpace` 实例，WHEN 调用 `world_to_grid(Vector2(215, 150))`，THEN 返回 `Vector2i(2, 3)`。WHEN 调用 `grid_to_world(Vector2i(2, 3))`，THEN 返回 `Vector2(192, 128)`。

**AC-C6 — CSV 映射**
GIVEN 使用 `.`、`#`、`O` 字符的 CSV，WHEN 地图加载，THEN `.` → walkable，`#` → blocked，`O` → obstacle。

**AC-C7 — 场景根节点为空的 TileMapLayer**
GIVEN Map 场景文件，WHEN 进行检查，THEN TileMapLayer 节点包含零个预置瓦片。WHEN `_ready()` 运行，THEN 对每个 CSV 单元格调用一次 `set_cell()`。

**AC-C8 — is_walkable 双重检查**
GIVEN 一个空的可通行瓦片，WHEN 调用 `is_walkable(coord)`，THEN `true`。GIVEN 该瓦片在 `place_unit` 成功后，WHEN 重新查询，THEN `false`。GIVEN 一个 blocked 或 obstacle 瓦片，WHEN 查询，THEN `false`，无论占用状态。

**AC-C9 — get_neighbors 仅限边界**
GIVEN 角落瓦片 `(0,0)`，WHEN 调用 `get_neighbors(0,0)`，THEN 恰好返回 2 个坐标（下和右），均在界内，且 blocked 邻居**包含在内**。

**AC-C10 — place_unit 拒绝**
GIVEN 越界、不可通行或已占用的坐标，WHEN 调用 `place_unit(unit, coord)`，THEN 返回 `false` 且占用不变。

**AC-C11 — 在空瓦片上 remove_unit**
GIVEN 一个空瓦片，WHEN 调用 `remove_unit(coord)`，THEN 发出 `push_warning()` 并返回 `false`。

**AC-C12 — CSV 校验错误**
GIVEN 行/列数不匹配、包含未知字符或文件缺失的 CSV，WHEN 地图尝试加载，THEN 加载失败并输出标识问题的具体错误消息。

### Formulas

**AC-F1 — grid_to_world**
GIVEN row=2, col=3, TILE_SIZE=64，WHEN 计算 `grid_to_world(2,3)`，THEN `Vector2(192, 128)` —— 即 `(col*64, row*64)`。

**AC-F2 — world_to_grid**
GIVEN 像素 (215, 150)，WHEN 计算 `world_to_grid(215, 150)`，THEN `Vector2i(2, 3)` —— 即 `(floor(150/64), floor(215/64))`。

**AC-F3 — tile_center**
GIVEN row=2, col=3，WHEN 计算 `tile_center(2,3)`，THEN `Vector2(224, 160)` —— 与 `grid_to_world + Vector2(32,32)` 一致。

**AC-F4 — is_coord_in_bounds**
GIVEN 16×12 地图：`(0,0)` → `true`，`(15,11)` → `true`，`(-1,0)` → `false`，`(0,12)` → `false`。

**AC-F5 — NEIGHBOR_OFFSETS 常量**
GIVEN 该常量，WHEN 检查，THEN 其值恰好为 `[(-1,0),(1,0),(0,-1),(0,1)]`。

> **注**: "GridSpace 之外不得出现内联 `* 64` 运算"是 code-review 强制执行的规则，不是运行时 AC。它属于项目的 Forbidden Patterns，不属于本 GDD。

## Open Questions

- **OQ1 — 坐标运算强制规则的 CI grep gate**: "GridSpace 之外不得出现内联 `* 64` 或 `/ 64`"规则是 code-review 约束，不是运行时测试。是否应添加 CI grep 检查到项目的 Forbidden Patterns？→ 推迟到建立 CI pipeline 时的 `/architecture-decision`。

- **OQ2 — GridSpace 作为 RefCounted 配合依赖注入**: gameplay-programmer 建议将 GridSpace 作为普通 `RefCounted`（非 Autoload）以保持可测试性。这是一个架构决策。→ 推迟到 Map 系统 ADR 的 `/architecture-decision`。

- **OQ3 — 原子 move_unit vs 分离的 place/remove**: Edge Cases 中说明分离的 `place_unit`/`remove_unit` 调用会制造不同步窗口。Map 上的单一 `move_unit(unit, from, to)` 方法可以消除此问题。→ Movement GDD 必须使用此接口；Map GDD 将其加入接口规范。

- **OQ4 — 全阻塞地图检测**: 全阻塞地图成功加载（合法退化状态）但没有可放置单位的位置。Map 系统是否应在零 walkable 瓦片时发出加载警告？→ 推迟到 Unit GDD（unit 放置阶段会自然失败 —— 无需 Map 层面特殊检测，除非 Unit GDD 要求）。
