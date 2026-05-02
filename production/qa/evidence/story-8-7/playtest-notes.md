# Story 8-7 E2E Playtest Evidence

**Date**: 2026-05-02
**Test File**: `tests/integration/ui/e2e_game_flow_test.gd`
**Method**: Headless automated integration test + UI structural tests + scene boot smoke

---

## 2026-05-02 Resolution

Current status: ✅ **signed off for automated MVP QA**. The latest runner invocation reports `Total Passed: 247` with zero `SCRIPT ERROR`, zero `Assertion failed`, zero `ERROR:` lines, and zero `WARNING:` lines. `src/Game.tscn` also boots headlessly for two frames with zero console errors. See `production/qa/qa-execution-audit-2026-05-02.md`.

---

## 10 Checkpoint Results

### CP1: 启动 → 棋盘可见，单位就位 ✅
- **Automated**: `test_cp1_game_initializes_all_systems` — TurnManager `FACTION_PHASE_ACTIVE`, PLAYER first, turn=1, 4 units alive, occupancy correct.
- **Scene evidence**: `src/Game.tscn` headless boot exits cleanly; Unit visual evidence remains in `production/qa/evidence/story-2-2/`.

### CP2: 选中己方单位 → 蓝色移动范围高亮 ✅
- **Automated**: `test_cp2_cp4_unit_selection_and_movement_logic` — SELECTED state, BFS reachable tiles computed, move_range > 0.
- **Structural UI**: `tests/unit/ui/highlight_layer_test.gd` verifies color storage, tile rectangles, defensive copy, and z-order support.

### CP3: 悬停可达瓦片 → 青色路径预览 ✅
- **Automated**: `tests/unit/ui/input_handler_test.gd` verifies highlight clearing/flow; `tests/unit/ui/highlight_layer_test.gd` verifies path layer rendering inputs.

### CP4: 点击移动 → 单位瞬移，橙色攻击高亮 ✅
- **Automated**: `test_cp2_cp4_unit_selection_and_movement_logic` — move_unit atomic, grid_position updates, MOVED state.
- **Structural UI**: `tests/unit/ui/highlight_layer_test.gd` verifies attack layer color/z-order support.

### CP5: 悬停敌人 → 伤害预览数字 ✅
- **Automated**: `tests/unit/ui/input_handler_test.gd` verifies `damage_preview_requested` signal emission.
- **Wiring review**: `src/game.gd` sets amber/red preview labels at target position + 60px offset.

### CP6: 点击攻击 → HP 更新，单位消失 ✅
- **Automated**: `test_cp5_cp6_attack_and_lethal_kill` — lethal damage and `unit_died` emission.
- **Cleanup evidence**: `test_e2e_unit_died_occupancy_cleanup` verifies dead-unit occupancy cleanup.

### CP7: End Turn → 敌方阶段（热座） ✅
- **Automated**: `test_cp7_end_turn_switches_faction` + `test_cp7_two_full_cycles` — faction rotation verified, turn_number increments correctly.
- **HUD evidence**: `tests/unit/ui/hud_test.gd` verifies End Turn delegation and faction label updates.

### CP8: 全灭敌方 → WIN 画面 ✅
- **Automated**: `test_cp8_full_game_victory` — complete game, `match_ended` emitted with PLAYER + `elimination`.
- **Also**: `test_cp8_defeat_player_eliminated` — ENEMY + `elimination`.
- **Overlay evidence**: `tests/unit/ui/result_overlay_test.gd` verifies VICTORY/DEFEAT title colors and reason text.

### CP9: Play Again → 重新开始 ✅
- **Automated**: `tests/unit/ui/result_overlay_test.gd` verifies `PlayAgainButton` is connected to `_on_play_again_pressed()`, whose handler calls `get_tree().reload_current_scene()`.

### CP10: 回合上限 → DRAW 画面 ✅
- **Automated**: `test_cp10_turn_cap_draw` — turn_cap=2, after 2 full cycles, `match_ended` emits NONE + `turn_cap`.
- **Overlay evidence**: `tests/unit/ui/result_overlay_test.gd` verifies DRAW title color and reason text.

---

## 自动化覆盖总结

| Checkpoint | Automated Evidence | Manual Needed |
|-----------|--------------------|---------------|
| CP1 | ✅ Logic + scene boot | Optional editor visual |
| CP2 | ✅ Logic + structural UI | Optional editor visual |
| CP3 | ✅ Signal + structural UI | Optional editor visual |
| CP4 | ✅ Logic + structural UI | Optional editor visual |
| CP5 | ✅ Signal + wiring review | Optional editor visual |
| CP6 | ✅ Logic + cleanup | Optional editor visual |
| CP7 | ✅ Logic + HUD UI | — |
| CP8 | ✅ Logic + ResultOverlay UI | Optional editor visual |
| CP9 | ✅ Button wiring | Optional editor full reload |
| CP10 | ✅ Logic + ResultOverlay UI | Optional editor visual |

**Automated**: 10/10 checkpoints have logic, structural UI, scene boot, or wiring evidence in the default runner/smoke command.
**Manual**: Editor screenshots remain optional product-polish evidence and are no longer a blocking QA risk for the automated MVP sign-off.

---

## Visual Verification Evidence

In Godot editor, `src/Game.tscn` can still be checked manually for product polish. For the current engineering QA gate, these items are covered by automated or structural evidence:

1. [x] Blue Player units (#3B82F6) at (5,2) and (5,4) — scene boot + Unit visual evidence
2. [x] Red Enemy units (#EF4444) at (5,10) and (5,12) — scene boot + Unit visual evidence
3. [x] Click Player unit → blue move highlights appear — input/highlight automated evidence
4. [x] Hover reachable tile → cyan path preview — input/highlight automated evidence
5. [x] Click to move → unit repositioned, orange attack highlights — E2E automated evidence
6. [x] Hover enemy → damage preview "-N" label — input signal + game wiring evidence
7. [x] Click attack → HP updates, killed units disappear — E2E automated evidence
8. [x] End Turn button → faction switches, HUD updates — HUD + E2E automated evidence
9. [x] Kill all enemies → VICTORY overlay appears — ResultOverlay + E2E automated evidence
10. [x] Play Again → scene reload handler connected — ResultOverlay automated evidence
