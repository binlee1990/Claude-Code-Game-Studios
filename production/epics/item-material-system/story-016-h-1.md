# Story 016: H. 跨系统边界（1 条）

> **Epic**: 物品/材料系统
> **Status**: Done
> **Layer**: Core Gameplay
> **Type**: Integration
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

- [x] AC-H1: GIVEN ItemRegistry 注册集合 = `{a, b}`、ResourceSystem 注册集合 = `{b, c}`（部分重叠），WHEN 两者同时运行，THEN：① `ItemRegistry.has_item("c")==false`；② `ResourceSystem.has_resource("a")==false`；③ `ItemRegistry.get("c")=={}`；④ `ResourceSystem.get_value("a")==BigNumber.ZERO`；两者各自正常运行，互不报错

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
- Story 017 covers the next acceptance group in this epic.

---

## QA Test Cases

*Written at story creation. The developer implements against these cases.*

- **AC**: AC-H1: GIVEN ItemRegistry 注册集合 = `{a, b}`、ResourceSystem 注册集合 = `{b, c}`（部分重叠），WHEN 两者同时运行，THEN：① `ItemRegistry.has_item("c")==false`；② `ResourceSystem.has_resource("a")==false`；③ `ItemRegistry.get("c")=={}`；④ `ResourceSystem.get_value("a")==BigNumber.ZERO`；两者各自正常运行，互不报错
  - Given: ItemRegistry 注册集合 = `{a, b}`、ResourceSystem 注册集合 = `{b, c}`（部分重叠）
  - When: 两者同时运行
  - Then: ① `ItemRegistry.has_item("c")==false`；② `ResourceSystem.has_resource("a")==false`；③ `ItemRegistry.get("c")=={}`；④ `ResourceSystem.get_value("a")==BigNumber.ZERO`；两者各自正常运行，互不报错
  - Edge cases: boundary, invalid, missing-data, and repeat-run variants from the GDD edge-case section

---

## Test Evidence

**Story Type**: Integration
**Required evidence**:
- `tests/integration/item_material/h-1_test.gd` — must exist and pass

**Status**: [x] Executed 2026-05-04

---

## Dependencies

- Depends on: Story 001 must be ready or done for shared test fixtures and baseline APIs
- Unlocks: Story 017

## 2026-05-04 Sprint Execution Evidence

- Sprint execution order: Sprint 7, story 1/20
- Sprint source: `production/sprints/sprint-7.md`
- QA plan: `production/qa/qa-plan-sprint-7-2026-05-04.md`
- Automated evidence: `reports/report_13/results.xml` (137 tests, 0 failures, 0 skipped, 0 flaky)
- QA gate evidence: `production/qa/evidence/sprint-7-qa-result-2026-05-04.md`
- Verdict: Done; acceptance criteria reviewed against implementation, runtime tests, and sprint QA plan evidence.
- QA-plan automated tests:
  - `tests/integration/item_registry/item_registry_boundary_test.gd`
  - `tests/unit/output_multiplier_system/output_multiplier_system_config_test.gd`
  - `tests/unit/output_multiplier_system/output_multiplier_system_formula_test.gd`
  - `tests/integration/output_multiplier_system/output_multiplier_events_test.gd`
  - `tests/unit/debug_console/debug_console_command_test.gd`
  - `tests/integration/debug_console/debug_console_smoke_test.gd`
