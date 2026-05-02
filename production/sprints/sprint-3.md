# Sprint 3 — Presentation Layer + MVP Complete

**Start**: 2026-05-02
**End**: 2026-05-03

## Sprint Goal

实现 Presentation Layer — 将全部 7 个上游系统 (Map/Unit/Turn/Movement/Attack/Victory/AI) 编织为可玩的端到端体验。这是 MVP 的最后一块拼图。交付后 SRPG 骨架将**完整可玩**：启动 → 棋盘 → 选中单位 → 蓝色移动范围 → 移动 → 橙色攻击范围 → 攻击 → 敌人消失 → End Turn → 热座对手操作 → 全灭/回合上限 → 胜负画面。

## Capacity

- 单人 (solo developer)
- 估计 ~5 工作会话
- 缓冲 20%

## Tasks

### Must Have (依赖顺序)

| ID | Story | Epic | Type | Depends On |
|----|-------|------|------|------------|
| 8-1 | HighlightLayer — 3层代码绘制高亮系统 | ui | UI | — |
| 8-2 | InputHandler — 输入上下文状态机 | ui | Logic | 8-1 |
| 8-3 | HUD CanvasLayer — 回合指示器 + 阵营 + End Turn 按钮 | ui | UI | TurnManager |
| 8-4 | ResultOverlay — WIN/LOSE/DRAW 全屏覆盖层 | ui | UI | TurnManager.match_ended |
| 8-5 | Debug Overlay — 坐标叠加层 + 伤害预览浮字 | ui | UI | 8-1, 8-2 |
| 8-6 | Game Scene Wiring — 完整组合根集成 | ui | Integration | 8-1, 8-2, 8-3, 8-4, 8-5 |
| 8-7 | E2E Playtest — 全流程冒烟 + Victory/Loss 验证 | ui | Integration | 8-6 |

### Should Have

| ID | Story | Epic | Type |
|----|-------|------|------|
| 8-8 | Unit 已行动灰色 modulate (Color.GRAY × 0.5) | unit | Visual/Feel |

### Nice to Have

- UX 文档 (`design/ux/`) — 当 MVP 运行时作为参考写入
- BasicAI `take_turn()` scaffold — 已在 Sprint 4 完成，为 Tier 2 AI 预热接口
- `_draw_multirect()` batch 优化 — 仅在 perf profiling 显示 `_draw()` 超过 1ms 时执行

## Story Details

### 8-1: HighlightLayer — 3 层代码绘制高亮

