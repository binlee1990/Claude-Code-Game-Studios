# UX Spec: 战斗屏 (Combat Screen)

> **Status**: Draft
> **Author**: binlee1990 + ux-designer
> **Last Updated**: 2026-05-05
> **Journey Phase(s)**: 待补 — design/player-journey.md 不存在；本 spec 假设战斗屏在玩家完成 onboarding 后（约 3–5 分钟）首次解锁，是 game-concept §10.2 第二条可玩闭环的载体
> **Platform Target**: PC (Steam/Epic) — Keyboard/Mouse + Gamepad Partial
> **Template**: UX Spec
> **Sprint**: Sprint 11 / mvp-screens / S11-010
> **Asset Manifest 引用**: §8 starter_forest / east_sea_shore / ruined_temple（按 zone_id 动态背景）+ §10 idle_sheet / attack_sheet / hurt_sheet / death_sheet（玩家四态动画）+ §11 starter+mid+end zone 全 27 enemy PNG（按 enemy_id 动态加载，含 ghost_flame projectile）+ §5 combat_active / combat_failed（战斗状态）+ §9 failure_grey（失败覆层）+ §13 crit_hit_spark / victory_burst_gold / zone_transition_ink_wipe_01..04（VFX 与转场）

---

## Purpose & Player Need

战斗屏（Combat Screen）是玩家"刷怪变强"的**实时观战台**。HUD 顶栏回答"我在哪个区域 / 战斗状态是什么"——本屏回答**"我在打什么 / 打得怎么样 / 下一站去哪"**。

### 核心玩家目标

1. **选择挂机区域** — 3 个 MVP zone（starter_forest / east_sea_shore / ruined_temple）水平 tab 切换；锁定 zone 显示 lock icon + hover tooltip 解锁条件。这是战斗屏唯一的玩家决策点（pillar 4.2：低频高价值）。
2. **实时观战** — 当前敌人 portrait + health bar + 名称/等级 + 玩家 4 态动画（idle / attack / hurt / death）随 combat events 切换。玩家"看见战斗在发生"。
3. **监控队伍状态** — HP / ATK / 暴击率等核心战斗属性常驻可见；遭遇计数 + 胜率实时刷新（coalesced ≤ 10Hz）。
4. **阅读战斗日志** — P-FBK-03 Battle Log Scroll 在 RIGHT PANEL 常驻展开（替换 HUD 临时 RichTextLabel）；每行 = 时间戳 + 动作 + 结果；暴击/击杀/失败颜色编码。
5. **沉浸区域氛围** — 按 zone_id 动态切换全屏背景（starter_forest / east_sea_shore / ruined_temple）；zone 切换时触发 zone_transition_ink_wipe 转场动画。

### Sentence form

> "The player arrives at this screen wanting to **select a zone**, **watch** their character auto-battle enemies, **track** team performance, and **feel** the danger and reward of each region through ambient art and combat feedback."

### 反向定义（这里不做什么）

- ❌ 不提供手动攻击按钮（半自动战斗 GDD 已明确：系统自动 Seeking → Resolving → Rewarding；玩家不逐帧操作技能）
- ❌ 不做技能树 / 装备配置（各自有专门屏或 modal，本屏不污染）
- ❌ 不做掉落详情浮层（掉落通过 P-FBK-01 Toast + RIGHT PANEL 日志行显示；全量背包看资源屏）
- ❌ 不做 Boss 专属界面（Boss 系统 post-MVP，Sprint 11 范围外）
- ❌ 不做离线战斗模拟 UI（离线结算走 offline_settlement_screen / drawer，本屏只管在线战斗）
- ❌ 不显示修炼姿态切换（修炼屏专属，战斗屏不承载）
- ❌ 不做详细伤害公式拆解面板（debug 控制台 `combat_breakdown` 负责；本屏仅战斗日志详细模式提供简要公式）

### 与 game-concept §10.2 的关系

本屏是**第二条可玩闭环的载体**（战斗 → 掉落 → 变强 → 挑战更高级区域）；玩家从修炼屏积累资源后，切到战斗屏"把资源转化为实力验证"。game-concept §7 的 5 分钟 / 30 分钟循环中，玩家至少回本屏一次"看看打不打得过下一个区域"。

### Pillar 锚定

- **4.2 放置 = 低频高价值决策** — 区域选择是 5 分钟 / 30 分钟尺度的决策；战斗过程自动运行
- **4.3 刷宝提供惊喜** — 战斗日志滚动 + 稀有掉落 Toast 提供"下一把可能出好东西"的期待感
- **4.6 渐进叙事** — 3 区域从安全→危险逐步解锁，玩家感受到世界在扩展
- **4.7 子玩法服务主循环** — 战斗产出（exp / 材料 / 灵石）直接回流修炼与资源系统

---

## Player Context on Arrival

| 维度 | 答案 |
|------|------|
| **何时首次遇到** | 新存档 onboarding 后约 3–5 分钟（首次解锁第一个战斗区域"灵谷起始"后）；玩家从修炼屏通过 LEFT NAV "⚔战斗" 或按 `2` 主动切过来 |
| **之前在做什么** | **新玩家**：刚在修炼屏完成首次手动修炼 + 切过姿态，灵气开始累积，想要"试试身手"；**老玩家**：从其他屏切回来检查"掉落如何 / 是不是该换区域了" |
| **情绪状态（设计假设）** | **期待 + 轻度兴奋** — 不是 Boss 前的高紧张，但比修炼屏的 calm 高半档。玩家来这里是"看自己打怪变强"。锚点：art-bible 状态①禅静沉浸为底 + 状态⑦离线金白的"期待感"色调微升 |
| **主动 vs 被动** | **主动** — 玩家主动从 LEFT NAV 切过来检查战斗进度；战斗屏不是默认首屏 |

### 派生设计含义（约束 Layout 与 Transitions）

- **第一眼焦点**：当前敌人 portrait（玩家先看"我在打什么"，再看"打得怎么样"）
- **区域选择器置顶**：因为是最重要的低频决策，放在 CENTER CONTENT 顶部视觉优先位
- **离开时无确认**：本屏没有不可逆操作（区域切换可逆，暂停/恢复无代价），从战斗屏切到其他屏不需要"确定要离开吗"
- **战斗继续后台运行**：即使离开本屏（切到修炼屏/资源屏），战斗仍在后台继续运行（SemiAutoCombatSystem 独立于 UI），玩家切回来时看到的是最新状态
- **首次进入分支**：新玩家首次打开战斗屏时，**灵谷起始已解锁 + 自动选中**、**东海岸 + 古庙遗迹锁定**（显示 🔒 图标 + hover tooltip 解锁条件）

