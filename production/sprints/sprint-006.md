# Sprint 6: 养成深度 — Bond MVP + Equipment Enhancement + Base Phase 1

> Version: v1.1 | Date: 2026-04-27 | Status: **COMPLETE**
> Window: 2026-04-28 → 2026-05-02
> Previous: sprint-005 COMPLETE（本地化 + Credits 合规 + Ch.3/Bond/Base/Fog readiness）
> Control Manifest: 2026-04-26-v2（覆盖 ADR-001~007）+ ADR-008/009 已 Accepted（2026-04-27）
> Review Mode: solo

---

## Sprint Goal

把 Sprint-005 落实的 readiness 转成可玩养成闭环：

1. Bond 数据层 + affinity 钩子上线，让"角色之间的关系"在战斗与角色管理可见
2. 装备强化 MVP（已装备件 +1~+5）暴露 ADR-009 第一切片，让玩家能主动消耗 Sprint-004 的奖励金币/材料
3. Base 行动点 + Intel Room MVP 让基地有节奏与方向，为 Ch.3 准备入口
4. Ch.3 战斗 1 GDD 详化（不实现），为 Sprint-007 战斗实现做交付物

**不在 Sprint-006 范围**：Ch.3 战斗 1 实现 / Bond 酒馆对话（依赖 Base Tavern Slice）/ Base Tavern + Base Upgrade UI / Fog-of-war / 词缀 reroll / 装备分解 UI / 套装合成 UI。

---

## Capacity

- Total days: 5
- Buffer (20%): 1 day
- Available: 4 days
- Sprint-005 velocity: 14 任务全 DONE，混合 UI/Logic/Doc/QA gate
- Sprint-006 shape: Logic + Integration 重，UI 中等，Data-driven config 中等

---

## 入场前提

| 项 | 状态 |
|---|---|
| Sprint-005 | COMPLETE WITH SPRINT-006+ SCOPE NOTES |
| stage.txt | Production |
| ADR-008（资源经济升级 scope）| Accepted 2026-04-27 |
| ADR-009（装备升级 scope）| Accepted 2026-04-27 |
| TR registry | version 3，已同步 8 行 ADR-008/009 引用 |
| `production/epics/bond-system/` | EPIC + 4 story skeleton（BOND-001..004）已就位 |
| `production/epics/fog-of-war/` | EPIC + 4 story skeleton 就位（不在本 Sprint）|
| `docs/active/base-full-readiness-brief.md` | 提供 Sprint-006 候选切片顺序 |
| `design/gdd/chapter-03.md` | skeleton（B3-GATE 占位），需详化战斗 1 |
| Sprint-005 architecture review | CONCERNS（已修复）；Follow-up F-1/F-2 已记录 |
| Sprint-人工 队列 | 仍为外部验证集中地，本 Sprint 不依赖也不阻塞 |

---

## Tasks

### Must Have - 养成闭环主轴

| ID | Task | Agent/Owner | Est. Days | Dependencies | Acceptance Criteria |
|----|------|-------------|-----------|-------------|-------------------|
| BOND-DATA-001 | Bond 数据模型 + SaveData payload | gameplay-programmer | 0.5 | `design/gdd/bond-system.md`、ADR-003 | `BondPair` resource + `SaveData.story_progress.bond_levels`（已存）扩展为 pair-keyed；新增/读档保留；至少 1 个 Logic 单测覆盖 round-trip |
| BOND-EVT-001 | Affinity gain 事件钩子 | gameplay-programmer | 0.5 | BOND-DATA-001、ADR-001 GameEvents、battle settlement | 战斗结算或营地事件触发 `bond_level_up` signal（GameEvents 已有占位）；至少 1 个 Integration 测验证 affinity 增量；不引入装饰性 UI |
| EQUIP-ENH-001 | 装备强化 UI（已装备件，+1~+5）| ui-programmer | 0.75 | ADR-009、equipment-system 现有逻辑 | 角色管理"装备"Tab 中点击装备件可进入强化面板；金币 + 材料消耗预览基于 ADR-008 数据源；强化结果立即写回 SaveData；自动测试覆盖 +1→+5 路径 |
| EQUIP-ENH-002 | 强化成本来源 + 失败提示 | gameplay-programmer | 0.5 | EQUIP-ENH-001、ADR-008 §1+§3 | 成本读取 `Inventory.peek_cost(level)`；金币/材料不足显示精确缺口；保护符为 0 时风险区入口禁用；不实现 +6+ 风险区 |
| BASE-AP-001 | Action Point 模型 + save | gameplay-programmer | 0.75 | `docs/active/base-full-readiness-brief.md`、ADR-003 | `ActionPoints` autoload 或 base 子模块；每章重置；训练消耗 1 AP（市集仍免费）；save round-trip 测试 PASS；UI 顶部状态栏显示当前 AP |

