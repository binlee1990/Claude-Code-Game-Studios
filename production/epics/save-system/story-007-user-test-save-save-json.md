# Story 007: 文件写入 `user://test_save/save.json`

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

- [x] GIVEN: 存档目录路径为 `"user://test_save/"`，**WHEN** 用该路径构造 SaveManager 并保存，**THEN** 文件写入 `user://test_save/save.json`
- [x] GIVEN: 15 个 provider 各返回 ~800 bytes 数据，**WHEN** 保存，**THEN** 文件大小 < 50 KB，保存耗时 < 20 ms
- [x] GIVEN: 对同一 namespace 重复调用 `register_provider()`，**WHEN** 保存，**THEN** 使用最后一次注册的回调，打印覆盖警告

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
- Story 008 covers the next acceptance group in this epic.

---

## QA Test Cases

*Written at story creation. The developer implements against these cases.*

- **AC**: GIVEN: 存档目录路径为 `"user://test_save/"`，**WHEN** 用该路径构造 SaveManager 并保存，**THEN** 文件写入 `user://test_save/save.json`
  - Given: 存档目录路径为 `"user://test_save/"`
  - When: 用该路径构造 SaveManager 并保存
  - Then: 文件写入 `user://test_save/save.json`
  - Edge cases: boundary, invalid, missing-data, and repeat-run variants from the GDD edge-case section

- **AC**: GIVEN: 15 个 provider 各返回 ~800 bytes 数据，**WHEN** 保存，**THEN** 文件大小 < 50 KB，保存耗时 < 20 ms
  - Given: 15 个 provider 各返回 ~800 bytes 数据
  - When: 保存
  - Then: 文件大小 < 50 KB，保存耗时 < 20 ms
  - Edge cases: boundary, invalid, missing-data, and repeat-run variants from the GDD edge-case section

- **AC**: GIVEN: 对同一 namespace 重复调用 `register_provider()`，**WHEN** 保存，**THEN** 使用最后一次注册的回调，打印覆盖警告
  - Given: 对同一 namespace 重复调用 `register_provider()`
  - When: 保存
  - Then: 使用最后一次注册的回调，打印覆盖警告
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
- Unlocks: Story 008

## 2026-05-04 Sprint Execution Evidence

- Sprint execution order: Sprint 4, story 19/20
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
