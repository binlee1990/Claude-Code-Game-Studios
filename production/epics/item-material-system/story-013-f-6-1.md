# Story 013: F. 性能（6 条） 1

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

- [x] AC-F1: 性能矩阵 — MVP 5 条数据规模下，WHEN 单帧内执行各 100 次操作，THEN 总耗时满足：`get(id)` < 5 ms、`query_by_item_class` < 0.5 ms、`query_by_tag` < 0.5 ms、`peek_field` < 1 ms（公式 1/2/3a/3b 上限 × 100）
- [x] AC-F2: GIVEN mock items 含 5 条物品，WHEN 启动加载完成（含 DataConfig 调用），THEN 总加载耗时 < 5 ms
- [x] AC-F3: GIVEN MVP 5 条物品已加载，WHEN 用 `OS.get_static_memory_usage()` 差值采样，THEN ItemRegistry 净增内存 < 5 KB。**注**：跨平台/跨 GC 时机的绝对值波动较大，本 AC 仅作为 ADVISORY，限定运行环境为 Linux headless CI + 固定 GC 触发；非该环境下视为 informational

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
- Story 014 covers the next acceptance group in this epic.

---

## QA Test Cases

*Written at story creation. The developer implements against these cases.*

- **AC**: AC-F1: 性能矩阵 — MVP 5 条数据规模下，WHEN 单帧内执行各 100 次操作，THEN 总耗时满足：`get(id)` < 5 ms、`query_by_item_class` < 0.5 ms、`query_by_tag` < 0.5 ms、`peek_field` < 1 ms（公式 1/2/3a/3b 上限 × 100）
  - Given: the story preconditions from the linked GDD are set up
  - When: the behavior under this acceptance criterion is exercised
  - Then: AC-F1: 性能矩阵 — MVP 5 条数据规模下，WHEN 单帧内执行各 100 次操作，THEN 总耗时满足：`get(id)` < 5 ms、`query_by_item_class` < 0.5 ms、`query_by_tag` < 0.5 ms、`peek_field` < 1 ms（公式 1/2/3a/3b 上限 × 100）
  - Edge cases: boundary, invalid, missing-data, and repeat-run variants from the GDD edge-case section

- **AC**: AC-F2: GIVEN mock items 含 5 条物品，WHEN 启动加载完成（含 DataConfig 调用），THEN 总加载耗时 < 5 ms
  - Given: mock items 含 5 条物品
  - When: 启动加载完成（含 DataConfig 调用）
  - Then: 总加载耗时 < 5 ms
  - Edge cases: boundary, invalid, missing-data, and repeat-run variants from the GDD edge-case section

- **AC**: AC-F3: GIVEN MVP 5 条物品已加载，WHEN 用 `OS.get_static_memory_usage()` 差值采样，THEN ItemRegistry 净增内存 < 5 KB。**注**：跨平台/跨 GC 时机的绝对值波动较大，本 AC 仅作为 ADVISORY，限定运行环境为 Linux headless CI + 固定 GC 触发；非该环境下视为 informational
  - Given: MVP 5 条物品已加载
  - When: 用 `OS.get_static_memory_usage()` 差值采样
  - Then: ItemRegistry 净增内存 < 5 KB。注：跨平台/跨 GC 时机的绝对值波动较大，本 AC 仅作为 ADVISORY，限定运行环境为 Linux headless CI + 固定 GC 触发；非该环境下视为 informational
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
- Unlocks: Story 014

## 2026-05-04 Sprint Execution Evidence

- Sprint execution order: Sprint 6, story 18/20
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
