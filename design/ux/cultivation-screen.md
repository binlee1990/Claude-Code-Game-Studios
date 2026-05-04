# UX Spec: 修炼屏 (Cultivation Screen)

> **Status**: In Design
> **Author**: binlee1990 + ux-designer
> **Last Updated**: 2026-05-05
> **Journey Phase(s)**: 待补 — design/player-journey.md 不存在；本 spec 假设修炼屏出现在玩家"Onboarding → Early Game"全程，是 game-concept §10.2 第一条可玩闭环的起点
> **Platform Target**: PC (Steam/Epic) — Keyboard/Mouse + Gamepad Partial
> **Template**: UX Spec
> **Sprint**: Sprint 11 / mvp-screens / S11-009
> **Asset Manifest 引用**: §1 theme · §8 main_base · §10 player portrait + idle_sheet · §4 全 4 stance icons · §13 manual_click_pulse VFX · §2 5 resource icons (继承 HUD) · §3 realm icons (继承 HUD)

---

## Purpose & Player Need

修炼屏（Cultivation Screen）是玩家"思考修炼"的**深度仪表盘**。HUD 顶栏回答"我现在有多少灵气/修为/灵石"——本屏回答**"为什么是这个数字 / 怎么能更高"**。

### 核心玩家目标

1. **看清产出来源** — 把 OutputMultiplierSystem 当前每秒 `lingqi/xiuwei/lingshi/herb` 的 `base + 姿态 + 等级 + 境界 + 修正器` 各分项**全部拆开**显示给玩家，而不是只给"3.2/s"一个总数。
2. **试算决策后果**（MVP 必有）— 玩家想"如果我切到 condense 一分钟会得到多少修为？"，本屏给出试算（不实际切换）。**实现备注**：依赖 OutputMultiplierSystem 暴露 `simulate_tick_for(stance, duration_seconds)` 只读 query API；如该 API 引入 ADR-0011 范围外的决策，须在 Sprint 11 立 ADR-0017+。
3. **建立投入感锚点** — 手动修炼按钮 + `manual_click_pulse.png` VFX 反馈，玩家在 onboarding 早期建立"我和角色的连接"，但**不强制重复点击**（accessibility-requirements `Motor / 无 button mashing` 承诺）。
4. **沉浸主基地感** — `main_base.png` 全屏背景 + `portrait.png` + `idle_sheet.png` 微动画，玩家"待在自己洞府里"，而不是"看着面板做表格"。
5. **修炼姿态的策略入口** — 4 stance icon modal（`meditate` / `condense` 可选，`closed_door` / `idle` **置灰预告**预留 Sprint 12+），玩家明确选择"产灵气优先 vs 转修为优先"。

### Sentence form

> "The player arrives at this screen wanting to **understand** and **tune** their cultivation output, **switch stance with intention**, and **feel** the cultivation fantasy through ambient art."

### 反向定义（这里不做什么）

- ❌ 不重复显示 HUD 已有的资源数字（HUD = 当前值，本屏 = 来源拆解）
- ❌ 不做战斗 / 装备 / 宗门 / 秘境（各自有自己的屏，由 mvp-screens 后续 stories 承接）
- ❌ 不做强制点击玩法（`manual_cultivate` 是 optional，不是 progression gate）
- ❌ 不做教程文字（教程系统 GDD 38 负责，本屏不污染）
- ❌ 不实现 `closed_door` / `idle` 姿态的切换逻辑（cultivation-system MVP scope 外）

### 与 game-concept §10.2 的关系

本屏是**第一条可玩闭环的起点**（修炼 → 资源增长）；玩家循环里 30 秒 / 5 分钟 / 30 分钟（game-concept §7）都至少回到本屏一次检查产出与切换姿态。

### Pillar 锚定

- **4.1 数字增长就是快乐** — 产出明细让数字"为什么"也变成快乐源
- **4.2 放置 = 低频高价值决策** — 姿态切换是 5 分钟 / 30 分钟尺度的决策，不是秒级
- **4.6 渐进叙事** — modal 中 `closed_door` / `idle` 置灰预告，玩家看到"未来还有"

---

## Player Context on Arrival

| 维度 | 答案 |
|------|------|
| **何时首次遇到** | 新存档冷启动后 0–3 秒（默认首屏，玩家没有选择）— Sprint 11 S11-003 RootViewport 首屏配置 |
| **之前在做什么** | **新玩家**：刚启动游戏（可能刚看完 Steam 启动 splash）；**老玩家**：从其他屏（战斗 / 资源 / 存档 / 离线结算）切回来检查"我修得怎么样" |
| **情绪状态（设计假设）** | **calm + curious + 探索性低压力** — 不是战斗后的高肾上腺素，不是 Boss 前的紧张；玩家来这里是"安静地看自己变强"。锚点：art-bible 状态①禅静沉浸 + cultivation-system Player Fantasy |
| **主动 vs 被动** | **混合** — 冷启动时被动（默认首屏推过来）；后续是**主动**（玩家从 LEFT NAV 选"📊修炼" tab 切回来） |

### 派生设计含义（约束 Layout 与 Transitions）

