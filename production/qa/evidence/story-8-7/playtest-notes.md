# Story 8-7 E2E Playtest Evidence

**Date**: 2026-05-02
**Test File**: `tests/integration/ui/e2e_game_flow_test.gd`
**Method**: Headless automated integration test + manual visual review

---

## 10 Checkpoint Results

### CP1: 启动 → 棋盘可见，单位就位 ✅
- **Automated**: `test_cp1_game_initializes_all_systems` — TurnManager FACTION_PHASE_ACTIVE, PLAYER first, turn=1, 4 units alive, occupancy correct
- **Visual**: ⚠️ 需在 Godot 编辑器中确认蓝色/红色单位渲染

### CP2: 选中己方单位 → 蓝色移动范围高亮 ✅
- **Automated**: `test_cp2_cp4_unit_selection_and_movement_logic` — SELECTED state, BFS reachable tiles computed, move_range > 0
- **Visual**: ⚠️ 需确认 `_draw()` 蓝色高亮渲染 (#0891B2)

### CP3: 悬停可达瓦片 → 青色路径预览 ✅
- **Automated**: `input_handler_test.gd` → `test_cp3_hover_reachable_shows_path_preview` (5 existing UI tests)
- **Visual**: ⚠️ 需确认 `_draw()` 青色路径渲染 (#06B6D4)

### CP4: 点击移动 → 单位瞬移，橙色攻击高亮 ✅
- **Automated**: `test_cp2_cp4_unit_selection_and_movement_logic` — move_unit atomic, grid_position updates, MOVED state
- **Visual**: ⚠️ 需确认高亮清除 + 橙色攻击高亮 (#EA580C)

### CP5: 悬停敌人 → 伤害预览数字 ✅
- **Automated**: `input_handler_test.gd` — `damage_preview_requested` signal emission verified
- **Visual**: ⚠️ 需确认琥珀色/红色 "-N" 标签 600ms 显示

### CP6: 点击攻击 → HP 更新，单位消失 ✅
- **Automated**: `test_cp5_cp6_attack_and_lethal_kill` — damage=8 (atk=9 def=1), e.hp=4→0, unit_died emitted
- **Visual**: ⚠️ 需确认 HP label 更新 + queue_free 后单位消失

### CP7: End Turn → 敌方阶段（热座） ✅
- **Automated**: `test_cp7_end_turn_switches_faction` + `test_cp7_two_full_cycles` — faction rotation verified, turn_number increments correctly

### CP8: 全灭敌方 → WIN 画面 ✅
- **Automated**: `test_cp8_full_game_victory` — complete game, match_ended emitted with PLAYER + "elimination"
- **Also**: `test_cp8_defeat_player_eliminated` — ENEMY + "elimination"
- **Visual**: ⚠️ 需确认 ResultOverlay VICTORY/DEFEAT 标题颜色

### CP9: Play Again → 重新开始 ⚠️
- **Requires scene tree**: `get_tree().reload_current_scene()` 需在 Godot 编辑器中验证

### CP10: 回合上限 → DRAW 画面 ✅
- **Automated**: `test_cp10_turn_cap_draw` — turn_cap=2, after 2 full cycles, match_ended with NONE + "turn_cap"
- **Visual**: ⚠️ 需确认 ResultOverlay DRAW 灰色标题

---

## 自动化覆盖总结

| Checkpoint | Automated | Manual Needed |
|-----------|-----------|---------------|
| CP1 | ✅ Logic | ⚠️ Visual rendering |
| CP2 | ✅ Logic | ⚠️ Highlight color |
| CP3 | ✅ Signal | ⚠️ Path rendering |
| CP4 | ✅ Logic | ⚠️ Unit position + highlight |
| CP5 | ✅ Signal | ⚠️ Damage preview label |
| CP6 | ✅ Logic | ⚠️ HP update + death animation |
| CP7 | ✅ Logic | — |
| CP8 | ✅ Logic | ⚠️ ResultOverlay |
| CP9 | — | ⚠️ Full scene reload |
| CP10 | ✅ Logic | ⚠️ ResultOverlay |

**Automated**: 9/10 checkpoints have logic-level verification (222 total tests passing)
**Manual**: 8 checkpoints need visual confirmation in Godot editor (rendering/UI)

---

## Visual Verification (Manual)

In Godot editor, run `src/Game.tscn` and verify:

1. [ ] Blue Player units (#3B82F6) at (5,2) and (5,4)
2. [ ] Red Enemy units (#EF4444) at (5,10) and (5,12)
3. [ ] Click Player unit → blue move highlights appear
4. [ ] Hover reachable tile → cyan path preview
5. [ ] Click to move → unit repositioned, orange attack highlights
6. [ ] Hover enemy → damage preview "-N" label
7. [ ] Click attack → HP updates, killed units disappear
8. [ ] End Turn button → faction switches, HUD updates
9. [ ] Kill all enemies → VICTORY overlay appears
10. [ ] Play Again → scene reloads
