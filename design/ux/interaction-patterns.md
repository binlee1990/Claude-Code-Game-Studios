# Interaction Pattern Library

> **Status**: In Design — first draft, awaiting user review
> **Author**: ux-designer + binlee1990
> **Last Updated**: 2026-05-04
> **Template**: Interaction Pattern Library
> **Mode**: Forward-defined（无既有 UX spec 可抽取，从 GDD UI Requirements + art-bible + accessibility-requirements 三处合成）

---

## Overview

本 pattern library 是项目所有 UX spec 的"组件宪法"：每个 pattern 一旦锁定，所有屏幕实现必须引用而不重新发明。建立目的：

1. **防止同质 pattern 在不同屏幕长出微差异**（idle 游戏 30+ 系统 × 多屏幕，差异会指数膨胀）
2. **把 art-bible 的视觉法则落地为可复用组件**，避免每次屏幕设计重谈对比度 / 字号 / 边框
3. **把 accessibility-requirements Standard tier 的"全 remap / 色弱 backup / no timed input"硬编码到 pattern 层**，每屏自动继承

**约束总锚点**：

- art-bible Section 1 — 4.5:1 / 1.5:1 对比度法则（可交互 vs. 装饰）
- art-bible Section 3 — 直角 + 单侧切角；无圆角；screen-space HUD（非 diegetic）
- art-bible Section 4 — Theme token 命名（`panel_bg_*` / `text_*` / `ink_stroke` / 语义色 / 8 阶稀有度色阶）
- accessibility-requirements — Standard tier；键鼠 + gamepad partial；色弱模式 ×3；text scaling 75%–150%
- ui-framework GDD — `UIManager` Autoload；register/open/close/modal API；coalesced refresh；virtual list

---

## Pattern Catalog

按类别分组的索引（详细规格见下方 "Patterns" 节）：

### Navigation

| Pattern | 一句话 | Used In（计划） |
|---|---|---|
| **P-NAV-01** Top-Tab Navigation | 顶部水平 tab 切换主区域（修炼 / 战斗 / 城镇 / 秘境 / 飞升） | 所有主屏 |
| **P-NAV-02** Side-Tab Navigation | 左侧垂直 tab 切换子分类（背包 / 装备 / 词条 / 阵法） | 二级屏 |
| **P-NAV-03** Modal Stack | 单中心弹窗 + 最多 3 层（ADR-0011 + ui-framework `max_modal_depth`）| 突破 / 飞升 / 设置 / 详情 |
| **P-NAV-04** Drawer | 右侧抽屉浮层显示瞬时信息（离线结算 / 战报 / 通知队列） | 离线结算 / 通知 |

### Data Display

| Pattern | 一句话 | Used In（计划） |
|---|---|---|
| **P-DAT-01** Resource Row | 单行资源显示：图标 + 名称 + 数值 + 可选 cap/fill bar + 趋势 | HUD 顶栏 / 仓库 / 配方 |
| **P-DAT-02** Virtualized List | 长列表只渲染可视行 + overscan（ui-framework `visible_list_items`） | 背包 / 战斗日志 / 图鉴 |
| **P-DAT-03** Sortable Filterable Data Table | 多列表格，支持排序 / 过滤 / 列显示切换 | 装备 / 词条 / 居民 / 派遣 |
| **P-DAT-04** Item Card | 物品卡：图标 + 名称 + 8 阶稀有度边框 + 三重 backup（形状 / 文字 / 图标） | 掉落 / 背包 / 拍卖 / 拆分对比 |

### Feedback

| Pattern | 一句话 | Used In（计划） |
|---|---|---|
| **P-FBK-01** Toast Stack | 短时屏幕角落非阻塞提示（稀有掉落 / 突破 / 飞升 / 任务完成） | 全局 |
| **P-FBK-02** Inline Status Chip | 嵌入面板的小色块状态徽章（瓶颈红 / 满仓警告 / 解锁可用） | HUD / 经济视图 |
| **P-FBK-03** Battle Log Scroll | 自动滚动 + 虚拟化的战报流，支持简略 / 详细切换 | HUD / 战斗页 |

### Input

| Pattern | 一句话 | Used In（计划） |
|---|---|---|
| **P-INP-01** Tooltip | 悬停（鼠标）/ 长焦（手柄）显示详情；不抢主操作 | 全局；图标 / 词条 / 数值 |
| **P-INP-02** Confirm-Critical Modal | 不可逆操作（突破 / 飞升 / 重置 / 销毁稀有装备）的二次确认 | 突破 / 飞升 / 重置 / 高稀有度分解 |

