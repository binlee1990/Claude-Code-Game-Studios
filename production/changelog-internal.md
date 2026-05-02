# Internal Changelog — Sprint-001 through Sprint-009
> Generated: 2026-05-02
> Source: `production/sprints/sprint-001.md` ~ `sprint-009.md` + git log

---

## Sprint-001: Vertical Slice 核心循环
> Status: COMPLETE WITH PRODUCT-SCOPE NOTES | Baseline: 805 test_ methods

| Story ID | System | Files | Tests |
|----------|--------|-------|-------|
| TBM-006 | turn-based-mode | `src/core/combat/speed_controller.gd`, `src/core/autoload/game_events.gd` | 14 |
| TBM-007 | turn-based-mode | `src/core/combat/speed_controller.gd`, `auto_battle_controller.gd`, `action_system.gd`, `combat_system.gd` | 10 |
| BS-001 | battle-settlement | `src/core/settlement/settlement_result.gd`, `settlement_trigger.gd` | 15 |
| BS-002 | battle-settlement | `src/core/settlement/experience_distribution.gd` | 18 |
| BS-003 | battle-settlement | `src/core/settlement/battle_evaluation.gd` | 14 |
| BS-004 | battle-settlement | `src/core/settlement/drop_calculator.gd` | 18 |
| BS-005 | battle-settlement | `src/core/settlement/battle_history_log.gd` | 17 |
| CM-001 | camera-map-system | Camera scene/script (2D top-down fallback; isometric deferred) | — |
| CM-002 | camera-map-system | Grid map rendering (2D top-down) | — |
| CM-003 | camera-map-system | Save/load integration | — |
| UI-001 | ui-system | `src/ui/combat/battle_arena.gd` (battle HUD) | — |
| UI-002 | ui-system | Resource HUD + menu system | — |
| UI-003 | ui-system | Save/load integration | — |

**Gates**: godot --check-only PASS, GUT runner exit 0, packaged smoke PASS
**Note**: Pre-existing 5 epics (attribute/class/resource/tactical/AI) — 31 stories, 376 tests — completed prior to Sprint-001.

---

## Sprint-002: 治理闭环 + 观感 P0 + Ch.2 内容基线
> Status: COMPLETE | 686/686 PASS

### Lane A — 治理闭环

| Story ID | System | Files | Tests |
|----------|--------|-------|-------|
| GOV-001 | governance | `docs/architecture/ADR-004-combat-system.md` (Accepted) | — |
| GOV-002 | governance | `docs/architecture/ADR-005-ai-behavior.md` (Accepted) | — |
| GOV-003 | governance | `docs/architecture/ADR-006-attribute-data-model.md` (Accepted) | — |
| GOV-004 | governance | `docs/architecture/control-manifest.md` (v2, covers ADR-001~006) | — |
| GOV-005 | governance | 12× `production/epics/*/EPIC.md` (65 TR-ID refs backfilled) | — |
| GOV-006 | governance | `docs/architecture/tr-registry.yaml` (DEPRECATED, canonical → `production/registries/`) | — |

### Lane B — 观感 P0

| Story ID | System | Files | Tests |
|----------|--------|-------|-------|
| UI-P0-01 | ui-system | `src/ui/menu/main_menu.gd`, `src/core/save/save_manager.gd` (peek_save) | — |
| UI-P0-02 | ui-system | `src/ui/combat/battle_arena.gd` (Auto/speed badge) | — |
| UI-P0-03 | ui-system | `src/ui/combat/battle_arena.gd` (mini HP bar) | — |
| UI-P0-04 | ui-system | `src/ui/common/hint_bar.gd` (new) | — |
| ART-P0-05 | art/font | `assets/fonts/zcool_xiaowei.ttf`, `srpg_theme.gd` (TITLE_FONT) | — |
| ART-P0-06 | art/font | `assets/fonts/noto_serif_sc.otf`, `srpg_theme.gd` (BODY_FONT) | — |
| AUDIO-P0-07 | audio | `assets/audio/bgm/main_menu_bgm.ogg` (727KB, CC-BY 3.0) | — |
| AUDIO-P0-08 | audio | `assets/audio/bgm/battle_bgm.ogg` (3.3MB, CC-BY 3.0) | — |

### Lane C — Ch.2 内容基线

| Story ID | System | Files | Tests |
|----------|--------|-------|-------|
| CH2-001 | chapter-02 | `design/gdd/chapter-02.md` (531 lines, 8 sections) | — |
| CH2-002 | narrative | `design/narrative/belief-branching.md` (172 lines) | — |
| CH2-003 | chapter-02 | `src/ui/combat/battle_definitions/chapter_02_{act_a,act_b,finale}.json` | — |
| CH2-004 | chapter-02 | `production/epics/chapter-02/index.md` | — |

---

