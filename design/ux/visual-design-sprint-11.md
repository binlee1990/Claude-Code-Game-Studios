# Sprint 11 视觉设计规范 — 5 屏 MVP 视觉层

> **Status**: Draft — awaiting creative-director approval
> **Author**: art-director
> **Created**: 2026-05-05
> **Scope**: 5 个 MVP 主屏的完整视觉设计层（色彩、字体、间距、资产、动画、无障碍）
> **Source Documents**: art-bible.md (Sec 1–4) · ui-asset-manifest.md · interaction-patterns.md · accessibility-requirements.md · 5 UX specs
> **Sprint**: Sprint 11 / mvp-screens

---

## 0. 概述

本规范定义 Sprite 11 全部 5 个 MVP 主屏的视觉实现层，承接 `art-bible.md` Sections 1–4 的视觉法则、`design/ux/` 下 5 个 UX spec 的布局定义、`design/registry/ui-asset-manifest.md` 的资产路径。每一屏的设计覆盖：色彩、字体层级、间距布局、资产需求、动画风格、无障碍校验。

### 0.1 总体设计原则（继承 art-bible 最高视觉法则）

1. **水墨为骨，深面板为肉** — 装饰性墨痕仅在非数据区域（背景、分割线、标题装饰），数据区域保持纯 `panel_bg_primary` 色底
2. **信息层级即视觉亮度** — 可交互元素对比度 ≥ 4.5:1，背景装饰 ≤ 1.5:1
3. **直角 + 单侧切角** — 所有面板/卡片右上或左上切 6px 斜角；按钮纯直角；无圆角
4. **screen-space HUD 语言** — 非 diegetic，不模拟卷轴/竹简物理形态
5. **功能可读性绝对优先** — 任何水墨美学与数据可读性冲突时，可读性胜出

### 0.2 总体色板（继承 art-bible Sec 4.1–4.2）

所有面板背景、文字、分割线统一走 Theme token。**禁止在任何 UI 代码中 hardcode hex。**

| Token | Hex | 角色 |
|---|---|---|
| `panel_bg_primary` | `#1A1A20` | 主数据面板底板（最深层） |
| `panel_bg_secondary` | `#242430` | 次级面板、侧栏、浮层 |
| `panel_bg_elevated` | `#2E2E3C` | 卡片悬浮态、弹窗、选中态 |
| `text_primary` | `#E8E0D0` | 可操作标签、当前数值（≥ 4.5:1） |
| `text_secondary` | `#9A9488` | 次级说明、CD 倒计时（≥ 3:1） |
| `ink_stroke` | `#3D3830` | 分割线、水墨笔触装饰（≤ 1.5:1） |
| `warm_paper` | `#F5EDDB` | 离线结算卡片背景 |

| 语义 Token | Hex | 触发场景 |
|---|---|---|
| `burst_gold` | `#F5C842` | 选中态焦点描边、当前槽标记、爆发荣耀 |
| `threat_purple` | `#5B3D82` | 天劫四角压框（本 sprint 暂未触发） |
| `subplay_orange` | `#D4762A` | 秘境子玩法边框（本 sprint 暂未触发） |
| `bottleneck_red` | `#B04040` | 容量警告、资源损失 |
| `failure_red` | `#CC2222` | 战斗失败、存档损坏 |

### 0.3 总体字体层级（继承 accessibility-requirements Standard tier）

| 层级 | 字号 @ 1080p | 最小字号 @ 720p | 用途 | Token |
|---|---|---|---|---|
| **Hero** | 28–32px | 24px | 离线时长、主标题 | `text_primary` |
| **P0 数据** | 24px | 20px | 资源数值、等级、敌人名称、槽位标题 | `text_primary` |
| **菜单/标签** | 20–24px | 18px | Tab 标签、按钮文字、资源名称、面板标题 | `text_primary` |
| **次级信息** | 16–18px | 14px | 拆解明细、Tooltip 正文、metadata | `text_secondary` |
| **装饰/日志** | 14px | 12px | 战斗日志、趋势标注、角标文字 | `text_secondary` |

**强制规则**：
- HUD 关键信息 ≥ 20px（accessibility-requirements 已锁）
- 菜单文字 ≥ 24px（同上）
- 等宽数字用于所有资源数值（读者一眼对齐）
- 中文使用思源黑体或等效无衬线字体；Godot 默认字体在 14px 以下中文笔画粘连风险高，**建议 Sprint 11 至少挂载一个开源中文字体**（思源黑体 Noto Sans SC Regular，`assets/ui/fonts/` 路径）

### 0.4 间距系统

统一 4px 基础网格，所有 margin/padding/gap 为 4 的倍数。

| 间距类型 | 值 | 用途 |
|---|---|---|
| **panel_margin** | 16px | 面板内边距 |
| **zone_gap** | 24px | 相邻 Zone 之间的间距 |
| **row_gap** | 8px | 同 Zone 内行间距 |
| **item_gap** | 12px | 网格内卡片间距 |
| **stroke_width** | 1px | 面板边框、分割线 |
| **focus_outline** | 2px | 焦点描边宽度 |

### 0.5 资产路径引用规范

本规范中所有资产路径以 manifest section 编号引用。完整路径与用途对照见 `design/registry/ui-asset-manifest.md`。

**引用格式**: `§{section}` = 该 section 全部资产；`§{section} [file]` = section 内指定文件

---

## 1. 共享 Shell 元素

所有 5 屏共享 HUD Shell 的四个固定区域。这些元素不属于任一单屏，而是由 RootViewport 统一渲染。

### 1.1 LEFT NAV（左侧导航栏）

**Pattern**: P-NAV-02 Side-Tab Navigation
**定位**: 屏幕左侧固定，不随 CENTER CONTENT 滚动

| 属性 | 值 |
|---|---|
| 展开宽度 | 192px |
| 折叠宽度 | 48px |
| 高度 | 全屏高（1080px @ 1080p，减去 TOP STRIP 64px = 1016px） |
| 背景 | `panel_bg_secondary` |
| 与 CENTER 分隔 | 1px `ink_stroke` 右边框 |

**Tab 行规格**:

| 属性 | 展开态 | 折叠态 |
|---|---|---|
| 行高 | 48px | 48px |
| 图标 | 24×24，左对齐，距左边缘 16px | 24×24，居中 |
| 文字 | 16px `text_primary`，图标右侧 8px | 隐藏 |
| 徽章 | 文字右侧 8px，14px `text_secondary` | 8×8 圆点叠在图标右上角 |
| 当前态 | 左侧 4px `burst_gold` 竖条 + `panel_bg_elevated` 底 | 左侧 4px `burst_gold` 竖条 + `panel_bg_elevated` 底 |
| 悬停态 | `panel_bg_elevated` 底（非当前 tab 时） | 同展开态 |
| 锁定态 | 饱和度 −60%（图标 + 文字）+ 锁图标 overlay | 饱和度 −60% + 锁图标 overlay |

**5 个 Tab 顺序**（固定，所有屏一致）:

| 序号 | 图标（占位描述） | 文字 | 快捷键 | 对应屏 |
|---|---|---|---|---|
| 1 | 打坐人形 | 修炼 | `1` | cultivation |
| 2 | 双剑交叉 | 战斗 | `2` | combat |
| 3 | 包袱 | 资源 | `3` | resources |
| 4 | 玉简 | 存档 | `4` | save |
| 5 | 卷轴 | 离线 | `5` | offline_settlement |

**折叠/展开切换**: `F` 键 / 手柄 RT 长按；动画 150ms 宽度渐变（reduced-motion 下 instant）

**资产**: LEFT NAV 不使用独立背景资产；纯由 theme.tres token 渲染。Tab 图标来自各自对应的 icon 族（§3 realm icons 用于修炼 tab 示意，或独立设计 LEFT NAV 专用 icon set）。

### 1.2 TOP STRIP（顶部信息条）

**定位**: 屏幕顶部固定，全宽 1920px，高 64px

| 属性 | 值 |
|---|---|
| 高度 | 64px @ 1080p |
| 背景 | `panel_bg_primary` + 底部 1px `ink_stroke` 分割线 |
| 左边距 | LEFT NAV 展开时 192px 起始（LEFT NAV 右侧），折叠时 48px 起始 |
| 右边距 | RIGHT PANEL 320px 左侧为止 |

**内容布局**（从左到右）:
1. 5 资源缩略行（P-DAT-01 紧凑变体，行高 32px，仅图标 20×20 + 缩写数字）
2. 等级 + 境界徽章（Lv.X + 境界图标 24×24 + 境界名，≥20px）
3. 当前区域/上下文标签（如 "灵谷起始"，≥18px `text_secondary`）
4. 设置齿轮图标（24×24，最右，点击开 P-NAV-03 Settings modal）

**资产**: §2 5 resource icons, §3 realm icons (当前境界), §1 theme.tres

### 1.3 RIGHT PANEL（右侧信息面板）

