# Story 001: 全量 UI 字符串迁移至 SRPGLocalization

> **Epic**: Localization
> **Status**: Planning
> **Layer**: Foundation
> **Type**: Integration

> **Estimate**: 1 day

## Context

**GDD**: `design/gdd/localization-system.md`
**现有实现**: `src/core/localization/srpg_localization.gd`

当前 SRPGLocalization 仅有 ~15 个 key，大量 UI 字符串硬编码在 GDScript 中。
本 story 将所有玩家可见字符串提取到翻译目录并替换为 `translate()` 调用。

## Acceptance Criteria

- [ ] LOC-AC-1: `base_hub.gd` 所有中文字符串迁移至 key
- [ ] LOC-AC-2: `training_ground.gd` 所有中文字符串迁移至 key
- [ ] LOC-AC-3: `character_management.gd` 所有中文字符串迁移至 key
- [ ] LOC-AC-4: `equipment_management.gd` 所有英文字符串迁移至 key
- [ ] LOC-AC-5: `main_menu.gd` 所有中文字符串迁移至 key
- [ ] LOC-AC-6: `battle_arena.gd` 结算/管理部分字符串迁移至 key
- [ ] LOC-AC-7: zh_CN 和 en_US 目录 key 完全对称（覆盖率 100%）
- [ ] LOC-AC-8: godot --check-only: 0 parse error

## Implementation Notes

### 迁移步骤（每个文件）

1. 扫描文件中所有硬编码字符串（中文或英文 UI 文本）
2. 为每个字符串分配 `{domain}.{element}` 格式的 key
3. 在 SRPGLocalization._CATALOG 的 zh_CN 和 en_US 中添加翻译
4. 替换源码中的硬编码字符串为 `SRPGLocalization.translate("key")`

### key 命名规范

```
base.title, base.level, base.resources, base.gold, base.materials, base.action_points,
base.back, base.training_tab, base.market_tab, base.management_tab,
training.title, training.character_list, training.skill_proficiency, training.empty_hint,
training.select_character, training.rank, ...
management.title, management.party_label, management.confirm, management.close,
management.hint, management.detail_empty, management.attributes, management.skills,
management.equipment, management.empty, management.status_deployed, management.status_available,
management.status_departed, ...
market.title, market.buy, market.sell, market.confirm, market.quantity, market.total,
market.gold_insufficient, market.item_insufficient, market.buy_success, market.sell_success,
market.holding, market.select_item, ...
menu.base, menu.continue, menu.new_game, menu.settings, ...
common.empty, common.confirm, common.close, ...
```

### 受影响文件

| 文件 | 预估 key 数 |
|------|------------|
| `src/ui/base/base_hub.gd` | ~25 |
| `src/ui/base/training_ground.gd` | ~10 |
| `src/ui/management/character_management.gd` | ~20 |
| `src/ui/management/character_tab_bar.gd` | ~5 |
| `src/ui/management/equipment_management.gd` | ~15 |
| `src/ui/menu/main_menu.gd` | ~5 |
| `src/ui/combat/battle_arena.gd` | ~30 |
| **合计** | **~110** |