---

## Patterns

> **格式约定**：每个 pattern 含 Category / Used In / Description / Specification / When to Use / When NOT to Use / Reference 七节。Theme token 全部走 `res://assets/ui/theme.tres`（art-bible Sec 4.6 备注）。

---

### P-NAV-01  Top-Tab Navigation

**Category**: Navigation
**Used In**: 主屏（修炼 / 战斗 / 城镇 / 秘境 / 飞升）顶部一级切换

**Description**: 屏幕顶部水平 5–7 个 tab，互斥单选。当前 tab 高亮，其余 tab 走 `text_secondary` + `panel_bg_secondary`。点击 / 按 LB/RB 触发切换。锁定 tab（未解锁系统）显示灰色 + 锁图标，悬停显示解锁条件。

**Specification**:

- 容器高度：48px @ 1080p（基线，缩放后等比）
- Tab 间距：固定 4px 切角分隔（art-bible Sec 3.3 单侧切角语法）
- 当前态：`panel_bg_elevated` 底 + `text_primary` 文字 + 顶部 2px `ink_stroke` 描边
- 非当前态：`panel_bg_secondary` 底 + `text_secondary` 文字 + 无描边
- 锁定态：饱和度 −60% + 右下角"🔒"角标（不依赖颜色判断锁定）
- Input：鼠标点击 / 键盘 ←→ + Enter / 手柄 LB/RB 直接切换 + A 键确认
- 切换动画：120ms cross-fade（ui-framework `default_transition_ms`），减动模式下变为 instant cut

**When to Use**：屏幕需要切换 ≥ 3 个**对等优先级**的主区域，且玩家会频繁来回切换。

**When NOT to Use**：tab 数 < 3 → 用 segmented control；tab 数 > 7 → 用 P-NAV-02 Side-Tab；切换是单向流程 → 用导航栈而非 tab。

**Reference**：参照 hud-system GDD 顶栏 + ui-framework `register_screen` API。

---

### P-NAV-02  Side-Tab Navigation

**Category**: Navigation
**Used In**: 二级屏（背包 / 装备 / 词条 / 阵法 / 居民）左侧分类切换

**Description**: 屏幕左侧垂直 tab 列，宽度固定。每个 tab 含图标 + 文本 + 可选数字徽章（如背包"装备 (1234)"）。徽章数字走 `text_secondary` + `panel_bg_elevated`。

**Specification**:

- 容器宽度：折叠态 48px（仅图标） / 展开态 192px（图标 + 文本 + 徽章）
- 折叠 / 展开切换：F 键 / 手柄 RT 长按
- 单 tab 高度：40px @ 1080p
- 当前态：左侧 4px `burst_gold`（用 art-bible Sec 4.2 token 但仅作为"当前"指示，不传达"成就")竖条 + `panel_bg_elevated` 底
- 锁定态：同 P-NAV-01
- 数字徽章：≥ 1000 走 NumberFormatter（缩写如 "1.2K"）
- Input：鼠标 / 键盘 ↑↓ + Enter / 手柄 D-Pad ↑↓ + A

**When to Use**：tab 数 7–20 且需要常驻可见；每个分类有数量徽章。

**When NOT to Use**：tab 数 < 7 → 用 P-NAV-01 Top-Tab；tab 数 > 20 → 加二级折叠分组。

---

### P-NAV-03  Modal Stack

**Category**: Modal
**Used In**: 突破确认 / 飞升仪式 / 设置 / 物品详情 / 派遣队伍配置

**Description**: 居中浮层，背景按 ui-framework Modal 规则保持只读（除非 modal opt-out passthrough）。最多堆叠 3 层（ui-framework `max_modal_depth`，ADR-0011）。每层 modal 顶部 16px 标题区 + 底部 48px 操作区。

**Specification**:

- 最大尺寸：1280×720 @ 1080p；窗口缩小时自动等比缩
- 边距：外部至屏幕边 ≥ 64px
- 背景：`panel_bg_elevated` + 1px `ink_stroke` 边框 + 单侧切角
- 全屏遮罩：`#000000` opacity 50%（与 art-bible Sec 2 状态⑧失败的 60% 区分）
- 关闭：右上角"✕" / Esc / 手柄 B
- 操作区按钮顺序：取消（左） / 主操作（右，金色 burst_gold 边框，不填充）
- 切换动画：150ms scale 0.95→1.0 + fade in；减动模式下 instant
- Modal 内 modal：偏移 +16px / +16px，不完全覆盖父 modal 标题（玩家可看到上下文）

