# Story 001: `ResourceSystem.get_max("lingqi") == 1000`

> **Epic**: 存储上限系统
> **Status**: Done
> **Layer**: Feature
> **Type**: Integration
> **Manifest Version**: 2026-05-04

## Context

**GDD**: `design/gdd/storage-limit-system.md`
**Requirement**: `TR-storage-limit-001` — StorageLimitSystem computes resource caps and applies them through ResourceSystem ownership boundaries.

**ADR Governing Implementation**: ADR-0010: ResourceSystem 不可变 BigNumber 策略
**ADR Decision Summary**: ResourceSystem stores BigNumber values as immutable value objects. Operations calculate new BigNumber instances and replace the stored value. `add()` returns the actual added amount. `spend()` is atomic per resource. `batch_add()` executes sequential per-resource adds and returns a dictionary of actual additions; it does not roll back earlier successful changes.

**Engine**: Godot 4.6.2 | **Risk**: LOW
**Engine Notes**: ADR-0010 status is Accepted; verify any Godot 4.6.2 behavior named by the ADR before closing the story.

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

*From GDD `design/gdd/storage-limit-system.md`, scoped to this story:*

- [x] GIVEN: `lingqi` base cap 1000 and no modifiers, **WHEN** storage limits initialize, **THEN** `ResourceSystem.get_max("lingqi") == 1000`.
- [x] GIVEN: `lingqi` current 900 and cap 1000, **WHEN** `get_capacity_state("lingqi")`, **THEN** state is `warning` and fill_ratio is 0.9.
- [x] GIVEN: `lingshi` is uncapped, **WHEN** `get_capacity_state("lingshi")`, **THEN** state is `uncapped` and no warning is emitted.

---

## Implementation Notes

*Derived from ADR-0010 Implementation Guidelines:*

- Must store resource values as `BigNumber`.
- Must replace stored values with newly calculated BigNumber instances.
- Must not mutate BigNumber instances in place.
- Must keep ResourceSystem limited to resource CRUD, caps, reset, events, and snapshot/restore.
- Must not include production, multiplier, loot, level, or economy business logic.
- Must emit `resource.{id}.changed` only when actual value changes.

---

## Out of Scope

- Story 002 covers the next acceptance group in this epic.

---

## QA Test Cases

*Written at story creation. The developer implements against these cases.*

- **AC**: GIVEN: `lingqi` base cap 1000 and no modifiers, **WHEN** storage limits initialize, **THEN** `ResourceSystem.get_max("lingqi") == 1000`.
  - Given: `lingqi` base cap 1000 and no modifiers
  - When: storage limits initialize
  - Then: `ResourceSystem.get_max("lingqi") == 1000`
  - Edge cases: boundary, invalid, missing-data, and repeat-run variants from the GDD edge-case section

- **AC**: GIVEN: `lingqi` current 900 and cap 1000, **WHEN** `get_capacity_state("lingqi")`, **THEN** state is `warning` and fill_ratio is 0.9.
  - Given: `lingqi` current 900 and cap 1000
  - When: `get_capacity_state("lingqi")`
  - Then: state is `warning` and fill_ratio is 0.9
  - Edge cases: boundary, invalid, missing-data, and repeat-run variants from the GDD edge-case section

- **AC**: GIVEN: `lingshi` is uncapped, **WHEN** `get_capacity_state("lingshi")`, **THEN** state is `uncapped` and no warning is emitted.
  - Given: `lingshi` is uncapped
  - When: `get_capacity_state("lingshi")`
  - Then: state is `uncapped` and no warning is emitted
  - Edge cases: boundary, invalid, missing-data, and repeat-run variants from the GDD edge-case section

---

## Test Evidence

**Story Type**: Integration
**Required evidence**:
- `tests/integration/storage_limit/resourcesystem-get-max-lingqi-1000_test.gd` — must exist and pass

**Status**: [x] Executed 2026-05-04

---

## Dependencies

- Depends on: None
- Unlocks: Story 002

## 2026-05-04 Sprint Execution Evidence

- Sprint execution order: Sprint 8, story 13/20
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
