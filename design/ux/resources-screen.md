# UX Spec: 资源/背包屏 (Resources & Backpack Screen)

> **Status**: Draft
> **Author**: binlee1990 + ux-designer
> **Last Updated**: 2026-05-05
> **Journey Phase(s)**: Early Game 全程 — 玩家首次获得掉落物后自然产生"查看库存"需求；与修炼屏形成"产出→库存"互补关系
> **Platform Target**: PC (Steam/Epic) — Keyboard/Mouse + Gamepad Partial
> **Template**: UX Spec
> **Sprint**: Sprint 11 / mvp-screens / S11-011
> **Asset Manifest 引用**: §2 全 5 资源图标 · §6 全 8 稀有度框 (rarity_frame) · §12 全 13 物品图标 (item icons) · §5 overflow_warn 状态图标 · §13 overflow_warn_flash VFX

---

## Purpose & Player Need

资源/背包屏是玩家的"仓库账本 + 背包清点"合一屏。HUD 顶栏回答"我现在有多少"——本屏回答**"我的库存发生了什么 / 我捡到了什么 / 我还剩多少空间"**。

### 核心玩家目标

1. **看清资源全貌** — 5 资源的当前值 / 上限 / 填充率 / 每秒产出速率，全部在一个面板中一览无余。HUD 顶栏只显示缩略数字，本屏给**完整精度**。
2. **追溯资源变动** — 展开任一资源行，查看"近一小时变动明细"：来源（挂机产出 / 战斗掉落 / 手动修炼 / 离线结算 / 宗门税收）+ 每笔变动量。玩家不再疑惑"数字怎么少了/多了"。
3. **清点背包战利品** — 物品库存以卡片网格展示：图标 + 名称 + 稀有度边框 + 堆叠数量。玩家挂机回来第一件事就是来背包看"掉了什么好东西"。
4. **感知容量压力** — 有上限资源（灵气 / 药材）的 fill bar 在 ≥85% 时红闪警示，玩家提前决策"消耗还是扩容"。
5. **预览 Loot Filter 入口** — "图鉴" tab 作为 Loot Filter 占位，告知玩家"未来可以自定义掉落过滤"。

### Sentence form

> "The player arrives at this screen wanting to **audit** their resource stock, **inspect** recent inflows/outflows, and **browse** their backpack loot — all with the trust that every number has a traceable source."

### 反向定义（这里不做什么）

- 不重复修炼屏的"产出速率来源拆解"（base/姿态/等级/境界/修正器拆解属于修炼屏 DECISION ZONE）
- 不提供资源消耗 / 使用的操作入口（修炼 / 战斗消耗不走本屏）
- 不做装备详情 / 词条对比 / 物品拆分（Alpha 阶段装备系统 GDD 负责）
- 不做 Loot Filter 实际编辑器（仅占位 tab，Sprint 12+ 实现）
- 不做物品出售 / 分解 / 合成操作（Alpha 阶段经济/合成系统 GDD 负责）

### 与修炼屏的互补关系

| 维度 | 修炼屏 (Cultivation) | 资源屏 (Resources) |
|------|---------------------|-------------------|
| 核心问题 | "为什么是这个数字 / 怎么能更高" | "库存发生了什么 / 我捡到了什么" |
| 资源展示 | 每秒产出 + 来源拆解（base/姿态/等级/境界/修正器） | 当前值/上限/填充率 + 近一小时变动追溯 |
| 情绪 | calm + curious（安静看自己变强） | audit + inventory satisfaction（清点战利品的收获感） |
| 操作 | 切换姿态 / 手动修炼 / 试算 | 查看明细 / 浏览背包 / Tooltip 检视物品 |

### Pillar 锚定

- **4.1 数字增长就是快乐** — 资源数字的全精度展示 + 变动追溯让"增长"有据可查；背包里每一个物品卡片都是成长的具象化
- **4.2 放置 = 低频高价值决策** — 容量警告把"数字增长"翻译为"扩容 or 消耗"的决策提示，不做秒级操作催促
- **4.4 城镇宗门是后勤系统** — 上限展示为宗门/仓储升级提供反馈闭环："升级聚灵阵 → 容量扩大 → 不再溢出"
- **4.6 渐进叙事** — 8 阶稀有度边框 + 物品图标本身是世界观的最小笔触；"图鉴" tab 预告未来内容

---

## Player Context on Arrival

| 维度 | 答案 |
|------|------|
| **何时首次遇到** | 新玩家：完成第一次战斗掉落后，HUD 出现"📦 获得物品"提示 → 玩家点 LEFT NAV "📦资源" tab 或按数字键 `3` 进入。老玩家：挂机回来第一站 — 先看灵气有没有满、再看背包掉了什么 |
| **之前在做什么** | **新玩家**：刚打完第一场战斗（或刚完成新手引导修炼），看到 HUD 状态点闪烁提示有新物品；**老玩家**：从离线结算 drawer 关闭后过来、从修炼屏切过来、或从战斗屏打完一波怪过来"验货" |
| **情绪状态（设计假设）** | **audit + inventory satisfaction** — 不是战斗的肾上腺素，不是修炼的禅静；是"打开背包看看捡到了什么"的期待感和"确认数字没算错"的审计安全感。锚点：resource-system Player Fantasy "账本般的确定性" |
| **主动 vs 被动** | **主动** — 玩家不会被动推到本屏（修炼屏是默认首屏）；来本屏都是"我想看看库存/背包" |

### 派生设计含义（约束 Layout 与 Transitions）

