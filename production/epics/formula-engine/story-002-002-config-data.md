# Story 002: 多余变量被忽略，结果正确

> **Epic**: 公式引擎
> **Status**: Ready
> **Layer**: Core Data
> **Type**: Config/Data
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

- [ ] GIVEN: 公式声明变量 `["atk"]`，**WHEN** 上下文传入 `{"atk": 100.0, "spd": 50.0, "luck": 3.0}`，**THEN** 多余变量被忽略，结果正确
- [ ] GIVEN: 不存在的公式 ID `"nonexistent"`，**WHEN** 执行 `evaluate("nonexistent", {})`，**THEN** 返回 `0.0`，打印警告
- [ ] GIVEN: 空表达式公式，**WHEN** 执行 `evaluate`，**THEN** 返回 `0.0`，打印警告

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
- Story 003 covers the next acceptance group in this epic.

---

## QA Test Cases

*Written at story creation. The developer implements against these cases.*

- **AC**: GIVEN: 公式声明变量 `["atk"]`，**WHEN** 上下文传入 `{"atk": 100.0, "spd": 50.0, "luck": 3.0}`，**THEN** 多余变量被忽略，结果正确
  - Given: 公式声明变量 `["atk"]`
  - When: 上下文传入 `{"atk": 100.0, "spd": 50.0, "luck": 3.0}`
  - Then: 多余变量被忽略，结果正确
  - Edge cases: boundary, invalid, missing-data, and repeat-run variants from the GDD edge-case section

- **AC**: GIVEN: 不存在的公式 ID `"nonexistent"`，**WHEN** 执行 `evaluate("nonexistent", {})`，**THEN** 返回 `0.0`，打印警告
  - Given: 不存在的公式 ID `"nonexistent"`
  - When: 执行 `evaluate("nonexistent", {})`
  - Then: 返回 `0.0`，打印警告
  - Edge cases: boundary, invalid, missing-data, and repeat-run variants from the GDD edge-case section

- **AC**: GIVEN: 空表达式公式，**WHEN** 执行 `evaluate`，**THEN** 返回 `0.0`，打印警告
  - Given: 空表达式公式
  - When: 执行 `evaluate`
  - Then: 返回 `0.0`，打印警告
  - Edge cases: boundary, invalid, missing-data, and repeat-run variants from the GDD edge-case section

---

## Test Evidence

**Story Type**: Config/Data
**Required evidence**:
- `production/qa/smoke-formula-engine.md` — smoke check evidence

**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: Story 001 must be ready or done for shared test fixtures and baseline APIs
- Unlocks: Story 003
