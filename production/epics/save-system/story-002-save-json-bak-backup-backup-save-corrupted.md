# Story 002: 尝试加载 `save.json.bak`，若 backup 有效则从 backup 恢复，发布 `save.corrupted` 事件

> **Epic**: 存档系统
> **Status**: Ready
> **Layer**: Core Data
> **Type**: Config/Data
> **Manifest Version**: 2026-05-04

## Context

**GDD**: `design/gdd/save-system.md`
**Requirement**: `TR-save-system-001` — SaveManager persists namespaced provider data to a versioned JSON autosave with temp-write, backup recovery, and migrations.

**ADR Governing Implementation**: ADR-0006: 存档格式与版本迁移
**ADR Decision Summary**: Implement `SaveManager` as a global Autoload that owns a provider registry. Each persistent system registers `save_fn() -> Dictionary` and `restore_fn(data: Dictionary) -> void` under a namespace. SaveManager writes a JSON save to `user://save/save.json` through a temporary file and keeps `save.json.bak` for recovery.

**Engine**: Godot 4.6.2 | **Risk**: MEDIUM
**Engine Notes**: ADR-0006 status is Accepted; verify any Godot 4.6.2 behavior named by the ADR before closing the story.

**Control Manifest Rules (this layer)**:
- Required: **Use JSON files under `res://assets/data/` as the MVP configuration source** — source: ADR-0005
- Required: **Keep DataConfig schema-agnostic; consumers parse BigNumber strings themselves** — source: ADR-0005
- Required: **Keep all MVP config tables resident in DataConfig memory after startup load** — source: ADR-0005
- Required: **Use SaveManager provider callbacks by namespace for persistence** — source: ADR-0006
- Forbidden: **Never use Godot Resource files as the MVP content format** — source: ADR-0005
- Forbidden: **Never write runtime player state through DataConfig** — source: ADR-0005
- Forbidden: **Never make SaveManager import or understand concrete system state types** — source: ADR-0006
- Guardrail: **DataConfig**: MVP load target <= 100 ms and cache <= 5 MB — source: ADR-0005
- Guardrail: **SaveManager**: MVP save/load target <= 20 ms and save object <= 50 KB — source: ADR-0006
- Guardrail: **ModifierEngine**: cached 1000 `get_multiplier()` calls target <= 1 ms — source: ADR-0007

---

## Acceptance Criteria

*From GDD `design/gdd/save-system.md`, scoped to this story:*

- [ ] GIVEN: `save.json` JSON 语法错误，**WHEN** 调用 `load_game()`，**THEN** 尝试加载 `save.json.bak`，若 backup 有效则从 backup 恢复，发布 `save.corrupted` 事件
- [ ] GIVEN: `save.json` 和 `save.json.bak` 都损坏，**WHEN** 调用 `load_game()`，**THEN** 游戏以默认状态开始，发布 `save.corrupted` 事件（`recovered_from_backup: false`）
- [ ] GIVEN: `save.json` 缺少 `meta` 顶层键，**WHEN** 调用 `load_game()`，**THEN** 视为格式错误，触发损坏恢复流程

---

## Implementation Notes

*Derived from ADR-0006 Implementation Guidelines:*

- Must save a JSON object with top-level `meta` and `systems`.
- Must use provider callbacks; SaveManager must not import concrete system state types.
- Must check `FileAccess.store_string()` and other `store_*` return values.
- Must write to a temp file before replacing the primary save.
- Must keep a backup save when backup is enabled.
- Must continue saving other namespaces when one provider returns invalid data.

---

## Out of Scope

- Story 001 covers the baseline contract for this epic; do not duplicate its setup work here.
- Story 003 covers the next acceptance group in this epic.

---

## QA Test Cases

*Written at story creation. The developer implements against these cases.*

- **AC**: GIVEN: `save.json` JSON 语法错误，**WHEN** 调用 `load_game()`，**THEN** 尝试加载 `save.json.bak`，若 backup 有效则从 backup 恢复，发布 `save.corrupted` 事件
  - Given: `save.json` JSON 语法错误
  - When: 调用 `load_game()`
  - Then: 尝试加载 `save.json.bak`，若 backup 有效则从 backup 恢复，发布 `save.corrupted` 事件
  - Edge cases: boundary, invalid, missing-data, and repeat-run variants from the GDD edge-case section

- **AC**: GIVEN: `save.json` 和 `save.json.bak` 都损坏，**WHEN** 调用 `load_game()`，**THEN** 游戏以默认状态开始，发布 `save.corrupted` 事件（`recovered_from_backup: false`）
  - Given: `save.json` 和 `save.json.bak` 都损坏
  - When: 调用 `load_game()`
  - Then: 游戏以默认状态开始，发布 `save.corrupted` 事件（`recovered_from_backup: false`）
  - Edge cases: boundary, invalid, missing-data, and repeat-run variants from the GDD edge-case section

- **AC**: GIVEN: `save.json` 缺少 `meta` 顶层键，**WHEN** 调用 `load_game()`，**THEN** 视为格式错误，触发损坏恢复流程
  - Given: `save.json` 缺少 `meta` 顶层键
  - When: 调用 `load_game()`
  - Then: 视为格式错误，触发损坏恢复流程
  - Edge cases: boundary, invalid, missing-data, and repeat-run variants from the GDD edge-case section

---

## Test Evidence

**Story Type**: Config/Data
**Required evidence**:
- `production/qa/smoke-save-system.md` — smoke check evidence

**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: Story 001 must be ready or done for shared test fixtures and baseline APIs
- Unlocks: Story 003