- **No onboarding overlay**：本屏不做新手引导浮层（修炼屏的手动修炼呼吸光晕已承担 onboarding 暗示）
- **第一眼焦点**：因为玩家是主动来"验货" → 默认焦点在**第一个资源行**（灵气），Tab 顺序自然向下
- **离开时无确认**：本屏无不可逆操作（纯查看），切到其他屏不需要"确定要离开吗"
- **背包空状态特殊处理**：首次进入背包 tab 时，若物品数为 0，显示引导文案"暂无物品 —— 前往战斗获取掉落"，提供方向但不强制

---

## Navigation Position

资源屏位于 **Root → ScreenStack → Resources Screen**（LEFT NAV "📦资源" tab，第 3 位）。与修炼屏、战斗屏平级切换；无独占父屏，也不通向任何子屏。

### 替代入口

| 入口源 | 触发方式 |
|--------|---------|
| LEFT NAV "📦资源" tab | 鼠标点击 / 键盘 ↑↓ + Enter / 手柄 D-Pad ↑↓ + A |
| 全局快捷键 `3` | 数字键 1–5 直达 5 主区域，资源 = `3` |
| HUD 顶栏资源数字点击 | 点击任意资源数字（灵气的 "1.2K"）→ `open_screen("resources")` 且自动滚动到对应资源行 |
| 离线结算 drawer "查看详情" 按钮 | drawer 底部 "📊 查看完整资源账本" → `open_screen("resources")` |
| 调试控制台 `goto resources` | dev only；release 构建排除（ADR-0012） |

### 不能从这里到达的地方

资源屏**不通向**任何子屏（无层级深度）。所有详情通过 P-DAT-01-EXP 展开（资源变动明细）或 P-INP-01 Tooltip（物品详情）在本屏内呈现，不走 modal 或子屏。唯一例外：未来"图鉴" tab 实现 Loot Filter 编辑器时可能触发 P-NAV-03 Modal。

---

## Entry & Exit Points

### Entry

| Entry Source | Trigger | Player carries this context |
|---|---|---|
| LEFT NAV tap | Click "📦资源" / Press `3` / D-Pad 选第 3 项 + A | 当前游戏状态 |
| HUD 顶栏资源数字 click | 点击灵气/修为/灵石/药材/经验任一数字 | 当前游戏状态；自动滚动到被点击的资源行 |
| Offline drawer "查看详情" | drawer 底部按钮点击 | `offline.settled` 已处理；drawer 关闭后开本屏 |
| Debug `goto resources` | dev only | — |

### Exit

| Exit Destination | Trigger | Notes |
|---|---|---|
| Cultivation screen | LEFT NAV "📊修炼" / Press `1` | — |
| Combat screen | LEFT NAV "⚔战斗" / Press `2` | — |
| Save screen | LEFT NAV / Press `4` | — |
| Offline drawer | `offline.settled` 事件触发后玩家点 "📦 N" 角标 | 浮层 — 关闭后回本屏 |
| App quit | 系统关闭 | 触发 SaveManager auto-save |

无一次性出口；所有 exit 可通过 LEFT NAV 返回，无不可逆状态。

---

## Layout Specification

### Information Hierarchy

按 art-bible 第 2 原则"决策优先级 = 视觉亮度"映射，从最高到最低：

1. **Hero Tier**（屏幕顶部，立即可见）— 容量警告
   - 有上限资源的 fill bar ≥ 85% 时：bottleneck_red + "⚠" 字符 + 资源行背景微红
2. **Decision Tier**（屏幕上半，玩家审计时聚焦）— 5 资源全量明细
   - 每行：图标 + 名称 + 当前值/上限 + fill bar + 每秒产出速率
   - 展开态：近一小时变动明细（来源 + 变动量 + 时间戳）
3. **Inspection Tier**（屏幕下半，玩家浏览时用）— 物品库存网格
   - 4 列 × N 行 P-DAT-04 Item Card（图标 + 名称 + 稀有度边框 + 堆叠数量）
   - 每卡 hover / 焦点时触发 P-INP-01 Tooltip 显示完整物品详情
4. **Preview Tier**（Tab 栏第三位）— 图鉴 / Loot Filter 占位
   - "Loot Filter — Sprint 12+ 开放" 文字 + 锁图标
5. **Ambient Tier**（背景，不参与交互）
   - theme.tres `panel_bg_primary` 纯色底（本屏无全屏背景图 — 数据密度高，背景图干扰可读性）

### Layout Zones

资源屏占 **HUD 的 CENTER CONTENT 区**（hud.md §Layout Zones 第 3 行），即去除 TOP STRIP 64px / LEFT NAV 192px / RIGHT PANEL 320px / BOTTOM ACTION BAR 之后的区域。

@ 1080p 基线：CENTER CONTENT 可用区域 ≈ **1408 × 1016 px**。

| Zone | 位置 | 尺寸 @ 1080p | 内容 |
|---|---|---|---|
| **TAB BAR** | 内容区顶部 | 1408 × 48 px | 3 tab：资源 / 背包 / 图鉴（P-NAV-01 Top-Tab） |
| **RESOURCE LIST** | TAB BAR 下方 | 1408 × 968 px | 5 资源行（P-DAT-01-EXP），每行可展开变动明细 |
| **INVENTORY GRID** | TAB BAR 下方（背包 tab 选中时） | 1408 × 968 px | 4 列虚拟化物品卡片网格（P-DAT-02 + P-DAT-04） |
| **ENCYCLOPEDIA PLACEHOLDER** | TAB BAR 下方（图鉴 tab 选中时） | 1408 × 968 px | 占位内容：锁图标 + "Loot Filter — Sprint 12+ 开放" |

### 屏幕安全区

