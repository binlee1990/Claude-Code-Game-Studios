# UX Spec: 存档屏 (Save Screen)

> **Status**: In Design
> **Author**: binlee1990 + ux-designer
> **Last Updated**: 2026-05-05
> **Journey Phase(s)**: 全阶段 — 玩家任何时间均可通过 LEFT NAV 或快捷键 `4` 进入
> **Platform Target**: PC (Steam/Epic) — Keyboard/Mouse Primary + Gamepad Partial
> **Template**: UX Spec
> **Sprint**: Sprint 11 / mvp-screens / S11-012
> **Asset Manifest 引用**: §10 portrait（每槽头像缩略）· §3 realm icons（当前存档境界图标）

---

## Purpose & Player Need

存档屏是玩家的"玉简管理台"——在这里玩家查看、创建、恢复和删除修仙世界的存档。GDD save-system 定义存档为"天地玉简"，本屏是将这一隐喻可视化的唯一触点。

### 核心玩家目标

1. **安心感** — 看到"上次自动保存: 30 秒前"，确认进度已被保护
2. **手动控制** — 主动保存（大决策前）或读取（回退到更早时点）
3. **槽位管理** — 3 个存档槽让玩家可尝试不同策略分支
4. **版本感知** — 看到存档版本号与迁移状态，了解存档健康状况
5. **存档健康** — 损坏存档被明确标记，不静默丢失数据；备份恢复路径可见

### Sentence form

> "The player arrives at this screen to **verify** their progress is safe, **manage** save slots for strategic branching, and **trust** that corrupted or outdated saves are clearly surfaced rather than silently broken."

### 反向定义（这里不做什么）

- 不自动弹出保存确认（打断感强，违反放置精神）
- 不做存档截图缩略图（MVP 用 portrait + metadata 文字代替）
- 不做云存档同步（MVP scope 外，save-system GDD 已明确）
- 不做存档文件导入/导出 UI（调试控制台可做，本屏不暴露给玩家）
- 不做存档比较 diff（post-MVP 功能）

### 与 save-system GDD 的关系

save-system GDD 原设计为 MVP 单存档位（`user://save/save.json`），Sprint 11 演进为 3 存档槽（S11-012 "多存档槽"）。本屏是这一演进在 UI 层的落地；目录结构由 ADR-0018 决议。

### Pillar 锚定

- **4.1 数字增长就是快乐** — 存档确保每一份进度被持久化，玩家明确知道自己的积累是安全的
- **4.2 放置 = 低频高价值决策** — 手动保存是 5 分钟/30 分钟尺度的决策，存档屏访问频率低但每次意义重大

---

## Player Context on Arrival

| 维度 | 答案 |
|------|------|
| **何时首次遇到** | 新存档冷启动后玩家首次点 LEFT NAV "存档" tab 或按 `4`；通常在修炼 5-10 分钟后首次进入 |
| **之前在做什么** | 刚在修炼/战斗/资源屏积累了进度，想做一次手动保存确保安全，或想切换到另一个存档槽尝试不同策略 |
| **情绪状态（设计假设）** | **calm + deliberate + 轻度审慎** — 玩家带着"保护进度"的明确意图而来。不是紧急的"游戏崩溃了我要看看存档还在不在"（那个走自动恢复流程，见 §States.corrupted） |
| **主动 vs 被动** | **主动** — 玩家从 LEFT NAV 选 "存档" tab 或按 `4` 进入 |

### 派生设计含义

- **第一眼焦点**: 自动保存指示器 + 当前槽位高亮 — 玩家先确认"进度已被保护"，再决定是否手动操作
- **离开时无确认**: 本屏没有中途状态（选择槽位不触发任何操作），切到其他屏不需要确认
- **操作才弹确认**: 只有"手动保存（覆盖）""读取（覆盖当前进度）""删除"三个不可逆操作走 P-NAV-03 或 P-INP-02 Modal 确认

---

## Navigation Position

存档屏位于 **Root → ScreenStack → Save Screen**（LEFT NAV "存档" tab，第 4 位）。所有其他主区域（修炼/战斗/资源/离线结算）通过 LEFT NAV 平级切换。

### 替代入口

| 入口源 | 触发方式 |
|--------|---------|
| LEFT NAV "存档" tab | 鼠标点击 / 键盘 ↑↓ + Enter / 手柄 D-Pad ↑↓ + A |
| 全局快捷键 `4` | 数字键 1-5 直达 5 主区域，存档 = `4` |
| 调试控制台 `goto save` | dev only；release 构建排除（ADR-0012） |

### 不能从这里到达的地方

存档屏**不通向**任何子屏。所有 modal（确认覆盖/确认删除/确认读取）通过 P-NAV-03 Modal Stack 浮层叠加；玩家关闭 modal 后仍在存档屏。

---

## Entry & Exit Points

### Entry

| Entry Source | Trigger | Player carries this context |
|---|---|---|
| LEFT NAV tap | Click "存档" / Press `4` / D-Pad 选第 4 项 + A | 当前游戏状态完整 |
| Modal closed | 任何 modal 关闭后回到本屏 | modal 内决策已落地（保存完成/读取完成/删除已取消） |
| Debug `goto save` | dev only | — |

### Exit

| Exit Destination | Trigger | Notes |
|---|---|---|
| 修炼/战斗/资源/离线结算屏 | LEFT NAV / 数字键 1-5 | 无状态丢失 |
| App quit | 系统关闭 | 触发 SaveManager auto-save |

无一次性出口；所有 exit 可通过 LEFT NAV 返回，无不可逆状态。

---

## Layout Specification

### Information Hierarchy

按玩家决策优先级，从最高到最低：

