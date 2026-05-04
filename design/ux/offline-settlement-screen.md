# UX Spec: 离线结算屏 (Offline Settlement Screen)

> **Status**: In Design
> **Author**: binlee1990 + ux-designer
> **Last Updated**: 2026-05-05
> **Journey Phase(s)**: 待补 — design/player-journey.md 不存在；本 spec 假设离线结算屏出现在玩家每次"从离线回归 → 查看收益 → 继续修炼"的循环中，是 game-concept §10.2 闭环的第七步（离线结算）
> **Platform Target**: PC (Steam/Epic) — Keyboard/Mouse + Gamepad Partial
> **Template**: UX Spec
> **Sprint**: Sprint 11 / mvp-screens / S11-013
> **Asset Manifest 引用**: §9 offline_paper（全屏背景）+ §2 全 5 资源图标 + §6 rarity_frame（离线掉落物品）+ §11 enemy portraits（战斗记录来源）+ §5 offline_pending（LEFT NAV 角标）+ §1 theme.tres（强制）

---

## Purpose & Player Need

离线结算屏是玩家的**闭关报告**——一份详细的"你不在的时候发生了什么"的收获清单。离线抽屉（P-NAV-04）回答"我得到了什么"的速览问题；本屏回答**"我得到了多少 / 为什么有些没拿到 / 下次如何优化"**的深度问题。

### 核心玩家目标

1. **看到收获全貌** — 离线多久、总共产出了多少资源、哪些入账了、哪些因满仓损失了。把所有数字摆在玩家面前，让"数字增长就是快乐"（pillar 4.1）在回归瞬间集中释放。
2. **理解损失原因** — 如有资源因 StorageLimit 满仓而损失，明确标出损失量 + 来源（哪个容器满了），让玩家形成"下次扩容"或"提前消费"的决策意图（pillar 4.2 低频高价值决策）。
3. **欣赏战利品** — 离线战斗中掉落的物品以 P-DAT-04 卡片网格展示，稀有度边框让玩家一眼看到"出了好东西"，建立对离线战斗的期待锚点。
4. **快速决策回归** — 玩家看完报告后，一个按钮回到修炼（继续 idle 循环），或"延后查看"先回到之前在做的屏（不打断之前的操作意图）。

### Sentence form

> "The player opens this screen wanting to **savor** their offline harvest, **understand** what was gained and lost, **inspect** any rare loot found, and **decide** whether to dive deeper or continue cultivating."

### 反向定义（这里不做什么）

- 不发起任何资源写入（本屏纯只读；settlement 在 `offline.settled` 事件前已完成）
- 不重复离线抽屉的所有内容（抽屉 = 速览；本屏 = 完整拆解）
- 不做实时数据刷新（settlement 数据是 snapshot，打开后不变）
- 不做"再算一次"（无重算按钮；数据来自 OfflineSettlementSummary，不可变）
- 不承载教程文字（教程系统 GDD 38 负责）
- 不触发突破 / 飞升印章（本屏不涉及境界变化）

### 与 game-concept §10.2 的关系

本屏是 MVP 闭环的**第七步**（离线结算）。玩家完成"修炼 → 资源 → 等级 → 战斗 → 掉落 → 推进区域 → **离线结算**"后回到修炼屏，形成完整循环。每次玩家回归时本屏（或其速览版 drawer）触达一次。

### Pillar 锚定

- **4.1 数字增长就是快乐** — 离线结算把"你不在时积累的数字"集中呈现，count-up 动画强化增长感受
- **4.2 放置 = 低频高价值决策** — 损失信息驱动"扩容 vs 消费"的策略决策，不是秒级操作
- **4.6 渐进叙事** — 首次看到离线报告时的"闭关报告"仪式感，让玩家感觉"我真的在修仙"

---

## Player Context on Arrival

| 维度 | 答案 |
|------|------|
| **何时首次遇到** | 第一次离线回归（游戏运行过、关闭过、再打开）后，在离线抽屉中点击"查看详情"；或之后随时通过 LEFT NAV "📅离线" tab 主动打开 |
| **之前在做什么** | **刚从离线回归** — 可能在修炼屏、战斗屏、资源屏；游戏检测到离线时长 > 0 且 settlement 已完成后触发 drawer；**或者**在之后的游戏中想回顾上一次离线收益 |
| **情绪状态（设计假设）** | **期待 + 好奇** — 玩家想知道"我不在的时候发生了什么"。不是战斗后的高肾上腺素，不是 Boss 前的紧张；是"拆礼包"的期待感。锚点：art-bible 状态③爆发荣耀的温和变体（不是全屏印章那么强烈，而是"数字跳动的满足"） |
| **主动 vs 被动** | **混合** — 首次回归时 drawer 被动弹出，玩家主动选择"查看详情"才进入本屏；后续通过 LEFT NAV 主动访问 |

### 派生设计含义（约束 Layout 与 Transitions）

- **Grand entrance, not splash**：玩家点"查看详情"进入本屏时，不是 loading 态而是 count-up 动画（数字从 0 滚动到最终值），制造"开箱"仪式感
- **第一眼焦点 = 离开时长**：大号 duration 文字先出现（"你离开了 8 小时 23 分钟"），然后资源数字依次开始 count-up——先定锚（多久）再释放（多少收获）
- **Scroll-friendly**：长离线时资源 + 物品内容多，垂直滚动是预期行为；短离线的报告无需滚动即可看完
- **离开时无确认**：本屏无不可逆操作（纯只读），所有出口按钮一键直达，不弹"确定要离开吗"
- **"延后查看"保留上下文**：如果玩家在 drawer 中点"查看详情"进入本屏，点"延后查看"应回到 drawer 出现前所在的屏（不是硬切修炼屏），尊重玩家之前的操作意图

