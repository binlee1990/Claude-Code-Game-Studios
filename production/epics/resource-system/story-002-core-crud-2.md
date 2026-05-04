# Story 002: Core CRUD 2

> **Epic**: 资源系统
> **Status**: Ready
> **Layer**: Core Gameplay
> **Type**: Logic
> **Manifest Version**: 2026-05-04

## Context

**GDD**: `design/gdd/resource-system.md`
**Requirement**: `TR-resource-system-001` — ResourceSystem owns resource CRUD, BigNumber balances, caps, overflow events, reset scopes, batch_add, snapshot, and restore.

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

*From GDD `design/gdd/resource-system.md`, scoped to this story:*

- [ ] GIVEN: `lingqi` current=`BigNumber.from_int(800)`，cap=`BigNumber.from_int(1000)`，**WHEN** `add("lingqi", BigNumber.from_int(300))`，**THEN** 返回 `BigNumber.from_int(200)`（钳位），`get_value == BigNumber.from_int(1000)`
- [ ] GIVEN: `lingshi` current=`BigNumber.from_int(500)`（has_cap=false），**WHEN** `add("lingshi", BigNumber.from_int(9999))`，**THEN** 返回 `BigNumber.from_int(9999)`，`get_value == BigNumber.from_int(10499)`
- [ ] GIVEN: `herb` current=`BigNumber.from_int(300)`，**WHEN** `spend("herb", BigNumber.from_int(300))`，**THEN** 返回 `true`，`get_value == BigNumber.ZERO`

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

- **AC**: GIVEN: `lingqi` current=`BigNumber.from_int(800)`，cap=`BigNumber.from_int(1000)`，**WHEN** `add("lingqi", BigNumber.from_int(300))`，**THEN** 返回 `BigNumber.from_int(200)`（钳位），`get_value == BigNumber.from_int(1000)`
  - Given: `lingqi` current=`BigNumber.from_int(800)`，cap=`BigNumber.from_int(1000)`
  - When: `add("lingqi", BigNumber.from_int(300))`
  - Then: 返回 `BigNumber.from_int(200)`（钳位），`get_value == BigNumber.from_int(1000)`
  - Edge cases: boundary, invalid, missing-data, and repeat-run variants from the GDD edge-case section

- **AC**: GIVEN: `lingshi` current=`BigNumber.from_int(500)`（has_cap=false），**WHEN** `add("lingshi", BigNumber.from_int(9999))`，**THEN** 返回 `BigNumber.from_int(9999)`，`get_value == BigNumber.from_int(10499)`
  - Given: `lingshi` current=`BigNumber.from_int(500)`（has_cap=false）
  - When: `add("lingshi", BigNumber.from_int(9999))`
  - Then: 返回 `BigNumber.from_int(9999)`，`get_value == BigNumber.from_int(10499)`
  - Edge cases: boundary, invalid, missing-data, and repeat-run variants from the GDD edge-case section

- **AC**: GIVEN: `herb` current=`BigNumber.from_int(300)`，**WHEN** `spend("herb", BigNumber.from_int(300))`，**THEN** 返回 `true`，`get_value == BigNumber.ZERO`
  - Given: `herb` current=`BigNumber.from_int(300)`
  - When: `spend("herb", BigNumber.from_int(300))`
  - Then: 返回 `true`，`get_value == BigNumber.ZERO`
  - Edge cases: boundary, invalid, missing-data, and repeat-run variants from the GDD edge-case section

---

## Test Evidence

**Story Type**: Logic
**Required evidence**:
- `tests/unit/resource/core-crud-2_test.gd` — must exist and pass

**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: Story 001 must be ready or done for shared test fixtures and baseline APIs
- Unlocks: Story 003