1. **Confirmation Tier**（顶部，一眼确认）— 自动保存指示器: "上次自动保存: 30 秒前" + 状态 icon
2. **Slot Tier**（中央主体，玩家做决策时聚焦）— 3 个存档槽卡片，竖排列表
3. **Action Tier**（底部，玩家操作入口）— 手动保存 / 读取存档 / 删除存档 / 返回 四个按钮
4. **Ambient Tier**（背景，不参与交互）— 当前屏无专属背景（复用 HUD 的 CENTER CONTENT 默认底）

### Layout Zones

存档屏占 **HUD 的 CENTER CONTENT 区**（去除 TOP STRIP 64px / LEFT NAV 192px / RIGHT PANEL 320px / BOTTOM ACTION BAR 之后）。

@ 1080p 基线：CENTER CONTENT 可用区域 ≈ **1408 × 1016 px**。

| Zone | 位置 | 尺寸 @ 1080p | 内容 |
|---|---|---|---|
| **AUTO-SAVE INDICATOR** | 顶部居中 | 1408 × 40 px | "上次自动保存: N 秒前" + 状态 icon（绿点=正常 / 红点=距上次 > 5 分钟 / 黄点=保存中） |
| **SLOTS AREA** | 中央 | 1408 × 840 px | 3 个存档槽卡片，竖排，每卡约 1408 × 260 px，间距 24px |
| **ACTION BAR** | 底部固定 | 1408 × 48 px | 4 按钮：手动保存 / 读取存档 / 删除存档 / 返回 |

### 屏幕安全区

- 1280×720 最小窗口：槽卡片高度缩至 200px；ACTION BAR 保持 48px
- 4K（3840×2160）：等比缩放 + 字号 +1 档（24px → 28px）
- Steam Deck 1280×800：LEFT NAV 折叠 48px；SLOTS AREA 宽度自适应

### Component Inventory

按 zone 分组；每行标注：组件类型 / 内容 / 是否交互 / 引用 pattern 或新组件。

#### AUTO-SAVE INDICATOR

| Component | Type | Content | Interactive | Pattern |
|---|---|---|---|---|
| 状态 icon | TextureRect | 绿点 (正常) / 黄点 (保存中) / 红点 (距上次 >5min) | No | — |
| 上次保存时间文本 | Label | "上次自动保存: N 秒前" / "N 分钟前"（每秒刷新） | No | — |
| 保存逾期警告 | Label | "⚠ 距上次保存超过 5 分钟"（仅 > 5min 时显示） | No | — |

#### SLOTS AREA — 每个存档槽卡片（×3）

| Component | Type | Content | Interactive | Pattern |
|---|---|---|---|---|
| 槽位编号标签 | Label | "存档 1" / "存档 2" / "存档 3" | No | — |
| 当前槽标记 | Panel 四边 border | `burst_gold` 2px 四边边框（仅当前活跃槽） | No | — |
| 选中高亮 | Panel 左侧竖条 + 底 | 左侧 4px `burst_gold` 竖条 + `panel_bg_elevated` 底（仅选中槽） | No（随点击触发） | — |
| Portrait 缩略图 | TextureRect | portrait.png 缩至 96×96 | No | — |
| 等级 + 境界标签 | Label + TextureRect | "Lv.32 筑基" + 当前境界 icon | No | 复用 HUD 等级徽章风格 |
| 游玩时长 | Label | "游玩时长: 12 小时 34 分" | No（hover tooltip 精确到秒） | P-INP-01 Tooltip |
| 保存时间戳 | Label | "保存于: 2026-05-05 14:32:15" | No | — |
| 数据版本 | Label | "数据版本: 0.0.3" | No | — |
| 存档格式版本 | Label | "存档格式 v1"（仅与当前版本不一致时显示） | No（hover tooltip 显示迁移链说明） | P-INP-01 Tooltip |
| 迁移需求 chip | StatusChip | "需要迁移 v1→v2"（仅 migration_needed = true 时） | No | P-FBK-02 Inline Status Chip |
| 损坏标记 chip | StatusChip | "⚠ 存档损坏"（仅 corrupted = true 时） | No | P-FBK-02 |
| 备份恢复标记 chip | StatusChip | "已从备份恢复"（仅 recovered_from_backup = true 时） | No | P-FBK-02 |
| 空槽占位 icon | TextureRect | ∅ placeholder（仅空槽时替换 portrait 区） | No | — |
| 空槽占位文本 | Label | "尚未创建存档"（仅空槽时显示） | No | — |
| 卡本体点击 | PanelContainer | 点击整个卡片选中槽位 | Yes（Click / Enter / A） | — |

#### ACTION BAR

| Component | Type | Content | Interactive | Pattern |
|---|---|---|---|---|
| 手动保存 Button | Button | "手动保存到槽位 N" | Yes — 触发 P-NAV-03 Confirm Overwrite modal（如目标槽有数据）或直接保存（如空槽） | — |
| 读取存档 Button | Button | "读取存档" | Yes — 触发 P-NAV-03 Confirm Load modal（显示进度对比） | — |
| 删除存档 Button | Button | "删除存档" | Yes — 触发 P-INP-02 Confirm-Critical modal | P-INP-02 |
| 返回 Button | Button | "返回修炼" | Yes — `open_screen("cultivation")` | — |

#### 保存中/加载中 Overlay（浮层）

| Component | Type | Content | Interactive |
|---|---|---|---|
| 半透明遮罩 | ColorRect | `#000000` opacity 30% | No（阻止操作穿透） |
| Spinner | AnimatedSprite2D | 旋转加载动画 | No |
| 状态文本 | Label | "保存中..." / "读取中..." / "正在迁移存档..." | No |