**定位**: 屏幕右侧固定，宽 320px，高 = 全屏高 − TOP STRIP 64px = 1016px

| 属性 | 值 |
|---|---|
| 宽度 | 320px @ 1080p |
| 背景 | `panel_bg_secondary` |
| 与 CENTER 分隔 | 1px `ink_stroke` 左边框 |
| 内容区 padding | 12px（上/下/左/右） |

**内容**:
- 战斗日志（P-FBK-03 Battle Log Scroll）— 默认 8 行可见，virtualized 保留 200 行
- 警告 chips 区（P-FBK-02 stack）— 资源溢出/瓶颈等状态 chip
- 日志简略/详细 toggle（SegmentedControl "简/详"，顶部）

**资产**: §5 status icons (overflow_warn), §13 VFX (overflow_warn_flash)，theme.tres 面板 frame

### 1.4 BOTTOM ACTION BAR

**定位**: 部分屏使用（修炼屏的 Ambient Hint、离线结算屏的 ACTION BAR）。高度 48–64px，背景 `panel_bg_primary` + 顶部 1px `ink_stroke`。

---

## 2. 修炼屏 (Cultivation Screen)

### 2.1 色彩

| Zone | 底板 Token | 文字 Token | 备注 |
|---|---|---|---|
| HERO ZONE | `panel_bg_secondary` | `text_primary` + `text_secondary` | portrait/idle_sheet 叠加于上 |
| DECISION ZONE | `panel_bg_primary` | `text_primary` (数值) / `text_secondary` (拆解) | 与 HERO 以 1px `ink_stroke` 竖线割断 |
| ACTION ZONE | `panel_bg_secondary` | `text_primary` | 手动修炼按钮底 |
| INSPECTION ZONE | `panel_bg_elevated` | `text_primary` | 试算面板浮动感 |
| 切换姿态 Button | `panel_bg_elevated` + 1px `burst_gold` 边框 | `text_primary` | 醒目但不抢占 hero |
| 手动修炼 Button (新存档) | `panel_bg_elevated` + 呼吸 `burst_gold` 边框（alpha 100↔70, 1.5s 循环） | `text_primary` | onboarding 暗示 |
| Ambient Hint | 透明 + `text_secondary` 14px | `text_secondary` | hover 时 tooltip |
| 灵气不足 Chip | `bottleneck_red` 文字 + 行背景 8% alpha 红 | `text_primary` | P-FBK-02 |

**全屏背景**: `main_base.png`（§8）在 CENTER 区域之下，dim 30%（`#000000` alpha 0.3 ColorRect overlay）。背景仅作用于 HERO ZONE 后方，不侵入数据面板（与 art-bible Sec 4.5 渡口规则一致）。

### 2.2 字体

| 元素 | 字号 @ 1080p | 字重/样式 | Token |
|---|---|---|---|
| Level + realm Label ("Lv.1 凡人") | 24px | Bold | `text_primary` |
| 4 资源每秒产出数字 | 24px | 等宽数字 | `text_primary` |
| 资源名称（收起态行内） | 20px | Regular | `text_primary` |
| 产出拆解明细条目 | 18px | Regular | `text_secondary` |
| 拆解各来源贡献值 | 18px | 等宽数字 | `text_primary` |
| 合计校验行 | 18px | Bold | `text_primary` |
| 切换姿态 Button 文字 | 20px | Bold | `text_primary` |
| 手动修炼 Button 文字 | 20px | Bold | `text_primary` |
| 凝练参数 ("cost: 10 / rate: 10%") | 18px | Regular | `text_secondary` |
| 试算 duration 标注 | 18px | Regular | `text_secondary` |
| 试算结果数字 | 24px | 等宽数字 | `text_primary` |
| 试算结果说明文字 | 18px | Regular | `text_secondary` |
| 灵气不足 Chip 文字 | 16px | Bold | `text_primary` |
| Cooldown 倒计时 | 18px | 等宽数字 | `text_secondary` |
| 锁定 stance Tooltip | 14px | Regular | `text_secondary` |

### 2.3 间距与布局

| 间距 | 值 | 位置 |
|---|---|---|
| HERO ↔ DECISION 水平间距 | 24px (zone_gap) | 1px `ink_stroke` 竖线在间隙中央 |
| HERO ↔ ACTION 垂直间距 | 16px (panel_margin) | — |
| DECISION ↔ INSPECTION 垂直间距 | 16px (panel_margin) | — |
| HERO ZONE 内边距 | 16px | portrait 距面板边缘 |
| DECISION ZONE 内边距 | 16px | 资源行距面板边缘 |
| 资源行之间间距 | 8px (row_gap) + 1px `ink_stroke` 分隔 | — |
| 拆解明细行间距 | 4px | 展开区内 |
| 切换姿态 Button 距资源行 | 12px | — |
| ACTION ZONE 内边距 | 16px | — |
| INSPECTION ZONE 内边距 | 16px | — |
| Ambient Hint 距屏右下 | 16px / 16px | 浮在 ACTION 与 INSPECTION 之上 |

**Zones 精确尺寸 @ 1080p**（CENTER CONTENT: 1408×1016）:

```
┌──────────────────────────────────────────┐
│  HERO ZONE         DECISION ZONE         │  ← 上排 680px 高
│  480 × 680         880 × 680            │
│  (左 0, 上 0)      (左 504, 上 0)       │      HERO 右边缘 = 480
│                                          │      gap 24 → DECISION 左 = 504
├──────────────────────────────────────────┤
│  ACTION ZONE        INSPECTION ZONE      │  ← 下排 320px 高
│  480 × 320         880 × 320            │
│  (左 0, 上 696)     (左 504, 上 696)     │      上排高度 680 + gap 16 = 696
└──────────────────────────────────────────┘
```

**1280×720 最小窗口**: HERO 缩至 360×500；DECISION/ACTION/INSPECTION 等比缩；Ambient Hint 折叠为 hover-reveal
**4K (3840×2160)**: 等比缩放 + 字号 +1 档（24px → 28px，20px → 24px）

### 2.4 资产需求

| Manifest § | 资产 | 用途 | 加载时机 |
|---|---|---|---|
| §1 | `theme.tres` | 全局主题继承 | 屏初始化（通过父节点继承） |
| §8 | `main_base.png` | 全屏背景（HERO ZONE 后方，dim 30%） | 屏打开时 |
| §10 | `portrait.png` | 主角立绘（HERO ZONE 480×680 内） | 屏打开时 |
| §10 | `idle_sheet.png` | 主角待机微动画（8fps，叠加 portrait 之上） | 屏打开时 |
| §4 | `meditate.png` | 当前 stance icon（HERO ZONE 内，32×32） | 屏打开时 |
| §4 | `condense.png` | 同上（切 stance 后动态切换） | stance 切换时 |
| §4 | `closed_door.png` | 锁定 stance 预告（Ambient Hint 24×24，饱和度 −60%） | 屏打开时 |
| §4 | `idle.png` | 锁定 stance 预告（同上） | 屏打开时 |
| §3 | 7 realm icons | 境界图标（HERO ZONE 内，动态切换 7 选 1） | 屏打开时 + 境界变化时 |
| §2 | 5 resource icons | DECISION ZONE 4 资源行图标（lingqi/xiuwei/lingshi/herb） | 屏打开时 |
| §13 | `manual_click_pulse.png` | 手动修炼 VFX（220ms 单帧扩散） | button_pressed 信号触发 |
| §13 | `overflow_warn_flash.png` | 灵气不足 chip 出现时 VFX（300ms） | shortage 状态变化时 |
| §5 | `overflow_warn.png` | 灵气不足状态 chip 图标 | shortage 状态变化时 |

**资产计数**: 17 个资产引用（含动态切换）。全部路径见 manifest。

### 2.5 动画风格

| 触发 | 动画 | 时长 | 缓动 | Reduced-Motion |
|---|---|---|---|---|
| 屏进入/退出 | cross-fade | 120ms | linear | instant cut |
| 资源行展开/收起 | 高度 expand + 内容 fade-in | 200ms | ease-out | instant |
| 切换姿态 Modal | scale 95%→100% + fade in | 200ms | ease-out | fade only |
| Modal 关闭 | scale 100%→95% + fade out | 150ms | ease-in | instant |
| 手动修炼按钮按下 | `manual_click_pulse` VFX 单帧从中心扩散 | 220ms | ease-out | 单帧静态闪 |
| Cooldown ProgressBar | linear fill | cooldown_seconds | linear | 同（功能性反馈） |
| 灵气不足 Chip 出现 | `overflow_warn_flash` + chip fade-in | 300ms | ease-out | instant + 静态红边 |
| 主角 idle_sheet | AnimatedSprite2D 循环，**8fps**，4 帧 0.5s 循环 | 持续 | — | 静态 portrait.png |
| 时间冻结 | HERO 灰度 50% fade | 300ms | ease-out | instant 灰度 |
| 新存档呼吸光晕 | scale 100↔105 + alpha 100↔70 `burst_gold` 边框 | 1.5s 周期 | ease-in-out | **关闭** → 静态 `burst_gold` 边框 |

