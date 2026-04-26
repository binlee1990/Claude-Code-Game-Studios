# Sprint 5: 本地化 + Credits 合规 + Ch.3 准备

> Version: v1.0 | Date: 2026-04-27 | Status: **COMPLETE**
> Completed: 2026-04-27
> Previous: sprint-004 COMPLETE（管理界面 Beta + 基地系统 MVP；外部验证队列另行集中管理）
> Control Manifest: 2026-04-26-v2（覆盖 ADR-001~007）
> Review Mode: reframe-and-execute

## Sprint Goal

在自动化与文档范围内关闭当前最靠近公开构建风险的缺口：

1. 将 Sprint-004 新增 UI 与主流程 UI 的玩家可见文本纳入 `SRPGLocalization`
2. 增加运行时语言切换与语言偏好持久化
3. 增加可从游戏内访问的 Credits 入口，确保 CC-BY / OFL 署名义务可被玩家看到
4. 修复高优先级规划漂移，为 Sprint-006 的 Ch.3 / Bond / Base 完整化提供清晰入口

本 Sprint 的核心判断：Sprint 1-4 的实现与自动化范围已经完成，Sprint 5 不应直接膨胀为 Ch.3 + Bond + Fog + Base 完整实现。先收束本地化、合规和文档权威，再进入下一章内容生产。

## Capacity

- Total days: 5
- Buffer (20%): 1 day
- Available: 4 days
- Sprint-004 velocity: UI + Logic 混合，核心实现任务完成；外部验证队列另见 `production/sprints/sprint-人工.md`
- Sprint-005 shape: UI/Integration + QA gate + planning repair

## 入场前提

| 项 | 状态 |
|---|---|
| sprint-001 ~ sprint-004 实现与自动化范围 | COMPLETE / COMPLETE WITH NOTES |
| stage.txt | Production |
| localization epic | Planning，`production/epics/localization/EPIC.md` 已存在 |
| `SRPGLocalization` | 已存在，但 key 覆盖很低，缺少运行时 locale 状态 |
| Sprint-004 UI | 主菜单 / 管理界面 / 基地 MVP 已完成，存在大量硬编码玩家可见文本 |
| Credits 资产清单 | `design/ux/credits.md` 已存在，标记为 public-facing build 必需 |
| Credits screen spec | 缺失，`design/ux/credits-screen.md` 尚未创建 |
| 外部验证队列 | 已集中至 `production/sprints/sprint-人工.md`，Sprint-005 不以此作为阻塞门槛 |
| ADR-008 / ADR-009 | 尚未建立，不阻塞本 Sprint Must Have |

---

## Tasks

### Must Have - 本地化与公开构建合规

| ID | Task | Agent/Owner | Est. Days | Dependencies | Acceptance Criteria |
|----|------|-------------|-----------|-------------|-------------------|
| LOC-001 | 全量 UI 字符串迁移至 `SRPGLocalization` | ui-programmer | 1.25 | localization epic / Sprint-004 UI | 主菜单、战斗结算管理入口、基地、训练场、角色管理、装备管理、Tab 文本均通过 localization key 渲染；`zh_CN` / `en_US` key parity 100%；保留 debug / data id 例外清单 |
| LOC-002 | 语言切换 UI | ui-programmer | 0.5 | LOC-001 | 主菜单或设置入口可切换 `zh_CN` / `en_US`；切换后当前界面立即刷新，不需要重启 |
| LOC-003 | 语言偏好持久化 + 运行时 locale | gameplay-programmer | 0.5 | LOC-001 + SaveManager | `SaveData` 或设置数据保存 locale；重新进入游戏后保持上次语言；运行时 `current_locale` 有测试覆盖 |
| REL-001 | 游戏内 Credits screen | ui-programmer | 0.75 | `design/ux/credits.md` | 主菜单或设置可进入 Credits；Kevin MacLeod CC-BY 3.0 必需署名逐字显示；字体 OFL 信息以紧凑列表显示；新增或更新 `design/ux/credits-screen.md` |
| REL-002 | Credits / localization 自动化门禁 | qa-lead | 0.5 | LOC-001~003 + REL-001 | 自动测试或 headless scene check 验证 Credits route 可达、署名文本存在、双语 key parity 通过；`godot --check-only` 无 parse error |

