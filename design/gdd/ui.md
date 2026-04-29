# UI / Input

> **Status**: In Design
> **Author**: binlee1990 + Claude
> **Last Updated**: 2026-04-29
> **Implements Pillar**: Pillar 1 — Data-Driven (UI reads state, doesn't embed values); Pillar 2 — System Orthogonality (Presentation layer aggregates upstream data without owning game logic)

## Overview

UI / Input 是 SRPG 骨架的**表现层**——玩家与游戏之间唯一的界面。它接收所有鼠标输入（点击单位、点击目标瓦片、悬停预览、Escape 取消、End Turn 按钮），并将 7 个底层系统的状态渲染为可见的视觉元素：蓝/红色的单位几何图形（方=玩家，圆=敌方）带 HP 标签、蓝色移动范围高亮、青色路径预览、红色攻击目标高亮、琥珀色伤害预览数字、回合指示器和 End Turn 按钮、以及绿/红/灰的胜/负/平局画面。UI 系统**不拥有任何游戏逻辑**——它读取上游系统的数据（Map 的瓦片状态、Unit 的属性、Turn 的回合数、Movement 的可达瓦片、Attack 的目标列表和伤害值、Victory 的胜负判定、AI 的 ActionList），并将其转换为 Control 节点树。所有视觉元素均为 code-drawn（Godot 内置 ColorRect / Polygon2D / Label / StyleBoxFlat），与 Programmer Art Functional 的零纹理、零图标、零动画立场一致。没有 UI 系统，游戏仍然在运行——单位仍然有 HP、BFS 仍然在计算、Turn 仍然在轮转——但玩家什么都看不见，什么都点不了。UI 让棋盘**可见**，让决策**可操作**。

## Player Fantasy

UI / Input 的幻想是**通过预见获得信心**——在每次点击之前，你已精确知晓点击的后果。

棋盘是你的对话对象。点击己方单位，蓝色范围瞬间铺开——每一个蓝色瓦片都是"你能到这里"的承诺。悬停任一瓦片，青色路径浮现，精确告诉你将如何到达。悬停任一敌人，琥珀色伤害数字出现在它头顶——`ATK - DEF`，你心算过的数字，UI 替你确认。如果是红色的，这一击将击杀。你从未"祈祷"伤害足够——你**知道**。

锚定时刻：你悬停一个残血敌人——"5"出现在它头顶。5 = 8 − 3。你再悬停另一个——"3"。你选择第一个值得打。你点击。HP 从 5 归零，单位从棋盘消失。你从未"希望"——你知道。

UI 是诚实的：它展示的是公式的输出，不是概率的区间。透明来自上游系统的所有承诺——确定性伤害、BFS 可达、无 RNG。UI 不做预言，它做预报。任何一个有争议的 UI 决策（加不加确认框？隐藏什么信息？）回到这个锚点：**提交前，玩家是否已看见精确后果？** 若非，UI 有遗漏。

这与 Attack GDD 的"数字是一个承诺"对齐，与 Movement GDD 的"蓝色 = 保证可到达"对齐，与 Programmer Art Functional 的"每个视觉元素存在都是为了呈现状态"对齐。UI 是棋盘对你的回应——在你行动之前。

## Detailed Design

### Core Rules

#### A. 输入解析

**A1 — 点击→坐标解析**：所有棋盘区域的左键点击通过 `GridSpace.world_to_grid(click_pos)` 解析为 `Vector2i` 网格坐标。棋盘区域定义为像素矩形 `(0, 0)` 至 `(map_cols × TILE_SIZE, map_rows × TILE_SIZE)`。越界点击被静默忽略。

**A2 — 上下文相关点击解释**：解析后的网格坐标根据当前输入上下文（UI 自有的 enum，不归 Unit 所有）进行不同解释：

| 上下文 | 点击目标 | 行为 |
|--------|---------|------|
| `BOARD_IDLE` | 可选中的己方单位 | 选中单位 → 上下文变为 `UNIT_SELECTED` |
| `BOARD_IDLE` | 空地 / 敌方单位 / 已行动单位 | 忽略 |
| `UNIT_SELECTED` | 可达集中的瓦片（含自身瓦片） | 移动至该瓦片 → 上下文变为 `ATTACK_TARGETING` |
| `UNIT_SELECTED` | `unit.rng` 内的敌方单位 | 直接攻击（跳过移动）→ 上下文变为 `BOARD_IDLE` |
| `UNIT_SELECTED` | 另一个可选中的己方单位 | 切换选中 → 上下文保持 `UNIT_SELECTED` |
| `UNIT_SELECTED` | 其他瓦片 | 忽略 |
| `ATTACK_TARGETING` | 有效攻击目标 | 执行攻击 → 上下文变为 `BOARD_IDLE` |
| `ATTACK_TARGETING` | 其他瓦片 | 忽略 |

输入上下文从 `current_state`、`active_faction` 和被选中单位的 `action_state` 的组合中派生。

**A3 — 悬停预览**：悬停根据输入上下文产生不同预览：

| 上下文 | 悬停目标 | 预览 |
|--------|---------|------|
| `UNIT_SELECTED` | 可达集内瓦片 | 路径高亮沿 `MovementResult.get_path_to(tile)` 渲染（青 #0891B2） |
| `UNIT_SELECTED` | 不在可达集内 | 无预览（路径查询返回空，UI 清除之前路径） |
| `ATTACK_TARGETING` | 有效敌方目标 | 伤害预览数字 `-N` 浮现于目标上方（非击杀=琥珀 #F59E0B，击杀=红 #EF4444） |
| `ATTACK_TARGETING` | 非目标瓦片 | 清除伤害预览 |
| `BOARD_IDLE` | 任意瓦片 | 无反馈 |

预览数据由上游系统计算（`MovementResult`、`AttackResolver.resolve_damage()`）—— UI 仅请求并渲染。

**A4 — 取消（取消选中）**：右键或 Escape 取消当前选中或攻击瞄准：
- `UNIT_SELECTED`：清除选中。单位 `action_state` 回到 IDLE。清除所有高亮。上下文 → `BOARD_IDLE`。
- `ATTACK_TARGETING`：跳过攻击。单位 `has_acted_this_turn = true`，`action_state = ACTED`。无伤害。清除所有高亮。上下文 → `BOARD_IDLE`。单位的行动被消耗。
- `BOARD_IDLE`：无操作。

#### B. 交互流程

**B1 — 单位激活循环**：`选中 → 预览移动 → 移动 → 预览攻击 → 攻击 → 变灰`。每个步骤是一个决策点。玩家可在移动后停止（跳过攻击），但一旦跳过攻击，行动被消耗。

**B2 — 完整步骤序列**：
1. **选中**：玩家左键点击可选中的己方单位。单位进入 SELECTED 状态。`MovementResolver.compute_reachable(unit, map)` 被调用。结果缓存为 `current_movement_result`。同时调用 `AttackRangeResolver.get_valid_targets(unit, map)` 获取从当前位置可直接攻击的敌人。
2. **预览移动**：可达瓦片渲染为蓝色（#3B82F6）。起始瓦片以特殊方式区分。可攻击的敌方瓦片渲染为橙色（#EA580C）。悬停可达瓦片显示路径预览（青色 #0891B2）。
3. **移动（提交）**：玩家左键点击可达瓦片。`Map.move_unit(unit, from, to)` 被原子调用。单位 `action_state` → MOVED。清除所有移动高亮。丢弃 `current_movement_result`。
4. **进入攻击瞄准**：调用 `AttackRangeResolver.get_valid_targets(unit, map)`。若结果为空 → 单位立即变为 ACTED（规则 B4）。否则，有效目标渲染为橙色（#EA580C）。上下文 → `ATTACK_TARGETING`。
5. **预览攻击**：悬停有效目标显示伤害数字。使用 `AttackResolver.resolve_damage(unit.atk, target.def)`。伤害 ≥ target.hp → 红色文本（#EF4444）。伤害 < target.hp → 琥珀色文本（#F59E0B）。
6. **攻击（提交）**：玩家左键点击有效目标。`AttackResolver.execute_attack(unit, target)` 被调用。伤害数字在目标上方停留 600ms。HP 标签即时更新。若目标死亡 → `unit_died` 信号 → Map 移除单位。攻击者：`has_acted_this_turn = true`，`action_state = ACTED`。所有高亮清除。上下文 → `BOARD_IDLE`。
7. **跳过攻击**：玩家按 Escape/右键。单位：`has_acted_this_turn = true`，`action_state = ACTED`。无伤害。清除所有高亮。上下文 → `BOARD_IDLE`。

**B3 — 从 SELECTED 直接攻击**：在 UNIT_SELECTED 中，玩家点击射程内已高亮的敌方单位 → 跳过移动，直接攻击。单位保持原位。`AttackResolver.execute_attack()` 立即调用。单位 SELECTED → ACTED，一步完成。

**B4 — 无目标时自动跳转**：若进入 ATTACK_TARGETING 时 `get_valid_targets()` 返回 `[]`，单位直接变为 ACTED（`has_acted = true`）。不展示空的攻击选项。

**B5 — 阶段完成**：活跃阵营最后一个未行动单位进入 ACTED 后，Turn System 的 auto-advance 触发。UI 响应 `faction_phase_ended` 信号清除所有高亮并取消选中。`faction_activated(next)` 信号触发时 UI 更新回合指示器。

**B6 — 玩家不能做的事**：
- 选择敌方单位
- 选择已死亡单位（瓦片为空）
- 选择已行动单位（灰色）
- 移动到不可达瓦片
- 移动非 SELECTED 状态的单位
- 攻击非 [SELECTED, MOVED] 状态单位
- 攻击同阵营单位（Attack 的 faction 守卫）
- 攻击已死亡单位（不在 `get_valid_targets()` 中）
- 在 FACTION_PHASE_ENDING / MATCH_ENDED / MATCH_NOT_STARTED 期间操作棋盘
- 撤销移动或攻击（MVP：无撤销）
- 同时选中多个单位（MVP：仅单选）

#### C. 约束与门禁

**C1 — Turn 状态门禁**：所有棋盘交互受 `TurnManager.current_state == FACTION_PHASE_ACTIVE` 约束。其他状态下所有棋盘点击被忽略。

**C2 — 活跃阵营门禁**：`TurnManager.active_faction` 决定哪些单位可选。`Unit.can_be_selected()` 在其前置条件中包含 `faction == active_faction`。

**C3 — 单位行动状态门禁**：选择要求 IDLE。移动要求 SELECTED。攻击要求 [SELECTED, MOVED]。ACTED 后忽略所有点击，直到下个阵营阶段。

**C4 — has_acted 门禁**：`has_acted == true` 通过 `can_be_selected()` 阻止选择。

**C5 — 点击目标验证**：所有无效点击静默忽略（MVP 无错误提示音、无抖动动画、无解释性工具提示）。视觉状态（无效瓦片无高亮）是无效点击的唯一反馈。

**C6 — End Turn 按钮门禁**：`TurnManager.current_state == FACTION_PHASE_ACTIVE` 时可见/可点击。其他状态下隐藏。TurnManager 自身拥有 `end_current_faction_turn()` 的重入保护。选中单位期间按 End Turn：静默放弃——清除选中+高亮，直接结束阶段。未行动单位丧失本轮行动。

**C7 — 多次点击防护**：MVP 中所有操作为同步原子操作——无动画延迟窗口。若未来 Tier 引入动画，Input 必须在过渡期间守卫 `_input_blocked` 标志。

#### D. 渲染组织（从下到上）

**D1 — 图层顺序**：

| 层 | 内容 | 所有者 | 备注 |
|----|------|--------|------|
| 0. 网格 | TileMapLayer 三种瓦片色 | Map | 静态。地图加载时渲染 |
| 1. 移动高亮 | 可达瓦片叠加层（蓝 #3B82F6） | UI / Input | 位于网格之上，单位之下 |
| 2. 路径预览 | 路径瓦片叠加层（青 #0891B2） | UI / Input | 位于移动高亮之上 |
| 3. 攻击高亮 | 目标瓦片叠加层（橙 #EA580C） | UI / Input | 位于网格之上，单位之下 |
| 4. 单位 | ColorRect + HP 标签 | Unit | 单位拥有其视觉节点 |
| 5. 伤害预览 | `-N` 标签，位于目标上方 `Vector2(0, -60)` | UI / Input | 琥珀/红色，停留 600ms |
| 6. HUD | 回合指示器、阵营指示器、End Turn 按钮 | UI / Input | CanvasLayer（第 0 层），屏幕空间 |
| 7. 覆盖层界面 | 胜/负/平画面、调试坐标叠加层 | UI / Input | CanvasLayer（第 10 层），全屏 |

**D2 — 高亮渲染**：三个 `HighlightLayer` 节点（Node2D，位于 Board 内），每个包含一个 `_draw()` 覆写，使用 `draw_rect()` 调用绘制纯色矩形。全部不透明（alpha = 1.0），通过颜色差异区分状态。

颜色规范（艺术圣经 §4.4 一致性——禁止低于 90% 不透明度）：

| 元素 | 颜色 | Hex |
|------|------|-----|
| 移动范围 | 青 | `#0891B2` |
| 路径预览 | 亮青 | `#06B6D4` |
| 攻击目标 | 橙 | `#EA580C` |
| 伤害预览（普通） | 琥珀 | `#F59E0B` |
| 伤害预览（击杀） | 敌方红 | `#EF4444` |
| 阵营 PLAYER | 蓝 | `#3B82F6` |
| 阵营 ENEMY | 红 | `#EF4444` |
| 已行动单位 | 灰 | `Color.GRAY`，50% modulate |

高亮颜色与阵营颜色解耦——移动青 ≠ 玩家蓝，攻击橙 ≠ 敌方红——确保高亮状态与单位身份在视觉上可区分。

**D3 — 高亮生命周期**：
- 移动高亮：单位进入 SELECTED 时创建，离开 SELECTED 时清除（移动、取消或直接攻击后）
- 路径预览：悬停可达瓦片时创建，鼠标移出或提交时清除
- 攻击高亮：进入 ATTACK_TARGETING 时创建，攻击提交、跳过或取消时清除
- 伤害预览：悬停有效目标时创建，鼠标移出、攻击提交或取消时清除（提交后延迟 600ms）

**D4 — 调试坐标叠加层**：默认开启（MVP）。在每个瓦片中心渲染 `(row, col)` 文本。Godot 默认字体，小号（12px），白色。切换键：反引号 `` ` ``。

#### E. HUD 元素

**E1 — 回合指示器**：持续显示 `"Turn X/Y"`。轮询 `TurnManager.turn_number` 和 `TurnManager.turn_cap`。位于屏幕左上角。FACTION_PHASE_ACTIVE 和 FACTION_PHASE_ENDING 期间可见。MATCH_NOT_STARTED 和 MATCH_ENDED 期间隐藏。

**E2 — 阵营指示器**：持续显示 `"Player Turn"` 或 `"Enemy Turn"`。轮询 `TurnManager.active_faction`。颜色编码：蓝（#3B82F6）= PLAYER，红（#EF4444）= ENEMY。位于回合指示器旁边。

**E3 — End Turn 按钮**：标签 `"End Turn"` 的可点击按钮。触发 `end_turn` InputMap 动作 → `TurnManager.end_current_faction_turn()`。位于屏幕右下角。仅在 `FACTION_PHASE_ACTIVE` 时可见。MVP 热座模式中 PLAYER 和 ENEMY 阶段均可见。

**E4 — HUD 定位**：所有 HUD 元素位于 CanvasLayer（第 0 层，屏幕空间），不受世界摄像机影响。按钮使用 Godot 默认 StyleBoxFlat 样式。

**E5 — 单位 HP 标签**：非 HUD 元素。归 Unit 场景所有（Label 子节点，偏移 `Vector2(0, -40)`，格式 `"HP: 8/10"`）。UI 仅在调试叠加层中读取 `unit.hp`/`unit.max_hp`——不创建或定位 HP 标签。

#### F. 屏幕状态

**F1 — 屏幕状态机**：

| 屏幕 | 触发条件 | 内容 |
|------|---------|------|
| `BOARD` | `match_started` 信号 | 网格 + 单位 + 高亮 + HUD |
| `WIN` | `match_ended("elimination", PLAYER)` 或 `match_ended("turn_cap", PLAYER)` | 全屏覆盖层：半透明深色背景 + "VICTORY"（大字居中）+ 原因文字 + "再来一局"按钮 |
| `LOSE` | `match_ended("elimination", ENEMY)` 或 `match_ended("turn_cap", ENEMY)` | 全屏覆盖层：半透明深色背景 + "DEFEAT"（大字居中）+ 原因文字 + "再来一局"按钮 |
| `DRAW` | `match_ended("turn_cap", NONE)` | 全屏覆盖层：半透明深色背景 + "DRAW"（大字居中）+ "回合上限到达" + "再来一局"按钮 |

**F2 — 屏幕过渡**：
- MATCH_NOT_STARTED → BOARD：`match_started` 信号
- BOARD → WIN / LOSE / DRAW：`match_ended(reason, winner)` 信号。棋盘在覆盖层下方保持可见（无需隐藏——覆盖层遮挡它）
- WIN / LOSE / DRAW → BOARD：点击"再来一局"。调用 Game 组合根上的 `restart_match()` 方法或 `get_tree().reload_current_scene()`

**F3 — 结果画面样式**：Godot 默认字体。标题大字居中。原因行小字居中位于标题下方。"再来一局"按钮居中位于底部。无自定义字体，无图标，无动画过渡——与 Programmer Art Functional 一致。

### Input Handling

#### 输入状态机

```
                    ┌──────────────────────────────────┐
                    │           BOARD_IDLE              │
                    │  (等待玩家点击己方单位)              │
                    └─────┬──────────────────┬─────────┘
              点击己方单位  │                  │ match_ended
                          ▼                  ▼
             ┌──────────────────┐    ┌──────────────┐
             │  UNIT_SELECTED   │    │  WIN / LOSE  │
             │  (移动+攻击预览)   │    │   / DRAW     │
             └──┬───────┬───────┘    └──────────────┘
     点击可达瓦片 │       │ 直接点击敌人
                ▼       ▼
      ┌──────────────────────┐
      │  ATTACK_TARGETING    │
      │  (选择攻击目标/跳过)   │
      └──────────┬───────────┘
      点击目标/跳过 │
                  ▼
             BOARD_IDLE
```

#### 输入状态表

| 状态 | 含义 | 左键行为 | 右键/Escape | 悬停反馈 |
|------|------|---------|------------|---------|
| `BOARD_IDLE` | 无单位选中 | 选中可选中单位 | 无操作 | 无反馈（空地）；指针光标（可选单位） |
| `UNIT_SELECTED` | 单位选中，显示移动+攻击范围 | 移动 / 直接攻击 / 切换选中 | 取消选中 → BOARD_IDLE | 路径预览（可达瓦片）；伤害预览（敌方单位）；十字光标（攻击目标） |
| `ATTACK_TARGETING` | 已移动，选择攻击目标 | 攻击 / 跳过（点击空地） | 跳过攻击 → BOARD_IDLE | 伤害预览（敌方单位）；十字光标 |

#### 输入架构

`InputHandler`（RefCounted，DI 注入到 Board）在 `_unhandled_input` 中处理棋盘点击。CanvasLayer 上的 Control 节点（按钮）在 Godot 内置的 `gui_input` 中优先处理——无需手动检查"是否点击了按钮"。覆盖层界面（CanvasLayer 第 10 层）通过设置背景 `mouse_filter = MOUSE_FILTER_STOP` 阻止点击穿透到棋盘。

**输入优先级链**：
1. 覆盖层界面活跃？→ 路由到界面按钮。停止
2. `current_state` 不允许交互（FACTION_PHASE_ENDING / MATCH_ENDED / MATCH_NOT_STARTED）？→ 忽略。停止
3. Control 节点（HUD 按钮）消耗事件？→ 由 Godot 自动处理。停止
4. Board `_unhandled_input`：`world_pos = get_global_mouse_position()` → `grid_pos = Map.world_to_grid(world_pos)` → 按输入上下文解析

#### 光标样式

| 条件 | 光标 |
|------|------|
| 悬停可选中的己方单位 | `POINTING_HAND` |
| 悬停可达瓦片 | `POINTING_HAND` |
| 悬停有效攻击目标 | `CROSS` |
| 悬停非交互区域 | `ARROW`（默认） |

### Screen Flow

```
[比赛开始]
    ↓ match_started
  BOARD ──────────────────────────┐
    ↓ match_ended                 │
    ├─ winner=PLAYER → WIN ───────┤ "再来一局"
    ├─ winner=ENEMY  → LOSE ──────┤
    └─ winner=NONE   → DRAW ──────┘
```

### Visual Elements

#### 高亮叠加层

三个 `HighlightLayer` 节点（Node2D），位于 TileMapLayer 之后、Units 之前在场景树中。每个覆写 `_draw()` 并使用 `draw_rect()` 进行矩形绘制。通过设置瓦片数组并调用 `queue_redraw()` 进行更新。

| 层 | 节点 | 颜色 | z_index |
|----|------|------|---------|
| 移动范围 | `move_highlight_layer` | `#3B82F6` 蓝 | 1 |
| 路径预览 | `path_highlight_layer` | `#0891B2` 青 | 2 |
| 攻击目标 | `attack_highlight_layer` | `#EA580C` 橙 | 3 |

实现模式（伪代码）：

```
class_name HighlightLayer extends Node2D

var tiles: Array[Vector2i] = []
var color: Color
var grid_space: GridSpace

func set_highlight(p_tiles: Array[Vector2i]) -> void:
    tiles = p_tiles
    queue_redraw()

func _draw() -> void:
    var rect := Rect2(0, 0, TILE_SIZE, TILE_SIZE)
    for tile in tiles:
        rect.position = grid_space.grid_to_world(tile)
        draw_rect(rect, color)
```

#### HUD

所有 HUD 位于 CanvasLayer（第 0 层）：
- **回合指示器**：`"Turn 3/30"`，左上角
- **阵营指示器**：`"Player Turn"`（蓝 #3B82F6）或 `"Enemy Turn"`（红 #EF4444），左上角，紧挨回合指示器
- **End Turn 按钮**：`"End Turn"`，右下角，仅在 `FACTION_PHASE_ACTIVE` 时可见

#### 覆盖层界面

所有覆盖层位于 CanvasLayer（第 10 层），盖住 HUD：
- **WIN/LOSE/DRAW 界面**：全屏 `ColorRect` 背景（半透明深色，alpha 0.7）+ 标题 `Label`（大号字体）+ 原因 `Label` + "再来一局" `Button`。仅在 `match_ended` 信号后可见。背景 `mouse_filter = MOUSE_FILTER_STOP` 阻止点击穿透到棋盘。
- **调试叠加层**：每格 `Label`，显示 `(row, col)`。12px Godot 默认字体，白色。默认可见。反引号 `` ` `` 切换可见性。

#### 伤害预览

浮动的 `Label` 节点位于目标单位上方 `Vector2(0, -60)`（HP 标签位于 `-40`，伤害数字位于 `-60`——垂直堆叠）。悬停有效目标时创建/更新，鼠标移出或攻击提交后清除。攻击提交后在目标上方停留 600ms。

颜色规则：
- 伤害 ≥ 目标当前 HP → `#EF4444`（红）——"这一击将击杀"
- 伤害 < 目标当前 HP → `#F59E0B`（琥珀）——普通伤害预览
- 格式：`"-N"`（例如 `"-3"`），前缀减号，无 `+`，无 `"HP"` 标签

### States and Transitions

| 转移 | 触发条件 | 效果 |
|------|---------|------|
| `BOARD_IDLE` → `UNIT_SELECTED` | 左键点击可选中的己方单位 | 单位 `action_state` = SELECTED。计算移动范围 + 攻击范围。渲染高亮。缓存 `MovementResult`。 |
| `UNIT_SELECTED` → `UNIT_SELECTED`（切换） | 左键点击另一个可选中的己方单位 | 取消当前选中（`action_state` = IDLE）。选中新单位。重新计算高亮。 |
| `UNIT_SELECTED` → `BOARD_IDLE` | 右键 / Escape | 单位 `action_state` = IDLE。清除所有高亮。丢弃 `MovementResult`。 |
| `UNIT_SELECTED` → `ATTACK_TARGETING` | 左键点击可达瓦片（含自身瓦片 0 步移动） | `Map.move_unit(unit, from, to)`。单位 `action_state` = MOVED。清除移动/路径高亮。计算攻击目标。上下文 = ATTACK_TARGETING。 |
| `UNIT_SELECTED` → `BOARD_IDLE` | 左键点击射程内已高亮的敌方单位 | 直接攻击：`execute_attack()`。单位 SELECTED → ACTED。`has_acted` = true。伤害数字停留 600ms。 |
| `ATTACK_TARGETING` → `BOARD_IDLE` | 左键点击有效攻击目标 | `execute_attack()`。`action_state` = ACTED。`has_acted` = true。伤害数字停留 600ms。清除所有高亮。 |
| `ATTACK_TARGETING` → `BOARD_IDLE` | 右键 / Escape（跳过攻击） | 无伤害。`action_state` = ACTED。`has_acted` = true。清除所有高亮。 |
| 任意 → `WIN/LOSE/DRAW` | `match_ended` 信号 | 显示对应的结果覆盖层。HUD 隐藏。所有棋盘输入被忽略。 |
| `WIN/LOSE/DRAW` → `BOARD_IDLE` | 点击"再来一局" | 比赛重启。重新初始化所有系统。 |

### Interactions with Other Systems

| 上游系统 | 方向 | 数据流 | UI 消费的接口 |
|----------|------|--------|-------------|
| **Map** | 上行（读取） | 点击→瓦片解析，高亮放置，瓦片颜色 | `world_to_grid()`、`grid_to_world()`、`is_coord_in_bounds()`、`get_unit_at()`、瓦片状态查询 |
| **Map** | 上行（写入，通过 Input） | 移动执行 | `Map.move_unit(unit, from, to)` —— 由 Input 调用 |
| **Unit** | 上行（读取） | 单位属性读取，可选性检查 | `hp`/`max_hp`、`faction`、`grid_position`、`action_state`、`has_acted`、`can_be_selected()`、`can_move()`、`can_attack()` |
| **Unit** | 上行（写入，通过 Attack） | 攻击消耗 | `take_damage()`、`has_acted = true`、`action_state = ACTED` —— 通过 Attack 代理 |
| **Turn System** | 上行（读取） | HUD 状态，输入门禁 | `active_faction`、`turn_number`、`turn_cap`、`current_state`（全部只读） |
| **Turn System** | 上行（信号） | HUD 更新，界面过渡 | `match_started`、`turn_started`、`faction_activated`、`faction_phase_ended`、`match_ended` |
| **Turn System** | 下行（调用） | End Turn | `end_current_faction_turn()` —— 由 End Turn 按钮调用 |
| **Movement** | 上行（读取） | 移动范围和路径数据 | `MovementResolver.compute_reachable()` → `MovementResult.get_reachable_tiles()`、`get_path_to()`、`get_distance_to()` |
| **Attack** | 上行（读取） | 目标列表，伤害预览 | `AttackRangeResolver.get_valid_targets()`、`AttackResolver.resolve_damage()` |
| **Attack** | 上行（调用，通过 Input） | 攻击执行 | `AttackResolver.execute_attack()` —— 由 Input 调用 |
| **Victory** | 上行（信号，通过 Turn） | 结果界面数据 | `match_ended(reason, winner)` —— 由 Turn System 发出 |
| **AI** | 间接 | 热座模式 | NullAI 返回空 ActionList → Input 消费 `faction_activated(ENEMY)` 用于热座控制 |

## Formulas

UI / Input 是纯表现层——不拥有游戏状态，不定义数学公式。UI 消费上游系统的所有公式（`damage_formula`、Manhattan 距离、`determine_winner` 等）。本节仅记录 UI 特有的布局约束、颜色规则和可见性逻辑。

### F1: 瓦片世界位置

`tile_world_pos(row, col) = (col × TILE_SIZE, row × TILE_SIZE)`

**所有权**：Map GDD F1。UI 通过 `GridSpace.grid_to_world()` 消费。所有高亮叠加层和坐标解析均依赖此转换。

### F2: 点击→瓦片解析

`tile_grid_pos(x, y) = (floor(y / TILE_SIZE), floor(x / TILE_SIZE))`

**所有权**：Map GDD F2。UI 通过 `GridSpace.world_to_grid()` 消费。所有鼠标点击通过此公式解析为网格坐标。

### F3: UI 坐标系统

两套坐标空间，完全解耦：

| 空间 | 用途 | 原点 | 单位 |
|------|------|------|------|
| World Space | 棋盘渲染（TileMapLayer、高亮叠加层、单位） | 棋盘左上角 (0,0) | 像素（64px/瓦片） |
| Screen Space | HUD、覆盖层界面 | 窗口左上角 | 像素（CanvasLayer 锚定控制） |

棋盘世界空间坐标通过 `GridSpace.grid_to_world()` 与网格坐标互转。HUD 使用 CanvasLayer 锚定（`anchor_left=0, anchor_top=0` 左上角；`anchor_right=1, anchor_bottom=1` 右下角），与棋盘坐标空间完全解耦。

### F4: 伤害预览颜色选择

```
preview_color(atk, def, target_hp) =
    IF max(atk - def, 1) >= target_hp → Color("#EF4444")    # 击杀：红色
    ELSE                               → Color("#F59E0B")    # 普通：琥珀色
```

**变量：**

| 变量 | 符号 | 类型 | 范围 | 描述 |
|------|------|------|------|------|
| 攻击者 ATK | atk | int | [3, 8] | 来自 UnitStats |
| 防御者 DEF | def | int | [0, 5] | 来自 UnitStats |
| 目标 HP | target_hp | int | [1, 20] | 目标当前生命值 |
| 输出颜色 | color | Color | 两种可能值 | 琥珀 #F59E0B（普通），红 #EF4444（击杀） |

**输出**：两种颜色之一。纯展示用途——不影响伤害施加。底层伤害值 `resolve_damage(atk, def)` 由 Attack GDD F4 定义。

**示例**：ATK=5, DEF=2, target_hp=3 → `max(5-2, 1) = 3 ≥ 3` → 红色（击杀）。ATK=5, DEF=2, target_hp=10 → `3 < 10` → 琥珀（非击杀）。

### F5: HUD 元素可见性

| HUD 元素 | 可见条件 | 隐藏条件 |
|----------|---------|---------|
| 回合指示器 | `current_state ∈ {FACTION_PHASE_ACTIVE, FACTION_PHASE_ENDING}` | `MATCH_NOT_STARTED`, `MATCH_ENDED` |
| 阵营指示器 | 同上 | 同上 |
| End Turn 按钮 | `current_state == FACTION_PHASE_ACTIVE` | 所有其他状态 |
| 高亮叠加层 | `current_state == FACTION_PHASE_ACTIVE AND input_context ∈ {UNIT_SELECTED, ATTACK_TARGETING}` | 所有其他条件 |
| 伤害预览 | `input_context == ATTACK_TARGETING AND hover_target != null` | 所有其他条件 |
| 结果覆盖层 | `current_state == MATCH_ENDED` | 所有其他状态 |
| 调试叠加层 | 反引号切换（默认开启） | 再次按反引号 |

## Edge Cases

### 输入时序

- **若玩家在 FACTION_PHASE_ENDING 期间点击棋盘**：`current_state` 守卫拒绝。点击静默忽略。MVP 阶段转换是同步的（同帧完成），正常游玩不可达——守卫为未来异步转换而存在。

- **若玩家快速双击同一瓦片**：MVP 中所有操作同步且原子——第一次点击执行动作并转换状态，第二次点击在新状态下评估（可能被拒绝）。无动画窗口使双击成为问题。

- **若玩家在 ATTACK_TARGETING 进入的同帧内快速点击攻击目标**：同步执行——移动先完成，攻击瞄准进入，同帧处理攻击点击。无竞态条件。若未来实现引入 `await` 则需守卫。

- **若按下 End Turn 的同时正在进行另一操作**：输入优先级链处理——End Turn 按钮由 `gui_input` 消费（CanvasLayer），棋盘点击由 `_unhandled_input` 处理。按钮消费事件后棋盘不接收。同帧只触发其一。

### 边界与极限

- **若地图尺寸为 8×8（最小）且单位 MOV=6**：高亮瓦片数受地图边界自然裁剪。`HighlightLayer._draw()` 绘制 ≤36 个瓦片——无性能问题。

- **若地图尺寸为 32×32（最大）且全高亮**：MVP 仅单选——最多 ~85 移动瓦片 + ~24 攻击瓦片 + ~6 路径瓦片 = ~115 个矩形。`_draw()` 使用单个绘制调用——GPU 开销可忽略。

- **若窗口在比赛期间被调整大小**：CanvasLayer 锚定自动处理 HUD 重新定位。棋盘世界空间不受窗口尺寸影响（坐标空间隔离）。若棋盘超出窗口边界，MVP 无滚动摄像机——建议窗口 ≥ 1024×768 以确保 16×12 地图在 64px/瓦片下完全可见。

- **若玩家点击恰好位于瓦片边缘的像素（例如 x=64.0）**：`floor()` 解析为更高索引的瓦片——与 Map GDD F2 行为一致。

### 选中与取消

- **若选中单位后该单位因外部原因死亡**（MVP 中不可能——无延迟伤害/陷阱）：若未来 Tier 引入，`unit_died` 信号连接到 `InputHandler`——若死亡单位 == 被选中单位，清除选中和高亮，上下文 → BOARD_IDLE。MVP 预留守卫。

- **若玩家先点击己方单位选中，再对另一个己方单位按右键**：右键 = 取消——清除选中，不切换。右键仅取消，不重新选择。

- **若玩家在 ATTACK_TARGETING 中点击空地**：按 A2 规则忽略——空地不是有效攻击目标。玩家必须按 Escape/右键跳过或点击有效目标攻击。

- **若 End Turn 前最后一个未行动单位恰好进入 ATTACK_TARGETING**：玩家仍可点击目标攻击或跳过。攻击或跳过后 `has_acted = true` → auto-advance 立即触发。无死锁。

### HUD 与覆盖层

- **若 TurnManager 在 UI 元素初始化之前发射 `match_started` 信号**：延迟连接的 UI 在 `_ready()` 中轮询 `TurnManager.current_state`、`active_faction`、`turn_number`——与 Turn GDD AC-TURN-053 的延迟信号连接契约一致。

- **若 `match_ended` 信号携带异常参数**（`winner=NONE, reason=""` 在比赛终止时不可能——按 Victory GDD F3）：若收到，显示 DRAW 画面作为兜底。

- **若玩家在结果覆盖层显示期间按 Escape 或反引号**：结果覆盖层的 `MOUSE_FILTER_STOP` 阻止所有键盘/鼠标交互穿透到棋盘。仅"再来一局"按钮响应点击。

### 调试叠加层

- **若地图为 32×32 且调试叠加层开启**：1024 个 Label 节点。Godot 的 Control 批量渲染可处理；MVP 阶段可接受。若出现性能问题，降级为仅渲染可视区域内的坐标。

- **若调试叠加层切换键与系统快捷键冲突**：反引号 `` ` `` 通常不与游戏操作冲突。若发生冲突，通过 InputMap 重新绑定。

### 渲染

- **若 `_draw()` 在每帧都被调用**（而非仅在 `queue_redraw()` 时）：性能无影响——115 个矩形 < 1ms。但通过仅在数据变更时调用 `queue_redraw()` 来遵循最佳实践。

## Dependencies

### 上游依赖

| 系统 | 类型 | 消费的接口 | 备注 |
|------|------|-----------|------|
| **Map** | Hard | `world_to_grid()`、`grid_to_world()`、`is_coord_in_bounds()`、`get_unit_at()`、瓦片状态查询；`move_unit(unit, from, to)` | 接口由 Map GDD 锁定。无 Map，UI 无法解析点击或放置高亮 |
| **Unit** | Hard | `hp`/`max_hp`、`faction`、`grid_position`、`action_state`、`has_acted`、`can_be_selected()`、`can_move()`、`can_attack()`、`unit_died` 信号 | 接口由 Unit GDD 锁定。Unit 拥有其视觉节点（ColorRect + HP Label）——UI 不创建单位视觉 |
| **Turn System** | Hard | `active_faction`、`turn_number`、`turn_cap`、`current_state`（只读）；`match_started`、`turn_started`、`faction_activated`、`faction_phase_ended`、`match_ended` 信号；`end_current_faction_turn()` | 接口由 Turn GDD 锁定。Turn 是 UI 状态更新的主数据源和节奏控制器 |
| **Movement** | Hard | `MovementResolver.compute_reachable(unit, map) → MovementResult`；Result API：`get_reachable_tiles()`、`get_path_to()`、`get_distance_to()`、`get_start_tile()` | 接口由 Movement GDD 锁定。无 MovementResolver，无移动高亮 |
| **Attack** | Hard | `AttackRangeResolver.get_valid_targets(unit, map) → Array[Unit]`；`AttackResolver.resolve_damage(atk, def) → int`；`AttackResolver.execute_attack(attacker, target) → AttackResult` | 接口由 Attack GDD 锁定。无 Attack，无攻击高亮、无伤害预览 |
| **Victory** | Hard（间接，通过 Turn） | `match_ended(reason, winner)` 信号 | 由 Turn System 发出。UI 消费用于结果画面 |
| **AI** | Soft（仅 MVP 热座） | NullAI 返回空 ActionList —— Input 消费 `faction_activated(ENEMY)` 用于热座控制 | AI 不直接与 UI 交互。Tier 2 BasicAI 不引入新的 UI 元素——移动和攻击高亮由 Movement/Attack 覆盖 |

所有七个上游依赖均为 **hard**——缺少任意一个，UI 的相应功能将不可见/不可操作。

### 下游依赖

无——UI / Input 是表现层终端节点。没有系统依赖 UI。游戏逻辑在 UI 完全缺失的情况下仍正常运行（只是不可见、不可操作）。

### 外部依赖

| 依赖 | 类型 | 备注 |
|------|------|------|
| `InputHandler`（RefCounted） | Code | 输入协调器。DI 注入到 Board。消费所有上游系统，不拥有游戏逻辑 |
| `HighlightLayer`（Node2D） | Code | `_draw()` 高亮渲染。3 个实例——移动、路径、攻击 |
| `TurnManager`（RefCounted） | Code | Turn System 持有。UI 读取其属性和连接其信号 |
| `GridSpace`（RefCounted） | Code | Map 持有。UI 通过它进行坐标转换 |
| `Faction.Type` enum | Code | 定义在 `src/core/faction.gd`。UI 读取用于颜色映射和阵营指示器文本 |
| `InputMap` | Engine | Godot 的抽象输入动作系统。定义 `end_turn` 动作。End Turn 按钮触发此动作 |

## Tuning Knobs

| Knob | 位置 | 安全范围 | 过低的影响 | 过高的影响 | 备注 |
|------|------|---------|-----------|-----------|------|
| 伤害预览停留时间 | `DamagePreview` 常量 | [0, 2000] ms | 0：伤害数字闪现，玩家无法确认结果 | >1000：数字遮挡后续悬停交互 | MVP 固定 600ms（Attack GDD 规定） |
| 调试叠加层字体大小 | `DebugOverlay` 常量 | [8, 24] px | 低于 8px：在 64px 瓦片上不可读 | 高于 24px：相邻瓦片的文本重叠 | MVP 固定 12px |
| 窗口最小尺寸 | 项目设置 | [512×384, 3840×2160] | 低于 512×384：8×8 地图在 64px/瓦片下无法完整显示 | N/A | MVP 建议 ≥ 1024×768（16×12 × 64 = 1024×768） |
| 调试叠加层默认状态 | `DebugOverlay` 布尔值 | {true, false} | N/A | N/A | MVP 默认 ON |
| 调试叠加层切换键 | InputMap | 任意未使用的键 | N/A | N/A | MVP 固定为反引号 `` ` `` |

**无自有可调参数**：UI 绝大多数的"可调参数"由上游系统持有——`TILE_SIZE`（Map）、`turn_cap`（Turn）、`unit.mov`（Unit）、伤害公式参数（Attack）、颜色 token（各 GDD + 艺术圣经）。UI 是纯消费者——当上游值变化时 UI 自动反映，无需独立调校。

**Knob 交互关系**：伤害预览停留时间与游玩节奏交互——600ms 足以确认结果但不过度打断流程。若未来 Tier 引入攻击动画，停留时间应与之协调（例如动画结束后 + 200ms）。

## Visual/Audio Requirements

### 网格

- **瓦片渲染**：TileMapLayer，3 种 atlas 瓦片对应 3 种状态。64×64px 纯色。颜色：TILE_DEFAULT `#374151` · TILE_BLOCKED `#111827` · TILE_OBSTACLE `#1F2937`
- **网格线**：相邻瓦片之间的颜色对比度足以区分瓦片边界。无额外网格线渲染——减少视觉噪音，与 Programmer Art Functional 一致
- **无动画**：瓦片静态。地图加载后不变

### 高亮叠加层

三个 `HighlightLayer` 节点（Node2D），使用 `draw_rect()` 绘制不透明纯色矩形：

| 层 | 颜色 | Hex | z_index |
|----|------|-----|---------|
| 移动范围 | 青 | `#0891B2` | 1 |
| 路径预览 | 亮青 | `#06B6D4` | 2 |
| 攻击目标 | 橙 | `#EA580C` | 3 |

- **起始瓦片区分**：移动高亮层中，起始瓦片（单位当前位置）以 2px 宽同色系 `draw_rect` 边框包裹
- **路径叠层**：路径高亮（z=2）在移动高亮（z=1）之上绘制。路径瓦片覆盖其下方的移动瓦片
- **攻击目标叠层**：攻击高亮（z=3）在路径和移动高亮之上绘制。一个瓦片可以同时有移动高亮和攻击高亮——攻击高亮在上层，优先级更高
- **全部不透明**：alpha = 1.0。遵守艺术圣经 §4.4 禁止低于 90% 不透明度的规则

### 单位

- **所有权**：Unit 场景拥有所有单位视觉元素——UI 不创建或管理
- **ColorRect**：48×48px，在 64×64 瓦片内居中。阵营颜色：PLAYER `#3B82F6`（蓝）· ENEMY `#EF4444`（红）
- **HP Label**：位于单位上方 `Vector2(0, -40)`。格式 `"HP: 8/10"`。Godot 默认字体，14px，白色
- **已行动外观**：`Color.GRAY` modulate，50% 透明度
- **选中指示**：选中单位渲染 2px 宽的白色边框（`draw_rect`，不填充，`#FFFFFF`）。边框颜色与阵营无关——白色在任何单位颜色上都清晰可见

### HUD

全部位于 CanvasLayer 第 0 层，Godot 默认字体：

| 元素 | 位置 | 字体 | 颜色 |
|------|------|------|------|
| 回合指示器 `"Turn X/Y"` | 左上角，距边缘 16px | 18px | 白色 `#FFFFFF` |
| 阵营指示器 `"Player Turn"` / `"Enemy Turn"` | 左上角，回合指示器下方 4px | 16px | PLAYER=`#3B82F6` · ENEMY=`#EF4444` |
| End Turn 按钮 | 右下角，距边缘 16px | 16px | 深色背景 `#1F2937` · 白色文字 · 8px 圆角 · 最小 120×40px |

- **按钮样式**：Godot `StyleBoxFlat`。背景 `#1F2937`，文字 `#FFFFFF`，corner_radius 8px。悬停时背景变亮至 `#374151`。点击时不变（MVP 无动画）

### 伤害预览数字

- **位置**：目标单位中心上方 `Vector2(0, -60)`（HP 标签在 -40，伤害数字在 -60——垂直堆叠）
- **格式**：`"-N"`（例如 `"-3"`），前缀减号，无 `+`，无 `"HP"` 标签
- **字体**：Godot 默认字体，20px，加粗
- **颜色**：非击杀 `#F59E0B`（琥珀）· 击杀 `#EF4444`（红）
- **停留**：攻击提交后在目标上方保持 600ms，然后消失。无淡出动画——直接消失
- **背景**：无背景，透明。数字直接渲染在棋盘上

### 结果覆盖层

全部位于 CanvasLayer 第 10 层。全屏 `ColorRect` 背景遮罩：

- **背景**：`#000000`，alpha 0.75。深色半透明——最终棋盘状态在下方隐约可见
- **标题**：Godot 默认字体，48px，加粗，居中。VICTORY=`#10B981`（绿）· DEFEAT=`#EF4444`（红）· DRAW=`#9CA3AF`（灰）
- **原因文字**：Godot 默认字体，20px，居中，位于标题下方 16px，白色 `#FFFFFF`
- **"再来一局"按钮**：居中，位于原因文字下方 32px。样式：`StyleBoxFlat`，`#1F2937` 背景，白色文字，8px 圆角，120×40px
- **输入阻止**：背景 `ColorRect` 的 `mouse_filter = MOUSE_FILTER_STOP`——阻止所有点击和键盘事件穿透到棋盘

### 调试叠加层

- **内容**：每个瓦片中心显示白色 `(row, col)` 文本
- **字体**：Godot 默认字体，12px，白色 `#FFFFFF`
- **对齐**：居中于瓦片（`grid_to_world(r,c) + Vector2(32, 32)` 作为 Label 中心）
- **切换**：反引号 `` ` `` 键切换可见性。默认 ON
- **性能说明**：32×32 地图 = 1024 个 Label 节点。Godot Control 批量渲染可处理。禁用时节点 `visible = false`

### 光标样式

| 悬停目标 | 光标 | Godot 常量 |
|---------|------|-----------|
| 可选中的己方单位 | 手形指针 | `Input.CURSOR_POINTING_HAND` |
| 可达瓦片（移动范围） | 手形指针 | `Input.CURSOR_POINTING_HAND` |
| 有效攻击目标 | 十字 | `Input.CURSOR_CROSS` |
| 所有其他区域 | 默认箭头 | `Input.CURSOR_ARROW` |

### 音频

**无。** 根据 game-concept.md 反支柱和 MVP 范围明确排除。所有 UI 操作无声——无点击音效、无悬停音效、无过渡音效、无胜利/失败主题音。`match_ended` 信号是未来音频系统可以连接、无需修改 UI 代码的钩子。

> 📌 **Asset Spec** — 视觉需求已定义。美术圣经批准后运行 `/asset-spec system:ui` 以生成 HUD、覆盖层和叠加层的视觉描述和生成提示。

## UI Requirements

UI / Input **即为** UI 系统本身——UI Requirements 即为本 GDD 的全部内容。其他系统对本系统的 UI 期望汇总如下：

### 上游系统对本系统的 UI 期望

| 上游系统 | 期望 UI 提供 | 来源 |
|----------|-------------|------|
| **Map** | 网格渲染（TileMapLayer 三种瓦片色）、调试坐标叠加层（`world_to_grid` / `grid_to_world` 消费者） | Map GDD §Interactions |
| **Unit** | 单位选中高亮（白色边框）、行动状态视觉区分（已行动 = 灰色 50% 透明度）、HP 标签渲染（Unit 持有节点，UI 不创建） | Unit GDD §Visual/Audio、§UI Requirements |
| **Turn System** | 回合指示器（`"Turn X/Y"`）、阵营指示器（`"Player/Enemy Turn"`）、End Turn 按钮（调用 `end_current_faction_turn()`） | Turn GDD §UI Requirements |
| **Movement** | 移动范围高亮（蓝色→青色 #0891B2）、路径预览（亮青 #06B6D4）、起始瓦片区分 | Movement GDD §Visual/Audio、§UI Requirements |
| **Attack** | 攻击目标高亮（橙色 #EA580C）、伤害预览数字（琥珀/红色，-60px 偏移，600ms 停留）、攻击确认执行 | Attack GDD §Visual/Audio、§UI Requirements |
| **Victory** | WIN/LOSE/DRAW 覆盖层画面（消费 `match_ended` 信号） | Victory GDD §UI Requirements |
| **AI** | 热座模式：消费 `faction_activated(ENEMY)` 允许玩家手动操作敌方单位 | AI GDD §UI Requirements（间接） |

### UX 标记

> 📌 **UX Flag — UI / Input**：本系统即为 UI 系统。在 Phase 4（Pre-Production），运行 `/ux-design` 为以下界面创建 UX 规范（本 GDD 定义 WHAT，UX 规范定义具体布局和交互细节）：
> - `design/ux/hud.md` — HUD 布局（回合指示器、阵营指示器、End Turn 按钮）
> - `design/ux/board-interaction.md` — 棋盘交互流程（选中→移动→攻击→取消）
> - `design/ux/result-screen.md` — 结果画面（WIN/LOSE/DRAW）
> - `design/ux/debug-overlay.md` — 调试叠加层
>
> 在 systems index 中为本系统记录此事项。

## Acceptance Criteria

### A. 输入解析（16 条）

**AC-UI-001 — 点击坐标解析（A1）** [Logic]
GIVEN 棋盘已渲染，地图为 16×12，TILE_SIZE=64，WHEN 玩家在屏幕坐标 (320, 192) 处左键点击，THEN 点击被解析为网格坐标 Vector2i(3, 5)。

**AC-UI-002 — 棋盘外点击静默忽略（A1）** [Integration]
GIVEN 棋盘区域为 (0,0) 到 (1024, 768)，WHEN 玩家在棋盘边界外点击，THEN 无任何单位被选中，无高亮出现，游戏状态不变。

**AC-UI-003 — BOARD_IDLE 点击己方单位 → 选中（A2）** [Integration]
GIVEN 玩家回合进行中，无单位被选中，存在 IDLE 己方单位，WHEN 玩家左键点击该单位所在瓦片，THEN 该单位被选中（白色边框），其移动范围以青色显示。

**AC-UI-004 — BOARD_IDLE 点击敌方单位/空地 → 忽略（A2）** [Integration]
GIVEN 玩家回合进行中，无单位被选中，WHEN 玩家点击敌方单位或空地瓦片，THEN 无任何反应——无选中、无高亮。

**AC-UI-005 — 点击另一己方单位 → 切换选中（A2）** [Integration]
GIVEN 单位 A 已被选中（蓝移动范围可见），另有 IDLE 单位 B，WHEN 玩家点击单位 B，THEN A 的选中取消，B 被选中（移动范围切换至 B）。

**AC-UI-006 — UNIT_SELECTED 点击可达瓦片 → 移动（A2）** [Integration]
GIVEN 己方单位已选中，可达瓦片包括 (6,5)，WHEN 玩家点击 (6,5)，THEN 单位移动至 (6,5)，移动高亮清除，进入攻击瞄准。

**AC-UI-007 — UNIT_SELECTED 点击攻击范围内敌人 → 直接攻击（A2）** [Integration]
GIVEN 己方单位已选中，攻击范围内有橙色高亮敌方单位，WHEN 玩家点击该敌方单位，THEN 攻击立即执行——单位保持原位、变为已行动、所有高亮清除。

**AC-UI-008 — ATTACK_TARGETING 点击有效目标 → 攻击（A2）** [Integration]
GIVEN 单位已移动完毕，橙色攻击高亮可见，WHEN 玩家点击一个橙色高亮敌人，THEN 攻击执行——伤害数字显示并停留 600ms，攻击者变灰，所有高亮清除。

**AC-UI-009 — ATTACK_TARGETING 点击空地 → 忽略（A2）** [Integration]
GIVEN 单位处于攻击瞄准状态，WHEN 玩家点击无橙色高亮的空地瓦片，THEN 无反应——保持攻击瞄准状态。

**AC-UI-010 — 悬停可达瓦片显示路径预览（A3）** [Integration]
GIVEN 己方单位已选中，蓝色移动范围可见，WHEN 玩家悬停某个可达瓦片，THEN 从起始瓦片到悬停瓦片的路径以亮青(#06B6D4)高亮显示。

**AC-UI-011 — 悬停非可达瓦片清除路径（A3）** [Integration]
GIVEN 路径预览可见，WHEN 玩家将鼠标移到非可达瓦片，THEN 路径高亮消失。

**AC-UI-012 — 悬停攻击目标显示伤害预览（A3）** [Integration]
GIVEN 攻击瞄准状态，WHEN 玩家悬停有效的橙色高亮敌方单位，THEN 敌方单位头顶出现伤害数字 "-N"，琥珀(#F59E0B)或红(#EF4444)。

**AC-UI-013 — 悬停非攻击目标清除伤害预览（A3）** [Integration]
GIVEN 伤害预览数字可见，WHEN 玩家鼠标移出敌方单位，THEN 伤害预览数字消失。

**AC-UI-014 — Escape 取消选中（A4）** [Integration]
GIVEN 己方单位已选中，WHEN 玩家按 Escape 或右键，THEN 选中取消——高亮清除，单位恢复未选中外观。

**AC-UI-015 — Escape 跳过攻击（A4）** [Integration]
GIVEN 攻击瞄准状态，WHEN 玩家按 Escape 或右键，THEN 攻击跳过——无伤害，单位变灰（已行动），所有高亮清除。

**AC-UI-016 — 无选中时 Escape 无效果（A4）** [Integration]
GIVEN BOARD_IDLE 状态，WHEN 玩家按 Escape，THEN 无任何变化。

### B. 交互流程（10 条）

**AC-UI-017 — 完整选中→移动→攻击循环（B1, B2）** [Integration]
GIVEN 玩家回合进行中，一个 IDLE 己方单位可从起始瓦片移动并攻击到敌方，WHEN 玩家依次执行：点击选中 → 点击可达瓦片 → 点击攻击目标，THEN 单位移动至目标瓦片，攻击敌方（伤害数字显示），单位变为灰色，所有高亮清除。

**AC-UI-018 — 选中后同时显示移动和攻击范围（B2）** [Integration]
GIVEN 玩家回合中，IDLE 己方单位位于 (4,5)、MOV=3、RNG=2，WHEN 玩家点击该单位，THEN (a) BFS 可达瓦片以青色(#0891B2)高亮，(b) 起始瓦片有边框区分，(c) 当前位置可直接攻击的敌方单位以橙色(#EA580C)高亮。

**AC-UI-019 — 移动后清除移动预览，进入攻击瞄准（B2）** [Integration]
GIVEN 己方单位已选中，移动和攻击高亮可见，WHEN 玩家点击可达瓦片完成移动，THEN 移动高亮清除，若有可攻击敌人则显示橙色攻击高亮，若无则单位直接变灰。

**AC-UI-020 — 攻击预览伤害数字颜色正确（B2）** [Integration]
GIVEN 攻击瞄准状态，攻击者 ATK=5，悬停敌方 DEF=2、HP=3，WHEN 玩家悬停该敌方，THEN 显示 "-3" 且为红色(#EF4444)——击杀预览。GIVEN HP=10，THEN "-3" 且为琥珀(#F59E0B)。

**AC-UI-021 — 攻击提交后伤害数字停留（B2）** [Integration]
GIVEN 攻击瞄准状态，WHEN 玩家点击目标执行攻击，THEN 伤害数字在目标上方停留约 0.6 秒后消失，攻击者变灰。

**AC-UI-022 — 跳过攻击消耗行动（B2）** [Integration]
GIVEN 攻击瞄准状态，有可攻击敌人，WHEN 玩家按 Escape 跳过攻击，THEN 单位变灰（已行动），不造成伤害，该单位本回合不可再次选中。

**AC-UI-023 — 从选中状态直接攻击（B3）** [Integration]
GIVEN 己方单位已选中，当前位置可直接攻击橙色高亮敌人，WHEN 玩家点击该敌人（未先移动），THEN 攻击立即执行——单位保持原位、变灰、所有高亮清除。

**AC-UI-024 — 移动后无可攻击目标自动结束（B4）** [Integration]
GIVEN 己方单位已选中，从某可达瓦片出发无任何敌方在攻击范围内，WHEN 玩家点击该瓦片移动，THEN 单位移动后立即变灰——无空攻击选项展示。

**AC-UI-025 — 阶段完成时清除所有 UI 状态（B5）** [Integration]
GIVEN 玩家回合中，最后未行动单位完成行动或按 End Turn，WHEN Turn System 触发阶段结束，THEN 所有高亮清除，选中取消，回合指示器更新。

**AC-UI-026 — 十大禁止操作（B6）** [Integration]
GIVEN 玩家回合进行中，WHEN 玩家依次尝试：点击敌方单位、点击空地（无选中）、点击已变灰单位、点击不可达瓦片（选中后）、点击射程外敌人（攻击瞄准时）、在 MATCH_ENDED 后点击棋盘，THEN 所有操作均被静默忽略——无选中变化、无高亮变化、无报错。

### C. 约束与门禁（7 条）

**AC-UI-027 — Turn 状态门禁（C1）** [Logic]
GIVEN current_state 非 FACTION_PHASE_ACTIVE，WHEN 玩家在棋盘任意位置点击，THEN 点击被忽略。

**AC-UI-028 — 活跃阵营门禁（C2）** [Logic]
GIVEN 活跃阵营为 ENEMY，棋盘上有玩家 IDLE 单位，WHEN 玩家点击己方单位，THEN 己方单位不可被选中。

**AC-UI-029 — 单位行动状态门禁（C3）** [Logic]
GIVEN 玩家回合中，WHEN 尝试点击 MOVED 单位进行移动，或点击 ACTED 单位选中，THEN MOVED 单位不可移动（只可攻击/跳过），ACTED 单位不可选中。

**AC-UI-030 — has_acted 门禁（C4）** [Logic]
GIVEN 己方单位 has_acted=true（已变灰），WHEN 玩家点击该单位，THEN 无反应——不可选中。

**AC-UI-031 — End Turn 按钮仅在活跃阶段可见（C6）** [Integration]
GIVEN current_state 为 MATCH_ENDED 或 MATCH_NOT_STARTED，WHEN 查看屏幕右下角，THEN End Turn 按钮不可见。

**AC-UI-032 — End Turn 按钮在活跃阶段可见且可点击（C6）** [Integration]
GIVEN current_state == FACTION_PHASE_ACTIVE，WHEN 查看屏幕右下角，THEN "End Turn" 按钮可见且可点击。

**AC-UI-033 — 选中单位时按 End Turn 放弃行动（C6）** [Integration]
GIVEN 玩家回合中，己方单位已选中，WHEN 玩家点击 End Turn，THEN 选中取消，高亮清除，未行动单位丧失本轮行动，进入 FACTION_PHASE_ENDING。

### D. 渲染组织（6 条）

**AC-UI-034 — 图层顺序（D1）** [Visual]
GIVEN 单位已选中且处于攻击瞄准（移动高亮、路径、攻击高亮、单位、伤害预览同时可见），WHEN 目视检查，THEN 图层从下到上为：网格 → 移动高亮 → 路径 → 攻击高亮 → 单位+HP标签 → 伤害数字(-60px)。

**AC-UI-035 — 高亮颜色规范（D2）** [Visual]
GIVEN 单位已选中 + 路径预览可见 + 攻击目标高亮 + 伤害预览（普通+击杀），WHEN 目视检查，THEN 移动=#0891B2青、路径=#06B6D4亮青、攻击目标=#EA580C橙、普通伤害=#F59E0B琥珀、击杀伤害=#EF4444红。

**AC-UI-036 — 移动高亮生命周期（D3）** [Integration]
GIVEN 玩家回合中，WHEN 点击己方单位（高亮出现）→ 按 Escape，THEN 移动高亮消失。再次点击→移动至可达瓦片→移动高亮在移动后消失。

**AC-UI-037 — 攻击高亮生命周期（D3）** [Integration]
GIVEN 攻击瞄准状态，WHEN 按 Escape 跳过攻击，THEN 攻击高亮消失。再次：移动后点击敌人执行攻击→攻击高亮消失。

**AC-UI-038 — 路径高亮生命周期（D3）** [Integration]
GIVEN 己方单位已选中，WHEN 悬停瓦片 A（路径出现）→ 悬停瓦片 B（路径更新）→ 鼠标移出所有可达瓦片，THEN 路径高亮消失。

**AC-UI-039 — 调试坐标叠加层（D4）** [Visual]
GIVEN 比赛进行中，WHEN 按反引号 `` ` ``，THEN 每格显示白色 "(row,col)" 坐标（12px）。再次按 → 隐藏。默认可见。

### E. HUD 元素（5 条）

**AC-UI-040 — 回合指示器（E1）** [Integration]
GIVEN turn_number=3, turn_cap=30，WHEN 查看屏幕左上角，THEN 显示 "Turn 3/30"。

**AC-UI-041 — 阵营指示器（E2）** [Integration]
GIVEN 活跃阵营为 ENEMY，WHEN 查看回合指示器旁边，THEN 显示红色 "Enemy Turn"。切换到 PLAYER 时显示蓝色 "Player Turn"。

**AC-UI-042 — End Turn 按钮（E3）** [Visual]
GIVEN FACTION_PHASE_ACTIVE，WHEN 查看屏幕右下角，THEN 可见标签 "End Turn" 的可点击按钮。

**AC-UI-043 — HUD 不受世界摄像机影响（E4）** [Visual]
GIVEN 比赛进行中，HUD 可见，WHEN 摄像机发生平移/缩放，THEN HUD 固定在屏幕角落——不随棋盘移动。

**AC-UI-044 — HP 标签所有权（E5）** [Structural]
GIVEN 单位场景中有 HP Label，WHEN 检查其所属关系，THEN HP Label 归 Unit 场景所有（位于单位上方 -40px），不由 UI/Input 系统创建。

### F. 屏幕状态（5 条）

**AC-UI-045 — BOARD 屏幕（F1）** [Integration]
GIVEN match_started 信号已发出，WHEN 查看屏幕，THEN 显示完整棋盘：网格、单位、HUD，无覆盖层。

**AC-UI-046 — WIN 画面（F1, F4）** [Integration]
GIVEN 敌方全灭，match_ended("elimination", PLAYER) 已发出，WHEN 查看屏幕，THEN 半透明深色覆盖层显示绿色 "VICTORY" + 原因文字 + "再来一局"按钮。

**AC-UI-047 — LOSE 画面（F1, F4）** [Integration]
GIVEN 玩家全灭或回合上限敌方存活多，match_ended(_, ENEMY) 已发出，WHEN 查看屏幕，THEN 覆盖层显示红色 "DEFEAT" + 原因文字 + "再来一局"按钮。

**AC-UI-048 — DRAW 画面（F1, F4）** [Integration]
GIVEN 回合上限到达且存活数相等，match_ended("turn_cap", NONE) 已发出，WHEN 查看屏幕，THEN 覆盖层显示灰色 "DRAW" + "回合上限到达" + "再来一局"按钮。

**AC-UI-049 — 屏幕过渡（F2, F3）** [Integration]
GIVEN WIN/LOSE/DRAW 覆盖层显示中，WHEN 点击 "再来一局"，THEN 比赛重新开始——覆盖层消失，棋盘重新显示，HUD 重置为 Turn 1。

### G. 公式（5 条）

**AC-UI-050 — 伤害预览颜色：击杀（F4）** [Logic]
GIVEN ATK=6, DEF=2, target_hp=4，WHEN UI 计算 preview_color，THEN damage=max(6-2,1)=4≥4 → 返回 #EF4444（红）。

**AC-UI-051 — 伤害预览颜色：非击杀（F4）** [Logic]
GIVEN ATK=5, DEF=4, target_hp=6，WHEN UI 计算 preview_color，THEN damage=max(5-4,1)=1<6 → 返回 #F59E0B（琥珀）。

**AC-UI-052 — 伤害预览颜色：最小伤害边界（F4）** [Logic]
GIVEN ATK=2, DEF=5, target_hp=1，WHEN UI 计算 preview_color，THEN damage=max(2-5,1)=1≥1 → 返回 #EF4444（最小伤害 1 恰好等于 HP=1，仍是击杀）。

**AC-UI-053 — HUD 可见性：回合/阵营指示器（F5）** [Integration]
GIVEN current_state 经过 MATCH_NOT_STARTED → FACTION_PHASE_ACTIVE → FACTION_PHASE_ENDING → MATCH_ENDED，WHEN 检查，THEN 在 FACTION_PHASE_ACTIVE 和 FACTION_PHASE_ENDING 期间可见；MATCH_NOT_STARTED 和 MATCH_ENDED 期间隐藏。

**AC-UI-054 — HUD 可见性：End Turn 按钮（F5）** [Integration]
GIVEN current_state=FACTION_PHASE_ACTIVE，THEN 按钮可见。WHEN 变为 FACTION_PHASE_ENDING 或 MATCH_ENDED，THEN 按钮隐藏。

### H. 输入状态机（3 条）

**AC-UI-055 — BOARD_IDLE → UNIT_SELECTED 转移** [Integration]
GIVEN BOARD_IDLE，玩家回合中，存在 IDLE 己方单位，WHEN 玩家点击该单位，THEN 状态变为 UNIT_SELECTED——移动和攻击高亮出现。

**AC-UI-056 — UNIT_SELECTED → ATTACK_TARGETING 转移** [Integration]
GIVEN UNIT_SELECTED，己方单位已选中，WHEN 玩家点击可达瓦片，THEN 状态变为 ATTACK_TARGETING——移动高亮清除，攻击高亮出现。

**AC-UI-057 — ATTACK_TARGETING → BOARD_IDLE 转移** [Integration]
GIVEN ATTACK_TARGETING，攻击高亮可见，WHEN 玩家点击有效目标，THEN 攻击执行——伤害数字停留 600ms，攻击者变灰，状态回到 BOARD_IDLE。

### I. 边界情况（6 条）

**AC-UI-058 — 双击同一瓦片（Edge: 输入时序）** [Integration]
GIVEN 己方单位已选中，可达瓦片 (5,5) 高亮，WHEN 玩家快速双击 (5,5)，THEN 第一次点击移动（→ATTACK_TARGETING），第二次点击在攻击瞄准下被忽略——单位不产生异常状态。

**AC-UI-059 — 窗口调整大小后 HUD 保持定位（Edge: 边界）** [Visual]
GIVEN HUD 元素正在显示，WHEN 调整窗口大小，THEN HUD 通过 CanvasLayer 锚定保持在正确屏幕角落。棋盘世界坐标不受影响。

**AC-UI-060 — 点击瓦片边缘像素（Edge: 边界）** [Logic]
GIVEN TILE_SIZE=64，玩家点击 x=64.0, y=0（列 0 和列 1 的边界），WHEN floor(y/64)=0, floor(x/64)=1，THEN 解析为 (row=0, col=1)——与 Map GDD F2 一致。

**AC-UI-061 — 选中单位后该单位死亡（Edge: 选中与取消）** [Structural]
GIVEN 未来 Tier 引入延迟伤害，被选中单位因外部原因死亡（unit_died 信号），WHEN UI 收到信号，THEN 清除该单位的选中和高亮，上下文回到 BOARD_IDLE。MVP 预留守卫。

**AC-UI-062 — match_ended 携带异常参数（Edge: 覆盖层）** [Integration]
GIVEN match_ended 携带 winner=NONE, reason=""（比赛终止时逻辑不可能，防御编程兜底），WHEN UI 接收，THEN 显示 DRAW 画面。

**AC-UI-063 — 结果画面阻止穿透点击（Edge: 覆盖层）** [Integration]
GIVEN WIN/LOSE/DRAW 覆盖层显示中，WHEN 玩家在覆盖层背景上点击或按 Escape，THEN MOUSE_FILTER_STOP 阻止穿透——仅"再来一局"按钮响应。

### J. 结构/架构（2 条）

**AC-UI-064 — InputHandler 为 RefCounted，DI 注入** [Structural]
GIVEN 项目源码，WHEN 检查 InputHandler 类定义，THEN 继承 RefCounted（非 Node），所有依赖通过构造函数/属性注入，无 Autoload。

**AC-UI-065 — 三个 HighlightLayer 节点独立** [Structural]
GIVEN Board 场景树，WHEN 检查结构，THEN 存在三个独立 HighlightLayer 节点（move/path/attack），均为 Node2D，均覆写 _draw() 使用 draw_rect()，位于 TileMapLayer 之后、Units 之前。

### 汇总

| 分类 | 数量 | Logic | Integration | Visual | Structural |
|------|------|-------|-------------|--------|------------|
| A. 输入解析 | 16 | 1 | 15 | 0 | 0 |
| B. 交互流程 | 10 | 0 | 10 | 0 | 0 |
| C. 约束门禁 | 7 | 4 | 3 | 0 | 0 |
| D. 渲染组织 | 6 | 0 | 3 | 2 | 1 |
| E. HUD 元素 | 5 | 0 | 2 | 2 | 1 |
| F. 屏幕状态 | 5 | 0 | 5 | 0 | 0 |
| G. 公式 | 5 | 3 | 2 | 0 | 0 |
| H. 输入状态机 | 3 | 0 | 3 | 0 | 0 |
| I. 边界情况 | 6 | 1 | 3 | 1 | 1 |
| J. 结构/架构 | 2 | 0 | 0 | 0 | 2 |
| **合计** | **65** | **9** | **46** | **5** | **5** |

**门禁汇总**：
- **BLOCKING (Logic)**：9 条 —— 每条需在 `tests/unit/ui/` 中有自动化单元测试
- **BLOCKING (Integration)**：46 条 —— 每条需要集成测试或文档化 playtest
- **ADVISORY (Visual)**：5 条 —— 截图 + lead 签核
- **ADVISORY (Structural)**：5 条 —— 代码审查验证

## Open Questions

- **OQ1 — 艺术圣经颜色对齐**：颜色方案 C 已决——保留 GDD 阵营色、添加艺术圣经高亮色。艺术圣经本身是否需要更新以匹配 GDD 的 `#3B82F6`/`#EF4444` 阵营色？→ 建议在一致性检查后更新艺术圣经 §4.3。

- **OQ2 — 窗口尺寸与棋盘匹配**：MVP 无摄像机滚动。建议最小窗口 1024×768 以容纳 16×12 地图（1024×768px 恰好）。若窗口小于此尺寸，棋盘将被裁剪。是否需要运行时检测窗口尺寸并发出警告？→ 推迟到实现阶段。

- **OQ3 — 调试叠加层性能**：32×32 地图的调试坐标叠加层产生 1024 个 Label 节点。Godot 可处理，但若后续扩展到 64×64 地图（4096 个标签），是否应改为单个 `_draw()` Node2D？→ 推迟到性能分析阶段。MVP 规模下可接受。

- **OQ4 — 伤害预览停留时间可配置性**：600ms 停留时间由 Attack GDD 规定。是否应将该值放入数据文件（Pillar 1）而不是硬编码为常量？→ 倾向于在 MVP 阶段保持常量；若后续 UX 测试显示需要调整，再改为数据驱动。

- **OQ5 — 键盘快捷键（Escape、反引号）可重绑定**：当前 Escape=取消、反引号=切换调试叠加层。这些是否应通过 InputMap 可配置？→ MVP 固定键位可接受；若后续支持键位重绑定，通过 InputMap 迁移成本低。

- **OQ6 — 手机/触屏适配**：MVP 仅 PC 鼠标。触屏设备上"悬停预览"不可用。若未来支持触屏，需设计替代的预览机制（例如长按预览）。→ 不在 MVP 范围。

- **OQ7 — 多语言支持**：当前所有 UI 文字（"Turn X/Y"、"Player Turn"、"End Turn"、"VICTORY"、"再来一局"等）为硬编码英文字符串。是否需要 `tr()` 包裹以支持未来本地化？→ 建议 MVP 阶段硬编码英文；Tier 3 本地化时统一提取到字符串表。与 Godot 4.5+ 的 `tr()` 方案兼容。