## Sprint-003: Chapter 2 实战实装
> Status: COMPLETE | 776/776 PASS

| Story ID | System | Files | Tests |
|----------|--------|-------|-------|
| CH2-c-000 | chapter-02 | `production/epics/chapter-02/story-001~006.md` | — |
| CH2-c-001 | belief | `src/core/belief/belief_system.gd`, `belief_gate.gd` | 24 |
| CH2-c-002 | ai | `src/core/ai/wang_xiu_ai.gd` | 19 |
| CH2-c-003 | combat | `src/core/combat/guard_stance.gd` | 9 |
| CH2-c-004 | settlement | `src/core/settlement/suppression_battle_settlement.gd` | 8 |
| CH2-c-005 | combat | `src/core/combat/boss_phase_controller.gd` | 19 |
| CH2-c-006 | settlement | `src/core/settlement/fruit_selection.gd` | 12 |
| BOSS-GDD-001 | boss | `design/gdd/boss-system.md` | — |
| GOV-ADR-007 | governance | `docs/architecture/ADR-007-belief-branch-system.md` (Accepted) | — |

---

## Sprint-004: 管理界面 Beta + 基地系统 MVP
> Status: COMPLETE | 805 test_ methods

| Story ID | System | Files | Tests |
|----------|--------|-------|-------|
| MGMT-001 | character-management | `src/ui/management/character_management.gd`, `character_management_screen.tscn` | integration |
| MGMT-002 | equipment-system | `src/ui/management/equipment_management.gd`, `equipment_management_screen.tscn` | integration |
| MGMT-003 | ui | `src/ui/management/character_tab_bar.gd`, `battle_arena.gd` | integration |
| MGMT-004 | save | `battle_arena.gd` (auto-save on management change) | integration |
| MGMT-005 | ui | `main_menu.gd/tscn`, `battle_arena.gd` (base entrance button) | — |
| BASE-001 | base-system | `src/ui/base/base_hub.gd`, `base_hub.tscn` | integration |
| BASE-002 | base-system | `src/ui/base/training_ground.gd` | integration |
| BASE-003 | base-system | `base_hub.gd` (market buy/sell), `Inventory` → Autoload | integration |

---

## Sprint-005: 本地化 + Credits 合规 + Ch.3 准备
> Status: COMPLETE | 817 test_ methods

| Story ID | System | Files | Tests |
|----------|--------|-------|-------|
| LOC-001 | localization | `src/core/localization/srpg_localization.gd` (catalog expanded, `display_text()`) | unit |
| LOC-002 | localization | `src/ui/menu/main_menu.gd` (LanguageButton, instant refresh) | integration |
| LOC-003 | localization | `src/core/save/save_data.gd`, `save_manager.gd` (locale persistence) | unit |
| REL-001 | ui | `main_menu.gd` (Credits overlay), `design/ux/credits-screen.md` | — |
| REL-002 | qa | `tests/unit/localization/localization_test.gd`, `tests/integration/ui/main_menu_localization_credits_test.gd` | unit+int |
| GOV-001 | governance | `production/epics/index.md`, `sprint-status.yaml` | — |
| CH3-001 | chapter-03 | `design/gdd/chapter-03.md` (skeleton) | — |
| BOND-001 | bond-system | `production/epics/bond-system/EPIC.md` + story skeletons | — |
| TECH-001 | infra | BGM skip in smoke, resource leak triage | — |
| ADR-008 | governance | `docs/architecture/ADR-008-resource-economy-upgrade.md` (Accepted) | — |
| ADR-009 | governance | `docs/architecture/ADR-009-equipment-upgrade-scope.md` (Accepted) | — |
| BASE-FULL-001 | base-system | `docs/active/base-full-readiness-brief.md` | — |
| FOG-001 | fog-of-war | `production/epics/fog-of-war/EPIC.md` + story skeletons | — |

---

## Sprint-006: 养成深度 — Bond MVP + 装备强化 + Base Phase 1
> Status: COMPLETE | packaged smoke: `base_enhanced_level:5`, `bond_growth_present:true`

| Story ID | System | Files | Tests |
|----------|--------|-------|-------|
| BOND-DATA-001 | bond-system | `src/core/bond/bond_registry.gd` (176 lines, pair-keyed) | 4 |
| BOND-EVT-001 | bond-system | `GameEvents.bond_level_up` signal, affinity hooks | integration |
| EQUIP-ENH-001 | equipment-system | `src/ui/management/character_management.gd` (enhance panel), `Inventory.peek_cost` | integration |
| EQUIP-ENH-002 | equipment-system | `src/core/resource/inventory.gd`, `GameEvents.equipment_enhanced` signal | integration |
| BASE-AP-001 | base-system | `src/core/base/action_points.gd` (49 lines, spend/ensure_chapter/serialize) | 3 |
| BOND-UI-001 | bond-system | `character_management.gd` (top-3 affinity + rank) | — |
| EQUIP-ENH-003 | equipment-system | Enhancement round-trip + failure UI (hint_bar) | integration |
| BASE-INTEL-001 | base-system | `base_hub.gd` (Intel Tab, read-only) | integration |
| ECON-CFG-001 | economy | `assets/data/economy/base-upgrade-costs.json` (4 levels) | — |
| CH3-DESIGN-001 | chapter-03 | `design/gdd/chapter-03.md` (expanded to 8-section handoff) | — |