- **No splash overlay**：玩家到达时屏幕直接进入 Ready 状态，不要 loading shimmer 浪费 calm 情绪
- **第一眼焦点**：因为是 calm 情绪 → 默认焦点**不是按钮，而是产出明细面板**（玩家先看数字自己变强了，再决定要不要操作）
- **离开时无确认**：本屏没有不可逆操作（姿态切换可逆），从修炼屏切到其他屏不需要"确定要离开吗"
- **新存档 vs 继续游戏分支**：新存档时 `manual_cultivate` 按钮**呼吸光晕**（onboarding 隐式提示）；continued game 下不呼吸（避免老玩家被打扰）

---

## Navigation Position

修炼屏位于 **Root → ScreenStack → Cultivation Screen**（LEFT NAV "📊修炼" tab，第 1 位，**默认首屏**）。所有其他主区域（战斗 / 资源 / 存档 / 离线结算）都通过 LEFT NAV 平级切换；修炼屏没有独占的"父屏"，也不通向任何子屏。

### 替代入口

| 入口源 | 触发方式 |
|--------|---------|
| LEFT NAV "📊修炼" tab | 鼠标点击 / 键盘 ↑↓ + Enter / 手柄 D-Pad ↑↓ + A |
| 全局快捷键 `1` | 数字键 1–5 直达 5 主区域，修炼 = `1` |
| 离线结算 drawer 关闭后回归 | `offline.settled` 处理完玩家点 "回到修炼" → `open_screen("cultivation")` |
| 调试控制台 `goto cultivation` | dev only；release 构建排除（ADR-0012） |

### 不能从这里到达的地方

修炼屏**不通向**任何子屏（无层级深度）。所有 modal（姿态切换 / 设置）通过 P-NAV-03 Modal Stack 浮层叠加；玩家关闭 modal 后仍在修炼屏。

---

## Entry & Exit Points

### Entry

| Entry Source | Trigger | Player carries this context |
|---|---|---|
| Cold start (new save) | `RootViewport.open_screen("cultivation")` | 空状态 — Lv.1 fanren / lingqi=0 / stance=meditate |
| Cold start (continued) | Save loaded → `open_screen("cultivation")` | 上次保存的 lingqi/xiuwei/stance/level/realm |
| LEFT NAV tap | Click "📊修炼" / Press `1` / D-Pad 选第 1 项 + A | 当前游戏状态 |
| Offline drawer dismissed | drawer 关闭 + 自动回归首屏 | `offline.settled` 已处理 |
| Modal closed | 任何 modal 关闭后回到本屏 | modal 内决策已落地 |
| Debug `goto cultivation` | dev only | — |

### Exit

| Exit Destination | Trigger | Notes |
|---|---|---|
| Combat screen | LEFT NAV "⚔战斗" / Press `2` / LB+RB | 携带 stance（不重置） |
| Resources screen | LEFT NAV / Press `3` | — |
| Save screen | LEFT NAV / Press `4` | — |
| Offline drawer | `offline.settled` 事件触发后玩家点 "📦 N" 角标 | 浮层 — 关闭后回本屏 |
| Stance / Settings Modal | 屏内按钮 / ⚙ | 浮层 — 关闭后仍在本屏 |
| App quit | 系统关闭 | 触发 SaveManager auto-save |

无一次性出口；所有 exit 可通过 LEFT NAV 返回，无不可逆状态。

---

## Layout Specification

### Information Hierarchy

按 art-bible 第 2 原则"决策优先级 = 视觉亮度"映射，从最高到最低：

1. **Hero Tier**（屏幕左半中央，立即可见）— 沉浸锚点
   - 主角 portrait + idle_sheet 微动画
   - 当前 stance icon（大）+ Lv.1 凡人 Label
2. **Decision Tier**（屏幕右上半，玩家做决策时聚焦）
   - 每秒 lingqi/xiuwei/lingshi/herb 总产出（4 行大数字 ≥ 24px）
   - 每行可展开"产出来源拆解"（默认折叠 1 行简略，展开后 5–8 行明细）
   - "切换姿态"按钮（醒目，但非主行动）
3. **Action Tier**（屏幕左下半，玩家偶尔点击）
   - 手动修炼按钮（含冷却倒计时）+ manual_click_pulse VFX
   - 凝练参数微调（仅 condense 姿态时显示：cost / rate 当前值 + tooltip）
4. **Inspection Tier**（屏幕右下半，玩家深度思考时用）
   - 试算面板（"切到 condense 1 分钟得到 X 修为"）
   - 试算输入：duration 滑块 + 假设姿态 dropdown + 应用按钮
5. **Ambient Tier**（背景，不参与交互）
   - main_base.png 全屏背景 + 半透明 dim
   - 渐进解锁的姿态预告（closed_door / idle 置灰图标，屏幕右下角）

### Layout Zones

修炼屏占 **HUD 的 CENTER CONTENT 区**（hud.md §Layout Zones 第 3 行），即去除 TOP STRIP 64px / LEFT NAV 192px / RIGHT PANEL 320px / BOTTOM ACTION BAR 之后的区域。

@ 1080p 基线：CENTER CONTENT 可用区域 ≈ **1408 × 1016 px**。