**Must Have 合计：3.0 天**

### Should Have - 玩家可见层 + 数据驱动

| ID | Task | Agent/Owner | Est. Days | Dependencies | Acceptance Criteria |
|----|------|-------------|-----------|-------------|-------------------|
| BOND-UI-001 | 角色详情 Bond 摘要 | ui-programmer | 0.25 | BOND-DATA-001、character_management 现有 UI | 角色详情面板显示 top-3 affinity 关系 + level；本地化 key 完整；不可点击交互（Sprint-007 BOND-003 才接酒馆）|
| EQUIP-ENH-003 | 强化 round-trip + failure UI 收尾 | ui-programmer | 0.5 | EQUIP-ENH-001/002、ADR-003 schema | 强化成功/失败 toast；强化等级 round-trip 测覆盖 +5 装备；UI 失败状态使用 hint_bar 提示 |
| BASE-INTEL-001 | Intel Room 只读 briefing | ui-programmer | 0.5 | BASE-AP-001、`design/gdd/chapter-03.md` skeleton | 基地新增 Intel Tab；显示当前章节简介 + 下一战预览（数据来自 chapter JSON）；不消耗 AP；自动测试覆盖 Tab 路由 |
| ECON-CFG-001 | Base upgrade 成本数据表（design only）| systems-designer | 0.5 | ADR-008、resource-economy.md C.4 | 在 `assets/data/economy/base-upgrade-costs.tres`（或 JSON）落地草案数值；不实装升级 UI；qa-plan 中标记为 design-only acceptance |

**Should Have 合计：1.75 天**

### Nice to Have

| ID | Task | Agent/Owner | Est. Days | Dependencies | Acceptance Criteria |
|----|------|-------------|-----------|-------------|-------------------|
| CH3-DESIGN-001 | Ch.3 战斗 1 GDD 详化 | narrative-designer + game-designer | 0.5 | `design/gdd/chapter-03.md` skeleton、`design/narrative/belief-branching.md` | 章节 GDD 8 节齐全（已有 skeleton 节扩展）；战斗 1 地图布局描述 + 敌方编队 + B3-GATE 触发条件落字；Sprint-007 战斗实现可直接消费 |
| GOV-001 | Sprint / Manifest / Status 同步 | producer | 0.25 | Sprint-006 任务进展 | `production/sprint-status.yaml` Sprint-006 段同步；`production/epics/index.md` Bond/Equipment/Base 状态同步；Control Manifest 若有变更追加版本注记 |
| TECH-001 | Regression hardening | qa-tester | 0.25 | 任意 Must Have 完成 | 在新增 stories 周边补 1-2 条 negative test（如：BondPair 反向重复写入、EQUIP +0 装备进入面板边界）；不新增功能 |

**Nice to Have 合计：1.0 天**

### 总估算
- Must (3.0) + Should (1.75) + Nice (1.0) = **5.75d**
- 容量 4d + Buffer 1d = 5d；Should + Nice 部分允许浮动到 Sprint-007

---

## Carryover from Previous Sprint

| Task | Reason | New Estimate |
|------|--------|-------------|
| ADR-008/009 Acceptance | Sprint-005 标记为 Draft，2026-04-27 已 Accepted（独立工作流外完成） | DONE |
| Architecture Review CONCERNS 修复 | Sprint-005 后置审查 | DONE（2026-04-27 architecture-review report）|

