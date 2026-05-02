# Regression Suite — SRPG

> **Generated**: 2026-05-02
> **Baseline**: Post-audit hardening, 1037/1037 PASS
> **Purpose**: 确保 GDD critical path 全量覆盖，固定 bug 有回测

---

## Critical Path Coverage Map

### Foundation Layer

| GDD | Critical Path | Test File | Tests | Status |
|-----|--------------|-----------|-------|--------|
| attribute-growth-system | 属性初始化 + 成长公式 | `tests/unit/attributes/data_model_init_test.gd` | ≥5 | ✅ |
| attribute-growth-system | 成长公式正确性 | `tests/unit/attributes/growth_formula_test.gd` | ≥5 | ✅ |
| attribute-growth-system | 果子系统 | `tests/unit/attributes/fruit_system_test.gd` | ≥5 | ✅ |
| attribute-growth-system | 突破/碾压机制 | `tests/unit/attributes/barrier_breakthrough_test.gd` | ≥5 | ✅ |
| | | `tests/unit/attributes/crush_mechanic_test.gd` | ≥5 | ✅ |
| attribute-growth-system | 阈值奖励 | `tests/unit/attributes/threshold_rewards_test.gd` | ≥5 | ✅ |
| class-system | 职业解锁判定 | `tests/unit/class/unlock_judgment_test.gd` | ≥5 | ✅ |
| class-system | 职业属性加成 | `tests/unit/class/stat_bonuses_test.gd` | ≥5 | ✅ |
| class-system | 转职 | `tests/unit/class/class_change_test.gd` | ≥5 | ✅ |
| class-system | 经验/等级 | `tests/unit/class/experience_level_test.gd` | ≥5 | ✅ |
| class-system | 状态机 | `tests/unit/class/state_machine_test.gd` | ≥5 | ✅ |
| resource-economy | 金币/材料获取 | `tests/unit/resource/gold_material_acquisition_test.gd` | ≥5 | ✅ |
| resource-economy | 稀有掉落 | `tests/unit/resource/rare_drops_test.gd` | ≥5 | ✅ |
| resource-economy | 强化系统 | `tests/unit/resource/enhancement_system_test.gd` | ≥5 | ✅ |
| resource-economy | 消耗成本 | `tests/unit/resource/consumption_costs_test.gd` | ≥5 | ✅ |
| resource-economy | 数据模型/库存 | `tests/unit/resource/data_model_inventory_test.gd` | ≥5 | ✅ |
| localization | 多语言切换/持久化 | `tests/unit/localization/localization_test.gd` | ≥5 | ✅ |

### Core Layer

| GDD | Critical Path | Test File | Tests | Status |
|-----|--------------|-----------|-------|--------|
| tactical-mechanism | 地形数据模型 | `tests/unit/tactical/terrain_data_model_test.gd` | ≥5 | ✅ |
| tactical-mechanism | 武器三角 | `tests/unit/tactical/weapon_triangle_test.gd` | ≥5 | ✅ |
| tactical-mechanism | 高度优势 | `tests/unit/tactical/height_advantage_test.gd` | ≥5 | ✅ |
| tactical-mechanism | 元素交互 | `tests/unit/tactical/elemental_interactions_test.gd` | ≥5 | ✅ |
| ai-system | 威胁评估 | `tests/unit/ai/threat_system_test.gd` | ≥5 | ✅ |
| ai-system | AI 类型权重 | `tests/unit/ai/ai_type_weights_test.gd` | ≥5 | ✅ |
| ai-system | 目标/技能选择 | `tests/unit/ai/target_skill_selection_test.gd` | ≥5 | ✅ |
| ai-system | 位置评分 | `tests/unit/ai/position_scoring_test.gd` | ≥5 | ✅ |
| ai-system | Boss AI | `tests/unit/ai/boss_ai_test.gd` | ≥5 | ✅ |
| skill-system | 技能数据模型 | `tests/unit/skill/skill_data_model_test.gd` | ≥5 | ✅ |
| skill-system | 熟练度成长 | `tests/unit/skill/proficiency_leveling_test.gd` | ≥5 | ✅ |
| skill-system | 阶位系统 | `tests/unit/skill/rank_system_test.gd` | ≥5 | ✅ |
| skill-system | 技能伤害 | `tests/unit/skill/skill_damage_test.gd` | ≥5 | ✅ |
| skill-system | 特性选择 | `tests/unit/skill/trait_selection_test.gd` | ≥5 | ✅ |
| skill-system | 职业技能 | `tests/unit/skill/class_skills_test.gd` | ≥5 | ✅ |
| turn-based-mode | 回合顺序 | `tests/unit/turn/turn_order_test.gd` | ≥5 | ✅ |
| turn-based-mode | 行动系统 | `tests/unit/turn/action_system_test.gd` | ≥5 | ✅ |
| turn-based-mode | 移动系统 | `tests/unit/turn/movement_system_test.gd` | ≥5 | ✅ |
| turn-based-mode | 战斗流程 | `tests/unit/turn/combat_flow_test.gd` | ≥5 | ✅ |
| turn-based-mode | 自动战斗 | `tests/unit/turn/auto_battle_test.gd` | ≥5 | ✅ |
| turn-based-mode | 加速模式 | `tests/unit/turn/speed_up_mode_test.gd` | ≥5 | ✅ |

