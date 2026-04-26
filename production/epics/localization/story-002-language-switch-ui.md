# Story 002: 语言切换 UI

> **Epic**: Localization
> **Status**: Complete
> **Layer**: Foundation
> **Type**: UI

> **Estimate**: 0.25 day

## Context

**GDD**: `design/gdd/localization-system.md`
**Dependencies**: LOC-001（字符串迁移完成）

## Acceptance Criteria

- [x] LOC-AC-9: 主菜单显示语言切换按钮（`LanguageButton`）
- [x] LOC-AC-10: 点击后在 `zh_CN` / `en_US` 间切换
- [x] LOC-AC-11: 切换后当前主菜单和 Credits 文本立即更新

## Completion Notes — 2026-04-27

Sprint-005 uses a single toggle button instead of a modal option popup. This is a simpler equivalent interaction for two supported locales and is covered by `tests/integration/ui/main_menu_localization_credits_test.gd`.

## Implementation Notes

在 main_menu.gd 中添加语言切换按钮，点击后切换 `SRPGLocalization.DEFAULT_LOCALE`（或使用全局状态），
然后刷新当前屏幕所有 translate 调用。

需要一个全局 `current_locale` 状态（不是静态 DEFAULT_LOCALE），以便运行时切换。