无功能性 carryover。

---

## Risks

| Risk | Probability | Impact | Mitigation |
|------|------------|--------|------------|
| Bond 数据模型与既有 `SaveData.story_progress.bond_levels` 命名冲突 | 中 | 中 | BOND-DATA-001 第一动作是读 SaveData schema，必要时启用 ADR-003 §版本迁移 |
| 装备强化 UI 在角色管理 Tab 内造成层级过深 | 中 | 中 | UI 框架沿用 character_tab_bar 既有路径；强化面板作 modal overlay 不破坏 Tab |
| ADR-008 数据驱动价格表格式未定 | 中 | 高 | EQUIP-ENH-002 优先约定 schema，ECON-CFG-001 沿用 |
| Action Point 影响现有训练流程的回归 | 中 | 中 | BASE-AP-001 第一动作是读 training_ground.gd 现有调用，加 AP 检查为 opt-in；既有测试不应失败 |
| Ch.3 GDD 详化触发对 Bond/Base 的连锁需求扩张 | 高 | 中 | CH3-DESIGN-001 严格停在 GDD，不进入 epic/story 创建；新需求记入 backlog |
| Sprint-人工 队列产出新阻塞证据 | 低 | 低 | 仍按 Sprint-005 协议——人工不阻塞 Sprint-006 自动化 DoD |

---

## Dependencies on External Factors

- 不依赖新美术、音乐、翻译、第三方 API
- 不引入新 addon；继续使用 Godot Core + GUT
- ECON-CFG-001 数据表格式必须与 ADR-008 §"data-driven 价格表（.tres / JSON）"对齐；如未定，先约定再落地
- Sprint-人工 MAN-002（Base 视觉证据）若在本 Sprint 期间产生新 critical 反馈，可触发 Should/Nice 重排

---

## Out of Sprint-006 Scope（明确排除）

- Ch.3 战斗 1 / 战斗 2 / 战斗 3 实现
- B3-GATE 信念分叉运行时
- Bond 酒馆对话 UI（BOND-003 推到 Sprint-007）
- Bond 联携技能 / S-rank 浪漫内容
- Base Tavern UI / Base 升级 UI
- 装备词缀 reroll / 分解 UI / 套装合成 UI
- 装备 +6 以上风险区强化
- Fog-of-war 任意切片
- NG+ / Event / 正式音频系统
- Public release sign-off / 截图 / 人工 playtest（仍由 sprint-人工.md 管理）

---

## 执行顺序建议（5 天节拍）

```text
Day 1 (4-28): BOND-DATA-001 + EQUIP-ENH-001 起手（数据模型先行，UI 占位）
Day 2 (4-29): BOND-EVT-001 + EQUIP-ENH-002 + BASE-AP-001 起手
Day 3 (4-30): BASE-AP-001 收尾 + EQUIP-ENH-003 + BOND-UI-001
Day 4 (5-01): BASE-INTEL-001 + ECON-CFG-001 + 烟雾测验
Day 5 (5-02): CH3-DESIGN-001 + GOV-001 + TECH-001 + 收尾验证
```

---

## Definition of Done for this Sprint

- [x] 所有 Must Have 任务 COMPLETE，AC 全部 PASS
- [x] QA 计划存在并已被 stories 引用（`production/qa/qa-plan-sprint-6.md`）
- [x] 所有 Logic / Integration story 有对应自动化测试 PASS
- [x] `godot --headless --check-only project.godot` 退出码 0
- [x] GUT scene runner 退出码 0；新增覆盖无 regression
- [x] Windows export 退出码 0
- [x] Packaged smoke 维持 PASS（含新增 Bond/Equipment/Base 路径不引入资源泄漏）
- [x] 至少 1 条 Bond 关系可在战斗或营地路径增长，并 round-trip
- [x] 玩家从主菜单进入战斗 → 结算 → 基地 → 装备强化 +5 一件 → 进入下一战，全程不需要重启游戏
- [x] `production/epics/index.md` / `production/sprint-status.yaml` 状态同步
- [x] Sprint-007 handoff 列出 Ch.3 战斗实现入口、Bond 酒馆切片、Base Tavern + Upgrade 切片