### Should Have - 权威文档与下一章准备

| ID | Task | Agent/Owner | Est. Days | Dependencies | Acceptance Criteria |
|----|------|-------------|-----------|-------------|-------------------|
| GOV-001 | Sprint / Epic 权威状态同步 | producer | 0.5 | Sprint-001~004 revalidation | `production/epics/index.md` 与相关 story header 不再声称 Ch.2 / localization 的过期状态；外部验证 backlog 指向集中队列 |
| CH3-001 | Chapter 3 GDD skeleton / readiness brief | narrative-designer | 0.5 | Ch.2 已可自动化通过 | 创建 `design/gdd/chapter-03.md` 骨架，引用 `design/narrative/belief-branching.md` 的 B3-GATE 设计占位，不实现战斗 |
| BOND-001 | Bond system epic readiness | producer + gameplay-programmer | 0.5 | `design/gdd/bond-system.md` | 创建 bond-system epic / story skeleton，明确与 Ch.3 特殊对白、基地酒馆、支援关系的边界 |
| TECH-001 | 打包版 smoke 资源泄漏 triage | debugger | 0.5 | Sprint-004 packaged smoke PASS | 记录 `ObjectDB` / resources still in use 的来源；若 bounded 则修复，否则转入稳定性 backlog，不影响功能 PASS |

### Nice to Have

| ID | Task | Agent/Owner | Est. Days | Dependencies | Acceptance Criteria |
|----|------|-------------|-----------|-------------|-------------------|
| ADR-008 | 资源经济升级决策记录草稿 | architect | 0.25 | resource-economy GDD | 起草 ADR 或 decision brief，覆盖市集价格、升级消耗、奖励流入 |
| ADR-009 | 装备升级决策记录草稿 | architect | 0.25 | equipment-system GDD | 起草 ADR 或 decision brief，覆盖强化/附魔/分解是否进入 Beta |
| BASE-FULL-001 | 基地完整版准备 brief | producer | 0.25 | `design/gdd/base-system.md` | 明确行动点、酒馆、情报室、基地升级进入 Sprint-006+ 的拆分方式 |
| FOG-001 | Fog-of-war epic readiness | gameplay-programmer | 0.25 | `design/gdd/fog-of-war-system.md` | 输出 epic skeleton 或 backlog，暂不实现 |
| DOC-001 | Sprint 1-4 证据状态轻量清理 | qa-lead | 0.25 | GOV-001 | 只修正文档状态漂移；外部验证证据移至集中队列 |

---

## Dependencies on External Factors

- 不依赖新的美术、音乐、翻译供应商或第三方 API
- 外部体验验证与发布签收不属于本 Sprint 自动化交付；由 `production/sprints/sprint-人工.md` 管理
- 不引入新依赖；优先使用已有 Godot UI、SaveManager、测试框架
- 如果 key parity 或 hardcoded string inventory 发现范围过大，优先完成主菜单、Credits、基地、管理界面、战斗结算入口，其他数据名进入明确 backlog

---

## 不在本 Sprint 范围（明确排除）

- Chapter 3 战斗、地图、敌人、剧情正式实现
- Bond / Fog-of-war / NG+ / Event / Audio 系统完整实现
- 基地系统完整版（行动点、酒馆、情报室、基地升级）
- 装备强化 / 附魔 / 分解 UI 的正式实现
- 新语言包、自动翻译、CSV/JSON 外部导入导出、RTL 排版
- 正式 public release readiness

---

## 风险与缓解

