# Story 010: threshold 钳位到 `1.0`，打印警告

> **Epic**: 公式引擎
> **Status**: Done
> **Layer**: Core Data
> **Type**: Logic
> **Manifest Version**: 2026-05-04

## Context

**GDD**: `design/gdd/formula-engine.md`
**Requirement**: `TR-formula-engine-001` — FormulaEngine evaluates bounded cached float expressions and safe helper functions for growth, combat, and balance formulas.

**ADR Governing Implementation**: ADR-0013: FormulaEngine 表达式 DSL 深度
**ADR Decision Summary**: Implement a bounded expression evaluator, not a general-purpose DSL. It supports arithmetic, variables, selected safe functions, boolean-to-float comparisons, simple ternary-style conditionals where specified by GDD, and formula caching. The evaluator returns `float`; systems convert to/from BigNumber where appropriate.

**Engine**: Godot 4.6.2 | **Risk**: LOW
**Engine Notes**: ADR-0013 status is Accepted; verify any Godot 4.6.2 behavior named by the ADR before closing the story.

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

*From GDD `design/gdd/formula-engine.md`, scoped to this story:*

- [x] GIVEN: `softcap(200, -5, 0.5)`，**WHEN** 求值，**THEN** threshold 钳位到 `1.0`，打印警告
- [x] GIVEN: `softcap(200, 100, 2.0)`，**WHEN** 求值，**THEN** power 钳位到 `1.0`，结果为 `200.0`（等效无软上限）
- [x] GIVEN: 上下文为空字典 `{}`，**WHEN** 对无变量公式 `"42 * 2"` 求值，**THEN** 结果为 `84.0`

---

## Implementation Notes

*Derived from ADR-0013 Implementation Guidelines:*

- Must return `float` results from FormulaEngine.
- Must not execute arbitrary GDScript or external code.
- Must bound expression length and clamp invalid softcap parameters.
- Must return `0.0` with warnings for invalid expressions, divide-by-zero, NaN, or Inf.
- Must cache parsed formulas and expose invalidation.
- Must keep BigNumber absolute-value math in callers, not inside the formula DSL except through explicit conversions owned by callers.

---

## Out of Scope

- Story 001 covers the baseline contract for this epic; do not duplicate its setup work here.

---

## QA Test Cases

*Written at story creation. The developer implements against these cases.*

- **AC**: GIVEN: `softcap(200, -5, 0.5)`，**WHEN** 求值，**THEN** threshold 钳位到 `1.0`，打印警告
  - Given: `softcap(200, -5, 0.5)`
  - When: 求值
  - Then: threshold 钳位到 `1.0`，打印警告
  - Edge cases: boundary, invalid, missing-data, and repeat-run variants from the GDD edge-case section

- **AC**: GIVEN: `softcap(200, 100, 2.0)`，**WHEN** 求值，**THEN** power 钳位到 `1.0`，结果为 `200.0`（等效无软上限）
  - Given: `softcap(200, 100, 2.0)`
  - When: 求值
  - Then: power 钳位到 `1.0`，结果为 `200.0`（等效无软上限）
  - Edge cases: boundary, invalid, missing-data, and repeat-run variants from the GDD edge-case section

- **AC**: GIVEN: 上下文为空字典 `{}`，**WHEN** 对无变量公式 `"42 * 2"` 求值，**THEN** 结果为 `84.0`
  - Given: 上下文为空字典 `{}`
  - When: 对无变量公式 `"42 * 2"` 求值
  - Then: 结果为 `84.0`
  - Edge cases: boundary, invalid, missing-data, and repeat-run variants from the GDD edge-case section

---

## Test Evidence

**Story Type**: Logic
**Required evidence**:
- `tests/unit/formula_engine/threshold-1-0_test.gd` — must exist and pass

**Status**: [x] Executed 2026-05-04

---

## Dependencies

- Depends on: Story 001 must be ready or done for shared test fixtures and baseline APIs
- Unlocks: None

## 2026-05-04 Sprint Execution Evidence

- Sprint execution order: Sprint 4, story 5/20
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
