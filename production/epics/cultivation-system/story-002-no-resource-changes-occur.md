# Story 002: no resource changes occur

> **Epic**: 修炼系统
> **Status**: Ready
> **Layer**: Feature Integration
> **Type**: Integration
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

- [ ] GIVEN: TimeManager is frozen, **WHEN** manual or auto cultivation tries to run, **THEN** no resource changes occur.
- [ ] GIVEN: stance changes from Meditate to Condense, **WHEN** transition succeeds, **THEN** one `cultivation.stance_changed` event is emitted.

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

- Story 001 covers the baseline contract for this epic; do not duplicate its setup work here.

---

## QA Test Cases

*Written at story creation. The developer implements against these cases.*

- **AC**: GIVEN: TimeManager is frozen, **WHEN** manual or auto cultivation tries to run, **THEN** no resource changes occur.
  - Given: TimeManager is frozen
  - When: manual or auto cultivation tries to run
  - Then: no resource changes occur
  - Edge cases: boundary, invalid, missing-data, and repeat-run variants from the GDD edge-case section

- **AC**: GIVEN: stance changes from Meditate to Condense, **WHEN** transition succeeds, **THEN** one `cultivation.stance_changed` event is emitted.
  - Given: stance changes from Meditate to Condense
  - When: transition succeeds
  - Then: one `cultivation.stance_changed` event is emitted
  - Edge cases: boundary, invalid, missing-data, and repeat-run variants from the GDD edge-case section

---

## Test Evidence

**Story Type**: Integration
**Required evidence**:
- `tests/integration/cultivation/no-resource-changes-occur_test.gd` — must exist and pass

**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: Story 001 must be ready or done for shared test fixtures and baseline APIs
- Unlocks: None