---

## Sprint-007: Ch.3 战斗 1 + Bond 酒馆 + Base 升级 + 装备风险区 + 架构审查
> Status: COMPLETE | 855/855 PASS

| Story ID | System | Files | Tests |
|----------|--------|-------|-------|
| CH3-EPIC-001 | chapter-03 | `production/epics/chapter-03/EPIC.md` + 4 story skeletons | — |
| CH3-c-001 | chapter-03 | `src/ui/combat/battle_definitions/chapter_03_act_a.json` (53 lines), `assets/data/chapters/chapter_03_battle_1.json` | integration |
| BOND-003 | bond-system | `base_hub.gd` (tavern conversation → `BondRegistry.add_affinity()`) | integration |
| BASE-TAVERN-001 | base-system | `base_hub.gd` (TAB_TAVERN, conversation list, AP check) | integration |
| BASE-UPGRADE-001 | base-system | `base_hub.gd` (TAB_UPGRADE, `BaseUpgradeModel` → `base-upgrade-costs.json`) | unit |
| EQUIP-RISK-001 | equipment-system | `character_management.gd` (≥5 enhance entry, C.4 success rate, degrade 5, protect symbol) | — |
| ARCH-REVIEW-007 | governance | `docs/architecture/architecture-review-2026-05-03.md` (PASS); ADR-001 signal list +`equipment_enhanced` | — |
| EQUIP-RISK-002 | equipment-system | `tests/unit/equipment/equipment_risk_test.gd` (6 tests) | 6 |
| GOV-001 | governance | `sprint-status.yaml` 12 entries → complete, `epics/index.md` sync | — |
| TECH-001 | qa | 849/849 PASS, negative tests | — |

---

## Sprint-008: Ch.3 内容完成 + 装备养成收口
> Status: COMPLETE | 879/879 PASS

| Story ID | System | Files | Tests |
|----------|--------|-------|-------|
| CH3-EPIC-002 | chapter-03 | 3 story-*.md Backlog → Complete, epic index refresh | — |
| CH3-c-002 | chapter-03 | `src/ui/combat/battle_definitions/chapter_03_act_b.json` (pressure gauge) | unit+int |
| CH3-c-003 | belief | `src/core/belief/b3_gate_evaluator.gd` (dominant_route/margin/soft_lock/SaveData) | unit+int |
| EQUIP-UI-001 | equipment-system | `character_management.gd` (decompose/reroll panels) | unit+int |
| ARCH-CONCERN-001 | governance | `docs/architecture/architecture.md` (§8 ADR 001~009, BondSystem interface cleanup) | — |
| GOV-001 | governance | `sprint-status.yaml`, `epics/index.md` | — |
| CH3-c-004 | chapter-03 | `src/ui/combat/battle_definitions/chapter_03_finale.json` (Boss 3-phase + B3-GATE variants) | unit+int |
| TECH-001 | qa | 879/879 PASS, negative tests | — |
| BOND-COMBO-DESIGN | bond-system | `design/gdd/bond-system.md` (combo skill section: trigger/effect/rank) | — |
| FOG-GDD | fog-of-war | `design/gdd/fog-of-war-system.md` (Visibility/Reveal/Unit rules) | — |

---

## Sprint-009: Vertical Slice 系统收尾
> Status: COMPLETE | 1037/1037 PASS after post-audit hardening (12/12 stories)

| Story ID | System | Files | Tests |
|----------|--------|-------|-------|
| FOG-001 | fog-of-war | `src/core/fog/fog_state_manager.gd` (~80 lines) | 18 |
| FOG-002 | fog-of-war | `src/core/fog/fog_renderer.gd` (~90 lines), `fusion_builder.gd` (~10 lines) | 6 |
| FOG-003 | fog-of-war | `src/core/fog/fog_target_filter.gd` (~45 lines) | 7 |
| FOG-004 | fog-of-war | Save/load fog state in `battle_state.explored_cells` | 4 |
| BOND-COMBO-001 | bond-system | `src/core/bond/combo_skill_data.gd` (~40 lines), `combo_validator.gd` (~55 lines) | 23 |
| BOND-COMBO-002 | bond-system | Combo skill battle UI + 4-type effect integration | integration |
| DIFF-001 | difficulty | `src/core/difficulty/difficulty_manager.gd` (~95 lines), `assets/data/difficulty/phase_curve.json` | 22 |
| DIFF-002 | difficulty | Combat enemy stat ×multiplier, settlement exp/drop ×multiplier, AI strategy tier | 12 |
| BOSS-001 | boss | `src/core/boss/boss_profile.gd` (~30 lines), `boss_phase.gd` (~10 lines), `boss_checkpoint.gd` (~15 lines) | 16 |
| BOSS-002 | boss | `src/core/boss/boss_action_pattern.gd` (~15 lines, telegraph + range + cooldown) | — |
| EQUIP-014 | equipment-system | Equipment +11+ extreme-risk probability curve + protect symbol consumption | 13 |
| ARCH-REVIEW | governance | Post-Sprint-008 incremental review (ADR-001~009, fog/bond-combo/difficulty/boss TR sync) | — |