**When to Use**：操作需要玩家完整注意力 / 需要二次输入 / 不可逆。

**When NOT to Use**：纯通知 → 用 P-FBK-01 Toast；瞬时信息 → 用 P-NAV-04 Drawer；嵌入式表单 → 用 inline expand。

---

### P-NAV-04  Drawer

**Category**: Overlay
**Used In**: 离线结算（首次回流）/ 通知队列展开 / 战报详情

**Description**: 从屏幕右侧滑入的浮层，宽度固定占屏幕 30–40%。背景半透明 `panel_bg_secondary` + 左侧 1px `ink_stroke`。Drawer 不阻塞主屏（主屏可继续 idle 累积）。

**Specification**:

- 宽度：480px @ 1080p（缩放等比）
- 滑入动画：200ms ease-out from right；减动模式下 fade in
- 关闭：点击 drawer 外 / Esc / 手柄 B / 右上"✕"
- 多个事件触发：合并到同一 drawer 的列表区，不开多 drawer
- 顶部 ribbon：drawer 标题 + 事件数 + "全部展开 / 折叠" toggle

**When to Use**：信息是瞬时的（玩家看完即关）+ 需要保留主屏可见。

**When NOT to Use**：需要玩家做选择 → 用 P-NAV-03 Modal；信息长期相关 → 嵌入主屏面板。

---

### P-DAT-01  Resource Row

**Category**: Data Display
**Used In**: HUD 顶栏 / 仓库 / 配方原料区 / 突破消耗预览

**Description**: 单行资源信息：左 24×24 图标 + 中文名 + 当前数值（NumberFormatter）+ 可选 cap 后缀（"234K / 500K"）+ 可选 fill bar + 可选趋势箭头 ▲/▼。

**Specification**:

- 行高：32px @ 1080p（24px 字号 P0 数据；HUD 高密度可走 28px）
- 图标位：左 24×24，固定不缩
- 名称：`text_primary`，中文 16–20px，左对齐
- 数值：`text_primary`，等宽数字，右对齐，BigNumber 走 NumberFormatter
- Cap 后缀：`text_secondary`
- Fill bar（可选）：高 4px，按 fill_ratio 显示，警戒态（hud-system `resource_warning_threshold` ≥ 0.85）切 `bottleneck_red` + 在数字右侧加 "⚠" 字符 backup
- 趋势：30 秒内增长 → 绿 ▲，下降 → 红 ▼，平稳 → 隐藏。色弱备援：箭头形状本身就传达方向

**When to Use**：单一资源 / 单行展示，频繁刷新（hud_refresh_interval coalesced）。

**When NOT to Use**：多列对比 → 用 P-DAT-03 Data Table；单一资源详情页 → 自定义 hero block。

---

### P-DAT-02  Virtualized List

**Category**: Data Display
**Used In**: 背包 / 战斗日志 / 图鉴 / 派遣记录 / 拍卖列表

**Description**: 仅渲染可视行 + overscan 行（ui-framework `visible_list_items` 公式：`ceil(viewport_height / row_height) + overscan_rows * 2`）。滚动用滚轮 / 触控板 / 键盘 PgUp/PgDn / 手柄右摇杆。

**Specification**:

- 行高：必须固定（性能前提）；变高行用 fixed-tall 行模式
- Overscan：`overscan_rows` 默认 4（ui-framework tunable）
- 滚动条：右侧 6px，hover 加宽至 12px
- 跳转：Home / End / 手柄 LT+RT 跳首末
- 焦点行：`panel_bg_elevated` 底 + 左侧 2px `burst_gold` 描边
- 空列表：替换为 P-DAT-EMPTY 模板（图标 + 一句话原因 + 可选行动按钮）

**When to Use**：列表项 ≥ 50；性能敏感场景。

**When NOT to Use**：固定 < 30 行的小列表；需要保留所有行 DOM 做复杂跨行交互。

---

### P-DAT-03  Sortable Filterable Data Table

**Category**: Data Display
**Used In**: 装备列表 / 词条对比 / 居民工作台 / 派遣可用角色

