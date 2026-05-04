# Story 002: gain_exp 主路径 1

> **Epic**: 等级系统
> **Status**: Ready
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

- [ ] GIVEN: Lv.1，ResourceSystem.exp=100，**WHEN** `gain_exp(BN(100))`，**THEN** spend 成功消 100；while 升 3 级（10+21+33≈64 exp）后 amount_remaining=36 退回 ResourceSystem.exp；最终 level=4，exp=36，发 1 条 `level.changed{old=1, new=4, levels_gained=3}`，**不**发 realm.advanced
- [ ] GIVEN: Lv.1，exp=5，**WHEN** `gain_exp(BN(100))`，**THEN** ResourceSystem.spend(100) 返回 false（余额不足），gain_exp 返回 0，level 不变，exp 仍 5，不发事件
- [ ] GIVEN: Lv.1，**WHEN** `gain_exp(BN.ZERO)`，**THEN** 直接返回 0，不调 spend，不发事件

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

- **AC**: GIVEN: Lv.1，ResourceSystem.exp=100，**WHEN** `gain_exp(BN(100))`，**THEN** spend 成功消 100；while 升 3 级（10+21+33≈64 exp）后 amount_remaining=36 退回 ResourceSystem.exp；最终 level=4，exp=36，发 1 条 `level.changed{old=1, new=4, levels_gained=3}`，**不**发 realm.advanced
  - Given: Lv.1，ResourceSystem.exp=100
  - When: `gain_exp(BN(100))`
  - Then: spend 成功消 100；while 升 3 级（10+21+33≈64 exp）后 amount_remaining=36 退回 ResourceSystem.exp；最终 level=4，exp=36，发 1 条 `level.changed{old=1, new=4, levels_gained=3}`，不发 realm.advanced
  - Edge cases: boundary, invalid, missing-data, and repeat-run variants from the GDD edge-case section

- **AC**: GIVEN: Lv.1，exp=5，**WHEN** `gain_exp(BN(100))`，**THEN** ResourceSystem.spend(100) 返回 false（余额不足），gain_exp 返回 0，level 不变，exp 仍 5，不发事件
  - Given: Lv.1，exp=5
  - When: `gain_exp(BN(100))`
  - Then: ResourceSystem.spend(100) 返回 false（余额不足），gain_exp 返回 0，level 不变，exp 仍 5，不发事件
  - Edge cases: boundary, invalid, missing-data, and repeat-run variants from the GDD edge-case section

- **AC**: GIVEN: Lv.1，**WHEN** `gain_exp(BN.ZERO)`，**THEN** 直接返回 0，不调 spend，不发事件
  - Given: Lv.1
  - When: `gain_exp(BN.ZERO)`
  - Then: 直接返回 0，不调 spend，不发事件
  - Edge cases: boundary, invalid, missing-data, and repeat-run variants from the GDD edge-case section

---

## Test Evidence

**Story Type**: Integration
**Required evidence**:
- `tests/integration/level/gain-exp-1_test.gd` — must exist and pass

**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: Story 001 must be ready or done for shared test fixtures and baseline APIs
- Unlocks: Story 003