| Zone | 位置 | 尺寸 @ 1080p | 内容 |
|---|---|---|---|
| **HERO ZONE** | 左上 | 480 × 680 px | 立绘 + idle_sheet + 当前 stance icon + level/realm Label |
| **DECISION ZONE** | 右上 | 880 × 680 px | 4 资源每秒产出 + 拆解（可展开）+ 切换姿态按钮 |
| **ACTION ZONE** | 左下 | 480 × 320 px | 手动修炼按钮 + 凝练参数（condense 时显示）+ 灵气不足 chip |
| **INSPECTION ZONE** | 右下 | 880 × 320 px | 试算面板（duration slider + stance dropdown + 结果 + 应用按钮） |
| **Ambient Hint** | 屏右下角浮层 | 80 × 40 px | 2 个置灰 stance icons（closed_door / idle）预告未来内容 |

### 屏幕安全区

- 1280×720 最小窗口：HERO 缩到 360×500；DECISION/ACTION/INSPECTION 等比缩；Ambient Hint 折叠到 hover-reveal
- 4K：等比缩 + 字号 +1 档（24px → 28px）
- Steam Deck 1280×800：LEFT NAV 折叠 48px；CENTER 三段式布局保持比例

### Component Inventory

按 zone 分组；每行标注：组件类型 / 内容 / 是否交互 / 引用 pattern 或新组件。

#### HERO ZONE

| Component | Type | Content | Interactive | Pattern |
|---|---|---|---|---|
| Background fill | TextureRect | main_base.png 局部 crop | No | — |
| Player portrait | TextureRect | portrait.png | No | — |
| Player idle sprite | AnimatedSprite2D | idle_sheet.png（fps 由 pipeline-meta 定义） | No | — |
| Current stance icon | TextureRect | meditate / condense / closed_door / idle 之一 | No | — |
| Level + realm Label | Label | "Lv.1 凡人" | No | 复用 hud.md 等级徽章风格 |

#### DECISION ZONE

| Component | Type | Content | Interactive | Pattern |
|---|---|---|---|---|
| Resource Production Row × 4 | 自定义（扩展 P-DAT-01 Resource Row） | 收起态：图标 + 名称 + "+3.2/s"；展开态：上述 + 5–8 行 base/姿态/等级/境界/修正器拆解 | Yes（点行展开/收起 + tooltip） | **新 component**：扩展 P-DAT-01 加 expand 行为；建议入 interaction-patterns.md 为 P-DAT-01-EXP |
| 切换姿态 Button | Button | "🧘 切换姿态" + 当前姿态名 | Yes（开 modal） | 触发 P-NAV-03 Modal Stack |
| Stance Selection Modal | PanelContainer + 4 IconButton | 4 stance icon 选择，2 个置灰 + tooltip "Sprint 12+ 解锁" | Yes | P-NAV-03 |

#### ACTION ZONE

| Component | Type | Content | Interactive | Pattern |
|---|---|---|---|---|
| Manual Cultivate Button | Button | "✋ 手动修炼 (+1 灵气)" | Yes | + manual_click_pulse VFX 触发 |
| Cooldown ProgressBar | ProgressBar | 0 → click_cooldown_seconds | No（show only） | — |
| Condense Cost Label | Label | "凝练消耗: 10 灵气" + tooltip | No（hover tooltip） | P-INP-01 Tooltip |
| Condense Rate Label | Label | "凝练效率: 10%" + tooltip | No（hover tooltip） | P-INP-01 Tooltip |
| 灵气不足 Chip | StatusChip | "灵气不足 ⚠"（仅 last_shortage = true 时显示） | No | P-FBK-02 Inline Status Chip |

#### INSPECTION ZONE

| Component | Type | Content | Interactive | Pattern |
|---|---|---|---|---|
| Duration HSlider | HSlider | 5 档：10s / 30s / 1min / 5min / 30min | Yes | — |
| Stance OptionButton | OptionButton | meditate / condense（2 选） | Yes | — |
| 试算结果 Label | RichTextLabel | "切到 condense 30s 得到 +96 修为 / -960 灵气" | No（show only） | 支持多行换行 |
| 应用此姿态 Button | Button | "应用此姿态" | Yes | 直接 set_stance，跳过 modal |

#### Ambient Hint

| Component | Type | Content | Interactive |
|---|---|---|---|
| Locked stance icons | TextureRect × 2 | closed_door.png + idle.png（饱和度 -60%） | hover only — 显示 tooltip "Sprint 12+ 解锁" |

#### 组件总数

11 个交互元素 + 8 个静态显示 + 1 个 modal = 共 20 个 UI components。

### ASCII Wireframe

