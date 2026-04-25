# Architecture Review Report — Sprint-002 Governance Baseline

> Date: 2026-04-26
> Reviewer: architect (read-only)
> Engine: Godot 4.6.2
> GDDs Reviewed: 23 systems (systems-index.md)
> ADRs Reviewed: 6 (ADR-001 ~ ADR-006)
> Epics Reviewed: 12 (production/epics/index.md)
> Mode: Production — traceability baseline for Sprint-002

---

## 1. Traceability Matrix

### 1.1 全量系统追溯表

| # | 系统名 | 分类 | 优先级 | GDD | Epic | ADR | 实现 (src/) | 单元测试 | 集成测试 |
|---|--------|------|--------|-----|------|-----|-------------|----------|----------|
| 1 | 美术风格 | Foundation | Foundation | art-style.md | [GAP] 无epic | [GAP] | [GAP] 无代码 | [GAP] | [GAP] |
| 2 | 存档系统 | Foundation | Foundation | save-system.md | [GAP] 无epic | ADR-003 (Accepted) | save_manager.gd, save_data.gd, auto_save_trigger.gd | [GAP] 无独立单测 | save/battle_save_manager_integration_test.gd |
| 3 | 世界观/叙事 | Narrative | Foundation | worldbuilding-narrative.md | [GAP] 无epic | [GAP] | [GAP] 无代码 | [GAP] | [GAP] |
| 4 | 属性与成长 | Core | MVP | attribute-growth-system.md | attribute-system (Complete, 7 stories) | ADR-006 (Proposed) | attribute_data.gd, attribute_component.gd, unit_attributes.gd, attribute_names.gd | 6 test files (data_model, growth, fruit, barrier, crush, threshold) | attributes/save_load_integration_test.gd |
| 5 | 职业系统 | Core | MVP | class-system.md | class-system (Complete, 6 stories) | [GAP] | class_component.gd, class_names.gd | 4 test files (unlock, stat_bonuses, class_change, experience_level, state_machine) | class/save_load_integration_test.gd |
| 6 | AI系统 | Core | MVP | ai-system.md | ai-system (Complete, 6 stories) | ADR-005 (Proposed) | ai_brain.gd, ai_types.gd, threat_system.gd | 5 test files (threat, weights, target_skill, position, boss_ai) | ai/ai_integration_test.gd |
| 7 | 资源经济 | Core | MVP | resource-economy.md | resource-economy (Complete, 6 stories) | [GAP] | inventory.gd, resource_types.gd, resource_formulas.gd | 4 test files (data_model, gold_material, rare_drops, enhancement, consumption) | resource/save_load_integration_test.gd |
| 8 | 战术机制 | Core | MVP | tactical-mechanism.md | tactical-mechanism (Complete, 5 stories) | [GAP] (ADR-004 部分覆盖) | tactical_formulas.gd, terrain_types.gd | 4 test files (terrain, weapon_triangle, height, elemental) | tactical/tactical_integration_test.gd |
| 9 | 技能系统 | Core | MVP | skill-system.md | skill-system (Complete, 7 stories) | [GAP] | skill_component.gd, skill_data.gd, skill_definitions.gd | 6 test files (data_model, proficiency, rank, trait, damage, class_skills) | skill/save_load_integration_test.gd |
| 10 | 装备系统 | Feature | MVP | equipment-system.md | equipment-system (Complete, 7 stories) | [GAP] | equipment_component.gd, equipment_item.gd, equipment_definitions.gd, equipment_affix_generator.gd | 6 test files (data_model, affix, enhancement, set_bonus, decomposition, final_attribute) | equipment/save_load_integration_test.gd |
| 11 | 回合制模式 | Core | MVP | turn-based-mode.md | turn-based-mode (Complete, 7 stories) | ADR-004 (Proposed, 部分覆盖) | combat_system.gd, action_system.gd, movement_system.gd, speed_controller.gd, auto_battle_controller.gd | 6 test files (turn_order, action, movement, combat_flow, auto_battle, speed_up) | turn/save_load_integration_test.gd + test_turn_order_integration.gd |
| 12 | 羁绊系统 | Feature | VS | bond-system.md | [GAP] 无epic | [GAP] | [GAP] 无代码 | [GAP] | [GAP] |
| 13 | 角色管理 | Feature | MVP | character-management.md | character-management (Complete, 3 stories) | [GAP] | character_roster.gd | 2 test files (party_composition, departure_recall) | character/save_load_integration_test.gd |
| 14 | 战斗结算 | Feature | MVP | battle-settlement.md | battle-settlement (Complete, 5 stories) | [GAP] (ADR-004 间接) | settlement_trigger.gd, experience_distribution.gd, battle_evaluation.gd, drop_calculator.gd, settlement_result.gd, battle_history_log.gd | 4 test files (trigger, experience, evaluation, drop) | settlement/save_load_integration_test.gd |
| 15 | 难度系统 | Meta | VS | difficulty-system.md | [GAP] 无epic | [GAP] | [GAP] (battle_difficulty_profile.gd 在 ui/combat/) | [GAP] | [GAP] |
| 16 | Boss战 | Feature | VS | boss-system.md | [GAP] 无epic | [GAP] (ADR-005 间接) | [GAP] (boss_ai_test.gd 存在但无独立实现文件) | boss_ai_test.gd (在 ai 目录) | [GAP] |
| 17 | 战争迷雾 | Feature | VS | fog-of-war-system.md | [GAP] 无epic | [GAP] | [GAP] 无代码 | [GAP] | [GAP] |
| 18 | 视角与地图 | Presentation | MVP | camera-map-system.md | camera-map-system (Complete, 3 stories) | ADR-002 (Accepted, 部分覆盖) | scene_manager.gd (场景管理) | [GAP] (无独立 camera 单测) | camera/battle_camera_map_test.gd + camera/save_load_integration_test.gd |
| 19 | 基地系统 | Feature | Alpha | base-system.md | [GAP] 无epic | [GAP] | [GAP] 无代码 | [GAP] | [GAP] |
| 20 | UI系统 | Presentation | MVP | ui-system.md | ui-system (Complete, 3 stories) | [GAP] | main_menu.gd, battle_arena.gd, srpg_theme.gd, ink_backdrop.gd | [GAP] (无独立 UI 单测) | ui/battle_hud_test.gd + ui/save_load_integration_test.gd |
| 21 | 多周目系统 | Meta | Alpha | new-game-plus-system.md | [GAP] 无epic | [GAP] | [GAP] 无代码 | [GAP] | [GAP] |
| 22 | 事件系统 | Narrative | Alpha | event-system.md | [GAP] 无epic | [GAP] | [GAP] (game_events.gd 是信号总线，非叙事事件) | [GAP] | [GAP] |
| 23 | 音效/音乐 | Presentation | Alpha | audio-system.md | [GAP] 无epic | [GAP] | srpg_audio_bus.gd (仅音频总线骨架) | [GAP] | [GAP] |