### Completion Evidence — 2026-04-27

- Bond: `src/core/bond/bond_registry.gd`, `GameEvents.bond_level_up`, battle settlement affinity gain, character detail top-3 summary.
- Equipment: Character Management equipped-item enhancement +1~+5, `Inventory.peek_cost`, precise shortage hints, `GameEvents.equipment_enhanced`, packaged smoke +5 path.
- Base: `ActionPoints` model, training AP spend/save, AP display, AP-free market, read-only Intel tab.
- Data/design: `assets/data/economy/base-upgrade-costs.json`; Ch.3 GDD expanded to full eight-section handoff.
- Verification: check-only PASS, GUT scene runner PASS, `git diff --check` PASS, Windows export PASS, packaged smoke PASS with `base_enhanced_level:5` and `bond_growth_present:true`.

---

## Revalidation — 2026-04-27

### 完成进展

复核结论：Sprint-006 的 Must Have、Should Have、Nice to Have 实施与文档交付均已落地，状态为 **COMPLETE WITH SPRINT-007+ SCOPE NOTES**。

| 复核项 | 结果 | 证据 |
|---|---|---|
| BOND-DATA-001 Bond 数据模型 + SaveData payload | 完成 | `src/core/bond/bond_registry.gd`（176 行，pair-keyed + RANK_THRESHOLDS + save round-trip）；`tests/unit/bond/bond_data_model_test.gd`（4 测试覆盖反向 key / ranking / 反向重复 / 旧 payload 迁移）|
| BOND-EVT-001 Affinity 事件钩子 | 完成 | `GameEvents.bond_level_up` 信号；`tests/integration/bond/affinity_event_hooks_test.gd`（rank 跨阈触发 + battle settlement payload round-trip）|
| EQUIP-ENH-001 装备强化 UI（已装备件 +1~+5）| 完成 | `src/ui/management/character_management.gd` 强化面板；`Inventory.peek_cost` 暴露成本预览；packaged smoke `base_enhanced_level:5` 路径覆盖 |
| EQUIP-ENH-002 强化成本来源 + 失败提示 | 完成 | `src/core/resource/inventory.gd` 提供 `peek_cost`；金币/材料缺口精确显示；`GameEvents.equipment_enhanced` 信号上线 |
| BASE-AP-001 Action Point 模型 + save | 完成 | `src/core/base/action_points.gd`（49 行，spend / ensure_chapter / serialize）；`tests/unit/base/action_points_test.gd`（3 测试覆盖核心场景）；`src/ui/base/training_ground.gd` 训练消耗 1 AP；市集仍免费 |
| BOND-UI-001 角色详情 Bond 摘要 | 完成 | `src/ui/management/character_management.gd` 角色详情显示 top-3 affinity + rank |
| EQUIP-ENH-003 强化 round-trip + failure UI | 完成 | 强化等级 round-trip 测试覆盖；UI 失败状态接 hint_bar 提示 |
| BASE-INTEL-001 Intel Room 只读 briefing | 完成 | `src/ui/base/base_hub.gd` 新增 Intel Tab；不消耗 AP |
| ECON-CFG-001 Base upgrade 成本数据表 | 完成 | `assets/data/economy/base-upgrade-costs.json`（4 级升级 + schema_version=1 + source=`design/gdd/base-system.md#F1`）|
| CH3-DESIGN-001 Ch.3 战斗 1 GDD 详化 | 完成 | `design/gdd/chapter-03.md` 扩展为完整 8 节 handoff |
| GOV-001 Sprint / Manifest / Status 同步 | 完成 | `production/sprint-status.yaml` 12 条均 `status: complete`；`production/epics/index.md` 同步 base-system 新增 epic 行与 Sprint-006 状态 |
| TECH-001 Regression hardening | 完成 | Bond / Base 边界 negative test 已并入新测试集合 |
| 自动化解析 | per Codex 报告 PASS | `godot --headless --check-only project.godot` 退出码 0（Codex 执行报告）|
| 自动化测试入口 | per Codex 报告 PASS | `godot --headless res://tests/test_runner.tscn` 退出码 0（Codex 执行报告）|
| Windows export | per Codex 报告 PASS | `godot --headless --export-release "Windows Desktop"` 退出码 0（Codex 执行报告）|
| 打包版冒烟 | per Codex 报告 PASS | `PACKAGED_PLAYTHROUGH_SMOKE PASS {"base_enhanced_level":5,"battle":"chapter_01_finale","bond_growth_present":true,"camp_report_present":true,"management_tab":"equipment","success":true}` |

