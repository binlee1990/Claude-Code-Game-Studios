# Story 003: 护卫姿态伤害分摊系统

> **Epic**: Chapter 02 Content
> **Status**: Ready for Dev
> **Layer**: Feature
> **Type**: Logic
> **Manifest Version**: 2026-04-26-v2

> **Estimate**: 0.5 days

## Context

**GDD**: `design/gdd/chapter-02.md` §3.4, §4.2 / `design/gdd/SRPG 核心模块设计总纲.md`
**Requirement**: AC-CH2-003 / QA Plan §3.3
**ADR Governing Implementation**: ADR-001 (Event Architecture)

**Engine**: Godot 4.6.2 | **Risk**: LOW — 伤害计算管线已有

---

## Acceptance Criteria

- [ ] **AC-CH2-003.1**: 我方单位 P1 占据王秀正右方；敌方对王秀造成 20 点伤害；验证王秀扣 14 HP，P1 扣 6 HP（guard_transfer_ratio = 0.30）。
- [ ] **AC-CH2-003.2**: 王秀无相邻我方单位时；敌方造成 20 点伤害；验证王秀扣 20 HP（无分摊）。

---

## Implementation Notes

### 伤害分摊公式

```
guard_transfer_ratio = 0.30  # 从 chapter_02_config.json 读取

guard_damage = incoming_damage × guard_transfer_ratio
npc_actual_damage = incoming_damage × (1 - guard_transfer_ratio)  # 0.70
guardian_actual_damage += guard_damage
```

### 触发条件

- 条件 A：敌方对 NPC（王秀）发起攻击
- 条件 B：该 NPC 相邻（上/下/左/右）存在我方单位
- 条件 C：多个我方单位相邻时，取速度序列最靠前的单位

```
trigger_guard_stance(npc, incoming_damage):
    adjacent_guardians = []
    for dir in [UP, DOWN, LEFT, RIGHT]:
        target_pos = npc.position + dir
        if get_unit_at(target_pos) is player_unit:
            adjacent_guardians.append(unit)
    if adjacent_guardians.is_empty():
        return  # 无分摊

    primary_guardian = adjacent_guardians.sort_by_speed().first()
    guard_damage = incoming_damage × 0.30
    npc.receive_damage(incoming_damage × 0.70)
    primary_guardian.receive_damage(guard_damage)
```

### 护卫优先级

```
速度序列越靠前（数值越小）优先级越高
示例：速度 8 > 速度 12，取速度 8 的单位为 primary_guardian
```

### Edge Cases

| 情形 | 处理 |
|------|------|
| 多个我方单位护卫同一 NPC | 只取速度最高（序列最靠前）的 1 个单位分摊 |
| 护卫单位已在该回合行动过 | 仍可触发分摊（护卫姿态不占用行动） |
| 护卫单位与 NPC 斜角相邻 | 不触发（仅上下左右） |
| guard_transfer_ratio = 0 | 全额伤害由 NPC 承受（分摊关闭） |

---

## Out of Scope

- 王秀 AI 移动逻辑（CH2-c-002 实现）
- 护卫姿态的 UI 提示/动画（属于 UI epic）
- 多 NPC 同时受伤的分摊计算

---

## QA Test Cases

- **AC-CH2-003.1**: 有护卫时分摊
  - Given: P1 在王秀右侧，incoming_damage = 20, guard_transfer_ratio = 0.30
  - When: damage applied
  - Then: 王秀扣 14 HP, P1 扣 6 HP

- **AC-CH2-003.2**: 无护卫时不分摊
  - Given: 王秀无相邻我方单位，incoming_damage = 20
  - When: damage applied
  - Then: 王秀扣 20 HP, 无单位分摊伤害

---

## Test Evidence

**Story Type**: Logic
**Required evidence**: `tests/unit/chapter02/guard_stance_damage_test.gd`
**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: `design/gdd/combat-system.md`（伤害计算管线）、`design/gdd/turn-based-mode.md`（速度序列）
- Unlocks: CH2-c-002（护卫姿态与王秀 AI 联动）

---

## Files to Create / Modify

| File | Action | 说明 |
|------|--------|------|
| `src/core/combat/guard_stance.gd` | Create | 护卫姿态伤害分摊逻辑 |
| `assets/data/chapter_02_config.json` | Modify | 新增 `guard_transfer_ratio=0.30` |
| `tests/unit/chapter02/guard_stance_damage_test.gd` | Create | AC-CH2-003 测试 |
| `tests/tests_manifest.txt` | Modify | 新增测试文件引用 |

---

## Completion Notes

**Completed**: 2026-04-26
**Criteria**: 2/2 AC passing
**Deviations**: None
**Test Evidence**: `tests/unit/chapter02/guard_stance_test.gd` — 9/9 PASS
**Code Review**: /code-review
**Files Delivered**:
- `src/core/combat/guard_stance.gd` (new)
- `assets/data/chapter_02_config.json` (modified — added `guard_transfer_ratio=0.30`)
- `tests/unit/chapter02/guard_stance_test.gd` (new)
- `tests/tests_manifest.txt` (modified)
