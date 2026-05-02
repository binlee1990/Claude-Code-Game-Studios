# Architecture Review — Post-Sprint-009 Sync

> **Date**: 2026-05-02
> **Previous**: 2026-05-03 (Sprint-008 closure)
> **Scope**: ADR-010~013 implementation verification + traceability update
> **Trigger**: Sprint-009 COMPLETE (VS 4 systems implemented)

---

## Verdict: PASS

All 4 Vertical Slice ADRs correctly implemented. No cross-ADR conflicts found. 3 minor findings (non-blocking).

---

## ADR Implementation Verification

### ADR-010: Fog-of-War

| Check | Status | Evidence |
|-------|--------|----------|
| Three-state visibility model (hidden/fog/visible) | ✅ | `fog_state_manager.gd` |
| Visibility formula: `vision_range = BASE + agi_bonus + class_bonus + height_bonus` | ✅ | `visibility_model_test.gd` 18 tests |
| Fog rendering overlay with 3 color states | ✅ | `fog_renderer.gd` |
| Unit visibility integration (hidden enemies + target filter) | ✅ | `fog_target_filter.gd` 7 tests |
| Save/load fog state | ✅ | `fog_save_load_test.gd` 4 tests |
| Opt-in toggle per battle | ✅ | `fusion_builder.gd` |

**Finding F-1 (INFO)**: FogRenderer 当前 MVP 不做 LOS 裁剪，大网格（25×25）可能有性能压力。ADR-010 §Performance 要求后续迭代中实现 frustum culling。非阻塞。

### ADR-011: Bond Combo Skill

| Check | Status | Evidence |
|-------|--------|----------|
| Manhattan distance ≤3 trigger condition | ✅ | `combo_validator.gd` |
| AP cost + cooldown per combo | ✅ | `combo_skill_data.gd` |
| 4 bond-type effects (trust/rivalry/mentor/blood) | ✅ | `combo_skill_data.gd` |
| Player-only trigger MVP (no enemy combo) | ✅ | `combo_validator.gd` |
| Combo battle UI button + disabled state + tooltip | ✅ | Story BOND-COMBO-002 |

**Finding F-2 (INFO)**: Combo battle UI 集成测试为 manual UI test，无自动化 UI interaction 测试。ADR-011 §Verification 建议后续添加 `tests/integration/ui/combo_battle_ui_test.gd`。非阻塞。

### ADR-012: Difficulty System

| Check | Status | Evidence |
|-------|--------|----------|
| 4-phase fixed curve (0.7/0.85/1.0/1.2×) | ✅ | `phase_curve.json` |
| Enemy stat scaling via multiplier | ✅ | `difficulty_manager.gd` |
| EXP/drop multiplier integration | ✅ | `integration_mock_test.gd` 12 tests |
| Settlement integration | ✅ | `difficulty_bridge_test.gd` |
| AI strategy tier switching | ✅ | `difficulty_manager.gd` (AI tier table) |

**Finding F-3 (ADVISORY)**: DifficultyManager 当前通过 mock 测试验证，但无端到端 battle-with-difficulty 集成测试。ADR-012 §Integration 描述 settlement/combat/AI 三系统集成，但 packaged smoke 验证的是 single-battle 而非 difficulty-scaled 全流程。建议 Sprint-011 regression 添加 `tests/integration/difficulty/difficulty_e2e_test.gd`。非阻塞。

### ADR-013: Boss System

| Check | Status | Evidence |
|-------|--------|----------|
| 5 boss types (tutorial/narrative/aptitude/peak/hidden) | ✅ | `boss_profile.gd` |
| Phase-based HP thresholds | ✅ | `boss_phase.gd` |
| Checkpoint spec (retained HP ratio + free retries) | ✅ | `boss_checkpoint.gd` |
| Action pattern with telegraph + range + cooldown | ✅ | `boss_action_pattern.gd` |
| BossProfile/Phase/Checkpoint data model | ✅ | `boss_profile_test.gd` 16 tests |

**No findings.** ADR-013 实现与 spec 完全一致。

---

## Cross-ADR Consistency

| Check | Status |
|-------|--------|
| ADR-010 fog visibility ↔ ADR-005 AI behavior (AI respects fog) | ✅ |
| ADR-011 combo MSD ≤3 ↔ ADR-004 combat targeting (combo requires adjacent allies) | ✅ |
| ADR-012 difficulty scaling ↔ ADR-004 combat formulas (enemy_stat × multiplier) | ✅ |
| ADR-012 difficulty ↔ ADR-008 resource economy (drop multiplier applied post-combat) | ✅ |
| ADR-013 boss phases ↔ ADR-004 combat systems (phase trigger on HP threshold) | ✅ |
| ADR-011 combo ↔ ADR-001 event architecture (combo triggered via game_events signal) | ✅ |

---

## Traceability Matrix Update

| TR-ID | System | ADR | Implementation | Tests | Status |
|-------|--------|-----|---------------|-------|--------|
| TR-fog-001 | fog-of-war | ADR-010 | `fog_state_manager.gd` | 18 | Complete |
| TR-fog-002 | fog-of-war | ADR-010 | `fog_renderer.gd` | 6 | Complete |
| TR-fog-003 | fog-of-war | ADR-010 | `fog_target_filter.gd` | 7 | Complete |
| TR-fog-004 | fog-of-war | ADR-010 | `fog_state_manager.gd` (serialize) | 4 | Complete |
| TR-bond-005 | bond-system | ADR-011 | `combo_validator.gd` + `combo_skill_data.gd` | 23 | Complete |
| TR-bond-006 | bond-system | ADR-011 | battle UI integration | manual | Complete |
| TR-diff-001 | difficulty | ADR-012 | `difficulty_manager.gd` + `phase_curve.json` | 22 | Complete |
| TR-diff-002 | difficulty | ADR-012 | difficulty bridge + integration mock | 17 | Complete |
| TR-boss-001 | boss | ADR-013 | `boss_profile.gd` + `boss_phase.gd` + `boss_checkpoint.gd` | 16 | Complete |
| TR-boss-002 | boss | ADR-013 | `boss_action_pattern.gd` | 44 | Complete |

**10/10 TR requirements verified.** All implementations match their ADR specs.

---

## Sprint-010 Architecture Changes

Sprint-010 无新增 ADR（纯治理 sprint）。以下为新产生的架构相关产出：

| Artifact | Path | Purpose |
|----------|------|---------|
| Regression suite | `tests/regression-suite.md` | GDD critical path → test mapping |
| Test helpers | `tests/helpers/` | 可复用测试基础设施 |
| Performance baseline | `tests/performance/frame_time_baseline_test.gd` | 微基准测试 |

---

## Recommendation

Architecture 层健康。建议 Sprint-011 启动前：
1. 为 event-system 创建 ADR-014（解锁 Alpha 层首个 epic）
2. 考虑 `design/quick-specs/` 目录用于后续小型调整
3. F-3 (difficulty E2E test) 在 Sprint-011 可行性评估后决定是否创建
