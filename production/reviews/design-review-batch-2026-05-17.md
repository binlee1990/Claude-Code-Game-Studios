# Design Review Batch — Per-System Review

> **Date**: 2026-05-02
> **Scope**: 5 个未独立 review 的系统（gate-check FAIL item B2）
> **Method**: 对照 GDD 8-section 标准逐系统检查

---

## Summary

| System | Design Completeness | GDD Quality | Implementation Fidelity | Verdict |
|--------|--------------------|--------------|------------------------|---------|
| fog-of-war | 8/8 sections | 8/8 sections in GDD | Matches ADR-010 | APPROVED |
| bond-system (combo) | 8/8 sections | Combo section added Sprint-008 | Matches ADR-011 | APPROVED |
| difficulty-system | 6/8 sections | 6/8 sections in GDD | Matches ADR-012 | APPROVED WITH NOTES |
| boss-system | 7/8 sections | 7/8 sections in GDD | Matches ADR-013 | APPROVED |
| base-system (Phase 1) | 6/8 sections | 6/8 sections in GDD | Matches Phase 1 scope | APPROVED WITH NOTES |

**Verdict**: 5/5 systems APPROVED 或 APPROVED WITH NOTES。无 FAIL。

---

## Per-System Detail

### 1. Fog-of-War System

| Section | Present | Quality |
|---------|---------|---------|
| Overview | ✅ | Clear one-paragraph summary |
| Player Fantasy | ✅ | "侦察与发现" fantasy well-defined |
| Detailed Rules | ✅ | 3 states + vision formula + tile reveal |
| Formulas | ✅ | F1 vision_range, F2 reveal_radius |
| Edge Cases | ✅ | 0-vision, out-of-bounds, save/load |
| Dependencies | ✅ | tactical grid, combat targeting, save system |
| Tuning Knobs | ✅ | BASE_VISION, height_bonus, scout_multiplier |
| Acceptance Criteria | ✅ | 4 ACs covering data/render/integration/save |

**Notes**: Fog GDD F1 与 MVP spec 的 vision_range 公式有微差异（已记录在 consistency-check，ADR-010 以 MVP spec 为准）。

### 2. Bond System (Combo Skills)

| Section | Present | Quality |
|---------|---------|---------|
| Overview | ✅ | Combo 作为羁绊系统的高级表现 |
| Player Fantasy | ✅ | "并肩作战" fantasy |
| Detailed Rules | ✅ | MSD ≤3, AP cost, cooldown, player-only trigger |
| Formulas | ✅ | F5 combo_damage = base × (1 + 0.1 × bond_level) |
| Edge Cases | ✅ | 门槛不满足显示 disabled+tooltip |
| Dependencies | ✅ | BondRegistry, combat targeting, battle unit id |
| Tuning Knobs | ✅ | AP cost per type, cooldown per type, damage coef |
| Acceptance Criteria | ✅ | 6 ACs covering data/UI/integration |

**Notes**: S-rank bond 内容为 future scope，GDD 已明确标注。

### 3. Difficulty System

| Section | Present | Quality |
|---------|---------|---------|
| Overview | ✅ | 一周目固定曲线 |
| Player Fantasy | ✅ | "渐进式挑战" |
| Detailed Rules | ✅ | 4 phases, multipliers per stat type |
| Formulas | ✅ | F1 stat_scaling = base_stat × difficulty_multiplier |
| Edge Cases | ⚠️ PARTIAL | 未覆盖 phase 边界切换时的战斗中途难度变化 |
| Dependencies | ✅ | combat, settlement, AI |
| Tuning Knobs | ✅ | phase_curve.json external config |
| Acceptance Criteria | ✅ | 2 ACs covering data model + integration |

**Finding D-1 (ADVISORY)**: Edge Cases 缺少"phase 切换发生在战斗中途时，当前战斗是否即时应用新倍率？"的设计决策。建议在 `design/quick-specs/difficulty-phase-transition.md` 中补充。

### 4. Boss System

| Section | Present | Quality |
|---------|---------|---------|
| Overview | ✅ | 5 类 Boss + checkpoint 系统 |
| Player Fantasy | ✅ | "史诗感 Boss 战" |
| Detailed Rules | ✅ | Phase HP thresholds, telegraph, checkpoint recovery |
| Formulas | ✅ | F1 phase trigger, F2 retained HP |
| Edge Cases | ✅ | 0 HP skip phases, checkpoint retry exhaustion |
| Dependencies | ✅ | combat system, save system, AI system |
| Tuning Knobs | ⚠️ PARTIAL | phase thresholds and telegraph durations listed but not organized as a tuning table |
| Acceptance Criteria | ✅ | 4 ACs covering profile/phase/checkpoint/action pattern |

**No blocking findings.** Tuning Knobs 建议转换为 `assets/data/boss/` JSON 配置以对齐 data-driven 标准。

### 5. Base System (Phase 1)

| Section | Present | Quality |
|---------|---------|---------|
| Overview | ✅ | 战后基地 hub |
| Player Fantasy | ✅ | "回家的感觉" |
| Detailed Rules | ✅ | 5 areas (Training/Tavern/Market/Upgrade/Intel) |
| Formulas | ✅ | F1 AP generation, F2 upgrade cost |
| Edge Cases | ⚠️ PARTIAL | AP 溢出、基地等级上限未定义 |
| Dependencies | ✅ | settlement (triggers base entry), save system |
| Tuning Knobs | ✅ | base-upgrade-costs.json |
| Acceptance Criteria | ✅ | 4 ACs (Phase 1 only) |

**Finding D-2 (ADVISORY)**: Phase 2+ scope 未在 GDD 中明确标记。建议在 GDD header 添加 "Phase 1: MVP (Sprint-004/006) | Phase 2: Alpha (TBD)" 范围声明。

---

## Recommendation

1. **D-1** (difficulty phase transition): 写入 `design/quick-specs/difficulty-phase-transition.md`
2. **D-2** (base Phase 2 scope): 更新 `design/gdd/base-system.md` header 加 scope 标记
3. 创建 `design/quick-specs/` 目录用于后续小型设计决策

无阻塞项。5 个系统均可安全进入 Polish。
