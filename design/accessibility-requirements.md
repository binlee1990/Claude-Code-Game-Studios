# Accessibility Requirements: 修仙放置挂机刷宝 RPG

> **Status**: Committed
> **Author**: ux-designer + producer（占位作者，由实际负责人接手前为代表）
> **Last Updated**: 2026-05-04
> **Accessibility Tier Target**: **Standard**
> **Platform(s)**: PC（Steam 优先；Web / 移动端为后续可选）
> **External Standards Targeted**:
> - WCAG 2.1 Level AA（对比度、文本缩放、键盘可操作）
> - AbleGamers CVAA Guidelines — 部分采纳
> - Xbox Accessibility Guidelines (XAG) — N/A（不在主线发行平台）
> - PlayStation Accessibility (Sony Guidelines) — N/A
> - Apple / Google Accessibility Guidelines — N/A（移动端非首发）
> **Accessibility Consultant**: 暂未聘请；如未来发行规模扩大可评估接入 AbleGamers Player Panel
> **Linked Documents**:
> - `design/gdd/systems-index.md`
> - `design/art/art-bible.md`（Section 4.6 已先行交付色弱安全 + 8 阶稀有度多重 backup）
> - `docs/architecture/architecture.md`（Autoload / UI 屏幕架构与 Theme token）

> **Why this document exists**：本文件锁定项目级无障碍承诺、特性矩阵、测试计划与审计历史。
> 单屏 UX 注释属于各 `design/ux/[screen].md`，本文件优先级高于任何后续 UX 决策——
> 任何与本承诺冲突的功能须改回功能本身，而不是降低承诺，除非 producer 走正式修订流程。
>
> **路径备注**：本文件位于 `design/accessibility-requirements.md`（与 `gate-check` skill 一致）。
> 旧 `design/CLAUDE.md` 曾标注 `design/ux/accessibility-requirements.md` 为路径，已于
> 2026-05-04 同步修正为本路径。如发现仍有引用 `design/ux/` 路径，请提交修复。
>
> **当前作者范围**：精简过 gate 版本——头部承诺 + tier + rationale + 顶层特性表 + 已知限制 +
> art-bible 交叉引用。**Per-Feature Accessibility Matrix、Gameplay-Critical SFX Audit、
> 完整 Test Plan、Audit History 标为 Deferred**，将在 Pre-Production / Production 阶段
> 随系统实现增量补全。

---

## Accessibility Tier Definition

> **Why define tiers**：无障碍非二元。四阶给团队共享词汇、强制制作前明确承诺、
> 防止"以后再说"和"全都要支持"两个方向的 scope creep。

| Tier | Core Commitment | 投入度 |
|------|----------------|--------|
| **Basic** | 关键文本可在标准分辨率下阅读；颜色不作为唯一区分；音乐/SFX/语音音量独立可控；无光敏风险。 | 低 |
| **Standard** | Basic + 全平台输入重映射、字幕带说话人识别、可调字号、至少一种色弱模式、不可有不能延长/取消的计时输入。 | **中（本项目目标）** |
| **Comprehensive** | Standard + 菜单 screen reader、单声道音频、辅助难度、HUD 可重定位、reduced motion 模式、所有关键音效有视觉等价。 | 高 |
| **Exemplary** | Comprehensive + 全字幕定制、高对比模式、认知辅助、所有音频有触觉/振动等价、外部第三方无障碍审计。 | 极高 |

### This Project's Commitment

**Target Tier**: **Standard**

**Rationale**：

1. **题材与玩法定位**：本项目是 2D UI 重度的中文修仙半放置 RPG，95% 的视觉是面板、列表、图标。
   Reading-heavy + 长 session（4+ 小时）使**视觉障碍**成为最大风险，不是动作类游戏的运动 / 反应障碍。
2. **Standard 精准命中本项目主要风险**：input remapping 覆盖 PC 鼠键 / 手柄；text scaling
   是中文长 session 的硬需求；colorblind + 4.5:1 对比已通过 art-bible Section 4.6 提前交付；
   "无不可延长的计时输入"与本项目"放置 = 低频高价值决策"理念天然一致。