### 1.2 统计汇总

| 维度 | 有 | 缺 | 覆盖率 |
|------|----|----|--------|
| GDD (Designed) | 23/23 | 0 | 100% |
| Epic (Created) | 12/23 | 11 | 52% |
| Epic (Complete) | 12/12 | 0 | 100% (已创建的全部完成) |
| ADR (any status) | 6/23 | 17 | 26% |
| ADR (Accepted) | 3/6 | — | 50% of existing ADRs |
| src/ 实现 | 14/23 | 9 | 61% |
| 单元测试 | 12/23 | 11 | 52% |
| 集成测试 | 12/23 | 11 | 52% |

---

## 2. ADR 缺口分析

### 2.1 现有 ADR 状态

| ADR | 系统 | 层级 | 状态 | 覆盖 GDD |
|-----|------|------|------|----------|
| ADR-001 | 事件架构 | Foundation | **Accepted** | 全局（所有系统解耦通信） |
| ADR-002 | 场景管理 | Foundation | **Accepted** | camera-map-system, ui-system |
| ADR-003 | 存档系统 | Foundation | **Accepted** | save-system, 全局持久化 |
| ADR-004 | 战斗系统 | Core/Feature | **Proposed** | turn-based-mode, tactical-mechanism, battle-settlement |
| ADR-005 | AI行为 | Core | **Proposed** | ai-system, boss-system |
| ADR-006 | 属性数据模型 | Core | **Proposed** | attribute-growth-system |

