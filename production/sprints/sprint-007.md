# Sprint 7: Ch.3 战斗 1 + Bond 酒馆 + Base Tavern/Upgrade + Equipment +6 + Architecture Review Full

> Version: v1.0 | Date: 2026-04-27 | Status: **COMPLETE**
> Window: 2026-05-03 → 2026-05-07
> Previous: sprint-006 COMPLETE WITH SPRINT-007+ SCOPE NOTES
> Control Manifest: 2026-04-26-v2（覆盖 ADR-001~007）+ ADR-008/009 Accepted（2026-04-27）
> Review Mode: solo

---

## Sprint Goal

把 Sprint-006 的养成深度切到玩家可推进的内容深度：

1. Ch.3 战斗 1 第一次成为可玩战斗（地图 + 编队 + B3-GATE 占位 + 自动化测试）
2. Bond 关系从"数据可见"上升到"主动推进"——酒馆对话即第一条主动 affinity 增长路径
3. Base Phase 1 收口：Base Tavern + Base Upgrade UI 让基地变成有方向感的循环
4. 装备 +6 风险区上线，闭合 ADR-009 所列的失败/降级/保护符闭环
5. Architecture Review full mode + ADR-001 信号补登 + AccessKit follow-up 验收，把 Sprint-005 review 留下的 F-1/F-2/F-3 三个尾巴清完

**不在 Sprint-007 范围**：Ch.3 战斗 2 / 战斗 3 实现 / B3-GATE 运行时分支 / Bond 联携技能 / 词缀 reroll / 装备分解 UI / 套装合成 UI / Fog-of-war / NG+ / Event / 正式音频系统 / Public release sign-off。

---

## Capacity

- Total days: 5
- Buffer (20%): 1 day
- Available: 4 days
- Sprint-006 velocity: 12 任务全 DONE，packaged smoke 含 `base_enhanced_level:5 + bond_growth_present:true`
- Sprint-007 shape: Logic + Integration + UI 重；Ch.3 战斗实现是最大单点 (1.5d)；arch-review 是 cross-cutting governance；接受超容量 0.75d 浮动

---

## 入场前提

| 项 | 状态 |
|---|---|
| Sprint-006 | COMPLETE WITH SPRINT-007+ SCOPE NOTES |
| stage.txt | Production |
| ADR-008 / ADR-009 | Accepted 2026-04-27 |
| `design/gdd/chapter-03.md` | v1.0 Full GDD（201 行，Sprint-006 CH3-DESIGN-001 完成）|
| `production/epics/chapter-03/` | 不存在，本 Sprint 必须新建 |
| `src/core/bond/bond_registry.gd` | Sprint-006 已交付，含 pair-keyed + ranking + save round-trip |
| `src/core/base/action_points.gd` | Sprint-006 已交付，训练消耗 1 AP / 市集免费 |
| `assets/data/economy/base-upgrade-costs.json` | Sprint-006 已交付，4 级升级数据表 ready |
| `production/epics/bond-system/story-003-base-tavern-dialogue.md` | Ready，依赖本 sprint BASE-TAVERN-001 |
| Sprint-005 architecture review F-1/F-2/F-3 | 待 Sprint-007 ARCH-REVIEW-007 完成 |
| Sprint-人工 队列 | 仍为外部验证集中地，本 Sprint 不依赖也不阻塞 |

---

## Tasks

### Must Have - 5 项主线 + 1 准备

