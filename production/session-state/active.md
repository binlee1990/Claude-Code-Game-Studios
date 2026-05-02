# Session State

**Last Updated**: 2026-05-02

## Current Task
**Sprint-010 COMPLETE** — 治理收口 + 里程碑审查，12/12 stories done

Active stage: Production. Sprint-010 计划: `production/sprints/sprint-010.md`。
Sprint-009: COMPLETE（12/12 stories, 1021/1021 PASS）。

## 2026-05-01: 治理缺口补全 (Batch P0+P1+P2)
（见 git commit dd06831）

## 2026-05-02: Sprint-009 代码实现

### 新增源文件 (12)

| 文件 | 系统 | 行数 |
|------|------|------|
| `src/core/fog/fog_state_manager.gd` | fog-of-war | ~80 |
| `src/core/fog/fog_renderer.gd` | fog-of-war | ~90 |
| `src/core/fog/fusion_builder.gd` | fog-of-war | ~10 |
| `src/core/fog/fog_target_filter.gd` | fog-of-war | ~45 |
| `src/core/difficulty/difficulty_manager.gd` | difficulty | ~95 |
| `src/core/boss/boss_profile.gd` | boss | ~30 |
| `src/core/boss/boss_phase.gd` | boss | ~10 |
| `src/core/boss/boss_checkpoint.gd` | boss | ~15 |
| `src/core/boss/boss_action_pattern.gd` | boss | ~15 |
| `src/core/bond/combo_skill_data.gd` | bond | ~40 |
| `src/core/bond/combo_validator.gd` | bond | ~55 |
| `assets/data/difficulty/phase_curve.json` | difficulty | ~10 |

### 新增测试文件 (9) / +117 tests

| 文件 | 系统 |
|------|------|
| `tests/unit/difficulty/data_model_test.gd` | difficulty (22 tests) |
| `tests/unit/difficulty/integration_mock_test.gd` | difficulty integration (12 tests) |
| `tests/unit/boss/boss_profile_test.gd` | boss (16 tests) |
| `tests/unit/fog/visibility_model_test.gd` | fog (18 tests) |
| `tests/unit/fog/rendering_overlay_test.gd` | fog renderer (6 tests) |
| `tests/unit/fog/target_filter_test.gd` | fog target filter (7 tests) |
| `tests/unit/bond/combo_validator_test.gd` | bond combo (23 tests) |
| `tests/unit/equipment/extreme_risk_test.gd` | equipment +11+ (13 tests) |
| `tests/integration/fog/fog_save_load_test.gd` | fog save/load (4 tests) |

### Story 完成状态

| Story | Status |
|-------|--------|
| FOG-001 Visibility data model | ✅ Complete |
| FOG-002 Fog rendering overlay | ✅ Complete |
| FOG-003 Unit visibility integration | ✅ Complete |
| FOG-004 Save/load fog | ✅ Complete |
| BOND-COMBO-001 Combo data model + trigger | ✅ Complete |
| DIFF-001 Difficulty data model | ✅ Complete |
| DIFF-002 Difficulty integration | ✅ Complete |
| BOSS-001 Boss data model | ✅ Complete |
| EQUIP-014 Extreme-risk tuning | ✅ Complete |
| BOND-COMBO-002 Combo battle UI | ⏳ Code done, needs UI integration test |
| BOSS-002 Boss action pattern | ⏳ Partially covered, needs standalone test |

## Sprint-009 计划概要

| 类别 | 数量 | 系统 |
|------|------|------|
| Must Have | 7 | FOG-001~004 / BOND-COMBO-001 / DIFF-001 / BOSS-001 |
| Should Have | 3 | BOND-COMBO-002 / DIFF-002 / BOSS-002 |
| Nice to Have | 2 | EQUIP-014 / ARCH-REVIEW |

**排除**: 章节剧情内容、Ch.4 规划、NG+ 难度倍率选择。

## Sprint-008 最终状态

| 类别 | 数量 | 状态 |
|------|------|------|
| Must Have | 6 | ✅ 全 DONE |
| Should Have | 2 | ✅ 全 DONE |
| Nice to Have | 2 | ✅ 全 DONE |
| godot --check-only | - | ✅ 退出码 0 |
| GUT runner | - | ✅ 879/879 PASS |
| Windows export | - | ✅ 退出码 0 |
| Packaged smoke | - | ✅ PASS，含 Ch.3 Battle 2/B3-GATE/Finale/decomp/reroll |

### Sprint-008 交付物

| Area | 新建/修改文件 |
|------|--------------|
| Ch.3 Battle 2 | `src/ui/combat/battle_definitions/chapter_03_act_b.json`, `tests/unit/chapter03/battle_2_pressure_test.gd`, `tests/integration/prototypes/chapter_03_battle_2_entry_test.gd` |
| B3-GATE | `src/core/belief/b3_gate_evaluator.gd`, `tests/unit/chapter03/b3_gate_evaluator_test.gd`, `tests/integration/chapter03/b3_gate_persistence_test.gd` |
| Ch.3 Finale | `src/ui/combat/battle_definitions/chapter_03_finale.json`, `tests/unit/chapter03/finale_route_variant_test.gd`, `tests/integration/chapter03/finale_boot_test.gd` |
| Equipment UI | `character_management.gd` decomp/reroll panels, `tests/unit/equipment/decomp_reroll_test.gd`, `tests/integration/equipment/decomp_reroll_ui_test.gd` |
| Architecture | `docs/architecture/architecture.md` §8 ADR 001~009, §5 Base/Ch.3 data flows |
| Design | `design/gdd/bond-system.md` combo skills, `design/gdd/fog-of-war-system.md` |