#### Confirm Modals（P-NAV-03 及其特化变体 P-INP-02）

| Modal | 触发条件 | Pattern | 确认后果描述 | 主按钮文本 |
|---|---|---|---|---|
| 确认覆盖 | 点击"手动保存" + 目标槽已有数据 | P-NAV-03 | "将覆盖存档 N 的现有数据（Lv.X·境界·游玩时长），此操作不可撤销" | "确认覆盖" |
| 确认读取 | 点击"读取存档" | P-NAV-03 | "读取后将丢失当前未保存进度（上次保存后约 N 分钟），是否继续？" + 当前进度 vs 存档进度对比（等级/境界/游玩时长） | "确认读取" |
| 确认删除 | 点击"删除存档" | **P-INP-02** Confirm-Critical | 列出将被删除的存档摘要（等级/境界/游玩时长/保存时间）；强制 2s 倒计时 + "我了解此操作不可逆"勾选框 | "删除此存档" |

#### 空槽时 ACTION BAR 按钮状态

| 按钮 | 空槽时的行为 |
|---|---|
| 手动保存 | **可用** — 直接保存到空槽，不弹 confirm modal |
| 读取存档 | **disabled** — 空槽无数据可读 |
| 删除存档 | **disabled** — 空槽无数据可删 |
| 返回 | 始终可用 |

#### 组件总数

9 个交互元素（3 槽位卡片 + 4 action 按钮）+ 最多 19 个静态显示元素（每槽最多 7 个 metadata 字段）+ 3 个 modal = 共约 31 个 UI components（含条件显示元素）。

### ASCII Wireframe

```
┌── HUD TOP STRIP (64px, 固定) ───────────────────────────────────────────┐
│ 灵气 ⛬ 1.2K │ 修为 ◯ 850K │ 灵石 ◇ 12.5M │ 药材 ❀ 234K │ Lv32 筑基  │ ⚙ │
├──────┬───────────────────────────────────────────────────┬─────────────┤
│LEFT  │                                                   │ RIGHT PANEL │
│NAV   │  ┌── AUTO-SAVE INDICATOR ────────────────────┐   │             │
│192px │  │ 🟢 上次自动保存: 30 秒前                    │   │ 战斗日志    │
│      │  └────────────────────────────────────────────┘   │             │
│📊修炼│                                                   │             │
│⚔战斗│  ┌── SLOT 1 (当前·选中) ═══════════ burst ──────┐│             │
│📦资源│  │ ┌──────┐  存档 1                    (当前)    ││             │
│💾存档│  │ │      │  Lv.32 筑基  ⛰                      ││             │
│📅离线│  │ │ 立绘 │  游玩时长: 12h 34m                   ││             │
│      │  │ │ 缩略 │  保存于: 2026-05-05 14:32            ││             │
│      │  │ │      │  数据版本: 0.0.3 · 格式 v1           ││             │
│      │  │ └──────┘                                     ││             │
│      │  └═══════════════════════════════════════════════┘│             │
│      │                                                   │             │
│      │  ┌── SLOT 2 ──────────────────────────────────┐  │             │
│      │  │ ┌──────┐  存档 2                            │  │             │
│      │  │ │      │  Lv.8 炼气  ⛰                      │  │             │
│      │  │ │ 立绘 │  游玩时长: 45m                       │  │             │
│      │  │ │      │  保存于: 2026-05-04 22:15            │  │             │
│      │  │ └──────┘                                     │  │             │
│      │  └──────────────────────────────────────────────┘  │             │
│      │                                                   │             │
│      │  ┌── SLOT 3 (空) ──────────────────────────────┐  │             │
│      │  │ ┌──────┐  存档 3                             │  │             │
│      │  │ │  ∅   │  尚未创建存档                        │  │             │
│      │  │ │      │                                     │  │             │
│      │  │ └──────┘                                     │  │             │
│      │  └──────────────────────────────────────────────┘  │             │
│      │                                                   │             │
│      │  ┌── ACTION BAR (48px) ────────────────────────┐  │             │
│      │  │  [手动保存到槽位 1]  [读取存档]  [🗑删除] [↩返回] │  │             │
│      │  └──────────────────────────────────────────────┘  │             │
└──────┴───────────────────────────────────────────────────┴─────────────┘
```

> **Wireframe 注**：本 wireframe 仅展示 1080p 默认布局。Slot 1 展示"当前槽 + 选中态"双重视觉编码（四边 burst_gold border = 当前；左侧竖条 + elevate 底 = 选中。两者可同时存在不冲突）。Slot 3 展示空槽状态（∅ placeholder icon + "尚未创建存档"文本）。ACTION BAR "手动保存"按钮动态显示目标槽编号。实际像素位由 art-director 在 Sprint 11 hud-real-layout S11-004 期间结合 theme.tres 9-slice 微调。

---

## States & Variants

