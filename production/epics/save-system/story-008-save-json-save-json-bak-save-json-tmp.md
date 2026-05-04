# Story 008: 存在 `save.json` 和 `save.json.bak`，不存在 `save.json.tmp`（临时文件已清理）

> **Epic**: 存档系统
> **Status**: Done
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

- [x] GIVEN: 保存成功完成，**WHEN** 检查文件系统，**THEN** 存在 `save.json` 和 `save.json.bak`，不存在 `save.json.tmp`（临时文件已清理）
- [x] GIVEN: 两个 provider 已注册（`time_manager` 和 `resource_system`），**WHEN** 调用 `collect_save_data()`，**THEN** 返回的 Dictionary 包含 `meta` 与 `systems` 顶层键，且 `systems.time_manager` 和 `systems.resource_system` 均为非空 Dictionary，且 `user://save/save.json` 文件**未被创建或修改**
- [x] GIVEN: SaveManager 处于 Idle 状态，**WHEN** 调用 `is_saving()`，**THEN** 返回 `false`；启动 `save_game()` 后立即在同一帧内查询 `is_saving()`，**THEN** 返回 `true`；保存完成后再次查询，**THEN** 返回 `false`

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

---

## QA Test Cases

*Written at story creation. The developer implements against these cases.*

- **AC**: GIVEN: 保存成功完成，**WHEN** 检查文件系统，**THEN** 存在 `save.json` 和 `save.json.bak`，不存在 `save.json.tmp`（临时文件已清理）
  - Given: 保存成功完成
  - When: 检查文件系统
  - Then: 存在 `save.json` 和 `save.json.bak`，不存在 `save.json.tmp`（临时文件已清理）
  - Edge cases: boundary, invalid, missing-data, and repeat-run variants from the GDD edge-case section

- **AC**: GIVEN: 两个 provider 已注册（`time_manager` 和 `resource_system`），**WHEN** 调用 `collect_save_data()`，**THEN** 返回的 Dictionary 包含 `meta` 与 `systems` 顶层键，且 `systems.time_manager` 和 `systems.resource_system` 均为非空 Dictionary，且 `user://save/save.json` 文件**未被创建或修改**
  - Given: 两个 provider 已注册（`time_manager` 和 `resource_system`）
  - When: 调用 `collect_save_data()`
  - Then: 返回的 Dictionary 包含 `meta` 与 `systems` 顶层键，且 `systems.time_manager` 和 `systems.resource_system` 均为非空 Dictionary，且 `user://save/save.json` 文件未被创建或修改
  - Edge cases: boundary, invalid, missing-data, and repeat-run variants from the GDD edge-case section

- **AC**: GIVEN: SaveManager 处于 Idle 状态，**WHEN** 调用 `is_saving()`，**THEN** 返回 `false`；启动 `save_game()` 后立即在同一帧内查询 `is_saving()`，**THEN** 返回 `true`；保存完成后再次查询，**THEN** 返回 `false`
  - Given: SaveManager 处于 Idle 状态
  - When: 调用 `is_saving()`
  - Then: 返回 `false`；启动 `save_game()` 后立即在同一帧内查询 `is_saving()`，THEN 返回 `true`；保存完成后再次查询，THEN 返回 `false`
  - Edge cases: boundary, invalid, missing-data, and repeat-run variants from the GDD edge-case section

---

## Test Evidence

**Story Type**: Config/Data
**Required evidence**:
- `production/qa/smoke-save-system.md` — smoke check evidence

**Status**: [x] Executed 2026-05-04

---

## Dependencies

- Depends on: Story 001 must be ready or done for shared test fixtures and baseline APIs
- Unlocks: None

## 2026-05-04 Sprint Execution Evidence

- Sprint execution order: Sprint 4, story 20/20
- Sprint source: `production/sprints/sprint-4.md`
- QA plan: `production/qa/qa-plan-sprint-4-2026-05-04.md`
- Automated evidence: `reports/report_13/results.xml` (137 tests, 0 failures, 0 skipped, 0 flaky)
- QA gate evidence: `production/qa/evidence/sprint-4-qa-result-2026-05-04.md`
- Verdict: Done; acceptance criteria reviewed against implementation, runtime tests, and sprint QA plan evidence.
- QA-plan automated tests:
  - `tests/unit/formula_engine/formula_engine_edges_test.gd`
  - `tests/unit/modifier_engine/modifier_engine_test.gd`
  - `tests/unit/save_system/save_manager_collect_test.gd`
  - `tests/integration/save_system/save_manager_file_contract_test.gd`
