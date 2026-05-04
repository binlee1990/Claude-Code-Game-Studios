# Story 008: 缓存清空，后续调用触发重新解析

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

- [ ] GIVEN: 缓存中有 50 个公式，**WHEN** 调用 `invalidate_all()`，**THEN** 缓存清空，后续调用触发重新解析
- [ ] GIVEN: `HOT_RELOAD_ENABLED = true`，**WHEN** 配置文件中公式表达式被修改并重新加载，**THEN** 新表达式生效
- [ ] GIVEN: 传入 int 值 `{"level": 5}`，**WHEN** 求值，**THEN** 自动转换为 float `5.0`，结果正确

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
- Story 009 covers the next acceptance group in this epic.

---

## QA Test Cases

*Written at story creation. The developer implements against these cases.*

- **AC**: GIVEN: 缓存中有 50 个公式，**WHEN** 调用 `invalidate_all()`，**THEN** 缓存清空，后续调用触发重新解析
  - Given: 缓存中有 50 个公式
  - When: 调用 `invalidate_all()`
  - Then: 缓存清空，后续调用触发重新解析
  - Edge cases: boundary, invalid, missing-data, and repeat-run variants from the GDD edge-case section

- **AC**: GIVEN: `HOT_RELOAD_ENABLED = true`，**WHEN** 配置文件中公式表达式被修改并重新加载，**THEN** 新表达式生效
  - Given: `HOT_RELOAD_ENABLED = true`
  - When: 配置文件中公式表达式被修改并重新加载
  - Then: 新表达式生效
  - Edge cases: boundary, invalid, missing-data, and repeat-run variants from the GDD edge-case section

- **AC**: GIVEN: 传入 int 值 `{"level": 5}`，**WHEN** 求值，**THEN** 自动转换为 float `5.0`，结果正确
  - Given: 传入 int 值 `{"level": 5}`
  - When: 求值
  - Then: 自动转换为 float `5.0`，结果正确
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
- Unlocks: Story 009