| State / Variant | Trigger | What Changes |
|---|---|---|
| **Default (idle)** | 进入存档屏 | 3 槽卡片显示对应数据；当前槽 burst_gold 四边 border；自动保存指示器显示距上次保存时间 |
| **Empty Slot** | 某槽位无存档文件 | portrait 区显示 ∅ placeholder icon；metadata 全部显示 "——" 占位；"读取""删除"按钮对该槽 disabled；"手动保存"直接写新存档无需 confirm |
| **Slot Selected** | 玩家点击某槽卡片 | 该槽左侧 4px `burst_gold` 竖条 + 底 `panel_bg_elevated`；ACTION BAR 按钮目标槽号更新 |
| **Current Slot Highlight** | 该槽 = 当前游戏所在存档位 | 四边 2px `burst_gold` 边框常驻；标签显示 "(当前)" |
| **Saving in Progress** | `SaveManager.is_saving() == true` | 半透明遮罩 (`#000` 30%) + spinner + "保存中..." 文本；所有 ACTION BAR 按钮 disabled；自动保存指示器切为黄点 + "正在保存..." |
| **Loading in Progress** | `SaveManager.is_loading() == true` | 半透明遮罩 + spinner + "读取中..."；所有按钮 disabled |
| **Save Success** | `save.saved` 事件（无 error） | 遮罩消失；P-FBK-01 Toast "存档 N 保存成功"（右上角，4s，`burst_gold` token）；自动保存指示器刷新为 "上次保存: 刚刚"；目标槽 metadata 刷新 |
| **Save Failed** | `save.saved` 事件（含 error） | 遮罩消失；P-FBK-01 Toast "存档 N 保存失败: [原因]"（`failure_red` token）；目标槽 metadata 不变 |
| **Load Success** | `save.loaded` 事件（无 error） | 遮罩消失 → UIManager 自动跳转修炼屏（默认首屏）；不在此屏停留 |
| **Load Failed** | `save.loaded` 事件（含 error） | 遮罩消失；P-FBK-01 Toast "读取失败: [原因]"（`failure_red`） |
| **Corrupted Save** | `save.corrupted` 事件或在 `list_saves()` 中 detected | 槽卡片边框变 `failure_red` 2px；左下角 ⚠ chip "存档损坏"；"读取""手动保存到此槽" disabled；"删除"可用 |
| **Backup Recovered** | `save.corrupted` 含 `recovered_from_backup: true` | 槽卡片显示 黄色边框 + chip "已从备份恢复"；metadata 使用 backup 文件的时间戳；"手动保存到此槽" 可用（覆盖损坏的主存档 + 有效 backup） |
| **Migration Needed** | `list_saves()` 中 save_version < CURRENT_SAVE_VERSION | 槽卡片右侧显示 "需要迁移 vN→vM" chip（`burst_gold` token）；"读取"可用但触发迁移链后再加载；hover tooltip 显示迁移路径说明 |
| **Migration in Progress** | 读取触发迁移链 | 遮罩 + "正在迁移存档 (1/3)..." 文本 + 进度条（按迁移链步数 fill）；完成后自动继续加载 |
| **Migration Failed** | 迁移链中某步返回 false / 错误 | 遮罩消失；P-FBK-01 Toast "存档迁移失败，已回退到备份"（`failure_red`）；槽卡片退回迁移前状态；按照 `save-system` GDD Edge Cases 规则 |
| **Confirm Overwrite Modal Open** | 点击"手动保存" + 目标槽已有数据 | P-NAV-03 modal 居中浮层；背景遮罩 `#000` 50%；显示 "将覆盖存档 N（Lv.32 筑基 · 12h 34m · 2026-05-05 14:32）"；主按钮 "确认覆盖"，取消按钮 "取消" |
| **Confirm Load Modal Open** | 点击"读取存档" + 目标槽有数据 | P-NAV-03 modal；显示 "读取后将丢失当前未保存进度（约 N 分钟）"；对比行：当前进度 (Lv/境界/时长) vs 存档进度；主按钮 "确认读取" |
| **Confirm Delete Modal Open (P-INP-02)** | 点击"删除存档" | P-INP-02 Confirm-Critical modal；标题 `failure_red` + ⚠ 图标；后果列表：等级/境界/时长/保存时间；强制 2s 倒计时进度条 + "我了解此操作不可逆"勾选框；主按钮 "删除此存档"（倒计时归零 + 勾选后可用）；取消按钮始终可用；**禁用**外部点击关闭 |
| **Time Frozen** | `TimeManager.is_frozen() == true` | 自动保存指示器追加 "(已冻结)" 灰字；手动保存按钮 disabled（无法生成有效保存时间戳） |
| **No Auto-Save Yet** | 新存档从未触发自动保存（`get_last_autosave_time()` 返回 null） | 自动保存指示器显示 "尚未自动保存" + 灰点 icon |

---

## Interaction Map

输入方法：键鼠（Primary）+ 手柄 Partial（D-Pad / A / B / X / Y / LB / RB）。无 touch。

| Action | Mouse / Keyboard | Gamepad | 即时反馈 | 结果 |
|---|---|---|---|---|
| 选择槽位 | Click 槽卡片 / Tab + Enter | D-Pad ↑↓ 选槽 + A | 左侧 4px `burst_gold` 竖条 + `panel_bg_elevated` 底（150ms） | UI only — ACTION BAR 按钮目标槽号更新 |
| 手动保存（目标槽有数据） | Click "手动保存" / Press `Ctrl+S` | X 键 | P-NAV-03 Confirm Overwrite modal 弹出（200ms scale+fade） | 确认后 `SaveManager.save_game(slot_index)` |
| 手动保存（目标槽为空） | Click "手动保存" / Press `Ctrl+S` | X 键 | 无 confirm — 直接进入 Saving 状态 | `SaveManager.save_game(slot_index)` |
| 读取存档 | Click "读取" / Press `Ctrl+L` | Y 键 | P-NAV-03 Confirm Load modal（显示进度对比）| 确认后 `SaveManager.load_game(slot_index)` + 成功后跳修炼屏 |
| 删除存档 | Click "删除" / Press `Del` | 长按 X 键 1s | P-INP-02 Confirm-Critical modal（2s 倒计时 + 勾选框） | 确认后 `SaveManager.delete_save(slot_index)` + 槽位刷新为空 |
| 取消 Modal | ESC / Click 遮罩（仅 P-NAV-03） | B 键 | Modal fade out 150ms | 回到存档屏 idle；无状态变更 |
| 确认 Modal | Click 确认按钮 / Enter | A 键 | 执行对应操作 + 关闭 modal | 保存/读取/删除 |
| 返回修炼屏 | Click "返回" / Press `1` | LB+D-Pad 选修炼 + A | 120ms cross-fade | `open_screen("cultivation")` |
| 切换主屏 | Click LEFT NAV / 数字 1-5 | LB / RB | 120ms cross-fade | `open_screen(...)` |
| Tooltip 触发（metadata 详情） | Mouse hover ≥ 0.5s | 焦点 + 长焦 0.8s | tooltip fade-in 150ms | P-INP-01 |