**Description**: 多列表格。列头点击切排序顺序（asc / desc / 默认）；顶部过滤栏支持文本搜索 + 多选 chip 过滤 + 数字范围。结果空时走 P-DAT-EMPTY。

**Specification**:

- 列头高：36px；表体行高：28–32px
- 列宽：可拖拽调整；右键列头切显示 / 隐藏列
- 排序：当前排序列头加 ▲ / ▼ 形状（不依赖颜色）
- 过滤 chip：选中态走 `panel_bg_elevated` + `burst_gold` 1px 边
- 列表本体走 P-DAT-02 Virtualized List
- 选中行：左侧 2px `burst_gold` + 底 `panel_bg_elevated`；多选用 Ctrl+Click / Shift+Click / 手柄 Y 键
- 批量操作：选中数 ≥ 1 时屏底浮出 action bar（出售 / 分解 / 比较）

**When to Use**：列表项有 ≥ 3 个可比维度；玩家需要排序 / 过滤决策。

**When NOT to Use**：单维度展示 → 用 P-DAT-02；< 10 项 → 用 segmented control + P-DAT-04 卡片网格。

---

### P-DAT-04  Item Card

**Category**: Data Display
**Used In**: 掉落弹窗 / 背包网格 / 装备详情 / 拍卖 / 套装预览

**Description**: 物品标准卡片：左上 48×48 图标（写意墨线，art-bible Sec 1 第 3 原则）+ 右上稀有度品阶角标（"凡 / 精 / 稀 / 史 / 传 / 神 / 先 / 混" 字 backup）+ 中央词条列表 + 底部分解 / 比较 / 装备按钮组。边框走 art-bible Sec 4.3 八阶规格（边框线宽 + 外发光半径 + 形状破框三轴编码）。

**Specification**:

- 卡片尺寸：网格态 96×128 / 详情态 320×420 @ 1080p
- 边框：按品阶查 art-bible Sec 4.3 表（凡 1px 灰 → 混沌 4px 多色动态）
- 文字角标：右上 16×16，等宽中文一字标，所有品阶都有（不仅靠颜色）
- 形状破框：神话 / 先天 / 混沌 三阶按 art-bible Sec 3.4 加形状特征
- 词条行：`text_primary` 名称 + `burst_gold` 数值（关键属性）
- 图标内：禁透视（art-bible Sec 3.5 禁区 4）；2 色墨线 + 单一主色
- Tooltip 触发：详情态 hover 不弹（已是详情）；网格态用 P-INP-01 Tooltip

**When to Use**：任何"物品"实体（装备 / 法宝 / 丹药 / 卷轴 / 宠物蛋）。

**When NOT to Use**：纯资源 → 用 P-DAT-01 Resource Row；技能 / 词条只读条目 → 简化卡（无操作区）。

---

### P-FBK-01  Toast Stack

**Category**: Feedback
**Used In**: 稀有掉落 / 突破成功 / 飞升 / 离线结算入口提示 / 任务完成

**Description**: 屏幕右上角栈式短时浮条。最多同时显示 4 条；超出排队。每条 4 秒自动消失（Standard tier "no timed input" 不适用，因为 toast 不要求玩家操作；玩家可点击展开 P-NAV-04 Drawer 看历史）。

**Specification**:

- 单条尺寸：320×64 @ 1080p
- 滑入：200ms from right；减动模式 fade only
- 内容：左 24×24 类型图标 + 标题（`text_primary` 18px）+ 副标（`text_secondary` 14px）
- 类型 → token：突破 / 飞升 / 稀有掉落 → `burst_gold`；任务完成 → `text_primary`；瓶颈警告 → `bottleneck_red`
- Stack：新条目从顶部插入，旧条目向下推
- 每条右上"✕"立即关闭；点击条目本体打开对应详情屏

**When to Use**：信息是 informational + 玩家不必立即操作。

**When NOT to Use**：需要玩家二次确认 → 用 P-NAV-03 Modal；持续状态 → 用 P-FBK-02 Status Chip。

---

### P-FBK-02  Inline Status Chip

**Category**: Feedback
**Used In**: HUD 资源警告 / 经济视图瓶颈格 / 系统解锁可用提示 / 突破准备完毕

**Description**: 嵌入数据面板的小色块徽章。常驻或事件触发持续显示直到状态解除。背景走对应语义色 token（4.2），文字走 `text_primary`。每个 chip 必须有图标 + 文字 backup，色弱不丢信息。

**Specification**:

