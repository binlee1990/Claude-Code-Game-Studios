# Story 012: E. 热重载（4 条） 2

> **Epic**: 物品/材料系统
> **Status**: Done
> **Layer**: Core Gameplay
> **Type**: Config/Data
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

- [x] AC-E3: GIVEN 初始加载含 id=`"old_item"`，reload 后 items.json 移除该 id，WHEN reload 完成，THEN：① `push_warning` 内容含 `"old_item"` 出现在差分列表中；② `has_item("old_item") == false`
- [x] AC-E4: GIVEN 初始加载 id=`"x"` 的 `item_class="resource_material"`，reload 后同一 id 的 `item_class` 改为 `"consumable"`，WHEN reload 完成，THEN：① `query_by_item_class("resource_material")` 返回数组不含 `"x"`；② `query_by_item_class("consumable")` 返回数组含 `"x"`

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
- Story 013 covers the next acceptance group in this epic.

---

## QA Test Cases

*Written at story creation. The developer implements against these cases.*

- **AC**: AC-E3: GIVEN 初始加载含 id=`"old_item"`，reload 后 items.json 移除该 id，WHEN reload 完成，THEN：① `push_warning` 内容含 `"old_item"` 出现在差分列表中；② `has_item("old_item") == false`
  - Given: 初始加载含 id=`"old_item"`，reload 后 items.json 移除该 id
  - When: reload 完成
  - Then: ① `push_warning` 内容含 `"old_item"` 出现在差分列表中；② `has_item("old_item") == false`
  - Edge cases: boundary, invalid, missing-data, and repeat-run variants from the GDD edge-case section

- **AC**: AC-E4: GIVEN 初始加载 id=`"x"` 的 `item_class="resource_material"`，reload 后同一 id 的 `item_class` 改为 `"consumable"`，WHEN reload 完成，THEN：① `query_by_item_class("resource_material")` 返回数组不含 `"x"`；② `query_by_item_class("consumable")` 返回数组含 `"x"`
  - Given: 初始加载 id=`"x"` 的 `item_class="resource_material"`，reload 后同一 id 的 `item_class` 改为 `"consumable"`
  - When: reload 完成
  - Then: ① `query_by_item_class("resource_material")` 返回数组不含 `"x"`；② `query_by_item_class("consumable")` 返回数组含 `"x"`
  - Edge cases: boundary, invalid, missing-data, and repeat-run variants from the GDD edge-case section

---

## Test Evidence

**Story Type**: Config/Data
**Required evidence**:
- `production/qa/smoke-item-material-system.md` — smoke check evidence

**Status**: [x] Executed 2026-05-04

---

## Dependencies

- Depends on: Story 001 must be ready or done for shared test fixtures and baseline APIs
- Unlocks: Story 013

## 2026-05-04 Sprint Execution Evidence

- Sprint execution order: Sprint 6, story 17/20
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