### Tab Order（accessibility Standard tier 强制）

AUTO-SAVE INDICATOR（焦点 readonly，跳过）→ Slot 1 卡片 → Slot 2 卡片 → Slot 3 卡片 → 手动保存按钮 → 读取存档按钮 → 删除存档按钮 → 返回按钮。共 **7 项可达交互**。

---

## Events Fired

| Player Action | Event Fired | Payload |
|---|---|---|
| 手动保存成功 | `save.saved`（SaveManager 自动发） | `{slot_index, saved_at, data_version}` |
| 手动保存失败 | `save.saved`（含 error 字段） | `{slot_index, error: "disk_full" \| "provider_error" \| ...}` |
| 读取存档成功 | `save.loaded`（SaveManager 自动发） | `{slot_index, loaded_at, data_version}` |
| 读取存档失败 | `save.loaded`（含 error） | `{slot_index, error: "..."}` |
| 删除存档成功 | `ui.save.deleted`（本屏发布） | `{slot_index}` |
| 存档损坏检测 | `save.corrupted`（SaveManager 自动发） | `{slot_index, recovered_from_backup: bool}` |
| 迁移链开始/完成/失败 | `save.migration.started` / `save.loaded` / `save.corrupted` | 随 SaveManager 现有事件体系 |
| 进入/离开本屏 | `ui.screen_opened` / `ui.screen_closed`（UIManager 自动发） | `{screen_id: "save"}` |
| 选择槽位 | **无事件** — 纯 UI 状态 | — |
| 自动保存成功（后台） | `save.saved`（SaveManager 自动发，本屏不操作） | 本屏收到后刷新 auto-save indicator 时间 |

### 架构标记

- 本屏**不直接写**任何 game state；所有保存/读取/删除操作走 SaveManager 公开 API
- `ui.save.deleted` 事件倾向走 UIManager 内部事件（本屏 → UIManager 通知刷新槽列表）；如 Settings 屏等需要感知存档删除，再升级到 EventBus
- 槽位列表数据来源：SaveManager 需新增 `list_saves()` 查询 API（见 §Data Requirements）
- 任何修改持久状态的 action 已经走 SaveManager command — UI 自身**不写**任何持久状态

---

## Transitions & Animations

| Trigger | Animation | Duration | Reduced-motion 替代 |
|---|---|---|---|
| 屏幕进入 | cross-fade | 120ms（ui-framework `default_transition_ms`） | instant cut |
| 屏幕退出 | cross-fade out | 120ms | instant cut |
| 槽位选中 | 左侧竖条 burst_gold 淡入 + 底 elevation 过渡 | 150ms | instant |
| Modal 打开（P-NAV-03） | scale 95% → 100% + fade | 200ms | fade only |
| Modal 关闭 | scale 100% → 95% + fade out | 150ms | instant |
| P-INP-02 倒计时进度条 | linear fill 2s | 2000ms | 同 — 功能性反馈 |
| Saving/Loading 遮罩 | fade in | 200ms | instant |
| Spinner（保存/加载中） | 循环旋转 | 持续直到完成 | 静态 "..." 文本替代 |
| 保存成功 Toast（P-FBK-01） | slide-in from right + fade | 200ms | fade only |
| 保存失败 Toast | slide-in from right + fade（`failure_red` token） | 200ms | fade only |
| 加载成功后跳转 | cross-fade 修炼屏 | 120ms | instant cut |
| 空槽 hover | `panel_bg_secondary` → `panel_bg_elevated` 过渡 | 150ms | instant |
| 迁移进度条 | linear fill（按迁移链步数 N 等分） | 取决于迁移链长度 | 同 — 功能性反馈 |
| 损坏存档标记出现 | `failure_red` 边框 fade in | 300ms | instant + 静态红边 |
| 自动保存指示器刷新 | 数字跳变（无动画） | 0ms | — |

### 禁区

- 本屏**不**触发 `burst_gold` 全屏印章（突破/飞升专用）
- 本屏**不**触发 `victory_burst_gold`（战斗专用）
- 本屏**不**触发 `failure_red` / `failure_grey` 全屏覆层（战斗失败专用）
- 本屏**不**触发任何持续动效背景（art-bible 状态① 禅静沉浸水墨云气由修炼屏承担）
- Save Success toast 使用 P-FBK-01 默认 `burst_gold` token，不触发全屏印章

---

## Data Requirements