### Sprint-008 验证

`879/879 PASS`, chapter_03 全三战 + B3-GATE + equipment UI 全闭环，Ch.3 可玩路径完整。

## Sprint-007 最终状态

| 类别 | 数量 | 状态 |
|------|------|------|
| Must Have | 5+2 | ✅ 全 DONE |
| Should Have | 3 | ✅ 全 DONE |
| Nice to Have | 1 | ✅ 全 DONE |
| godot --check-only | - | ✅ 退出码 0 |
| GUT runner | - | ✅ 855/855 PASS |
| Windows export | - | ✅ 退出码 0 |
| Packaged smoke | - | ✅ PASS |

<!-- STATUS -->
Epic: Alpha 准备
Feature: Sprint-010 Complete
Task: 等待人工 UX sign-off 后进入 Polish
<!-- /STATUS -->

## Sprint-006 最终状态

| 类别 | 数量 | 状态 |
|------|------|------|
| Must Have | 5 | ✅ 全 DONE |
| Should Have | 4 | ✅ 全 DONE |
| Nice to Have | 3 | ✅ 全 DONE |
| godot --check-only | - | ✅ 退出码 0 |
| GUT test runner | - | ✅ 退出码 0 |
| Windows export | - | ✅ 退出码 0 |
| Packaged smoke | - | ✅ PASS，含 Bond/Base/装备强化 +5 |

### Sprint-006 交付物

| Area | 新建/修改文件 |
|------|--------------|
| Bond MVP | `src/core/bond/bond_registry.gd`, `src/core/autoload/game_events.gd`, `src/ui/combat/battle_arena.gd`, `src/ui/management/character_management.gd` |
| Equipment enhancement | `src/core/resource/inventory.gd`, `src/core/equipment/equipment_component.gd`, `src/ui/management/character_management.gd`, `src/ui/menu/main_menu.gd` |
| Base Phase 1 | `src/core/base/action_points.gd`, `src/ui/base/base_hub.gd`, `src/ui/base/training_ground.gd` |
| Data / Design | `assets/data/economy/base-upgrade-costs.json`, `design/gdd/chapter-03.md` |
| Tests | `tests/unit/bond/bond_data_model_test.gd`, `tests/integration/bond/affinity_event_hooks_test.gd`, `tests/unit/base/action_points_test.gd`, extended equipment/base/character UI tests |

### Sprint-006 验证

`PACKAGED_PLAYTHROUGH_SMOKE PASS {"base_enhanced_level":5,"battle":"chapter_01_finale","bond_growth_present":true,"camp_report_present":true,"management_tab":"equipment","success":true}`

## Sprint-005 最终状态

| 类别 | 数量 | 状态 |
|------|------|------|
| Must Have | 5 | ✅ 全 DONE |
| Should Have | 4 | ✅ 全 DONE |
| Nice to Have | 5 | ✅ 全 DONE |
| godot --check-only | - | ✅ 0 parse error |
| GUT test runner | - | ✅ 退出码 0 |
| Packaged smoke | - | ✅ PASS，无 ObjectDB/resource leak warning |

### Sprint-005 交付物

| Story | 新建/修改文件 |
|-------|--------------|
| LOC-001 | `src/core/localization/srpg_localization.gd`，基地/训练/管理/战斗管理入口文案迁移 |
| LOC-002 | `src/ui/menu/main_menu.gd` 语言切换按钮与即时刷新 |
| LOC-003 | `src/core/save/save_data.gd` / `save_manager.gd` locale 持久化 |
| REL-001 | 主菜单 Credits overlay + `design/ux/credits-screen.md` |
| REL-002 | localization / Credits tests + manifest |
| GOV-001 | `production/epics/index.md`、localization epic/story 状态同步 |
| CH3-001 | `design/gdd/chapter-03.md` skeleton |
| BOND-001 | `production/epics/bond-system/` readiness epic |
| TECH-001 | packaged smoke BGM resource leak 修复 + triage doc |
| ADR-008/009 | resource economy / equipment upgrade draft ADRs |
| BASE-FULL-001 | `docs/active/base-full-readiness-brief.md` |
| FOG-001 | `production/epics/fog-of-war/` readiness epic |

### Sprint-005 遗留

| 项 | 状态 | 说明 |
|---|---|---|
| Ch.2 human playtest | backlog | 仍需人工验证培养闭环体验，但不阻塞非人工完成 |
| Sprint-004 screenshots/sign-off | backlog | 仍为人工视觉证据，不阻塞 Sprint-005 |
| ADR-008/009 | Accepted (2026-04-27) | 三节齐全，Sprint-006 base/equipment upgrade 实现门禁解除 |

---

## Sprint-004 最终状态