### Feature Layer

| GDD | Critical Path | Test File | Tests | Status |
|-----|--------------|-----------|-------|--------|
| equipment-system | 装备数据模型 | `tests/unit/equipment/equipment_data_model_test.gd` | ≥5 | ✅ |
| equipment-system | 词缀生成 | `tests/unit/equipment/affix_generation_test.gd` | ≥5 | ✅ |
| equipment-system | 套装加成 | `tests/unit/equipment/set_bonus_test.gd` | ≥5 | ✅ |
| equipment-system | 最终属性 | `tests/unit/equipment/final_attribute_test.gd` | ≥5 | ✅ |
| equipment-system | 强化 | `tests/unit/equipment/enhancement_test.gd` | ≥5 | ✅ |
| equipment-system | 分解 | `tests/unit/equipment/decomposition_test.gd` | ≥5 | ✅ |
| equipment-system | 风险区 | `tests/unit/equipment/equipment_risk_test.gd` | ≥5 | ✅ |
| equipment-system | 分解/重随 | `tests/unit/equipment/decomp_reroll_test.gd` | ≥5 | ✅ |
| equipment-system | 极风险区 | `tests/unit/equipment/extreme_risk_test.gd` | ≥13 | ✅ |
| character-management | 队伍编成 | `tests/unit/character/party_composition_test.gd` | ≥5 | ✅ |
| character-management | 离队/召回 | `tests/unit/character/departure_recall_test.gd` | ≥5 | ✅ |
| battle-settlement | 结算触发 | `tests/unit/settlement/settlement_trigger_test.gd` | ≥5 | ✅ |
| battle-settlement | 经验分配 | `tests/unit/settlement/experience_distribution_test.gd` | ≥5 | ✅ |
| battle-settlement | 战斗评价 | `tests/unit/settlement/battle_evaluation_test.gd` | ≥5 | ✅ |
| battle-settlement | 掉落计算 | `tests/unit/settlement/drop_calculator_test.gd` | ≥5 | ✅ |
| bond-system | 羁绊数据模型 | `tests/unit/bond/bond_data_model_test.gd` | ≥5 | ✅ |
| bond-system | 联携校验 | `tests/unit/bond/combo_validator_test.gd` | ≥23 | ✅ |
| base-system | 行动点 | `tests/unit/base/action_points_test.gd` | ≥5 | ✅ |
| base-system | 基地升级模型 | `tests/unit/base/base_upgrade_model_test.gd` | ≥5 | ✅ |

### Vertical Slice Layer

| GDD | Critical Path | Test File | Tests | Status |
|-----|--------------|-----------|-------|--------|
| fog-of-war | 可见性数据模型 | `tests/unit/fog/visibility_model_test.gd` | ≥18 | ✅ |
| fog-of-war | 渲染覆盖层 | `tests/unit/fog/rendering_overlay_test.gd` | ≥6 | ✅ |
| fog-of-war | 目标过滤 | `tests/unit/fog/target_filter_test.gd` | ≥7 | ✅ |
| fog-of-war | 战斗集成 | `tests/unit/fog/battle_integration_test.gd` | ≥5 | ✅ |
| difficulty-system | 难度数据模型 | `tests/unit/difficulty/data_model_test.gd` | ≥22 | ✅ |
| difficulty-system | 集成 mock | `tests/unit/difficulty/integration_mock_test.gd` | ≥12 | ✅ |
| difficulty-system | 难度桥接 | `tests/unit/difficulty/difficulty_bridge_test.gd` | ≥5 | ✅ |
| boss-system | Boss 数据模型 | `tests/unit/boss/boss_profile_test.gd` | ≥16 | ✅ |
| boss-system | Action Pattern | `tests/unit/boss/action_pattern_test.gd` | ≥20 | ✅ |
| boss-system | Action Pattern 独立 | `tests/unit/boss/boss_action_pattern_test.gd` | ≥24 | ✅ (Sprint-010) |

### Content Layer

| GDD | Critical Path | Test File | Tests | Status |
|-----|--------------|-----------|-------|--------|
| chapter-02 | 信念值系统 | `tests/unit/chapter02/belief_system_test.gd` | ≥5 | ✅ |
| chapter-02 | 分支门禁 | `tests/unit/chapter02/branch_gate_test.gd` | ≥5 | ✅ |
| chapter-02 | 护卫姿态 | `tests/unit/chapter02/guard_stance_test.gd` | ≥5 | ✅ |
| chapter-02 | 果子选择 | `tests/unit/chapter02/fruit_selection_test.gd` | ≥5 | ✅ |
| chapter-02 | 镇压结算 | `tests/unit/chapter02/suppression_settlement_test.gd` | ≥5 | ✅ |
| chapter-02 | 王秀 AI | `tests/unit/chapter02/wang_xiu_ai_test.gd` | ≥5 | ✅ |
| chapter-02 | Boss 阶段 | `tests/unit/chapter02/boss_phase_test.gd` | ≥5 | ✅ |
| chapter-03 | B3-GATE | `tests/unit/chapter03/b3_gate_evaluator_test.gd` | ≥5 | ✅ |
| chapter-03 | 战斗 2 压力 | `tests/unit/chapter03/battle_2_pressure_test.gd` | ≥5 | ✅ |
| chapter-03 | Finale 路线 | `tests/unit/chapter03/finale_route_variant_test.gd` | ≥5 | ✅ |

