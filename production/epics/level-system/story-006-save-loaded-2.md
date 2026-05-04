# Story 006: save.loaded 重建 2

> **Epic**: 等级系统
> **Status**: Done
> **Layer**: Feature
> **Type**: Integration
> **Manifest Version**: 2026-05-04

## Context

**GDD**: `design/gdd/level-system.md`
**Requirement**: `TR-level-system-001` — LevelSystem handles level/experience/realm progression using approved data, formulas, resource, modifier, event, and save boundaries.

**ADR Governing Implementation**: ADR-0013: FormulaEngine 表达式 DSL 深度
**ADR Decision Summary**: Implement a bounded expression evaluator, not a general-purpose DSL. It supports arithmetic, variables, selected safe functions, boolean-to-float comparisons, simple ternary-style conditionals where specified by GDD, and formula caching. The evaluator returns `float`; systems convert to/from BigNumber where appropriate.

**Engine**: Godot 4.6.2 | **Risk**: LOW
**Engine Notes**: ADR-0013 status is Accepted; verify any Godot 4.6.2 behavior named by the ADR before closing the story.

**Control Manifest Rules (this layer)**:
- Required: **Use CombatCalculator as the single damage-resolution service for online and offline combat** — source: ADR-0009
- Required: **Use RNGManager COMBAT and LOOT streams consistently for combat and drops** — source: ADR-0004, ADR-0009
- Required: **Aggregate offline combat/reward facts into a draft before settlement** — source: ADR-0009, ADR-0015
- Required: **Use OutputMultiplierSystem/ModifierEngine for production multipliers; ResourceSystem only receives settled amounts** — source: ADR-0007, ADR-0010
- Forbidden: **Never duplicate combat damage formulas inside OfflineCombatSimulation** — source: ADR-0009
- Forbidden: **Never let OfflineCombatSimulation call SemiAutoCombatSystem directly** — source: ADR-0009
- Forbidden: **Never let feature systems write resources by bypassing ResourceSystem APIs** — source: ADR-0010
- Guardrail: **Offline simulation**: chunk long deltas and profile before vertical slice — source: ADR-0015
- Guardrail: **Combat/offline equivalence**: fixed-seed online/offline replay tests are mandatory before Pre-Production prototype confidence — source: ADR-0009, ADR-0015

---

## Acceptance Criteria

*From GDD `design/gdd/level-system.md`, scoped to this story:*

- [x] GIVEN: snapshot 含 entity `"player"` 的 `realm = "unknown_realm"`（已被重命名或删除），**WHEN** `_on_save_loaded`，**THEN** 跳过 register，打印警告，entity 以无 realm modifier 状态运行
- [x] GIVEN: snapshot 含 `level=5, realm="jindan"`（不一致），**WHEN** `_on_save_loaded`，**THEN** 调 `_derive_realm(5)` 派生为 "fanren"，覆盖存档 realm 字段，按 fanren 处理（不注册 modifier）

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
- Story 007 covers the next acceptance group in this epic.

---

## QA Test Cases

*Written at story creation. The developer implements against these cases.*

- **AC**: GIVEN: snapshot 含 entity `"player"` 的 `realm = "unknown_realm"`（已被重命名或删除），**WHEN** `_on_save_loaded`，**THEN** 跳过 register，打印警告，entity 以无 realm modifier 状态运行
  - Given: snapshot 含 entity `"player"` 的 `realm = "unknown_realm"`（已被重命名或删除）
  - When: `_on_save_loaded`
  - Then: 跳过 register，打印警告，entity 以无 realm modifier 状态运行
  - Edge cases: boundary, invalid, missing-data, and repeat-run variants from the GDD edge-case section

- **AC**: GIVEN: snapshot 含 `level=5, realm="jindan"`（不一致），**WHEN** `_on_save_loaded`，**THEN** 调 `_derive_realm(5)` 派生为 "fanren"，覆盖存档 realm 字段，按 fanren 处理（不注册 modifier）
  - Given: snapshot 含 `level=5, realm="jindan"`（不一致）
  - When: `_on_save_loaded`
  - Then: 调 `_derive_realm(5)` 派生为 "fanren"，覆盖存档 realm 字段，按 fanren 处理（不注册 modifier）
  - Edge cases: boundary, invalid, missing-data, and repeat-run variants from the GDD edge-case section

---

## Test Evidence

**Story Type**: Integration
**Required evidence**:
- `tests/integration/level/save-loaded-2_test.gd` — must exist and pass

**Status**: [x] Executed 2026-05-04

---

## Dependencies

- Depends on: Story 001 must be ready or done for shared test fixtures and baseline APIs
- Unlocks: Story 007

## 2026-05-04 Sprint Execution Evidence

- Sprint execution order: Sprint 8, story 11/20
- Sprint source: `production/sprints/sprint-8.md`
- QA plan: `production/qa/qa-plan-sprint-8-2026-05-04.md`
- Automated evidence: `reports/report_13/results.xml` (137 tests, 0 failures, 0 skipped, 0 flaky)
- QA gate evidence: `production/qa/evidence/sprint-8-qa-result-2026-05-04.md`
- Verdict: Done; acceptance criteria reviewed against implementation, runtime tests, and sprint QA plan evidence.
- QA-plan automated tests:
  - `tests/unit/debug_console/debug_console_history_test.gd`
  - `tests/unit/level_system/level_system_formula_test.gd`
  - `tests/integration/level_system/level_system_progression_test.gd`
  - `tests/integration/storage_limit_system/storage_limit_system_test.gd`
  - `tests/integration/auto_production_system/auto_production_system_test.gd`