| 类别 | 数量 | 状态 |
|------|------|------|
| Must Have | 5 | ✅ 全 DONE |
| Should Have | 3 | ✅ 全 DONE |
| Nice to Have | 2 | ✅ 1 DONE，1 待人工 |
| godot --check-only | - | ✅ 0 parse error |

### Sprint-004 交付物

| Story | 新建/修改文件 |
|-------|--------------|
| MGMT-001 | character_management.gd, character_tab_bar.gd, character_management_screen.tscn |
| MGMT-002 | equipment_management.gd, equipment_management_screen.tscn |
| MGMT-003 | battle_arena.gd（Tab 整合） |
| MGMT-004 | battle_arena.gd（存档集成） |
| MGMT-005 | main_menu.gd/tscn, battle_arena.gd（基地入口） |
| BASE-001 | base_hub.gd, base_hub.tscn |
| BASE-002 | training_ground.gd |
| BASE-003 | base_hub.gd（市集），Inventory 升为 Autoload |

### 遗留（Nice to Have - 待人工）

| Story | 状态 | 说明 |
|-------|--------|------|
| BASE-004 | ⏳ backlog | 需要人工执行 Ch.2 playtest 验证培养闭环 |

---

## Sprint-003 最终状态

| 类别 | 数量 | 状态 |
|------|------|------|
| Must Have | 6 | ✅ 全 DONE |
| Should Have | 3 | ✅ 全 DONE |
| Nice to Have | 2 | ✅ 人工已标 DONE |
| 测试新增 | 78 | ✅ 764/764 PASS |

## Sprint-004 概要（2026-04-26 → 2026-05-01）

- Plan: `production/sprints/sprint-004.md`（v1.0 COMPLETE）
- Goal: 管理界面 Beta（角色+装备 UI）+ 基地系统 MVP（训练场+市集）

---

## Sprint-003 历史（参考）

### Sprint-003 概要（2026-04-26 → 2026-05-01）

- Plan: `production/sprints/sprint-003.md`（v1.0 PLANNING）
- Status YAML: `production/sprint-status.yaml`
- Goal: 把 Ch.2 从 GDD/JSON skeleton 推进到玩家可玩的三战完整内容
- Capacity: 5 天 / 6 Must Have + 3 Should Have + 2 Nice to Have

| 优先级 | Story IDs |
|---|---|
| Must Have | CH2-c-001 章节路由+B2-GATE / CH2-c-002 王秀护送 AI / CH2-c-003 护卫姿态分摊 / CH2-c-004 镇压战结算 / CH2-c-005 Boss 三阶段+检查点+援军 / CH2-c-006 果子二选三 |
| Should Have | CH2-c-000 story 文件落地 / BOSS-GDD-001 占位 GDD / GOV-ADR-007 信念值 ADR |
| Nice to Have | QA-EVID-001 Sprint-002 收尾 / CH2-PT-001 Ch.2 playtest |

## 关键风险

1. CH2-c-002 王秀 A* + 畏缩 AI 调参（HIGH/HIGH）→ Day 1 优先做独立 stories，AI 集中第 2-4 天
2. boss-system GDD 缺失（MED/MED）→ BOSS-GDD-001 是 CH2-c-005 硬前置
3. chapter-02 epic stories 仅 placeholder（HIGH/HIGH）→ CH2-c-000 第 1 天首先完成

## Day 1 完成（2026-04-26）

| Story | 交付物 | 测试 |
|--------|--------|------|
| CH2-c-000 | 6 个 story-*.md 文件 | N/A |
| BOSS-GDD-001 | 确认 boss-system.md 存在，F2 公式澄清 | N/A |
| CH2-c-001 | belief_system.gd / belief_gate.gd | 24 tests → 710/710 PASS |
| CH2-c-003 | guard_stance.gd | 9 tests → 731/710 PASS |
| CH2-c-006 | fruit_selection.gd | 12 tests → 731/710 PASS |

## Day 2 完成（2026-04-26）

| Story | 交付物 | 测试 |
|--------|--------|------|
| CH2-c-004 | suppression_battle_settlement.gd | 8 tests → 739/739 PASS |
| GOV-ADR-007 | ADR-007-belief-branch-system.md (Accepted) | N/A |

**测试基线**: 739/739 PASS（含原有 686）

## Day 3 完成（2026-04-26）

| Story | 交付物 | 测试 |
|--------|--------|------|
| CH2-c-005 | boss_phase_controller.gd | 20 tests → 757/757 PASS |
| CH2-c-002 | wang_xiu_ai.gd + game_events 新增 npc_departed signal | 19 tests → 776/776 PASS |

**测试基线**: 776/776 PASS（含原有 686）

**Sprint 进度**: 9/11 done（6 Must Have + 3 Should Have）
**剩余 Nice to Have**: QA-EVID-001（需手动截图）/ CH2-PT-001（需实际游玩）

## 下一步

- ⏳ Day 3：CH2-c-002 王秀 AI（A* + 畏缩）/ CH2-c-005 Boss 检查点逻辑准备
- ⏳ Day 4：CH2-c-005（Boss 三阶段 + 援军刷新）
- ⏳ Day 5：Ch.2 smoke + Nice to Have

## Sprint-002 已完成（参考）