---

## Navigation Position

离线结算屏位于 **Root → ScreenStack → OfflineSettlementScreen**（LEFT NAV "📅离线" tab，第 5 位）。本屏不是默认首屏（首屏是修炼屏），但在首次回归后通过离线抽屉的"查看详情"主动推入 ScreenStack。

### 替代入口

| 入口源 | 触发方式 |
|--------|---------|
| 离线抽屉 "查看详情" 按钮 | 鼠标点击 / 键盘 Enter / 手柄 A |
| LEFT NAV "📅离线" tab | 鼠标点击 / 键盘 ↑↓ + Enter / 手柄 D-Pad ↑↓ + A |
| 全局快捷键 `5` | 数字键 1–5 直达 5 主区域，离线结算 = `5` |
| 调试控制台 `goto offline_settlement` | dev only；release 构建排除（ADR-0012） |

### 不能从这里到达的地方

离线结算屏**不通向**任何子屏（无层级深度）。所有操作（查看物品详情 tooltip / 延后查看 / 继续修炼）都在本屏内或直接导航走。无 modal 子层。

### LEFT NAV 角标行为

- `offline.settled` 事件触发后，LEFT NAV "📅离线" tab 显示 `offline_pending.png` 角标（§5 status icon）
- 玩家首次打开本屏（通过任意入口）后，角标消失
- 同一 session 内后续 `offline.settled` 事件重新点亮角标

---

## Entry & Exit Points

### Entry

| Entry Source | Trigger | Player carries this context |
|---|---|---|
| 离线抽屉 "查看详情" | `offline.settled` → drawer slide-in → 玩家点 "查看详情" | Settlement 数据已生成；玩家已知 quick summary（从 drawer） |
| LEFT NAV "📅离线" tab | Click / Press `5` / D-Pad 选第 5 项 + A | 当前游戏状态；显示最近一次 settlement 数据 |
| Debug `goto offline_settlement` | dev only | — |

### Exit

| Exit Destination | Trigger | Notes |
|---|---|---|
| 修炼屏 | "继续修炼" 按钮 / Press `1` | 默认回归 — 玩家看完报告继续 idle 循环 |
| **之前活跃的屏** | "延后查看" 按钮 | **关键**：不硬切修炼屏，而是回到 drawer 触发前玩家所在的屏（`UIManager.previous_screen`）。如无 previous screen 则回修炼屏 |
| 任意主屏 | LEFT NAV / 数字 1–5 | 标准主屏切换 |
| 离线抽屉（返回） | 无直接路径 — drawer 是 overlay 不是屏；关闭 drawer 后玩家已在本屏或之前屏 |
| App quit | 系统关闭 | 触发 SaveManager auto-save |

无一次性出口；所有 exit 可通过 LEFT NAV 返回本屏，无不可逆状态。

---

## Layout Specification

### Information Hierarchy

按"闭关报告"的阅读逻辑，从上到下：

1. **Hero Tier**（屏幕顶部，第一眼看到）— 沉浸锚点
   - 离开时长大号文字："你离开了 8 小时 23 分钟"
   - 5 资源 total gross 水平汇总条（一行看完总收获）
   - "延后查看"按钮（右上角，secondary action）
2. **Detail Tier**（屏幕中部，主要阅读区）— 玩家理解"为什么"
   - 每个资源的详细卡片：gross / claimed / lost + 来源拆解（生产/战斗/探索）
   - 损失资源红色高亮 + tooltip 解释原因
3. **Collection Tier**（屏幕中下部）— 玩家欣赏战利品
   - 离线战斗掉落的物品网格（P-DAT-04 Item Card + rarity frame）
   - 空状态："本次离线未获得物品"
4. **Action Tier**（屏幕底部）— 玩家决策下一步
   - "继续修炼" 主按钮（回归 idle 循环）
5. **Ambient Tier**（背景，不参与交互）
   - `offline_paper.png` 全屏背景（卷轴质感）+ 半透明 dim
   - 水墨风边框装饰

### Layout Zones

离线结算屏占 **HUD 的 CENTER CONTENT 区**（即去除 TOP STRIP 64px / LEFT NAV 192px / RIGHT PANEL 320px / BOTTOM ACTION BAR 之后的区域）。

@ 1080p 基线：CENTER CONTENT 可用区域 ≈ **1408 × 1016 px**。

本屏采用**垂直滚动布局**（ScrollContainer），内容从上到下排列。短离线报告无需滚动即可看完；长离线报告可向下滚动。

| Zone | 位置 | 尺寸 @ 1080p | 内容 |
|---|---|---|---|
| **DURATION HERO** | 顶部居中 | 1408 × 180 px | 离开时长大字 + 5 资源 total gross 水平条 + "延后查看"按钮（右上浮动） |
| **RESOURCE BREAKDOWN** | 中上部 | 1408 × auto（≥ 300 px） | 最多 5 个资源详细卡片，每卡含 gross / claimed / lost + 来源拆解 |
| **LOOT GALLERY** | 中下部 | 1408 × auto（≥ 200 px） | "离线战利品"标题 + 物品卡片网格（P-DAT-04）+ 空状态兜底 |
| **ACTION BAR** | 底部固定 | 1408 × 64 px | "继续修炼" 主按钮；不随滚动 |

### 屏幕安全区

