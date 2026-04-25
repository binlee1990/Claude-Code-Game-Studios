# Sprint-002 Presentation P0 — Evidence

> Date: 2026-04-26
> Sprint: sprint-002 Lane B2
> Status: IMPLEMENTATION COMPLETE — 待人工截图验收

## Scope

UI 代码层 4 项 P0 修复 + 1 项 src/core 破例（peek_save 只读接口）。

## Implementation Map

| Story | 文件 | 落地点 | 验收方式 |
|-------|------|--------|----------|
| UI-P0-01 主菜单焦点 + 存档摘要 | `src/ui/menu/main_menu.gd:147` (peek_save 调用) | 焦点 GOLD（来自 srpg_theme），摘要行用 `SaveManager.peek_save(1)` 拼接 | 启动主菜单截图 |
| UI-P0-01 主菜单 GOLD 焦点（全局主题） | `src/ui/theme/srpg_theme.gd:65` | `apply_button` 的 focus stylebox border 改为 GOLD | 同上截图 |
| UI-P0-01 SaveManager 只读接口 | `src/core/save/save_manager.gd:73` | 新增 `func peek_save(slot:int) -> SaveData`，不修改 `_current_slot` 不 emit 信号 | 单测建议：peek_save 不影响后续 load_game 行为 |
| UI-P0-02 Auto 状态徽章 + speed badge | `src/ui/combat/battle_arena.gd:311-323, 1947-1950` | `_auto_badge_label` (`[Auto]`/`[手动]`) + `_speed_badge_label` (1x/2x/3x) | 战斗中切换 Auto + 切档截图 |
| UI-P0-03 立牌迷你 HP 条 | `src/ui/combat/battle_arena.gd` (`_refresh_turn_display` 内联实现) | VBoxContainer 含 Label + ProgressBar(高 4px) | 战斗截图，HP < 25% 应红色 |
| UI-P0-04 hint_bar 全局按键提示 | `src/ui/common/hint_bar.gd` (新建) + `battle_arena.gd:13,119` 挂载 | `set_hints(Array[Dictionary])` API；主菜单与战斗屏均挂载 | 4 屏底部提示截图 |

## Pending Manual Verification

| 验证项 | 期待结果 | 状态 |
|--------|----------|------|
| 主菜单截图：焦点为金铜色边框 | PASS | TODO |
| 主菜单截图：存档行显示 "第 X 章 · battle_id · 上次保存 HH:MM" 或 "暂无存档" | PASS | TODO |
| 战斗截图：Auto 切换后徽章立即更新 + 速度档位可读 | PASS | TODO |
| 战斗截图：回合立牌底部 HP 条颜色随血量变化 | PASS | TODO |
| 4 屏截图：底部 hint bar 显示当前可用键位 | PASS | TODO |

## Test Suite Sanity

实施完成后须跑全量测试 686/686 PASS。本 evidence 文档落盘时尚未跑测——下一步动作。

## Out of Scope (本 Sprint 推迟)

- ART-P0-05/06：字体替换（资产已就位 `assets/fonts/zcool_xiaowei.ttf` + `noto_serif_sc.otf`，srpg_theme 字体加载需后续 PR）
- AUDIO-P0-07/08：BGM 挂载（资产清单 URL 不可达，BLOCKED）