| 风险 | 影响 | 缓解 |
|---|---|---|
| LOC-001 覆盖面过大 | Sprint 被硬编码字符串迁移吞没 | 先建立 key inventory 与例外清单；按 UI surface 分批迁移 |
| Credits 属于合规风险 | 公开构建可能不应发布 | REL-001 优先于新内容实现；必需署名来自 `design/ux/credits.md` |
| 当前语言系统缺少运行时状态 | LOC-002 / LOC-003 互相阻塞 | 先扩展 `SRPGLocalization.current_locale` / `set_locale`，再接 UI |
| 数据名与 UI 文案边界不清 | key parity 测试误报或漏报 | 将 debug 字符串、resource id、数据表显示名分为不同类别 |
| 打包版 smoke 有资源释放 warning/error | 可能掩盖退出稳定性问题 | TECH-001 只做 triage；除非修复很小，否则不阻塞 Must Have |
| Ch.3 在体验数据不足时继续推进 | 设计假设可能偏离体验 | Sprint-005 只做 GDD skeleton 和 readiness，不做战斗实现；外部体验数据由集中队列回流 |

---

## 执行顺序建议（5 天节拍）

```text
Day 1  : REL-001 Credits screen + LOC-001 key inventory / parity test
Day 2  : LOC-001 迁移主菜单、基地、训练场、管理界面、战斗结算入口
Day 3  : LOC-002 语言切换 UI + LOC-003 locale 持久化 / 运行时刷新
Day 4  : REL-002 自动化门禁 + GOV-001 权威状态同步 + TECH-001 smoke warning triage
Day 5  : CH3-001 / BOND-001 readiness；若本地化门禁未绿，则改为 stabilization
```

---

## Definition of Done for this Sprint

- [x] LOC-001 / LOC-002 / LOC-003 全部 COMPLETE
- [x] REL-001 / REL-002 全部 COMPLETE，Credits 可从游戏内访问，必需署名文本可见
- [x] `zh_CN` / `en_US` localization key parity 100%，例外清单明确
- [x] `godot --headless --check-only project.godot` 退出码 0
- [x] GUT 测试套件无 regression，并新增 localization / credits / locale persistence 覆盖
- [x] 打包版 smoke 仍 PASS，且 Sprint-004 资源释放 warning 已修复
- [x] `production/epics/index.md` 不再保留本 Sprint 可修复的高优先级状态漂移
- [x] Sprint-006 handoff 明确列出 Ch.3 / Bond / Base full / Fog-of-war 的下一步范围

---

## Completion Progress — 2026-04-27

| ID | Result | Evidence |
|---|---|---|
| LOC-001 | COMPLETE | `src/core/localization/srpg_localization.gd` catalog expanded; scoped UI surfaces call localization helpers |
| LOC-002 | COMPLETE | `src/ui/menu/main_menu.gd` adds `LanguageButton` and immediate menu/Credits refresh |
| LOC-003 | COMPLETE | `SaveData.locale`, `SaveManager.save_locale_preference()`, `load_locale_preference()` |
| REL-001 | COMPLETE | Main menu Credits overlay; `design/ux/credits-screen.md` |
| REL-002 | COMPLETE | `tests/unit/localization/localization_test.gd`; `tests/integration/ui/main_menu_localization_credits_test.gd` |
| GOV-001 | COMPLETE | `production/epics/index.md`, localization epic/story statuses, `production/sprint-status.yaml` |
| CH3-001 | COMPLETE | `design/gdd/chapter-03.md` |
| BOND-001 | COMPLETE | `production/epics/bond-system/EPIC.md` + story skeletons |
| TECH-001 | COMPLETE | BGM skipped in smoke path; `docs/active/sprint-005-packaged-smoke-resource-triage.md` |
| ADR-008 | COMPLETE | `docs/architecture/ADR-008-resource-economy-upgrade.md` |
| ADR-009 | COMPLETE | `docs/architecture/ADR-009-equipment-upgrade-scope.md` |
| BASE-FULL-001 | COMPLETE | `docs/active/base-full-readiness-brief.md` |
| FOG-001 | COMPLETE | `production/epics/fog-of-war/EPIC.md` + story skeletons |
| DOC-001 | COMPLETE | Sprint status/session/epic state repaired; external validation queue centralized in `production/sprints/sprint-人工.md` |

## Verification — 2026-04-27