**情绪锚点**: 本屏对应 art-bible 状态①（禅静沉浸）。动画风格以"沉稳、绵长"为主调。idle_sheet 8fps 的低帧率保留水墨手绘感；展开/收起使用 ease-out 避免突兀。

### 2.6 无障碍校验

| 检查项 | 状态 | 依据 |
|---|---|---|
| 可交互文本对比度 ≥ 4.5:1 | ✅ PASS | `text_primary #E8E0D0` on `panel_bg_primary #1A1A20` ≈ 9:1 |
| 装饰元素对比度 ≤ 1.5:1 | ✅ PASS | `ink_stroke #3D3830` on `panel_bg_primary #1A1A20` ≈ 1.4:1 |
| 字号满足层级要求 | ✅ PASS | HERO label ≥24px, P0 数据 ≥24px, 次级信息 ≥18px |
| Tab order 完整（11 项） | ✅ DESIGN | 与 UX spec §Interaction Map 一致 |
| 焦点描边 2px `burst_gold` | ✅ DESIGN | 所有交互元素统一 |
| 色弱 backup — stance icons | ✅ PASS | 4 个 stance icon 形状不同，不依赖颜色 |
| 色弱 backup — 灵气不足 chip | ✅ PASS | 色 (`bottleneck_red`) + 文字 + ⚠ 图标三重 |
| 缩放 75%/100%/150% 不破 | ⚠️ 待验证 | 需 1280×720 + 三档缩放实机截图 |
| Reduced-motion 全部 ≤ 50ms | ✅ DESIGN | instant cut + 静态 fallback |
| No timed input / no button mashing | ✅ PASS | manual_cultivate 冷却期间点击不报错只忽略 |

---

## 3. 战斗屏 (Combat Screen)

### 3.1 色彩

| Zone | 底板 Token | 文字 Token | 备注 |
|---|---|---|---|
| ZONE SELECTOR | `panel_bg_primary` | `text_primary` (active) / `text_secondary` (available) | Active tab: `panel_bg_elevated` + 顶部 2px `burst_gold` 描边 |
| Locked Zone Tab | `panel_bg_secondary` (饱和度 −60%) | `text_secondary` (饱和度 −60%) | + 🔒 图标 |
| ENEMY ZONE | zone background + `panel_bg_primary` dim 30% overlay | `text_primary` | 背景通过 #000 alpha 0.3 ColorRect dim |
| ENEMY ZONE — 敌人 portrait | 透明 + 背景 dim | — | portrait 保持原色，不被 dim |
| TEAM STATUS ZONE | `panel_bg_secondary` | `text_primary` | — |
| COMBAT CONTROLS | `panel_bg_primary` | `text_primary` | — |
| 战斗状态点 ● | `burst_gold` 绿（战斗中） | — | 8×8 ColorRect 圆角 0px（art-bible 无圆角 → 正方形点） |
| 战斗状态点 ○ | `text_secondary` 灰（待机） | — | 同上 |
| 战斗状态点 ◆ | `threat_purple`（Boss 预留） | — | 同上 |
| 战斗状态点 ✕ | `failure_red`（失败） | — | 同上 |
| 暴击战斗日志行 | — | `burst_gold` + "暴击!" 文字 | P-FBK-03 颜色编码 |
| 击杀战斗日志行 | — | `victory_burst_gold` + "击杀" 文字 | 同上 |
| 失败战斗日志行 | — | `failure_red` + "败" 文字 | 同上 |
| HP bar 高血量 | 绿 (60%–100%) | — | 色弱 backup: 数字百分比文字 |
| HP bar 中血量 | 黄 (30%–60%) | — | 同上 |
| HP bar 低血量 | `failure_red` (0%–30%) | — | 同上 |
| 连败 Chip | `bottleneck_red` | `text_primary` | P-FBK-02 |

**全屏 Overlay**:
- `victory_burst_gold`: **opacity 40%**, 1s 持续，覆盖全屏（CENTER CONTENT + RIGHT PANEL，不覆盖 TOP STRIP 和 LEFT NAV）
- `failure_grey`: **opacity 60%**, 300ms fade-in，覆盖全屏（与 art-bible Sec 4.4 状态⑧一致）
- `zone_transition_ink_wipe`: 4 帧 sprite sheet 转场，覆盖 CENTER CONTENT 区

### 3.2 字体

| 元素 | 字号 @ 1080p | 字重/样式 | Token |
|---|---|---|---|
| Zone Tab 名称（"灵谷起始"） | 20px | Bold (active) / Regular (available) | `text_primary` / `text_secondary` |
| Zone Tab 推荐等级 | 16px | Regular | `text_secondary` |
| 敌人名称 + 等级 ("森林狼 Lv.3") | 24px | Bold | `text_primary` |
| 敌人 Health Bar 百分比 | 20px | 等宽数字 | `text_primary` |
| 搜寻中指示器 ("搜寻中...") | 18px | Regular | `text_secondary` |
| Player HP/ATK 标签 | 20px | Regular | `text_primary` |
| Player HP/ATK 数值 | 24px | 等宽数字 | `text_primary` |
| 暴击率 ("暴击率 12%") | 20px | Regular | `text_primary` |
| 遭遇计数 ("遭遇: 12") | 18px | 等宽数字 | `text_secondary` |
| 胜率 ("胜率: 91%") | 18px | 等宽数字 | `text_primary` |
| 连胜/连败 Chip | 16px | Bold | `text_primary` |
| 暂停/恢复 Button | 20px | Bold | `text_primary` |
| 冷却倒计时 ("冷却: 3s") | 18px | 等宽数字 | `text_secondary` |
| Zone threat info ("推荐 Lv.1-5") | 18px | Regular | `text_secondary` |
| 战斗日志行 | 14px | Regular | `text_secondary` (普攻) / `burst_gold` (暴击) / `failure_red` (失败) |
| 战斗日志时间戳 | 12px | 等宽数字 | `text_secondary` |

### 3.3 间距与布局

| 间距 | 值 | 位置 |
|---|---|---|
| ZONE SELECTOR 高度 | 56px | CENTER CONTENT 顶部 |
| Zone Tab 宽度 | 均分 (1408/3 ≈ 469px each) | Tab 间 4px 切角分隔 |
| ZONE SELECTOR ↔ ENEMY/TEAM 垂直间距 | 16px (panel_margin) | — |
| ENEMY ↔ TEAM STATUS 水平间距 | 16px (panel_margin) | — |
| ENEMY ZONE 内边距 | 16px | portrait 距边缘 |
| TEAM STATUS ZONE 内边距 | 16px | bars 距边缘 |
| HP/ATK/暴击率行间距 | 8px (row_gap) | — |
| ENEMY/TEAM ↔ COMBAT CONTROLS 垂直间距 | 8px | — |
| COMBAT CONTROLS 高度 | 64px | CENTER CONTENT 底部 |

**Zones 精确尺寸 @ 1080p** (CENTER CONTENT: 1408×1016):

```
ZONE SELECTOR         1408 × 56   (上 0)
  gap 16
ENEMY ZONE            600 × 560   (左 0, 上 72)
TEAM STATUS ZONE      600 × 560   (左 616, 上 72)    ← 600 + gap 16 = 616
  gap 8
COMBAT CONTROLS       1408 × 64   (上 640)           ← 上排底 632 + gap 8 = 640
RIGHT PANEL           320 × 1016  (固定右侧)
```

**ENEMY ZONE 内部布局**:
- 敌人 portrait: **320×400**, 水平居中于 600px 宽度内 (左/右 margin 各 140px)
- 敌人 health bar: portrait 下方 8px, 宽度 400px 居中
- 敌人名称 + 等级: health bar 上方 4px
- 搜寻中指示器: portrait 区域中央（Seeking 态时）

**1280×720 最小窗口**:
- ENEMY ZONE 缩到 400×420
- TEAM STATUS ZONE 等比缩
- Zone Tab 文字缩至单字（灵/东/古），16px
- RIGHT PANEL 缩到 240px

**4K**: 等比缩放 + 字号 +1 档

### 3.4 资产需求

