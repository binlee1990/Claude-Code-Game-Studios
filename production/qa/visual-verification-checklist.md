# MVP 视觉验证清单

> **用途**: 在 Godot 编辑器中逐项验证 MVP 的渲染/UI 层。
> **前提**: `src/Game.tscn` 已设为主场景，按 F5 运行。
> **棋盘布局**: 16×12 网格。2 个 Player (蓝) 在 (5,2)(5,4)，2 个 Enemy (红) 在 (5,10)(5,12)。

---

## 2026-05-02 Automated QA Status

当前 Sprint 1-3 自动化 QA 已签核，且 Tier 2 BasicAI 计划生成器测试已纳入默认 runner：`tests/test_runner.gd` 报告 `Total Passed: 262`，且 `SCRIPT ERROR` / `Assertion failed` / `ERROR:` / `WARNING:` 均为 0。`src/Game.tscn` headless scene boot 也为 clean。

本清单保留为 Godot 编辑器中的人工观感/产品 polish 检查。2026-05-02 已完成 CP1-CP10 及综合检查人工复测，全部通过；自动化工程风险由 `production/qa/qa-execution-audit-2026-05-02.md`、`production/qa/evidence/story-8-7/playtest-notes.md`、UI 结构测试和 E2E 测试覆盖。

---

## CP1 — 启动：棋盘 / 单位 / HUD / Debug

> **人工最终验收（2026-05-02）**: CP1-CP10 及综合检查均已人工复测通过。所有检查项标为 `[x]`。

### 1.1 棋盘渲染
- [x] 看到 TileMapLayer 渲染的完整网格（16×12）
- [x] DebugOverlay 绘制的细网格线使瓦片边界清晰，无黑屏区域
- **异常**: 黑屏 → 检查 `assets/data/maps/test_map.csv` 是否存在
- **异常**: 瓦片错位 → 检查 TileSet `assets/data/tileset.tres`

