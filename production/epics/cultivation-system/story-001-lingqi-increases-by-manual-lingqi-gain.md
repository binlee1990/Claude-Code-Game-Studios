# Story 001: lingqi increases by `manual_lingqi_gain`

> **Epic**: 修炼系统
> **Status**: Done
> **Layer**: Feature Integration
> **Type**: UI
> **Manifest Version**: 2026-05-04

## Context

**GDD**: `design/gdd/cultivation-system.md`
**Requirement**: `TR-cultivation-system-001` — CultivationSystem uses resource, auto-production, and time services to orchestrate cultivation stance and progress.

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

*From GDD `design/gdd/cultivation-system.md`, scoped to this story:*

- [x] GIVEN: player clicks manual cultivate off cooldown, **WHEN** call executes, **THEN** lingqi increases by `manual_lingqi_gain`.
- [x] GIVEN: player is in Condense and has enough lingqi, **WHEN** tick conversion runs, **THEN** lingqi decreases and xiuwei increases by formula result.
- [x] GIVEN: player lacks lingqi, **WHEN** Condense tick runs, **THEN** no xiuwei is added and a shortage state is available to HUD.

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

- **Manual check**: GIVEN: player clicks manual cultivate off cooldown, **WHEN** call executes, **THEN** lingqi increases by `manual_lingqi_gain`.
  - Setup: player clicks manual cultivate off cooldown
  - Verify: call executes
  - Pass condition: lingqi increases by `manual_lingqi_gain`

- **Manual check**: GIVEN: player is in Condense and has enough lingqi, **WHEN** tick conversion runs, **THEN** lingqi decreases and xiuwei increases by formula result.
  - Setup: player is in Condense and has enough lingqi
  - Verify: tick conversion runs
  - Pass condition: lingqi decreases and xiuwei increases by formula result

- **Manual check**: GIVEN: player lacks lingqi, **WHEN** Condense tick runs, **THEN** no xiuwei is added and a shortage state is available to HUD.
  - Setup: player lacks lingqi
  - Verify: Condense tick runs
  - Pass condition: no xiuwei is added and a shortage state is available to HUD

---

## Test Evidence

**Story Type**: UI
**Required evidence**:
- `production/qa/evidence/lingqi-increases-by-manual-lingqi-gain-evidence.md` — manual/interaction evidence with sign-off

**Status**: [x] Executed 2026-05-04

---

## Dependencies

- Depends on: None
- Unlocks: Story 002

## 2026-05-04 Sprint Execution Evidence

- Sprint execution order: Sprint 9, story 10/20
- Sprint source: `production/sprints/sprint-9.md`
- QA plan: `production/qa/qa-plan-sprint-9-2026-05-04.md`
- Automated evidence: `reports/report_13/results.xml` (137 tests, 0 failures, 0 skipped, 0 flaky)
- QA gate evidence: `production/qa/evidence/sprint-9-qa-result-2026-05-04.md`
- Verdict: Done; acceptance criteria reviewed against implementation, runtime tests, and sprint QA plan evidence.
- QA-plan automated tests:
  - `tests/integration/sprint9/sprint9_feature_stack_test.gd`
