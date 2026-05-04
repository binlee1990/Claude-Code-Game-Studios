# HUD Design

> **Status**: In Design — first draft, awaiting user review
> **Author**: ux-designer + binlee1990
> **Last Updated**: 2026-05-04
> **Template**: HUD Design
> **Scope**: MVP HUD only（hud-system.md GDD 8 必需元素 + 极少数 P0 扩展）；post-MVP growth 列入 Gaps section

---

## HUD Philosophy

**Information-Dense, Progressively Unveiled, Restrained**

| 维度 | 立场 |
|------|------|
| **密度** | 决策相关数字常驻可见。 idle RPG 玩家做决策依赖读数（资源 / 等级 / 战力 / 区域 / 战斗状态）；隐藏关键信息 = 强迫玩家进菜单 = 违反 pillar 4.2"放置 = 低频高价值决策"。 |
| **解锁节奏** | 渐进披露。开局 HUD 仅显示**修炼资源 + 当前活动**（约 4 个元素）；随系统解锁逐步加项至 MVP 完整态（约 12 个元素）。pillar 4.6 + ui-framework 渐进 UI 解锁机制。 |
| **视觉克制** | 信息密集但**不喧宾夺主**。所有数字刷新走 art-bible Sec 2 状态①"禅静沉浸 + 60s 周期极缓水墨云气 + 资源面板不参与动效"。常规 tick 走 `text_secondary`；只有突破 / 稀有掉落 / 失败用语义色（参 art-bible Sec 4.2）。 |
| **HUD vs. Modal 边界** | HUD 显示**当前状态**，不承担**操作流程**。任何超过 1 步的操作（突破 / 飞升 / 装备配置 / 派遣）走 P-NAV-03 Modal 或专门屏。 |
| **冲突仲裁** | 当"密度需要"与"克制视觉"冲突 → **可读性优先**（继承 art-bible Sec 1 顶层裁决）。具体表现：宁可拆 tooltip 详情也不缩字号；宁可分页也不挤行高。 |

> **取自的对照游戏**：Melvor Idle（信息密集但克制）+ Antimatter Dimensions（数字常驻 + 渐进解锁）+ Path of Exile（HUD 不承担操作流程，全走面板）。
> **明确不取**：Hollow Knight 类极简 HUD（与本项目数字玩法直接冲突）；Diablo IV 类高饱和闪烁 HUD（破坏 long-session 4+ 小时观看舒适度）。

---

## Information Architecture

### Full Information Inventory

下表整合 `hud-system.md` UI Requirements + 关联 GDD 的 HUD 触达需求。范围：**MVP 需要在 HUD 出现的所有信息**。

| # | 信息项 | 来源 GDD | 信号特性 |
|---|---|---|---|
| 1 | 灵气（lingqi） | resource-system | 高频累积 + 可能溢出 |
| 2 | 修为（xiuwei） | resource-system, cultivation | 中频累积 |
| 3 | 灵石（lingshi） | resource-system | 低频累积 |
| 4 | 药材（herb） | resource-system | 低频累积 |
| 5 | 经验（exp） | level-system | 中频累积 |
| 6 | 等级 + 境界 | level-system | 事件驱动 |
| 7 | 当前区域 | zone-system | 玩家选择 + 显示 |
| 8 | 战斗状态（idle / fighting / boss / failed） | semi-auto-combat | 事件驱动 |
| 9 | 战斗日志 | semi-auto-combat | 高频流 |
| 10 | 当前修炼姿态（cultivation stance） | cultivation-system | 玩家选择 + 显示 |
| 11 | 离线收益入口（事件后亮起） | offline-reward-settlement | 事件驱动 |
| 12 | 警告 / 通知栈（瓶颈 / 满仓 / 解锁可用 / 突破可用） | hud-system, multiple | 事件驱动 |
| 13 | 设置 / 调试入口（dev build only） | hud-system, debug-console | 静态入口 |

### Categorization

按"Must Show / Contextual / On Demand / Hidden"分类：

