# Sprint 8: Ch.3 内容完成 + 装备养成收口

> Version: v1.0 | Date: 2026-04-27 | Status: **COMPLETE**
> Window: 2026-05-08 → 2026-05-12
> Previous: sprint-007 COMPLETE（Ch.3 Battle 1 + Bond Tavern + Base + Equipment Risk Zone + Arch Review）
> Control Manifest: 2026-04-26-v2（覆盖 ADR-001~007）+ ADR-008/009 Accepted（2026-04-27）
> Review Mode: solo

---

## Sprint Goal

把 Ch.3 从前半截推进到完整三战可玩 —— Battle 2 压力量表 + B3-GATE 信念分叉激活 + Finale Boss，同时收口装备养成 UI（分解/reroll）。

**不在 Sprint-008 范围**：Bond 联携技能实现（仅 GDD）、Fog-of-war 实现（仅 GDD）、Ch.4 内容、NG+。

## Completion Summary

Completed on 2026-04-27.

| Area | Result | Evidence |
|------|--------|----------|
| Ch.3 battle 2 | Complete | `src/ui/combat/battle_definitions/chapter_03_act_b.json`, `tests/unit/chapter03/battle_2_pressure_test.gd`, `tests/integration/prototypes/chapter_03_battle_2_entry_test.gd` |
| B3-GATE runtime branching | Complete | `src/core/belief/b3_gate_evaluator.gd`, `tests/unit/chapter03/b3_gate_evaluator_test.gd`, `tests/integration/chapter03/b3_gate_persistence_test.gd` |
| Ch.3 finale boss | Complete | `src/ui/combat/battle_definitions/chapter_03_finale.json`, `tests/unit/chapter03/finale_route_variant_test.gd`, `tests/integration/chapter03/finale_boot_test.gd` |
| Equipment decompose/reroll UI | Complete | `src/core/equipment/equipment_component.gd`, `src/ui/management/character_management.gd`, `tests/unit/equipment/decomp_reroll_test.gd`, `tests/integration/equipment/decomp_reroll_ui_test.gd` |
| Architecture/GDD/governance | Complete | `docs/architecture/architecture.md`, `design/gdd/bond-system.md`, `design/gdd/fog-of-war-system.md`, `production/sprint-status.yaml` |

Verification:

- `godot --headless --check-only project.godot` PASS.
- GUT scene runner PASS: `Total: 879 | Pass: 879 | Fail: 0`.
- Windows export PASS: `builds/windows/SRPG.exe`, 124,334,616 bytes, SHA256 `A472CE209E17ABEB74D8281E4CEEA8B099665FA4026F4FE1E3C568A76DF2FD64`.
- Packaged smoke PASS with `chapter3_act_b=true`, `b3_gate_route=ren`, `chapter3_finale=true`, `finale_boss_phase=3`, `chapter3_complete=true`, `decompose_materials=10`, `reroll_preserved_level=7`.

---

## Capacity

- Total days: 5
- Buffer (20%): 1 day
- Available: 4 days
- Sprint-007 velocity: 12 任务全 DONE，855/855 PASS
- Sprint-008 shape: Content 重（三战实现），Logic 中等（B3-GATE 分叉），UI 轻（分解/reroll panel）

---

## 入场前提

| 项 | 状态 |
|---|---|
| Sprint-007 | COMPLETE |
| stage.txt | Production |
| ADR-007（信念分支）| Accepted |
| ADR-008 / ADR-009 | Accepted 2026-04-27 |
| `design/narrative/belief-branching.md` | Sprint-002 已交付 |
| `design/gdd/chapter-03.md` | v1.0 Full GDD |
| `production/epics/chapter-03/` | EPIC + 4 stories（1 complete, 3 Backlog）|
| `src/core/combat/boss_phase_controller.gd` | Sprint-003 已交付（Ch.2 Boss 模式）|
| `src/core/attributes/belief_system.gd` | Sprint-003 已交付 |
| architecture.md | v0.2 Sprint-007 对齐，§8 ADR 列表缺 004~009 |
| Sprint-人工 队列 | 仍为外部验证集中地，本 Sprint 不依赖也不阻塞 |

---

## Tasks

### Must Have — 内容推进主轴