### 2.2 按架构层级的 ADR 缺口

#### Foundation 层 — 完整 (3/3 Accepted)

无缺口。ADR-001/002/003 全部 Accepted。

#### Core 层 — 严重缺口 (3/7 有 ADR，其中 0 Accepted)

| 缺口系统 | 缺失 ADR | 严重性 | 建议优先级 |
|----------|----------|--------|-----------|
| 职业系统 | [GAP] 无 ADR | HIGH — 12 个 epic 已 Complete 但职业架构未文档化 | P1 |
| 资源经济 | [GAP] 无 ADR | HIGH — 双层资源模型是多个下游系统的基础 | P1 |
| 技能系统 | [GAP] 无 ADR | MEDIUM — 技能熟练度/阶位/特质三层架构需记录 | P2 |
| 战术机制 | [GAP] 独立 ADR 缺失 | MEDIUM — ADR-004 部分覆盖但克制/元素/高低差作为子系统缺少独立决策记录 | P2 |
| 属性与成长 | ADR-006 Proposed | LOW — 已有 ADR 草案，需提升至 Accepted | P1 |
| AI系统 | ADR-005 Proposed | LOW — 已有 ADR 草案，需提升至 Accepted | P1 |
| 回合制模式 | ADR-004 Proposed | LOW — 已有 ADR 草案，需提升至 Accepted | P1 |

**关键风险**: ADR-004/005/006 均为 Proposed 状态。按 docs/CLAUDE.md 规则，"stories referencing a Proposed ADR are auto-blocked"。12 个 epic 的 story 已全部 Complete，说明 ADR 状态检查在实现阶段被绕过。建议立即将 ADR-004/005/006 提升为 Accepted 以消除合规风险。

#### Feature 层 — 大面积缺口 (0/7 有 ADR)

| 缺口系统 | 需要独立 ADR? | 理由 |
|----------|--------------|------|
| 装备系统 | **YES** | 词缀生成、强化风险区、分解、套装——架构复杂度高 |
| 角色管理 | NO | 逻辑简单（花名册+编队），可在 control manifest 中以规则覆盖 |
| 战斗结算 | NO | 管线逻辑，可作为 ADR-004 的扩展章节 |
| 羁绊系统 | **YES** | 未实现，需在 VS/Alpha 前有架构方案 |
| Boss战 | NO | ADR-005 已部分覆盖，可作为扩展章节 |
| 难度系统 | NO | 逻辑为系数倍率，可在 control manifest 中以规则覆盖 |
| 战争迷雾 | **YES** | 与 AI 系统和战术机制深度交互，需独立架构决策 |

#### Presentation 层 — 严重缺口 (0/3 有独立 ADR)

| 缺口系统 | 需要独立 ADR? | 理由 |
|----------|--------------|------|
| UI系统 | **YES** | HD-2D 中国风主题系统、键盘导航架构、多面板管理——ADR-002 仅覆盖场景层分离 |
| 视角与地图 | NO | ADR-002 部分覆盖，补充 camera 专用规则到 control manifest 即可 |
| 音效/音乐 | NO | Alpha 阶段，当前仅有音频总线骨架 |

#### Meta 层 — 全部缺口 (0/2)

| 缺口系统 | 需要独立 ADR? | 理由 |
|----------|--------------|------|
| 难度系统 | NO | 系数倍率逻辑，control manifest 规则即可 |
| 多周目系统 | **YES** | 跨周目数据迁移、成就点数兑换机制需架构决策 |

