# Story 014: 结果为 `BigNumber.MAX`（饱和）

> **Epic**: 大数值系统
> **Status**: Done
> **Layer**: Foundation
> **Type**: Logic
> **Manifest Version**: 2026-05-04

## Context

**GDD**: `design/gdd/big-number-system.md`
**Requirement**: `TR-big-number-001` — BigNumber provides the shared non-negative mantissa/exponent numeric abstraction for all large game quantities.

**ADR Governing Implementation**: ADR-0001: BigNumber 实现策略
**ADR Decision Summary**: Implement `BigNumber` as an immutable `RefCounted` GDScript value type using `mantissa: float` and `exponent: int`. Normalized non-zero values keep `mantissa` in `[1.0, 10.0)` and `exponent` in `[0, 308]`. Zero is `{0.0, 0}`. Overflow saturates to `MAX`; negative or sub-unit absolute results clamp to `ZERO`.

**Engine**: Godot 4.6.2 | **Risk**: HIGH
**Engine Notes**: ADR-0001 status is Accepted; verify any Godot 4.6.2 behavior named by the ADR before closing the story.

**Control Manifest Rules (this layer)**:
- Required: **Use `BigNumber` for all game absolute quantities** — source: ADR-0001
- Required: **Keep BigNumber arithmetic immutable; every operation returns a new instance** — source: ADR-0001
- Required: **Serialize BigNumber as `{"m": mantissa, "e": exponent}`** — source: ADR-0001
- Required: **Route cross-system notifications through EventBus exact subscriptions in production** — source: ADR-0002
- Forbidden: **Never store resources, attributes, damage, experience, or rewards as raw `int` / `float` absolute values** — source: ADR-0001
- Forbidden: **Never introduce GDExtension BigNumber before the GDScript performance gate fails with measured evidence** — source: ADR-0001
- Forbidden: **Never use EventBus prefix subscriptions for production UI/gameplay behavior** — source: ADR-0002
- Guardrail: **BigNumber**: 1000 instances × 50 operations must fit within a 16.6 ms frame before GDExtension is deferred long term — source: ADR-0001
- Guardrail: **EventBus**: typical frame cost target is <= 0.5 ms/frame — source: ADR-0002
- Guardrail: **TimeManager**: 1000 `get_game_time()` calls target <= 0.1 ms — source: ADR-0003

---

## Acceptance Criteria

*From GDD `design/gdd/big-number-system.md`, scoped to this story:*

- [x] GIVEN: `a = BigNumber.MAX` 且 `b = BigNumber.MAX`，**WHEN** 执行 `a.multiply(b)`，**THEN** 结果为 `BigNumber.MAX`（饱和）
- [x] GIVEN: `a = {5.0, 0}` 且 `b = {7.0, 0}`，**WHEN** 执行 `a.divide(b)`，**THEN** 结果为 `BigNumber.ZERO`（亚单位值 < 1，按非负约束钳位）

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

---

## QA Test Cases

*Written at story creation. The developer implements against these cases.*

- **AC**: GIVEN: `a = BigNumber.MAX` 且 `b = BigNumber.MAX`，**WHEN** 执行 `a.multiply(b)`，**THEN** 结果为 `BigNumber.MAX`（饱和）
  - Given: `a = BigNumber.MAX` 且 `b = BigNumber.MAX`
  - When: 执行 `a.multiply(b)`
  - Then: 结果为 `BigNumber.MAX`（饱和）
  - Edge cases: boundary, invalid, missing-data, and repeat-run variants from the GDD edge-case section

- **AC**: GIVEN: `a = {5.0, 0}` 且 `b = {7.0, 0}`，**WHEN** 执行 `a.divide(b)`，**THEN** 结果为 `BigNumber.ZERO`（亚单位值 < 1，按非负约束钳位）
  - Given: `a = {5.0, 0}` 且 `b = {7.0, 0}`
  - When: 执行 `a.divide(b)`
  - Then: 结果为 `BigNumber.ZERO`（亚单位值 < 1，按非负约束钳位）
  - Edge cases: boundary, invalid, missing-data, and repeat-run variants from the GDD edge-case section

---

## Test Evidence

**Story Type**: Logic
**Required evidence**:
- `tests/unit/big_number/bignumber-max_test.gd` — must exist and pass

**Status**: [x] Executed 2026-05-04

---

## Dependencies

- Depends on: Story 001 must be ready or done for shared test fixtures and baseline APIs
- Unlocks: None

## 2026-05-04 Sprint Execution Evidence

- Sprint execution order: Sprint 1, story 14/20
- Sprint source: `production/sprints/sprint-1.md`
- QA plan: `production/qa/qa-plan-sprint-1-2026-05-04.md`
- Automated evidence: `reports/report_13/results.xml` (137 tests, 0 failures, 0 skipped, 0 flaky)
- QA gate evidence: `production/qa/evidence/sprint-1-qa-result-2026-05-04.md`
- Verdict: Done; acceptance criteria reviewed against implementation, runtime tests, and sprint QA plan evidence.
- QA-plan automated tests:
  - `tests/integration/big_number/api_contract_test.gd`
  - `tests/unit/big_number/big_number_arithmetic_test.gd`
  - `tests/performance/big_number_performance_test.gd`
  - `tests/integration/rng/deterministic_replay_test.gd`
  - `tests/unit/rng/stream_independence_test.gd`
