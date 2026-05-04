# Story 005: 迁移中止，不覆盖原文件，回退到 backup 或新游戏

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

- [x] GIVEN: 迁移脚本 v1→v2 返回 `false`，**WHEN** 加载，**THEN** 迁移中止，不覆盖原文件，回退到 backup 或新游戏
- [x] GIVEN: `BACKUP_ENABLED = true`，**WHEN** 调用 `save_game()`，**THEN** 保存成功后 `save.json.bak` 包含上一次的存档数据
- [x] GIVEN: 正在执行保存操作，**WHEN** 再次调用 `save_game()`，**THEN** 忽略重复请求，打印调试日志

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
- Story 006 covers the next acceptance group in this epic.

---

## QA Test Cases

*Written at story creation. The developer implements against these cases.*

- **AC**: GIVEN: 迁移脚本 v1→v2 返回 `false`，**WHEN** 加载，**THEN** 迁移中止，不覆盖原文件，回退到 backup 或新游戏
  - Given: 迁移脚本 v1→v2 返回 `false`
  - When: 加载
  - Then: 迁移中止，不覆盖原文件，回退到 backup 或新游戏
  - Edge cases: boundary, invalid, missing-data, and repeat-run variants from the GDD edge-case section

- **AC**: GIVEN: `BACKUP_ENABLED = true`，**WHEN** 调用 `save_game()`，**THEN** 保存成功后 `save.json.bak` 包含上一次的存档数据
  - Given: `BACKUP_ENABLED = true`
  - When: 调用 `save_game()`
  - Then: 保存成功后 `save.json.bak` 包含上一次的存档数据
  - Edge cases: boundary, invalid, missing-data, and repeat-run variants from the GDD edge-case section

- **AC**: GIVEN: 正在执行保存操作，**WHEN** 再次调用 `save_game()`，**THEN** 忽略重复请求，打印调试日志
  - Given: 正在执行保存操作
  - When: 再次调用 `save_game()`
  - Then: 忽略重复请求，打印调试日志
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
- Unlocks: Story 006

## 2026-05-04 Sprint Execution Evidence

- Sprint execution order: Sprint 4, story 17/20
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