- 1280×720 最小窗口：RESOURCE LIST 行高从 32px 缩至 28px；INVENTORY GRID 从 4 列缩至 3 列；卡片从 96×128 缩至 80×108
- 4K：等比缩放 + 字号 +1 档（20px → 24px）；INVENTORY GRID 扩展至 6 列
- Steam Deck 1280×800：LEFT NAV 折叠 48px；TAB BAR 全宽保持

### Component Inventory

按 zone 分组；每行标注：组件类型 / 内容 / 是否交互 / 引用 pattern 或新组件。

#### TAB BAR

| Component | Type | Content | Interactive | Pattern |
|---|---|---|---|---|
| Tab "资源" | Button (Tab) | "📊 资源" + 图标 | Yes（切换 tab） | P-NAV-01 Top-Tab |
| Tab "背包" | Button (Tab) | "🎒 背包" + 图标 + 物品总数徽章 | Yes（切换 tab） | P-NAV-01 Top-Tab |
| Tab "图鉴" | Button (Tab, locked) | "🔍 图鉴" + 锁图标（饱和度 −60%） | Yes（hover tooltip "Sprint 12+ 开放"） | P-NAV-01 Top-Tab (locked) |

#### RESOURCE LIST（Tab: 资源）

| Component | Type | Content | Interactive | Pattern |
|---|---|---|---|---|
| Resource Row × 5 | 自定义（P-DAT-01-EXP） | 收起态：24×24 图标 + 名称 + "current / cap" + 4px fill bar + 每秒产出速率 + ▲/▼ 趋势；展开态：收起态全部 + 近一小时变动明细列表（每行：来源名称 + 变动量 + 相对时间） | Yes（点行展开/收起 + 行级 tooltip） | P-DAT-01-EXP（扩展变体 — 展开内容为变动明细而非来源拆解） |
| Cap Warning Overlay | P-FBK-02 Inline Status Chip + ProgressBar 颜色切换 | fill_ratio ≥ 0.85 → fill bar 切 `bottleneck_red` + 数字右侧 "⚠" 字符 + 行背景微红 8% alpha | No（状态驱动显示） | P-FBK-02 + storage-limit-system `get_capacity_state()` |
| Capacity Pressure Chip | P-FBK-02 Inline Status Chip | fill_ratio ≥ 1.0（满仓）→ "已满 ⚠" chip + 每秒产出数字变灰 "(溢出)" | No（状态驱动显示） | P-FBK-02 |

#### INVENTORY GRID（Tab: 背包）

| Component | Type | Content | Interactive | Pattern |
|---|---|---|---|---|
| Item Card × N | 自定义（P-DAT-04 网格变体） | 48×48 图标 + 名称（14px）+ 稀有度边框（8 阶 9-slice）+ 右上角稀有度文字角标（"凡/精/稀/史/传/神/先/混"）+ 右下角堆叠数量 | Yes（hover/focus 显示 P-INP-01 Tooltip） | P-DAT-04 Item Card（网格态 96×128） |
| Virtualized ScrollContainer | ScrollContainer + P-DAT-02 | 仅渲染可视行 + 4 行 overscan；右侧 6px 滚动条 | Yes（滚轮 / PgUp/PgDn / 手柄右摇杆） | P-DAT-02 Virtualized List |
| Empty Inventory Placeholder | TextureRect + Label | 占位插画 + "暂无物品 —— 前往战斗获取掉落" | No | P-DAT-EMPTY 模板 |
| Item Detail Tooltip | P-INP-01 Tooltip | 物品图标（大）+ 名称 + 稀有度文字 + 描述 + tags 标签列表 + 堆叠上限信息 | No（hover/focus 触发） | P-INP-01 Tooltip |

#### ENCYCLOPEDIA PLACEHOLDER（Tab: 图鉴）

| Component | Type | Content | Interactive |
|---|---|---|---|
| Locked placeholder | TextureRect + Label | 锁图标 + "Loot Filter — Sprint 12+ 开放" + 副标题 "自定义掉落筛选规则" | hover tooltip 仅 |

#### 组件总数

8 个交互元素 + 6 个静态显示 + 1 个 tooltip 浮层 = 共 15 个 UI components。

### ASCII Wireframe