---

## Navigation Position

战斗屏位于 **Root → ScreenStack → Combat Screen**（LEFT NAV "⚔战斗" tab，第 2 位）。所有其他主区域（修炼 / 资源 / 存档 / 离线结算）都通过 LEFT NAV 平级切换；战斗屏没有独占的"父屏"，也不通向任何子屏。

### 替代入口

| 入口源 | 触发方式 |
|--------|---------|
| LEFT NAV "⚔战斗" tab | 鼠标点击 / 键盘 ↑↓ + Enter / 手柄 D-Pad ↑↓ + A |
| 全局快捷键 `2` | 数字键 1–5 直达 5 主区域，战斗 = `2` |
| 离线结算 drawer "去战斗" 按钮 | `offline.settled` drawer 内可选"去战斗区域看看" → `open_screen("combat")` |
| 调试控制台 `goto combat` | dev only；release 构建排除（ADR-0012） |

### 不能从这里到达的地方

战斗屏**不通向**任何子屏（无层级深度）。所有 modal（设置 / zone 详情）通过 P-NAV-03 Modal Stack 浮层叠加；玩家关闭 modal 后仍在战斗屏。

---

## Entry & Exit Points

### Entry

| Entry Source | Trigger | Player carries this context |
|---|---|---|
| LEFT NAV tap | Click "⚔战斗" / Press `2` / D-Pad 选第 2 项 + A | 当前游戏状态（zone / combat_state / 队伍属性） |
| Offline drawer "去战斗" | drawer 内点击 → `open_screen("combat")` | `offline.settled` 已处理，携带离线战斗结果摘要 |
| Debug `goto combat` | dev only | — |

### Exit

| Exit Destination | Trigger | Notes |
|---|---|---|
| Cultivation screen | LEFT NAV "📊修炼" / Press `1` / LB+RB | 战斗继续后台运行 |
| Resources screen | LEFT NAV / Press `3` | — |
| Save screen | LEFT NAV / Press `4` | 触发 SaveManager auto-save |
| Settings Modal | 屏内 ⚙ / Press `Esc`（无 modal 时按 Esc 开设置，不退出本屏） | 浮层 — 关闭后仍在本屏 |
| App quit | 系统关闭 | 触发 SaveManager auto-save |

无一次性出口；所有 exit 可通过 LEFT NAV 返回，战斗后台持续运行，无不可逆状态。

---

## Layout Specification

### Information Hierarchy

按 art-bible 第 2 原则"决策优先级 = 视觉亮度"映射，从最高到最低：

1. **Hero Tier**（屏幕左中央，立即可见）— 当前威胁锚点
   - 当前敌人 portrait + idle 微动画（按 enemy_id 动态加载）
   - 敌人 health bar（当前 HP / 最大 HP，coalesced ≤ 10Hz 刷新）
   - 敌人名称 + 等级 Label
2. **Decision Tier**（CENTER CONTENT 顶部，玩家做决策时聚焦）
   - Zone Selector：3 个水平 zone tab（灵谷起始 / 东海岸 / 古庙遗迹）
   - 锁定 zone 显示 🔒 图标 + hover tooltip 解锁条件
   - 当前激活 zone 高亮 + 战斗状态点（● 绿 = 战斗中 / ○ 灰 = 待机 / ◆ 紫 = Boss（预留） / ✕ 红 = 失败）
3. **Status Tier**（屏幕右中央，玩家监控队伍用）
   - Player HP bar + ATK bar + 暴击率（常驻）
   - Player 四态动画（idle / attack / hurt / death）随 combat events 切换
   - 遭遇计数 + 当前胜率 + 连胜/连败 chip
4. **Feedback Tier**（RIGHT PANEL，实时战斗信息流）
   - P-FBK-03 Battle Log Scroll（最新 8 行可见 + auto-scroll；virtualized 保留 200 行）
   - 暴击行 `burst_gold` / 击杀行 `victory_burst_gold` / 失败行 `failure_red`
   - 简略/详细 toggle
5. **Control Tier**（CENTER CONTENT 底部，玩家偶尔操作）
   - 暂停/恢复战斗 toggle（主要控制）
   - 遇敌间隔 / 冷却倒计时显示
6. **Ambient Tier**（全屏背景，不参与交互）
   - 按 zone_id 动态切换全屏背景（starter_forest / east_sea_shore / ruined_temple）
   - zone 切换时触发 zone_transition_ink_wipe 4 帧转场动画

### Layout Zones

战斗屏占 **HUD 的 CENTER CONTENT 区**（hud.md §Layout Zones 第 3 行），即去除 TOP STRIP 64px / LEFT NAV 192px / RIGHT PANEL 320px 之后的区域。

战斗日志复用 RIGHT PANEL（320px）的 P-FBK-03，本屏不另建日志区域；战斗屏负责确保进入时 RIGHT PANEL 战斗日志**默认展开**（玩家可手动折叠；折叠偏好全局记住）。

@ 1080p 基线：CENTER CONTENT 可用区域 ≈ **1408 × 1016 px**。

| Zone | 位置 | 尺寸 @ 1080p | 内容 |
|---|---|---|---|
| **ZONE SELECTOR** | CENTER 顶部 | 1408 × 56 px | 3 个水平 zone tab + 战斗状态点 + 当前 zone 名称 |
| **ENEMY ZONE** | CENTER 左中 | 600 × 560 px | 敌人 portrait + idle animation + health bar + 名称/等级 + seeking 指示器 |
| **TEAM STATUS ZONE** | CENTER 右中 | 600 × 560 px | Player 四态 sprite + HP/ATK/暴击率 bars + 遭遇计数 + 胜率 |
| **COMBAT CONTROLS** | CENTER 底部 | 1408 × 64 px | 暂停/恢复 toggle + 遇敌间隔倒计时 + 连胜/连败 chip |
| **RIGHT PANEL** | HUD 固定右侧 | 320 × (1080 − 64) px | P-FBK-03 Battle Log Scroll + P-FBK-02 警告 chips（继承 HUD shell） |