详见下方 Sprint-002 历史段。已 outstanding 项已纳入 Sprint-003 Nice to Have（QA-EVID-001）。

## Sprint-002 Lane C — COMPLETE 2026-04-26

| Story | 交付物 | 行数 | 状态 |
|-------|-------|------|------|
| CH2-001 | `design/gdd/chapter-02.md`（8 节全量） | 531 行 | DONE |
| CH2-002（信念值分支） | `design/narrative/belief-branching.md`（新建，含目录） | ~170 行 | DONE |
| CH2-003（三战 JSON） | `chapter_02_act_a.json` / `chapter_02_act_b.json` / `chapter_02_finale.json` | 各约 100-200 行 | DONE |
| CH2-004（epic 入口） | `production/epics/chapter-02/index.md` | ~70 行 | DONE |
| CH2-004（index 追加） | `production/epics/index.md` 末尾新增 chapter-02 行 | +1 行 | DONE |

## 关键决策记录（Lane C）

- B2-GATE 分叉阈值：5（义领先 ≥5 走 suppression，否则走 mercy）
- 王秀 HP：30；护卫姿态伤害分摊比：30%
- Ch.2-3 援军刷新：第 12 回合（阶段三提前至第 10 回合）
- enemy_stat_multiplier：act_a=1.10 / act_b=1.15 / finale=1.30
- design/narrative/ 目录已由 Write 工具自动创建

## Sprint-002 Lane A — COMPLETE 2026-04-26

| Story | 交付物 | 状态 |
|-------|-------|------|
| GOV-001 | ADR-004 Combat System → Accepted | DONE |
| GOV-002 | ADR-005 AI Behavior → Accepted | DONE |
| GOV-003 | ADR-006 Attribute Data Model → Accepted | DONE |
| GOV-004 | docs/architecture/control-manifest.md → v2（覆盖 ADR-001~006） | DONE |
| GOV-005 | 12 EPIC.md 回填 TR-IDs（65 行 TR refs） | DONE |
| GOV-006 | docs/architecture/tr-registry.yaml 加 DEPRECATED 注释，权威路径迁至 production/registries/ | DONE |

## Sprint-002 Lane B — COMPLETE 2026-04-26

| Story | 交付物 | 状态 |
|-------|-------|------|
| UI-P0-01 | 主菜单焦点 GOLD + 存档摘要 + SaveManager.peek_save 只读接口 | DONE |
| UI-P0-02 | 战斗 HUD Auto/手动徽章 + speed badge | DONE |
| UI-P0-03 | 回合立牌迷你 HP 条（HP%-color） | DONE |
| UI-P0-04 | src/ui/common/hint_bar.gd 全局按键提示行（主菜单 + 战斗均挂载） | DONE |
| ART-P0-05 | 标题字体 ZCOOL XiaoWei（OFL）落盘 + srpg_theme TITLE_FONT preload | DONE |
| ART-P0-06 | 正文字体 Noto Serif SC（OFL）落盘 + srpg_theme BODY_FONT preload | DONE |
| AUDIO-P0-07 | 主菜单 BGM Cambodean Odyssey（CC-BY 3.0，727KB）autoplay loop | DONE |
| AUDIO-P0-08 | 战斗 BGM Rite of Passage（CC-BY 3.0，3.3MB）autoplay loop | DONE |

## 关键架构决策记录（Lane B）

- focus stylebox border 颜色全局 JADE → GOLD（统一焦点视觉语言）
- SaveManager 加 peek_save(slot) → SaveData 只读接口（避免 load_game 副作用污染主菜单预览）
- HintBar 类型注解用 Control 而非 class_name HintBar（规避 Godot --check-only 模式下 class 注册时序问题）
- BGM autoplay 在 _ready 末尾挂载；AudioStreamOggVorbis 设 loop=true；OGG 文件需先 godot --editor 触发 import 扫描

## 关键事件记录（Lane B 资产链）

- art-director 初版 BGM 清单 4 条 URL 全部死链（soundimage 404、opengameart 搜索页非直链、pixabay 403、Wonders_2014 archive item 文件清单为空）
- audio-director 重做后仍有 3/4 死链（Wonders_2014 album 内文件 02/05/10 均 404）
- orchestrator 介入直接 curl https://archive.org/download/Global_Sampler-9620/ 拉取真实文件清单，挑出 9 首中适配武侠基调的 2 首作为 menu/battle BGM
- 教训：archive.org item 存在 ≠ 内部任意预期文件名存在；future agent 必须基于真实 directory listing 而非搜索结果中"看似"的曲目编号

## Sprint-002 Baseline Documents — 2026-04-26

| Lane | Document | Path | Lines |
|------|----------|------|-------|
| L1 治理 | Architecture review | `production/reviews/architecture-review-2026-04-26.md` | 276 |
| L1 治理 | TR registry | `production/registries/tr-registry.yaml` | 699 |
| L2 内容 | Chapter 2 GDD skeleton | `design/gdd/chapter-02.md` | 179 |
| L3 UX | UI redesign proposal | `design/ux/ui-redesign-proposal-2026-04-26.md` | 368 |
| L4 美术 | Free asset shopping list | `production/assets/free-asset-shopping-list.md` | 283 |
| L4 美术 | Art redesign direction | `design/art/redesign-direction-2026-04-26.md` | 210 |