```
┌── HUD TOP STRIP (64px, 固定) ───────────────────────────────────────────┐
│ ⛬ 1.2K ◯ 850K ◇ 12.5M ❀ 234K ⚡ 1.2K │  Lv.1 凡人  │  📊修炼 ▼  │  ⚙ │
├──────┬───────────────────────────────────────────────────┬─────────────┤
│LEFT  │  ┌─────────────────────────────────────────────┐  │ RIGHT PANEL │
│NAV   │  │ TAB BAR (1408×48)                           │  │             │
│192px │  │ [📊 资源]  [🎒 背包(13)]  [🔍 图鉴 🔒]     │  │ 战斗日志 ▼  │
│      │  ├─────────────────────────────────────────────┤  │ ┌─────────┐ │
│📊修炼│  │ RESOURCE LIST (1408×968)                     │  │ │ 17:32   │ │
│⚔战斗│  │                                              │  │ │  普攻   │ │
│📦资源│  │ ┌──────────────────────────────────────┐    │  │ │  暴击!  │ │
│💾存档│  │ │ ⛬ 灵气   8,500 / 10,000  ████▌ 85%  │    │  │ │   ...   │ │
│📅离线│  │ │           +3.2/s  ▲          ⚠      │    │  │ │  ▼ jump │ │
│      │  │ │  ▶ 近一小时变动                     │    │  │ └─────────┘ │
│      │  │ │     挂机产出  +12,340    52 分钟前   │    │  │             │
│      │  │ │     手动修炼  +150       31 分钟前   │    │  │ ─────       │
│      │  │ │     离线结算  +8,200     28 分钟前   │    │  │ [警告 chips] │
│      │  │ │     战斗掉落  +50        15 分钟前   │    │  │             │
│      │  │ │     凝练消耗  -960       10 分钟前   │    │  │             │
│      │  │ ├──────────────────────────────────────┤    │  │             │
│      │  │ │ ◯ 修为   850,000 / ∞     ████░ ...  │    │  │             │
│      │  │ │           +0.8/s  ▲                  │    │  │             │
│      │  │ ├──────────────────────────────────────┤    │  │             │
│      │  │ │ ◇ 灵石   12,500,000 / ∞  ████░ ...  │    │  │             │
│      │  │ │           +0.1/s  ▲                  │    │  │             │
│      │  │ ├──────────────────────────────────────┤    │  │             │
│      │  │ │ ❀ 药材   180 / 200       █████ 90%  │    │  │             │
│      │  │ │           +0.0/s  —          ⚠      │    │  │             │
│      │  │ ├──────────────────────────────────────┤    │  │             │
│      │  │ │ ⚡ 经验   5,300 / ∞       ████░ ...  │    │  │             │
│      │  │ │           — (战斗获取)               │    │  │             │
│      │  │ └──────────────────────────────────────┘    │  │             │
│      │  │                                              │  │             │
│      │  │ ═══ TAB 切换至 "背包" ═══════════════════   │  │             │
│      │  │                                              │  │             │
│      │  │ INVENTORY GRID (1408×968)                    │  │             │
│      │  │ ┌──────┐ ┌──────┐ ┌──────┐ ┌──────┐        │  │             │
│      │  │ │灵草  │ │血参  │ │灵石  │ │矿石  │        │  │             │
│      │  │ │      │ │      │ │(低)  │ │      │        │  │             │
│      │  │ │ [凡] │ │ [精] │ │ [凡] │ │ [稀] │        │  │             │
│      │  │ │ ×234 │ │  ×5  │ │ ×47  │ │ ×12  │        │  │             │
│      │  │ └──────┘ └──────┘ └──────┘ └──────┘        │  │             │
│      │  │ ┌──────┐ ┌──────┐ ┌──────┐ ┌──────┐        │  │             │
│      │  │ │龙鳞  │ │珍珠  │ │符纸  │ │丹药  │        │  │             │
│      │  │ │      │ │      │ │      │ │(低)  │        │  │             │
│      │  │ │ [史] │ │ [传] │ │ [精] │ │ [凡] │        │  │             │
│      │  │ │  ×2  │ │  ×1  │ │ ×30  │ │ ×18  │        │  │             │
│      │  │ └──────┘ └──────┘ └──────┘ └──────┘        │  │             │
│      │  │  ... (虚拟化滚动，仅渲染可视行)               │  │             │
│      │  │                                              │  │             │
│      │  │ ═══ TAB 切换至 "图鉴" ═══════════════════   │  │             │
│      │  │                                              │  │             │
│      │  │        🔒                                  │  │             │
│      │  │   Loot Filter — Sprint 12+ 开放              │  │             │
│      │  │   自定义掉落筛选规则                          │  │             │
│      │  │                                              │  │             │
│      │  └──────────────────────────────────────────────┘  │             │
└──────┴───────────────────────────────────────────────────┴─────────────┘
```

> **Wireframe 注**：本 wireframe 展示 1080p 默认布局，"资源" tab 选中状态。5 个资源行中灵气行处于展开态（显示近一小时变动明细），其余行处于收起态。切换至"背包" tab 时 RESOURCE LIST 区域替换为 INVENTORY GRID。实际像素位由 art-director 在 Sprint 11 mvp-screens 实现期间结合 theme.tres 微调。资源行之间间隔 4px（ink_stroke 分隔线）。

---

## States & Variants

| State / Variant | Trigger | What Changes |
|---|---|---|
| **Default (资源 tab)** | 进入本屏 / 点击"资源" tab | 5 资源行全部收起；聚焦第 1 行（灵气） |
| **Resource Row Expanded** | 点击单行 / 键盘 Enter / 手柄 A | 该行 200ms 展开显示变动明细；其他行自动收起（手风琴模式） |
| **Cap Warning (fill ≥ 85%)** | `StorageLimitSystem.get_capacity_state(id).state == "warning"` | fill bar 切 `bottleneck_red`；数字右侧 "⚠" 出现；行背景 8% 红 alpha |
| **Cap Full (fill == 100%)** | `StorageLimitSystem.get_capacity_state(id).state == "full"` | fill bar 满红；"已满 ⚠" chip 出现；每秒产出数字变灰 "(溢出)" |
| **背包 tab — 有物品** | 物品库存 > 0 | 4 列卡片网格正常显示；每卡含 icon + name + rarity frame + count |
| **背包 tab — 空库存** | 物品库存 == 0 | 占位插画 + "暂无物品 —— 前往战斗获取掉落"；网格区隐藏 |
| **图鉴 tab — 锁定** | 点击"图鉴" tab | 锁图标 + 占位文案；hover 显示 tooltip "Sprint 12+ 开放" |
| **Loading (cold start)** | 0–500ms 在 ResourceSystem / ItemRegistry 首个 snapshot 就绪前 | 资源行数值显示 "..." 占位；背包 tab 显示 "加载中..." |
| **Time Frozen** | `TimeManager.frozen == true` | 所有资源行每秒产出速率追加 "(已冻结)" 灰字；趋势箭头隐藏 |
| **玩家从未获得物品** | 新存档 + 从未战斗/掉落 | 背包 tab 空状态含额外文字 "战斗击败敌人可获取灵草、矿石等材料"（比"已玩过但消耗光"多一行方向指引） |