### 1.2 Player 单位
- [x] 2 个蓝色方块 (#3B82F6)，坐标 (5,2) 和 (5,4)
- [x] 方块尺寸 48×48 像素
- [x] 方块与细网格线之间有可见边距，不再看起来占满整个瓦片
- **异常**: 单位不可见 → 检查 `src/unit/Unit.tscn` 是否存在
- **异常**: 坐标错误 → 检查 `game.gd:131-134`

### 1.3 Enemy 单位
- [x] 2 个红色方块 (#EF4444)，坐标 (5,10) 和 (5,12)
- **异常**: 颜色不对 → 检查 `unit.gd:3-4` 常量

### 1.4 HP 标签
- [x] Player 单位上方显示 "HP: 10/10"
- [x] Enemy 单位上方显示 "HP: 8/8"
- [x] 标签白色文字，位于 ColorRect 中心上方约 40px
- **异常**: 无标签 → 检查 `unit.gd:89-90` Label 节点

### 1.5 HUD — 回合指示器
- [x] 显示 "Turn 1/30"
- [x] HUD 位于棋盘右侧深色面板，不遮挡瓦片

### 1.6 HUD — 阵营指示器
- [x] 显示 "Player Turn"，蓝色文字 (#3B82F6)
- [x] 阵营指示器位于棋盘右侧深色面板，不遮挡瓦片
- **异常**: 不显示 → 检查 `hud.gd:41-48`

### 1.7 HUD — End Turn 按钮
- [x] 可见可点击
- [x] 点击后阵营指示器切换为 "Enemy Turn"（红色 #EF4444）
- **异常**: 按钮灰色 → 检查 `hud.gd:31` `_end_turn_button.visible`

### 1.8 Debug Overlay
- [x] 每个瓦片中心显示白色 "(row,col)" 坐标文字，包括 (5,12)
- [x] 字体大小约 10px
- [x] 按反引号键 (`` ` ``) 可切换坐标文字显示/隐藏；细网格线保持显示
- **异常**: 无坐标 → 上次修复了 `ThemeDB.fallback_font`，确认生效

---

## CP2 — 选中单位 → 蓝色移动范围高亮

### 操作
1. 点击 (5,2) 位置的蓝色 Player 单位

### 验证
- [x] 单位有选中反馈（当前 MVP 无视觉选中效果，可通过后续高亮确认）
- [x] 以该单位为中心，mov=4 格范围内的 walkable 瓦片显示**蓝色半透明矩形** (#0891B2)
- [x] 高亮范围不超出棋盘边界
- [x] 高亮不覆盖 blocked 瓦片（test_map 中如有）
- **异常**: 无高亮 → 检查 `Unit.tscn` 的 ColorRect/Label `mouse_filter = Ignore`、`highlight_layer.gd:_draw()` 及 `queue_redraw()`
- **异常**: 范围不对 → 检查 `movement_resolver.gd:compute_reachable()` 的 BFS 逻辑

---

## CP3 — 悬停可达瓦片 → 青色路径预览

### 操作
1. 在 CP2 基础上（单位已选中，蓝色高亮可见）
2. 鼠标悬停在蓝色高亮范围内的某个瓦片上

### 验证
- [x] 从起点到悬停瓦片显示**青色矩形路径** (#06B6D4)
- [x] 路径包含起点和终点
- [x] 鼠标移到另一个瓦片 → 路径更新
- [x] 鼠标移出棋盘 → 路径高亮消失
- **异常**: 路径不连续 → 检查 `movement_result.gd:get_path_to()` 的父链重建
- **异常**: 路径穿越 blocked → 检查 BFS 是否正确排除了阻塞瓦片

---

## CP4 — 点击移动 → 橙色攻击高亮

### 操作
1. 在 CP2 基础上，点击一个可达瓦片（蓝色高亮范围内）

### 验证
- [x] 单位**瞬移**到目标位置（无动画）
- [x] 蓝色移动高亮**全部清除**
- [x] 单位射程内（rng=1）的敌方瓦片显示**橙色矩形** (#EA580C)
- [x] 如果射程内无敌方单位 → 不显示橙色高亮，单位自动结束行动
- **异常**: 单位未移动 → 检查 `input_handler.gd:_execute_move()` 中的 `map.move_unit()`
- **异常**: 蓝色高亮未清除 → 检查 `input_handler.gd:162-163`

---

## CP5 — 悬停敌人 → 伤害预览

### 操作
1. 在 CP4 基础上（橙色攻击高亮可见）
2. 鼠标悬停在橙色高亮范围内的敌方单位上

### 验证
- [x] 敌方单位头顶显示 **"-N"** 数字标签
- [x] 颜色规则：
  - [x] 伤害 < 目标 HP → **琥珀色** (#F59E0B)
  - [x] 伤害 ≥ 目标 HP → **红色** (#EF4444)，带黑色描边以避免和 Enemy 红色方块混淆
- [x] 鼠标移开后数字**立即消失**
- [x] 伤害计算正确：预览显示 "-4" 与 "ATK 5 - DEF 1"，用于现场校验公式
- **异常**: 数字不显示 → 检查 `_on_damage_preview` 信号连接 (`game.gd:73`)
- **异常**: 数字一直显示 → 检查 `_hide_preview` 是否被调用

---

## CP6 — 点击攻击 → HP 更新 / 单位消失

### 操作
1. 在 CP5 基础上，点击橙色高亮内的敌方单位

### 验证
- [x] 敌方 HP 标签**立即更新**：从 "HP: 8/8" 变为 "HP: 4/8"
- [x] "-4" 伤害数字停留约 **0.6 秒**后消失
- [x] 攻击者单位变为已行动状态（半透明灰色）
- [x] Player 单位 HP **不变**（无反击）

### CP6b — 击杀
1. End Turn → End Turn（回到 Player Turn）
2. 再次选中 Player 单位 → 移动 → 攻击同一敌人（HP 4/8）

### 验证
- [x] 敌方 HP 从 4/8 降至 0（标签显示 "HP: 0/8"）
- [x] 敌方单位**从棋盘完全消失**（queue_free）
- [x] 死亡位置变为空瓦片（可被其他单位移动至此）
- **异常**: HP=0 但单位仍可见 → 检查 `game.gd:158-160` 的 `_on_unit_died`
- **异常**: HP 变负数 → 检查 `unit.gd:18` 的 `clampi`

---

## CP7 — End Turn / 阵营切换（热座）

### 操作
1. Player 单位行动完毕后，点击 **End Turn** 按钮

### 验证
- [x] HUD 阵营指示器从 "Player Turn"（蓝色）切换为 **"Enemy Turn"**（红色）
- [x] Turn 数字不变（Player→Enemy 不递增回合）
- [x] 敌方单位 `has_acted_this_turn` 重置为 false（可被选中）

### CP7b — 热座操作敌方
1. 点击红色 Enemy 单位

### 验证
- [x] Enemy 单位正常选中
- [x] 蓝色移动范围出现
- [x] 可以移动/攻击 Player 单位
- [x] 再次点击 End Turn → 切换回 Player
- [x] Turn 从 1 变为 2（Enemy→Player 时递增）
- **异常**: 阵营切换后仍显示旧阵营 → 检查 `turn_manager.gd:79-103` 的 `_transition_to_ending`

---

## CP8a — VICTORY 画面

### 操作
1. 持续操作直到击杀**所有** Enemy 单位（2 个）

### 验证
- [x] 最后一个 Enemy 死亡的同一帧，**全屏半透明深色背景**出现
- [x] 标题：绿色大字 **"VICTORY"** (#10B981)
- [x] 原因文字：显示 "elimination"
- [x] **"Play Again"** 按钮可见可点击
- [x] 所有输入被屏蔽（MOUSE_FILTER_STOP）
- **异常**: 全灭后无反应 → 检查 `turn_manager.gd:94-96` match_ended 信号
- **异常**: 标题颜色/文字不对 → 检查 `result_overlay.gd:25-34`

---

## CP8b — DEFEAT 画面

### 操作
1. F5 重新运行游戏
2. 故意让所有 Player 单位被 Enemy 击杀

### 验证
- [x] 最后一个 Player 死亡瞬间，全屏覆盖层出现
- [x] 标题：红色大字 **"DEFEAT"** (#EF4444)
- [x] 原因文字：显示 "elimination"
- [x] "Play Again" 按钮可见

---

## CP10 — DRAW 画面（回合上限）

### 操作
1. 打开 `src/game.gd`，找到第 29 行 `TurnConfig.new()`
2. 临时替换为：
   ```gdscript
   var tc = TurnConfig.new()
   tc.turn_cap = 2
   # 然后在 turn_manager.initialize(units, tc, ...) 中使用 tc
   ```
3. F5 运行，在 2 个完整回合内避免任何单位死亡
4. 第 2 回合 Enemy phase 结束后

### 验证
- [x] 全屏覆盖层出现
- [x] 标题：灰色大字 **"DRAW"** (#9CA3AF)
- [x] 原因文字：显示 "turn_cap"
- [x] "Play Again" 按钮可见
- **异常**: 回合上限不触发 → 检查 `victory_checker.gd:17-23` turn_cap 分支
- **重要**: 测试完成后**还原** `game.gd` 的修改

---

## CP9 — Play Again

### 操作
1. 在任意结束画面（WIN/DEFEAT/DRAW）点击 **Play Again** 按钮

### 验证
- [x] 场景**完全重新加载**
- [x] 棋盘回到初始状态：4 单位在原始位置
- [x] Turn 显示 "1/30"，阵营显示 "Player Turn"
- [x] 无残留单位/高亮/HUD 状态
- **异常**: 点击无反应 → 检查 `result_overlay.gd:38-39` 的 `reload_current_scene()`
- **异常**: 重载后状态残留 → 检查 singleton/Autoload 是否有未重置的状态

---

## 综合检查

- [x] 运行全过程无控制台报错（红色 SCRIPT ERROR）
- [x] 帧率保持流畅（无卡顿）
- [x] 内存无明显泄漏（任务管理器观察，5 分钟内增长不超过 50MB）
- [x] 窗口缩放/最小化后恢复正常渲染

---

## 验证结果

| CP | 状态 | 备注 |
|----|------|------|
| CP1 启动 | ✅ | 人工反馈确认 1.1、1.2、1.5、1.6、1.8 均没问题；此前已确认 1.3、1.4、1.7。 |
| CP2 选中+蓝高亮 | ✅ | 人工反馈确认点击 (5,2) 后蓝色半透明移动范围正常，边界和 blocked 排除正常。 |
| CP3 悬停+路径 | ✅ | 人工反馈确认青色路径、起终点、悬停更新、移出棋盘清除均正常。 |
| CP4 移动+橙高亮 | ✅ | 人工反馈确认瞬移、清除蓝色高亮、橙色攻击高亮、无目标自动结束均正常。 |
| CP5 伤害预览 | ✅ | 人工反馈确认全部没问题，包括伤害数字、颜色、移出清除和公式可读性。 |
| CP6 攻击+击杀 | ✅ | 人工反馈确认 CP6 与 CP6b 全部没问题。 |
| CP7 End Turn | ✅ | 人工反馈确认 CP7 与 CP7b 全部没问题。 |
| CP8a WIN | ✅ | 人工反馈确认 CP8a 全部没问题。 |
| CP8b DEFEAT | ✅ | 人工反馈确认 CP8b 全部没问题。 |
| CP10 DRAW | ✅ | 人工反馈确认 CP10 全部没问题。 |
| CP9 Play Again | ✅ | 人工反馈确认 CP9 全部没问题。 |

**检查人**: User manual QA
**日期**: 2026-05-02
**总评**: CP1-CP10 与综合检查全部通过。
