# Story 011: Performance / Memory 1

> **Epic**: 属性系统
> **Status**: Done
> **Layer**: Core Gameplay
> **Type**: Logic
> **Manifest Version**: 2026-05-04

## Context

**GDD**: `design/gdd/attribute-system.md`
**Requirement**: `TR-attribute-system-001` — AttributeSystem owns entity attribute base values, final-value queries through ModifierEngine, events, snapshot, and restore.

**ADR Governing Implementation**: ADR-0001: BigNumber 实现策略
**ADR Decision Summary**: Implement `BigNumber` as an immutable `RefCounted` GDScript value type using `mantissa: float` and `exponent: int`. Normalized non-zero values keep `mantissa` in `[1.0, 10.0)` and `exponent` in `[0, 308]`. Zero is `{0.0, 0}`. Overflow saturates to `MAX`; negative or sub-unit absolute results clamp to `ZERO`.

**Engine**: Godot 4.6.2 | **Risk**: HIGH
**Engine Notes**: ADR-0001 status is Accepted; verify any Godot 4.6.2 behavior named by the ADR before closing the story.

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

*From GDD `design/gdd/attribute-system.md`, scoped to this story:*

- [x] GIVEN: 226 实体已注册，每实体 6 属性，5 订阅者监听，**WHEN** 单帧 50 次 `get_final`，**THEN** 总耗时 < 0.667 ms（帧预算）
- [x] GIVEN: 1 主角，3 订阅者监听，**WHEN** 单帧 5 次 `set_base`（不同 attr），**THEN** 总耗时 < 0.155 ms
- [x] GIVEN: 启动时分帧批量注册 226 实体 × 7 属性，**WHEN** 完成，**THEN** 任一帧耗时 < 2.5 ms（不超过帧预算的 15%）

---

## Implementation Notes

*Derived from ADR-0001 Implementation Guidelines:*

- Must store game absolute quantities as `BigNumber`, not raw `int` or `float`.
- Must return a new `BigNumber` from every arithmetic method.
- Must serialize as `{"m": mantissa, "e": exponent}`.
- Must clamp negative results and sub-unit absolute results to `ZERO`.
- Must treat division by zero and overflow as saturated `MAX`.
- Must not introduce GDExtension until the GDScript performance gate fails with measured evidence.

---

## Out of Scope

- Story 001 covers the baseline contract for this epic; do not duplicate its setup work here.
- Story 012 covers the next acceptance group in this epic.

---

## QA Test Cases

*Written at story creation. The developer implements against these cases.*

- **AC**: GIVEN: 226 实体已注册，每实体 6 属性，5 订阅者监听，**WHEN** 单帧 50 次 `get_final`，**THEN** 总耗时 < 0.667 ms（帧预算）
  - Given: 226 实体已注册，每实体 6 属性，5 订阅者监听
  - When: 单帧 50 次 `get_final`
  - Then: 总耗时 < 0.667 ms（帧预算）
  - Edge cases: boundary, invalid, missing-data, and repeat-run variants from the GDD edge-case section

- **AC**: GIVEN: 1 主角，3 订阅者监听，**WHEN** 单帧 5 次 `set_base`（不同 attr），**THEN** 总耗时 < 0.155 ms
  - Given: 1 主角，3 订阅者监听
  - When: 单帧 5 次 `set_base`（不同 attr）
  - Then: 总耗时 < 0.155 ms
  - Edge cases: boundary, invalid, missing-data, and repeat-run variants from the GDD edge-case section

- **AC**: GIVEN: 启动时分帧批量注册 226 实体 × 7 属性，**WHEN** 完成，**THEN** 任一帧耗时 < 2.5 ms（不超过帧预算的 15%）
  - Given: 启动时分帧批量注册 226 实体 × 7 属性
  - When: 完成
  - Then: 任一帧耗时 < 2.5 ms（不超过帧预算的 15%）
  - Edge cases: boundary, invalid, missing-data, and repeat-run variants from the GDD edge-case section

---

## Test Evidence

**Story Type**: Logic
**Required evidence**:
- `tests/unit/attribute/performance-memory-1_test.gd` — must exist and pass

**Status**: [x] Executed 2026-05-04

---

## Dependencies

- Depends on: Story 001 must be ready or done for shared test fixtures and baseline APIs
- Unlocks: Story 012

## 2026-05-04 Sprint Execution Evidence

- Sprint execution order: Sprint 6, story 4/20
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