- 1280×720 最小窗口：Duration Hero 缩到 140 px；Resource Breakdown 卡片等比例缩窄；Loot Gallery 物品卡片网格态可用 80×80 单元
- 4K：等比例放大；字号 +1 档（24px → 28px）
- Steam Deck 1280×800：LEFT NAV 折叠 48px；CENTER 垂直滚动保持比例

### Component Inventory

按 zone 分组；每行标注：组件类型 / 内容 / 是否交互 / 引用 pattern 或新组件。

#### DURATION HERO ZONE

| Component | Type | Content | Interactive | Pattern |
|---|---|---|---|---|
| Background fill | TextureRect | offline_paper.png 9-slice 拉伸 | No | §9 |
| Duration label | Label (hero) | "你离开了 X 小时 YY 分钟"（≥ 28px，text_primary） | No | — |
| Total gross summary bar | HBoxContainer | 5 个资源图标 + 各自 total gross 数字（水平排列） | No（hover tooltip 显示资源名） | 复用 P-DAT-01 图标位 + 数字；简化版（无 fill bar / cap） |
| "延后查看" 按钮 | Button (secondary) | "延后查看" | Yes | — |

#### RESOURCE BREAKDOWN ZONE（ScrollContainer 内容区）

| Component | Type | Content | Interactive | Pattern |
|---|---|---|---|---|
| Resource Detail Card × N（N ≤ 5） | PanelContainer 自定义 | **头部**：24×24 图标 + 资源名 + gross/claimed/lost 三列数字；**来源拆解**：生产/战斗/探索各自贡献值 | Yes（loss row hover tooltip；来源拆解行 hover tooltip） | **新 component**：P-DAT-05 Settlement Row（结算资源行），建议入 interaction-patterns.md |
| Lost highlight | 行级样式 | lost > 0 的行：`bottleneck_red` 文字 + 行背景暗红 8% opacity | No（hover tooltip） | P-FBK-02 语义色 |
| Source breakdown sub-row | Label × 3 | "生产: +N" / "战斗: +N" / "探索: —"（探索暂无数据时灰字） | No（hover tooltip 显示模拟器名称） | — |

#### LOOT GALLERY ZONE

| Component | Type | Content | Interactive | Pattern |
|---|---|---|---|---|
| Section header | Label | "离线战利品" + 物品数量（如"（3 件）"） | No | — |
| Item card grid | GridContainer | 物品图标 + rarity_frame 边框 + 物品名 + 数量 | Yes（hover tooltip 显示物品详情；click 暂无行为 — post-MVP 可跳转物品详情屏） | P-DAT-04 Item Card（网格态 96×128） |
| Empty state | Label | "本次离线未获得物品"（text_secondary 斜体） | No | P-DAT-EMPTY 模板 |
| Enemy portrait (可选) | TextureRect | 离线战斗中遇到的敌人 portrait（如 settlement 含战斗） | No（hover tooltip 显示敌人名） | §11 |

#### ACTION BAR ZONE（底部固定）

| Component | Type | Content | Interactive | Pattern |
|---|---|---|---|---|
| "继续修炼" 按钮 | Button (primary) | "继续修炼"（24px + burst_gold 边框不填充） | Yes | 导航至 cultivation_screen |

#### 组件总数

6 个交互元素 + 12 个静态显示 + 0 个 modal = 共 18 个 UI components。

### ASCII Wireframe

```
┌── HUD TOP STRIP (64px, 固定) ─────────────────────────────────────────────┐
│ ⛬ 1.2K ◯ 850K ◇ 12.5M ❀ 234K  │  Lv.1 凡人  │  📊修炼 ▼  │  ⚙          │
├──────┬─────────────────────────────────────────────────────┬───────────────┤
│LEFT  │  ╔═══════════════════════════════════════════════╗  │ RIGHT PANEL   │
│NAV   │  ║ DURATION HERO ZONE (1408×180)                 ║  │               │
│192px │  ║                                              ║  │ 战斗日志 ▼    │
│      │  ║        你离开了 8 小时 23 分钟          [延后查看]║  │ ┌───────────┐ │
│📊修炼│  ║                                              ║  │ │ 17:32     │ │
│⚔战斗│  ║  ⛬ 12.5K   ◯ 850   ◇ 120   ❀ 45   ✦ 2.3K   ║  │ │  普攻     │ │
│📦资源│  ║  (5 资源 total gross 水平汇总条)              ║  │ │  暴击!    │ │
│💾存档│  ╠═══════════════════════════════════════════════╣  │ │   ...     │ │
│📅离线│  ║ RESOURCE BREAKDOWN ZONE (scrollable)          ║  │ │  ▼ jump   │ │
│  🔴  │  ║                                              ║  │ └───────────┘ │
│      │  ║ ┌─────────────────────────────────────────┐  ║  │               │
│      │  ║ │ ⛬ 灵气                                    │  ║  │               │
│      │  ║ │   总计产出: 12,500  实际入账: 12,500  损失: 0│  ║  │               │
│      │  ║ │   来源: 生产 +10,200 | 战斗 +2,300 | 探索 — │  ║  │               │
│      │  ║ └─────────────────────────────────────────┘  ║  │               │
│      │  ║ ┌─────────────────────────────────────────┐  ║  │               │
│      │  ║ │ ◯ 修为                                    │  ║  │               │
│      │  ║ │   总计产出: 850    实际入账: 850    损失: 0  │  ║  │               │
│      │  ║ │   来源: 生产 +850  | 战斗 —    | 探索 —     │  ║  │               │
│      │  ║ └─────────────────────────────────────────┘  ║  │               │
│      │  ║ ┌─────────────────────────────────────────┐  ║  │               │
│      │  ║ │ ❀ 药材  ⚠ 损失                           │  ║  │               │
│      │  ║ │   总计产出: 45     实际入账: 12    损失: 33  │  ║  │               │
│      │  ║ │   来源: 生产 +24   | 战斗 +21  | 探索 —     │  ║  │               │
│      │  ║ │   ⓘ 损失原因: 药材仓库已满 (12/200)         │  ║  │               │
│      │  ║ └─────────────────────────────────────────┘  ║  │               │
│      │  ║ ... (最多 5 资源卡片，向下滚动可见更多)        ║  │               │
│      │  ╠═══════════════════════════════════════════════╣  │               │
│      │  ║ LOOT GALLERY ZONE                            ║  │               │
│      │  ║                                              ║  │               │
│      │  ║  离线战利品 (3 件)                             ║  │               │
│      │  ║  ┌──────┐ ┌──────┐ ┌──────┐                 ║  │               │
│      │  ║  │🐉鳞甲│ │💎海珠│ │🧪邪尘│                 ║  │               │
│      │  ║  │ 史诗 │ │ 稀有 │ │ 精良 │                 ║  │               │
│      │  ║  │  ×2  │ │  ×1  │ │  ×5  │                 ║  │               │
│      │  ║  └──────┘ └──────┘ └──────┘                 ║  │               │
│      │  ║                                              ║  │               │
│      │  ║  🐺 森林狼  🧟 邪修弟子                       ║  │               │
│      │  ║  (可选: 战斗中遇到的敌人 portrait)              ║  │               │
│      │  ╠═══════════════════════════════════════════════╣  │               │
│      │  ║ ACTION BAR (64px, 固定底部)                   ║  │               │
│      │  ║           ┌──────────────────┐               ║  │               │
│      │  ║           │    继续修炼       │               ║  │               │
│      │  ║           └──────────────────┘               ║  │               │
│      │  ╚═══════════════════════════════════════════════╝  │               │
└──────┴─────────────────────────────────────────────────────┴───────────────┘
```

