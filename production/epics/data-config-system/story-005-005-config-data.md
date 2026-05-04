# Story 005: 无操作

> **Epic**: 数据配置系统
> **Status**: Ready
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

- [ ] GIVEN: `HOT_RELOAD_ENABLED = false`，**WHEN** 执行 `reload_table("enemies")`，**THEN** 无操作
- [ ] GIVEN: 数据目录路径为 `"res://test/fixtures/data/"`，**WHEN** 用该路径构造 DataConfig 并加载，**THEN** 从测试目录加载数据
- [ ] GIVEN: JSON 含嵌套对象 `{"boss": {"stats": {"atk": "500"}}}`，**WHEN** 执行 `get("enemies", "boss")`，**THEN** 返回含嵌套 Dictionary 的记录

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

- **AC**: GIVEN: `HOT_RELOAD_ENABLED = false`，**WHEN** 执行 `reload_table("enemies")`，**THEN** 无操作
  - Given: `HOT_RELOAD_ENABLED = false`
  - When: 执行 `reload_table("enemies")`
  - Then: 无操作
  - Edge cases: boundary, invalid, missing-data, and repeat-run variants from the GDD edge-case section

- **AC**: GIVEN: 数据目录路径为 `"res://test/fixtures/data/"`，**WHEN** 用该路径构造 DataConfig 并加载，**THEN** 从测试目录加载数据
  - Given: 数据目录路径为 `"res://test/fixtures/data/"`
  - When: 用该路径构造 DataConfig 并加载
  - Then: 从测试目录加载数据
  - Edge cases: boundary, invalid, missing-data, and repeat-run variants from the GDD edge-case section

- **AC**: GIVEN: JSON 含嵌套对象 `{"boss": {"stats": {"atk": "500"}}}`，**WHEN** 执行 `get("enemies", "boss")`，**THEN** 返回含嵌套 Dictionary 的记录
  - Given: JSON 含嵌套对象 `{"boss": {"stats": {"atk": "500"}}}`
  - When: 执行 `get("enemies", "boss")`
  - Then: 返回含嵌套 Dictionary 的记录
  - Edge cases: boundary, invalid, missing-data, and repeat-run variants from the GDD edge-case section

---

## Test Evidence

**Story Type**: Config/Data
**Required evidence**:
- `production/qa/smoke-data-config-system.md` — smoke check evidence

**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: Story 001 must be ready or done for shared test fixtures and baseline APIs
- Unlocks: Story 006