---

## Interaction Map

输入方法：键鼠（Primary）+ 手柄 partial（D-Pad / A / B / X / Y / LB / RB）。无 touch（technical-preferences `Touch Support: None`）。

| Action | Mouse / Keyboard | Gamepad | 即时反馈 | 结果 |
|---|---|---|---|---|
| 切换 Tab（资源/背包/图鉴） | Click tab / ←→ 键 + Enter | LB / RB 直接切换 | 120ms cross-fade tab 内容 | UI only — 切换内容区；不发事件 |
| 展开 / 收起单资源变动明细 | Click 行 / Tab + Enter | A 键 | 200ms 高度 expand 动画 | UI only — 不发事件（手风琴模式） |
| 滚动资源列表 | 滚轮 / PgUp/PgDn | 右摇杆 ↑↓ | 即时滚动 | UI only |
| Hover 资源行查看趋势 tooltip | Mouse hover ≥ 0.3s | 焦点 ≥ 0.5s | tooltip fade-in 150ms | P-INP-01 — 显示"30 分钟趋势：+12.3K 灵气" |
| 滚动物品网格 | 滚轮 / PgUp/PgDn | 右摇杆 ↑↓ | 即时 + P-DAT-02 虚拟化回收/创建行 | UI only |
| 检视物品详情（Tooltip） | Mouse hover 物品卡 ≥ 0.3s | 焦点物品卡 + A 键 | tooltip fade-in 150ms | P-INP-01 — 显示 name / rarity / description / tags / stack_limit |
| 点击物品卡 | Click / Enter | A 键 | 微闪（100ms `panel_bg_elevated` 高亮） | UI only — MVP 无物品详情子屏（Alpha 装备系统补） |
| 从 HUD 顶栏资源数字跳入 | Click 顶栏资源数字 | — | 开屏 + 自动滚动定位 | `open_screen("resources")` + 参数 `{focus_resource: "lingqi"}` |
| 关闭本屏（去其他主屏） | Click LEFT NAV / 数字 1–5 | LB / RB 切 tab | 120ms cross-fade | `UIManager.open_screen(...)` |

### Tab Order（accessibility-requirements Standard tier 强制）

Tab "资源" → Tab "背包" → Tab "图鉴" → Resource Row 1 → Resource Row 2 → Resource Row 3 → Resource Row 4 → Resource Row 5 →（若在"背包" tab）Item Card 1 → Item Card 2 → ... → 虚拟化回收/创建后重排。共 ≥ 8 项可达交互（资源 tab 下 3 tab + 5 行 = 8 项；背包 tab 下 3 tab + N 张可见卡片）。

---

## Events Fired

| Player Action | Event Fired | Payload |
|---|---|---|
| 进入本屏 | `ui.screen_opened`（UIManager 自动发，本屏不重发） | `{screen_id: "resources"}` |
| 离开本屏 | `ui.screen_closed`（UIManager 自动发） | `{screen_id: "resources"}` |
| 资源数值刷新（被动接收） | `resource.{id}.changed`（ResourceSystem 发，本屏订阅） | `{resource_id, old_value, new_value, delta}` |
| 资源上限变化（被动接收） | `resource.{id}.cap_changed`（ResourceSystem 发，本屏订阅） | `{resource_id, old_cap, new_cap}` |
| 资源溢出（被动接收） | `resource.{id}.overflow`（ResourceSystem 发，本屏订阅） | `{resource_id, attempted, actual_added, lost}` |
| 资源行展开 / 收起 | **无事件** — 纯 UI 状态 | — |
| Tab 切换 | **无事件** — 纯 UI 状态 | — |
| 物品 Tooltip 显示 | **无事件** — 纯 UI 状态 | — |

### 架构标记

- 本屏**只订阅不发布**（除 UIManager 自动发的 `screen_opened/closed`）。所有资源数据刷新走 EventBus 订阅；所有物品 metadata 走 ItemRegistry 同步查询。
- 本屏**不写**任何持久状态。所有数据读取走 host getter；无 command 操作（纯查看屏）。
- `resource.{id}.overflow` 事件到达时，对应资源行的 fill bar 触发 `overflow_warn_flash` VFX（300ms），并在 RIGHT PANEL 警告区显示"灵气溢出：损失 1,700 万"。

---

## Transitions & Animations

| Trigger | Animation | Duration | Reduced-motion 替代 |
|---|---|---|---|
| 屏幕进入（LEFT NAV 切入 / HUD 资源数字跳入） | cross-fade | 120ms（ui-framework `default_transition_ms`） | instant cut |
| 屏幕退出 | cross-fade out | 120ms | instant cut |
| Tab 切换 | cross-fade 内容区 | 120ms | instant cut |
| 资源行展开 | 高度 expand + 变动明细 fade-in | 200ms | instant |
| 资源行收起 | 高度 collapse + 内容 fade-out | 150ms | instant |
| 容量警告出现（fill ≥ 85%） | fill bar 颜色渐变为 `bottleneck_red` + "⚠" fade-in | 300ms | instant 静态红 + 静态 "⚠" |
| 满仓 chip 出现（fill ≥ 100%） | `overflow_warn_flash.png` VFX 单帧扩散 | 300ms | 静态暗红边框 |
| 资源数值刷新 | 数字瞬间跳变（无 tween — 保持"账本"的精确感） | 0ms | 同 |
| 物品 Tooltip 进入 | fade-in | 150ms | instant |
| 物品 Tooltip 退出 | fade-out | 100ms | instant |
| 物品卡 hover 高亮 | `panel_bg_elevated` 微亮 | 100ms | instant |
| 空库存占位出现 / 消失 | fade-in / fade-out | 200ms | instant |
| 时间冻结进入 | 资源行产出速率灰度 fade 50% | 300ms | instant 灰度 |
| 时间解冻 | 灰度恢复 | 300ms | instant |