### 屏幕安全区

- 1280×720 最小窗口：ENEMY ZONE 缩到 400×420；TEAM STATUS ZONE 等比缩；ZONE SELECTOR tab 文字缩到单字（灵/东/古）
- 4K：等比缩 + 字号 +1 档（24px → 28px）
- Steam Deck 1280×800：LEFT NAV 折叠 48px；CENTER 三段式保持比例；RIGHT PANEL 缩到 240px 或可折叠

### Component Inventory

按 zone 分组；每行标注：组件类型 / 内容 / 是否交互 / 引用 pattern 或新组件。

#### ZONE SELECTOR

| Component | Type | Content | Interactive | Pattern |
|---|---|---|---|---|
| Zone Tab × 3 | Button（互斥 toggle group） | 区域名 + 推荐等级 + 🔒 图标（locked 时） | Yes（切换区域） | **新 component**：继承 P-NAV-01 Top-Tab 样式（48px 容器 + 4px 切角分隔），但用于 zone 级导航；建议入 interaction-patterns.md 为 P-NAV-01-ZONE |
| Locked Zone Tooltip | Tooltip | hover 显示解锁条件（等级 / 前置区域完成度） | Yes（hover/focus） | P-INP-01 Tooltip |
| Combat Status Dot | ColorRect | 8×8 点：● 绿 = 战斗中 / ○ 灰 = 待机 / ◆ 紫 = Boss（预留） / ✕ 红 = 失败 | No | 复用 hud.md 战斗状态点规格 |

#### ENEMY ZONE

| Component | Type | Content | Interactive | Pattern |
|---|---|---|---|---|
| Zone Background | TextureRect | 按 zone_id 动态加载 §8 对应背景 PNG | No | — |
| Enemy Portrait | TextureRect | 按 enemy_id 动态加载 §11 portrait PNG | No | — |
| Enemy Idle Animation | AnimatedSprite2D | 按 enemy_id 动态加载 idle sheet（如可用） | No | — |
| Enemy Health Bar | ProgressBar + Label | "森林狼 Lv.3" + ██████░░ + "85%" | No（hover 显示 P-INP-01 Tooltip 攻/防/速详细数值） | **新交互**：hover enemy portrait ≥ 0.3s 弹出 P-INP-01 Tooltip 显示敌人攻/防/速 |
| Seeking Indicator | Label + AnimatedSprite2D | "搜寻中..." + 旋转墨点动画 | No | — |
| Enemy Name + Level | Label | "森林狼 / Lv.3" | No | — |

#### TEAM STATUS ZONE

| Component | Type | Content | Interactive | Pattern |
|---|---|---|---|---|
| Player HP Bar | ProgressBar + Label | "生命 ████████░░ 80%" | No | — |
| Player ATK Bar | ProgressBar + Label | "攻击 ██████░░░░ 62%" | No | — |
| Player Crit Rate | Label | "暴击率 12%" | No（hover 显示 P-INP-01 Tooltip 公式拆解） | P-INP-01 Tooltip |
| Player Sprite | AnimatedSprite2D | 按 combat_state 切换 idle / attack / hurt / death sheet | No | — |
| Encounter Counter | Label | "遭遇: 12 / 胜率: 91%" | No | — |
| Win/Loss Streak Chip | P-FBK-02 StatusChip | "连胜 ×5 🔥" / "连败 ×2 ⚠" | No | P-FBK-02 Inline Status Chip |

#### COMBAT CONTROLS

| Component | Type | Content | Interactive | Pattern |
|---|---|---|---|---|
| Pause/Resume Toggle | Button | "⏸ 暂停战斗" / "▶ 继续战斗" | Yes | — |
| Cooldown Timer | Label + ProgressBar | "冷却: 3s"（仅 failure_cooldown 期间显示） | No | — |
| Zone Threat Info | Label | "推荐 Lv.1-5 / 威胁: 低" | No | — |

#### RIGHT PANEL（继承 HUD Shell）

| Component | Type | Content | Interactive | Pattern |
|---|---|---|---|---|
| Battle Log | Virtualized List | 倒序时间线（最新在底部）+ auto-scroll；保留 200 行 | Yes（滚动 / 简略详细 toggle / 聚焦行 tooltip） | P-FBK-03 Battle Log Scroll |
| 简略/详细 Toggle | SegmentedControl | "简 / 详" | Yes | — |
| Warning Chips | P-FBK-02 Stack | 瓶颈/满仓/解锁可用 | No（hover tooltip） | P-FBK-02 Inline Status Chip |

#### 组件总数

10 个交互元素 + 16 个静态显示 = 共 26 个 UI components（不含 RIGHT PANEL 继承的 HUD 组件）。

### ASCII Wireframe

```
┌── HUD TOP STRIP (64px, 固定) ───────────────────────────────────────────┐
│ ⛬ 1.2K ◯ 850K ◇ 12.5M ❀ 234K  │  Lv.1 凡人  │  灵谷起始 ▼  │  ● ⚙   │
├──────┬───────────────────────────────────────────────────┬─────────────┤
│LEFT  │  ╔═══════════════════════════════════════════════╗ │ RIGHT PANEL │
│NAV   │  ║ ZONE SELECTOR (1408×56)                       ║ │   320px     │
│192px │  ║ ┌──────────┬──────────┬──────────┐            ║ │             │
│      │  ║ │● 灵谷起始 │  东海岸  │ 🔒古庙遗迹│            ║ │ 战斗日志 ▼  │
│📊修炼│  ║ │ Lv.1-5   │ Lv.5-10  │ Lv.10+   │            ║ │ ┌─────────┐ │
│⚔战斗│  ║ └──────────┴──────────┴──────────┘            ║ │ │ 18:32   │ │
│📦资源│  ║                                                ║ │ │  普攻   │ │
│💾存档│  ║ ENEMY ZONE          TEAM STATUS ZONE           ║ │ │ 18:32   │ │
│📅离线│  ║ (600×560)           (600×560)                  ║ │ │  暴击!  │ │
│      │  ║ ┌────────────┐ ┌──────────────────────────┐   ║ │ │ 18:33   │ │
│      │  ║ │            │ │ 生命  ████████░░  80%   │   ║ │ │  击杀   │ │
│      │  ║ │  森林狼    │ │ 攻击  ██████░░░░  62%   │   ║ │ │ 18:33   │ │
│      │  ║ │  portrait  │ │ 暴击率  12%              │   ║ │ │ +灵石   │ │
│      │  ║ │  + idle    │ │                          │   ║ │ │  ...    │ │
│      │  ║ │  动画      │ │  ▲ 主角 attack_sheet    │   ║ │ │  ▼ jump │ │
│      │  ║ │            │ │    动画（战斗中）         │   ║ │ └─────────┘ │
│      │  ║ │ ██████░░  │ │                          │   ║ │             │
│      │  ║ │  85%       │ │ 遭遇: 12  胜率: 91%      │   ║ │ [警告 chips] │
│      │  ║ │ Lv.3      │ │ 连胜 ×5 🔥              │   ║ │             │
│      │  ║ └────────────┘ └──────────────────────────┘   ║ │             │
│      │  ║                                                ║ │             │
│      │  ║ COMBAT CONTROLS (1408×64)                      ║ │             │
│      │  ║ ┌──────────────────────────────────────────┐   ║ │             │
│      │  ║ │  [⏸ 暂停战斗]    推荐 Lv.1-5 · 威胁: 低  │   ║ │             │
│      │  ║ └──────────────────────────────────────────┘   ║ │             │
│      │  ╚═══════════════════════════════════════════════╝ │             │
└──────┴───────────────────────────────────────────────────┴─────────────┘

Background: starter_forest.png 全屏 dim 30% 叠加在 CENTER 区域之下
```