| 信息项 | 类别 | 触发 / 显示规则 |
|---|---|---|
| 灵气 | **Must Show** | 顶栏第 1 位，常驻；fill bar 当 ≥ 0.85 cap 触发瓶颈红 chip |
| 修为 | **Must Show** | 顶栏第 2 位；显示当前 / 下一阶位需求 |
| 灵石 | **Must Show** | 顶栏第 3 位；纯数值（无 cap） |
| 药材 | **Contextual** | 顶栏右侧 chips 区域；首次解锁炼丹后常驻 |
| 经验 | **Contextual** | 等级徽章下方进度条；接近升级时高亮 |
| 等级 + 境界 | **Must Show** | 顶栏右侧徽章 |
| 当前区域 | **Must Show** | 顶栏中央，可点击切换 |
| 战斗状态 | **Must Show** | 中央内容区右上角 + 顶栏区域选择器旁状态点 |
| 战斗日志 | **Must Show**（默认） / **On Demand**（玩家可折叠） | 右侧 panel；最近 8 行；右侧上"折叠"按钮 |
| 修炼姿态 | **Contextual** | 仅"主基地"屏可见；其他屏不显示 |
| 离线收益入口 | **Contextual** | 仅 `offline.settled` 后到玩家查看前；点击 → P-NAV-04 Drawer |
| 警告 / 通知栈 | **Contextual** | 仅有 active 警告时；右上 toast stack（P-FBK-01） |
| 设置入口 | **Must Show** | 顶栏极右"⚙"按钮 |
| 调试入口 | **Hidden** | 仅 dev build；F1 快捷键 + 顶栏右"🐞"按钮 |

**Must Show 数**：6（灵气 / 修为 / 灵石 / 等级境界 / 当前区域 / 战斗状态）+ 1（设置入口） = **7**。
**Contextual 数**：5。
**On Demand 数**：0–1（战斗日志可折叠）。
**Hidden 数**：1（调试）。

> **Conflict check**（按 skill 要求）：philosophy = "info-dense progressive"，Must Show 数 7 项与 philosophy 一致（不是"nearly HUD-free"，所以 Must Show ≥ 5 是合理的）；不触发降级建议。
> **解锁起点 vs. MVP 满载**：开局新存档 HUD 仅显示 4 项（灵气 / 修为 / 当前区域 / 战斗状态）；其他 Must Show / Contextual 随对应系统解锁逐项加入。

---

## Layout Zones

### 1080p 三段式布局

```
┌──────────────────────────────────────────────────────────────────────────────┐
│  [TOP STRIP — 64px]                                                          │
│  灵气 ⛬ 1.2K/2K   修为 ◯ 850K   灵石 ◇ 12.5M   药材 ❀ 234K  ┊  Lv32 筑基  ┊ 区域: 灵谷 ▼  ┊ ⚙ │
├────────┬─────────────────────────────────────────────────┬──────────────────┤
│  [LEFT │  [CENTER — main content per current screen]     │  [RIGHT — 320px] │
│   192px│                                                  │                  │
│   tabs]│  ┌─ status: 自动战斗中 · 区域 灵谷             │  战斗日志 ▼      │
│        │  │  Lv32 筑基  → 下一突破: 22%               │  ┌──────────────┐│
│  📊修炼│  │                                              │  │ 18:32 普攻 │║
│  ⚔战斗│  │   [main panel content area]                  │  │ 18:32 暴击!│║
│  🏯城镇│  │                                              │  │ 18:33 击杀 │║
│  🏞秘境│  │                                              │  │ ...        │║
│  ⛅飞升│  │                                              │  │            │║
│        │  │                                              │  │ ▼ jump latest│
│        │  │                                              │  └──────────────┘│
│        │  │                                              │                  │
│        │  └─                                              │  [警告 chips]   │
│        │                                                  │                  │
│        │  ┌─ contextual: ❀ 修炼姿态 = 五行打坐 ⚙        │                  │
│        │  └─                                              │                  │
├────────┴─────────────────────────────────────────────────┴──────────────────┤
│  [BOTTOM ACTION BAR — 仅在选中物品/角色 时弹出 48px]                         │
│  3 项已选  ⏤  ✕ 取消  │  ⊘ 分解  │  ↑ 比较  │  ◇ 装备                       │
└──────────────────────────────────────────────────────────────────────────────┘

Toast Stack（绝对定位 right: 16px, top: 80px, P-FBK-01）：
                                                              ┌──────────────┐
                                                              │ 🌟 突破成功！│
                                                              │ Lv31 → Lv32  │
                                                              └──────────────┘
                                                              ┌──────────────┐
                                                              │ 💎 史诗掉落 │
                                                              │ 千年灵剑·锋  │
                                                              └──────────────┘
```

### 区域功能与尺寸