## Sprint-002 Plan

Path: `production/sprints/sprint-002.md`
Status: **COMPLETE** (v1.0 — 2026-04-26)

| Lane | Stories | Risk | Notes |
|------|---------|------|-------|
| A 治理闭环 | GOV-001~006 (6) | LOW — 文档级 | ADR-004/005/006 升 Accepted + control-manifest v2 + tr-registry 集成 |
| B 观感 P0 修复 | UI/ART/AUDIO-P0-01~08 (8) | LOW-MED — 代码级但范围有限 | 字体 + BGM + 主菜单焦点 + Auto 状态可读性 + 迷你 HP 条 + 按键提示 |
| C Ch.2 内容基线 | CH2-001~004 (4) | LOW — 设计级 | Ch.2 GDD 全量展开 + 信念值分支 + epic 创建 |

## Critical Findings From Baseline

1. **治理 P0**: ADR-004/005/006 status=Proposed 但其 12 epic 已 Complete — 合规绕过风险，需立即提升至 Accepted
2. **观感 P0**: 玩家"简陋感"主因是字体不统一 + 音频缺失 — 零逻辑改动即可显著改善（替换 OFL 字体 + 挂载 OpenGameArt BGM）
3. **内容 P0**: Ch.1 finale 后无下一战 — Ch.2 GDD skeleton 已就位，需 `/design-system` 全量展开
4. **路径冲突**: 存在两个 tr-registry 路径 — 本轮已规范化到 `production/registries/`，旧的 `docs/architecture/tr-registry.yaml` 待 deprecated

## Out of Sprint-002 Scope (Sprint-003+)

- 羁绊 / 战争迷雾 / 基地 / 多周目 / 事件系统 / 正式音频系统 epic 化与实现
- 深度手动编队、装备切换、奖励领取动画的管理屏升级
- 角色立绘 / 3D 立牌正式美术资产
- 全量本地化、平台合规、人工 release sign-off

---

## Legacy Sections (Sprint-001 history) — kept for traceability

## Immediate Execution Checklist — 2026-04-25

| Step | Owner | Evidence file | Exit rule |
|------|-------|---------------|-----------|
| Visual sign-off on formal battle path | Human | `production/playtests/playtest-2026-04-24-visual-signoff.md` | COMPLETE — PASS WITH NOTES |
| Free-play fun validation rerun | Human | `production/playtests/playtest-2026-04-25-fun-validation-rerun.md` | COMPLETE — PASS WITH PRODUCT-SCOPE NOTES |
| Targeted UX friction fixes | Agent | `src/ui/combat/battle_arena.gd`, `src/core/combat/speed_controller.gd` | COMPLETE — board responsiveness, Auto status/immediate takeover/paced turns, speed-tier test cleanup, and main-menu return |
| Stage resync after rerun | Human + agent | `production/session-state/active.md`, `production/project-stage-report.md`, `production/stage.txt` | COMPLETE — stage advanced to `Production` with concerns |
| Windows packaged-build playthrough | Human + agent | `production/playtests/windows-build-smoke-2026-04-25.md` | PASS — `builds/windows/SRPG.exe` generated, launches, and passes main menu -> battle -> Auto/manual -> save/load -> main menu |
| Chapter 1 content/presentation batch | Agent | `production/qa/evidence/chapter-01-content-slice-evidence.md` | COMPLETE — automated suite, check-only, export, and launch smoke all pass |
| Post-battle settlement/reward path | Agent | `production/qa/evidence/post-battle-settlement-evidence.md` | COMPLETE — victory grants EXP/gold/materials/equipment, settlement menu exposes rewards, SaveManager restores the post-battle state |
| Campaign/camp/tactics systems path | Agent | `production/qa/evidence/campaign-camp-tactics-evidence.md` | COMPLETE — second battle, default camp growth, tactical modifiers, AI/Boss behavior, save/load, tests, export, and launch smoke pass |
| Chapter 1 complete release path | Agent | `production/qa/evidence/chapter-01-complete-release-evidence.md` | COMPLETE — third battle, independent management screen, audio/localization scaffolds, release packaging script, packaged scripted playthrough, export, and launch smoke pass |

## Production Guardrails

- Do not treat the vertical-slice PASS as release readiness.
- Prioritize Chapter 2 content expansion, deeper manual management interactions, and human subjective UI/UX release sign-off before broad new systems.
- Keep every production-phase lane tied to smoke tests, human-visible evidence, or automated regression.

## Phase 1 Documentation — Completed 2026-04-23

| # | Task | Output File | Status |
|---|------|-------------|--------|
| 1 | Battle HUD UX spec | design/ux/battle-hud.md | DONE |
| 2 | Main Menu UX spec | design/ux/main-menu.md | DONE |
| 3 | Pause Menu UX spec | design/ux/pause-menu.md | DONE |
| 4 | HUD Design Document | design/ux/hud.md | DONE |
| 5 | Control Manifest | docs/architecture/control-manifest.md | DONE |
| 6 | Character Visual Profiles | design/art/character-visual-profiles.md | DONE |
| 7 | Art Bible AD Sign-off | design/art/art-bible.md (header updated) | DONE |
| 8 | Sprint Plan Rewrite | production/sprints/sprint-001.md (v1.0) | DONE |
| 9 | Core ADRs ×3 | docs/architecture/ADR-004/005/006 | DONE |