#### Narrative 层 — 全部缺口 (0/2)

| 缺口系统 | 需要独立 ADR? | 理由 |
|----------|--------------|------|
| 世界观/叙事 | NO | 内容型系统，非技术架构 |
| 事件系统 | **YES** | 叙事触发器与游戏状态交互、条件评估引擎需架构方案 |

### 2.3 ADR 缺口优先级排序

| 优先级 | 动作 | 系统 | 建议 ADR 编号 |
|--------|------|------|--------------|
| **P0** | 提升状态 Proposed→Accepted | ADR-004 战斗系统 | — |
| **P0** | 提升状态 Proposed→Accepted | ADR-005 AI行为 | — |
| **P0** | 提升状态 Proposed→Accepted | ADR-006 属性数据模型 | — |
| **P1** | 新建 ADR | 职业系统 | ADR-007 |
| **P1** | 新建 ADR | 资源经济 | ADR-008 |
| **P1** | 新建 ADR | 装备系统 | ADR-009 |
| **P2** | 新建 ADR | UI系统 | ADR-010 |
| **P2** | 新建 ADR | 技能系统 | ADR-011 |
| **P3** | 新建 ADR (Alpha 前) | 羁绊系统 | ADR-012 |
| **P3** | 新建 ADR (Alpha 前) | 战争迷雾 | ADR-013 |
| **P3** | 新建 ADR (Alpha 前) | 事件系统 | ADR-014 |
| **P3** | 新建 ADR (Alpha 前) | 多周目系统 | ADR-015 |

---

## 3. Control Manifest 评估

### 3.1 现状

`docs/architecture/control-manifest.md` 已存在，覆盖 Foundation 层 3 个 ADR（ADR-001/002/003），版本 `2026-04-23-v1`。包含：
- Event Architecture: 5 Required + 3 Forbidden + 3 Guardrails
- Scene Management: 5 Required + 3 Forbidden + 3 Guardrails
- Save System: 6 Required + 3 Forbidden + 4 Guardrails
- Cross-Layer Rules: 3 条

**缺口**: ADR-004/005/006 的规则完全未纳入 manifest。所有 12 个 Complete epic 的 story 实现时 manifest 未包含 Gameplay 层规则。

### 3.2 建议更新

Control Manifest 必须在 ADR-004/005/006 提升为 Accepted 后立即更新至 v2，新增以下节：

| 新增节 | 来源 ADR | 预计规则数 |
|--------|----------|-----------|
| Combat System | ADR-004 | ~8 Required + ~4 Forbidden + ~3 Guardrails |
| AI Behavior | ADR-005 | ~5 Required + ~2 Forbidden + ~3 Guardrails |
| Attribute Data Model | ADR-006 | ~6 Required + ~2 Forbidden + ~2 Guardrails |

关键新增规则（从 ADR 内容提取）：

- **CB-R01**: 伤害计算必须在单帧内完成，禁止异步 (ADR-004)
- **CB-F01**: 战斗中禁止存档 (ADR-004)
- **AI-R01**: AI 配置必须数据驱动（JSON/Resource），禁止硬编码行为权重 (ADR-005)
- **AI-G01**: 单单位 AI 决策 < 5ms (ADR-005)
- **AT-R01**: 属性值范围 [0, 999]，潜质枚举 [E=1, D=2, C=3, B=4, A=5, S=6] (ADR-006)
- **AT-F01**: 下游系统禁止直接修改属性值，必须通过属性系统接口 (ADR-006)

---

## 4. TR-Registry 回填提案

### 4.1 命名规则

```
TR-[system-slug]-[NNN]

system-slug 对照表:
  attr     → 属性与成长系统
  class    → 职业系统
  resource → 资源经济
  tactical → 战术机制
  ai       → AI系统
  skill    → 技能系统
  equip    → 装备系统
  turn     → 回合制模式
  settle   → 战斗结算
  char     → 角色管理
  camera   → 视角与地图
  ui       → UI系统
  bond     → 羁绊系统
  fog      → 战争迷雾
  boss     → Boss战
  diff     → 难度系统
  base     → 基地系统
  ngp      → 多周目系统
  event    → 事件系统
  audio    → 音效/音乐
  save     → 存档系统
  art      → 美术风格
  lore     → 世界观/叙事
```