```
┌── HUD TOP STRIP (64px, 固定) ───────────────────────────────────────────┐
│ ⛬ 1.2K ◯ 850K ◇ 12.5M ❀ 234K  │  Lv.1 凡人  │  📊修炼 ▼  │  ⚙        │
├──────┬───────────────────────────────────────────────────┬─────────────┤
│LEFT  │  ╔═══════════════════════════════════════════════╗ │ RIGHT PANEL │
│NAV   │  ║ HERO ZONE              DECISION ZONE          ║ │             │
│192px │  ║ (480×680)              (880×680)              ║ │ 战斗日志 ▼  │
│      │  ║ ┌────────────┐ ┌──────────────────────────┐   ║ │ ┌─────────┐ │
│📊修炼│  ║ │            │ │ ⛬ 灵气   +3.2/s         ▶│   ║ │ │ 17:32   │ │
│⚔战斗│  ║ │  立绘       │ │ ◯ 修为   +0.8/s         ▶│   ║ │ │  普攻   │ │
│📦资源│  ║ │   +         │ │ ◇ 灵石   +0.1/s         ▶│   ║ │ │  暴击!  │ │
│💾存档│  ║ │  idle_sheet │ │ ❀ 药材   +0.0/s         ▶│   ║ │ │   ...   │ │
│📅离线│  ║ │   动画      │ │                          │   ║ │ │  ▼ jump │ │
│      │  ║ │             │ │ ┌────────────────────┐  │   ║ │ └─────────┘ │
│      │  ║ │  🧘         │ │ │ 🧘  切换姿态       │  │   ║ │             │
│      │  ║ │  meditate   │ │ └────────────────────┘  │   ║ │ ─────       │
│      │  ║ │  Lv.1 凡人  │ │                          │   ║ │ [警告 chips] │
│      │  ║ └────────────┘ └──────────────────────────┘   ║ │             │
│      │  ║                                                ║ │             │
│      │  ║ ACTION ZONE             INSPECTION ZONE        ║ │             │
│      │  ║ (480×320)               (880×320)              ║ │             │
│      │  ║ ┌────────────┐ ┌──────────────────────────┐   ║ │             │
│      │  ║ │  ✋        │ │ 试算: 切到 [meditate ▾]  │   ║ │             │
│      │  ║ │  手动修炼  │ │ 持续: ━━━●━━━━━ [30s]    │   ║ │             │
│      │  ║ │  (+1 灵气) │ │ 结果: + 96 灵气           │   ║ │             │
│      │  ║ │  ◷ 0.5s    │ │ ┌──────────────────┐    │   ║ │             │
│      │  ║ │            │ │ │  应用此姿态       │    │   ║ │             │
│      │  ║ │ [凝练参数] │ │ └──────────────────┘    │   ║ │             │
│      │  ║ │ cost: 10   │ │                          │   ║ │             │
│      │  ║ │ rate: 10%  │ │                          │   ║ │             │
│      │  ║ │ ⚠ 灵气不足  │ │                          │   ║ │             │
│      │  ║ └────────────┘ └──────────────────────────┘   ║ │             │
│      │  ╚═══════════════════════════════════════════════╝ │             │
│      │                                          🚪 💤 ←hint │             │
└──────┴───────────────────────────────────────────────────┴─────────────┘
```

> **Wireframe 注**：本 wireframe 仅展示 1080p 默认布局；实际像素位由 art-director 在 Sprint 11 hud-real-layout S11-004 期间结合 theme.tres 9-slice 与 panel margin 微调。背景 main_base.png 在 ▒ dim 之下若隐若现，立绘部分透明叠加；HERO 与 DECISION 之间有 24px 间隙。

---

## States & Variants

| State / Variant | Trigger | What Changes |
|---|---|---|
| **Default (meditate)** | 新存档冷启动 | HERO stance icon = `meditate.png`；ACTION ZONE 不显示凝练参数；DECISION 4 行产出按 meditate 倍率 |
| **Condense Active** | 玩家选 condense | HERO stance icon = `condense.png`；ACTION ZONE 显示 cost / rate / shortage chip |
| **Lingqi Shortage** | `CultivationSystem.last_shortage = true` | "灵气不足" chip 红色显示；condense 资源行 fill bar 闪烁（overflow_warn_flash 复用） |
| **Manual Cooldown** | manual_cultivate 后 0 → click_cooldown_seconds | 手动修炼按钮 disabled + ProgressBar 0 → full 倒计时 |
| **Time Frozen** | `TimeManager.frozen = true` | HERO idle_sheet 暂停；4 资源行追加 "(已冻结)" 灰字；手动修炼按钮 disabled |
| **Loading (cold start)** | 0 – 500ms 在 AutoProductionSystem 第一 tick 之前 | 4 资源行显示 "..." 占位 |
| **Empty (new save first 3s)** | manual_cultivate 从未触发 + lingqi == 0 | 手动修炼按钮**呼吸光晕**（onboarding 暗示）；触发一次后光晕消失 |
| **Closed Door / Idle Locked** | cultivation-system 不实现这两个 stance | Modal 中 2 个置灰 stance；hover 显示 "Sprint 12+ 解锁" tooltip |
| **OMS Breakdown API Missing** | 架构降级（ADR-0017 未通过） | DECISION 资源行收起态显示总数；展开态显示 "拆解 API 待实现"；INSPECTION 静态示例代替试算 |
| **Player Death / Defeat** | 战斗失败回到本屏 | 无特化 — 本屏与战斗解耦；玩家直接看到当前修为，自行决定是否继续 |

---

## Interaction Map

输入方法：键鼠（Primary）+ 手柄 partial（D-Pad / A / B / X / Y / LB / RB）。无 touch（technical-preferences `Touch Support: None`）。

