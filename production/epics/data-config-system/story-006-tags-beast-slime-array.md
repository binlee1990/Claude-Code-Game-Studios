# Story 006: `tags` 为 `["beast", "slime"]`（Array 类型）

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

- [x] GIVEN: JSON 含数组字段 `{"slime": {"tags": ["beast", "slime"]}}`，**WHEN** 执行 `get("enemies", "slime")`，**THEN** `tags` 为 `["beast", "slime"]`（Array 类型）
- [x] GIVEN: DataConfig 新建未调用 `load_all()`，**WHEN** 调用 `is_loaded()`，**THEN** 返回 `false`；调用 `load_all()` 后再次调用 `is_loaded()`，**THEN** 返回 `true`（无论加载过程中是否有单表失败）

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

---

## QA Test Cases

*Written at story creation. The developer implements against these cases.*

- **AC**: GIVEN: JSON 含数组字段 `{"slime": {"tags": ["beast", "slime"]}}`，**WHEN** 执行 `get("enemies", "slime")`，**THEN** `tags` 为 `["beast", "slime"]`（Array 类型）
  - Given: JSON 含数组字段 `{"slime": {"tags": ["beast", "slime"]}}`
  - When: 执行 `get("enemies", "slime")`
  - Then: `tags` 为 `["beast", "slime"]`（Array 类型）
  - Edge cases: boundary, invalid, missing-data, and repeat-run variants from the GDD edge-case section

- **AC**: GIVEN: DataConfig 新建未调用 `load_all()`，**WHEN** 调用 `is_loaded()`，**THEN** 返回 `false`；调用 `load_all()` 后再次调用 `is_loaded()`，**THEN** 返回 `true`（无论加载过程中是否有单表失败）
  - Given: DataConfig 新建未调用 `load_all()`
  - When: 调用 `is_loaded()`
  - Then: 返回 `false`；调用 `load_all()` 后再次调用 `is_loaded()`，THEN 返回 `true`（无论加载过程中是否有单表失败）
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
- Unlocks: None

## 2026-05-04 Sprint Execution Evidence

- Sprint execution order: Sprint 3, story 15/20
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