> **Wireframe 注**：本 wireframe 仅展示 1080p 灵谷起始区域默认布局（combat active 状态中）。ENEMY ZONE 与 TEAM STATUS ZONE 之间有 16px 间隙。ZONE SELECTOR 当前激活 tab 高亮（`panel_bg_elevated` + 顶部 2px `burst_gold` 描边）。实际像素位由 art-director 在 Sprint 11 hud-real-layout S11-004 期间结合 theme.tres 9-slice 微调。背景图在 dim overlay 之下若隐若现。

---

## States & Variants

| State / Variant | Trigger | What Changes |
|---|---|---|
| **No Zone Selected** | 首次进入战斗屏但所有 zone locked | ZONE SELECTOR 显示 3 个 locked tab；ENEMY ZONE 显示"暂无可用区域"空状态 placeholder；TEAM STATUS ZONE 正常显示；战斗日志空 |
| **Idle (Zone Active, Combat Paused)** | zone 已选但战斗未启动或已暂停 | 战斗状态点 ○ 灰；ENEMY ZONE 显示"待机中 — 按▶开始"；player 动画 = idle_sheet；暂停按钮显示"▶ 继续战斗" |
| **Seeking** | zone 激活 + 战斗运行中，系统选敌中 | 战斗状态点 ● 绿；ENEMY ZONE 显示"搜寻中..." + 旋转墨点指示器；player 动画 = idle_sheet |
| **Combat Active** | enemy found + CombatCalculator 结算中 | ENEMY ZONE 敌人 portrait 淡入 + health bar 递减（coalesced）；player 动画 = attack_sheet；战斗日志滚动 |
| **Critical Hit** | combat event 暴击（当前通过伤害阈值模拟或未来 `combat.crit` 事件） | ENEMY ZONE 触发 crit_hit_spark VFX（220ms 单帧扩散）；战斗日志行 `burst_gold` + "暴击!" 文字 |
| **Victory** | 战斗胜利（CombatResult = win） | victory_burst_gold VFX 全屏 1s；ENEMY ZONE 敌人 fade-out 200ms；战斗日志行"击杀"；掉落以 P-FBK-01 Toast 通知（如为稀有掉落） |
| **Defeat** | 战斗失败（CombatResult = lose） | failure_grey 全屏覆层 fade-in 300ms；ENEMY ZONE dim 50%；player 动画 = death_sheet（3s 后切回 idle）；战斗日志行 `failure_red`；COMBAT CONTROLS 显示冷却倒计时 |
| **Cooldown** | 战斗失败后进入 `failure_cooldown_seconds`（默认 5s） | ENEMY ZONE 显示"休整中... Xs"；暂停按钮替换为倒计时 ProgressBar；player 动画 = idle_sheet；倒计时归零后自动恢复到 Seeking |
| **Paused** | 玩家点击暂停 | 战斗状态点 ○ 灰 + 闪烁；暂停按钮变为"▶ 继续战斗"；ENEMY ZONE health bar 冻结；player 动画暂停在当前帧；战斗日志追加"⏸ 战斗已暂停"系统行 |
| **Zone Locked** | zone unlock_conditions 未满足 | Zone tab 显示 🔒 图标 + 饱和度 −60%；hover/focus 显示 P-INP-01 Tooltip 列出解锁条件（等级 / 前置区域完成场次）；点击无响应 |
| **Zone Switching** | 玩家选择不同 zone | zone_transition_ink_wipe 4 帧转场（120ms）；背景切换；ENEMY ZONE 重置为 Seeking；战斗日志追加"→ 进入 [区域名]"系统行 |
| **Loading** | 战斗屏首次打开，资产未就绪 | ENEMY ZONE 显示 "..." 占位；TEAM STATUS ZONE 数值显示 "--"；战斗日志显示"加载中..." |
| **Empty Enemy Pool** | 当前 zone 的 enemy_pool 为空或全 invalid | ENEMY ZONE 显示"该区域暂无可用敌人"placeholder；战斗暂停；战斗日志追加"⚠ zone 数据异常"警告行 |
| **Consecutive Failure Threshold** | 连败 ≥ 5（`failure_pause_threshold`） | 自动暂停战斗；TEAM STATUS ZONE 旁出 P-FBK-02 chip "建议换区或提升属性"；暂停按钮 disabled（需玩家手动换区） |
| **Time Frozen** | `TimeManager.frozen = true` | 所有 combat 计时器冻结；暂停按钮 disabled 并显示"时间已冻结"灰字；player 动画暂停；战斗日志停止追加 |

---

## Interaction Map

输入方法：键鼠（Primary）+ 手柄 partial（D-Pad / A / B / X / Y / LB / RB / Start）。无 touch（technical-preferences `Touch Support: None`）。