| ID | Task | Agent/Owner | Est. Days | Dependencies | Acceptance Criteria |
|----|------|-------------|-----------|-------------|-------------------|
| CH3-EPIC-001 | 创建 chapter-03 epic + 4 stories skeleton | producer | 0.25 | `design/gdd/chapter-03.md` v1.0 | `production/epics/chapter-03/EPIC.md` 新建；4 个 story-*.md skeleton 落盘（CH3-c-001..004）；`production/epics/index.md` 同步追加 chapter-03 行 |
| CH3-c-001 | Ch.3 战斗 1 实现 | gameplay-programmer | 1.5 | CH3-EPIC-001、CH3 GDD §3 战斗 1、Sprint-002 chapter_02_act_a JSON pattern | 新建 `assets/data/chapters/chapter_03_battle_1.json`；地图布局 + 我方/敌方编队 + 胜利条件落地；scene 路由从 `chapter_03_intro -> chapter_03_battle_1`；automated test 覆盖战斗 boot + victory 条件；不实现 B3-GATE 运行时分叉（仅占位） |
| BOND-003 | 酒馆对话 MVP | ui-programmer | 0.5 | BASE-TAVERN-001、Sprint-006 BondRegistry | 酒馆 Tab 列出可用 support 对话；触发对话消耗 1 AP；对话完成时 `BondRegistry.add_affinity(...)` 触发；UI 在酒馆未解锁时优雅降级；至少 1 个 Integration test 覆盖 affinity 增长路径 |
| BASE-TAVERN-001 | 基地酒馆 UI | ui-programmer | 0.5 | Sprint-006 ActionPoints + base_hub.gd | base_hub 新增 Tavern Tab；显示当前章节可用对话列表；与 BOND-003 接合；自动化测试覆盖 Tab 路由 |
| BASE-UPGRADE-001 | 基地升级 UI | ui-programmer | 0.75 | Sprint-006 ECON-CFG-001 (`base-upgrade-costs.json`) | base_hub 新增 Upgrade Tab；读取 4 级升级数据表；金币/材料消耗预览；升级后 unlocks 字段触发 base 状态改变；至少 1 个 Logic 测覆盖 cost 读取 + 升级 round-trip |
| EQUIP-RISK-001 | 装备 +6 风险区强化 | gameplay-programmer + ui-programmer | 0.75 | Sprint-006 EQUIP-ENH-001~003 | 强化面板支持 +6+ 入口；C.4 表成功率落地；失败时降级 5 级；保护符消耗与 0 时禁用；UI 失败/保护符生效 toast；自动化测试覆盖 +6 失败 / +6 保护符 / +10 边界 |
| ARCH-REVIEW-007 | Architecture Review full mode | architect | 0.5 | 全部 30 GDD + 9 ADR + Sprint-005 review F-1/F-2/F-3 | 跑 full mode 审查；ADR-001 信号列表追加 `equipment_enhanced(item_id, level, success)`（F-1）；写入 `docs/architecture/architecture-review-2026-05-03.md`；F-2 AccessKit 验收纳入 Sprint-007 QA plan；F-3 architecture.md 顶层文档对齐或追加 gap 报告 |

**Must Have 合计：4.75 天**

### Should Have

| ID | Task | Agent/Owner | Est. Days | Dependencies | Acceptance Criteria |
|----|------|-------------|-----------|-------------|-------------------|
| EQUIP-RISK-002 | 风险区 round-trip 测 | qa-tester | 0.25 | EQUIP-RISK-001 | +6/+8/+10 round-trip + 保护符消耗持久化的自动化覆盖；任何失败路径在 SaveData 中不留死状态 |
| GOV-001 | Sprint / Manifest / Status 同步 | producer | 0.25 | Sprint-007 任务进展 | `production/sprint-status.yaml` Sprint-007 段同步；`production/epics/index.md` chapter-03 / bond-system / base-system 状态更新；Control Manifest 若 ADR 列表变更追加版本注记 |
| TECH-001 | Regression hardening | qa-tester | 0.25 | Must Have 完成 | 在 Ch.3 战斗 + Bond 酒馆 + Equipment 风险区周边补 1-2 条 negative test；不新增功能 |

**Should Have 合计：0.75 天**

### Nice to Have

| ID | Task | Agent/Owner | Est. Days | Dependencies | Acceptance Criteria |
|----|------|-------------|-----------|-------------|-------------------|
| DOC-001 | sprint-人工 队列与 Sprint-007 evidence sync | producer | 0.25 | Sprint-007 完成 | `production/sprints/sprint-人工.md` 中 MAN-002 / MAN-004 候选项追加 Sprint-007 截图候选清单；不新增 release-blocking 项 |

**Nice to Have 合计：0.25 天**

### 总估算
- Must (4.75) + Should (0.75) + Nice (0.25) = **5.75d**
- 容量 4d + Buffer 1d = 5d；超出 0.75d 由 Should/Nice 浮动到 Sprint-008 容纳

---

## Carryover from Previous Sprint

| Task | Reason | New Estimate |
|------|--------|-------------|
| 无功能性 carryover | Sprint-006 已 COMPLETE | — |
| Sprint-005 review F-1/F-2/F-3 | 三个 follow-up 纳入 ARCH-REVIEW-007 一次清完 | 0.5d（已计入）|