### 禁区

- 本屏**不**触发 `burst_gold` 全屏印章（突破/飞升专用）
- 本屏**不**触发 `victory_burst_gold`（战斗专用）
- 本屏**不**触发 `failure_red` / `failure_grey`（战斗失败专用）
- 本屏**不**做数字滚动 tween（资源数值跳变体现"账本"精确感，不做 slot-machine 式滚动）

---

## Data Requirements

| Data | Source System | R/W | Notes |
|---|---|---|---|
| `lingqi/xiuwei/lingshi/herb/exp` 当前值 | `ResourceSystem.get_value(id)` | Read | 高频读 — coalesce 至 ≤ 10Hz（同 HUD `hud_refresh_interval`） |
| `lingqi/herb` 上限值 | `ResourceSystem.get_max(id)` | Read | `xiuwei/lingshi/exp` 无上限（has_cap=false），显示 "∞" |
| 填充率 & 容量状态 | `StorageLimitSystem.get_capacity_state(id)` | Read | 返回 `{current, cap, fill_ratio, state}`；state 驱动 UI 状态切换 |
| 每秒产出速率 | `OutputMultiplierSystem.get_tick_amount(resource_id, 1.0)` | Read | 沿用 HUD 已有的 coalesced 读；经验显示 "战斗获取" 而非速率 |
| 近一小时变动明细 | **新 API**：`ResourceSystem.get_recent_history(id, seconds: float = 3600.0) → Array[Dictionary]` | Read | 返回 `[{source: String, delta: BigNumber, timestamp: float}, ...]`。**本屏最大架构需求**：若 ResourceSystem 不记录变动历史，本屏需 ADR 决议此 API；降级方案为"展开区显示现有 data sources 静态列表（非历史明细）" |
| 物品 inventory 列表 | **新 API**：`ResourceSystem.get_inventory_snapshot() → Dictionary` 或通过 ItemRegistry + ResourceSystem 联合查询 | Read | 遍历 `get_all_ids()`，过滤 `category="material"` 且 `current > ZERO` 的条目，联合 ItemRegistry 取 metadata |
| 物品 metadata（name/icon_path/rarity/tags/stackable/stack_limit） | `ItemRegistry.get(id)` / `ItemRegistry.peek_field(id, field)` | Read | 背包网格渲染时高频调用；应在 `item_registry.loaded` 事件后批量缓存（避免每帧 `get()` 的深拷贝开销） |
| 物品堆叠数量 | `ResourceSystem.get_value(id)` — material 类资源 | Read | 同质化材料数量即资源当前值；注意：`stackable=false` 的物品走 item 实例系统（Alpha），MVP 全部 stackable=true |
| 玩家从未获得物品标记 | `ResourceSystem` 所有 material current 总和 == 0 且战斗系统 `total_combats == 0` | Read | 用于区分空库存的两种原因（"从没打过" vs "用光了"） |
| TimeManager.frozen 状态 | `TimeManager.is_frozen()` — 建议补简易 getter | Read | 用于 Time Frozen state |

### 架构关注（ADR 评估）

本屏对 ResourceSystem 提出 **1 个新 API**（`get_recent_history`）用于展开态的变动明细。若 ResourceSystem MVP 不记录变动历史：

- **降级方案 A**：展开区显示"变动明细暂不可用 —— 该功能将在后续版本开放"（`text_secondary` 斜体），保留 UI 框架但无数据。**风险**：阉割本屏 30% 价值。
- **降级方案 B**：展开区显示**实时静态来源列表**（非历史明细），列出当前 resource 的所有已知来源系统（挂机产出 / 战斗掉落 / 手动修炼 / 离线结算 / 宗门税收）+ 各自当前倍率。虽不如历史追溯完整，但仍有"来源透明"价值。

倾向：MVP 优先走降级方案 B（零新 API 成本），历史明细 API 留 Sprint 12+。

---

## Accessibility

继承 `design/accessibility-requirements.md` Standard tier。本屏特化条款：

### 视觉

- 资源行名称 ≥ 20px；当前值数字 ≥ 24px（P0 数据）；上限后缀 ≥ 18px；变动明细行 ≥ 16px
- 所有可交互文本与背景对比 ≥ 4.5:1（theme.tres `text_primary` on `panel_bg_primary` ≈ 9:1 已满足）
- 容量警告：色（`bottleneck_red`）+ 文字 "⚠" 字符 + fill bar 形状变化三重 backup
- 8 阶稀有度边框：色（8 阶色阶）+ 形状（art-bible Sec 3.4 破框）+ 文字角标（"凡/精/稀/史/传/神/先/混"）三重 backup — art-bible Sec 4.6 色弱矩阵全覆盖
- 趋势箭头 ▲/▼：形状本身传达方向，不依赖绿色/红色
- UI 缩放 75% / 90% / 100% / 125% / 150% 五档下布局不破，文字不裁切，物品卡片等比缩放
- 物品卡片文字角标在缩放下保持可读（最小 10px）

### 键鼠 / 手柄等价