> **Wireframe 注**：本 wireframe 展示 1080p 默认布局，RESOURCE BREAKDOWN 区域可垂直滚动（offline_paper 背景随滚动延伸）。实际像素位由 art-director 在 hud-real-layout S11-004 期间结合 theme.tres 微调。"损失"行仅在 lost > 0 时显示；"探索"列在 MVP 中始终显示 "—"（探索系统未实现，预留列位）。LEFT NAV "📅离线" tab 上的 🔴 表示 offline_pending 角标（有未查看的 settlement）。

---

## States & Variants

| State / Variant | Trigger | What Changes |
|---|---|---|
| **Normal Settlement** | 离线时长 > 0 + settlement 成功 | 全屏显示 settlement 数据；count-up 动画播放 |
| **No Offline Progress** | 离线时长 = 0（刚保存又马上打开） | Duration Hero 显示"你刚刚离开，暂无离线收益"；Resource Breakdown 隐藏；Loot Gallery 隐藏；Action Bar 仅显示"继续修炼"；**不触发 count-up 动画** |
| **Capacity Loss Present** | 至少一个资源的 lost > 0 | 该资源卡片：lost 列 `bottleneck_red` 文字 + 行背景暗红 8% opacity + "损失原因" tooltip 行出现（"X 仓库已满 (current/max)"）；DURATION HERO total gross 汇总条该资源数字右侧出现 ⚠ chip |
| **All Resources Lost** | 所有资源 lost == gross（极端满仓） | 所有资源卡片红色高亮；DURATION HERO 下方显示警告 banner："所有仓库已满，离线收益全部损失。建议扩容后再离开。"（`bottleneck_red` chip + 文字） |
| **Combat Loot Present** | 离线战斗产生掉落 | LOOT GALLERY 正常显示物品卡片网格 + 敌人 portrait 行 |
| **No Combat Loot** | 离线战斗无掉落或未发生战斗 | LOOT GALLERY 显示空状态："本次离线未获得物品"（text_secondary 斜体）；敌人 portrait 行隐藏 |
| **Settlement Data Expired** | 玩家已查看过 settlement + 无新 settlement | 显示上次 settlement 数据（历史快照）；DURATION HERO 顶部追加灰色小字 "上次离线收益 — 2026/05/04 22:15" |
| **Settlement Failed** | `offline.settled` 状态 = Failed | Duration Hero 显示"离线收益结算异常"；Resource Breakdown 隐藏；显示错误摘要 + "收益已自动重试，如持续失败请联系客服"；Action Bar 仍可用 |
| **Loading** | 从 drawer 点"查看详情"后，screen transition 期间 | 骨架屏：Duration Hero 显示"..."占位；Resource Breakdown 区 3 个灰色占位卡片（shimmer）；200ms 内 count-up 开始 |
| **Reduced Motion Active** | 玩家在 Settings 开启 reduce motion | count-up 动画跳过，数字直接显示最终值；screen enter transition = instant cut（120ms → 0ms） |

---

## Interaction Map

输入方法：键鼠（Primary）+ 手柄 partial（D-Pad / A / B / X / Y / LB / RB）。无 touch（technical-preferences `Touch Support: None`）。