## Phase 1 Impact on Gate Artifacts

| Gate Artifact | Before | After |
|---------------|--------|-------|
| UX specs for key screens | 0 | 3 (battle-hud, main-menu, pause-menu) |
| HUD design document | MISSING | design/ux/hud.md |
| Control manifest | MISSING | docs/architecture/control-manifest.md |
| Character visual profiles | MISSING | design/art/character-visual-profiles.md |
| AD-ART-BIBLE sign-off | MISSING | APPROVED WITH NOTES |
| Sprint plan with real paths | FAIL (generic IDs) | PASS (real story paths) |
| Core layer ADRs | 0 (only Foundation) | 3 (Combat/AI/Attribute) |

## Remaining Blockers (Phase 2+3)

| Blocker | Status | Action |
|---------|--------|--------|
| Vertical Slice build | IMPLEMENTATION COMPLETE | 自动化验证通过，人工可读性 PASS WITH NOTES |
| Playtest ≥3 sessions | STRUCTURED VALIDATION COMPLETE | 已有 3 份 session 记录（1 人工自测 + 2 scripted validation） |
| Core loop fun validated | PASS WITH CONCERNS | 2026-04-25 rerun PASS；玩家表示需要完善游戏才愿意继续 |

## Architecture Update — ADRs

| ADR | Title | Status | Layer |
|-----|-------|--------|-------|
| ADR-001 | Event Architecture | Accepted | Foundation |
| ADR-002 | Scene Management | Accepted | Foundation |
| ADR-003 | Save System | Accepted | Foundation |
| ADR-004 | Combat System | Proposed | Core |
| ADR-005 | AI Behavior | Proposed | Core |
| ADR-006 | Attribute Data Model | Proposed | Core |

## Progress Summary

### Verified & Closed (31 stories, 376 test functions)

| Epic | Stories | Tests | Status |
|------|---------|-------|--------|
| **attribute-system** | 7 | 82 | COMPLETE |
| **class-system** | 6 | ~96 | COMPLETE |
| **resource-economy** | 6 | ~73 | COMPLETE |
| **tactical-mechanism** | 5 | ~66 | COMPLETE |
| **ai-system** | 6 | ~59 | COMPLETE |

### Sprint 001 Scope (Vertical Slice)

| Epic | Stories | Status |
|------|---------|--------|
| turn-based-mode (收尾) | 2 | COMPLETE |
| battle-settlement | 5 | COMPLETE |
| camera-map-system | 3 | COMPLETE |
| ui-system | 3 | COMPLETE |

## Consistency Check — 2026-04-22
- Registry: design/registry/entities.yaml — populated with 7 items, 15 formulas, 35 constants
- Cross-review: PASS (blockers fixed 2026-04-23)

## Tech Debt — Pre-existing Test Issues
- Resolved 2026-04-23: automated baseline restored to 0 compile failures / 0 assertion failures

## Current Validation State — 2026-04-23
- Formal battle path (`main_menu -> battle`) is now playable
- Camera / Map / UI / SaveManager productization implemented
- Formal battle scene was remediated from awkward 2.5D projection to a 2D top-down readable grid after user feedback
- Automated coverage passes, including:
  - `tests/integration/camera/battle_camera_map_test.gd`
  - `tests/integration/camera/save_load_integration_test.gd`
  - `tests/integration/ui/battle_hud_test.gd`
  - `tests/integration/ui/save_load_integration_test.gd`
  - `tests/integration/save/battle_save_manager_integration_test.gd`
- Structured validation sessions now exist:
  - `production/playtests/playtest-2026-04-23-session-1.md`
  - `production/playtests/playtest-2026-04-23-session-2.md`
  - `production/playtests/playtest-2026-04-23-session-3.md`
- Human visual readability sign-off is PASS WITH NOTES; subjective fun validation rerun is PASS WITH PRODUCT-SCOPE NOTES

## P3 Progress — 2026-04-23
- `skill-system` epic implementation complete
- `equipment-system` epic implementation complete
- `character-management` epic implementation complete
- New coverage added:
  - `tests/unit/skill/skill_data_model_test.gd`
  - `tests/unit/skill/proficiency_leveling_test.gd`
  - `tests/unit/skill/rank_system_test.gd`
  - `tests/unit/skill/trait_selection_test.gd`
  - `tests/unit/skill/skill_damage_test.gd`
  - `tests/unit/skill/class_skills_test.gd`
  - `tests/integration/skill/save_load_integration_test.gd`
  - `tests/unit/equipment/equipment_data_model_test.gd`
  - `tests/unit/equipment/affix_generation_test.gd`
  - `tests/unit/equipment/enhancement_test.gd`
  - `tests/unit/equipment/set_bonus_test.gd`
  - `tests/unit/equipment/decomposition_test.gd`
  - `tests/unit/equipment/final_attribute_test.gd`
  - `tests/integration/equipment/save_load_integration_test.gd`
  - `tests/unit/character/party_composition_test.gd`
  - `tests/unit/character/departure_recall_test.gd`
  - `tests/integration/character/save_load_integration_test.gd`
