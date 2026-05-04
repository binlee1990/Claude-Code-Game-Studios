# Story 013: Performance / Memory

> **Epic**: 资源系统
> **Status**: Done
> **Layer**: Core Gameplay
> **Type**: Integration
> **Manifest Version**: 2026-05-04

## Context

**GDD**: `design/gdd/resource-system.md`
**Requirement**: `TR-resource-system-001` — ResourceSystem owns resource CRUD, BigNumber balances, caps, overflow events, reset scopes, batch_add, snapshot, and restore.

**ADR Governing Implementation**: ADR-0002: 事件总线架构
**ADR Decision Summary**: Use a global `EventBus` Autoload Node with string event names and `Dictionary` payloads. The bus dispatches events synchronously in the current frame. Exact subscriptions are the production path. Prefix pattern subscriptions exist only for debug tooling such as `event watch resource`. Coalesced events are allowed only for display refreshes where latest-state wins.

**Engine**: Godot 4.6.2 | **Risk**: HIGH
**Engine Notes**: ADR-0002 status is Accepted; verify any Godot 4.6.2 behavior named by the ADR before closing the story.

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

*From GDD `design/gdd/resource-system.md`, scoped to this story:*

- [x] GIVEN: `lingqi` has_cap=true，5 个订阅者，**WHEN** 单帧 100 次 `add("lingqi", BigNumber.from_int(1))`，**THEN** 总耗时 < 0.333 ms（帧预算）
- [x] GIVEN: MVP 5 资源已注册，changes 含 5 条增量，**WHEN** `batch_add(changes)`，**THEN** 总耗时 < 0.15 ms
- [x] GIVEN: `get_all_ids().size()==5`，**WHEN** 内存采样，**THEN** ResourceSystem 总占用 < 2 KB

---

## Implementation Notes

*Derived from ADR-0002 Implementation Guidelines:*

- Must define event names as constants; production code must not use untracked magic strings.
- Must use exact subscriptions for production UI and gameplay consumers.
- Must restrict `subscribe_pattern` to DebugConsole and similar diagnostics.
- Must reject empty prefix pattern subscriptions.
- Must validate `Callable.is_valid()` before delivery and remove invalid callables.
- Must defer subscribe/unsubscribe mutations until after current dispatch completes.

---

## Out of Scope

- Story 001 covers the baseline contract for this epic; do not duplicate its setup work here.

---

## QA Test Cases

*Written at story creation. The developer implements against these cases.*

- **AC**: GIVEN: `lingqi` has_cap=true，5 个订阅者，**WHEN** 单帧 100 次 `add("lingqi", BigNumber.from_int(1))`，**THEN** 总耗时 < 0.333 ms（帧预算）
  - Given: `lingqi` has_cap=true，5 个订阅者
  - When: 单帧 100 次 `add("lingqi", BigNumber.from_int(1))`
  - Then: 总耗时 < 0.333 ms（帧预算）
  - Edge cases: boundary, invalid, missing-data, and repeat-run variants from the GDD edge-case section

- **AC**: GIVEN: MVP 5 资源已注册，changes 含 5 条增量，**WHEN** `batch_add(changes)`，**THEN** 总耗时 < 0.15 ms
  - Given: MVP 5 资源已注册，changes 含 5 条增量
  - When: `batch_add(changes)`
  - Then: 总耗时 < 0.15 ms
  - Edge cases: boundary, invalid, missing-data, and repeat-run variants from the GDD edge-case section

- **AC**: GIVEN: `get_all_ids().size()==5`，**WHEN** 内存采样，**THEN** ResourceSystem 总占用 < 2 KB
  - Given: `get_all_ids().size()==5`
  - When: 内存采样
  - Then: ResourceSystem 总占用 < 2 KB
  - Edge cases: boundary, invalid, missing-data, and repeat-run variants from the GDD edge-case section

---

## Test Evidence

**Story Type**: Integration
**Required evidence**:
- `tests/integration/resource/performance-memory_test.gd` — must exist and pass

**Status**: [x] Executed 2026-05-04

---

## Dependencies

- Depends on: Story 001 must be ready or done for shared test fixtures and baseline APIs
- Unlocks: None

## 2026-05-04 Sprint Execution Evidence

- Sprint execution order: Sprint 5, story 13/20
- Sprint source: `production/sprints/sprint-5.md`
- QA plan: `production/qa/qa-plan-sprint-5-2026-05-04.md`
- Automated evidence: `reports/report_13/results.xml` (137 tests, 0 failures, 0 skipped, 0 flaky)
- QA gate evidence: `production/qa/evidence/sprint-5-qa-result-2026-05-04.md`
- Verdict: Done; acceptance criteria reviewed against implementation, runtime tests, and sprint QA plan evidence.
- QA-plan automated tests:
  - `tests/unit/resource_system/resource_system_crud_test.gd`
  - `tests/integration/resource_system/resource_system_state_test.gd`
  - `tests/unit/attribute_system/attribute_system_crud_test.gd`
  - `tests/integration/attribute_system/attribute_system_final_test.gd`