| Action | Mouse / Keyboard | Gamepad | 即时反馈 | 结果 |
|---|---|---|---|---|
| 打开本屏（从 drawer） | Click "查看详情" / Enter | A 键 | Drawer fade out 150ms → 本屏 cross-fade in 120ms + count-up 动画开始 | `UIManager.open_screen("offline_settlement")` |
| 打开本屏（从 LEFT NAV） | Click "📅离线" / Press `5` | D-Pad ↑↓ + A | 120ms cross-fade + count-up 动画（仅首次查看当前 settlement 时播放） | 同上 |
| 滚动内容 | 滚轮 / PgUp/PgDn / 拖滚动条 | 右摇杆 ↑↓ | 即时滚动；ACTION BAR 固定在底部不随滚动 | UI only |
| "继续修炼" | Click button / Enter（焦点时） | A 键 | 120ms cross-fade | `UIManager.open_screen("cultivation")` |
| "延后查看" | Click button / ESC（当无 modal 时） | B 键 | 120ms cross-fade | `UIManager.open_screen(previous_screen \|\| "cultivation")` — 回之前活跃的屏 |
| Tooltip 触发（损失原因 / 资源名 / 来源拆解 / 物品详情） | Mouse hover ≥ 0.3s | 焦点 + 长焦 0.5s | tooltip fade-in 150ms | P-INP-01 |
| 物品卡片 hover | Mouse hover | 焦点 | 卡片边框微亮（rarity_frame 外发光 + 10%）+ tooltip | P-DAT-04 + P-INP-01 |
| 关闭本屏（去其他主屏） | Click LEFT NAV / 数字 1–5 | LB / RB 切 tab | 120ms cross-fade | `UIManager.open_screen(...)` |

### Tab Order（accessibility-requirements Standard tier 强制）

"延后查看" 按钮 → Resource Card 1 损失 tooltip（如存在）→ Resource Card 2 损失 tooltip → ... → Resource Card 5 → Loot Gallery 物品 1 → 物品 2 → ... → 物品 N → "继续修炼" 按钮。共 2 + N_resources_with_loss + N_items 项可达交互。

---

## Events Fired

| Player Action | Event Fired | Payload |
|---|---|---|
| 进入本屏 | **无新事件** — 本屏消费已存在的 `offline.settled` 事件数据；`ui.screen_opened` 由 UIManager 自动发 | `{screen_id: "offline_settlement"}` |
| 离开本屏 | `ui.screen_closed`（UIManager 自动发） | `{screen_id: "offline_settlement"}` |
| 首次查看当前 settlement（本屏打开 + settlement 未 viewed） | `offline.settlement.viewed`（**新增事件**，建议 OfflineRewardSettlementSystem 发布） | `{settlement_id, viewed_at_timestamp}` — 用于熄灭 LEFT NAV offline_pending 角标 |
| "继续修炼" | `ui.screen_opened`（cultivation） | — |
| "延后查看" | `ui.screen_opened`（previous_screen） | — |
| 滚动 / tooltip / hover | **无事件** — 纯 UI 行为 | — |

### 架构标记

- 本屏**是纯消费者** — 所有数据来自已生成的 `OfflineSettlementSummary`（read-only snapshot）；不调用任何 command
- `offline.settlement.viewed` 事件是本屏**唯一建议新增的事件** — 用于熄灭 LEFT NAV 角标 + 未来 analytics 埋点；如 MVP 不实现此事件，角标熄灭改为 UIManager 内部状态（`if opened_screen == "offline_settlement" → clear_badge("offline")`）
- 本屏**不订阅** EventBus 实时更新（settlement 数据是打开时的 snapshot，不需要实时刷新）

---

## Transitions & Animations

| Trigger | Animation | Duration | Reduced-motion 替代 |
|---|---|---|---|
| 屏幕进入（从 drawer "查看详情"） | Drawer slide-out right 150ms → 本屏 cross-fade in 120ms → count-up 开始 | 总 ~1.7s（含 1.5s count-up） | Drawer instant close → 本屏 instant cut → 数字直接显示 |
| 屏幕进入（从 LEFT NAV） | cross-fade in | 120ms | instant cut |
| 屏幕退出 | cross-fade out | 120ms | instant cut |
| **Count-up 动画（核心）** | 5 资源 total gross 数字 + 每个资源卡片的 gross/claimed/lost 数字从 0 滚动到最终值（ease-out，像收银机） | 1.5s（可配置） | **关闭** — 数字直接显示最终值 |
| Count-up 序列 | (1) Duration 文字 300ms fade-in → (2) 200ms 后 total gross 行 5 数字并行 count-up → (3) 200ms 后 Resource Breakdown 卡片各行依次 stagger（每行延迟 100ms）→ (4) Loot Gallery fade-in 200ms | 全部自动编排 | 全部 instant |
| 损失行出现 | lost > 0 的行：`bottleneck_red` 文字 + 行背景暗红 fade-in | 300ms（在 count-up 到达最终值后触发） | instant + 静态红边 |
| 物品卡片 grid 出现 | fade-in + 轻微 scale 0.95→1.0（每行 stagger 50ms） | 200ms per row | instant |
| 离线战利品空状态出现 | 简单 fade-in | 150ms | instant |
| "继续修炼"按钮 hover | 边框 `burst_gold` 亮度 + 20%（与 theme.tres Button hover 状态一致） | 100ms | 同（功能性反馈，不算 motion） |

### Count-up 动画详细时序

```
t=0ms     屏幕 cross-fade in 完成
t=0ms     Duration 文字 "你离开了 8 小时 23 分钟" fade-in 开始
t=300ms   Duration 文字完全可见
t=500ms   5 资源 total gross 数字并行 count-up 开始
t=2000ms  Total gross count-up 完成
t=2200ms  Resource Card 1 数字 count-up 开始
t=2300ms  Resource Card 2 数字 count-up 开始（+100ms stagger）
t=2400ms  Resource Card 3 数字 count-up 开始
...以此类推
t=3200ms  所有 Resource Card count-up 完成
t=3200ms  如有损失行 → bottleneck_red fade-in 300ms
t=3500ms  Loot Gallery fade-in 200ms 开始
t=3700ms  全部动画完成
```

