# Story 001: 返回 `{"name": "史莱姆", "hp": "100"}`

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

- [ ] GIVEN: `assets/data/enemies.json` 含 `{"slime": {"name": "史莱姆", "hp": "100"}}`，**WHEN** 执行 `DataConfig.get("enemies", "slime")`，**THEN** 返回 `{"name": "史莱姆", "hp": "100"}`
- [ ] GIVEN: 表 `enemies` 已加载，**WHEN** 执行 `DataConfig.get("enemies", "nonexistent")`，**THEN** 返回 `null`，打印警告
- [ ] GIVEN: 表 `nonexistent` 未加载，**WHEN** 执行 `DataConfig.get("nonexistent", "any")`，**THEN** 返回 `null`，打印警告

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

- Story 002 covers the next acceptance group in this epic.

---

## QA Test Cases

*Written at story creation. The developer implements against these cases.*

- **AC**: GIVEN: `assets/data/enemies.json` 含 `{"slime": {"name": "史莱姆", "hp": "100"}}`，**WHEN** 执行 `DataConfig.get("enemies", "slime")`，**THEN** 返回 `{"name": "史莱姆", "hp": "100"}`
  - Given: `assets/data/enemies.json` 含 `{"slime": {"name": "史莱姆", "hp": "100"}}`
  - When: 执行 `DataConfig.get("enemies", "slime")`
  - Then: 返回 `{"name": "史莱姆", "hp": "100"}`
  - Edge cases: boundary, invalid, missing-data, and repeat-run variants from the GDD edge-case section

- **AC**: GIVEN: 表 `enemies` 已加载，**WHEN** 执行 `DataConfig.get("enemies", "nonexistent")`，**THEN** 返回 `null`，打印警告
  - Given: 表 `enemies` 已加载
  - When: 执行 `DataConfig.get("enemies", "nonexistent")`
  - Then: 返回 `null`，打印警告
  - Edge cases: boundary, invalid, missing-data, and repeat-run variants from the GDD edge-case section

- **AC**: GIVEN: 表 `nonexistent` 未加载，**WHEN** 执行 `DataConfig.get("nonexistent", "any")`，**THEN** 返回 `null`，打印警告
  - Given: 表 `nonexistent` 未加载
  - When: 执行 `DataConfig.get("nonexistent", "any")`
  - Then: 返回 `null`，打印警告
  - Edge cases: boundary, invalid, missing-data, and repeat-run variants from the GDD edge-case section

---

## Test Evidence

**Story Type**: Config/Data
**Required evidence**:
- `production/qa/smoke-data-config-system.md` — smoke check evidence

**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: None
- Unlocks: Story 002