---

## Risks

| Risk | Probability | Impact | Mitigation |
|------|------------|--------|------------|
| CH3-c-001 战斗实现量超估（地图 + AI 编队 + 胜负判定）| 高 | 高 | Day 1 优先做 chapter_03_battle_1.json + 路由；AI 编队复用 Sprint-003 Ch.2 模式；不实现 B3-GATE 分叉运行时 |
| BOND-003 + BASE-TAVERN-001 互依导致同时阻塞 | 中 | 中 | BASE-TAVERN-001 第一步只做 Tab + 占位列表；BOND-003 在 BASE-TAVERN-001 Tab 可见后并行接入 |
| EQUIP-RISK-001 风险区失败概率与 GDD C.4 表实现偏差 | 中 | 中 | 直接消费 equipment-system.md C.4 表数值；自动化测试驱动 +6 / +7 / +8 边界 |
| BASE-UPGRADE-001 数据驱动遭遇 schema 漂移 | 低 | 中 | `base-upgrade-costs.json` schema_version 在 Sprint-006 已落字段；本 sprint 仅消费 |
| ARCH-REVIEW-007 full mode 揭示新的硬阻塞 | 中 | 高 | 即使发现新 gap，先记录到 review 报告并标 PARTIAL；不阻塞本 sprint Must Have；新 gap 转入 Sprint-008 |
| Codex 单 sprint 执行 12 任务后疲劳 | 低 | 中 | 接受 Should/Nice 浮动；TECH-001 / DOC-001 可并入 Sprint-008 |

---

## Dependencies on External Factors

- 不依赖新美术、音乐、翻译、第三方 API
- 不引入新 addon
- Ch.3 战斗 1 复用既有 chapter_02 JSON schema；如发现需要扩展，追加到 `design/data-schemas/` 而不是 sprint 内拆解
- ADR-001 信号补登 (F-1) 是文档动作，不影响代码；可与代码 story 并行

---

## Out of Sprint-007 Scope（明确排除）

- Ch.3 战斗 2 / 战斗 3 实现
- B3-GATE 信念分叉运行时（仅占位）
- Bond 联携技能 / S-rank 浪漫内容
- 词缀 reroll / 装备分解 UI / 套装合成 UI
- 装备 +11 以上极风险区
- Fog-of-war 任意切片
- NG+ / Event / 正式音频系统
- Public release sign-off / 截图 / 人工 playtest（仍由 sprint-人工.md 管理）

---

## 执行顺序建议（5 天节拍）

```text
Day 1 (5-03): CH3-EPIC-001 + CH3-c-001 起手（epic + battle JSON + scene 路由）
Day 2 (5-04): CH3-c-001 收尾 + BASE-TAVERN-001 + BOND-003 起手
Day 3 (5-05): BOND-003 收尾 + BASE-UPGRADE-001 + EQUIP-RISK-001 起手
Day 4 (5-06): EQUIP-RISK-001 收尾 + ARCH-REVIEW-007 + EQUIP-RISK-002
Day 5 (5-07): GOV-001 + TECH-001 + DOC-001 + 收尾验证（check-only / GUT / export / smoke）
```

---

## Definition of Done for this Sprint

- [x] 所有 Must Have 任务 COMPLETE，AC 全部 PASS
- [x] QA 计划存在并已被 stories 引用（`production/qa/qa-plan-sprint-7.md`）
- [x] 所有 Logic / Integration story 有对应自动化测试 PASS
- [x] `godot --headless --check-only project.godot` 退出码 0
- [x] GUT scene runner 退出码 0；新增覆盖无 regression
- [x] Windows export 退出码 0
- [x] Packaged smoke 维持 PASS（含 Ch.3 战斗 1 启动 + 酒馆对话 + 装备 +7 路径）
- [x] 玩家从主菜单 → Ch.3 战斗 1 启动 → 进入战斗循环 → 战胜 → 进入基地 → 酒馆触发 affinity → 装备进入 +6 风险区强化（成功或保护符生效），全程不需要重启游戏
- [x] `production/epics/chapter-03/` epic + 4 stories 落盘
- [x] `production/epics/index.md` / `production/sprint-status.yaml` 状态同步
- [x] `docs/architecture/architecture-review-2026-05-03.md` 落盘，verdict 为 PASS / CONCERNS（已修复）
- [x] ADR-001 信号列表追加 `equipment_enhanced` 一行（F-1 闭合）
- [x] Sprint-008 handoff 列出 Ch.3 战斗 2/3、装备 +11+ 极风险区、Bond 联携、Fog-of-war 候选