| ID | Task | Agent/Owner | Est. Days | Dependencies | Acceptance Criteria |
|----|------|-------------|-----------|-------------|-------------------|
| CH3-EPIC-002 | Ch.3 epic/story 刷新 | producer | 0.25 | CH3-EPIC-001、ch.3 EPIC.md | 3 个 backlog story（story-002/003/004）更新为 sprint-ready；epic index 同步 |
| CH3-c-002 | Ch.3 战斗 2 压力量表 | gameplay-programmer | 1.5 | CH3-EPIC-002、Ch.3 GDD B3-GATE 段、Ch.2 act_b JSON 模板 | 新建 `battle_definitions/chapter_03_act_b.json`；敌方增援/回合压力槽落地；automated test 覆盖压力触发 + victory 条件；不实现 B3-GATE 运行时（CH3-c-003 负责） |
| CH3-c-003 | B3-GATE 信念分叉激活 | gameplay-programmer | 1.0 | CH3-c-002、`design/narrative/belief-branching.md`、ADR-007 | `belief_system.gd` 读取 `narrative_choice.runtime_branching=true`；B3-N1 节点运行时选择 → 影响 Ch.3 终章路线；SaveData 持久化分叉状态；automated test 覆盖分叉 → round-trip；不实现联携技能（Sprint-009） |
| EQUIP-UI-001 | 装备分解 + 词缀 reroll UI | ui-programmer | 0.75 | Sprint-007 EQUIP-RISK-001/002、`decomposition_test.gd`（既有逻辑）| 分解面板：选中装备 → 预览返还材料 → 确认分解 → 写回 SaveData；reroll 面板：消耗金币 + 材料 → 重新随机单个词缀；UI toast 成功/材料不足；automated 测覆盖分解 round-trip + reroll 边界 |
| ARCH-CONCERN-001 | architecture.md 补全 | architect | 0.25 | ARCH-REVIEW-007、当前 architecture.md v0.2 | §8 ADR 列表从 001~003 扩展到 001~009；BondSystem 接口移除 `trigger_combo_skill`（超前）；新增 Base/Ch.3 数据流段 |
| GOV-001 | Sprint / Manifest / Status 同步 | producer | 0.25 | Sprint-008 任务进展 | `sprint-status.yaml` Sprint-008 段同步；epics/index.md Ch.3/equipment/bond 状态更新 |

**Must Have 合计：4.0 天**

### Should Have

| ID | Task | Agent/Owner | Est. Days | Dependencies | Acceptance Criteria |
|----|------|-------------|-----------|-------------|-------------------|
| CH3-c-004 | Ch.3 战斗 3 Finale + Boss | gameplay-programmer | 1.5 | CH3-c-003、Ch.2 Boss 模式（Sprint-003）| `battle_definitions/chapter_03_finale.json`；Boss 三阶段复用 `boss_phase_controller.gd`；B3-GATE 分支影响 Finale 初始条件；automated test 覆盖 Boss phase + 分支条件 |
| TECH-001 | Regression hardening | qa-tester | 0.25 | Must Have 完成 | 在 B3-GATE / 分解 / reroll 周边补 1-2 条 negative test |

**Should Have 合计：1.75 天**

### Nice to Have

| ID | Task | Agent/Owner | Est. Days | Dependencies | Acceptance Criteria |
|----|------|-------------|-----------|-------------|-------------------|
| BOND-COMBO-DESIGN | Bond 联携技能 GDD | game-designer | 0.5 | Sprint-007 BOND-003、Bond GDD §联携技能段 | `design/gdd/bond-system.md` 联携技能段扩展（触发条件/效果类型/rank 门槛）；不实现代码 |
| FOG-GDD | Fog-of-war GDD 详化 | game-designer | 0.5 | `production/epics/fog-of-war/EPIC.md` | `design/gdd/fog-of-war-system.md` 新建或扩展现有；Visibility/Reveal/Unit 规则落地；Sprint-009 实现 ready |

**Nice to Have 合计：1.0 天**

### 总估算
- Must (4.0) + Should (1.75) + Nice (1.0) = **6.75d**
- 容量 4d + Buffer 1d = 5d；Should/Nice 的 1.75d 浮动到 Sprint-009

---

## Carryover from Previous Sprint

| Task | Reason | New Estimate |
|------|--------|-------------|
| architecture.md §8 ADR 列表 | Sprint-007 ARCH-REVIEW-007 review 发现 001~003 → 004~009 gap，本次闭环 | 0.25d（已计入） |
| BondSystem `combo_skill` 接口 | architecture.md 超前声明的接口，推至 Sprint-009 | — |

---

## Risks

| Risk | Probability | Impact | Mitigation |
|------|------------|--------|------------|
| CH3-c-003 B3-GATE 分叉量与既有 `belief_system` 耦合过深 | 中 | 高 | Day 1 先读 `belief_system.gd` + ADR-007；分叉实现限定在 B3 节点不影响旧数据 |
| CH3-c-002/003/004 三个战斗在一 Sprint 内实现超估 | 高 | 中 | CH3-c-004 放在 Should Have，可浮动 |
| EQUIP-UI-001 分解逻辑已存在但 UI 复用 character_management Tab 导致层级过深 | 中 | 中 | 分解/reroll 作 modal overlay，不新增 Tab |
| B3-GATE Finale 分支条件跨战斗持久化出现死状态 | 中 | 中 | CH3-c-003 实现时优先定义 SaveData 分叉字段 schema；negative test 覆盖无效分支值 |
| Fog/Bond GDD 详化触发 scope creep | 低 | 低 | Nice to Have 严格停在 GDD，不进故事创建 |

