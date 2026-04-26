# Story 006: 果子二选三结算界面（强制弹窗 + 资源经济写入）

> **Epic**: Chapter 02 Content
> **Status**: Ready for Dev
> **Layer**: Feature
> **Type**: Logic
> **Manifest Version**: 2026-04-26-v2

> **Estimate**: 0.5 days

## Context

**GDD**: `design/gdd/chapter-02.md` §3.7, §5.8 / `design/gdd/battle-settlement.md` / `design/gdd/resource-economy.md`
**Requirement**: AC-CH2-008 / QA Plan §3.6
**ADR Governing Implementation**: ADR-001 (Event Architecture) / ADR-003 (Save System)

**Engine**: Godot 4.6.2 | **Risk**: LOW

---

## Acceptance Criteria

- [ ] **AC-CH2-008.1**: Ch.2-3 胜利后，结算屏出现果子三选二界面，显示 fruit_str / fruit_agi / fruit_int 各 1 份。
- [ ] **AC-CH2-008.2**: 玩家选择 2 种后点击确认；对应 fruit 写入库存；第三种不进入库存。
- [ ] **AC-CH2-008.3**: 若存档中断后重载，界面重新弹出（`fruit_selection_done = false` 检测）。

---

## Implementation Notes

### 触发条件

```
when battle == "chapter_02_finale" and battle_result == "victory":
    if not progress_data.fruit_selection_done:
        trigger_fruit_selection_screen()
```

### 果子数据

| 果子 ID | 名称 | 属性加成 |
|--------|------|---------|
| `fruit_str` | 力量果子 | STR +3 |
| `fruit_agi` | 敏捷果子 | AGI +3 |
| `fruit_int` | 智力果子 | INT +3 |

### 界面交互规则

```
- 强制弹窗：不可 Esc/Enter 跳过
- 可选状态：选中（高亮）/ 未选中（灰暗）
- 最大选择数：2（第三选项点击时替换较早选择）
- 确认按钮：已选 2 项时启用
- 点击确认：写入 inventory，置 fruit_selection_done=true，关闭弹窗
```

### 资源经济写入

```
inventory.add_item("fruit_str", 1)   # 若选中
inventory.add_item("fruit_agi", 1)    # 若选中
inventory.add_item("fruit_int", 1)   # 若选中
progress_data.fruit_selection_done = true
```

### Edge Cases

| 情形 | 处理 |
|------|------|
| 玩家只选 1 项点击确认 | 按钮禁用，不可提交 |
| 连续点击同一个果子 | 取消选中（toggle） |
| 中断重载（fruit_selection_done=false） | 重新弹出界面 |
| 正常完成选择（fruit_selection_done=true） | 不再弹出，直接进入基地/下一章 |

---

## Out of Scope

- 果子使用的时机和效果（由 resource-economy / attribute-system epic 实现）
- 结算屏的美术/布局（由 UI epic 实现）
- 其他章节的果子选择（后续章节复用该系统）

---

## QA Test Cases

- **AC-CH2-008.1**: 界面显示
  - Given: Ch.2-3 胜利，fruit_selection_done=false
  - When: settlement screen
  - Then: 3 fruits displayed: fruit_str, fruit_agi, fruit_int

- **AC-CH2-008.2**: 选择写入库存
  - Given: Player selects fruit_str and fruit_agi, clicks confirm
  - When: selection confirmed
  - Then: inventory.fruit_str=1, inventory.fruit_agi=1, fruit_int=0, fruit_selection_done=true

- **AC-CH2-008.3**: 中断重载
  - Given: fruit_selection_done=false (未完成选择), player reloads
  - When: player loads saved game
  - Then: fruit selection screen appears again

---

## Test Evidence

**Story Type**: Logic
**Required evidence**: `tests/unit/chapter02/fruit_selection_test.gd`
**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: `design/gdd/resource-economy.md`（inventory 接口）、`design/gdd/battle-settlement.md`（结算触发）
- Unlocks: Ch.3 入口（章节完成解锁）

---

## Files to Create / Modify

| File | Action | 说明 |
|------|--------|------|
| `src/core/settlement/fruit_selection.gd` | Create | 果子选择逻辑 + 中断重载检测 |
| `src/ui/settlement/fruit_selection_screen.tscn` | Modify | 现有结算屏添加果子选择控件 |
| `src/core/save/progress_data.gd` | Modify | 新增 `fruit_selection_done` 字段 |
| `tests/unit/chapter02/fruit_selection_test.gd` | Create | AC-CH2-008 测试 |
| `tests/tests_manifest.txt` | Modify | 新增测试文件引用 |

---

## Completion Notes

**Completed**: YYYY-MM-DD
**Criteria**: X/X AC passing
**Deviations**: None
**Test Evidence**: `tests/unit/chapter02/fruit_selection_test.gd` — N/N PASS
**Code Review**: /code-review
**Files Delivered**: (list files)
