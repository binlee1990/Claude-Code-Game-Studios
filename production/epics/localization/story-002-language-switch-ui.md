# Story 002: 语言切换 UI

> **Epic**: Localization
> **Status**: Planning
> **Layer**: Foundation
> **Type**: UI

> **Estimate**: 0.25 day

## Context

**GDD**: `design/gdd/localization-system.md`
**Dependencies**: LOC-001（字符串迁移完成）

## Acceptance Criteria

- [ ] LOC-AC-9: 主菜单显示语言切换按钮（"语言 / Language"）
- [ ] LOC-AC-10: 点击后弹出选项（中文 / English），选择后即时切换
- [ ] LOC-AC-11: 切换后当前屏幕所有文本立即更新

## Implementation Notes

在 main_menu.gd 中添加语言切换按钮，点击后切换 `SRPGLocalization.DEFAULT_LOCALE`（或使用全局状态），
然后刷新当前屏幕所有 translate 调用。

需要一个全局 `current_locale` 状态（不是静态 DEFAULT_LOCALE），以便运行时切换。