- 尺寸：自适应内容宽度，高度 20–24px
- 圆角：0px（art-bible Sec 3.5 禁区 1）；切角 2px
- 内容：12×12 图标 + 中文短语（≤ 6 字符）
- 类型 → token：满仓 / 瓶颈 → `bottleneck_red`；突破可用 → `burst_gold`；战斗失利 → `failure_red`（仅短瞬，长持需切语义降级）
- 闪烁：仅初次出现 0.5 秒淡入，**不持续动效**（art-bible Sec 3.5 禁区 5：禁形状动画表数据变化）

**When to Use**：状态长持 + 需在关联数据旁就近显示。

**When NOT to Use**：瞬时事件 → P-FBK-01 Toast；批量事件汇总 → P-NAV-04 Drawer。

---

### P-FBK-03  Battle Log Scroll

**Category**: Data Display + Feedback
**Used In**: HUD 战斗日志 / 战斗页详细日志 / 离线结算战报片段

**Description**: 倒序时间线（最新在底部）的战斗事件流。`battle_log_rows` 默认 8 行（hud-system tunable）。每行 = 时间戳 + 角色 + 动作 + 结果。auto-scroll 默认开；用户向上滑 / 滚轮则暂停 auto-scroll，底部出现 "↓ 跳到最新" chip。

**Specification**:

- 行高：22px @ 1080p（中文 14px）
- 颜色编码：暴击 `burst_gold` / 治疗 `rarity_innate`（青白）/ 失败 `failure_red` / 普攻 `text_secondary`
- 简略 / 详细 toggle：屏幕右上 segmented control（"简" / "详"）
- 详细模式行高 + 50%，含伤害公式分解
- 焦点：键盘 / 手柄可用方向键步进单行查看，触发 tooltip 看公式
- 列表本体走 P-DAT-02 Virtualized List

**When to Use**：高频时间序列事件，玩家会回看分析。

**When NOT to Use**：单一事件提示 → P-FBK-01 Toast；持续状态 → P-FBK-02 Chip。

---

### P-INP-01  Tooltip

**Category**: Input + Feedback
**Used In**: 全局；图标 / 词条 / 数值 / 缩略图 / 锁定 tab

**Description**: 鼠标 hover 0.3 秒触发；手柄焦点态长焦 0.5 秒触发或按 X 键查看。Tooltip 不抢主操作焦点；玩家鼠标移开 / 焦点切换立即消失。

**Specification**:

- 触发延迟：mouse 300ms / gamepad focus 500ms
- 内容：标题（`text_primary` 16px）+ 描述（`text_secondary` 14px）+ 可选数据表（属性 / 词条 / 公式）
- 边框：1px `ink_stroke` + 单侧切角；底 `panel_bg_elevated`
- 位置：默认在触发元素**右上**；屏边折回到对侧
- 最大尺寸：320×480 @ 1080p；超长内容内部滚动
- 隐藏：mouse leave / 触发元素失焦 / Esc / 任意点击主屏

**When to Use**：辅助信息可被忽略 + 信息量较大不便常驻。

**When NOT to Use**：信息是决策必要 → 直接显示在主面板；触发元素已是详情态 → 不再 tooltip。

---

### P-INP-02  Confirm-Critical Modal

**Category**: Modal + Input
**Used In**: 突破 / 渡劫 / 飞升 / 轮回 / 合道 / 重置 / 销毁稀有度 ≥ 史诗 装备 / 解散稀有弟子

**Description**: P-NAV-03 Modal 的特化变体，用于不可逆操作。强制 3 道闸：(1) 标题明示后果；(2) 列出将丢失 / 改变的内容；(3) 主操作按钮 2 秒延迟可点（防止误点）+ 玩家手动确认勾选框 "我了解此操作不可逆"。

**Specification**:

- 标题：`failure_red` 文字 + 警示图标 ⚠（不仅靠颜色）
- 后果列表：bullet list，每条配 ↓ / + 符号 backup（"↓ 修为重置至 0" / "+ 解锁飞升后世界"）
- 主操作按钮：默认禁用 + 2s 倒计时进度条；勾选 "我了解此操作不可逆" + 倒计时归零后可点
- 主按钮颜色：`burst_gold` 边框 + 不填充（不用 `failure_red`，避免错按"我要失败"）
- 取消按钮：左侧，always enabled，`panel_bg_elevated` 底
- 关闭快捷键：Esc / 手柄 B 等于"取消"，**禁用**外部点击关闭（防误关）
- 撤销窗口：操作执行后 5 秒内可在 toast 上点 "撤销"（如系统支持）；不支持撤销的操作不显示该 toast

