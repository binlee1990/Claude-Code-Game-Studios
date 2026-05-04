# Story 007: 结果为 `BigNumber.MAX`（饱和）

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

- [ ] GIVEN: `a = BigNumber.MAX`，**WHEN** 执行 `a.add(BigNumber.ONE)`，**THEN** 结果为 `BigNumber.MAX`（饱和）
- [ ] GIVEN: 两个操作数 exponent 差 > 15，**WHEN** 执行加法，**THEN** 结果等于较大操作数
- [ ] GIVEN: 两个相等值的 BigNumber，**WHEN** 执行 `a.equals(b)`，**THEN** 结果为 `true`

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
- Story 008 covers the next acceptance group in this epic.

---

## QA Test Cases

*Written at story creation. The developer implements against these cases.*

- **AC**: GIVEN: `a = BigNumber.MAX`，**WHEN** 执行 `a.add(BigNumber.ONE)`，**THEN** 结果为 `BigNumber.MAX`（饱和）
  - Given: `a = BigNumber.MAX`
  - When: 执行 `a.add(BigNumber.ONE)`
  - Then: 结果为 `BigNumber.MAX`（饱和）
  - Edge cases: boundary, invalid, missing-data, and repeat-run variants from the GDD edge-case section

- **AC**: GIVEN: 两个操作数 exponent 差 > 15，**WHEN** 执行加法，**THEN** 结果等于较大操作数
  - Given: 两个操作数 exponent 差 > 15
  - When: 执行加法
  - Then: 结果等于较大操作数
  - Edge cases: boundary, invalid, missing-data, and repeat-run variants from the GDD edge-case section

- **AC**: GIVEN: 两个相等值的 BigNumber，**WHEN** 执行 `a.equals(b)`，**THEN** 结果为 `true`
  - Given: 两个相等值的 BigNumber
  - When: 执行 `a.equals(b)`
  - Then: 结果为 `true`
  - Edge cases: boundary, invalid, missing-data, and repeat-run variants from the GDD edge-case section

---

## Test Evidence

**Story Type**: Logic
**Required evidence**:
- `tests/unit/big_number/bignumber-max_test.gd` — must exist and pass

**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: Story 001 must be ready or done for shared test fixtures and baseline APIs
- Unlocks: Story 008