---

## Cross-Sprint Summary

| Metric | Sprint-001 | Sprint-002 | Sprint-003 | Sprint-004 | Sprint-005 | Sprint-006 | Sprint-007 | Sprint-008 | Sprint-009 |
|--------|------------|------------|------------|------------|------------|------------|------------|------------|------------|
| Stories | 13 | 18 | 11 | 8 | 14 | 12 | 12 | 10 | 12 |
| Test baseline | 805 | 686 | 776 | 805 | 817 | ~830 | 855 | 879 | 1037 |
| New source files | ~10 | ~12 | 8 | 8 | 8 | 4 | 5 | 4 | 12 |
| godot --check-only | PASS | PASS | PASS | PASS | PASS | PASS | PASS | PASS | PASS |
| Packaged smoke | PASS | PASS | N/A | PASS | PASS | PASS | PASS | PASS | PASS |

**Total across Sprints 001-009 + post-audit hardening**: 110 stories, 1037 tests, ~60+ new source files, 0 parse errors, all smokes PASS.

### System Coverage Map

| System | Sprint Introduced | Full Implementation Sprint |
|--------|------------------|---------------------------|
| attribute / class / resource / tactical / AI | Pre-Sprint-001 | Pre-001 (31 stories) |
| turn-based-mode (speed/auto/save) | Sprint-001 | Sprint-001 |
| battle-settlement (exp/eval/drops/log) | Sprint-001 | Sprint-001 |
| camera-map (2D top-down) | Sprint-001 | Sprint-001 |
| battle HUD / resource HUD | Sprint-001 | Sprint-001 |
| governance (ADR-004~009, control-manifest) | Sprint-002 | Sprint-007 |
| presentation (fonts, BGM, hint_bar) | Sprint-002 | Sprint-002 |
| chapter-02 (GDD, JSON, full implementation) | Sprint-002 (design) | Sprint-003 (code) |
| belief-system (B2-GATE, B3-GATE) | Sprint-003 | Sprint-008 |
| boss-system (phase controller, checkpoint) | Sprint-003 | Sprint-009 |
| guard-stance / suppression settlement | Sprint-003 | Sprint-003 |
| character-management UI | Sprint-004 | Sprint-004 |
| equipment-management UI | Sprint-004 | Sprint-004 |
| base-system (hub, training, market, AP, intel, tavern, upgrade) | Sprint-004 | Sprint-007 |
| localization (catalog, switch, persistence) | Sprint-005 | Sprint-005 |
| credits (screen, compliance) | Sprint-005 | Sprint-005 |
| chapter-03 (GDD, design) | Sprint-005 (skeleton) | Sprint-008 (full) |
| bond-system (data, events, UI, combo) | Sprint-005 (readiness) | Sprint-009 |
| fog-of-war (data, render, filter, save) | Sprint-005 (readiness) | Sprint-009 |
| equipment-enhancement (+1~+5, +6 risk, decompose, reroll, +11+) | Sprint-006 | Sprint-009 |
| action-points | Sprint-006 | Sprint-006 |
| difficulty (curve, integration) | Sprint-009 | Sprint-009 |

### ADR Registry

| ADR | Title | Status | Sprint Accepted |
|-----|-------|--------|-----------------|
| ADR-001 | Event Architecture | Accepted | Pre-Sprint-001 |
| ADR-002 | Scene Management | Accepted | Pre-Sprint-001 |
| ADR-003 | Save System | Accepted | Pre-Sprint-001 |
| ADR-004 | Combat System | Accepted | Sprint-002 |
| ADR-005 | AI Behavior | Accepted | Sprint-002 |
| ADR-006 | Attribute Data Model | Accepted | Sprint-002 |
| ADR-007 | Belief & Branch System | Accepted | Sprint-003 |
| ADR-008 | Resource Economy Upgrade | Accepted | Sprint-005 |
| ADR-009 | Equipment Upgrade Scope | Accepted | Sprint-005 |