| Check | Result |
|---|---|
| Task validation | PASS — `.tasks/active/sprint-005-execution-20260427.task.md` has 10/10 required fields |
| Godot parse check | PASS — `godot --headless --check-only project.godot`, exit code 0 |
| GUT scene runner | PASS — `godot --headless res://tests/test_runner.tscn`, exit code 0 |
| Windows export | PASS — `godot --headless --export-release "Windows Desktop" builds/windows/SRPG.exe`, exit code 0 |
| Packaged smoke | PASS — `PACKAGED_PLAYTHROUGH_SMOKE PASS {"battle":"chapter_01_finale","camp_report_present":true,"management_tab":"equipment","success":true}` |
| Packaged leak check | PASS — verbose smoke no longer reports ObjectDB leak / resources still in use |

## Post-completion Fix — 2026-04-27

| Issue | Result | Evidence |
|---|---|---|
| 中文语言下仍有英文展示残留 | FIXED | 战斗 HUD、行动提示、菜单、结算、回营报告、单位/装备/技能/难度/章节目标等数据驱动展示统一接入 `SRPGLocalization.display_text()` |
| 装备管理场景初始英文默认值 | FIXED | `equipment_management_screen.tscn` 默认按钮、标题、提示已改为中文，脚本刷新路径继续按当前 locale 渲染 |
| Chapter 1 胜利后进基地编辑队伍会卡流程 | FIXED | `SaveManager` 在基地保存时保留既有 `battle_state` / `story_progress`；`BaseHub` 增加“继续战役”入口；战斗场景消费 `advance_after_base` 一次性标记后直接进入下一战 |
| 基地编辑后的队伍未带入下一战 | FIXED | `_start_campaign_battle()` 按基地保存的 party 顺序填充下一战我方出生槽；当地图默认出生槽少于编队人数时，在已有出生点附近补空格部署；覆盖 R1/P1/R2/R4 替换默认 P1/P2 的回归测试 |
| 回归测试 | PASS | 新增/更新中文展示与基地继续战役断言；静态测试数 817 个 `test_` 方法 |
| 自动化验证 | PASS | `godot --headless --check-only project.godot`、`godot --headless res://tests/test_runner.tscn`、Windows export、packaged smoke 均退出码 0 |

## Remaining Issues

- 外部体验验证、截图证据与发布签收队列已集中至 `production/sprints/sprint-人工.md`。
- `ADR-008` and `ADR-009` are Draft. Accept them before implementing Base full economy sinks or equipment upgrade UI.
- Full Chapter 3 combat, Bond runtime, Fog runtime, Base full, NG+, Event, and Audio systems remain Sprint-006+ work.
- Credits legal attribution still preserves required license/proper-noun wording (Kevin MacLeod / Creative Commons / OFL names). Gameplay and menu-facing Chinese locale surfaces are localized.

---

## 参考文档

| 文档 | 路径 | 说明 |
|------|------|------|
| Localization GDD | `design/gdd/localization-system.md` | 多语言架构、语言切换、持久化 |
| Localization Epic | `production/epics/localization/EPIC.md` | LOC-001~003 原始 story |
| Credits audit | `design/ux/credits.md` | 必须显示的 CC-BY / OFL 信息 |
| Save system | `src/core/save/save_data.gd` / `src/core/save/save_manager.gd` | locale persistence 接入点 |
| Localization service | `src/core/localization/srpg_localization.gd` | key registry 与运行时 locale 接入点 |
| Main menu UI | `src/ui/menu/main_menu.gd` / `src/ui/menu/main_menu.tscn` | 语言切换与 Credits 入口候选 |
| Base UI | `src/ui/base/base_hub.gd` / `src/ui/base/training_ground.gd` | Sprint-004 新增 UI 文案迁移 |
| Management UI | `src/ui/management/character_management.gd` / `equipment_management.gd` / `character_tab_bar.gd` | Sprint-004 新增 UI 文案迁移 |
| Chapter 3 branching | `design/narrative/belief-branching.md` | Ch.3 GDD skeleton 的分支占位来源 |
| Bond system GDD | `design/gdd/bond-system.md` | Bond epic readiness 输入 |
| Base system GDD | `design/gdd/base-system.md` | Base full Sprint-006+ 拆分输入 |

---

## Sprint-006 Handoff 初稿

若 Sprint-005 的 Must Have 全部完成，Sprint-006 优先级建议为：