| Data | Source System | R/W | Notes |
|---|---|---|---|
| 3 槽位存档列表（metadata 摘要） | `SaveManager.list_saves() -> Array[Dictionary]` | Read | **新 API** — 返回每个槽位的 `{slot_index, exists, meta: {version, saved_at, data_version, play_time_seconds}, portrait_ref, level, realm, save_size_bytes, corrupted, recovered_from_backup, migration_needed}` |
| 上次自动保存时间戳 | `SaveManager.get_last_autosave_time() -> float \| null` | Read | **新 API** — 返回 Unix 时间戳或 null（从未自动保存）；本屏每秒刷新一次相对时间显示 |
| 当前游戏所在槽位 | `SaveManager.get_current_slot() -> int` | Read | **新 API** — 返回当前活跃槽编号 |
| 自动保存间隔 | `SaveManager.AUTOSAVE_INTERVAL_SECONDS` | Read | 已有 config（来自 save-system GDD Tuning Knobs） |
| 当前存档格式版本 | `SaveManager.CURRENT_SAVE_VERSION` | Read | 已有 constant |
| 当前数据版本 | 数据配置系统 | Read | 已有 |
| 玩家 portrait 路径 | LevelSystem / ResourceSystem | Read | 复用 HUD 路径 |
| 玩家 level + realm | `LevelSystem.get_level("player")` / `.get_realm("player")` | Read | 已有（HUD 已订阅） |
| `save_game(slot_index: int)` | SaveManager command | Write（间接） | **扩展** — MVP 单槽 API 升级为支持 slot_index 参数 |
| `load_game(slot_index: int)` | SaveManager command | Write（间接） | **扩展** — 同上 |
| `delete_save(slot_index: int) -> bool` | SaveManager command | Write（间接） | **新 API** — 删除指定槽位的 `save.json` 和 `save.json.bak`；返回是否成功 |
| `is_saving()` / `is_loading()` | SaveManager query | Read | 已有（GDD §Detailed Design #12） |
| `TimeManager.is_frozen()` | TimeManager getter | Read | 已有（或建议新增简易 getter 避免每帧调 collect_save_data） |
| `collect_save_data()` | SaveManager query | Read（仅进度对比 modal 用） | 已有 — 用于 Confirm Load Modal 中"当前进度 vs 存档进度"对比 |

### 架构关注（ADR 评估）

Sprint 11 多存档槽需求对 SaveManager 提出架构变更，需立 **ADR-0018** 决议以下事项：

1. **多槽目录结构** — 倾向 `user://save/slot_0/save.json` + `save.json.bak`（每槽一个子目录），保持单槽原子写入不变
2. **4 个新 API** — `list_saves()` / `get_last_autosave_time()` / `get_current_slot()` / `delete_save()`；加上 `save_game(slot_index)` / `load_game(slot_index)` 的扩展
3. **向后兼容** — 旧单槽 `user://save/save.json` 在首次多槽保存时自动迁移到 Slot 0 子目录
4. **自动保存目标** — 自动保存始终写入当前活跃槽（不切槽）

如 ADR-0018 否决多槽目录方案，本屏降级为单存档槽模式（仅显示 1 个槽 + "新建存档"按钮不可用）。

UI 自身**不持有**任何 game state；所有读取走 host getter，所有写入走 command。符合 `.claude/rules/ui-code.md` "UI 必须 NEVER 拥有或直接修改 game state"。

---

## Accessibility

继承 `design/accessibility-requirements.md` Standard tier。本屏特化条款：

### 视觉

- 槽位卡片标题（"存档 1"）≥ 24px；metadata 文本 ≥ 20px（HUD 字号阈值）
- 所有可交互文本与背景对比 ≥ 4.5:1（theme.tres `text_primary` on `panel_bg_primary` ≈ 9:1 已满足）
- "损坏" chip 使用 `failure_red` + ⚠ 图标 + "存档损坏" 文字三重 backup
- "备份恢复" chip 使用 黄色边框 + "已从备份恢复" 文字，不依赖颜色
- 当前槽 vs 选中槽用不同视觉编码：当前 = 四边 border，选中 = 左侧竖条 + elevation — 两者可同时存在不冲突；色弱玩家可通过四边 border 识别当前槽
- 空槽用 ∅ icon + "尚未创建存档" 文本，不依赖灰色暗示"空"
- UI 缩放 75% / 90% / 100% / 125% / 150% 五档下布局不破，文字不裁切

### 键鼠/手柄等价

- Tab order 7 项可达交互（见 §Interaction Map）
- 当前焦点元素加 2px `burst_gold` 描边（与 hud.md 对齐）
- Modal 关闭：ESC / B 键（P-INP-02 除外 — 外部点击关闭被禁用，仅取消按钮 / B 键可以取消）
- Ctrl+S 全局快捷键手动保存（在修炼/战斗屏也可触发）
- Ctrl+L 全局快捷键读取存档（可选 — 如与其他快捷键冲突则降级）

### 时间相关

- **No timed input**：本屏无强制计时输入。P-INP-02 的 2s 倒计时是防误点机制，不是 gameplay 计时要求（accessibility-requirements §Cognitive 承诺 "无不可延长/取消的计时输入" 不对防误点机制生效）
- 自动保存指示器 "X 秒前" 文字每秒刷新一次 — 是信息更新，不是计时压力

### 动作/体力

- 所有按钮 hit area ≥ 32 × 32 px；槽卡片 hit area = 全卡片区域（约 1408 × 260 px @ 1080p）
- 无 button mashing：每次手动保存触发一次；保存中重复点击被忽略
- 长按（手柄删除存档 1s 长按 X 键）不是 gate — 玩家可通过 D-Pad 选槽 + A → 点击 "删除" 按钮替代

### Reduced Motion

详见 §Transitions & Animations 表 "Reduced-motion 替代" 列。Spinner 改为静态 "..." 文本；所有 transition ≤ 50ms 或 instant。

### 已知限制

- Menu screen reader（NVDA / Narrator passthrough）— 与 accessibility-requirements 全局一致，本屏不单独实现，记入项目级 Open Questions

---

## Localization Considerations

