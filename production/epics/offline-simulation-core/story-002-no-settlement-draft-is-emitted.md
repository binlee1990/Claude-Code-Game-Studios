# Story 002: no settlement draft is emitted

> **Epic**: 离线模拟内核
> **Status**: Done
> **Layer**: Simulation
> **Type**: Integration
> **Manifest Version**: 2026-05-04

## Context

**GDD**: `design/gdd/offline-simulation-core.md`
**Requirement**: `TR-offline-sim-core-001` — OfflineSimulationCore converts capped offline delta into ordered chunked simulator runs and emits settlement drafts.

**ADR Governing Implementation**: ADR-0015: 离线模拟 tick 粒度
**ADR Decision Summary**: Use fixed MVP offline simulation granularity: clamp total offline delta through TimeManager, then split into chunks up to `MAX_CHUNK_SECONDS` (GDD example: 1800 seconds). Within each chunk, simulators use 1-second logical tick semantics or closed-form aggregation if they can prove equivalence. OfflineSimulationCore merges partial results into an `OfflineSimulationDraft`; OfflineRewardSettlement is the only system that writes rewards to ResourceSystem.

**Engine**: Godot 4.6.2 | **Risk**: LOW
**Engine Notes**: ADR-0015 status is Accepted; verify any Godot 4.6.2 behavior named by the ADR before closing the story.

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

*From GDD `design/gdd/offline-simulation-core.md`, scoped to this story:*

- [x] GIVEN: delta is 0, **WHEN** simulation is requested, **THEN** no settlement draft is emitted.
- [x] GIVEN: save.loaded has not completed, **WHEN** offline delta arrives, **THEN** simulation is deferred.

---

## Implementation Notes

*Derived from ADR-0015 Implementation Guidelines:*

- Must clamp offline duration through TimeManager before simulation.
- Must split simulation into bounded chunks no larger than `MAX_CHUNK_SECONDS`.
- Must run simulators in ascending priority, then registration order.
- Must use 1-second business tick semantics unless a simulator documents an equivalent closed-form aggregation.
- Must collect failed non-critical simulator warnings without discarding successful partial results.
- Must not write ResourceSystem from OfflineSimulationCore or OfflineCombatSimulation.

---

## Out of Scope

- Story 001 covers the baseline contract for this epic; do not duplicate its setup work here.

---

## QA Test Cases

*Written at story creation. The developer implements against these cases.*

- **AC**: GIVEN: delta is 0, **WHEN** simulation is requested, **THEN** no settlement draft is emitted.
  - Given: delta is 0
  - When: simulation is requested
  - Then: no settlement draft is emitted
  - Edge cases: boundary, invalid, missing-data, and repeat-run variants from the GDD edge-case section

- **AC**: GIVEN: save.loaded has not completed, **WHEN** offline delta arrives, **THEN** simulation is deferred.
  - Given: save.loaded has not completed
  - When: offline delta arrives
  - Then: simulation is deferred
  - Edge cases: boundary, invalid, missing-data, and repeat-run variants from the GDD edge-case section

---

## Test Evidence

**Story Type**: Integration
**Required evidence**:
- `tests/integration/offline_simulation_core/no-settlement-draft-is-emitted_test.gd` — must exist and pass

**Status**: [x] Executed 2026-05-04

---

## Dependencies

- Depends on: Story 001 must be ready or done for shared test fixtures and baseline APIs
- Unlocks: None

## 2026-05-04 Sprint Execution Evidence

- Sprint execution order: Sprint 9, story 17/20
- Sprint source: `production/sprints/sprint-9.md`
- QA plan: `production/qa/qa-plan-sprint-9-2026-05-04.md`
- Automated evidence: `reports/report_13/results.xml` (137 tests, 0 failures, 0 skipped, 0 flaky)
- QA gate evidence: `production/qa/evidence/sprint-9-qa-result-2026-05-04.md`
- Verdict: Done; acceptance criteria reviewed against implementation, runtime tests, and sprint QA plan evidence.
- QA-plan automated tests:
  - `tests/integration/sprint9/sprint9_feature_stack_test.gd`