- Tab order 见 §Interaction Map（≥ 8 项可达交互）
- 当前焦点元素加 2px `burst_gold` 描边（与 hud.md 对齐）
- 资源行焦点态：左侧 2px `burst_gold` 竖条 + `panel_bg_elevated` 底
- 物品卡片焦点态：`burst_gold` 1px 边框 + 卡片微放大 105%
- 物品网格支持 D-Pad 四向导航（↑↓←→ 移动焦点卡片）
- 图鉴 tab（锁定）：可聚焦 + tooltip 可触发

### 时间相关

- **No timed input**：本屏无任何计时操作
- 变动明细的"X 分钟前"时间戳是相对时间显示（不要求玩家在时限内操作）

### 动作 / 体力

- 所有可交互 hit area ≥ 32 × 32 px（资源行）/ 48 × 48 px（物品卡片）/ 32 × 32 px（tab）
- 虚拟化滚动不要求快速滚动操作；手柄右摇杆灵敏度可调
- PgUp/PgDn / Home / End 键盘跳转完全支持

### Reduced Motion

详见 §Transitions & Animations 表"Reduced-motion 替代"列。容量警告闪烁在 reduced motion 下**完全关闭**，改为静态红边。

### 已知限制

- Menu screen reader（NVDA / Narrator passthrough）— 与 accessibility-requirements 全局一致，本屏不单独实现
- 物品卡片 48×48 图标在 1280×720 最小窗口 + 150% 缩放的极端组合下可能裁切 — 需最小字号验证

---

## Localization Considerations

| 元素 | 中文最长 | 设计预留宽度 | 风险 / 备注 |
|---|---|---|---|
| 资源中文名（灵气 / 修为 / 灵石 / 药材 / 经验） | 2 字 | 4 字宽度 | 低 — 英文 "Spirit Qi / Cultivation / Spirit Stone / Herb / EXP" 已在范围 |
| Tab 标签（"资源" / "背包" / "图鉴"） | 2 字 | 4 字宽度 | 低 — 英文 "Resources / Backpack / Index" |
| 变动明细来源名称（"挂机产出" / "离线结算"等） | 4 字 | 12 字宽度（按 +200% 翻译宽容） | **中** — 英文 "Auto-Production / Offline Settlement" ≈ 20 字符；需测试德文 |
| 容量警告文字（"已满 ⚠"） | 3 字 | 6 字宽度 | 低 |
| 空库存文案（"暂无物品 —— 前往战斗获取掉落"） | 14 字 | **支持 2 行换行** | **HIGH** — 英文 "No items — Go to combat to obtain loot" ≈ 38 字符；必须 autowrap |
| 新玩家空库存附文（"战斗击败敌人可获取灵草、矿石等材料"） | 16 字 | **支持 2 行换行** | **HIGH** — 同上 |
| 物品名称（item-material-system `name` 字段） | 最长 "纯质水晶" 4 字 (MVP) | 6 字宽度 | 低 — 英文 "Pure Qi Crystal" ≈ 15 字符；网格态卡片需测试溢出省略 |
| 物品稀有度角标（"凡/精/稀/史/传/神/先/混"） | 1 字 | 固定 16×16 角标区域 | 低 — 不需要翻译（角标为视觉符号，中英共用；英文 tooltip 显示 rarity name） |
| 物品 Tooltip 内容（name + rarity + description + tags） | description 最长 ≈ 20 字 (MVP) | RichTextLabel 多行 + autowrap | **HIGH** — description 字段未来可能扩展至 200 字符 |
| 堆叠数量标签 | "×234" | 5 字宽度 | 低 — 数字部分走 NumberFormatter |
| 图鉴占位文案（"Loot Filter — Sprint 12+ 开放"） | — | 上线前替换为玩家可读语言 | **中** — 需 player-facing 文案："掉落筛选 — 即将开放" |

### HIGH PRIORITY 项（标记给 localization engineer）

- **空库存文案** 必须用 `RichTextLabel` + `autowrap_mode = AUTOWRAP_WORD_SMART`，最少支持 2 行
- **物品 Tooltip** 用 `RichTextLabel` 支持多行 + 段落间距；description 字段预留 200 字符宽度
- **变动明细来源名称** 建议用 icon + 文字组合（而非纯文字），减少翻译长度压力

### 数字格式

所有 BigNumber 走 NumberFormatter；中文 / 短格式 / 科学格式由 settings 切换（参 hud-system §UI Requirements + ADR-0014）。

### 不需要本地化的元素

- 资源 PNG 图标（`§2`）— 视觉无文字
- 稀有度边框 PNG（`§6`）— 视觉无文字
- 物品 PNG 图标（`§12`）— 视觉无文字
- 趋势箭头 ▲/▼ — 通用符号
- 容量警告 "⚠" — 通用符号

---

## Acceptance Criteria

按 `.claude/rules/design-docs.md` 标准；至少 5 条可测试、QA 可独立验证、不读其他文档可验证。共 14 条：

### 导航

- [ ] **AC-1** LEFT NAV 点 "📦资源" / 数字键 `3` / 手柄 LB+D-Pad 选第 3 项 + A，3 种入口都能正确开屏（screenshot 证据 ×3）；HUD 顶栏资源数字点击也能跳入本屏
- [ ] **AC-2** Tab "资源" / "背包" / "图鉴" 三者互斥切换；Tab 切换 120ms 内完成且不丢键盘焦点；图鉴 tab hover 显示 "Sprint 12+ 开放" tooltip

### 核心数值