- Automatable P3 recommendation chain complete (`skill-system` → `equipment-system` → `character-management`)
- Pre-Production -> Production gate has moved beyond PARTIAL; remaining work is Production-phase product completion and polish

## Session Extract — /dev-story 2026-04-23
- Story: production/epics/turn-based-mode/story-006-speed-up-mode.md — Speed-Up Mode (TBM-006)
- Files changed:
  - `src/core/autoload/game_events.gd` (edit: +1 signal `speed_tier_changed`)
  - `src/core/combat/speed_controller.gd` (new, 139 lines)
  - `tests/unit/turn/speed_up_mode_test.gd` (new, 14 tests, all PASS)
  - `tests/tests_manifest.txt` (edit: registered new test file)
  - `production/epics/turn-based-mode/story-006-speed-up-mode.md` (Manifest Version N/A → 2026-04-23-v1)
- Test result: 14/14 PASS; suite totals 447 tests / 430 pass / 17 pre-existing fail (unchanged)
- Blockers: None
- Next: /code-review src/core/combat/speed_controller.gd src/core/autoload/game_events.gd then /story-done

## Session Extract — /story-done 2026-04-23
- Verdict: COMPLETE
- Story: production/epics/turn-based-mode/story-006-speed-up-mode.md — Speed-Up Mode (TBM-006)
- Review Mode: solo (LP-CODE-REVIEW + QL-TEST-COVERAGE gates skipped)
- Code Review (manual): APPROVED WITH NITS → both NITs fixed (enum-name dict keys, signal order documented)
- Tech debt logged: None
- Sprint-001 progress: 1/13 Complete (TBM-006), 12 remaining
- Next recommended: TBM-007 Save/Load Integration (only story directly unblocked by TBM-006)

## Session Extract — /dev-story+/story-done 2026-04-23 (TBM-007)
- Verdict: COMPLETE (AC-S1 ~ AC-S4 all pass; position field deferred — requires camera-map-system)
- Story: production/epics/turn-based-mode/story-007-save-load-integration.md — Turn-Based Save/Load Integration
- Files changed:
  - `src/core/combat/speed_controller.gd` (+serialize/deserialize ~15 lines)
  - `src/core/combat/auto_battle_controller.gd` (+serialize/deserialize)
  - `src/core/combat/action_system.gd` (+serialize/deserialize)
  - `src/core/combat/combat_system.gd` (+serialize/deserialize with enum validation)
  - `tests/integration/turn/save_load_integration_test.gd` (new, 10 tests)
  - `tests/tests_manifest.txt` (+1 line)
- Test result: 10/10 PASS; suite totals 457 tests / 440 pass / 17 pre-existing fail (Δ=+10)
- Code review: APPROVE with MEDIUM finding fixed (enum validation on _state/_result/team)
- Epic turn-based-mode: ALL 7 STORIES COMPLETE (001-007)
- Sprint-001 progress: 2/13 Complete (TBM-006, TBM-007), 11 remaining
- Next recommended: BS-001 Settlement Trigger Flow (pure Logic, battle-settlement epic start)

## Session Extract — /dev-story+/story-done 2026-04-23 (BS-001)
- Verdict: COMPLETE
- Story: production/epics/battle-settlement/story-001-settlement-trigger-flow.md — Settlement Trigger & Flow
- Files changed:
  - `src/core/settlement/settlement_result.gd` (new)
  - `src/core/settlement/settlement_trigger.gd` (new)
  - `src/core/autoload/game_events.gd` (+signal `settlement_triggered`)
  - `tests/unit/settlement/settlement_trigger_test.gd` (new, 15 tests)
  - `tests/tests_manifest.txt` (+1 line)
- Test result: 15/15 PASS; suite totals 472 tests / 455 pass / 17 pre-existing fail (Δ=+15)
- Sprint-001 progress: 3/13 Complete (TBM-006, TBM-007, BS-001), 10 remaining
- Logic batch progress: 3/5 (remaining: BS-002, BS-003, BS-004)
- Next: BS-002 Experience Distribution (Logic, consumes SettlementResult)

## Session Extract — /dev-story+/story-done 2026-04-23 (BS-002)
- Verdict: COMPLETE
- Story: production/epics/battle-settlement/story-002-experience-distribution.md — Experience Distribution
- Files changed:
  - `src/core/settlement/experience_distribution.gd` (new, pure math helper class)
  - `tests/unit/settlement/experience_distribution_test.gd` (new, 18 tests)
  - `tests/tests_manifest.txt` (+1 line)
- Test result: 18/18 PASS; suite totals 490 tests / 473 pass / 17 pre-existing fail (Δ=+18)
- Deviations: test file renamed `exp_distribution_test.gd` → `experience_distribution_test.gd` for class-name consistency; `apply_with_overflow` returns both `overflow` and `current` fields (semantic aliases)
- Sprint-001 progress: 4/13 Complete (TBM-006, TBM-007, BS-001, BS-002), 9 remaining
- Logic batch progress: 4/5 (remaining: BS-003, BS-004)
- Next: BS-003 Battle Evaluation (Logic, ~3 ACs)

