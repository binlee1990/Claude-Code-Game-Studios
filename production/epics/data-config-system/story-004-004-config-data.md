# Story 004: 后者覆盖前者，打印警告

> **Epic**: 数据配置系统
> **Status**: Done
> **Layer**: Core Data
> **Type**: Config/Data
> **Manifest Version**: 2026-05-04

## Context

**GDD**: `design/gdd/data-config-system.md`
**Requirement**: `TR-data-config-001` — DataConfig loads MVP JSON tables, keeps a schema-agnostic memory cache, and exposes read-only table/record/query access.

**ADR Governing Implementation**: ADR-0005: 数据配置加载策略
**ADR Decision Summary**: Implement `DataConfig` as a `RefCounted` service held by an Autoload host. It scans JSON files under `res://assets/data/`, parses them with Godot JSON APIs, stores raw dictionaries in memory, and returns raw values to consumers. BigNumber conversion is performed by consumers according to their schemas.

**Engine**: Godot 4.6.2 | **Risk**: MEDIUM
**Engine Notes**: ADR-0005 status is Accepted; verify any Godot 4.6.2 behavior named by the ADR before closing the story.

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

*From GDD `design/gdd/data-config-system.md`, scoped to this story:*

- [x] GIVEN: 同一表内有重复 ID `"slime"`，**WHEN** 加载完成，**THEN** 后者覆盖前者，打印警告
- [x] GIVEN: 10 张表各 200 条记录，**WHEN** 执行 `load_all()`，**THEN** 总耗时 < 100 ms，总内存 < 5 MB
- [x] GIVEN: `HOT_RELOAD_ENABLED = true`，**WHEN** 修改 `enemies.json` 后执行 `reload_table("enemies")`，**THEN** 后续 `get("enemies", ...)` 返回新数据

---

## Implementation Notes

*Derived from ADR-0005 Implementation Guidelines:*

- Must use JSON files in `res://assets/data/` for MVP configuration.
- Must not use Godot Resource files as the MVP content format.
- Must keep DataConfig schema-agnostic; consumers parse BigNumber strings themselves.
- Must keep all loaded tables in memory for MVP.
- Must allow one failed table to degrade to an empty table without stopping other tables.
- Must restrict `reload_table` and `reload_all` to debug builds.

---

## Out of Scope

- Story 001 covers the baseline contract for this epic; do not duplicate its setup work here.
- Story 005 covers the next acceptance group in this epic.

---

## QA Test Cases

*Written at story creation. The developer implements against these cases.*

- **AC**: GIVEN: 同一表内有重复 ID `"slime"`，**WHEN** 加载完成，**THEN** 后者覆盖前者，打印警告
  - Given: 同一表内有重复 ID `"slime"`
  - When: 加载完成
  - Then: 后者覆盖前者，打印警告
  - Edge cases: boundary, invalid, missing-data, and repeat-run variants from the GDD edge-case section

- **AC**: GIVEN: 10 张表各 200 条记录，**WHEN** 执行 `load_all()`，**THEN** 总耗时 < 100 ms，总内存 < 5 MB
  - Given: 10 张表各 200 条记录
  - When: 执行 `load_all()`
  - Then: 总耗时 < 100 ms，总内存 < 5 MB
  - Edge cases: boundary, invalid, missing-data, and repeat-run variants from the GDD edge-case section

- **AC**: GIVEN: `HOT_RELOAD_ENABLED = true`，**WHEN** 修改 `enemies.json` 后执行 `reload_table("enemies")`，**THEN** 后续 `get("enemies", ...)` 返回新数据
  - Given: `HOT_RELOAD_ENABLED = true`
  - When: 修改 `enemies.json` 后执行 `reload_table("enemies")`
  - Then: 后续 `get("enemies", ...)` 返回新数据
  - Edge cases: boundary, invalid, missing-data, and repeat-run variants from the GDD edge-case section

---

## Test Evidence

**Story Type**: Config/Data
**Required evidence**:
- `production/qa/smoke-data-config-system.md` — smoke check evidence

**Status**: [x] Executed 2026-05-04

---

## Dependencies

- Depends on: Story 001 must be ready or done for shared test fixtures and baseline APIs
- Unlocks: Story 005

## 2026-05-04 Sprint Execution Evidence

- Sprint execution order: Sprint 3, story 13/20
- Sprint source: `production/sprints/sprint-3.md`
- QA plan: `production/qa/qa-plan-sprint-3-2026-05-04.md`
- Automated evidence: `reports/report_13/results.xml` (137 tests, 0 failures, 0 skipped, 0 flaky)
- QA gate evidence: `production/qa/evidence/sprint-3-qa-result-2026-05-04.md`
- Verdict: Done; acceptance criteria reviewed against implementation, runtime tests, and sprint QA plan evidence.
- QA-plan automated tests:
  - `tests/unit/time_manager/time_manager_logic_test.gd`
  - `tests/unit/number_formatting/number_formatter_test.gd`
  - `tests/performance/number_formatter_performance_test.gd`
  - `tests/unit/data_config/data_config_test.gd`
  - `tests/unit/formula_engine/formula_engine_test.gd`