| 元素 | 中文最长 | 设计预留宽度 | 风险/备注 |
|---|---|---|---|
| 槽位标签 | 3 字 ("存档 1") | 8 字宽度 | 低 — 英文 "Slot 1" ≈ 6 字符 |
| 自动保存指示器 | ~20 字 ("上次自动保存: 30 秒前") | 40 字宽度 | **中** — 英文 "Last auto-save: 30 seconds ago" ≈ 28 字符；德文可能更长 |
| 逾期警告 | ~18 字 ("⚠ 距上次保存超过 5 分钟") | 32 字宽度 | **中** — 英文 "⚠ Last save over 5 minutes ago" ≈ 32 字符 |
| 空槽文本 | 6 字 ("尚未创建存档") | 16 字宽度 | 低 — 英文 "Empty Slot" ≈ 10 字符 |
| 游玩时长 | ~18 字 ("游玩时长: 12 小时 34 分") | 30 字宽度 | **中** — 英文 "Play time: 12h 34m" 更短；小时/分钟缩写因语言而异 |
| 保存时间戳 | ~30 字 ("保存于: 2026-05-05 14:32:15") | 40 字宽度 | **高** — 日期格式因 locale 不同（YYYY-MM-DD vs MM/DD/YYYY vs DD/MM/YYYY）；时间格式 12h vs 24h；必须用 `tr()` + locale-aware datetime format |
| 当前槽标记 | 4 字 ("(当前)") | 8 字宽度 | 低 — 英文 "(Current)" ≈ 9 字符 |
| 数据版本 | ~15 字 ("数据版本: 0.0.3") | 25 字宽度 | 低 |
| 存档格式版本 | ~15 字 ("格式 v1 · 需迁移") | 24 字宽度 | 低 |
| 迁移需求 chip | ~15 字 ("需要迁移 v1→v2") | 24 字宽度 | 低 |
| 损坏 chip | 6 字 ("存档损坏") | 12 字宽度 | 低 — 英文 "Corrupted" ≈ 9 字符 |
| 备份恢复 chip | 8 字 ("已从备份恢复") | 16 字宽度 | 低 — 英文 "Backup Restored" ≈ 16 字符 |
| ACTION BAR 按钮 | 8 字 ("手动保存到槽位 N") | 16 字宽度 | 低 — 英文 "Save to Slot N" ≈ 14 字符 |
| Modal 确认标题 | ~12 字 ("确认覆盖" / "确认读取" / "删除此存档") | 20 字宽度 | **中** — 英文 "Confirm Overwrite" ≈ 18 字符 |
| Modal 确认描述 | ~50 字 | **支持 3 行换行**，使用 RichTextLabel + autowrap | **高** — 翻译后易超长；必须 autowrap + 最小 3 行高度 |
| P-INP-02 勾选框文本 | ~12 字 ("我了解此操作不可逆") | 24 字宽度 | **中** — 英文 "I understand this cannot be undone" ≈ 36 字符 |
| Toast 消息 | ~15 字 ("存档 N 保存成功") | 24 字宽度 | 低 |
| Tooltip metadata | ~30 字 | RichTextLabel 多行 | 低 |

### HIGH PRIORITY 项（标记给 localization engineer）

- **保存时间戳格式** 必须使用 locale-aware datetime format，由 settings 的 locale 控制（`tr()` 格式化）；预测试中/英/德/日四种 locale 下的日期宽度
- **Modal 确认文本**（P-NAV-03 / P-INP-02）必须用 `RichTextLabel` + `autowrap_mode = AUTOWRAP_WORD_SMART`，最少支持 3 行；预测试德/法/西翻译
- **游玩时长格式** — "小时/分钟" 缩写因语言而异；英文 "12h 34m" vs 中文 "12小时34分" vs 德文 "12 Std. 34 Min."；建议用短格式配置表

### 数字格式

游玩时长中的小时/分钟/秒走本地化数字；BigNumber（等级/境界相关数字如经验值）走 NumberFormatter（ADR-0014）。

### 不需要本地化的元素

- portrait.png — 视觉无文字
- realm icon — 视觉无文字
- ∅ 空槽 placeholder icon — 视觉无文字
- 状态 icon（绿/黄/红点）— visual token，颜色之外有位置+文字 backup

---

## Acceptance Criteria

共 **15 条**，按类别分组：

### 导航

- [ ] **AC-1** LEFT NAV 点 "存档" / 数字键 `4` / 手柄 LB+D-Pad 选第 4 项 + A，3 种入口都能正确开屏（screenshot 证据 ×3）
- [ ] **AC-2** 屏内 ESC / B 键不会退出本屏；ESC/B 仅在 modal 打开时关闭 modal

### 槽位管理

- [ ] **AC-3** 3 个存档槽全部显示；空槽显示 ∅ icon + "尚未创建存档" 文本；当前活跃槽显示四边 `burst_gold` 2px 边框 + "(当前)" 标签
- [ ] **AC-4** 点击任一槽卡片选中该槽，左侧出现 4px `burst_gold` 竖条 + 底 `panel_bg_elevated`；ACTION BAR 按钮动态更新目标槽编号
- [ ] **AC-5** 选中空槽时，"读取""删除"按钮 disabled（不可操作）；"手动保存"可用且直接写新存档（不弹 confirm modal）

### 保存/读取/删除

- [ ] **AC-6** 手动保存到已有数据的槽：P-NAV-03 Confirm modal 弹出，显示将被覆盖的存档摘要（等级/境界/游玩时长/保存时间）；确认后执行保存；成功显示 P-FBK-01 Toast "存档 N 保存成功"；失败显示 Toast "保存失败: [原因]"
- [ ] **AC-7** 读取存档：P-NAV-03 Confirm modal 弹出，对比显示当前进度 vs 存档进度（等级/境界/游玩时长）；确认后进入 Loading 状态，成功后自动跳转修炼屏
- [ ] **AC-8** 删除存档：P-INP-02 Confirm-Critical modal（`failure_red` 标题 + 后果列表 + 2s 倒计时 + "我了解此操作不可逆"勾选框）；确认后删除文件，槽位刷新为空状态；Toast "存档 N 已删除"