---

## Dependencies on External Factors

- 不依赖新美术、音乐、翻译、第三方 API
- 不引入新 addon
- Ch.3 战斗 2/3 复用既有 `chapter_02_act_b` / `chapter_02_finale` JSON 模板
- Boss 三阶段复用 Sprint-003 `boss_phase_controller.gd`

---

## Out of Sprint-008 Scope（明确排除）

- Ch.4 内容
- Bond 联携技能实现（仅 GDD）
- Fog-of-war 实现（仅 GDD）
- 装备 +11 以上极风险区
- NG+ / Event / 正式音频系统
- Public release sign-off / 截图 / 人工 playtest（仍由 sprint-人工.md 管理）

---

## 执行顺序建议（5 天节拍）

```text
Day 1 (5-08): CH3-EPIC-002 + CH3-c-002 起手（epic 刷新 + battle 2 JSON）
Day 2 (5-09): CH3-c-002 收尾 + CH3-c-003 起手（B3-GATE）
Day 3 (5-10): CH3-c-003 收尾 + EQUIP-UI-001（分解/reroll）
Day 4 (5-11): ARCH-CONCERN-001 + GOV-001 + CH3-c-004 起手
Day 5 (5-12): CH3-c-004 收尾 + TECH-001 + 收尾验证（check-only / GUT / export / smoke）
```

---

## Definition of Done for this Sprint

- [x] 所有 Must Have 任务 COMPLETE，AC 全部 PASS
- [x] QA 计划存在并已被 stories 引用（`production/qa/qa-plan-sprint-8.md`）
- [x] 所有 Logic / Integration story 有对应自动化测试 PASS
- [x] `godot --headless --check-only project.godot` 退出码 0
- [x] GUT scene runner 退出码 0；新增覆盖无 regression
- [x] Windows export 退出码 0
- [x] Packaged smoke 维持 PASS（含 Ch.3 Battle 2 B3-GATE 分叉 → Battle 3 Boss 阶段 → 分解/reroll）
- [x] 玩家从主菜单 → Ch.3 战斗 2 → B3-GATE 选择 → Finale Boss → 战胜 → 装备分解/reroll，全程不需要重启
- [x] `production/epics/index.md` / `production/sprint-status.yaml` 状态同步
- [x] architecture.md §8 ADR 列表覆盖 001~009；BondSystem 接口无超前 `trigger_combo_skill`
- [x] Sprint-009 handoff 列出 Bond 联携技能实现、Fog-of-war MVP 实现、装备 +11+ 极风险区

---

## Sprint-009 Handoff 初稿

若 Sprint-008 Must Have 全部完成：

1. **Bond 联携技能实现**（依赖 Sprint-008 BOND-COMBO-DESIGN GDD + 多对 B-rank 关系）
2. **Fog-of-war MVP 实现**（依赖 Sprint-008 FOG-GDD + Sprint-007 Ch.3 战斗数据）
3. **装备 +11+ 极风险区**（接 EQUIP-UI-001）
4. **Ch.4 内容规划**（首个 post-Ch.3 章节）
5. **Architecture Review full mode**（Post-Sprint-007 review CONCERNS 跟进）

---

## 参考文档

| 文档 | 路径 | 说明 |
|------|------|------|
| Chapter 3 GDD | `design/gdd/chapter-03.md` | B3-GATE / 战斗 2/3 实现依据 |
| Belief Branching | `design/narrative/belief-branching.md` | B3-N1 分叉设计 |
| ADR-007 | `docs/architecture/ADR-007-belief-branch-system.md` | 信念分支架构 |
| ADR-008 | `docs/architecture/ADR-008-resource-economy-upgrade.md` | 资源经济约束 |
| ADR-009 | `docs/architecture/ADR-009-equipment-upgrade-scope.md` | 装备强化 scope |
| Equipment GDD | `design/gdd/equipment-system.md` | 分解 D.3 / reroll D.2 |
| Bond GDD | `design/gdd/bond-system.md` | 联携技能段起点 |
| Bond Epic | `production/epics/bond-system/EPIC.md` | BOND-001~004 |
| Fog-of-war Epic | `production/epics/fog-of-war/EPIC.md` | readiness stories |
| Architecture Review | `docs/architecture/architecture-review-2026-05-03.md` | Sprint-007 review |
| Architecture.md | `docs/architecture/architecture.md` | v0.2 待补全 |
| Sprint-人工 | `production/sprints/sprint-人工.md` | 外部验证队列（不阻塞） |