- [ ] **AC-3** "资源" tab 下 5 资源行每行显示：图标 + 名称 + `current / cap` + fill bar + 每秒产出速率 + 趋势箭头；数值与 `ResourceSystem.get_value(id)` / `get_max(id)` 一致（刷新延迟 ≤ 200ms）
- [ ] **AC-4** 资源行展开后显示变动明细列表；每条明细显示来源名称 + 变动量 + 相对时间戳；所有明细的变动量之和与当前值逻辑一致（若 API 就绪）
- [ ] **AC-5** 手风琴模式：展开资源行 A → 自动收起之前展开的资源行 B；同一时间最多 1 行展开
- [ ] **AC-6** 有上限资源（灵气 / 药材）的 fill bar 在 fill_ratio < 0.85 时正常色；fill_ratio ≥ 0.85 时切 `bottleneck_red` + "⚠" 出现；fill_ratio == 1.0 时显示 "已满 ⚠" chip + 产出速率灰字 "(溢出)"
- [ ] **AC-7** 无上限资源（修为 / 灵石 / 经验）的 cap 显示为 "∞"；不做容量警告；经验的产出速率显示 "战斗获取" 而非数字

### 背包

- [ ] **AC-8** "背包" tab 下物品以 4 列卡片网格显示；每卡含 48×48 图标 + 名称 + 稀有度边框（8 阶对应正确）+ 文字角标 + 堆叠数量；hover 物品卡 0.3s 触发 P-INP-01 Tooltip 显示 name / rarity / description / tags / stack_limit
- [ ] **AC-9** 背包空库存（物品数 == 0）时显示占位插画 + "暂无物品 —— 前往战斗获取掉落"；新玩家（从未战斗）额外显示 "战斗击败敌人可获取灵草、矿石等材料"
- [ ] **AC-10** 物品网格走 P-DAT-02 虚拟化渲染；超过 1 屏物品时仅渲染可视行 + 4 行 overscan；Home/End 键跳首/末

### 状态

- [ ] **AC-11** TimeManager 冻结时，所有资源行产出速率追加 "(已冻结)" 灰字，趋势箭头隐藏；解冻后恢复

### Accessibility（Standard tier 强制）

- [ ] **AC-12** 键盘 Tab 顺序覆盖 Tab 栏 3 项 + 5 资源行 + N 张可见物品卡（顺序与 §Interaction Map 一致）；每个焦点显示 2px `burst_gold` 描边；物品网格支持 D-Pad 四向导航
- [ ] **AC-13** UI 缩放 75% / 100% / 150% 三档 + 1280×720 最小窗口下，布局不破、文字不裁切、物品卡片至少显示 3 列、所有交互元素仍可达
- [ ] **AC-14** reduced-motion 开启时，所有 transition ≤ 50ms 或 instant；容量警告闪烁完全关闭转静态红边；物品 Tooltip 变为 instant 显示

---

## Open Questions

| Question | Owner | Deadline | Resolution |
|---|---|---|---|
| ResourceSystem 是否新增 `get_recent_history(id, seconds)` API 以驱动变动明细？涉及 ResourceSystem 内部是否记录变动日志 | technical-director + game-designer | Sprint 11 dev | 未解决 — 倾向：MVP 走降级方案 B（展开区显示实时静态来源列表，零新 API）；历史明细 API 留 Sprint 12+ |
| 背包物品列表的数据来源是遍历 ResourceSystem 的 material 类资源（current > 0）还是引入独立的 InventorySystem？ | technical-director + game-designer | Sprint 11 dev | 未解决 — 倾向：MVP 直接遍历 ResourceSystem + ItemRegistry 联合查询（5+13=18 条物品，O(N) ≈ 0.2ms 可忽略）；Alpha 装备/词条上线后引入独立 InventorySystem |
| "近一小时"变动明细的时间窗口是否可通过设置调整（30min / 1h / 2h / 全部）？ | ux-designer + game-designer | Sprint 11 dev | 未解决 — 倾向：MVP 固定 1 小时窗口；post-MVP 加 segmented control 切换 |
| 物品卡片点击后的行为（MVP 仅 Tooltip 还是跳详情子屏）？ | game-designer | Sprint 11 dev | 未解决 — 倾向：MVP 仅 Tooltip（Alpha 装备系统补详情屏） |
| HUD 顶栏资源数字点击跳入本屏 + 自动定位到对应资源行，Sprint 11 是否实现还是留后续？ | ux-designer + ui-programmer | Sprint 11 dev | 未解决 — 倾向：Sprint 11 实现基础跳入（不带定位参数）；定位参数留 Sprint 12 |
| 背包 tab 徽章数字（物品总数）应显示"物品种类数"还是"物品总堆叠数"？ | ux-designer | Sprint 11 dev | 未解决 — 倾向：显示种类数（"背包(13)" = 13 种不同物品），与未来图鉴"已收集 12/30"语义一致 |
| 物品稀有度 Tooltip 中 rarity 是否显示中文全称（"凡品"）还是简称（"凡"）？ | ux-designer + narrative-director | Sprint 11 polish | 未解决 — 倾向：角标用简称（1 字），Tooltip 用全称（"凡品 / common"） |
| 图鉴 tab 占位是否需要更具体的预告信息（"即将支持：自定义掉落筛选 / 物品收集进度 / 稀有度图鉴"）？ | game-designer | Sprint 11 polish | 未解决 — 倾向：MVP 保持极简占位（锁 + 一句）；post-MVP 补 roadmap teaser |
| `design/player-journey.md` 缺失 — 资源屏在玩家"挂机回来 → 清点背包 → 决策扩容/消耗"循环中的节奏假设需要 journey 文档支撑 | producer + ux-designer | Sprint 11 启动前 | 未解决 — 与 cultivation-screen.md Open Questions 同源问题 |