| Action | Mouse / Keyboard | Gamepad | 即时反馈 | 结果 |
|---|---|---|---|---|
| 切换区域（已解锁） | Click zone tab / ←→ + Enter | D-Pad ←→ + A | zone_transition_ink_wipe 120ms + 背景切换 | `ZoneSystem.set_current_zone(zone_id)` → `zone.changed` |
| 查看锁定 zone 解锁条件 | Hover zone tab ≥ 0.3s | Focus + A（长焦 0.5s 自动弹出 P-INP-01） | tooltip fade-in 150ms | P-INP-01 — UI only（ZoneSystem 返回 lock_reason） |
| 暂停 / 恢复战斗 | Click toggle / Press `Space` | Start 键 | 按钮文字 + 图标切换 100ms；战斗日志追加系统行 | `SemiAutoCombatSystem.toggle_pause()` |
| 查看敌人详细数值 | Hover enemy portrait ≥ 0.3s | D-Pad 选 ENEMY ZONE + A | P-INP-01 Tooltip fade-in 150ms（攻/防/速） | UI only — 读 `SemiAutoCombatSystem.get_current_encounter()` |
| 查看玩家属性公式 | Hover HP/ATK/Crit bars ≥ 0.3s | D-Pad 选 TEAM STATUS + A | P-INP-01 Tooltip fade-in 150ms | UI only — 读 `AttributeSystem.get_combat_stats("player")` |
| 滚动战斗日志 | Scroll wheel / PgUp/PgDn | 右摇杆 ↑↓ | 即时滚动；向上滚暂停 auto-scroll + 底部出"↓ 跳到最新"chip | P-FBK-03 — UI only |
| 切换战斗日志简略/详细 | Click "简/详" segmented control | Y 键 | 行高变化 200ms | P-FBK-03 — UI only |
| 关闭本屏（去其他主屏） | Click LEFT NAV / 数字键 1–5 | LB / RB 切 tab | 120ms cross-fade | `UIManager.open_screen(...)` |
| 打开设置 Modal | Click ⚙ / Press `Esc`（无 modal 时按 Esc 开设置） | Start（长按 0.5s） | P-NAV-03 Modal scale-in 200ms | `UIManager.open_modal("settings")` |
| 关闭设置 Modal | Esc / Click modal 外 | B 键 | fade-out 150ms | `UIManager.close_modal()` |

### Tab Order（accessibility-requirements Standard tier 强制）

Zone Tab 1 → Zone Tab 2 → Zone Tab 3 → ENEMY ZONE（focusable readonly，hover/focus 显示 tooltip）→ TEAM STATUS ZONE HP bar（focusable readonly）→ ATK bar → Crit Rate → 暂停/恢复 toggle → RIGHT PANEL 战斗日志（focus 可滚动）→ 简略/详细 toggle。共 10 项可达交互。

---

## Events Fired

| Player Action | Event Fired | Payload |
|---|---|---|
| 切换区域（成功） | `zone.changed`（ZoneSystem 自动发，UI 不重发） | `{old_zone_id, new_zone_id}` |
| 切换区域（失败 — locked） | **无事件** — ZoneSystem 返回 lock_reason，UI 显示 P-INP-01 Tooltip | — |
| 暂停 / 恢复战斗 | **待确认** — `SemiAutoCombatSystem.toggle_pause()` 是 command，系统内部状态变化；是否发独立事件待定；战斗状态的自然断点由 `combat.encounter_started` / `combat.encounter_finished` 表达 | — |
| 战斗遭遇开始（系统驱动） | `combat.encounter_started`（SemiAutoCombatSystem 自动发） | `{enemy_id, zone_id, encounter_id, timestamp}` |
| 战斗遭遇结束（系统驱动，胜利） | `combat.encounter_finished`（SemiAutoCombatSystem 自动发） | `{encounter_id, result: "victory", loot: [...], exp_gained, duration_ms}` |
| 战斗遭遇结束（系统驱动，失败） | `combat.encounter_finished` | `{encounter_id, result: "defeat", reason: "hp_depleted" \| "timeout" \| "data_error", duration_ms}` |
| 稀有掉落（系统驱动） | `loot.rare_drop`（LootSystem 自动发） | `{item_id, rarity, quantity}` → P-FBK-01 Toast Stack 显示 |
| 暴击 | **无独立事件**（当前设计）；如 CombatCalculator 未来加 `combat.crit` 事件，本屏订阅以触发 crit_hit_spark VFX；MVP 用伤害值 > 阈值模拟 | — |
| 进入 / 离开本屏 | `ui.screen_opened` / `ui.screen_closed`（UIManager 自动发，本屏不重发） | `{screen_id: "combat"}` |
| 战斗日志滚动 / 简略详细切换 | **无事件** — 纯 UI 状态 | — |
| enemy portrait hover tooltip | **无事件** — 纯 UI 读数据 | — |

### 架构标记

- UI 自身**不写**任何持久状态；所有写入（zone 切换 / combat pause）走系统 command
- `combat.encounter_started` 和 `combat.encounter_finished` 的 payload 结构由 SemiAutoCombatSystem 定义，本屏只订阅不定义
- Player 四态动画切换由本屏监听 combat events + combat_state getter 自行驱动，不走 EventBus（纯 UI 行为）
- 连败阈值检测由 SemiAutoCombatSystem 内部处理，触发时**自动暂停** + 暴露 `recommendation_state` 供 UI 读取
- 暴击视觉效果 MVP 用伤害阈值模拟触发；post-MVP 如有 `combat.crit` 事件则改为订阅

---

## Transitions & Animations

