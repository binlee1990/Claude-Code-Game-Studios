# Consistency Check — 跨 GDD 一致性审查

> **Date**: 2026-05-01
> **Method**: Grep-first approach — 对比 GDD 间的交叉引用、公式变量、依赖关系
> **Scope**: 24 GDDs + entity registry + TR registry

---

## Verdict: PASS (WITH 5 FINDINGS)

---

## Finding 1: Fog GDD 视野公式 vs Sprint-009 规范不一致

**Source**: `design/gdd/fog-of-war-system.md` F1 vs Sprint-008 MVP spec section

GDD 公式:
```
vision_range = BASE_VISION + floor(agility / 60) + class_bonus + height_bonus
```

MVP spec 描述: "地形规则：高地提供 +1"

**问题**: GDD F1 中 agility 除以 60 做 floor（60→1, 80→1, 120→2），但 MVP spec 中称 "敏捷≥60 +1, ≥80 +2"。公式与 spec 不一致 — floor(60/60)=1, floor(80/60)=1（相同结果），无法区分 ≥60 和 ≥80。

**建议**: Sprint-009 实现时以 MVP spec 为准（if agility>=80→+2, elif agility>=60→+1），ADR-010 已反映此修正。

---

## Finding 2: Boss GDD HP 阈值 vs Difficulty 倍率兼容性

**Source**: `design/gdd/boss-system.md` F1 vs `design/gdd/difficulty-system.md` F1

Boss 阶段切换阈值: `boss_max_hp × phase_threshold[N]`（50%, 25%）
Difficulty 倍率: `scaled_stat = base_stat × difficulty_multiplier`

**验证**: 百分比阈值与倍率兼容。`boss_max_hp` 经 difficulty 倍率后，50%/25% 仍有效。ADR-013 已确认此兼容性。PASS。

---

## Finding 3: Bond Combo 曼哈顿距离定义跨系统一致

**Source**: `design/gdd/bond-system.md` §Sprint-008 spec vs `design/gdd/tactical-mechanism.md`

Bond spec: "曼哈顿距离 ≤3"
Tactical spec: 未明确定义曼哈顿距离，但网格系统使用 `Vector2i` 坐标

**验证**: `abs(x1-x2) + abs(y1-y2) ≤ 3` 是标准曼哈顿距离。Bond combo 实现应使用此公式。ADR-011 已明确。

---

## Finding 4: Entity Registry 缺少 4 个系统实体

**Source**: `design/registry/entities.yaml` vs `design/gdd/systems-index.md`

Entities.yaml 包含 7 items / 15 formulas / 35 constants，但以下系统无实体注册：
- Fog-of-war (fog cell state, vision range)
- Difficulty (difficulty profile, phase curve)
- Boss (boss profile, action pattern, checkpoint)
- Combo skill (combo skill data, 4 bond-type effects)

**建议**: Sprint-009 实现后回填 entity registry。

---

## Finding 5: HP 系统 GDD 引用链条完整

**Source**: `design/gdd/hp-system.md` Dependencies

HP 系统声称依赖 attribute/class/equipment，并在 boss-system/bond-system/difficulty-system GDD 中被引用。

**验证**: 
- Boss GDD → HP: "Boss max_hp 由 battle_definition 提供" ✓
- Bond GDD → HP: "消耗 30% HP 以战斗内 max_hp 为基准" ✓
- Difficulty GDD → HP: "enemy max_hp 调用 BattleDifficultyProfile.scale_enemy_hp()" ✓

所有 HP 交叉引用一致。PASS。

---

## Cross-System Dependency Check

| Upstream | Downstream | Dependencies Match? |
|----------|-----------|---------------------|
| attribute-growth | class, skill, equipment, bond, character | All GDDs reference correctly |
| tactical-mechanism | ai, turn-based, fog | All GDDs reference correctly |
| battle-settlement | bond, difficulty, equipment | All GDDs reference correctly |
| ai-system | boss, fog, turn-based | All GDDs reference correctly |
| difficulty | boss, ai, settlement | All GDDs reference correctly (Sprint-009) |

**No broken dependency chains detected.**

---

## Formula Variable Naming Consistency

扫描所有 GDD 的公式节，检查跨文档变量命名：

| Variable | Used In | Consistent? |
|----------|---------|-------------|
| `base_stat` / `S_base` | difficulty, equipment, attribute | ⚠ 命名不一致（difficulty 用 `base_stat`, equipment 用 `base_value`） |
| `hp_cost` | bond, hp | ✓ |
| `vision_range` | fog | ✓ (单一系统) |
| `affinity_gain` | bond | ✓ (单一系统) |

**Finding 6**: `base_stat` / `base_value` 在不同 GDD 中指代相同概念但命名有差异。不影响实现（代码使用具体字段名），但影响文档可读性。

---

## Summary

| Finding | Severity | Action |
|---------|----------|--------|
| F1: Fog 视野公式不一致 | HIGH | Sprint-009 以 MVP spec 为准（已在 ADR-010 修正） |
| F2: Boss HP 阈值 vs Difficulty 兼容 | — | 已验证 PASS |
| F3: Manhattan distance 定义 | — | 已验证 PASS |
| F4: Entity registry 缺失 VS 实体 | LOW | Sprint-009 后回填 |
| F5: HP 交叉引用一致性 | — | 已验证 PASS |
| F6: 跨 GDD 变量命名不统一 | LOW | 不阻塞实现 |

---

## Checklist

- [x] All 24 GDDs scanned for cross-references
- [x] Dependency chains verified (no broken links)
- [x] Formula variable naming compared
- [x] Entity registry audited
- [x] 4 new systems (fog/bond-combo/diff/boss) checked against existing systems
- [x] Findings classified by severity