| Action | Mouse / Keyboard | Gamepad | 即时反馈 | 结果 |
|---|---|---|---|---|
| 展开 / 收起单资源拆解 | Click 行 / Tab + Enter | A 键 | 200ms 高度 expand 动画 | UI only — 不发事件 |
| 切换姿态 modal 打开（modal 深度 1/3） | Click "切换姿态" / Press `S` | Y 键 | 200ms scale 95→100% + fade | `UIManager.open_modal("stance_select")` — 修炼屏 → stance modal 为深度 1，远在 `max_modal_depth=3` 限制内 |
| 选择姿态（modal 内） | Click 4 icon 之一 / D-Pad 选 + Enter | D-Pad + A | manual_click_pulse-like 微闪 | `CultivationSystem.set_stance(...)` |
| 关闭 modal（取消） | ESC / Click 外 | B 键 | fade out 200ms | `UIManager.close_modal()` |
| 手动修炼 | Click button / Press `SPACE` | A 键 | manual_click_pulse VFX 220ms | `CultivationSystem.manual_cultivate()` |
| 调整试算 duration | 拖 HSlider / ←→ 键（滑块焦点时） | D-Pad ←→ | 实时计算（≤ 100ms） | UI only — 调用 OMS query |
| 切换试算假设姿态 | Click OptionButton + 选项 | Y 键开 dropdown + D-Pad 选 | dropdown 弹 | UI only — 重新调 OMS query |
| 应用试算姿态 | Click "应用此姿态" | X 键 | manual_click_pulse | `CultivationSystem.set_stance(simulated)` |
| 关闭本屏（去其他主屏） | Click LEFT NAV / 数字 1–5 | LB / RB 切 tab | 120ms cross-fade | `UIManager.open_screen(...)` |
| Tooltip 触发（参数 / 拆解项） | Mouse hover ≥ 0.5s | 焦点 + 长焦 0.8s | tooltip fade-in 150ms | P-INP-01 |

### Tab Order（accessibility-requirements Standard tier 强制）

HERO（焦点 readonly，跳过）→ Resource Row 1 → Resource Row 2 → Resource Row 3 → Resource Row 4 → 切换姿态按钮 → 手动修炼按钮 → 凝练参数（如可见）→ 试算 duration slider → 试算姿态 dropdown → 应用按钮。共 11 项可达交互。

---

## Events Fired

| Player Action | Event Fired | Payload |
|---|---|---|
| 切换姿态成功（modal 或试算应用） | `cultivation.stance_changed`（CultivationSystem 自动发，UI 不重发） | `{stance: "condense"}` |
| 手动修炼成功 | `resource.lingqi.changed`（ResourceSystem 自动发） | `{resource_id, old_value, new_value, delta}` |
| 凝练成功 | `resource.lingqi.changed` + `resource.xiuwei.changed` | 同上 ×2 |
| 凝练失败（灵气不足） | **无新事件**；UI 直接读 `CultivationSystem.get_hud_state().shortage` | — |
| 试算 query | **无事件** — read-only OMS call，不进 EventBus | — |
| 进入 / 离开本屏 | `ui.screen_opened` / `ui.screen_closed`（UIManager 自动发，本屏不重发） | `{screen_id: "cultivation"}` |
| 资源行展开 / 收起 | **无事件** — 纯 UI 状态 | — |

### 架构标记

- `cultivation.stance_changed.applied_via` metadata 字段建议 cultivation-system 加 `set_stance(stance, source: String = "")` 可选参数；如不在 MVP scope，UI 只发标准事件，"通过试算应用"信息走 telemetry/analytics 旁路而非 EventBus（保持事件总线纯净）
- 任何修改持久状态的 action（manual_cultivate / set_stance）已经走 CultivationSystem command — UI 自身**不写**任何持久状态

---

## Transitions & Animations

| Trigger | Animation | Duration | Reduced-motion 替代 |
|---|---|---|---|
| 屏幕进入（cold start / LEFT NAV 切入） | cross-fade | 120ms（ui-framework `default_transition_ms`） | instant cut |
| 屏幕退出 | cross-fade out | 120ms | instant cut |
| 资源行展开 / 收起 | 高度 expand + 内容 fade-in | 200ms | instant |
| 切换姿态 modal 打开 | scale 95% → 100% + fade | 200ms | fade only |
| 切换姿态 modal 关闭 | scale 100% → 95% + fade out | 150ms | instant |
| 手动修炼按钮按下 | `manual_click_pulse.png` VFX 单帧扩散 | 220ms | 单帧静态闪一下 |
| Cooldown ProgressBar 0 → full | linear fill | click_cooldown_seconds | 同 — 是功能性反馈，不算 motion |
| 灵气不足 chip 出现 | `overflow_warn_flash.png` 复用（暗红墨晕） | 300ms | instant + 静态红边 |
| 凝练成功 | 资源行 fill bar 推进 | 200ms | instant 数字跳变 |
| 主角 idle_sheet 循环 | AnimatedSprite2D | meta.json 定义 fps | 静态 portrait.png |
| 时间冻结进入 | HERO 灰度 fade 50% | 300ms | instant 灰度 |
| 时间解冻 | 灰度恢复 | 300ms | instant |
| 新存档手动修炼按钮呼吸光晕 | scale 100 ↔ 105 + alpha 100 ↔ 70 | 1.5s 周期循环 | **关闭** — 静态高亮边框替代 |