> **注**：上述时序为默认（reduced-motion = false）。总动画时长约 3.7s，其中 count-up 主体占 1.5s。玩家可在任意时刻滚动或点击按钮，动画不阻塞交互（动画继续播放但玩家操作即时响应）。

### 禁区

- 本屏**不**触发 `burst_gold` 全屏印章（突破 / 飞升专用）
- 本屏**不**触发 `victory_burst_gold`（战斗专用）
- 本屏**不**触发 `failure_red` / `failure_grey`（战斗失败专用）
- 本屏**不**触发 `manual_click_pulse` VFX（修炼屏专用）
- 全屏水墨云气背景动效：`offline_paper.png` 静态纹理即可，MVP 不加动态背景

---

## Data Requirements

| Data | Source System | R/W | Notes |
|---|---|---|---|
| `OfflineSettlementSummary`（完整） | `OfflineRewardSettlementSystem.get_last_summary()` | Read | 已生成 snapshot；包含 gross / claimed / lost / breakdown / duration / warnings |
| `summary.duration_seconds` | 同上 | Read | 用于 Duration Hero 显示；格式化由本屏负责（时/分/秒） |
| `summary.total_gross` / `summary.total_claimed` / `summary.total_lost` | 同上 | Read | 按资源 ID 索引的 Dictionary；用于 total gross 汇总条和 Resource Breakdown 卡片 |
| `summary.simulator_breakdown[resource_id]` | 同上 | Read | 按模拟器来源拆解：`{production: BigNumber, combat: BigNumber, exploration: BigNumber}` |
| `summary.warnings[]` | 同上 | Read | 字符串数组；用于损失原因 tooltip 和警告 banner |
| `summary.loot_items[]` | 同上 | Read | 物品数组：`[{item_id, quantity, rarity, enemy_source?}]`；用于 Loot Gallery |
| `summary.enemies_encountered[]` | 同上 | Read | 敌人 ID 数组；用于敌人 portrait 行（可选） |
| `UIManager.previous_screen` | UIManager | Read | 用于"延后查看"回到之前屏；如为 null 则 fallback 到 cultivation |
| `settings.reduce_motion` | SettingsSystem | Read | 控制 count-up 动画开关 |
| LEFT NAV badge state | UIManager 内部 | Read/Write（间接） | `offline.settlement.viewed` 事件触发后熄灭角标；或 UIManager 内部判断 |

### 架构关注

本屏**不新增任何 system API**。所有数据已存在于 `OfflineSettlementSummary`（由 settlement 系统在 `offline.settled` 事件前生成）。`OfflineRewardSettlementSystem` 需暴露一个简单的 getter `get_last_summary() -> OfflineSettlementSummary` 供本屏读取。

UI 自身**不持有**任何 game state；不写任何持久状态。符合 `.claude/rules/ui-code.md` "UI 必须 NEVER 拥有或直接修改 game state"。

---

## Accessibility

继承 `design/accessibility-requirements.md` Standard tier。本屏特化条款：

### 视觉

- Duration 文字 ≥ 28px（hero 级别）；total gross 汇总条数字 ≥ 24px（P0 数据级别）；Resource Breakdown 卡片标题 ≥ 20px（HUD 级别）；卡片内来源拆解 ≥ 18px；Loot Gallery 物品名 ≥ 16px
- 所有可交互文本与背景对比 ≥ 4.5:1（theme.tres `text_primary` on `panel_bg_primary` ≈ 9:1 已满足）
- 损失信息三重 backup：`bottleneck_red` 文字色 + ⚠ 图标 + 文字说明"损失原因: X 仓库已满"
- 5 资源图标形状已不同（不依赖颜色识别资源 — art-bible Sec 4.6 色弱 backup 自带）
- 8 阶稀有度物品卡片三重 backup：rarity_frame 边框形状 + 文字角标"凡/精/稀/史/传/神/先/混" + 颜色
- UI 缩放 75% / 90% / 100% / 125% / 150% 五档下布局不破，文字不裁切，ScrollContainer 正常滚动

### 键鼠 / 手柄等价

- Tab order 见 §Interaction Map（2 + N_loss_rows + N_items 项可达交互）
- 当前焦点元素加 2px `burst_gold` 描边（与 hud.md 对齐）
- "延后查看"：ESC / 手柄 B 键（当无 modal 时）
- "继续修炼"：Enter / 手柄 A 键（当焦点在按钮时）
- ScrollContainer 滚动：键盘 PgUp/PgDn / 手柄右摇杆
- 物品卡片焦点：D-Pad ←→↑↓ 在 GridContainer 内移动

### 时间相关

- **No timed input**：本屏无强制计时输入；count-up 动画纯观赏性，播放期间所有按钮可正常点击
- Count-up 动画时长 1.5s，期间交互不阻塞

### 动作 / 体力

- **No button mashing**：所有按钮单击触发
- 所有可交互 hit area ≥ 32 × 32 px（按钮）/ 48 × 48 px（物品卡片）
- ScrollContainer 支持键盘 / 手柄滚动，不强制鼠标滚轮

### Reduced Motion

详见 §Transitions & Animations 表"Reduced-motion 替代"列。核心：count-up 动画完全关闭，数字直接显示最终值；所有 transition ≤ 50ms 或 instant。

### 已知限制

- 菜单 screen reader（NVDA / Narrator passthrough）— 与 accessibility-requirements 全局一致，本屏不单独实现，记入项目级 Open Questions
- Count-up 动画对 vestibular 敏感的玩家可能不适 — reduced-motion 模式已完全关闭数字滚动，改为 instant display

