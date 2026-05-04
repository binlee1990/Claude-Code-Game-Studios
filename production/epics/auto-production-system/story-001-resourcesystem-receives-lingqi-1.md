# Story 001: ResourceSystem receives lingqi +1

> **Epic**: 自动产出系统
> **Status**: Done
> **Layer**: Feature
> **Type**: Integration
> **Manifest Version**: 2026-05-04

## Context

**GDD**: `design/gdd/auto-production-system.md`
**Requirement**: `TR-auto-production-001` — AutoProductionSystem uses TimeManager deltas and OutputMultiplierSystem rates to batch-add online passive resource gains.

**ADR Governing Implementation**: ADR-0003: 时间源与双时间体系
**ADR Decision Summary**: Implement `TimeManager` as an Autoload that owns a dual-time snapshot: real Unix time and derived game time. All gameplay timing uses `TimeManager`, never direct `_process(delta)` as authority. Online ticks use `get_game_delta_since`; offline settlement uses `min(real_now - exit_timestamp, MAX_OFFLINE_SECONDS)` with speed multiplier ignored.

**Engine**: Godot 4.6.2 | **Risk**: LOW
**Engine Notes**: ADR-0003 status is Accepted; verify any Godot 4.6.2 behavior named by the ADR before closing the story.

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

*From GDD `design/gdd/auto-production-system.md`, scoped to this story:*

- [x] GIVEN: TimeManager reports delta 1.0s and OMS returns lingqi 1, **WHEN** auto production ticks, **THEN** ResourceSystem receives lingqi +1.
- [x] GIVEN: OMS returns ZERO for herb due to fractional carry, **WHEN** tick runs, **THEN** ResourceSystem is not called for herb.
- [x] GIVEN: TimeManager is frozen, **WHEN** tick update runs, **THEN** no resources are added.

---

## Implementation Notes

*Derived from ADR-0003 Implementation Guidelines:*

- Must use `Time.get_unix_time_from_system()` as the authoritative real-time source.
- Must not use `_process(delta)` as the source of truth for idle progress or offline rewards.
- Must multiply online game time by registered speed sources.
- Must ignore speed multipliers for MVP offline reward time.
- Must clamp offline duration to `MAX_OFFLINE_SECONDS = 28800`.
- Must publish `time.frozen`, `time.unfrozen`, `time.speed_changed`, and `time.offline_delta` through EventBus.

---

## Out of Scope

- Story 002 covers the next acceptance group in this epic.

---

## QA Test Cases

*Written at story creation. The developer implements against these cases.*

- **AC**: GIVEN: TimeManager reports delta 1.0s and OMS returns lingqi 1, **WHEN** auto production ticks, **THEN** ResourceSystem receives lingqi +1.
  - Given: TimeManager reports delta 1.0s and OMS returns lingqi 1
  - When: auto production ticks
  - Then: ResourceSystem receives lingqi +1
  - Edge cases: boundary, invalid, missing-data, and repeat-run variants from the GDD edge-case section

- **AC**: GIVEN: OMS returns ZERO for herb due to fractional carry, **WHEN** tick runs, **THEN** ResourceSystem is not called for herb.
  - Given: OMS returns ZERO for herb due to fractional carry
  - When: tick runs
  - Then: ResourceSystem is not called for herb
  - Edge cases: boundary, invalid, missing-data, and repeat-run variants from the GDD edge-case section

- **AC**: GIVEN: TimeManager is frozen, **WHEN** tick update runs, **THEN** no resources are added.
  - Given: TimeManager is frozen
  - When: tick update runs
  - Then: no resources are added
  - Edge cases: boundary, invalid, missing-data, and repeat-run variants from the GDD edge-case section

---

## Test Evidence

**Story Type**: Integration
**Required evidence**:
- `tests/integration/auto_production/resourcesystem-receives-lingqi-1_test.gd` — must exist and pass

**Status**: [x] Executed 2026-05-04

---

## Dependencies

- Depends on: None
- Unlocks: Story 002

## 2026-05-04 Sprint Execution Evidence

- Sprint execution order: Sprint 8, story 15/20
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