| 区域 | 位置 | 尺寸 @ 1080p | 内容 |
|---|---|---|---|
| **TOP STRIP** | 顶部固定 | 屏宽 × 64px | 资源 / 等级境界 / 区域 / 设置 |
| **LEFT NAV** | 左侧固定 | 192px（折叠 48px） × (屏高 − 64) | P-NAV-02 Side-Tab：5 主区域 |
| **CENTER CONTENT** | 中央 | 自适应 × (屏高 − 64) | 当前主屏内容（依 LEFT NAV 切换） |
| **RIGHT PANEL** | 右侧固定 | 320px × (屏高 − 64) | 战斗日志（默认展开）+ 警告 chips（底部） |
| **BOTTOM ACTION BAR** | 底部弹出 | 屏宽 × 48px | 仅选中物品/角色时；批量操作（参 P-DAT-03） |
| **TOAST STACK** | 屏右上覆盖 | 320 × auto | P-FBK-01；最多 4 条 |
| **OFFLINE DRAWER** | 屏右滑入 | 480px × 屏高 | 触发后；P-NAV-04 |

### 屏幕安全区

- 最小窗口：1280×720 → 缩放：LEFT 折叠 48px / RIGHT 缩到 240px 或可折叠
- Steam Deck（1280×800）：默认 LEFT 折叠 + 字号 +1 档（约 22px → 24px 主数据）
- 4K（3840×2160）：等比缩放，不变布局比例

---

## HUD Elements

详细规格按区域分组。Theme token 全部走 `res://assets/ui/theme.tres`（art-bible Sec 4.6）。

### TOP STRIP — 资源条

| 元素 | Pattern | 视觉 | 更新行为 | 触发条件 |
|---|---|---|---|---|
| 灵气 row | P-DAT-01 Resource Row | 24px ⛬图标 + 中文 + BigNumber + cap fill bar | coalesced ≤ 0.1s（hud_refresh_interval）| 常驻 |
| 修为 row | P-DAT-01 | ◯图标 + 数值 + 下一阶位需求 | coalesced ≤ 0.1s | 常驻 |
| 灵石 row | P-DAT-01 | ◇图标 + 数值（无 cap） | coalesced ≤ 0.1s | 常驻 |
| 药材 chip | P-FBK-02 inline chip | ❀图标 + 数值 | coalesced ≤ 0.1s | 解锁炼丹后常驻 |
| 等级 / 境界徽章 | 自定义 | "Lv32 · 筑基" + 经验 fill bar（细 4px） | 事件驱动（`level.changed` / `realm.advanced`）| 常驻 |
| 区域选择器 | 自定义按钮 + Modal | "区域: 灵谷 ▼" → 点击打开区域列表 Modal | 事件驱动（`zone.changed`）| 常驻 |
| 战斗状态点 | 单色点 | 区域选择器右侧 8×8 点：● 战斗中 / ○ 待机 / ◆ Boss / ✕ 失败 | 事件驱动 | 常驻 |
| 设置 ⚙ | Icon button | 顶栏极右 32×32 按钮 | 静态 | 常驻 |
| 调试 🐞 | Icon button | dev build：⚙左侧 32×32 | 静态 | dev only |

### CENTER CONTENT — 状态摘要

仅顶部 ribbon 属于 HUD 范围，内容区由各主屏 spec 自定。

| 元素 | 视觉 | 更新行为 |
|---|---|---|
| 状态行 | 一行：当前主活动文本（"自动战斗中 · 区域 灵谷"）+ 当前等级境界 + 下一突破进度 % | 事件驱动 |
| 修炼姿态指示 | "主基地"屏专属：当前姿态名 + ⚙打开姿态切换 modal | 事件驱动 |

### RIGHT PANEL — 战斗日志 + 警告

| 元素 | Pattern | 视觉 | 更新行为 |
|---|---|---|---|
| 战斗日志 | P-FBK-03 Battle Log Scroll | 8 行虚拟列表 + auto-scroll + "↓ 跳到最新"chip | 事件驱动 |
| 简略 / 详细 toggle | Segmented | 日志顶部右"简 / 详"toggle | 玩家手动 |
| 折叠 / 展开 toggle | Icon button | 日志顶部"⇲"按钮，可折叠到屏右边缘条 | 玩家手动 |
| 警告 chip 区 | P-FBK-02 Inline Status Chip | 战斗日志下方堆叠：满仓 / 瓶颈 / 解锁可用 / 突破可用 | 事件驱动 |

### TOAST STACK — 浮动通知

| 元素 | Pattern | 视觉 | 更新行为 |
|---|---|---|---|
| 突破 / 稀有掉落 / 飞升 toast | P-FBK-01 Toast Stack | 320×64 卡片，4 秒消失，可点击展开 | 事件驱动 |