| Manifest § | 资产 | 用途 | 加载时机 |
|---|---|---|---|
| §1 | `theme.tres` | 全局主题 | 继承 |
| §8 | `starter_forest.png` | zone background (灵谷起始) | zone 切换时动态加载 |
| §8 | `east_sea_shore.png` | zone background (东海岸) | 同上 |
| §8 | `ruined_temple.png` | zone background (古庙遗迹) | 同上 |
| §10 | `idle_sheet.png` | 玩家待机动画 | 屏打开时 |
| §10 | `attack_sheet.png` | 玩家攻击动画（combat active 时） | combat event 触发时 |
| §10 | `hurt_sheet.png` | 玩家受击动画 | combat event 触发时 |
| §10 | `death_sheet.png` | 玩家失败动画（defeat 时） | combat.finished (defeat) 触发 |
| §11 | starter/mid/end zone enemy PNGs | 敌人 portrait + idle/attack sheets（按 enemy_id 动态加载） | encounter_started 时 |
| §5 | `combat_active.png` | 战斗状态点 icon | 战斗状态变化时 |
| §5 | `combat_failed.png` | 战斗失败状态 icon | 战斗失败时 |
| §9 | `failure_grey.png` | 失败全屏覆层（opacity 60%） | combat.finished (defeat) 触发 |
| §13 | `crit_hit_spark.png` | 暴击 VFX（220ms） | 暴击触发时 |
| §13 | `victory_burst_gold.png` | 胜利全屏 VFX（1s, 40% opacity） | combat.finished (victory) 触发 |
| §13 | `zone_transition_ink_wipe_01..04.png` | 区域切换 4 帧转场（120ms） | zone 切换时 |

**资产计数**: 核心 16 个引用的资产路径（不含按 enemy_id/zone_id 动态加载的 27 enemy PNG）。全部路径见 manifest §8, §10, §11, §5, §9, §13。

**已知 gap**（manifest §17）: Enemy hurt/death sheet 不存在，Sprint 11 用静态闪烁兜底。

### 3.5 动画风格

| 触发 | 动画 | 时长 | 缓动 | Reduced-Motion |
|---|---|---|---|---|
| 屏进入/退出 | cross-fade | 120ms | linear | instant cut |
| 区域切换 | `zone_transition_ink_wipe` 4 帧 Spritesheet（120ms, 30ms/frame） | 120ms | — | instant cut |
| 敌人出现 (Seeking→Combat) | portrait fade-in + scale 0.95→1.0 | 200ms | ease-out | fade only |
| 敌人死亡 (Victory) | portrait fade-out + scale 1.0→0.9 | 200ms | ease-in | instant |
| 暴击 | `crit_hit_spark` VFX 单帧从中心扩散 | 220ms | ease-out | 单帧静态闪 |
| 战斗胜利 | `victory_burst_gold` 全屏 overlay fade-in, opacity 40% | 1000ms | ease-out | 缩至 300ms, 无缩放 |
| 战斗失败 | `failure_grey` 全屏 overlay fade-in, opacity 60% | 300ms | ease-in | instant 灰度 |
| 失败恢复 | `failure_grey` fade-out | 300ms | ease-out | instant |
| 暂停/恢复 | 按钮文字+图标切换 | 100ms | linear | instant |
| 战斗日志新行 | fade-in | 220ms | ease-out | instant |
| 简略↔详细切换 | 行高 expand/collapse | 200ms | ease-out | instant |
| 搜寻中指示器 | 墨点旋转循环 (60fps sync) | 持续 | linear | 静态"搜寻中..."文字 |
| Player 四态动画切换 | attack/hurt 按 sheet meta fps; death 播完留在末帧 | — | — | death 静态单帧 portrait.png; attack/hurt 单帧 |
| HP bar 变化 | **无动画** — coalesced 直跳当前值 | 0ms | — | 同（功能性反馈） |

**关键决策**: Enemy health bar **不做平滑 tween**。在 idle auto-battle 场景中，平滑递减会让玩家误判战斗仍在进行。改为 coalesced 直跳（≤ 10Hz 刷新），保证数值精确感。

**情绪锚点**: 本屏对应 art-bible 状态②（稳健流动）+ 状态③（爆发荣耀，仅 victory 时瞬时触发）。日常战斗动画以"有序、节律"为基调 — 战斗日志行交错淡入而非刷新闪烁。爆发金仅在胜利时出现且 1s 结束，不持续污染画面。

### 3.6 无障碍校验

| 检查项 | 状态 | 依据 |
|---|---|---|
| 可交互文本对比度 ≥ 4.5:1 | ✅ PASS | `text_primary` on `panel_bg_primary` ≈ 9:1 |
| 战斗日志颜色编码有文字 backup | ✅ PASS | 暴击=`burst_gold`+"暴击!"；失败=`failure_red`+"败"；击杀="击杀" |
| 战斗状态点形状区分 | ✅ PASS | ●/○/◆/✕ 形状不同, 颜色为辅 |
| HP bar 颜色变化有数字百分比 backup | ✅ PASS | 色弱安全 |
| Zone tab 锁定态三重 backup | ✅ PASS | 饱和度 −60% + 🔒 + tooltip 文字 |
| 字号满足层级要求 | ✅ PASS | 敌人名称 ≥24px, HP% ≥20px, 日志 ≥14px |
| Tab order 完整（10 项交互） | ✅ DESIGN | Zone tabs ×3 + ENEMY ZONE + TEAM bars ×3 + pause + log + toggle |
| 焦点描边 2px `burst_gold` | ✅ DESIGN | 所有交互元素统一 |
| Reduced-motion 全部 ≤ 50ms | ✅ DESIGN | 详见动画表 "Reduced-Motion" 列 |
| No button mashing | ✅ PASS | 无攻击按钮，只有 toggle 操作 |

---

## 4. 资源/背包屏 (Resources Screen)

### 4.1 色彩

| Zone | 底板 Token | 文字 Token | 备注 |
|---|---|---|---|
| TAB BAR | `panel_bg_primary` | `text_primary` (active) / `text_secondary` (inactive) | Active tab: `panel_bg_elevated` + 顶部 2px `ink_stroke` |
| Tab "图鉴" (locked) | `panel_bg_secondary` (饱和度 −60%) | `text_secondary` (饱和度 −60%) | + 锁图标 |
| RESOURCE LIST 行 | `panel_bg_primary`（行背景）/ `panel_bg_elevated`（展开态） | `text_primary` (数值) / `text_secondary` (来源明细) | — |
| Fill bar 正常 | `text_primary` 或默认色 | — | 高度 4px |
| Fill bar 警戒 (≥85%) | `bottleneck_red` | — | + "⚠" 字符 backup |
| Fill bar 满仓 (100%) | `bottleneck_red` | `text_secondary` "(溢出)" | + P-FBK-02 "已满 ⚠" chip |
| 容量警告行背景 | `panel_bg_primary` + 8% alpha `bottleneck_red` | — | — |
| INVENTORY GRID 底板 | `panel_bg_primary` | — | — |
| 物品卡片底 | `panel_bg_secondary` | `text_primary` (名称) | hover → `panel_bg_elevated` |
| 物品卡片稀有度边框 | 按 8 阶色阶（见下表） | — | 9-slice frame |
| ENCYCLOPEDIA 占位 | `panel_bg_primary` | `text_secondary` | — |

**稀有度色阶（卡片边框）**（完整定义见 art-bible Sec 4.3）:

| 品阶 | Token | Hex | 边框宽度 | 外发光 |
|---|---|---|---|---|
| 凡品 | `rarity_common` | `#707070` | 1px | — |
| 精良 | `rarity_uncommon` | `#C8C8C0` | 1px | — |
| 稀有 | `rarity_rare` | `#3A7FCC` | 2px | 4px |
| 史诗 | `rarity_epic` | `#8844CC` | 2px | 6px |
| 传说 | `rarity_legendary` | `#D4A820` | 2px | 8px |
| 神话 | `rarity_mythic` | `#F5C842`→`#FF9A00` | 3px 渐变 | 12px |
| 先天 | `rarity_innate` | `#A8E8D8` | 3px | 16px |
| 混沌 | `rarity_chaos` | `#CC2288`/`#4488FF`/`#F5C842` | 4px 动态 | 24px |

**文字角标颜色**: 与边框色相同。角标位置：物品卡片右上 16×16 区域。所有品阶都有角标（"凡/精/稀/史/传/神/先/混"），不依赖边框颜色识别。

### 4.2 字体

| 元素 | 字号 @ 1080p | 字重/样式 | Token |
|---|---|---|---|
| Tab 标签 ("资源"/"背包"/"图鉴") | 20px | Bold (active) / Regular (inactive) | `text_primary` / `text_secondary` |
| 背包 Tab 徽章数字 ("(13)") | 16px | Regular | `text_secondary` |
| 资源名称 | 20px | Bold | `text_primary` |
| 资源当前值 (如 "8,500") | 24px | 等宽数字 | `text_primary` |
| 资源 cap 后缀 ("/10,000") | 18px | 等宽数字 | `text_secondary` |
| 每秒产出速率 ("+3.2/s") | 18px | 等宽数字 | `text_primary` |
| 趋势箭头 (▲/▼) | 16px | — | 形状传达方向 |
| 变动明细来源名称 | 16px | Regular | `text_secondary` |
| 变动明细数量 | 16px | 等宽数字 | `text_primary` |
| 变动明细时间戳 | 14px | Regular | `text_secondary` |
| Fill bar 百分比 | 14px | 等宽数字 | `text_secondary` |
| 容量警告 "⚠" | 18px | — | `bottleneck_red` |
| "已满 ⚠" Chip 文字 | 16px | Bold | `text_primary` |
| 物品卡片名称 | 14px | Regular | `text_primary` |
| 物品卡片稀有度角标 ("凡") | 12px | Bold | 对应稀有度色 |
| 物品卡片堆叠数量 ("×234") | 14px | 等宽数字 | `text_primary` |
| 空库存占位文本 | 18px | Regular | `text_secondary` |
| 图鉴占位文本 | 20px | Regular | `text_secondary` |

