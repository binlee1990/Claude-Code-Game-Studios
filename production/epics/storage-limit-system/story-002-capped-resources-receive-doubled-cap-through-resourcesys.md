# Story 002: capped resources receive doubled cap through ResourceSystem

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

- [x] GIVEN: a realm multiplier changes from 1.0 to 2.0, **WHEN** storage limits recompute, **THEN** capped resources receive doubled cap through ResourceSystem.
- [x] GIVEN: a new cap below current value, **WHEN** `set_max` is called, **THEN** ResourceSystem performs clamping and overflow reporting.

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

- Story 001 covers the baseline contract for this epic; do not duplicate its setup work here.

---

## QA Test Cases

*Written at story creation. The developer implements against these cases.*

- **AC**: GIVEN: a realm multiplier changes from 1.0 to 2.0, **WHEN** storage limits recompute, **THEN** capped resources receive doubled cap through ResourceSystem.
  - Given: a realm multiplier changes from 1.0 to 2.0
  - When: storage limits recompute
  - Then: capped resources receive doubled cap through ResourceSystem
  - Edge cases: boundary, invalid, missing-data, and repeat-run variants from the GDD edge-case section

- **AC**: GIVEN: a new cap below current value, **WHEN** `set_max` is called, **THEN** ResourceSystem performs clamping and overflow reporting.
  - Given: a new cap below current value
  - When: `set_max` is called
  - Then: ResourceSystem performs clamping and overflow reporting
  - Edge cases: boundary, invalid, missing-data, and repeat-run variants from the GDD edge-case section

---

## Test Evidence

**Story Type**: Integration
**Required evidence**:
- `tests/integration/storage_limit/capped-resources-receive-doubled-cap-through-resourcesys_test.gd` — must exist and pass

**Status**: [x] Executed 2026-05-04

---

## Dependencies

- Depends on: Story 001 must be ready or done for shared test fixtures and baseline APIs
- Unlocks: None

## 2026-05-04 Sprint Execution Evidence

- Sprint execution order: Sprint 8, story 14/20
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
