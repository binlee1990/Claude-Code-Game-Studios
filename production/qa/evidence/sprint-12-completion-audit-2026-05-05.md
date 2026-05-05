# Sprint 12 Completion Audit — 2026-05-05

验收结论: PASS

## 辩证审计结论

Claude 的 `production/sprints/sprint-12.md` 已声明 19/19 完成，但审计前存在证据缺口：`production/session-state/active.md` 仍停留在 Phase 1-2；Sprint 12 的 5 个 Epic 仍标为 Planned/Todo；Godot 实测发现 UI 编译错误、FTUE autoload 缺失、旧 QA 脚本未适配渐进解锁。

Codex 本轮按“声明不等于完成”处理：先用 Godot 和数据一致性检查证明失败，再修复代码、数据、校验脚本和状态文档。

## 已修复问题

- `project.godot` 缺少 `FTUEStateMachineHostAutoload`，导致 FTUE 运行时未接入。
- `src/ui/shell/left_nav.gd` 调用不存在的 `_connect_signals()`，且 `_tab_states` 未初始化。
- `src/ui/toast/toast_stack.gd` 使用 Variant 推断触发 Godot “warning as error”，并且不能正确格式化 `offline.settled.claimed`。
- `src/systems/features/ftue_state_machine.gd` 订阅了不存在的 `resource.changed` / `offline.settlement_shown` 事件。
- `src/systems/features/zone_system.gd` 解锁区域时未发布 `zone.unlocked`，FTUE Stage 3 无法自然推进。
- `assets/data/exp_curve.json` 的 Lv.1-30 经验表与 `design/balance/mvp-content-progression.md §3.1` 不一致。
- Sprint 11 校验脚本仍假设所有屏幕开局可打开，未适配 Sprint 12 渐进解锁。
- 突破仪式使用的 `realm_burst_gold` 未登记到 `Sprint11AssetCatalog`。

## 验证证据

| Gate | Evidence |
|------|----------|
| Sprint 12 FTUE + UI 解锁 | `godot --headless --path . --script res://scripts/validate_sprint12_experience.gd` → `SPRINT12_EXPERIENCE_GLUE_OK` |
| 主场景加载 | `validate_main_scene_load.gd` → `MAIN_SCENE_LOAD_OK` |
| 修炼屏布局 | `validate_cultivation_layout.gd` → `CULTIVATION_LAYOUT_OK` |
| 战斗屏布局 | `validate_combat_layout.gd` → `COMBAT_LAYOUT_OK` |
| 设置交互 | `validate_settings_interaction.gd` → `SETTINGS_INTERACTION_OK` |
| 4K 缩放 | `validate_4k_ui_scale.gd` → `S11_4K_UI_SCALE_OK` |
| 数据一致性 | enemies=15, zones=3, loot_tables=15, exp_levels=30, errors=[] |
| GdUnit 回归 | `reports/report_36/results.xml` → 132 tests, 0 failures, 0 skipped, 0 flaky |
| Godot import | `godot --headless --path . --import --quit` → exit 0 |

## 剩余风险

- `exp_curve.json` 已按设计配置，但现有 `LevelSystem` 仍使用已通过回归的公式路径；若后续要求 LevelSystem 直接消费该 JSON，需要单独改 LevelSystem 与对应测试。
- Headless 环境无法产出截图，相关截图 gate 在脚本中显式打印 `*_SCREENSHOT_SKIPPED_HEADLESS`；布局数值检查已通过。
