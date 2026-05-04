# Story 003: 返回 `true`；再次调用 `unregister("abc")` 返回 `false`

> **Epic**: 修正器/倍率引擎
> **Status**: Done
> **Layer**: Core Data
> **Type**: Logic
> **Manifest Version**: 2026-05-04

## Context

**GDD**: `design/gdd/modifier-engine.md`
**Requirement**: `TR-modifier-engine-001` — ModifierEngine owns modifier registration, target naming, ADD and MULT pool stacking, cache invalidation, and expiry events.

**ADR Governing Implementation**: ADR-0007: 修正器叠加顺序
**ADR Decision Summary**: Use one `ModifierEngine` service with a three-stage pipeline: `base + add_sum`, then same-pool additive percentage multipliers, then cross-pool multiplication. MVP pools are `equipment`, `realm`, `zone`, and `buff`. Targets are strings such as `player.atk` and `lingqi_production`.

**Engine**: Godot 4.6.2 | **Risk**: LOW
**Engine Notes**: ADR-0007 status is Accepted; verify any Godot 4.6.2 behavior named by the ADR before closing the story.

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

*From GDD `design/gdd/modifier-engine.md`, scoped to this story:*

- [x] GIVEN: 注册修正器返回 id="abc"，**WHEN** 调用 `unregister("abc")`，**THEN** 返回 `true`；再次调用 `unregister("abc")` 返回 `false`
- [x] GIVEN: source="sword_001" 注册了 3 个修正器，**WHEN** 调用 `unregister_by_source("sword_001")`，**THEN** 返回 `3`，相关 target 修正器数量减少 3
- [x] GIVEN: 注册 value=NaN 的修正器，**WHEN** 调用 `register()`，**THEN** 返回空字符串 `""`，打印警告

---

## Implementation Notes

*Derived from ADR-0007 Implementation Guidelines:*

- Must apply modifiers in the order ADD, same-pool additive MULT, cross-pool multiplicative MULT.
- Must use `"{entity_id}.{attr_id}"` for attribute targets.
- Must use `"{resource_id}_production"` for production targets.
- Must cache clean target multiplier results and invalidate on register/unregister/expiry.
- Must emit `modifier_expired` when duration-based modifiers expire.
- Must not evaluate business-specific conditions in ModifierEngine.

---

## Out of Scope

- Story 001 covers the baseline contract for this epic; do not duplicate its setup work here.
- Story 004 covers the next acceptance group in this epic.

---

## QA Test Cases

*Written at story creation. The developer implements against these cases.*

- **AC**: GIVEN: 注册修正器返回 id="abc"，**WHEN** 调用 `unregister("abc")`，**THEN** 返回 `true`；再次调用 `unregister("abc")` 返回 `false`
  - Given: 注册修正器返回 id="abc"
  - When: 调用 `unregister("abc")`
  - Then: 返回 `true`；再次调用 `unregister("abc")` 返回 `false`
  - Edge cases: boundary, invalid, missing-data, and repeat-run variants from the GDD edge-case section

- **AC**: GIVEN: source="sword_001" 注册了 3 个修正器，**WHEN** 调用 `unregister_by_source("sword_001")`，**THEN** 返回 `3`，相关 target 修正器数量减少 3
  - Given: source="sword_001" 注册了 3 个修正器
  - When: 调用 `unregister_by_source("sword_001")`
  - Then: 返回 `3`，相关 target 修正器数量减少 3
  - Edge cases: boundary, invalid, missing-data, and repeat-run variants from the GDD edge-case section

- **AC**: GIVEN: 注册 value=NaN 的修正器，**WHEN** 调用 `register()`，**THEN** 返回空字符串 `""`，打印警告
  - Given: 注册 value=NaN 的修正器
  - When: 调用 `register()`
  - Then: 返回空字符串 `""`，打印警告
  - Edge cases: boundary, invalid, missing-data, and repeat-run variants from the GDD edge-case section

---

## Test Evidence

**Story Type**: Logic
**Required evidence**:
- `tests/unit/modifier_engine/true-unregister-abc-false_test.gd` — must exist and pass

**Status**: [x] Executed 2026-05-04

---

## Dependencies

- Depends on: Story 001 must be ready or done for shared test fixtures and baseline APIs
- Unlocks: Story 004

## 2026-05-04 Sprint Execution Evidence

- Sprint execution order: Sprint 4, story 8/20
- Sprint source: `production/sprints/sprint-4.md`
- QA plan: `production/qa/qa-plan-sprint-4-2026-05-04.md`
- Automated evidence: `reports/report_13/results.xml` (137 tests, 0 failures, 0 skipped, 0 flaky)
- QA gate evidence: `production/qa/evidence/sprint-4-qa-result-2026-05-04.md`
- Verdict: Done; acceptance criteria reviewed against implementation, runtime tests, and sprint QA plan evidence.
- QA-plan automated tests:
  - `tests/unit/formula_engine/formula_engine_edges_test.gd`
  - `tests/unit/modifier_engine/modifier_engine_test.gd`
  - `tests/unit/save_system/save_manager_collect_test.gd`
  - `tests/integration/save_system/save_manager_file_contract_test.gd`