| Trigger | Animation | Duration | Reduced-motion 替代 |
|---|---|---|---|
| 屏幕进入（LEFT NAV 切入） | cross-fade | 120ms（ui-framework `default_transition_ms`） | instant cut |
| 屏幕退出 | cross-fade out | 120ms | instant cut |
| 区域切换 | zone_transition_ink_wipe 4 帧 sprite sheet | 120ms（共 4 帧 × 30ms） | instant cut（直接切换背景） |
| 敌人出现（Seeking → Combat） | enemy portrait fade-in + scale 0.95 → 1.0 | 200ms | fade only |
| 敌人死亡（Victory） | enemy portrait fade-out + scale 1.0 → 0.9 | 200ms | instant |
| 暴击 | crit_hit_spark VFX 单帧扩散 | 220ms | 单帧静态闪一下 |
| 战斗胜利全屏 | victory_burst_gold VFX 全屏印章 | 1000ms | 缩到 300ms + 无缩放变换 |
| 战斗失败覆层 | failure_grey 全屏 fade-in | 300ms | instant 灰度 |
| 失败恢复（cooldown → idle） | failure_grey fade-out | 300ms | instant |
| 暂停 / 恢复 | 按钮文字 + 图标切换 | 100ms | instant |
| 战斗日志新行 | fade-in | 220ms | instant |
| 战斗日志简略 ↔ 详细切换 | 行高 expand/collapse | 200ms | instant |
| 掉落 Toast | 从右侧滑入（P-FBK-01） | 200ms | fade only |
| 搜寻中指示器（Seeking） | 墨点旋转循环 | 持续循环（60fps sync） | **关闭** — 静态"搜寻中..."文字 |
| Player 四态动画切换 | attack/hurt/death 按 combat events 触发；idle 循环 | sheet meta.json fps | death 静态单帧；attack/hurt 单帧静态；idle 静态 portrait.png |
| HP bar 变化 | linear fill（coalesced ≤ 10Hz 直跳，不做平滑 tween） | 即时（无动画） | 同 — 是功能性数据刷新，不算 motion |

### 禁区

- 本屏**不**触发 `burst_gold` 全屏印章（突破/飞升专用，本屏不承载）
- 本屏**不**触发 `ink_default` 印章（成就专用）
- 本屏**不**触发 `manual_click_pulse` VFX（修炼屏专用）
- 敌人 health bar 递减**不走** 0 → target 的平滑 tween（会造成玩家"还在打"的错觉）；改为 coalesced 直跳当前值
- 全屏背景水墨云气动效：如 art-bible 状态① 60s 周期横移在 polish 阶段加入，reduced-motion 下完全关闭

---

## Data Requirements

| Data | Source System | R/W | Notes |
|---|---|---|---|
| 当前 zone_id + zone 详情（enemy_pool, recommended_level, loot_modifiers） | `ZoneSystem.get_current_zone()` | Read | 已有 |
| 所有 zone 列表（含 unlock_conditions + lock_reason） | `ZoneSystem.get_all_zones()` | Read | 已有；用于渲染 ZONE SELECTOR tabs |
| zone unlock status | `ZoneSystem.is_unlocked(zone_id)` | Read | 已有；通过 MapProgressionSystem 查询 |
| 当前 enemy snapshot | `SemiAutoCombatSystem.get_current_encounter()` | Read | 包含 enemy_id / name / level / hp_current / hp_max / atk / def / spd；**待确认 API 是否存在** |
| enemy portrait + idle sheet 路径 | `EnemyDatabase.get_asset_paths(enemy_id)` | Read | 已有；返回 `{portrait, idle_sheet, attack_sheet}` |
| 玩家当前 HP/ATK/Crit | `AttributeSystem.get_combat_stats("player")` | Read | 已有；coalesced 刷新 ≤ 10Hz |
| 玩家四态动画 sheet 引用（idle/attack/hurt/death） | pipeline-meta.json 定义的路径常量 | Read | §10 player sheets 路径固定 |
| 战斗状态（idle/seeking/combat/cooldown） | `SemiAutoCombatSystem.get_combat_state()` | Read | **待确认 API 是否存在**；驱动 ENEMY ZONE + player 动画切换 |
| 遭遇计数 + 胜率 | `SemiAutoCombatSystem.get_session_stats()` | Read | 返回 `{encounters, wins, losses, win_rate, streak}`；**待确认 API 是否存在** |
| 连败次数 + recommendation_state | `SemiAutoCombatSystem.get_recommendation()` | Read | 连败 ≥ 5 时返回非 null |
| 战斗日志行 | `SemiAutoCombatSystem.get_recent_logs(n)` 或 BattleLogService | Read | P-FBK-03 消费；virtualized 保留 200 行 |
| `combat.encounter_started` / `combat.encounter_finished` 事件 | EventBus subscribe | Read | 已有；驱动动画 + VFX |
| `zone.changed` 事件 | EventBus subscribe | Read | 已有；驱动背景切换 + zone selector 刷新 |
| `loot.rare_drop` 事件 | EventBus subscribe | Read | 驱动掉落 Toast |
| `set_current_zone(zone_id)` command | `ZoneSystem.set_current_zone()` | Write（间接） | 通过命令 |
| `toggle_pause()` command | `SemiAutoCombatSystem.toggle_pause()` | Write（间接） | **待确认 API 是否存在**；如不存在则 UI 通过 `set_paused(bool)` 间接调 |
| TimeManager.frozen 状态 | `TimeManager` — 建议暴露 `is_frozen() -> bool` getter | Read | 与修炼屏相同需求；建议 TimeManager 补 method |
| 区域背景图路径 | `ZoneSystem.get_background(zone_id) -> String` | Read | **待确认 API 是否存在**；如不存在则 UI 自行按 zone_id 映射 §8 路径 |

### 架构关注

- **待确认 API × 4**：`get_current_encounter()` / `get_combat_state()` / `get_session_stats()` / `toggle_pause()` 需与 SemiAutoCombatSystem 确认；如不存在则本 sprint 补，或 UI 自行从 combat events 缓存 encounter state
- **背景图路径映射**：如 ZoneSystem 不暴露 `get_background()`，UI 需自行维护 zone_id → §8 PNG 的映射表
- UI 自身**不持有**任何 game state；所有读取走 host getter，所有写入走 command。符合 `.claude/rules/ui-code.md`

---

## Accessibility

继承 `design/accessibility-requirements.md` Standard tier。本屏特化条款：

### 视觉

- ENEMY ZONE 敌人名称 + 等级 Label ≥ 24px（菜单字号阈值）；health bar 百分比 ≥ 20px
- TEAM STATUS ZONE HP/ATK Label ≥ 20px；数值 ≥ 24px
- 所有可交互文本与背景对比 ≥ 4.5:1（art-bible 第 2 原则；theme.tres `text_primary` on `panel_bg_primary` ≈ 9:1 已满足）
- 战斗日志行 ≥ 14px（中文），颜色编码全部有文字 backup（暴击 = `burst_gold` + "暴击!" 文字；失败 = `failure_red` + "败" 文字；击杀 = `victory_burst_gold` + "击杀" 文字）
- 战斗状态点 ● / ○ / ◆ / ✕ 形状本身就是主信号，颜色为辅助（复用 hud.md 色弱 backup）
- Zone tab 锁定态 = 饱和度 −60% + 🔒 图标 + hover tooltip 文字 = 三重 backup（不依赖颜色判断锁定）
- HP bar 颜色从绿→黄→红变化 + 数字百分比文字 backup（色弱安全）
- UI 缩放 75% / 90% / 100% / 125% / 150% 五档下布局不破，文字不裁切

