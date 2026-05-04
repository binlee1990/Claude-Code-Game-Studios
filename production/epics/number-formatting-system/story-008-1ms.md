# Story 008: 总耗时 < 1ms

> **Epic**: 数值格式化系统
> **Status**: Ready
> **Layer**: Core Data
> **Type**: Logic
> **Manifest Version**: 2026-05-04

## Context

**GDD**: `design/gdd/number-formatting-system.md`
**Requirement**: `TR-number-formatting-001` — NumberFormatter provides the single formatting path for BigNumber display using direct, Chinese-unit, and scientific notation ranges.

**ADR Governing Implementation**: ADR-0014: NumberFormatter 缩写映射策略
**ADR Decision Summary**: Implement `NumberFormatter` as a utility service with a hard-coded MVP Chinese unit table: `万, 亿, 兆, 京, 垓, 秭, 穰, 沟, 涧, 正, 载, 极`. Values above `10^48` use scientific notation. This table stays code-owned for MVP; DataConfig-driven formatting can be revisited Post-MVP if localization or content scale requires it.

**Engine**: Godot 4.6.2 | **Risk**: LOW
**Engine Notes**: ADR-0014 status is Accepted; verify any Godot 4.6.2 behavior named by the ADR before closing the story.

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

*From GDD `design/gdd/number-formatting-system.md`, scoped to this story:*

- [ ] GIVEN: 1000 个不同量级的 BigNumber，**WHEN** 各调用 `format()` 一次，**THEN** 总耗时 < 1ms

---

## Implementation Notes

*Derived from ADR-0014 Implementation Guidelines:*

- Must route all player-facing BigNumber display through NumberFormatter.
- Must use the MVP hard-coded Chinese unit table.
- Must switch to scientific notation above `10^48`.
- Must return `"0"` for zero/invalid BigNumber values.
- Must return `"MAX"` for BigNumber.MAX.
- Must handle rounding across unit thresholds.

---

## Out of Scope

- Story 001 covers the baseline contract for this epic; do not duplicate its setup work here.

---

## QA Test Cases

*Written at story creation. The developer implements against these cases.*

- **AC**: GIVEN: 1000 个不同量级的 BigNumber，**WHEN** 各调用 `format()` 一次，**THEN** 总耗时 < 1ms
  - Given: 1000 个不同量级的 BigNumber
  - When: 各调用 `format()` 一次
  - Then: 总耗时 < 1ms
  - Edge cases: boundary, invalid, missing-data, and repeat-run variants from the GDD edge-case section

---

## Test Evidence

**Story Type**: Logic
**Required evidence**:
- `tests/unit/number_formatting/1ms_test.gd` — must exist and pass

**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: Story 001 must be ready or done for shared test fixtures and baseline APIs
- Unlocks: None