3. **Comprehensive 不在能力范围**：menu screen reader 需 Godot 4.6 AccessKit 集成 + UI 树重构；
   HUD repositioning 在 idle 游戏场景下边际价值低（HUD 几乎是常驻而非战斗 HUD）；reduced motion
   的部分价值已被 art-bible Section 2 的"数据区不参与情绪渲染"+"burst 状态 3s 衰减"自然部分满足。
4. **Exemplary 不实际**：单团队 / 无专门无障碍预算 / 无外部审计预算。强行声明只会破坏可信度。
5. **降级 Basic 的代价**：会失去色弱玩家（约 8% 男性）+ 中文小字号阅读受困玩家（弱视、老花）+
   弱手柄玩家无 remap 支持。AbleGamers 数据估算合并影响 ≥ 12% 目标受众。

**Features explicitly in scope (beyond tier baseline)**：

- **8 阶稀有度三重 backup**（颜色 + 形状 + 数字 + 图标）—— 由 art-bible Section 4.6 锁定。
  超出 Standard tier 对"colorblind mode"的最低要求（Standard 只要求"至少一种色弱模式"）。
- **WCAG AAA 字幕背景对比度 7:1**—— 中文字幕在密集面板上需要更高对比，比 Standard 默认的 4.5:1 高一档。
- **三种色弱模式（Protan / Deutan / Tritan）全覆盖**—— Standard 只要求"至少一种"。

**Features explicitly out of scope**：

- **Menu screen reader（NVDA / Windows Narrator passthrough）**—— Godot 4.6 AccessKit 支持但
  需要 UI 树标注重构，超出当前能力。记入 Known Intentional Limitations 与 Open Questions。
- **HUD element repositioning**—— idle 游戏 HUD 不是战斗 HUD，可重定位价值低；不投入。
- **Tactile / haptic 替代音效**—— PC 主线发行无 DualSense/Xbox controller 必备假设。

---

## Top-Line Feature Commitments（顶层特性表）

> **范围说明**：完整的 per-feature 表（含每行 Status / Implementation Notes / Test Method）
> 在模板原表里。本精简版只列**项目级承诺**与**已落地 / 待开工**状态。下次完整填表时回填。

### Visual Accessibility

| 承诺 | 状态 | 来源 / 备注 |
|------|------|-------------|
| 4.5:1 对比度（可交互文本与背景） | **已锁** | art-bible Sec 1 第 2 原则 + Sec 4.1 token table |
| 1.5:1 对比度（背景装饰上限） | **已锁** | art-bible Sec 1 第 2 原则 |
| 字幕背景对比度 7:1（WCAG AAA） | **已锁** | 本文件 in-scope 升级 |
| 三种色弱模式（Protan / Deutan / Tritan） | **已设计** | art-bible Sec 4.6 矩阵；待实现 |
| 8 阶稀有度颜色之外的 backup（形状 + 文字 + 图标） | **已锁** | art-bible Sec 4.6 三表 |
| UI 缩放 75%–150%（默认 100%） | 待实现 | Pre-Production |
| 中文字幕字号 ≥ 32px @ 1080p | 待实现 | Pre-Production |
| 中文菜单字号 ≥ 24px @ 1080p | 待实现 | Pre-Production |
| 中文 HUD 关键信息 ≥ 20px @ 1080p | 待实现 | Pre-Production |
| 光敏 / 闪烁警告（启动前） | 待实现 | Pre-Production；art-bible Sec 2 已限定 burst 3s 衰减、burst 状态非高频 |

### Motor Accessibility

