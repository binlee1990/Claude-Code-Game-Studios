# Story 001: `user://save/save.json` 包含 `meta` 和 `systems`，且 `systems.time_manager`

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

- [ ] GIVEN: 两个系统已注册 provider（`time_manager`、`resource_system`），**WHEN** 调用 `save_game()`，**THEN** `user://save/save.json` 包含 `meta` 和 `systems`，且 `systems.time_manager` 和 `systems.resource_system` 均为非空 Dictionary
- [ ] GIVEN: `save.json` 含有效存档数据，**WHEN** 调用 `load_game()`，**THEN** 所有已注册 provider 的 `restore_fn()` 被调用，参数为对应 namespace 的 Dictionary
- [ ] GIVEN: `save.json` 不存在，**WHEN** 调用 `load_game()`，**THEN** 所有 provider 的 `restore_fn()` 不被调用，游戏以默认状态开始，无错误

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

- Story 002 covers the next acceptance group in this epic.

---

## QA Test Cases

*Written at story creation. The developer implements against these cases.*

- **AC**: GIVEN: 两个系统已注册 provider（`time_manager`、`resource_system`），**WHEN** 调用 `save_game()`，**THEN** `user://save/save.json` 包含 `meta` 和 `systems`，且 `systems.time_manager` 和 `systems.resource_system` 均为非空 Dictionary
  - Given: 两个系统已注册 provider（`time_manager`、`resource_system`）
  - When: 调用 `save_game()`
  - Then: `user://save/save.json` 包含 `meta` 和 `systems`，且 `systems.time_manager` 和 `systems.resource_system` 均为非空 Dictionary
  - Edge cases: boundary, invalid, missing-data, and repeat-run variants from the GDD edge-case section

- **AC**: GIVEN: `save.json` 含有效存档数据，**WHEN** 调用 `load_game()`，**THEN** 所有已注册 provider 的 `restore_fn()` 被调用，参数为对应 namespace 的 Dictionary
  - Given: `save.json` 含有效存档数据
  - When: 调用 `load_game()`
  - Then: 所有已注册 provider 的 `restore_fn()` 被调用，参数为对应 namespace 的 Dictionary
  - Edge cases: boundary, invalid, missing-data, and repeat-run variants from the GDD edge-case section

- **AC**: GIVEN: `save.json` 不存在，**WHEN** 调用 `load_game()`，**THEN** 所有 provider 的 `restore_fn()` 不被调用，游戏以默认状态开始，无错误
  - Given: `save.json` 不存在
  - When: 调用 `load_game()`
  - Then: 所有 provider 的 `restore_fn()` 不被调用，游戏以默认状态开始，无错误
  - Edge cases: boundary, invalid, missing-data, and repeat-run variants from the GDD edge-case section

---

## Test Evidence

**Story Type**: Config/Data
**Required evidence**:
- `production/qa/smoke-save-system.md` — smoke check evidence

**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: None
- Unlocks: Story 002