NNN = 三位零填充序列号，每系统从 001 起步。

### 4.2 12 个已 Complete Epic 的 TR-ID 提案

完整 YAML 内容见 `production/registries/tr-registry.yaml`。

---

## 5. 跨 ADR 冲突检查

| 检查项 | 结果 |
|--------|------|
| ADR-001 vs ADR-004 | 无冲突 — ADR-004 的战斗信号定义与 ADR-001 的 GameEvents 规范一致 |
| ADR-001 vs ADR-005 | 无冲突 — AI 决策输出通过 GameEvents 传递 |
| ADR-001 vs ADR-006 | 无冲突 — 属性变更通过 attribute_changed 信号通知 |
| ADR-003 vs ADR-006 | 无冲突 — 属性数据通过 UnitSaveData 持久化 |
| ADR-004 vs ADR-005 | **注意**: ADR-004 定义 CombatStateMachine 的 ENEMY_TURN 状态调用 AI，但 ADR-005 的 AIDecisionEngine 作为独立 Node 架构。需确认耦合方式是信号还是直接调用。 |
| ADR-005 BossPhaseController vs boss-system.md | 无冲突 — 阈值一致 (70%/50%) |

---

## 6. 引擎兼容性审计

| ADR | Engine Compatibility Section | Post-Cutoff API | 风险 |
|-----|------------------------------|-----------------|------|
| ADR-001 | YES | None | LOW |
| ADR-002 | YES | None | LOW |
| ADR-003 | YES | None | LOW |
| ADR-004 | YES | None | MEDIUM (状态机+信号链需验证) |
| ADR-005 | YES | None | HIGH (AI 复杂度) |
| ADR-006 | YES | None | LOW |

**未解决的引擎风险**（沿袭 2026-04-20 review）:
- Jolt 物理引擎（4.6 默认）：未在任何 ADR 中确认兼容性
- D3D12 渲染（4.6 Windows 默认）：未确认
- 建议：在 ADR-002 扩展章节或新建 ADR 记录物理/渲染引擎选择

---

## 7. 优先级建议（Sprint-002 治理 lane）

### 立即执行（本 Sprint）

1. **提升 ADR-004/005/006 为 Accepted** — 3 个 Proposed ADR 需经技术总监确认后接受，消除 story 引用合规风险
2. **更新 Control Manifest v2** — 从 ADR-004/005/006 提取 Gameplay 层规则
3. **写入 tr-registry.yaml** — 覆盖 12 个 Complete epic 的全部 TR-ID（见 production/registries/tr-registry.yaml）
4. **回填 Epic 中的 TR-ID 引用** — 每个 EPIC.md 的 "GDD Requirements" 表补上 TR-ID

### 下一 Sprint

5. **新建 P1 ADR** — 职业系统 (ADR-007)、资源经济 (ADR-008)、装备系统 (ADR-009)
6. **新建 P2 ADR** — UI 系统 (ADR-010)、技能系统 (ADR-011)

### Alpha 前

7. **新建 P3 ADR** — 羁绊、战争迷雾、事件系统、多周目
8. **为 11 个无 epic 系统创建 epic** — bond, fog-of-war, boss, difficulty, base, new-game-plus, event, audio, art-style, worldbuilding-narrative, save-system(独立)

---

## 8. 路径治理决策

项目中存在两个 tr-registry 路径：
- `docs/architecture/tr-registry.yaml`（已有空文件）
- `production/registries/tr-registry.yaml`（本轮规范路径）

**建议**：将 `production/registries/` 作为规范路径；`docs/architecture/tr-registry.yaml` 在下一轮提升 ADR 时标记 deprecated 或留 README 重定向，避免双源。