| 承诺 | 状态 | 来源 / 备注 |
|------|------|-------------|
| 全输入重映射（鼠键 + 手柄） | 待实现 | Pre-Production |
| 输入方法热切换（鼠键 ↔ 手柄无重启） | 待实现 | Pre-Production |
| 无强制计时输入（QTE / 反应窗） | **设计承诺** | 本项目核心理念："放置 = 低频高价值决策"，天然契合 |
| Hold-to-press 替代为 toggle | 待实现 | Pre-Production；适用于"长按修炼""长按加速"等 |
| 无 button mashing | **设计承诺** | 自动战斗主导，玩家不做高频点击 |

### Cognitive Accessibility

| 承诺 | 状态 | 来源 / 备注 |
|------|------|-------------|
| 任意状态可暂停（含战斗 / 离线结算 / 突破动画） | 待实现 | 离线结算需特别确认可暂停 |
| 教程文本可在帮助页随时回查 | 待实现 | 关联系统 38（教程系统）+ 39（百科） |
| 当前任务 / 目标 ≤ 2 次按键可达 | 待实现 | 关联系统 212（任务/目标系统） |
| 自动消失对话窗 ≥ 5 秒 或 改为玩家确认 | **设计承诺** | 本项目偏好玩家确认而非自动消失 |
| 关键音效有视觉等价（突破成功 / 稀有掉落 / 失败） | **已锁** | art-bible Sec 2 八状态视觉锚点已显式给出 |

### Auditory Accessibility

| 承诺 | 状态 | 来源 / 备注 |
|------|------|-------------|
| 字幕（叙事文本 / 教程 / 关键事件提示） | 待实现 | 本项目无大规模 voice acting，"字幕"主要是事件文本与教程 |
| 独立音量条（Music / SFX / Voice / UI）| 待实现 | 关联系统 41（音频系统）+ 45（设置系统） |
| 关键音效（突破 / 稀有掉落 / 失败 / 离线结算）有视觉 backup | **已锁** | art-bible Sec 2 八状态视觉锚点 |
| Mono audio option | **降级 — 不在 Standard 必需**；视后续社区反馈在 Comprehensive 升级时补 |

---

## Known Intentional Limitations

| 缺失功能 | 所需 Tier | 不做的原因 | 风险 / 影响 | 缓解 |
|----------|----------|------------|------------|------|
| 菜单 screen reader（NVDA / Windows Narrator passthrough） | Comprehensive | 需 Godot 4.6 AccessKit 集成 + UI 树访问性标注重构；超出当前工程能力。 | 全盲玩家无法独立导航菜单。 | 在 Settings 内提供高对比模式 + 极大字号；视社区反馈在 v1.x 评估投入。开放问题入 Open Questions。 |
| HUD 元素可重定位 | Comprehensive | idle 游戏 HUD 是常驻面板，非战斗 HUD；可重定位边际价值低且工程量大。 | 头部追踪 / 眼控玩家可能无法将 HUD 移到舒适视野。 | 提供"紧凑 / 标准 / 大字号"三种 HUD 预设布局，覆盖大部分需求。 |
| 触觉 / 振动替代音效（DualSense / Xbox controller haptic） | Exemplary | 主线 PC 发行不强假设玩家持有 DualSense / Xbox controller。 | 听障玩家少一条 backup 通道。 | 本项目所有关键音效已有视觉 backup（art-bible Sec 2），听障玩家不会因此遗漏关键信息。 |
| 中文字幕全样式定制（字体 / 颜色 / 背景 / 位置） | Comprehensive | Godot 中文字体管线工程量大。 | 阅读障碍 / 弱视玩家少一档定制空间。 | 提供"标准 / 高可读"两套字幕预设作为部分缓解。 |

---

## Per-Feature Accessibility Matrix

> **Deferred** — 在每个 GDD 通过 `/design-review` 后，回填该系统在 Visual / Motor / Cognitive /
> Auditory 四列的具体顾虑与处置。当前空表，待 Pre-Production / Production 增量补。

模板（实际填写时按 `design/gdd/systems-index.md` 系统列表展开）：

| System | Visual | Motor | Cognitive | Auditory | Addressed | Notes |
|--------|--------|-------|-----------|----------|-----------|-------|
| _待 Pre-Production 接手_ | | | | | | |

---