---

## QA Plan

> Status: **COMPLETE 2026-04-27** — `/qa-plan sprint-008` 已运行并完成验证，10 个 Sprint-008 stories/tasks 均有 QA 测试条件与完成证据
> Target: `production/qa/qa-plan-sprint-8.md`

**Scope check**：本 Sprint 选定的 stories 全部源自既有 GDD（Ch.3 / Equipment / Bond / Fog）+ Sprint-007 Handoff；无 epic 外新增。无需立即跑 `/scope-check`。

---

## Revalidation — 2026-04-27

### 完成进展

复核结论：Sprint-008 的 Must Have、Should Have、Nice to Have 实施与文档交付均已落地，状态为 **COMPLETE**。

| 复核项 | 结果 | 证据 |
|---|---|---|
| CH3-EPIC-002 Ch.3 epic/story 刷新 | 完成 | 3 个 story-*.md 状态从 Backlog → Complete；epic index Ch.3 行同步 |
| CH3-c-002 Ch.3 战斗 2 压力量表 | 完成 | `src/ui/combat/battle_definitions/chapter_03_act_b.json` + `tests/unit/chapter03/battle_2_pressure_test.gd` + `tests/integration/prototypes/chapter_03_battle_2_entry_test.gd` |
| CH3-c-003 B3-GATE 信念分叉激活 | 完成 | `src/core/belief/b3_gate_evaluator.gd`（dominant_route/margin/soft_lock/fallback/SaveData round-trip）；`tests/unit/chapter03/b3_gate_evaluator_test.gd` + `tests/integration/chapter03/b3_gate_persistence_test.gd` |
| EQUIP-UI-001 装备分解 + 词缀 reroll UI | 完成 | `character_management.gd` 分解/reroll 面板 + `tests/unit/equipment/decomp_reroll_test.gd` + `tests/integration/equipment/decomp_reroll_ui_test.gd` |
| ARCH-CONCERN-001 architecture.md 补全 | 完成 | `docs/architecture/architecture.md` §8 ADR 列表已扩展至 001~009；BondSystem 接口无超前 `trigger_combo_skill` |
| GOV-001 Sprint / Manifest / Status 同步 | 完成 | `sprint-status.yaml` 10 条全部 complete；`epics/index.md` 状态同步 |
| CH3-c-004 Ch.3 战斗 3 Finale + Boss | 完成 | `src/ui/combat/battle_definitions/chapter_03_finale.json`（Boss 三阶段 + B3-GATE 路线变体）；`tests/unit/chapter03/finale_route_variant_test.gd` + `tests/integration/chapter03/finale_boot_test.gd` |
| TECH-001 Regression hardening | 完成 | 879/879 PASS，无回归；negative test 已并入 chapter03 测试 |
| BOND-COMBO-DESIGN Bond 联携技能 GDD | 完成 | `design/gdd/bond-system.md` 联携技能段扩展（触发条件/效果类型/rank 门槛） |
| FOG-GDD Fog-of-war GDD 详化 | 完成 | `design/gdd/fog-of-war-system.md` Visibility/Reveal/Unit 规则落地 |
| godot --check-only | PASS | 退出码 0，无 parse error（独立验证） |
| GUT runner | PASS | 879 total / 879 pass / 0 fail，退出码 0（独立验证，+24 tests vs Sprint-007） |
| Windows export | per Codex 报告 PASS | `builds/windows/SRPG.exe` 124,334,616 bytes，SHA256 `A472CE20...` |
| Packaged smoke | per Codex 报告 PASS | `chapter3_act_b=true`, `b3_gate_route=ren`, `chapter3_finale=true`, `finale_boss_phase=3`, `chapter3_complete=true`, `decompose_materials=10`, `reroll_preserved_level=7` |

### 偏差说明

无偏差。Codex 执行轮次严格按照 Sprint-008 plan + QA plan 的 10 条任务执行，所有 Must/Should/Nice 交付物路径与预期一致。

### 遗留问题

- 外部体验验证、截图证据、release sign-off 仍由 `production/sprints/sprint-人工.md` 集中管理，不阻塞 Sprint-008。
- 自动化 gate 中 check-only 与 GUT 已独立复验 PASS；Windows export 与 packaged smoke 为 Codex 执行轮次的报告值。
- Bond 联携技能仅 GDD 落地，运行时实现推入 Sprint-009。
- Fog-of-war 仅 GDD 落地，运行时实现推入 Sprint-009。
- Ch.4 内容规划尚未开始。
- 不阻塞 Sprint-009 启动。