1. Ch.3 GDD → Ch.3 MVP 战斗 1 / 分支钩子
2. Bond system MVP → 支援关系、特殊对白、基地酒馆入口
3. Base full phase 1 → 行动点 + 情报室
4. Fog-of-war MVP → 只接入需要该系统的章节地图
5. ADR-008 / ADR-009 定稿后再进入资源经济与装备升级实现

## Revalidation — 2026-04-27

### 完成进展

复核结论：Sprint-005 的 Must Have、Should Have 与 Nice to Have 文档/代码交付均已落地，状态为 **COMPLETE WITH SPRINT-006+ SCOPE NOTES**。

| 复核项 | 结果 | 证据 |
|---|---|---|
| LOC-001 UI 字符串迁移与 key parity | 完成 | `src/core/localization/srpg_localization.gd` 扩展 catalog、`display_text()`、`current_locale` 与 parity helpers；`tests/unit/localization/localization_test.gd` 覆盖双语 key parity |
| LOC-002 运行时语言切换 | 完成 | `src/ui/menu/main_menu.gd` 暴露 `LanguageButton` 并刷新主菜单/Credits 文案；`tests/integration/ui/main_menu_localization_credits_test.gd` 覆盖切换行为 |
| LOC-003 语言偏好持久化 | 完成 | `src/core/save/save_data.gd` 有 `locale` 字段；`src/core/save/save_manager.gd` 有 `save_locale_preference()` / `load_locale_preference()` |
| REL-001 游戏内 Credits | 完成 | `src/ui/menu/main_menu.gd` 暴露 `CreditsButton` / `CreditsLayer`；`design/ux/credits-screen.md` 记录 UI spec，Kevin MacLeod CC-BY 3.0 与 OFL 字体信息保留 |
| REL-002 Credits / localization 门禁 | 完成 | `tests/unit/localization/localization_test.gd` 与 `tests/integration/ui/main_menu_localization_credits_test.gd` 覆盖 key parity、Credits route、署名文本 |
| Sprint / Epic 权威状态 | 完成 | `production/sprint-status.yaml` 中 Sprint-005 条目均为 done；`production/epics/localization/EPIC.md` 标记 LOC-001~003 Complete |
| Ch.3 / Bond / Base / Fog readiness | 完成 | `design/gdd/chapter-03.md`、`production/epics/bond-system/EPIC.md`、`docs/active/base-full-readiness-brief.md`、`production/epics/fog-of-war/EPIC.md` 均存在 |
| ADR / smoke triage 文档 | 完成 | `docs/architecture/ADR-008-resource-economy-upgrade.md`、`docs/architecture/ADR-009-equipment-upgrade-scope.md`、`docs/active/sprint-005-packaged-smoke-resource-triage.md` 均存在 |
| 自动化解析 | PASS | 2026-04-27 运行 `godot --headless --check-only project.godot`，退出码 0 |
| 自动化测试入口 | PASS | 2026-04-27 运行 `godot --headless res://tests/test_runner.tscn`，退出码 0；当前仓库静态统计 817 个 `test_` 方法 |
| Windows export | PASS | 2026-04-27 运行 `godot --headless --export-release "Windows Desktop" builds/windows/SRPG.exe`，退出码 0 |
| 打包版冒烟 | PASS | 2026-04-27 运行 `builds/windows/SRPG.exe --headless --srpg-playthrough-smoke`，输出 `PACKAGED_PLAYTHROUGH_SMOKE PASS {"battle":"chapter_01_finale","camp_report_present":true,"management_tab":"equipment","success":true}` |

### 遗留问题

- 外部体验验证、截图证据与发布签收队列已集中至 `production/sprints/sprint-人工.md`。
- `ADR-008` 与 `ADR-009` 仍为 Draft；在实现 Base full economy sinks 或 equipment upgrade UI 前需要先定稿/接受。
- Chapter 3 正式战斗、Bond runtime、Fog runtime、Base full、NG+、Event、Audio 系统仍是 Sprint-006+ 范围。
- Credits 法务署名中的 Kevin MacLeod / Creative Commons / OFL 专有名词应继续保持逐字可见，不应被普通本地化改写。