## Gameplay-Critical SFX Audit

> **Deferred** — 待音频系统（GDD 41 / 42）实现并入正式 sprint 后逐音效审计。
> 本项目几乎无 voice acting，主要 SFX 类别预计为：UI 点击、突破成功、稀有掉落、
> 失败 / 战斗失利、离线结算、天劫倒计时、子玩法波次切换。所有上述均已在 art-bible Sec 2
> 显式获得视觉锚点。

---

## Accessibility Test Plan

> **Deferred** — 在 Pre-Production / Production 进入 QA 阶段前回填。最低需覆盖：
> (1) 自动化对比度扫描（所有 UI 截图）；
> (2) Coblis 模拟器跑三种色弱模式截图；
> (3) 全输入手动 remap 走一遍主流程；
> (4) Hold-to-press toggle 模式走一遍核心循环；
> (5) 关键音效屏蔽测试（mute 全部 SFX 后能否完成主流程）；
> (6) 字号 75% / 100% / 150% 三档全 UI 走查。
>
> 与 `tests/smoke/critical-paths.md` 第 14–15 条 ("可访问性") 联动。

---

## Audit History

> **Deferred** — 首次正式审计建议在 Pre-Production 末尾或第一次 vertical-slice playtest 后进行。
> 自审计 / 外部审计每次落到下表。

| Date | Auditor | Type | Scope | Findings | Status |
|------|---------|------|-------|---------|--------|
| 2026-05-04 | gate-check skill | 文件存在性检查 | 本文件创建 + tier 承诺 | 通过 — Pre-Production gate blocker 3 解除 | 通过 |

---

## External Resources

| Resource | URL | Relevance |
|----------|-----|-----------|
| WCAG 2.1 | https://www.w3.org/TR/WCAG21/ | 对比度、文本缩放、键盘可操作的基础标准 |
| Game Accessibility Guidelines | https://gameaccessibilityguidelines.com | 游戏专用清单，按类别 + 成本组织 |
| AbleGamers Player Panel | https://ablegamers.org/player-panel/ | 玩家测试服务（如未来扩大发行可评估） |
| Colour Blindness Simulator (Coblis) | https://www.color-blindness.com/coblis-color-blindness-simulator/ | 色弱模式截图模拟 |
| Godot AccessKit 集成说明 | https://docs.godotengine.org/en/stable/tutorials/ui/accessibility/ | Godot 4.5+ 菜单 screen reader 集成（未来评估 Comprehensive 升级时使用） |

---

## Open Questions

| Question | Owner | Deadline | Resolution |
|----------|-------|----------|-----------|
| Godot 4.6 AccessKit 是否可对动态 HUD 元素生效，还是只支持静态菜单？ | ux-designer | Pre-Production gate 前 | 未解决 — 需查 `docs/engine-reference/godot/` |
| 中文字幕字号在 1080p 下是否需要从 32px 上提到 36px（笔画密集）？ | ux-designer | 第一次 vertical slice playtest 时验证 | 未解决 |
| 离线结算页是否完全可暂停（玩家阅读时不计时跳过）？ | systems-designer | Pre-Production | 未解决 — 设计承诺已在本文件，但实现端需确认 |
| Standard tier 的"无不可延长计时输入"是否覆盖天劫倒计时（GDD 181）？倾向：天劫属境界突破挑战，可由"准备度"前置降低风险，不算计时输入。 | game-designer + ux-designer | Pre-Production | 未解决 |

---

## Cross-Reference Index

- **art-bible Section 1** — 4.5:1 / 1.5:1 对比度法则
- **art-bible Section 2** — 八状态视觉锚点已为关键音效提供视觉等价
- **art-bible Section 4.1** — base palette token + 对比度数据
- **art-bible Section 4.6** — 色弱安全矩阵 + 8 阶稀有度三重 backup
- **`docs/architecture/architecture.md`** — UI 屏幕架构（ADR-0011）
- **`tests/smoke/critical-paths.md`** — 可访问性 smoke 测试条目