### 键鼠 / 手柄等价

- Tab order 见 §Interaction Map（共 10 项可达交互）
- 当前焦点元素加 2px `burst_gold` 描边（与 hud.md 对齐）
- 设置 modal 关闭：Esc / B 键
- 战斗日志滚动：滚轮 / PgUp/PgDn / 手柄右摇杆
- 手柄 partial：ZONE SELECTOR D-Pad ←→ + A；暂停 Start；简略/详细 toggle Y 键

### 时间相关

- **No timed input**：本屏无强制计时输入；暂停/恢复是 toggle，无反应窗
- 遇敌间隔 / 冷却倒计时是**系统状态显示**，不要求玩家计时操作
- 连败 ≥ 5 自动暂停 + 建议 chip 是**系统主动暂停**，不要求玩家反射

### 动作 / 体力

- **No button mashing**：无攻击按钮，符合 accessibility-requirements 承诺
- 所有可交互 hit area ≥ 32 × 32 px（按钮）/ zone tab ≥ 120 × 48 px（宽大，易于点击）
- 暂停/恢复是 toggle 行为，长按不加速

### Reduced Motion

详见 §Transitions & Animations 表"Reduced-motion 替代"列。Critical items：
- zone_transition_ink_wipe → instant cut
- enemy 出现/死亡 scale 动画 → fade only
- player death_sheet 动画 → 静态单帧 portrait
- 搜寻中旋转墨点 → 静态"搜寻中..."文字
- victory_burst_gold 全屏 → 缩到 300ms + 无缩放变换

### 已知限制

- Menu screen reader（NVDA / Narrator passthrough）— 与 accessibility-requirements 全局一致，本屏不单独实现，记入项目级 Open Questions

---

## Localization Considerations

| 元素 | 中文最长 | 设计预留宽度 | 风险 / 备注 |
|---|---|---|---|
| 区域名称（灵谷起始 / 东海岸 / 古庙遗迹） | 4–5 字 | 6 字宽度（zone tab 正常态）/ 1 字（1280×720 缩略态） | 低 — 英文 "Spirit Valley" / "East Shore" / "Ruined Temple" 在范围 |
| Zone tab 推荐等级（"Lv.1-5"） | 7 字符 | 10 字符宽度 | 低 — 格式固定 |
| 敌人名称（"森林狼" / "寒尸" / "断龙影"） | 3–4 字 | 8 字宽度（ENEMY ZONE Label 区） | **中** — 英文翻译可能超 15 字符（如 "Broken Dragon Shadow"）；需支持 autowrap 折行至双行 |
| 锁定 zone tooltip 解锁条件 | ~15 字中文 | P-INP-01 Tooltip 支持多行（≥ 3 行 autowrap） | **HIGH** — "需要等级 10 + 完成灵谷起始 20 场战斗" 翻译后可能超 60 字符；tooltip 必须支持 RichTextLabel autowrap |
| 战斗日志行（"森林狼 普攻 -12"） | ~10 字中文 | P-FBK-03 虚拟列表 + RichTextLabel autowrap | **HIGH** — 详细模式含公式拆解，英文行可能超 40 字符；必须测试德/法/西翻译长度 |
| 暂停/恢复按钮 | 4 字（"暂停战斗" / "继续战斗"） | 8 字宽度 | 低 — 英文 "Pause" / "Resume" ≈ 6 字符 |
| 连胜/连败 chip | 5 字（"连胜 ×5🔥"） | 10 字宽度 | 低 |
| 搜寻中指示器 | 4 字（"搜寻中..."） | 8 字宽度 | 低 — 英文 "Searching..." ≈ 11 字符 |
| Zone threat info（"推荐 Lv.1-5 · 威胁: 低"） | ~12 字 | 20 字宽度 | 中 — 英文更长；需测试 |

### HIGH PRIORITY 项（标记给 localization engineer）

- **锁定 zone tooltip** 内容必须用 `RichTextLabel` + `autowrap_mode = AUTOWRAP_WORD_SMART`，最少支持 3 行
- **战斗日志行** 已通过 P-FBK-03 虚拟列表 + autowrap 解决；详细模式行高 + 50%，预测试德/法/西翻译
- **敌人名称** 在 ENEMY ZONE 中需预留双行空间（中文 ≤ 4 字单行，英文可能需要折行）
- **区域名称** 在 1280×720 缩略态下需测试单字显示（如 古庙遗迹 → 古）

### 数字格式

所有 BigNumber 走 NumberFormatter；中文 / 短格式 / 科学格式由 settings 切换（参 hud-system §UI Requirements + ADR-0014）。

### 不需要本地化的元素

- 区域背景 PNG（§8）— 视觉无文字
- 敌人 portrait + sheet（§11）— 视觉无文字
- 玩家四态 sheet（§10）— 视觉无文字
- VFX（§13）— 视觉无文字
- 战斗状态点（● / ○ / ◆ / ✕）— 形状通用
- 🔒 锁定图标 — 图标通用

---

## Acceptance Criteria

按 `.claude/rules/design-docs.md` 标准；至少 10 条可测试、QA 可独立验证、不读其他文档可验证。共 14 条：

### 性能

- [ ] **AC-1** 战斗屏从触发 `open_screen("combat")` 到 Ready 状态 ≤ 200ms（含 zone background + enemy portrait 首次加载）
- [ ] **AC-2** zone_transition_ink_wipe 转场完整播放 4 帧 × 30ms = 120ms；动画期间不阻塞其他交互（zone 切换可连续触发）

### 导航

- [ ] **AC-3** LEFT NAV 点 "⚔战斗" / 数字键 `2` / 手柄 LB+D-Pad 选第 2 项 + A，3 种入口都能正确开屏（screenshot 证据 ×3）
- [ ] **AC-4** 屏内任何位置按 Esc / 手柄 B 不会退出本屏（无父屏可返回）；Esc / B 仅在 modal 打开时关闭 modal