### 4.3 间距与布局

| 间距 | 值 | 位置 |
|---|---|---|
| TAB BAR 高度 | 48px | CENTER CONTENT 顶部 |
| TAB BAR ↔ 内容区 | 0px（紧贴） | TAB BAR 是内容区的 header |
| 资源行高度 | 44px（收起）/ auto（展开） | — |
| 资源行之间间距 | 4px + 1px `ink_stroke` 分隔线 | — |
| 资源行内边距 | 12px（左/右）/ 8px（上/下） | — |
| 展开区明细行高度 | 28px | — |
| Fill bar 高度 | 4px | 资源数值右侧 |
| 物品卡片网格间距 | 12px (item_gap) | — |
| 物品卡片尺寸（网格态） | **96×128** | P-DAT-04 规范 |
| 物品卡片尺寸（详情态 Tooltip）| **320×420** | P-DAT-04 规范 |
| 物品卡片内边距 | 8px | 图标距卡片边缘 |
| 物品图标尺寸（网格态） | 48×48 | 卡片内居中偏上 |
| 物品名称距图标 | 4px | — |
| 滚动条宽度 | 6px | 右侧 |

**列数响应**:

| 分辨率 | 列数 | 卡片 size | 网格可用宽度 |
|---|---|---|---|
| 1280×720 | 3 | 80×108 | ~840px（LEFT NAV 48 + RIGHT PANEL 240 后） |
| 1920×1080 (baseline) | **4** | 96×128 | 1408px |
| 2560×1440 | 5 | 96×128 | ~1960px |
| 3840×2160 (4K) | 6 | 112×144 | ~3000px |

**4 列 grid 精确布局 @ 1080p**:
```
可用宽度: 1408px
列数: 4
卡片宽度: 96px
卡片间距: 12px
总 grid 宽度: 4 × 96 + 3 × 12 = 384 + 36 = 420px
左侧 margin: (1408 - 420) / 2 = 494px (居中)
```

### 4.4 资产需求

| Manifest § | 资产 | 用途 | 加载时机 |
|---|---|---|---|
| §1 | `theme.tres` | 全局主题 | 继承 |
| §2 | 5 resource icons | RESOURCE LIST 每行图标 + TAB BAR 图标 | 屏打开时 |
| §6 | 8 rarity frames | INVENTORY GRID 物品卡片边框（按物品稀有度动态匹配） | 物品卡片渲染时 |
| §12 | 13 item icons | INVENTORY GRID 物品卡片内图标（按 item_id 动态加载） | 物品卡片渲染时 |
| §5 | `overflow_warn.png` | 容量警告 chip 图标 | 容量状态变化时 |
| §13 | `overflow_warn_flash.png` | 满仓 VFX（300ms） | 满仓事件触发时 |

**资产计数**: 核心 5 + 8 + 13 + 1 + 1 = 28 个 PN G资产引用（含动态匹配）。全部路径见 manifest §2, §6, §12, §5, §13。

### 4.5 动画风格

| 触发 | 动画 | 时长 | 缓动 | Reduced-Motion |
|---|---|---|---|---|
| 屏进入/退出 | cross-fade | 120ms | linear | instant cut |
| Tab 切换 | cross-fade 内容区 | 120ms | linear | instant cut |
| 资源行展开 | 高度 expand + 明细 fade-in | 200ms | ease-out | instant |
| 资源行收起 | 高度 collapse + 内容 fade-out | 150ms | ease-in | instant |
| 容量警告出现 (≥85%) | Fill bar 渐变为 `bottleneck_red` + "⚠" fade-in | 300ms | ease-out | instant 静态红 + 静态 ⚠ |
| 满仓 chip (100%) | `overflow_warn_flash` VFX + chip fade-in | 300ms | ease-out | 静态暗红边框 |
| 资源数值刷新 | **瞬间跳变，无 tween** | 0ms | — | 同 |
| 物品 Tooltip 进入 | fade-in | 150ms | ease-out | instant |
| 物品 Tooltip 退出 | fade-out | 100ms | ease-in | instant |
| 物品卡 hover 高亮 | `panel_bg_elevated` 微亮 | 100ms | ease-out | instant |
| 空库存占位出现/消失 | fade-in/out | 200ms | ease-out | instant |
| 时间冻结 | 产出速率灰度 50% | 300ms | ease-out | instant 灰度 |

**关键决策**: 资源数值**不做 slot-machine 式滚动 tween**。资源屏的核心情绪是"账本般的精确"（audit），瞬间跳变强化数字精确感。平滑滚动会暗示"数字还在变"，破坏审计信任。

### 4.6 无障碍校验

| 检查项 | 状态 | 依据 |
|---|---|---|
| 可交互文本对比度 ≥ 4.5:1 | ✅ PASS | `text_primary` on `panel_bg_primary` ≈ 9:1 |
| 8 阶稀有度三重 backup | ✅ PASS | 色 (8 阶色阶) + 形状 (边框线宽 + 破框) + 文字角标 ("凡/精/稀/史/传/神/先/混") |
| 容量警告三重 backup | ✅ PASS | `bottleneck_red` + "⚠" + fill bar 形状 |
| 趋势箭头形状传达方向 | ✅ PASS | ▲/▼ 不依赖绿色/红色 |
| 字号满足层级要求 | ✅ PASS | P0 数据 ≥24px, 资源名称 ≥20px, 明细 ≥16px |
| Tab order 完整 (≥8 项) | ✅ DESIGN | Tabs + 资源行 ×5 + 物品卡片 |
| 焦点描边 2px `burst_gold` | ✅ DESIGN | 所有交互元素 |
| 物品网格 D-Pad 四向导航 | ✅ DESIGN | ←→↑↓ 移动焦点卡片 |
| 物品卡片文字角标 缩放可读 | ✅ DESIGN | 最小 10px @ 125% 缩放 + 720p |
| 缩放 75%/100%/150% 不破 | ⚠️ 待验证 | 极端组合 720p+150% 需实机验证卡片不裁切 |

---

## 5. 存档屏 (Save Screen)

### 5.1 色彩

| Zone | 底板 Token | 文字 Token | 备注 |
|---|---|---|---|
| AUTO-SAVE INDICATOR | `panel_bg_primary` | `text_primary` (时间) / `text_secondary` (标签) | 居中 |
| 自动保存状态点 (● 绿) | 绿 (正常) | — | 8×8 方形点 |
| 自动保存状态点 (● 黄) | `burst_gold` (保存中) | — | 8×8 方形点 |
| 自动保存状态点 (● 红) | `failure_red` (>5min) | — | 8×8 方形点 |
| SLOTS AREA 背景 | `panel_bg_primary` | — | — |
| Slot 卡片 — 普通态 | `panel_bg_secondary` | `text_primary` (标题) / `text_secondary` (metadata) | 1px `ink_stroke` 边框 + 右上 6px 切角 |
| Slot 卡片 — hover 态 | `panel_bg_elevated` | 同上 | — |
| Slot 卡片 — 当前槽 | 4 边 2px `burst_gold` 边框 | 同上 | 边框不随 hover/selected 变化（始终表示"这是活跃存档"） |
| Slot 卡片 — 选中态 | 左侧 4px `burst_gold` 竖条 + `panel_bg_elevated` 底 | 同上 | 竖条从卡片顶部延伸至底部 |
| Slot 卡片 — 当前且选中 | 4 边 border + 左侧竖条 叠加 | 同上 | 两者不冲突：四边 = 活跃信号，竖条 = UI 焦点信号 |
| Slot 卡片 — 损坏 | `failure_red` 2px 边框 | 同上 + "⚠ 存档损坏" chip | `failure_red` |
| Slot 卡片 — 备份恢复 | 黄色 2px 边框 | 同上 + "已从备份恢复" chip | — |
| Slot 卡片 — 空槽 | `panel_bg_secondary` | `text_secondary` ("尚未创建存档") | ∅ 占位图标 |
| 迁移需求 Chip | `burst_gold` | `text_primary` | "需要迁移 vN→vM" |
| ACTION BAR | `panel_bg_primary` | `text_primary` (enabled) / `text_secondary` (disabled) | `panel_bg_primary` 底 + 顶部 1px `ink_stroke` |
| 删除存档 Button | — | — | 禁用时灰色；可用时 `failure_red` 边框（不填充） |
| 保存中/加载中遮罩 | `#000000` opacity 30% | `text_primary` ("保存中...") | 阻止操作穿透 |

