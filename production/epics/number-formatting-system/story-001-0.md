# Story 001: 返回 `"0"`

> **Epic**: 数值格式化系统
> **Status**: Done
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

- [x] GIVEN: `BigNumber.ZERO`，**WHEN** 调用 `format()`，**THEN** 返回 `"0"`
- [x] GIVEN: `BigNumber.from_int(42)`，**WHEN** 调用 `format()`，**THEN** 返回 `"42"`
- [x] GIVEN: `BigNumber.from_int(999)`，**WHEN** 调用 `format()`，**THEN** 返回 `"999"`

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

- Story 002 covers the next acceptance group in this epic.

---

## QA Test Cases

*Written at story creation. The developer implements against these cases.*

- **AC**: GIVEN: `BigNumber.ZERO`，**WHEN** 调用 `format()`，**THEN** 返回 `"0"`
  - Given: `BigNumber.ZERO`
  - When: 调用 `format()`
  - Then: 返回 `"0"`
  - Edge cases: boundary, invalid, missing-data, and repeat-run variants from the GDD edge-case section

- **AC**: GIVEN: `BigNumber.from_int(42)`，**WHEN** 调用 `format()`，**THEN** 返回 `"42"`
  - Given: `BigNumber.from_int(42)`
  - When: 调用 `format()`
  - Then: 返回 `"42"`
  - Edge cases: boundary, invalid, missing-data, and repeat-run variants from the GDD edge-case section

- **AC**: GIVEN: `BigNumber.from_int(999)`，**WHEN** 调用 `format()`，**THEN** 返回 `"999"`
  - Given: `BigNumber.from_int(999)`
  - When: 调用 `format()`
  - Then: 返回 `"999"`
  - Edge cases: boundary, invalid, missing-data, and repeat-run variants from the GDD edge-case section

---

## Test Evidence

**Story Type**: Logic
**Required evidence**:
- `tests/unit/number_formatting/0_test.gd` — must exist and pass

**Status**: [x] Executed 2026-05-04

---

## Dependencies

- Depends on: None
- Unlocks: Story 002

## 2026-05-04 Sprint Execution Evidence

- Sprint execution order: Sprint 3, story 2/20
- Sprint source: `production/sprints/sprint-3.md`
- QA plan: `production/qa/qa-plan-sprint-3-2026-05-04.md`
- Automated evidence: `reports/report_13/results.xml` (137 tests, 0 failures, 0 skipped, 0 flaky)
- QA gate evidence: `production/qa/evidence/sprint-3-qa-result-2026-05-04.md`
- Verdict: Done; acceptance criteria reviewed against implementation, runtime tests, and sprint QA plan evidence.
- QA-plan automated tests:
  - `tests/unit/time_manager/time_manager_logic_test.gd`
  - `tests/unit/number_formatting/number_formatter_test.gd`
  - `tests/performance/number_formatter_performance_test.gd`
  - `tests/unit/data_config/data_config_test.gd`
  - `tests/unit/formula_engine/formula_engine_test.gd`