---

## Localization Considerations

| 元素 | 中文最长 | 设计预留宽度 | 风险 / 备注 |
|---|---|---|---|
| Duration hero 文字 | "你离开了 23 小时 59 分钟" (12 字) | 全宽居中，不截断 | **中** — 英文 "You were away for 23 hours 59 minutes" ≈ 40 字符；德文更长；必须用 autowrap |
| 资源中文名（灵气/修为/灵石/药材/经验） | 2 字 | 4 字宽度 | 低 — 英文 "Spirit Qi" 已在范围 |
| Total gross 汇总条数字 | 可变（BigNumber 缩写如 "12.5K"） | 每项 80px 固定宽度 | 低 — NumberFormatter 已处理缩写 |
| Resource Breakdown 卡片标题（"总计产出:"等） | 4 字 | 8 字宽度 | **中** — 英文 "Total Gross:" / "Claimed:" / "Lost:" 各约 6–13 字符 |
| 来源拆解标签（"生产:"/"战斗:"/"探索:"） | 3–4 字 | 8 字宽度 | 低 — 英文 "Production:" / "Combat:" / "Exploration:" 约 8–12 字符 |
| 损失原因 tooltip（"药材仓库已满 (12/200)"） | ~16 字 | RichTextLabel 多行 autowrap | **HIGH** — 必须支持多行；翻译易超 30 字符 |
| "继续修炼" 按钮 | 4 字 | 12 字宽度 | 低 — 英文 "Continue Cultivation" ≈ 20 字符 |
| "延后查看" 按钮 | 4 字 | 8 字宽度 | 低 — 英文 "Review Later" ≈ 12 字符 |
| "离线战利品" 标题 + 数量 | "离线战利品 (99 件)" (9 字) | 20 字宽度 | 低 — 英文 "Offline Loot (99 items)" ≈ 22 字符 |
| 空状态文字 | "本次离线未获得物品" (9 字) | 全宽居中 | 低 |
| 物品名（来自 items.json） | ≤ 4 字（中文假设） | 4 字宽度 per 卡片 | **HIGH** — 英文物品名可能超 15 字符；卡片内必须 autowrap + 省略 |
| 稀有度角标（凡/精/稀/史/传/神/先/混） | 1 字 | 16×16 固定 frame | 低 — 单字符，所有语言一致 |
| 警告 banner | "所有仓库已满，离线收益全部损失。建议扩容后再离开。" (~24 字) | 全宽多行 | **HIGH** — 翻译必超长度；用 RichTextLabel + autowrap |

### HIGH PRIORITY 项（标记给 localization engineer）

- **Duration hero 文字** 必须用 `RichTextLabel` + `autowrap_mode = AUTOWRAP_WORD_SMART`，支持最少 2 行；预测试德/法/西翻译
- **损失原因 tooltip** 必须支持 ≥ 3 行 + 段落间距
- **物品卡片内物品名** 必须 autowrap + 超长省略（clip 或 "..."）
- **警告 banner** 必须支持多行 autowrap
- 来源拆解标签后的冒号（"生产:"）在翻译版中须保留分隔符

### 数字格式

所有 BigNumber 走 NumberFormatter；中文 / 短格式 / 科学格式由 settings 切换（参 hud-system §UI Requirements + ADR-0014）。

### Duration 格式化

Duration 格式化必须本地化：
- 中文："8 小时 23 分钟"（或 "23 分钟" / "45 秒"，按实际时长省略零值单位）
- 英文："8h 23m" 或 "8 hours 23 minutes"
- 最小粒度：秒（"45 秒" / "45s"）；不显示毫秒
- 时长 = 0 时显示："你刚刚离开，暂无离线收益" / "You were only gone a moment"

### 不需要本地化的元素

- 资源 PNG 图标（§2）— 视觉无文字
- rarity_frame PNG（§6）— 视觉无文字（文字角标由代码 overlay 并走本地化）
- 敌人 portrait（§11）— 视觉无文字
- offline_paper.png 背景（§9）— 视觉无文字

---

## Acceptance Criteria

按 `.claude/rules/design-docs.md` 标准；至少 5 条可测试、QA 可独立验证、不读其他文档可验证。共 14 条：

### 入口与导航

- [ ] **AC-1** 离线抽屉 "查看详情" 按钮 → 本屏在 120ms cross-fade 内完成打开，count-up 动画在打开后 200ms 内开始（reduced-motion 模式下 instant display）
- [ ] **AC-2** LEFT NAV "📅离线" tab 点击 / 数字键 `5` / 手柄 D-Pad 选第 5 项 + A，3 种入口都能正确开屏（screenshot 证据 ×3）
- [ ] **AC-3** "延后查看" 按钮回到 drawer 触发前玩家所在的屏（测试：从战斗屏触发 drawer → 查看详情 → 延后查看 → 应回到战斗屏；从修炼屏触发 → 应回到修炼屏）

### 数据显示

- [ ] **AC-4** Duration hero 显示时长与 `OfflineSettlementSummary.duration_seconds` 一致（容差 ± 1 秒）；格式化正确（时/分/秒递增，零值单位省略）
- [ ] **AC-5** Resource Breakdown 每张卡片的 gross / claimed / lost 数值与 `OfflineSettlementSummary` 完全一致（含 BigNumber 精度）
- [ ] **AC-6** 来源拆解（生产/战斗/探索）三项贡献值之和 = 总计产出（gross），容差 ≤ 0.01
- [ ] **AC-7** lost > 0 的资源卡片：lost 列 `bottleneck_red` 文字 + 行背景暗红 + 损失原因 tooltip 可读（hover 触发）；lost == 0 时损失行隐藏

