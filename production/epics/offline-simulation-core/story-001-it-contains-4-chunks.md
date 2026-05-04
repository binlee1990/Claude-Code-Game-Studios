# Story 001: it contains 4 chunks

> **Epic**: 离线模拟内核
> **Status**: Done
> **Layer**: Simulation
> **Type**: UI
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

- [x] GIVEN: offline delta 7200s and chunk size 1800s, **WHEN** plan builds, **THEN** it contains 4 chunks.
- [x] GIVEN: two registered simulators, **WHEN** offline simulation runs, **THEN** both are called in priority order.
- [x] GIVEN: one non-critical simulator fails, **WHEN** simulation completes, **THEN** draft includes failure and successful simulator output.

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

- Story 002 covers the next acceptance group in this epic.

---

## QA Test Cases

*Written at story creation. The developer implements against these cases.*

- **Manual check**: GIVEN: offline delta 7200s and chunk size 1800s, **WHEN** plan builds, **THEN** it contains 4 chunks.
  - Setup: offline delta 7200s and chunk size 1800s
  - Verify: plan builds
  - Pass condition: it contains 4 chunks

- **Manual check**: GIVEN: two registered simulators, **WHEN** offline simulation runs, **THEN** both are called in priority order.
  - Setup: two registered simulators
  - Verify: offline simulation runs
  - Pass condition: both are called in priority order

- **Manual check**: GIVEN: one non-critical simulator fails, **WHEN** simulation completes, **THEN** draft includes failure and successful simulator output.
  - Setup: one non-critical simulator fails
  - Verify: simulation completes
  - Pass condition: draft includes failure and successful simulator output

---

## Test Evidence

**Story Type**: UI
**Required evidence**:
- `production/qa/evidence/it-contains-4-chunks-evidence.md` — manual/interaction evidence with sign-off

**Status**: [x] Executed 2026-05-04

---

## Dependencies

- Depends on: None
- Unlocks: Story 002

## 2026-05-04 Sprint Execution Evidence

- Sprint execution order: Sprint 9, story 16/20
- Sprint source: `production/sprints/sprint-9.md`
- QA plan: `production/qa/qa-plan-sprint-9-2026-05-04.md`
- Automated evidence: `reports/report_13/results.xml` (137 tests, 0 failures, 0 skipped, 0 flaky)
- QA gate evidence: `production/qa/evidence/sprint-9-qa-result-2026-05-04.md`
- Verdict: Done; acceptance criteria reviewed against implementation, runtime tests, and sprint QA plan evidence.
- QA-plan automated tests:
  - `tests/integration/sprint9/sprint9_feature_stack_test.gd`
