# Active Session State

**Updated**: 2026-05-03

## Current Task

调试控制台 (Debug Console) GDD — Section A+B+C 完成, Section D (Formulas) 起接续

## Status

Skeleton + Sections A/B/C 已写入 design/gdd/debug-console.md。
- A Overview ✅
- B Player Fantasy ✅
- C Detailed Design ✅（13 条 Core Rules + 状态机 + 7 个系统交互表）
- D Formulas — 待
- E Edge Cases — 待
- F Dependencies — 待
- G Tuning Knobs — 待
- H Visual/Audio Requirements — 待（可选，调试工具非 VFX 类）
- I UI Requirements — 待
- J Acceptance Criteria — 待
- K Open Questions — 待

## Files Modified This Session

| File | Purpose |
|------|---------|
| design/gdd/debug-console.md | Section C 写入：Core Rules / States / Interactions（约 200 行） |
| production/session-state/active.md | 当前会话同步 |

## Key Decisions Locked in Section C

- Autoload + .tscn UI；`OS.is_debug_build()` 入口排除
- `~` 键检测使用 `physical_keycode == KEY_QUOTELEFT`（跨布局稳定）
- 控制台打开 = `get_tree().paused = true` + 缓存/恢复前焦点
- `process_mode = PROCESS_MODE_ALWAYS`、`CanvasLayer.layer = 128`
- 静态硬编码命令注册表（10 命令：res/event/config/modifier/attr/prod/time/save/help/clear）
- LineEdit + RichTextLabel(BBCode) + SystemFont monospace fallback
- 输出缓冲 500 行环形 Array<String> + clear+rebuild
- 命令历史 50 条，仅内存（不跨会话持久化）
- EventBus 需补充 `subscribe_pattern` + 对称的 `unsubscribe_pattern`
- 关闭控制台时遍历注销所有活跃 watch

## Downstream GDD Gaps (need followup edits)

- **EventBus GDD**：需追加 `subscribe_pattern(prefix, callable)` 与 `unsubscribe_pattern(prefix, callable)` 接口（Phase 5 的 EventBus 修订条目）
- **ModifierEngine GDD**：需新增 `get_all_targets() -> Array[String]`（`modifier list` 命令需要）
- **OutputMultiplierSystem GDD**：高层 `get_final_rate()` + breakdown API 当前未声明（`prod breakdown` 命令需要）
- **SaveSystem GDD**：需将 `save_game()` 拆出 `collect_save_data() -> Dictionary` 内部方法（`save dump` 命令需要）

## Previous Tasks

- output-multiplier-system.md — Designed (CD-GDD-ALIGN: APPROVED)
- item-material-system.md — Designed (CD-GDD-ALIGN: CONCERNS accepted)
- attribute-system.md — Designed (CD-GDD-ALIGN: APPROVED)
- resource-system.md — Designed (CD-GDD-ALIGN: REVISED)

## Next Step

继续 debug-console.md Section D (Formulas)。本系统数学性较弱，主要 formula 候选：
- 输出缓冲 clear+rebuild 耗时模型
- `event watch` 回调每帧累计耗时上限
- 命令分发延迟预算

如认为 Formulas 节"不适用"可写一句声明跳过，但 Edge Cases、Tuning Knobs、Acceptance Criteria 必须填实。

## Open Questions

None (session-level).

<!-- STATUS -->
Epic: MVP Systems Design
Feature: Debug Console
Task: Section A+B+C complete — resume from Section D (Formulas)
<!-- /STATUS -->