### 遗留问题

- 外部体验验证、截图证据、release sign-off 仍由 `production/sprints/sprint-人工.md` 集中管理，不阻塞 Sprint-006。
- 4 个自动化 gate 验证为 Codex 执行轮次的报告值；如需独立确认，可在新会话运行：`godot --headless --check-only project.godot` / `godot --headless res://tests/test_runner.tscn` / Windows export / packaged smoke。
- Bond 酒馆 UI（BOND-003）、Base Tavern UI、Base 升级 UI、装备 +6 风险区、Ch.3 战斗 1 实现仍为 Sprint-007+ 范围。
- `architecture-review-2026-04-27.md` follow-up F-1（GameEvents 登记 `equipment_enhanced` 信号到 ADR-001 信号列表）已通过 EQUIP-ENH-002 实现侧落地，但 ADR-001 文档列表未同步——建议下次 architecture-review 或 control-manifest 更新一并补齐。
- `architecture-review-2026-04-27.md` follow-up F-2（强化 UI AccessKit / 键盘导航验收）未在本 Sprint 显式核查，应在 Sprint-007 QA plan 中纳入。

---

## Sprint-007 Handoff 初稿

若 Sprint-006 Must Have 全部完成：

1. **Ch.3 战斗 1 实现**（依赖 CH3-DESIGN-001 输出 + B3-GATE 占位）
2. **BOND-003 酒馆对话 MVP**（依赖 Sprint-006 BASE-AP-001、Sprint-007 Tavern Slice）
3. **Base Tavern + Base Upgrade UI**（依赖 ECON-CFG-001 价格表 + ADR-008 §3）
4. **装备 +6 风险区 + 失败/保护符 UI**（依赖 EQUIP-ENH-001~003、resource-economy E.2/E.3 边界）
5. **Architecture Review full mode** — 把 architecture.md 顶层文档纳入对齐（Sprint-005 review 的 F-3 follow-up）

---

## 参考文档

| 文档 | 路径 | 说明 |
|------|------|------|
| Bond GDD | `design/gdd/bond-system.md` | BOND-DATA/EVT/UI 实现依据 |
| Bond Epic | `production/epics/bond-system/EPIC.md` | 4 个 readiness story 入口 |
| ADR-008 | `docs/architecture/ADR-008-resource-economy-upgrade.md` | 资源经济升级 scope（Accepted）|
| ADR-009 | `docs/architecture/ADR-009-equipment-upgrade-scope.md` | 装备强化 scope（Accepted）|
| Equipment GDD | `design/gdd/equipment-system.md` | 强化 C.4 表 + D.1 最终属性 |
| Resource GDD | `design/gdd/resource-economy.md` | C.3 消耗规则 + D.4 强化成本公式 |
| Base brief | `docs/active/base-full-readiness-brief.md` | Sprint-006 候选切片顺序 |
| Chapter 3 GDD | `design/gdd/chapter-03.md` | Ch.3 战斗 1 详化起点 |
| Architecture review | `docs/architecture/architecture-review-2026-04-27.md` | F-1/F-2/F-3 follow-up 列表 |
| Sprint-人工 | `production/sprints/sprint-人工.md` | 外部验证队列（不阻塞）|

---

## QA Plan

> Status: **GENERATED 2026-04-27** — `/qa-plan sprint-006` 已生成
> Target: `production/qa/qa-plan-sprint-6.md`

**Scope check**：本 Sprint 选定的 stories 全部源自既有 readiness epics + ADR-008/009 接受后的实现门禁；无 epic 外新增。无需立即跑 `/scope-check`。