### HP System (Implicit)

| GDD | Critical Path | Test File | Tests | Status |
|-----|--------------|-----------|-------|--------|
| hp-system | HP 公式 | `tests/unit/hp/hp_formula_test.gd` | ≥5 | ✅ |

---

## Integration Points (Cross-System)

| Integration | Test File | Tests | Status |
|------------|-----------|-------|--------|
| Save/Load — attributes | `tests/integration/attributes/save_load_integration_test.gd` | ≥5 | ✅ |
| Save/Load — class | `tests/integration/class/save_load_integration_test.gd` | ≥5 | ✅ |
| Save/Load — character | `tests/integration/character/save_load_integration_test.gd` | ≥5 | ✅ |
| Save/Load — equipment | `tests/integration/equipment/save_load_integration_test.gd` | ≥5 | ✅ |
| Save/Load — skill | `tests/integration/skill/save_load_integration_test.gd` | ≥5 | ✅ |
| Save/Load — settlement | `tests/integration/settlement/save_load_integration_test.gd` | ≥5 | ✅ |
| Save/Load — fog | `tests/integration/fog/fog_save_load_test.gd` | ≥4 | ✅ |
| Save/Load — turn | `tests/integration/turn/save_load_integration_test.gd` | ≥5 | ✅ |
| Save/Load — battle | `tests/integration/save/battle_save_manager_integration_test.gd` | ≥5 | ✅ |
| Camera + Map | `tests/integration/camera/battle_camera_map_test.gd` | ≥5 | ✅ |
| Tactical Integration | `tests/integration/tactical/tactical_integration_test.gd` | ≥5 | ✅ |
| AI Integration | `tests/integration/ai/ai_integration_test.gd` | ≥5 | ✅ |
| Bond Events | `tests/integration/bond/affinity_event_hooks_test.gd` | ≥5 | ✅ |
| B3-GATE Persistence | `tests/integration/chapter03/b3_gate_persistence_test.gd` | ≥5 | ✅ |
| Ch.3 Finale Boot | `tests/integration/chapter03/finale_boot_test.gd` | ≥5 | ✅ |
| Battle HUD | `tests/integration/ui/battle_hud_test.gd` | ≥5 | ✅ |
| Base Hub | `tests/integration/ui/base_hub_test.gd` | ≥5 | ✅ |
| Character Mgmt | `tests/integration/ui/character_management_test.gd` | ≥5 | ✅ |
| Menu/Credits | `tests/integration/ui/main_menu_localization_credits_test.gd` | ≥5 | ✅ |
| Save/Load UI | `tests/integration/ui/save_load_integration_test.gd` | ≥5 | ✅ |
| Decomp UI | `tests/integration/equipment/decomp_reroll_ui_test.gd` | ≥5 | ✅ |
| Battle Arena Entry | `tests/integration/prototypes/battle_arena_entry_test.gd` | ≥5 | ✅ |
| Ch.3 Battle 2 Entry | `tests/integration/prototypes/chapter_03_battle_2_entry_test.gd` | ≥5 | ✅ |
| VS Battle | `tests/integration/prototypes/vs_battle_test.gd` | ≥5 | ✅ |

---

## Coverage Summary

| Layer | Unit Tests | Integration Tests | Total Files | Coverage |
|-------|-----------|-------------------|-------------|----------|
| Foundation | 40+ | 8 | 7 | 100% |
| Core | 40+ | 10 | 12 | 100% |
| Feature | 60+ | 8 | 11 | 100% |
| Vertical Slice | 90+ | 1 | 9 | 100% |
| Content | 35+ | 4 | 8 | 100% |
| **Total** | **265+** | **31** | **47** | **100% of GDD critical paths** |

## Uncovered GDD Sections

| GDD | Missing Coverage | Priority | Sprint |
|-----|-----------------|----------|--------|
| event-system | 无 epic，无测试 | LOW | Alpha |
| new-game-plus-system | 无 epic，无测试 | LOW | Alpha |
| chapter-04 | 无 epic，无测试 | LOW | Alpha |

## Bug Regression Register

> Bug fixes since Sprint-001. Every fixed bug must have a regression test.

| Bug ID | Sprint | Description | Regression Test | Status |
|--------|--------|-------------|----------------|--------|
| BUG-001 | Post-Sprint-009 | `DifficultyManager` script class hid the autoload singleton and emitted packaged smoke startup errors | `tools/package_windows_release.ps1` strict smoke + `tests/unit/difficulty/data_model_test.gd` | ✅ RESOLVED |

每个修复后的 bug 都必须在此表登记，并保留可自动执行的回归证据。