### 禁区

- 本屏**不**触发 `burst_gold` 全屏印章（突破 / 飞升专用，本屏不承担境界突破）
- 本屏**不**触发 `victory_burst_gold`（战斗专用）
- 本屏**不**触发 `failure_red`/`failure_grey`（战斗失败专用）
- 全屏覆层动效仅在 art-bible 状态①背景水墨云气 60s 周期横移（如 polish 阶段加入），且 reduced-motion 完全关闭

---

## Data Requirements

| Data | Source System | R/W | Notes |
|---|---|---|---|
| `lingqi/xiuwei/lingshi/herb/exp` 当前值 | ResourceSystem | Read | HUD 已订阅，本屏复用顶栏数据 |
| 4 资源每秒总产出（实时） | `OutputMultiplierSystem.get_tick_amount(resource_id, 1.0)` | Read | 高频读 — coalesce 至 ≤ 10Hz（hud_refresh_interval） |
| 产出来源拆解（base / 姿态 / 等级 / 境界 / 修正器） | `OutputMultiplierSystem.get_breakdown(resource_id) -> Dictionary` | Read | ✅ OMS GDD §Detailed Design #8 已定义（返回 `{base_rate, pools: {realm/equipment/zone/buff}, final_multiplier, rate_per_second}`）；本屏直接使用现有 API |
| 当前 stance + last_shortage | `CultivationSystem.get_hud_state()` | Read | 已有 |
| `condense_cost` / `condense_rate` 当前值 | `CultivationSystem.get_condense_cost()` / `.get_condense_rate()` | Read | 动态计算值（依赖 stance + level）；建议用 method 而非 public field，实现时与 cultivation-system GDD 确认 |
| 主角 level + realm | `LevelSystem.get_level("player")` / `.get_realm("player")` | Read | 已有；HUD 已订阅 |
| 试算结果 | `OutputMultiplierSystem.simulate_tick_for(stance, seconds)` — 新 API | Read | 已立 ADR-0017 决议此 query API；返回 `{amount: BigNumber, rate_per_second: float, error: String}` |
| `cultivation.stance_changed` 事件 | EventBus subscribe | Read | 已有 |
| `manual_cultivate()` command | `CultivationSystem.manual_cultivate()` | Write（间接） | 通过命令，不直接写资源 |
| `set_stance(next)` command | `CultivationSystem.set_stance()` | Write（间接） | 同上 |
| TimeManager.frozen 状态 | `TimeManager.collect_save_data().frozen` | Read | 用于 Time Frozen state；建议 TimeManager 暴露简单 `is_frozen()` getter 避免每帧序列化 save data |

### 架构关注（ADR 评估）

本屏对 OMS 提出 **1 个新 API**（`simulate_tick_for`）。`get_breakdown` 已在 OMS GDD §Detailed Design #8 定义（返回 `Dictionary`），可直接使用。ADR-0017 已立（2026-05-05 Proposed）决议 `simulate_tick_for` 作为只读 query；如否决则降级为"只显示总数 + 静态示例（无试算）" — 但这等于阉割本屏 60% 的价值。

UI 自身**不持有**任何 game state；所有读取走 host getter，所有写入走 command。符合 `.claude/rules/ui-code.md` "UI 必须 NEVER 拥有或直接修改 game state"。

---

## Accessibility

继承 `design/accessibility-requirements.md` Standard tier。本屏特化条款：

### 视觉

- HERO 立绘下方 Label ≥ 24px（菜单字号阈值）；DECISION 4 资源数字 ≥ 24px；产出拆解明细 ≥ 20px（HUD 字号阈值）；INSPECTION 试算结果 ≥ 24px
- 所有可交互文本与背景对比 ≥ 4.5:1（art-bible 第 2 原则；theme.tres `text_primary` on `panel_bg_primary` ≈ 9:1 已满足）
- 产出拆解明细文本 ≥ 4.5:1（虽是次级信息但可阅读性需保留 — pillar 4.1）
- 4 stance icons 形状已不同（不依赖颜色识别 stance — art-bible Sec 4.6 色弱 backup 自带）
- "灵气不足" chip：色（`bottleneck_red`）+ 文字 + ⚠ 图标三重 backup
- UI 缩放 75% / 90% / 100% / 125% / 150% 五档下布局不破，文字不裁切

### 键鼠 / 手柄等价

- Tab order 见 §Interaction Map（共 11 项可达交互）
- 当前焦点元素加 2px `burst_gold` 描边（与 hud.md 对齐）
- 姿态切换 modal 关闭：ESC / B 键
- HSlider 焦点时 ←→ 键 / D-Pad 调节
- OptionButton dropdown 用 D-Pad 选择 + A 确认

### 时间相关

- **No timed input**：本屏无强制计时输入（cultivation-system MVP 验证）
- manual_cultivate 冷却 0.5s 是**可选优化**，不是 progression gate；按 cooldown 期间按按钮**不报错**只忽略
- 试算 duration 5 档预设无计时压力

### 动作 / 体力