### 自动保存指示器

- [ ] **AC-9** 自动保存指示器实时显示距上次自动保存的相对时间（"N 秒前"/"N 分钟前"），每秒刷新一次；距上次 > 5 分钟时显示 "⚠ 距上次保存超过 5 分钟" 警告文本 + 红点状态 icon；从未自动保存时显示 "尚未自动保存" + 灰点

### 异常状态

- [ ] **AC-10** 损坏存档：槽卡片 `failure_red` 2px 边框 + ⚠ "存档损坏" chip；"读取""手动保存到此槽" disabled；"删除"可用
- [ ] **AC-11** 备份恢复存档：槽卡片黄色边框 + "已从备份恢复" chip；metadata 使用 backup 文件时间戳；"手动保存到此槽" 可用（覆盖损坏主文件）
- [ ] **AC-12** 迁移待处理：槽卡片右侧显示 "需要迁移 vN→vM" chip；"读取"触发迁移链 → 遮罩 "正在迁移存档 (1/N)..." + 进度条 → 迁移完成后自动继续加载；迁移失败显示 Toast + 槽卡片回退到迁移前状态

### 保存/加载反馈

- [ ] **AC-13** 保存/读取/迁移进行中：半透明遮罩 (`#000` 30%) + spinner + 状态文本；所有 ACTION BAR 按钮 disabled；完成/失败后恢复正常状态

### Accessibility（Standard tier 强制）

- [ ] **AC-14** 键盘 Tab 顺序覆盖 7 项交互（Slot 1 → Slot 2 → Slot 3 → 手动保存 → 读取存档 → 删除存档 → 返回）；每个焦点显示 2px `burst_gold` 描边
- [ ] **AC-15** UI 缩放 75% / 100% / 150% 三档 + 1280×720 最小窗口下，布局不破、文字不裁切、所有 7 项交互仍可达；reduced-motion 开启时所有 transition ≤ 50ms 或 instant，spinner 改为静态 "..." 文本

---

## Open Questions

| Question | Owner | Deadline | Resolution |
|---|---|---|---|
| **SaveManager 多槽目录结构方案** — `user://save/slot_N/` 子目录 vs `user://save/save_N.json` 扁平文件？涉及 save-system GDD 架构变更，需 ADR-0018 | technical-director | Sprint 11 开发前 | **阻塞** — 需立 ADR-0018 决议；本 spec 假设子目录方案（`slot_N/save.json` + `slot_N/save.json.bak`） |
| **SaveManager 4 个新 API** — `list_saves()` / `get_last_autosave_time()` / `get_current_slot()` / `delete_save()` 是否在 Sprint 11 scope 内？还是先做 UI 占位 + Sprint 12 补 API？ | technical-director + producer | Sprint 11 开发前 | 未解决 — 倾向：先定义 API 签名（interface + stub），本屏开发时 mock；实现延后到 Sprint 12 |
| 删除存档是否支持 5 秒撤销窗口？save-system GDD 未提及撤销 | ux-designer + game-designer | Sprint 11 | 未解决 — 倾向：MVP 不做撤销（与 P-INP-02 的 undo toast 保留一致）；Post-MVP 补 |
| portrait 缩略图在空槽/损坏槽显示什么？∅ icon vs 默认 silhouette vs portrait + 破损叠加？ | art-director | Sprint 11 开发 | 未解决 — 倾向：空槽 = ∅ placeholder icon；损坏槽 = portrait 正常显示 + 红色破损边框叠加指示 |
| "读取存档" Modal 中"当前进度 vs 存档进度"的对比需要哪些字段？是否包括资源/战斗进度差异？ | ux-designer + game-designer | Sprint 11 | 未解决 — 倾向：MVP 仅显示等级 + 境界 + 游玩时长对比；资源/战斗进度差异 post-MVP |
| 自动保存指示器的"上次保存"时间是所有槽中最新的还是仅当前槽？ | ux-designer | Sprint 11 | 未解决 — 倾向：显示当前活跃槽的自动保存时间（玩家最关心的）；各槽卡片内独立显示各自的保存时间 |
| 是否需要"新建存档槽"按钮而非仅覆盖空槽？玩家可能想保留 Slot 1 当前进度并开始全新存档 | game-designer + ux-designer | Sprint 11 | 未解决 — 倾向：MVP 手动保存到空槽 = 新建；不提供专门的"新建存档"按钮；若 3 槽全满且玩家想开新存档，必须先删除一槽 |
| `list_saves()` 是读取文件系统实际 metadata 还是内存缓存？存档屏每次打开是否重新扫描？ | technical-director | Sprint 11 | 未解决 — 倾向：每次 open 本屏时重新 `list_saves()` 扫描文件系统（轻量，仅读 meta 不读全 systems）；`save.saved` 事件后增量刷新目标槽 |
| `design/player-journey.md` 缺失 — 存档屏访问频率/时长/首次进入时机缺乏 journey 文档支撑 | producer | Pre-Production | 未解决 — 与其他 5 屏共性问题 |
| P-INP-02 Confirm-Critical Modal 的 2 秒倒计时是否被 accessibility "no timed input" 命中？倾向：算"防误点"而非"计时输入"，但需 user testing 验证 | ux-designer | Pre-Production | 未解决 — 与 interaction-patterns.md Open Questions 第 3 条同步 |
