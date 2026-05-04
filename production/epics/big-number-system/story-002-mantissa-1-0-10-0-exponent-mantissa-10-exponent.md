# Story 002: `mantissa ∈ [1.0, 10.0)` 且 `exponent` 使得 `mantissa × 10^exponent` 等于原始

> **Epic**: 大数值系统
> **Status**: Ready
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

- [ ] GIVEN: 任意正 float 值，**WHEN** 通过 `BigNumber.from_float()` 创建实例，**THEN** `mantissa ∈ [1.0, 10.0)` 且 `exponent` 使得 `mantissa × 10^exponent` 等于原始值
- [ ] GIVEN: 两个 BigNumber `a = {2.5, 3}` 和 `b = {3.0, 2}`，**WHEN** 执行 `a.add(b)`，**THEN** 结果为 `{2.8, 3}`（即 2800）
- [ ] GIVEN: `a = {2.0, 3}` 和 `b = {5.0, 3}`，**WHEN** 执行 `a.subtract(b)`，**THEN** 结果为 `BigNumber.ZERO`（非负约束）

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
- Story 003 covers the next acceptance group in this epic.

---

## QA Test Cases

*Written at story creation. The developer implements against these cases.*

- **AC**: GIVEN: 任意正 float 值，**WHEN** 通过 `BigNumber.from_float()` 创建实例，**THEN** `mantissa ∈ [1.0, 10.0)` 且 `exponent` 使得 `mantissa × 10^exponent` 等于原始值
  - Given: 任意正 float 值
  - When: 通过 `BigNumber.from_float()` 创建实例
  - Then: `mantissa ∈ [1.0, 10.0)` 且 `exponent` 使得 `mantissa × 10^exponent` 等于原始值
  - Edge cases: boundary, invalid, missing-data, and repeat-run variants from the GDD edge-case section

- **AC**: GIVEN: 两个 BigNumber `a = {2.5, 3}` 和 `b = {3.0, 2}`，**WHEN** 执行 `a.add(b)`，**THEN** 结果为 `{2.8, 3}`（即 2800）
  - Given: 两个 BigNumber `a = {2.5, 3}` 和 `b = {3.0, 2}`
  - When: 执行 `a.add(b)`
  - Then: 结果为 `{2.8, 3}`（即 2800）
  - Edge cases: boundary, invalid, missing-data, and repeat-run variants from the GDD edge-case section

- **AC**: GIVEN: `a = {2.0, 3}` 和 `b = {5.0, 3}`，**WHEN** 执行 `a.subtract(b)`，**THEN** 结果为 `BigNumber.ZERO`（非负约束）
  - Given: `a = {2.0, 3}` 和 `b = {5.0, 3}`
  - When: 执行 `a.subtract(b)`
  - Then: 结果为 `BigNumber.ZERO`（非负约束）
  - Edge cases: boundary, invalid, missing-data, and repeat-run variants from the GDD edge-case section

---

## Test Evidence

**Story Type**: Logic
**Required evidence**:
- `tests/unit/big_number/mantissa-1-0-10-0-exponent-mantissa-10-exponent_test.gd` — must exist and pass

**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: Story 001 must be ready or done for shared test fixtures and baseline APIs
- Unlocks: Story 003
