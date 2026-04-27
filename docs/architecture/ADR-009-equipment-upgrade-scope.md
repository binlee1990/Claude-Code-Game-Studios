# ADR-009: Equipment Upgrade Scope

> **Status**: Accepted
> **Date**: 2026-04-27
> **Author**: technical-planner
> **Systems Affected**: Equipment System, Resource Economy, Character Management, Base

---

## Context

The equipment system already supports enhancement, affixes, decomposition, set bonuses, final attribute calculation, and save/load. Sprint-004 exposed equipment viewing and swapping, but full enhancement / enchant / decomposition UI was explicitly deferred.

---

## Decision

For Sprint-006+, equipment upgrade work should enter in this order:

1. **Enhancement MVP**: expose existing enhancement logic for equipped items only.
2. **Cost clarity**: source cost from resource economy constants, not UI literals.
3. **Failure states**: show insufficient gold/material/protection-symbol feedback before mutation.
4. **Persistence**: verify enhanced item state survives save/load.

Affix rerolling, decomposition UI, set crafting, and sockets remain outside the first upgrade slice.

---

## Consequences

### Positive

- Reuses implemented equipment logic without opening every designed feature.
- Gives players a clear Ch.3 preparation sink.
- Keeps UI blast radius small by starting from equipped items.

### Negative

- Inventory-wide equipment management remains incomplete.
- Balance depends on ADR-008 resource tuning.

---

## Rejected Alternatives

- **Implement full forge UI immediately**: rejected because enhancement, affix, decomposition, and set systems would exceed one sprint.
- **Leave enhancement hidden indefinitely**: rejected because Ch.2 feedback identified missing cultivation/preparation as a pain point.

---

## Verification Required

- Unit tests for enhancement cost and result remain green.
- UI test equips or enhances a deterministic item.
- Save/load integration confirms enhancement level persists.

---

## ADR Dependencies

- **ADR-008** (Resource Economy Upgrade Scope): 强化消耗的资源数量与失败补偿来源
- **ADR-003** (Save System): 强化等级 / 词缀状态持久化
- **ADR-001** (Event Architecture): `equipment_enhanced(item_id, level, success)` 信号

---

## Engine Compatibility

| Engine | Godot 4.6.2 |
|--------|-------------|
| `Resource` 子类 EquipmentItem | ✓ |
| `Control` + `GridContainer` 强化 UI | ✓ |
| Save/load 保留枚举状态（按 ADR-003 schema 推荐做 round-trip 校验） | ✓ |

---

## GDD Requirements Addressed

- `design/gdd/equipment-system.md` — TR-equip-003（强化安全/风险区）
- `design/gdd/equipment-system.md` — TR-equip-006（最终属性合成纳入强化结果）
- `design/gdd/equipment-system.md` — TR-equip-007（强化等级 round-trip）