创建 `src/ui/highlight_layer.gd` — Node2D 子类，覆写 `_draw()` 使用 `draw_rect()` 绘制纯色矩形高亮。
- 3 个实例：MoveHighlight (z=1, #0891B2), PathHighlight (z=2, #06B6D4), AttackHighlight (z=3, #EA580C)
- `set_highlight(tiles: Array[Vector2i])` → `queue_redraw()`
- 测试: 5 AC — 渲染正确颜色、清除高亮、独立 queue_redraw、z_order 正确、TileSize 矩形尺寸

### 8-2: InputHandler — 输入上下文状态机

创建 `src/ui/input_handler.gd` — RefCounted，实现 ADR-0010 的 InputContext 状态机。
- `BOARD_IDLE → UNIT_SELECTED → ATTACK_TARGETING → BOARD_IDLE`
- `handle_event(event)` 通过 `GridSpace.world_to_grid()` 解析点击
- 选择/移动/攻击/取消/直接攻击 全部流程
- End Turn 输入门禁 (InputMap action)
- 测试: 10 AC — 需要 ≥5 个自动化单元测试 (synthetic InputEvent → handle_event → 断言 state)

### 8-3: HUD CanvasLayer

创建 `src/ui/hud.gd` — CanvasLayer (layer 0)，屏幕空间。
- TurnIndicator: `"Turn X/Y"` 标签，轮询 TurnManager
- FactionIndicator: `"Player Turn"` / `"Enemy Turn"`，颜色编码
- EndTurnButton: 触发 `end_current_faction_turn()`，仅 FACTION_PHASE_ACTIVE 时可见
- 所有元素通过信号刷新 (notification, not polling per frame)

### 8-4: ResultOverlay

创建 `src/ui/result_overlay.gd` — CanvasLayer (layer 10)，全屏覆盖。
- 半透明深色背景 ColorRect (MOUSE_FILTER_STOP)
- TitleLabel: "VICTORY" (#10B981) / "DEFEAT" (#EF4444) / "DRAW" (#9CA3AF)
- ReasonLabel: "elimination" / "turn_cap reached"
- PlayAgainButton: 重新加载场景
- 监听 `match_ended` 信号

### 8-5: Debug Overlay + 伤害预览

- Debug Overlay: `_draw()` 在每个瓦片中心渲染 `(row, col)` 文字 (12px, 白色)，默认开启，反引号切换
- 伤害预览浮字: Label 节点，`−N` 文字显示于目标单位头顶 600ms (琥珀=非致命 / 红=击杀)
- 属于 InputHandler 视觉输出 — 非独立系统

### 8-6: Game Scene Wiring

重写 `src/game.gd` `_ready()` 实现 ADR-0010 完整初始化顺序:
1. GridSpace → 2. Map → 3. Units → 4. TurnManager → 5. Resolvers → 6. InputHandler → 7. HighlightLayers → 8. HUD → 9. ResultOverlay → 10. Signal wiring → 11. start_match()
- `_unhandled_input(event)` bridge → InputHandler
- 所有 TurnManager 信号连接
- unit_died → map.remove_unit + queue_free (已有)

### 8-7: E2E Playtest

手动 playtest 检查清单 — 完整 MVP 游戏循环:
- 启动 → 棋盘可见，单位在位置，蓝色 Player 单位，红色 Enemy 单位
- 选中己方单位 → 蓝色移动范围高亮
- 悬停可达瓦片 → 青色路径预览
- 点击移动 → 单位瞬移，橙色攻击高亮出现
- 悬停敌人 → 伤害预览数字
- 点击攻击 → 伤害结算，HP 更新，杀死时单位消失
- End Turn → 敌方阶段（热座，玩家操作敌方）
- 全灭敌方 → WIN 画面
- Play Again → 重新开始
- 回合上限到达 → DRAW 画面

## Risks

| Risk | Probability | Impact | Mitigation |
|------|------------|--------|------------|
| InputHandler 逻辑复杂 (150行, 6 依赖) 导致测试覆盖不足 | 中 | 中 | 8-2 是 Logic Story → ≥5 自动化测试，mock 所有依赖 |
| Game Scene 初始化顺序错误导致启动崩溃 | 中 | 高 | 严格按 ADR-0010 初始化顺序 (9 steps)；每步后验证 |
| HighlightLayer `_draw()` 在 unit 之上渲染导致视觉遮蔽 | 低 | 低 | z_index 已在 ADR-0010 指定 (move=1, path=2, attack=3)，units 高于此 |
| End Turn 按钮 gate 条件错误导致可多次点击 | 低 | 低 | TurnManager 已有重入保护；UI 额外加 visible gate |
| 热座模式体验混淆 (玩家需操作双方) | 中 | 低 | HUD 阵营指示器明确显示当前操作方；这是 MVP 已知限制 |

## Dependencies on External Factors

- 无外部依赖 (单人项目，Godot 4.6.2 本地已安装)

## Definition of Done

- [x] 所有 7 个 Must Have Story 完成（implementation status: `production/sprint-status.yaml` 中 8-1 至 8-7 为 `done`）
- [x] 8-2 (InputHandler Logic Story) 有 ≥5 通过测试 (`tests/unit/ui/`) — `input_handler_test.gd` 7 个测试已进入 default runner
- [x] 8-6 集成有 E2E 冒烟检查清单完成 — E2E 自动化 + `src/Game.tscn` headless scene boot clean
- [x] 8-7 全流程 playtest 通过 (所有 10 个检查点) — 见 `production/qa/evidence/story-8-7/playtest-notes.md`
- [x] 8-8 Should Have 已行动灰色 modulate 完成 — `tests/unit/unit/unit_scene_visual_test.gd` 覆盖
- [x] 代码审查通过 (current QA risk-resolution diff reviewed against sprint scope)
- [x] MVP 完整可玩: 启动 → 移动 → 攻击 → End Turn → Victory/Loss
- [x] `game-concept.md` MVP 定义全部 8 项满足

> ✅ **QA Plan Execution (refreshed 2026-05-02)**: `production/qa/qa-plan-sprint-3-2026-05-02.md` 已执行，Sprint 3 QA sign-off 已生成：`production/qa/qa-signoff-sprint-3-2026-05-02.md`。当前 headless runner 复核为 clean：`Total Passed: 262`，`SCRIPT ERROR` / `Assertion failed` / `ERROR:` / `WARNING:` 均为 0。Sprint 3 当前状态为 **MVP automated QA signed off**。详情见 `production/qa/qa-execution-audit-2026-05-02.md`。

## Sprint Completion Gate = MVP Complete

实现层已覆盖 8 个 MVP 原语模块 (Map/Unit/Turn/Movement/Attack/Victory/AI/UI)，Sprint Completion Gate 已通过当前 automated QA。人工编辑器验证也已完成：CP1-CP10 与综合检查全部通过。