## Session Extract — /dev-story+/story-done 2026-04-23 (BS-003)
- Verdict: COMPLETE
- Story: production/epics/battle-settlement/story-003-battle-evaluation.md — Battle Evaluation
- Files: `src/core/settlement/battle_evaluation.gd` (new), `tests/unit/settlement/battle_evaluation_test.gd` (14 tests), `tests/tests_manifest.txt` (+1)
- Test result: 14/14 PASS; suite 504/487/17 (Δ=+14)
- Next: BS-004

## Session Extract — /dev-story+/story-done 2026-04-23 (BS-004)
- Verdict: COMPLETE
- Story: production/epics/battle-settlement/story-004-material-equipment-drops.md — Material & Equipment Drops
- Files: `src/core/settlement/drop_calculator.gd` (new), `tests/unit/settlement/drop_calculator_test.gd` (18 tests), `tests/tests_manifest.txt` (+1)
- Test result: 18/18 PASS; suite 522/505/17 (Δ=+18)
- Fixes applied pre-write: extends Gut (not GutTest); TIER_MATERIAL_MULTIPLIER table to decouple enum ordinal from numeric tier (NORMAL=0 would have yielded 0 materials without this)
- Logic batch: ALL 5 COMPLETE (TBM-007, BS-001, BS-002, BS-003, BS-004)
- Sprint-001 progress: 6/13 Complete, 7 remaining (BS-005, CM-001/002/003, UI-001/002/003)
- CHECKPOINT: Return to user for next-batch decision (CM vs UI vs Integration vs stop)

## Session Extract — /dev-story+/story-done 2026-04-23 (BS-005)
- Verdict: COMPLETE
- Story: production/epics/battle-settlement/story-005-save-load-integration.md — Settlement Save/Load Integration
- Scope clarified: AC-S1 for EXP/gold/materials is already covered by pre-existing save/load integrations (class-system, resource-economy). BS-005's real work is BattleHistoryLog (new persistent class) + round-trip verification + end-to-end pipeline integration test
- Files: `src/core/settlement/battle_history_log.gd` (new), `tests/integration/settlement/save_load_integration_test.gd` (new, 17 tests incl. E2E with real SettlementTrigger/Dist/Eval/Drop pipeline), `tests/tests_manifest.txt` (+1)
- Test result: 17/17 PASS; suite 539/522/17 (Δ=+17)
- Epic battle-settlement: ALL 5 COMPLETE (001-005)
- Sprint-001 progress: 7/13 Complete, 6 remaining
- Remaining 6 stories ALL require scene/UI work + manual visual verification:
  - CM-001 斜45度摄像机 (Visual/Feel)
  - CM-002 网格地图渲染 (Visual/Feel, depends on CM-001)
  - CM-003 存档集成 (Integration, depends on CM-001/002)
  - UI-001 战斗 HUD (UI, depends on battle-hud UX spec ✓)
  - UI-002 资源HUD+菜单 (UI)
  - UI-003 存档集成 (Integration, depends on UI-001/002)
- CHECKPOINT REACHED: autonomous Logic/Integration completion ceiling
- Total new tests in this session: 106 (all PASS); pre-existing 17 failures unchanged
- Total new source files: 7 (speed_controller, settlement_result, settlement_trigger, experience_distribution, battle_evaluation, drop_calculator, battle_history_log)

## Session Extract — /architecture-review 2026-04-27
- Verdict: CONCERNS（已修复）
- Mode: 增量审查（ADR-008/009）
- Requirements: 13 increment TR — 8 covered after sync, 0 partial, 0 gap
- New TR-IDs registered: None（仅同步既有 TR 的 adr 字段）
- ADRs touched: ADR-008（§Dependencies / §Engine / §GDD reqs 修订）；ADR-009（无修订）
- Cross-ADR conflicts found: 3 — 全部已修
  - C-1 信号重复（inventory_changed vs resource_changed/item_acquired）→ 改为复用既有信号
  - C-2 Dependencies 节歧义 → 拆 Depends On / Enables
  - C-3 TR ID 命名错误 TR-econ → TR-resource
- Engine compat: PASS（无 deprecated / post-cutoff API、无 Jolt/D3D12 影响）
- GDD revision flags: None
- TR registry: version 2 → 3, 8 行 adr 字段补登
- Report: docs/architecture/architecture-review-2026-04-27.md
- Follow-ups: F-1 GameEvents 登记 equipment_enhanced（Sprint-006 实现期）/ F-2 强化 UI AccessKit 验收 / F-3 下次 full review 对齐 architecture.md
## Session Extract — /qa-plan sprint-007 + dev-story kickoff 2026-04-27

Generated `production/qa/qa-plan-sprint-7.md` with QA conditions for all 11 Sprint-007 stories/tasks. Started Sprint-007 dev-story cadence by completing `CH3-EPIC-001`: created `production/epics/chapter-03/EPIC.md`, four Chapter 03 story skeletons, Base Tavern/Upgrade Sprint-007 stories, Equipment risk-zone stories, and TR registry entries for the new Sprint-007 requirements. Next pickup: `/dev-story production/epics/chapter-03/story-001-battle-1-implementation.md`.