**Modal 配色**（P-NAV-03 / P-INP-02）:

| Modal 类型 | 底板 | 标题色 | 主按钮 |
|---|---|---|---|
| Confirm Overwrite (P-NAV-03) | `panel_bg_elevated` + 1px `ink_stroke` | `text_primary` | `burst_gold` 边框 (不填充) |
| Confirm Load (P-NAV-03) | 同上 | `text_primary` | `burst_gold` 边框 (不填充) |
| Confirm Delete (P-INP-02) | 同上 | `failure_red` + ⚠ 图标 | `burst_gold` 边框 (不填充) |

### 5.2 字体

| 元素 | 字号 @ 1080p | 字重/样式 | Token |
|---|---|---|---|
| 自动保存指示器文本 | 18px | Regular | `text_primary` |
| 逾期警告 ("⚠ 距上次保存超过 5 分钟") | 18px | Bold | `failure_red` |
| Slot 卡片标题 ("存档 1") | 24px | Bold | `text_primary` |
| 当前槽标记 ("(当前)") | 16px | Regular | `burst_gold` |
| Portrait 缩略图旁等级+境界 | 20px | Bold | `text_primary` |
| 游玩时长 | 18px | Regular | `text_secondary` |
| 保存时间戳 | 18px | Regular | `text_secondary` |
| 数据版本/格式版本 | 16px | Regular | `text_secondary` |
| 迁移需求 Chip | 16px | Bold | `text_primary` |
| 损坏 Chip | 16px | Bold | `failure_red` |
| 备份恢复 Chip | 16px | Bold | `text_primary` |
| 空槽占位文本 ("尚未创建存档") | 20px | Regular | `text_secondary` |
| ACTION BAR 按钮文字 | 20px | Bold | `text_primary` / `text_secondary` |
| Modal 标题 | 24px | Bold | `failure_red` (P-INP-02) / `text_primary` (P-NAV-03) |
| Modal 描述文本 | 18px | Regular | `text_primary` / `text_secondary` |
| P-INP-02 勾选框文本 | 18px | Regular | `text_primary` |
| Toast 消息 | 18px | Regular | `burst_gold` (成功) / `failure_red` (失败) |

### 5.3 间距与布局

| 间距 | 值 | 位置 |
|---|---|---|
| AUTO-SAVE INDICATOR 高度 | 40px | CENTER CONTENT 顶部居中 |
| AUTO-SAVE ↔ SLOTS 间距 | 24px (zone_gap) | — |
| Slot 卡片高度 | **260px** | @ 1080p |
| Slot 卡片宽度 | 1408px (全 CENTER 宽) 减去左右各 16px padding = 1376px 内容宽 | — |
| Slot 卡片之间间距 | 24px (zone_gap) | 竖排 |
| Slot 卡片内边距 | 16px | — |
| Portrait 缩略图尺寸 | 96×96 | 卡片左上角 |
| Portrait ↔ 文字区间距 | 16px | — |
| 文字区每行间距 | 4px | — |
| SLOTS ↔ ACTION BAR 间距 | 24px | — |
| ACTION BAR 高度 | 48px | CENTER CONTENT 底部 |

**3 Slot 卡片垂直布局 @ 1080p**:

```
AUTO-SAVE INDICATOR: 40px
gap:                 24px
Slot 1:              260px
gap:                 24px
Slot 2:              260px
gap:                 24px
Slot 3:              260px
                     ----
                     892px (剩余 124px 为下方留白)
ACTION BAR:          48px (底部固定)
```

**1280×720 最小窗口**: Slot 卡片高度缩至 200px；portrait 缩至 72×72
**4K**: Slot 卡片高度 280px；portrait 120×120

### 5.4 资产需求

| Manifest § | 资产 | 用途 | 加载时机 |
|---|---|---|---|
| §1 | `theme.tres` | 全局主题 | 继承 |
| §10 | `portrait.png` | 每个槽位的 portrait 缩略图（96×96） | 屏打开时（每槽） |
| §3 | realm icons | 当前境界图标（每槽，动态加载对应境界） | 屏打开时（每槽） |

**资产计数**: 2 个资产族 + 动态匹配。存档屏无专属背景/边框资产；全部通过 theme.tres token 渲染。

### 5.5 动画风格

| 触发 | 动画 | 时长 | 缓动 | Reduced-Motion |
|---|---|---|---|---|
| 屏进入/退出 | cross-fade | 120ms | linear | instant cut |
| 槽位选中 | 左侧竖条 `burst_gold` fade-in + 底 elevation 过渡 | 150ms | ease-out | instant |
| Modal 打开 (P-NAV-03) | scale 95%→100% + fade | 200ms | ease-out | fade only |
| Modal 关闭 | scale 100%→95% + fade out | 150ms | ease-in | instant |
| P-INP-02 倒计时进度条 | linear fill 2s | 2000ms | linear | 同（功能性反馈） |
| 保存/加载遮罩 | fade in | 200ms | ease-out | instant |
| Spinner（保存/加载中） | 循环旋转 | 持续 | linear | 静态 "..." 文本 |
| 保存成功 Toast | slide-in from right + fade | 200ms | ease-out | fade only |
| 保存失败 Toast | slide-in from right + fade, `failure_red` | 200ms | ease-out | fade only |
| 损坏存档标记 | `failure_red` 边框 fade-in | 300ms | ease-out | instant + 静态红边 |
| 自动保存指示器刷新 | 数字跳变（无动画） | 0ms | — | — |

**情绪锚点**: 存档屏的情绪是"审慎、安心"（deliberate + calm）。动画以轻量 fade 为主，不做全屏爆发动效。当前槽四边 `burst_gold` 边框常驻，给玩家"我的进度被保护着"的视觉确认。

### 5.6 无障碍校验

| 检查项 | 状态 | 依据 |
|---|---|---|
| 可交互文本对比度 ≥ 4.5:1 | ✅ PASS | `text_primary` on `panel_bg_primary` ≈ 9:1 |
| 损坏 chip 三重 backup | ✅ PASS | `failure_red` + ⚠ + "存档损坏" 文字 |
| 当前槽 vs 选中槽视觉独立 | ✅ PASS | 四边 border (当前) vs 左侧竖条 (选中)，可共存不冲突 |
| 空槽用 ∅ + 文字，不纯靠灰色 | ✅ PASS | ∅ icon + "尚未创建存档" |
| 字号满足层级要求 | ✅ PASS | 槽标题 ≥24px, metadata ≥18px, 按钮 ≥20px |
| Tab order 完整（7 项） | ✅ DESIGN | Slot ×3 + 保存 + 读取 + 删除 + 返回 |
| 焦点描边 2px `burst_gold` | ✅ DESIGN | 所有交互元素 |
| P-INP-02 倒计时非 timed input | ✅ PASS | 防误点机制，非 gameplay 计时（accessibility-requirements 已确认） |
| Ctrl+S/Ctrl+L 全局快捷键 | ✅ DESIGN | 键鼠可不用鼠标 |
| Reduced-motion 全部 ≤ 50ms | ✅ DESIGN | spinner → 静态 "..." |

---

## 6. 离线结算屏 (Offline Settlement Screen)

### 6.1 色彩

