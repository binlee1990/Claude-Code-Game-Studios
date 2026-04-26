# Story 003: 语言偏好持久化 + 运行时切换

> **Epic**: Localization
> **Status**: Complete
> **Layer**: Foundation
> **Type**: Integration

> **Estimate**: 0.25 day

## Context

**GDD**: `design/gdd/localization-system.md`
**Dependencies**: LOC-001 + LOC-002 + SaveManager

## Acceptance Criteria

- [x] LOC-AC-12: 语言偏好保存到 SaveData（新增 `locale` 字段）和 settings payload
- [x] LOC-AC-13: 主菜单启动时从 settings/save 读取语言偏好，回退到 DEFAULT_LOCALE
- [x] LOC-AC-14: 切换语言后自动保存 locale preference

## Completion Notes — 2026-04-27

`SaveManager.save_locale_preference()` writes `user://saves/settings.tres` so language choice can persist even when no battle save exists. `load_game()` also restores locale from SaveData when available.

## Implementation Notes

1. 在 `SaveData` 添加 `@export var locale: String = ""`
2. 在 `SRPGLocalization` 添加 `static var current_locale: String = DEFAULT_LOCALE` 和 `set_locale()`
3. 所有 `translate()` 调用使用 `current_locale` 而非参数默认值
4. `capture_runtime_state()` 包含 `locale`
5. 加载时恢复 locale 并刷新 UI