### BOTTOM ACTION BAR — 批量操作

| 元素 | 视觉 | 更新行为 |
|---|---|---|
| 选中数 + 批量按钮 | "N 项已选 │ 取消 / 分解 / 比较 / 装备" | 选中数 ≥ 1 时滑入；= 0 时滑出 |

### OFFLINE DRAWER — 离线结算

| 元素 | Pattern | 视觉 | 更新行为 |
|---|---|---|---|
| 离线结算入口 | TOP STRIP 状态点旁"📦 N"角标 | 收到 `offline.settled` 后亮起 | 事件驱动 |
| Drawer 本体 | P-NAV-04 Drawer | 480px 宽，列出资源 / 经验 / 战利品 / 生产完成 | 玩家点击入口 |

---

## Dynamic Behaviors

HUD 在 idle 游戏不切换"模式"（无 combat vs. exploration），但有 4 类动态变化：

### 1. 渐进解锁（Progressive Unveil）

| 触发 | HUD 变化 |
|---|---|
| 新存档开始 | 顶栏只显示：灵气 / 修为 / 当前区域 / 战斗状态点 / 设置（5 项） |
| 解锁灵石（首次完成自动战斗） | 顶栏加入灵石 row |
| 解锁炼丹系统 | 顶栏加入药材 chip |
| 解锁城镇 | LEFT NAV 加入"🏯城镇"tab |
| 解锁秘境 | LEFT NAV 加入"🏞秘境"tab |
| 解锁飞升 | LEFT NAV 加入"⛅飞升"tab |

> 实现：HUD 订阅 `system.{system_name}.unlocked` 事件，触发对应元素淡入（200ms fade）。元素位置预留，不改变其他元素位置。

### 2. 资源警戒态

| 触发 | HUD 变化 |
|---|---|
| 资源 fill_ratio ≥ 0.85（hud-system `resource_warning_threshold`）| Resource Row fill bar 切 `bottleneck_red` + 数字右侧加"⚠" 字符 + RIGHT PANEL 警告 chip 区出"满仓"chip |
| Recent_lost_ratio > 0（最近溢出过资源）| 同上 + chip 文字"近期溢出 N" |

### 3. 战斗状态切换

| 触发 | HUD 变化 |
|---|---|
| 战斗开始 | 战斗状态点 ● 红 + 战斗日志 auto-scroll 启动 |
| Boss 战 | 战斗状态点 ◆ 紫 + art-bible Sec 2 状态④四角 `threat_purple` 晕染压框 + 倒计时字号 1.25× |
| 战斗失利 | 战斗状态点 ✕ + art-bible Sec 2 状态⑧全屏灰墨覆层 + `failure_red` 印章字 |
| 突破成功 | art-bible Sec 2 状态③全屏 `burst_gold` 印章 3s 收缩 + Toast |

### 4. 长 Session 视觉漂移防护

per art-bible Sec 1 第 2 原则 + Sec 2 状态①："数据区不参与情绪渲染"。HUD 默认状态下：

- 所有数字 tick 用 `text_primary`，无颜色变化（除瓶颈警示外）
- 数字增长不带闪烁 / 弹跳动画（art-bible Sec 3.5 禁区 5）
- 战斗日志新行用 fade-in 220ms，无 slide / bounce
- 背景水墨云气 60s 周期极缓慢横移（art-bible Sec 2 状态①）

> 目的：玩家挂机 4+ 小时不会因 HUD 视觉刺激产生疲劳。

---

## Platform & Input Variants

### Resolution / Aspect

| 分辨率 | 处理 |
|---|---|
| 1280×720（最小） | LEFT NAV 默认折叠 48px；RIGHT PANEL 缩到 240px |
| 1920×1080（基线） | 三段式如上 |
| 2560×1440 | 等比缩 |
| 3840×2160（4K） | 等比缩 + 字号 +1 档 |
| 21:9 / 32:9 超宽 | CENTER 内容区 max-width 限制 1920px 居中；LEFT/RIGHT 钉边 |
| Steam Deck 1280×800 | 字号 +1 档；LEFT 折叠默认 |

### Input Variants

| 输入 | HUD 行为 |
|---|---|
| 键鼠 | 鼠标 hover 触发 P-INP-01 Tooltip；点击 / 拖拽全可用 |
| 手柄（partial） | LEFT NAV 用 D-Pad ←→；CENTER 用左摇杆 + A 键；RIGHT 战斗日志用右摇杆滚动；Tab 切屏用 LB/RB；Modal 关闭用 B；Toast 展开用 X；设置用 Start |
| 触屏 | **不支持**（technical-preferences `Touch Support: None`）；后续移植再考虑 |

