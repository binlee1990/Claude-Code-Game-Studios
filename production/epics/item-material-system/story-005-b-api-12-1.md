# Story 005: B. 查询 API（12 条） 1

> **Epic**: 物品/材料系统
> **Status**: Done
> **Layer**: Core Gameplay
> **Type**: Logic
> **Manifest Version**: 2026-05-04

## Context

**GDD**: `design/gdd/item-material-system.md`
**Requirement**: `TR-item-material-001` — ItemRegistry loads immutable item/material definitions from DataConfig and exposes query-only metadata APIs.

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

*From GDD `design/gdd/item-material-system.md`, scoped to this story:*

- [x] AC-B1: GIVEN ItemRegistry 已加载，WHEN `has_item("herb")`，THEN `true`，无警告
- [x] AC-B2: GIVEN ItemRegistry 已加载，WHEN `has_item("nonexistent")`，THEN `false`，不打印警告
- [x] AC-B3: GIVEN ItemRegistry 已加载，WHEN `get("nonexistent")`，THEN `{}` + 打印警告

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
- Story 006 covers the next acceptance group in this epic.

---

## QA Test Cases

*Written at story creation. The developer implements against these cases.*

- **AC**: AC-B1: GIVEN ItemRegistry 已加载，WHEN `has_item("herb")`，THEN `true`，无警告
  - Given: ItemRegistry 已加载
  - When: `has_item("herb")`
  - Then: `true`，无警告
  - Edge cases: boundary, invalid, missing-data, and repeat-run variants from the GDD edge-case section

- **AC**: AC-B2: GIVEN ItemRegistry 已加载，WHEN `has_item("nonexistent")`，THEN `false`，不打印警告
  - Given: ItemRegistry 已加载
  - When: `has_item("nonexistent")`
  - Then: `false`，不打印警告
  - Edge cases: boundary, invalid, missing-data, and repeat-run variants from the GDD edge-case section

- **AC**: AC-B3: GIVEN ItemRegistry 已加载，WHEN `get("nonexistent")`，THEN `{}` + 打印警告
  - Given: ItemRegistry 已加载
  - When: `get("nonexistent")`
  - Then: `{}` + 打印警告
  - Edge cases: boundary, invalid, missing-data, and repeat-run variants from the GDD edge-case section

---

## Test Evidence

**Story Type**: Logic
**Required evidence**:
- `tests/unit/item_material/b-api-12-1_test.gd` — must exist and pass

**Status**: [x] Executed 2026-05-04

---

## Dependencies

- Depends on: Story 001 must be ready or done for shared test fixtures and baseline APIs
- Unlocks: Story 006

## 2026-05-04 Sprint Execution Evidence

- Sprint execution order: Sprint 6, story 10/20
- Sprint source: `production/sprints/sprint-6.md`
- QA plan: `production/qa/qa-plan-sprint-6-2026-05-04.md`
- Automated evidence: `reports/report_13/results.xml` (137 tests, 0 failures, 0 skipped, 0 flaky)
- QA gate evidence: `production/qa/evidence/sprint-6-qa-result-2026-05-04.md`
- Verdict: Done; acceptance criteria reviewed against implementation, runtime tests, and sprint QA plan evidence.
- QA-plan automated tests:
  - `tests/unit/attribute_system/attribute_system_batch_snapshot_test.gd`
  - `tests/unit/item_registry/item_registry_load_test.gd`
  - `tests/unit/item_registry/item_registry_query_test.gd`
  - `tests/integration/item_registry/item_registry_lifecycle_test.gd`
  - `tests/performance/item_registry_performance_test.gd`