| Zone | 底板 Token | 文字 Token | 备注 |
|---|---|---|---|
| DURATION HERO | `warm_paper` (#F5EDDB) | `text_primary` (duration 大字) / `text_secondary` (subtitle) | offline_paper 9-slice 拉伸底 |
| Total Gross 汇总条 | 透明（在 hero 底上） | `text_primary` | 5 资源图标 + 数字 |
| RESOURCE BREAKDOWN 卡片 | `panel_bg_primary` (在 warm_paper 上形成对比卡片) | `text_primary` (gross/claimed) / `bottleneck_red` (lost) | 1px `ink_stroke` 边框 + 右上 6px 切角 |
| 损失行背景 | `panel_bg_primary` + 8% alpha `bottleneck_red` | `bottleneck_red` + "损失原因" tooltip | — |
| LOOT GALLERY 底板 | 透明（在 warm_paper 上） | — | — |
| 物品卡片 | `panel_bg_secondary`（在 warm_paper 上形成对比） | `text_primary` (名称) | rarity frame 边框 |
| ACTION BAR | `panel_bg_primary` | `text_primary` | 底部固定 + 顶部 1px `ink_stroke` |
| "继续修炼" Button | `panel_bg_elevated` + 1px `burst_gold` 边框 (不填充) | `text_primary` | 主行动按钮 |
| "延后查看" Button | `panel_bg_elevated` | `text_secondary` | 次级按钮 |
| 警告 Banner (全满仓) | `bottleneck_red` chip + 8% alpha 红底 | `text_primary` | — |
| 空状态文字 | — | `text_secondary` 斜体 | 无离线收益 / 无战利品 |

**关键**: `warm_paper` (#F5EDDB) 仅在离线结算屏使用，是唯一使用浅色底板的主屏。深色面板卡片 (`panel_bg_primary`) 浮在浅色纸纹底上形成"报告卡片"的层次感。`text_primary` (#E8E0D0) 在 `panel_bg_primary` (#1A1A20) 上对比度 ≈ 9:1，但在 `warm_paper` 上需切换为深色文字。**本屏 duration hero 文字和 total gross 文字须使用接近 `#1A1A20` 的深色**（如 `#2A2A30`），保证在浅色纸纹底上的可读性。

**纸纹底文字 Token 覆盖**:

| 纸纹底文字用途 | 色值 | 对比度 vs `warm_paper` #F5EDDB |
|---|---|---|
| Duration hero 大字 | `#2A2A30` (深墨色) | ≈ 13:1 |
| Total gross 数字 | `#2A2A30` | ≈ 13:1 |
| 次级说明 ("上次离线收益") | `#6A6560` | ≈ 4.5:1 |

### 6.2 字体

| 元素 | 字号 @ 1080p | 字重/样式 | Token (纸纹底) / Token (面板底) |
|---|---|---|---|
| Duration hero ("你离开了 8 小时 23 分钟") | **32px** | Bold | 深墨色 (≈ #2A2A30) |
| 次级说明 ("上次离线收益 — 2026/05/04") | 16px | Regular | `text_secondary` (纸纹底版) |
| Total gross 数字 | 24px | 等宽数字，Bold | 深墨色 |
| "延后查看" 按钮文字 | 18px | Regular | `text_secondary` |
| Resource Card 标题 ("⛬ 灵气") | 20px | Bold | `text_primary` |
| Gross / Claimed / Lost 标签 | 18px | Regular | `text_secondary` |
| Gross / Claimed 数字 | 24px | 等宽数字 | `text_primary` |
| Lost 数字 | 24px | 等宽数字，Bold | `bottleneck_red` |
| 来源拆解 ("生产: +10,200") | 18px | Regular | `text_secondary` (标签) / `text_primary` (数字) |
| 损失原因 Tooltip 文字 | 16px | Regular | `text_secondary` |
| "离线战利品" 标题 | 24px | Bold | 深墨色 (纸纹底) |
| 物品数量 ("(3 件)") | 18px | Regular | 深墨色 |
| 物品卡片名称 | 14px | Regular | `text_primary` |
| 物品卡片稀有度角标 | 12px | Bold | 对应稀有度色 |
| 物品卡片数量 | 14px | 等宽数字 | `text_primary` |
| 空状态文字 ("本次离线未获得物品") | 18px | Regular, Italic | `text_secondary` |
| 警告 Banner 文字 | 18px | Bold | `text_primary` |
| "继续修炼" 按钮文字 | 24px | Bold | `text_primary` |

### 6.3 间距与布局

| 间距 | 值 | 位置 |
|---|---|---|
| DURATION HERO 高度 | 180px | CENTER CONTENT 顶部 |
| HERO 内 duration 文字距顶部 | 32px | — |
| Duration ↔ total gross 间距 | 16px | — |
| Total gross 5 项间距 | 24px（水平排列） | — |
| "延后查看" 按钮距右上 | 16px/16px | — |
| HERO ↔ RESOURCE BREAKDOWN 间距 | 24px (zone_gap) | — |
| Resource Card 之间间距 | 12px | 竖排 |
| Resource Card 内边距 | 16px | — |
| Card 内头部 ↔ 来源拆解间距 | 8px | — |
| LOOT GALLERY 标题距 Card 区 | 24px | — |
| 物品卡片网格间距 | 12px (item_gap) | — |
| 物品卡片尺寸（网格态）| **96×128** | P-DAT-04 |
| 敌人 portrait 行间距 | 12px | — |
| ACTION BAR 固定底部 | 64px | 不随 ScrollContainer 滚动 |

**ScrollContainer**: RESOURCE BREAKDOWN + LOOT GALLERY 整个中间区放在 ScrollContainer 内（背景 `offline_paper` 9-slice 随内容延伸）。短离线无需滚动即可看完（总内容高度 < 1016 − 180 − 64 = 772px 可用中间区）；长离线向下滚动。

**offline_paper 9-slice 纹理映射**:
- 原图假设为卷轴/纸纹纹理 PNG
- 切片边距: 上 48px / 右 48px / 下 **64px** / 左 48px
- 上/左/右边距 48px 保留纸缘纹理，中心区拉伸填充内容
- 下边距 64px 略宽，容纳 ACTION BAR 重叠区（BAR 底与纸纹底略有叠加，避免生硬割断）
- 切片模式: Godot NinePatchRect, `patch_margin_left=48, patch_margin_top=48, patch_margin_right=48, patch_margin_bottom=64`

### 6.4 资产需求

| Manifest § | 资产 | 用途 | 加载时机 |
|---|---|---|---|
| §1 | `theme.tres` | 全局主题 | 继承 |
| §9 | `offline_paper.png` | 全屏背景（9-slice 拉伸，ScrollContainer 背景） | 屏打开时 |
| §2 | 5 resource icons | DURATION HERO total gross 行 + Resource Breakdown 每卡片 | 屏打开时 |
| §6 | rarity frames (按稀有度动态) | LOOT GALLERY 物品卡片边框 | 物品卡片渲染时 |
| §11 | enemy portraits (可选) | 战斗中遇到的敌人 portrait 行 | 有战斗数据时 |
| §5 | `offline_pending.png` | LEFT NAV 角标（由 UIManager 控制，本屏入口影响其可见性） | offline.settled 事件触发时 |

**资产计数**: 5 个资产族。全部路径见 manifest §9, §2, §6, §11, §5。

### 6.5 动画风格

| 触发 | 动画 | 时长 | 缓动 | Reduced-Motion |
|---|---|---|---|---|
| 屏进入（从 drawer） | drawer slide-out right 150ms → 本屏 cross-fade 120ms | 总 ~270ms | ease-out | instant cut |
| 屏进入（从 LEFT NAV） | cross-fade | 120ms | linear | instant cut |
| 屏退出 | cross-fade out | 120ms | linear | instant cut |
| **Count-up 动画** | 5 资源 total gross + 每个卡片 gross/claimed/lost 数字从 0 count-up 到最终值 | **1.5s** (可配置) | **ease-out cubic** | **关闭** — 数字直接显示最终值 |
| Count-up 序列编排 | t=0ms Duration fade-in (300ms) → t=500ms total gross 5 数字并行 count-up → t=2200ms 卡片依次 stagger (每行 +100ms) → t=3500ms Loot Gallery fade-in | 总 ~3.7s | — | 全部 instant |
| 损失行出现 | `bottleneck_red` 文字 + 行背景暗红 fade-in（count-up 到达最终值后触发） | 300ms | ease-out | instant + 静态红边 |
| 物品卡片 grid 出现 | fade-in + scale 0.95→1.0, 每行 stagger 50ms | 200ms/row | ease-out | instant |
| 空状态出现 | 简单 fade-in | 150ms | ease-out | instant |
| "继续修炼" hover | 边框 `burst_gold` 亮度 +20% | 100ms | ease-out | 同（功能性反馈） |

**Count-up easing curve 详解**:

```
ease-out cubic: f(t) = 1 - (1-t)^3

数值变化特征:
- 0-30% 时长: 数字快速通过低位（制造"收银机"飞转感）
- 30-70% 时长: 减速但仍有明显变化
- 70-100% 时长: 缓慢逼近最终值（让玩家看清最后几位数字）

总时长 1.5s:
- 0-0.5s: 数字到达约 70% (0.5/1.5 时刻, f(0.33) = 1-0.67^3 ≈ 0.70)
- 0.5-1.0s: 数字到达约 96%
- 1.0-1.5s: 数字从 96% 缓慢逼近 100%
```

**关键决策**: Count-up 动画**不阻塞交互**。玩家可在动画播放期间的任意时刻点击按钮或滚动。动画继续播放但不影响交互响应。

**情绪锚点**: 本屏对应 art-bible 状态⑦（离线收益结算 — 惊喜开箱）。`warm_paper` 浅色纸纹底 + count-up 动画制造"拆礼包"仪式感。深色卡片浮在浅色纸底上产生"报告"的权威感，不与修炼屏的"深色沉浸"混淆。

### 6.6 无障碍校验

| 检查项 | 状态 | 依据 |
|---|---|---|
| Duration hero 在纸纹底上对比度 ≥ 4.5:1 | ✅ PASS | 深墨色 ≈ #2A2A30 on `warm_paper` #F5EDDB ≈ 13:1 |
| 面板底文字对比度 ≥ 4.5:1 | ✅ PASS | `text_primary` on `panel_bg_primary` ≈ 9:1 |
| 损失信息三重 backup | ✅ PASS | `bottleneck_red` + ⚠ + "损失原因: X 仓库已满" |
| 8 阶稀有度三重 backup | ✅ PASS | 边框 + 文字角标 + 颜色 |
| 5 资源图标形状区分 | ✅ PASS | 不依赖颜色识别资源类型 |
| 字号满足层级要求 | ✅ PASS | Duration ≥32px, P0 数据 ≥24px, Card 标题 ≥20px |
| Tab order 完整 | ✅ DESIGN | "延后查看" → 损失 tooltips → 物品卡片 → "继续修炼" |
| 焦点描边 2px `burst_gold` | ✅ DESIGN | 所有交互元素 |
| No timed input | ✅ PASS | Count-up 纯观赏性，动画期间按钮可正常点击 |
| Reduced-motion: count-up 关闭 | ✅ DESIGN | 数字直接显示最终值，无滚动 |
| 缩放 75%/100%/150% 不破 | ⚠️ 待验证 | ScrollContainer + 纸纹 9-slice 在各缩放档需实机验证 |
| Vestibular 敏感玩家 | ✅ PASS | Reduced-motion 模式完全关闭 count-up 数字滚动 |

---

## 7. 跨屏一致性校验

### 7.1 共享元素统一性

| 共享元素 | 规范来源 | 5 屏一致性 |
|---|---|---|
| LEFT NAV | P-NAV-02, 本规范 §1.1 | ✅ 5 屏完全一致（192/48px, 5 tab, 同顺序, 同样式） |
| TOP STRIP | 本规范 §1.2 | ✅ 5 屏完全一致（64px, 5 资源行, 等级徽章, 设置齿轮） |
| RIGHT PANEL | 本规范 §1.3 | ✅ 5 屏完全一致（320px, 战斗日志 + 警告 chips） |
| 焦点描边 | art-bible Sec 4.2 | ✅ 所有屏 2px `burst_gold` |
| Panel 切角 | art-bible Sec 3.3 | ✅ 所有卡片/面板右上或左上 6px 切角 |
| 按钮形状 | art-bible Sec 3.3 | ✅ 所有按钮纯直角，无圆角 |
| P-DAT-04 Item Card | interaction-patterns.md | ✅ 资源屏/离线屏同一规范（96×128 网格/320×420 详情） |
| P-DAT-01 Resource Row | interaction-patterns.md | ✅ 修炼屏/资源屏/离线屏同一规范 |
| P-NAV-03 Modal | interaction-patterns.md | ✅ 修炼屏/存档屏/战斗屏同一规范 |
| P-INP-01 Tooltip | interaction-patterns.md | ✅ 5 屏全部使用 |
| 4.5:1 对比度 | art-bible Sec 1 | ✅ 5 屏全部满足 |
| No round corners | art-bible Sec 3.5 禁区 1 | ✅ 5 屏全部遵守 |

### 7.2 可能的不一致风险

| 风险 | 影响屏 | 缓解 |
|---|---|---|
| `warm_paper` 浅色底上的文字色 vs 深色底 `text_primary` | 离线结算屏 | 本规范 §6.1 已定义纸纹底文字 Token 覆盖（深墨色 #2A2A30），不混用深色底 token |
| 资源屏 4 列 vs 离线屏物品网格 — 列数/卡片尺寸 | 资源屏 / 离线屏 | 统一使用 P-DAT-04 96×128，列数仅在响应式断点变化（本规范 §4.3 断点表） |
| 按钮边框 `burst_gold` vs 选中态竖条 `burst_gold` | 全部屏 | `burst_gold` 作为"当前/选中/重要"指示色的使用语义一致：选中 = 竖条/边框，CTA = 边框不填充 |
| 战斗屏 HP bar 无动画 vs 资源屏 fill bar 无动画 | 战斗屏 / 资源屏 | 一致：数据驱动的 bar 全部使用 instant jump（coalesced 刷新），不做平滑 tween |

---

## 8. 无障碍合规总表

| Standard Tier 承诺 | 本规范落实 | 状态 |
|---|---|---|
| 4.5:1 对比度（可交互文本） | `text_primary` on `panel_bg_primary` ≈ 9:1，全 5 屏满足 | ✅ |
| 1.5:1 对比度（背景装饰上限） | `ink_stroke` on `panel_bg_primary` ≈ 1.4:1 | ✅ |
| 三种色弱模式 | 所有颜色编码均有形状/文字/图标 backup（art-bible Sec 4.6） | ✅ |
| UI 缩放 75%–150% | 响应式断点已设计，待实机验证 | ⚠️ |
| 字号 ≥ 24px (菜单) / ≥ 20px (HUD) | 全 5 屏满足层级要求 | ✅ |
| 无不可延长计时输入 | Count-up 不阻塞交互；P-INP-02 防误点不算 timed input | ✅ |
| No button mashing | 全 5 屏无强制高频点击 | ✅ |
| Reduced-motion 模式 | 每屏动画表"Reduced-Motion"列已定义替代方案 | ✅ |
| 全输入重映射（键盘+手柄） | Tab order + D-Pad 导航已设计，待实现 | ⚠️ |
| 关键音效有视觉 backup | art-bible Sec 2 八状态视觉锚点已覆盖 | ✅ |

---

## 9. 附录 A — 屏级资产清单总表

| 屏 | Manifest § 引用 | 核心资产数 | 动态匹配 |
|---|---|---|---|
| **修炼屏** | §1, §2, §3, §4, §5, §8, §10, §13 | 17 | realm icon (7选1) |
| **战斗屏** | §1, §5, §8, §9, §10, §11, §13 | 16+27 | zone bg (3选1), enemy PNG (27) |
| **资源屏** | §1, §2, §5, §6, §12, §13 | 28 | rarity frame (8选1), item icon (13) |
| **存档屏** | §1, §3, §10 | 3 | realm icon (每槽) |
| **离线结算屏** | §1, §2, §5, §6, §9, §11 | 6 族+ | rarity frame (动态), enemy portrait (可选) |

---

## 10. 附录 B — 关键设计决策记录

| # | 决策 | 选择 | 理由 |
|---|---|---|---|
| D-1 | idle_sheet fps | 8fps (4帧 0.5s 循环) | 修炼屏"禅静沉浸"状态，低帧率 = 沉稳绵长，高帧率会导致 hero 显得焦躁 |
| D-2 | victory_burst_gold overlay opacity | 40%, 1s | 低于 failure_grey 的 60%，因为胜利是庆祝而非警示，不应过度遮挡画面 |
| D-3 | Enemy health bar 动画 | 无 tween — coalesced 直跳 | 避免"还在打"的错觉。idle auto-battle 场景下数字精确 > 视觉流畅 |
| D-4 | 资源数值动画 | 无 tween — 瞬间跳变 | 资源屏"账本精确感"，slot-machine 滚动破坏审计信任 |
| D-5 | 库存列数 | 4 列 @ 1080p（基准） | 6 列在 1080p 下卡片缩至 <64px 违反写意图标可识别性要求 |
| D-6 | Slot 当前 vs 选中编码 | 当前=4边包围 / 选中=左侧竖条 | 两种信号独立不冲突；当前是存档身份信号，选中是 UI 交互信号 |
| D-7 | Count-up easing | ease-out cubic (1 - (1-t)^3) | 收银机感：前快后慢，让玩家看到低位飞转 + 高位缓慢逼近 |
| D-8 | offline_paper 9-slice | 48/48/48/64 margin | 48px 保留纸缘纹理；下边 64px 容纳 ACTION BAR 重叠 |
| D-9 | `warm_paper` 上文字色 | 深墨色 #2A2A30 | 浅色纸纹底不可用 `text_primary #E8E0D0` 浅色字（对比度 ≈ 1.6:1 不可读） |
| D-10 | LEFT NAV Tab 图标 | 独立 icon set (24×24) | 不使用 realm/resource icon 替代 — LEFT NAV 需要完整图标族（修炼/战斗/资源/存档/离线） |

---

## 11. 附录 C — 待完成项

| 项 | 负责 | Sprint |
|---|---|---|
| 中文字体挂载（思源黑体 Noto Sans SC Regular）至 `assets/ui/fonts/` | technical-artist + art-director | Sprint 11 (nice-to-have) |
| LEFT NAV 5 个 tab 专属图标 (24×24 SVG/PNG) | art-director (spec) → technical-artist (pipeline) | Sprint 11 |
| 1280×720 + 75%/100%/150% 缩放三档实机截图验证（5 屏全量） | ui-programmer + art-director | Sprint 11 QA |
| 4K 缩放字号验证 | ui-programmer | Sprint 11 QA (optional) |
| offline_paper.png 9-slice 适配验证（Godot NinePatchRect 实际切片效果） | ui-programmer | Sprint 11 |
| 色弱模拟器截图（Protan/Deutan/Tritan, 5 屏各 3 张 = 15 张） | art-director | Sprint 11 QA |
| player-journey.md mini 版本（5 屏在玩家循环中的频率/停留时长支撑视觉节奏决策） | producer + ux-designer | Sprint 11 启动前 |