- **No button mashing**：manual_cultivate 鼓励**单次点击**，长按不加速；持续按按钮按下也只触发一次
- **Hold-to-press 替代**：未来如 closed_door 涉及"长按修炼"，必须有 toggle 替代（accessibility-requirements Motor 段）
- 所有可交互 hit area ≥ 32 × 32 px（按钮）/ 48 × 48 px（slider handle）

### Reduced Motion

详见 §Transitions & Animations 表"Reduced-motion 替代"列。新存档呼吸光晕在 reduced motion 下**完全关闭**，改为静态 `burst_gold` 边框。

### 已知限制

- Menu screen reader（NVDA / Narrator passthrough）— 与 accessibility-requirements 全局一致，本屏不单独实现，记入项目级 Open Questions

---

## Localization Considerations

| 元素 | 中文最长 | 设计预留宽度 | 风险 / 备注 |
|---|---|---|---|
| 资源中文名（灵气 / 修为 / 灵石 / 药材 / 经验） | 2 字 | 4 字宽度 | 低 — 英文 "Spirit Qi/Cultivation/Spirit Stone/Herb/EXP" 已在范围 |
| 产出拆解条目（"等级倍率 +20%"） | ~10 字 | 16 字宽度（按 +60% 翻译宽容） | **中** — 德文 "Stufenmultiplikator +20%" ≈ 21 字符；需测试 |
| 切换姿态按钮文字 | 4 字 ("切换姿态") | 8 字宽度 | 低 — 英文 "Change Stance" ≈ 13 字符；考虑 16 字宽度 |
| 手动修炼按钮 | 8 字 ("手动修炼 (+1 灵气)") | 16 字宽度 | 低 |
| 试算结果（"切到 condense 30s 得到 +96 修为"） | ~16 字 | **支持 2 行换行**，无单行约束 | **HIGH** — 翻译易超 30 字符；必须用 RichTextLabel + autowrap |
| 凝练参数 tooltip（"消耗 N 灵气产出 N×rate 修为"） | ~20 字 | RichTextLabel 多行 | **HIGH** — tooltip 主体支持 ≥ 3 行 |
| stance icon tooltip（"meditate / 默认打坐"） | ~10 字 | 单行 + 副标题双行 | 中 |
| Locked stance tooltip（"Sprint 12+ 解锁 - 闭关"） | ~12 字 | 单行 | 低 — 上线版本应改为玩家可读语言（"未来内容 - 闭关"） |

### HIGH PRIORITY 项（标记给 localization engineer）

- **试算结果 Label** 必须用 `RichTextLabel` + `autowrap_mode = AUTOWRAP_WORD_SMART`，最少支持 2 行；预测试德 / 法 / 西翻译
- **凝练参数 tooltip** 用 `RichTextLabel` 支持多行 + 段落间距
- **资源拆解条目** 数字与文字之间必须有逗号 / 空格分隔（中文无空格但翻译版本必须有）

### 数字格式

所有 BigNumber 走 NumberFormatter；中文 / 短格式 / 科学格式由 settings 切换（参 hud-system §UI Requirements + ADR-0014）。

### 不需要本地化的元素

- 资源 PNG 图标（`§2`）— 视觉无文字
- stance PNG 图标（`§4`）— 视觉无文字
- 立绘 + idle_sheet — 视觉无文字
- main_base.png 背景 — 视觉无文字（art 资产无文字嵌入）

---

## Acceptance Criteria

按 `.claude/rules/design-docs.md` 标准；至少 5 条可测试、QA 可独立验证、不读其他文档可验证。共 13 条：

### 性能

- [ ] **AC-1** 屏幕从触发 `open_screen("cultivation")` 到 Ready 状态 ≤ 200ms（含 main_base.png 背景 + portrait.png + idle_sheet.png 加载）
- [ ] **AC-2** 资源行展开 / 收起动画 ≤ 220ms 完成；动画期间不阻塞其他交互

### 导航

- [ ] **AC-3** LEFT NAV 点 "📊修炼" / 数字键 `1` / 手柄 LB+D-Pad 选第 1 项 + A，3 种入口都能正确开屏（screenshot 证据 ×3）
- [ ] **AC-4** 屏内任何位置按 ESC / 手柄 B 不会退出本屏（无父屏可返回）；ESC / B 仅在 modal 打开时关闭 modal

### 核心数值

- [ ] **AC-5** 4 资源行的"每秒产出总数"显示与 `OutputMultiplierSystem.get_tick_amount(resource_id, 1.0)` 一致；展开拆解后所有分项之和 = 总数（含浮点容差 ≤ 0.01）
- [ ] **AC-6** 切换 stance 后产出明细在 ≤ 200ms 内全部刷新（4 资源 × 5–8 分项均更新）
- [ ] **AC-7** 试算 duration=60s + condense → 结果与 `simulate_tick_for("condense", 60)` 一致；点 "应用此姿态" 后 stance 实际切换且发 `cultivation.stance_changed`

### 状态