### 核心功能

- [ ] **AC-5** Zone tabs 3 种状态正确渲染：active（`panel_bg_elevated` + 顶部 2px `burst_gold` 描边 + 状态点 ●） / available（`panel_bg_secondary` + `text_secondary` + 状态点 ○） / locked（饱和度 −60% + 🔒 图标 + hover 显示 tooltip 解锁条件）
- [ ] **AC-6** 选择 unlocked zone 后：zone_transition_ink_wipe 播放 → 背景切换 → 战斗日志追加"→ 进入 [区域名]"系统行 → `zone.changed` 事件发出 → ENEMY ZONE 进入 Seeking 态
- [ ] **AC-7** 暂停 toggle 按下后：战斗状态点 ○ 灰闪烁 → 按钮文字变为"▶ 继续战斗" → ENEMY ZONE health bar 停止更新 → player 动画冻结 → 战斗日志追加"⏸ 战斗已暂停"
- [ ] **AC-8** 战斗胜利后：victory_burst_gold VFX 1s 播放 → enemy portrait fade-out → 掉落 Toast 出现（如稀有）→ next_encounter_delay 后进入 Seeking
- [ ] **AC-9** 战斗失败后：failure_grey 覆层 fade-in 300ms → player 动画 = death_sheet（3s 后回 idle）→ 冷却倒计时显示 → cooldown 归零后自动恢复到 Seeking
- [ ] **AC-10** 连败 ≥ 5 次后：战斗自动暂停 + TEAM STATUS ZONE 旁出 P-FBK-02 chip "建议换区或提升属性" + 暂停按钮 disabled（需玩家手动换区）

### 状态

- [ ] **AC-11** TimeManager 冻结时（debug 命令触发）：COMBAT CONTROLS 显示"时间已冻结"灰字 + 暂停按钮 disabled + 战斗日志停止追加 + player 动画冻结

### Accessibility（Standard tier 强制）

- [ ] **AC-12** 键盘 Tab 顺序覆盖所有 10 项交互（顺序与 §Interaction Map 一致）；每个焦点显示 2px `burst_gold` 描边
- [ ] **AC-13** UI 缩放 75% / 100% / 150% 三档 + 1280×720 最小窗口下，布局不破、文字不裁切、zone tab 缩略正确（灵/东/古）、所有 10 项交互仍可达
- [ ] **AC-14** reduced-motion 开启时，所有 transition ≤ 50ms 或 instant；zone transition → instant cut；player animation → static portrait；searching indicator → 静态文字；victory_burst_gold → 300ms 静态闪

---

## Open Questions

| Question | Owner | Deadline | Resolution |
|---|---|---|---|
| `SemiAutoCombatSystem` 是否暴露 `get_current_encounter()` / `get_combat_state()` / `get_session_stats()` / `toggle_pause()` 这些 read/write API？如不存在，UI 需自行缓存 encounter state 还是本 sprint 补 API？ | technical-director + game-designer | Sprint 11 启动前 | 未解决 — 倾向：系统暴露简易 getter + pause command；避免 UI 做事件重放 |
| 锁定区域的解锁条件从哪个系统读取？`MapProgressionSystem` 是否已定义 unlock conditions 查询 API？ | game-designer | Sprint 11 dev | 未解决 — zone-system GDD §States 引用 MapProgression 但 API 未明确定义 |
| Player 四态动画（idle/attack/hurt/death）的切换逻辑由哪个系统驱动？UI 自行监听 combat events 还是 SemiAutoCombatSystem 暴露状态？ | game-designer + ui-programmer | Sprint 11 dev | 未解决 — 倾向：UI 监听 `combat.encounter_started` / `combat.encounter_finished` + `get_combat_state()` getter，自行驱动动画切换 |
| 战斗日志 RIGHT PANEL 在战斗屏离开后是否保持展开态？还是全局记住折叠/展开偏好？ | ux-designer | Sprint 11 dev | 未解决 — 倾向：全局记住玩家偏好；战斗屏进入时不强制展开，但首次使用默认展开 |
| 区域切换后战斗是立即从当前 zone 的 enemy_pool 开始，还是需要玩家手动点"▶ 继续"？ | game-designer | Sprint 11 dev | 未解决 — 倾向：如果之前是战斗中，切 zone 后自动继续（无缝）；如果之前是暂停，保持暂停 |
| `combat.crit` 事件当前不存在 — 暴击的 crit_hit_spark VFX 触发条件是什么？ | game-designer | Sprint 11 dev | 未解决 — 倾向：如 CombatCalculator 不暴露 crit 标记，MVP 用伤害值 > 阈值模拟；post-MVP 补事件 |
| ENEMY ZONE 中 enemy health bar 是读 CombatCalculator 实时 HP 还是只在 encounter 开始/结束之间做客户端插值？ | game-designer + technical-director | Sprint 11 dev | 未解决 — 倾向：health bar 在 encounter 期间用 coalesced 刷新（≤ 10Hz）读系统当前 HP，不做客户端插值（避免"还在打"错觉） |
| Zone 背景图路径映射（zone_id → §8 PNG）由 ZoneSystem 提供 getter 还是 UI 自行 hardcode？ | technical-director | Sprint 11 dev | 未解决 — 倾向：ZoneSystem 暴露 `get_background(zone_id) -> String`；如不暴露则 UI 读 zones.json 的 `background` 字段 |
| TimeManager 是否暴露 `is_frozen() -> bool` 简易 getter（与修炼屏相同需求）？ | technical-director | Sprint 11 dev | 未解决 — 建议补 method，修炼屏和战斗屏共享 |
| design/player-journey.md 缺失 — 战斗屏在玩家 30 分钟 / 5 小时 / 长 session 中的"频率 / 停留时长"需要 journey 文档支撑 | producer + ux-designer | Sprint 11 启动前 | 未解决 — 建议 sprint-11 立项前补 player-journey.md mini 版本 |
| 战斗屏首次解锁时机：是首次完成修炼屏手动修炼后自动弹引导（"灵谷起始已解锁 — 去看看？"），还是静默解锁等玩家自己发现？ | ux-designer + producer | Sprint 11 startup playtest | 未解决 — 倾向：静默解锁 + LEFT NAV "⚔战斗" tab 从隐藏变为显示（渐进解锁 200ms fade-in），不做强制引导 |