### 手柄 partial 已知限制（与 patterns Open Questions 一致）

- P-DAT-03 Data Table 列拖拽 / 多选用手柄受限：手柄走预设列宽，多选用 Y 键单点累加
- 调试控制台（dev only）暂不支持手柄

---

## Accessibility

继承 `design/accessibility-requirements.md` Standard tier。本节列 HUD 特化条款：

### 视觉

- 所有 HUD 文字 ≥ 20px（Standard tier"HUD 关键信息 ≥ 20px @ 1080p"）
- 顶栏资源数字与背景对比 ≥ 4.5:1（art-bible Sec 4.1 `text_primary` on `panel_bg_primary` ≈ 9:1）
- 警戒态 chip 与背景对比 ≥ 4.5:1（`bottleneck_red` 与 `panel_bg_secondary` ≈ 5.2:1）
- 8 阶稀有度（出现在 Toast / 战斗日志击杀掉落预览 / Drawer 离线战利品）走 art-bible Sec 4.6 三重 backup（颜色 + 形状 + "凡/精/稀/史/传/神/先/混"字角标）
- UI 缩放 75%–150% 时 HUD 须不破布局：实现端测 5 个档位（75 / 90 / 100 / 125 / 150）

### 键鼠 / 手柄等价

- 所有 HUD 交互均有键鼠 + 手柄路径（参 Platform & Input Variants）
- Tab order：TOP STRIP（左→右）→ LEFT NAV（上→下）→ CENTER → RIGHT PANEL → BOTTOM ACTION BAR
- 可见焦点指示：当前焦点元素加 2px `burst_gold` 描边

### 时间相关

- Toast 4s 自动消失：accessibility-requirements 已记录开放问题；提供 settings"延长 toast 至 8s / 不自动消失"开关
- 战斗日志 auto-scroll：玩家手动向上滑后立即暂停（不计时强行滑回）
- 突破 / 飞升的 burst 动画 3s：无玩家输入要求，不算"timed input"

### 色弱 backup（HUD 特化）

| 信号 | 颜色 | 非颜色 backup |
|---|---|---|
| 战斗状态点 | ● 红 = 战斗中 / ○ 灰 = 待机 / ◆ 紫 = Boss / ✕ 红 = 失败 | 形状本身（圆 / 空圆 / 菱形 / 叉）已是主信号 |
| 资源警戒 chip | `bottleneck_red` | "满仓" / "瓶颈" 中文文字 + ⚠图标 |
| 突破可用 chip | `burst_gold` | "突破" 文字 + 印章图标 |
| 等级徽章经验进度 | 单色 fill bar | 数字百分比文字 |

### Reduced Motion

继承 settings"reduce motion"开关：

- 渐进解锁淡入：200ms → instant cut
- Toast 滑入：200ms from right → fade only
- 战斗状态切换的四角紫晕染：保留（不属于"motion"，是静态压框）
- 全屏 burst 印章：3s 缩到 0.5s + 不加缩放变换
- 背景水墨云气 60s 横移：彻底关闭

---

## Gaps & Future Growth

post-MVP HUD 元素，等对应系统进入 sprint 再补：

| 元素 | 触发系统进入 sprint | 优先级 |
|---|---|---|
| Minimap / 区域简图 | Layer 10 世界地图系统（系统 166） | P1 |
| 多角色血量 / 资源条 | 队伍系统（系统 84） | P1 |
| 阵法可视化 | 阵法系统（系统 86） | P2 |
| 宠物状态条 | 灵宠系统（系统 131） | P2 |
| 经济流水图（实时产销）| 经济仿真器（系统 28） | P2 |
| 试炼塔层数 / 兽潮波次 | 各对应模式（系统 170 / 175） | P2 |
| 自动化任务排队显示 | 自动化解锁系统（系统 60） | P1 |
| 命格 / 因果 / 气运高阶资源条 | 后期境界解锁（轮回 / 合道阶段） | P2 |

---

## Open Questions