---

## Sprint-008 Handoff 初稿

若 Sprint-007 Must Have 全部完成：

1. **Ch.3 战斗 2 实现**（继 CH3-c-001）+ B3-GATE 运行时分叉
2. **Ch.3 战斗 3 + Boss 阶段** （Sprint-003 Ch.2 Boss 模式复用）
3. **装备词缀 reroll / 分解 UI**（接 EQUIP-RISK-001/002）
4. **Bond 联携技能 MVP**（依赖至少 2 对达 B-rank 关系）
5. **Fog-of-war MVP**（如 Ch.3 任一战斗需要）
6. **Architecture Review CONCERNS 跟进**（如 ARCH-REVIEW-007 留下新 gap）

---

## 参考文档

| 文档 | 路径 | 说明 |
|------|------|------|
| Chapter 3 GDD | `design/gdd/chapter-03.md` | v1.0 Full GDD，CH3-c-001 起点 |
| Bond GDD | `design/gdd/bond-system.md` | BOND-003 实现依据 |
| Bond Epic | `production/epics/bond-system/EPIC.md` | BOND-003 readiness story |
| Base brief | `docs/active/base-full-readiness-brief.md` | Base Tavern + Upgrade 切片顺序 |
| Equipment GDD | `design/gdd/equipment-system.md` | C.4 风险区成功率表 + D.4 强化降级 |
| Resource GDD | `design/gdd/resource-economy.md` | E.2/E.3 边界 + 强化失败处理 |
| ADR-008 | `docs/architecture/ADR-008-resource-economy-upgrade.md` | 资源经济升级 scope（Accepted）|
| ADR-009 | `docs/architecture/ADR-009-equipment-upgrade-scope.md` | 装备强化 scope（Accepted）|
| Architecture review (2026-04-27) | `docs/architecture/architecture-review-2026-04-27.md` | F-1/F-2/F-3 follow-up |
| Sprint-005 信念分支 | `design/narrative/belief-branching.md` | B3-GATE 占位参考 |
| Sprint-人工 | `production/sprints/sprint-人工.md` | 外部验证队列（不阻塞）|

---

## QA Plan

> Status: **GENERATED 2026-04-27** — `/qa-plan sprint-007` 已运行，11 个 Sprint-007 stories/tasks 均有 QA 测试条件
> Target: `production/qa/qa-plan-sprint-7.md`

**Scope check**：本 Sprint 选定的 stories 全部源自既有 GDD（Ch.3 / Bond / Base / Equipment）+ Sprint-006 已交付的基础设施 + Sprint-005 review follow-up；无 epic 外新增。无需立即跑 `/scope-check`。

---

## Dev-Story Cadence Kickoff

> Started: 2026-04-27

1. `CH3-EPIC-001` 已完成：`production/epics/chapter-03/EPIC.md` 与 4 个 Chapter 03 story skeleton 已落盘。
2. 下一条可拾取 story：`/dev-story production/epics/chapter-03/story-001-battle-1-implementation.md`。
3. Base / Equipment Sprint-007 story files 已补齐，后续按 QA plan 的 pickup order 执行。

---

## Completion Evidence

> Completed: 2026-04-27

| Gate | Evidence |
|---|---|
| Godot check-only | `G:\SteamLibrary\steamapps\common\Godot Engine\godot.windows.opt.tools.64.exe --headless --check-only project.godot` PASS |
| GUT runner | `849 total / 849 pass / 0 fail` |
| Windows export | `builds/windows/SRPG.exe` generated, 124279592 bytes |
| Artifact hash | SHA256 `9BA385F3F5AB36D0335AFB1BC4D6FADB4F0299E88887074A5783BBF84E39E9FF` |
| Packaged smoke | PASS: `chapter3_battle=chapter_03_act_a`, `chapter3_victory=true`, `chapter3_base_level=2`, `tavern_affinity=25`, `risk_enhanced_level=7` |