### 战利品

- [ ] **AC-8** Loot Gallery 物品卡片与 `summary.loot_items[]` 一一对应；每卡片显示物品图标 + rarity_frame + 稀有度角标 + 物品名 + 数量；无掉落时显示空状态文字
- [ ] **AC-9** 物品卡片 rarity_frame 与物品稀有度匹配（凡→common_frame / 精→uncommon_frame / ... / 混→chaos_frame）

### 状态

- [ ] **AC-10** 离线时长 = 0 时（刚保存马上打开），显示空状态："你刚刚离开，暂无离线收益"；不播放 count-up 动画；Resource Breakdown 和 Loot Gallery 隐藏
- [ ] **AC-11** 所有资源 lost == gross 时（极端满仓），警告 banner 显示且可读；所有资源卡片红色高亮

### Accessibility（Standard tier 强制）

- [ ] **AC-12** 键盘 Tab 顺序覆盖所有交互元素（"延后查看" → 各资源损失 tooltip → 各物品卡片 → "继续修炼"）；每个焦点显示 2px `burst_gold` 描边
- [ ] **AC-13** UI 缩放 75% / 100% / 150% 三档 + 1280×720 最小窗口下，布局不破、文字不裁切、ScrollContainer 正常滚动、所有交互仍可达
- [ ] **AC-14** reduced-motion 开启时，count-up 动画完全关闭（数字直接显示最终值），所有 transition ≤ 50ms 或 instant

### 资产覆盖（Sprint 11 DoD §15）

- [ ] **AC-15** 本屏挂载 **5+3 个资产族**：§9 offline_paper.png（全屏背景 9-slice）+ §2 全 5 资源图标（DURATION HERO + Resource Breakdown）+ §6 rarity_frame 全覆盖（Loot Gallery 物品卡片，根据稀有度动态加载）+ §11 敌人 portrait（有战斗数据时显示）+ §1 theme.tres（强制全树继承）+ §5 offline_pending（LEFT NAV 角标，由 UIManager 控制但本屏入口影响其可见性）— 通过 `production/qa/evidence/sprint-11/offline-settlement-screen-asset-snap.png` 截图证明全部可见

---

## Open Questions

| Question | Owner | Deadline | Resolution |
|---|---|---|---|
| `OfflineSettlementSummary.loot_items[]` 中物品稀有度字段名是 `rarity` 还是 `quality`？需与 loot-system GDD / items.json 对齐 | game-designer + ui-programmer | Sprint 11 dev | 未解决 — 倾向：`rarity`（与 art-bible Sec 4.3 命名一致） |
| `summary.enemies_encountered[]` 是否在 MVP OfflineSettlementSummary 中？离线战斗模拟系统 GDD 未明确是否输出此字段 | game-designer | Sprint 11 dev | 未解决 — 如无此字段，敌人 portrait 行在 MVP 中隐藏，后续 sprint 补 |
| 玩家从 drawer 进入本屏后，drawer 是否保持打开（作为背景 overlay），还是自动关闭？倾向：drawer 自动关闭（drawer 是瞬时 overlay；进入全屏结算后不需要 drawer 背景） | ux-designer | Sprint 11 dev | 未解决 — 等待与 drawer story S11-008 联调时确认 |
| LEFT NAV offline_pending 角标熄灭逻辑：用新增事件 `offline.settlement.viewed`，还是 UIManager 内部逻辑（`if opened_screen == "offline_settlement" → clear_badge`）？倾向：MVP 用 UIManager 内部逻辑（简单），post-MVP 加事件供 analytics 追踪 | ux-designer + ui-programmer | Sprint 11 dev | 未解决 |
| Count-up 动画的 stagger 时序（每行 +100ms）和总时长（1.5s）是否需要 Settings 可调？倾向：MVP 硬编码，post-MVP 加 Settings 滑块"动画速度: 标准 | 快速 | 关闭" | ux-designer | Sprint 11 polish | 未解决 |
| "探索" 来源列在 MVP 中始终显示 "—" —— 是否应该完全隐藏该列（而非灰字占位）？倾向：保留灰字占位（给玩家"未来还有"的预告感，类似 cultivation screen stance modal 的 locked stance 置灰） | ux-designer | Sprint 11 dev | 未解决 |
| 离线结算屏是否应保留在 ScreenStack 中（返回时通过 LEFT NAV），还是看完后从 stack 中 pop？倾向：保留在 stack 中（玩家可通过 LEFT NAV 随时回看上次结算数据） | ux-designer + ui-programmer | Sprint 11 dev | 未解决 |
| `design/player-journey.md` 缺失 — 离线结算屏在玩家"每次回归"的体验节奏需要 journey 文档支撑；drawer vs full screen 的推送策略也依赖 journey 上下文 | producer + ux-designer | Sprint 11 启动前 | 未解决 — 建议 sprint-11 立项前补 player-journey.md mini 版本 |
| 离线时长显示精度：是否需要在 ≥ 24 小时时显示天数（"1 天 3 小时" vs "27 小时"）？倾向：≥ 24 小时显示天数，格式 "X 天 YY 小时 ZZ 分钟" | ux-designer | Sprint 11 dev | 未解决 |
| 物品卡片在 LOOT GALLERY 中的点击行为：MVP 是否需要有"点击查看物品详情"？倾向：MVP 仅 hover tooltip，click 无行为（预留 post-MVP 物品详情屏跳转） | ux-designer + game-designer | Sprint 11 dev | 未解决 |