| Question | Owner | Deadline | Resolution |
|---|---|---|---|
| 顶栏 7 个 must-show 元素在 1280×720 最小分辨率下是否会折行 / 挤压？需在 prototype 第一周做布局测试 | ux-designer + ui-programmer | Pre-Production sprint 1 | 未解决 |
| 战斗日志在 ≥ 1000 条历史时玩家滚回早期是否会卡顿？P-DAT-02 Virtualized List 已声明，需性能验证 | ui-programmer | Pre-Production | 未解决 |
| 渐进解锁的 12 个元素淡入顺序与节奏是否需要 player-journey 文档驱动？建议本 sprint 内做 player-journey 草稿 | producer | Pre-Production | 未解决 |
| 8 阶稀有度形状破框（神话 / 先天 / 混沌）出现在 Toast 卡片 320×64 上是否能稳定渲染？需在 art-bible Section 5 / asset spec 时验证 | art-director | Production | 未解决 |
| 离线收益入口角标"📦 N"在 N ≥ 100 时如何显示（比如刷夜回流）？建议 ≥ 99 显示"99+" | ux-designer | Pre-Production | 未解决 |
| Toast 4s 自动消失与 accessibility "延长至 8s"开关的默认值？倾向：默认 4s（不打扰），长按可手动延长 | ux-designer | Pre-Production | 未解决 |

---

## Cross-Reference Index

- **art-bible Sec 1**：4.5:1 / 1.5:1 对比度法则 → HUD 全部数字色与背景关系
- **art-bible Sec 2 状态①**：禅静沉浸 + 数据区不参与情绪渲染 → HUD 默认态视觉克制
- **art-bible Sec 2 状态③④⑦⑧**：突破金 / Boss 紫 / 离线金白 / 失败灰红 → HUD 状态切换视觉
- **art-bible Sec 4.1**：base palette 7 token → 顶栏 / 主面板 / 装饰
- **art-bible Sec 4.2**：5 语义色 + 瓶颈红 vs. 失败红区分 → HUD chip 与状态点
- **art-bible Sec 4.6**：色弱矩阵 + 8 阶稀有度 backup → HUD 战斗日志击杀掉落预览
- **interaction-patterns**：P-DAT-01 Resource Row / P-DAT-02 Virtualized List / P-FBK-01 Toast / P-FBK-02 Status Chip / P-FBK-03 Battle Log / P-NAV-02 Side-Tab / P-NAV-04 Drawer / P-INP-01 Tooltip
- **accessibility-requirements**：Standard tier → HUD 字号 / 对比 / 键鼠手柄等价 / 色弱 backup / reduced motion
- **hud-system GDD**：8 必需元素 + coalesced refresh + battle_log_rows + resource_warning_threshold tunable
- **ui-framework GDD**：UIManager / register_screen / max_modal_depth / virtual list 公式 / `default_transition_ms`
- **resource-system GDD**：资源数据源
- **level-system GDD**：等级 / 境界数据源
- **zone-system GDD**：当前区域数据源
- **semi-auto-combat GDD**：战斗状态 + 战斗日志数据源
- **offline-reward-settlement GDD**：离线结算入口数据源

---

## Acceptance Criteria（HUD 整体）

- [ ] **新存档**首次进入游戏，HUD 仅显示 5 项（灵气 / 修为 / 当前区域 / 战斗状态点 / 设置入口），其余隐藏
- [ ] 解锁炼丹系统后，顶栏药材 chip 在 200ms 内淡入，其他元素位置不变
- [ ] 50 条 `resource.lingqi.changed` 事件在一帧内触发时，HUD 只 layout 一次（继承 hud-system 验收）
- [ ] 灵气 fill_ratio ≥ 0.85 时，资源行 fill bar 切 `bottleneck_red` + 数字右"⚠" + RIGHT PANEL 出"满仓" chip
- [ ] Boss 战触发时，状态点 ◆ 紫 + 屏四角晕染压框 + 倒计时字号 1.25×
- [ ] 突破成功时，全屏 `burst_gold` 印章 3s 内收缩消散，HUD 数据面板仍可读
- [ ] 离线收益事件后，TOP STRIP 状态点旁"📦 N"角标亮起，玩家点击打开 P-NAV-04 Drawer
- [ ] Tab 顺序覆盖所有可交互元素：TOP STRIP → LEFT NAV → CENTER → RIGHT PANEL → BOTTOM ACTION BAR
- [ ] UI 缩放 75% / 100% / 150% 三档下，HUD 布局不破，文字不裁切，最小窗口 1280×720 通过
- [ ] 减动模式开启时，Toast 滑入变 fade，背景水墨云气停止，全屏 burst 缩到 0.5s
- [ ] 手柄 partial：LEFT NAV / Toast 展开 / Modal 关闭 / 设置入口全可达；Data Table 列拖拽明确禁用