**When to Use**：操作不可逆 + 影响 ≥ 30 分钟玩家进度 + 涉及稀有资源销毁。

**When NOT to Use**：可撤销操作 → 用 P-NAV-03 普通 Modal；低稀有度日常分解 → 直接执行 + 撤销 toast。

---

## Gaps & Patterns Needed

以下场景已识别但本批次未起草，列入下次扩充：

| Pattern 候选 | 优先级 | 触发场景 |
|---|---|---|
| **Loot Filter Editor** | P1 | loot-system GDD 提到 Loot Filter；需可视化编辑器 |
| **Build Library Manager** | P1 | 系统 207 Build 库系统：保存 / 一键切换队伍 + 装备 + 战法 |
| **Skill Tree Browser** | P1 | 系统 76 / 77 天赋树 / 法则星图：超大被动树渲染 + 缩放 + 筛选 |
| **Loop Card Placement** | P2 | 系统 172 Loop 远征：卡牌放置地形 |
| **Backpack Grid Placement** | P2 | 系统 177 阵盘 / 背包构筑：物品形状 + 相邻联动 |
| **Auction Bid UI** | P2 | 系统 129 拍卖 / 黑市：单机拍卖与出价 |
| **Onboarding Tutorial Overlay** | P0（首发前必补） | 系统 38 教程系统：首次解锁系统的非阻塞引导 |
| **Settings / Accessibility Panel** | P0（首发前必补） | 系统 45 设置系统 + accessibility-requirements.md 实现端 |

---

## Open Questions

| Question | Owner | Deadline | Resolution |
|---|---|---|---|
| 手柄 partial 支持是否覆盖 P-DAT-03 Data Table 的多选 + 列拖拽？拖拽列宽很难手柄化 | ux-designer | Pre-Production | 未解决；备选方案：手柄走预设列宽，禁拖拽 |
| 离线结算 P-NAV-04 Drawer 是否完全可暂停（accessibility 承诺）？涉及"自动消失对话窗 ≥ 5 秒"是否包括 toast | ux-designer | Pre-Production | 未解决；倾向：toast 4s 不算违反，但提供"延长 toast 时长 to 8s"在 settings |
| P-INP-02 Confirm-Critical Modal 的 2 秒倒计时是否被 accessibility "no timed input" 命中？倾向：算"防误点"而非"计时输入"，但需 user testing 验证 | ux-designer + game-designer | Pre-Production | 未解决 |
| 8 阶稀有度形状破框（神话 / 先天 / 混沌）在 P-DAT-04 网格态 96×128 卡片中是否能稳定渲染不视觉抖动？需在 art bible Sec 5 角色 / 物品 art spec 时验证 | art-director | Production | 未解决 |
| `design/player-journey.md` 缺失，部分 pattern 选择（如 onboarding overlay）需要 player journey 提供节奏依据 | producer | Pre-Production | 未解决 — 建议本 sprint 内做 player-journey 草稿 |

---

## Cross-Reference Index

- **art-bible Section 1**：4.5:1 / 1.5:1 对比度法则 → 所有 pattern 的 token 选择
- **art-bible Section 2**：8 状态情绪锚点 → P-FBK-01 toast / P-NAV-03 modal 切换动画
- **art-bible Section 3.3**：UI 形状语法 → 所有 pattern 切角 / 边框 / 不用圆角
- **art-bible Section 3.4**：8 阶稀有度编码 → P-DAT-04 Item Card 边框
- **art-bible Section 3.5**：5 条形状禁区 → P-FBK-02 Chip 不闪烁等约束
- **art-bible Section 4.1–4.3**：Theme token + 语义色 + 稀有度色阶 → 所有 pattern 颜色引用
- **art-bible Section 4.6**：色弱矩阵 + 8 阶 backup → P-DAT-04 角标 / P-NAV-01 锁图标 / P-FBK-02 图标
- **accessibility-requirements**：Standard tier → 全部 pattern 提供键鼠 + 手柄输入 + 色弱 backup
- **ui-framework GDD**：UIManager / register_screen / max_modal_depth / virtual list 公式 → P-NAV-03 / P-DAT-02
- **hud-system GDD**：MVP HUD 元素 / coalesced refresh / battle_log_rows → P-DAT-01 / P-FBK-03