- [ ] **AC-8** condense 姿态 + 灵气不足时（强制把 lingqi 设为 0）："灵气不足" chip 显示 + condense 资源行 fill bar 闪烁；切回 meditate 后 chip 在 200ms 内消失
- [ ] **AC-9** TimeManager 冻结时（debug 命令触发），HERO idle_sheet 暂停 + 手动修炼按钮 disabled + 4 行产出末尾追加 "(已冻结)" 灰字
- [ ] **AC-10** 新存档前 3 秒 + manual_cultivate 未触发，按钮显示**呼吸光晕**；触发一次后光晕消失且不再出现

### Accessibility（Standard tier 强制）

- [ ] **AC-11** 键盘 Tab 顺序覆盖所有 11 项交互（顺序与 §Interaction Map 一致）；每个焦点显示 2px `burst_gold` 描边
- [ ] **AC-12** UI 缩放 75% / 100% / 150% 三档 + 1280×720 最小窗口下，布局不破、文字不裁切、所有 11 项交互仍可达
- [ ] **AC-13** reduced-motion 开启时，所有 transition ≤ 50ms 或 instant；idle_sheet 静态 portrait.png；新存档呼吸光晕完全关闭

### 资产覆盖（Sprint 11 DoD §15）

- [ ] **AC-14** 本屏挂载 **17 个资产路径**：§1 theme.tres + §8 main_base.png + §10 portrait.png + §10 idle_sheet.png + §4 全 4 stance icons (meditate/condense/closed_door/idle) + §13 manual_click_pulse.png + §13 overflow_warn_flash.png + §3 当前境界图标 (动态切换 7 选 1) + §2 5 资源图标 (lingqi/xiuwei/lingshi/herb/exp) + §5 overflow_warn.png — 通过 `production/qa/evidence/sprint-11/cultivation-screen-asset-snap.png` 截图证明全部可见

---

## Open Questions

| Question | Owner | Deadline | Resolution |
|---|---|---|---|
| OutputMultiplierSystem 是否新增 `get_breakdown(resource_id)` + `simulate_tick_for(stance, seconds)` 2 个 query API？阻塞试算与拆解功能 | technical-director + game-designer | Sprint 11 启动前 | ✅ **部分解决** — `get_breakdown` 已在 OMS GDD §Detailed Design #8 定义（返回 Dictionary）；`simulate_tick_for` 已立 ADR-0017（2026-05-05 Proposed）；如 ADR-0017 否决则本屏降级到 §States.OMS Breakdown API Missing |
| 新存档时本屏是否触发"姿态选择"引导（onboarding 第一决策）？还是默认 meditate 静默通过？ | ux-designer + producer | Sprint 11 startup playtest | 未解决 — 倾向：默认 meditate 静默 + 手动修炼按钮呼吸光晕作为唯一 onboarding 提示 |
| 试算面板的 5 档 duration（10s / 30s / 1min / 5min / 30min）是否需要自定义输入（spinner）？ | game-designer | Sprint 11 dev | 未解决 — 倾向：MVP 5 档；post-MVP 加自定义 spinner |
| `cultivation.stance_changed` 事件是否扩展 metadata 字段记录 `applied_via: simulator`？涉及 cultivation-system 接口扩展 | game-designer | Sprint 11 dev | 未解决 — 倾向：MVP 不扩，telemetry 走旁路；事件保持纯净 |
| HERO ZONE 立绘 480×680 与 LEFT NAV 折叠态 48px 在 1280×720 最小窗口下的兼容性？需 art-director 测试比例 | art-director + ui-programmer | Sprint 11 hud-real-layout S11-004 完成后 | 未解决 — 必须做 1280×720 截图验证 |
| 本屏是否参与 art-bible 状态①禅静沉浸的 60s 周期水墨云气背景动效？还是 main_base.png 静态足够？ | art-director | Sprint 11 polish | 未解决 — 倾向：MVP 静态足够，post-MVP 加云气动效 |
| TimeManager 是否暴露 `is_frozen() -> bool` 简易 getter，避免本屏每帧调 `collect_save_data()` 序列化 dict？ | technical-director | Sprint 11 dev | 未解决 — 小 ADR 或直接补 method；建议补 method |
| 新存档手动修炼按钮"呼吸光晕"具体触发 / 终止条件：仅 manual_cultivate 触发一次后终止？还是 lingqi 累积到某阈值后终止？ | ux-designer | Sprint 11 dev | 未解决 — 倾向：触发一次即终止（明确 onboarding 信号） |
| 试算结果展示精度（"+ 96.34 修为" vs "+ 96 修为"）由 NumberFormatter 哪个 mode？ | game-designer + ux-designer | Sprint 11 dev | 未解决 — 倾向：试算用 raw 模式（≥ 1 时整数显示，< 1 时 2 位小数） |
| design/player-journey.md 缺失 — 修炼屏在玩家整体 30 分钟 / 5 小时 / 长 session 中的"频率 / 时长"假设需要 journey 文档支撑 | producer + ux-designer | Sprint 11 启动前 | 未解决 — 建议 sprint-11 立项前补 player-journey.md mini 版本 |
| stance icon 的 tooltip 文案是否需要 narrative-director 润色？例如 "meditate" → "打坐 - 灵气稳定汇聚" | narrative-director | Sprint 11 polish | 未解决 — MVP 用功能性中文（"打坐"/"凝练"），polish 阶段可润色 |
