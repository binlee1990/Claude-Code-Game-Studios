# Story 001: next zone becomes unlocked

> **Epic**: 地图推进系统
> **Status**: Ready
> **Layer**: Feature Integration
> **Type**: UI
> **Manifest Version**: 2026-05-04

## Context

**GDD**: `design/gdd/map-progression-system.md`
**Requirement**: `TR-map-progression-001` — MapProgressionSystem unlocks and advances zones based on ZoneSystem, LevelSystem, and combat progression events.

**ADR Governing Implementation**: ADR-0002: 事件总线架构
**ADR Decision Summary**: Use a global `EventBus` Autoload Node with string event names and `Dictionary` payloads. The bus dispatches events synchronously in the current frame. Exact subscriptions are the production path. Prefix pattern subscriptions exist only for debug tooling such as `event watch resource`. Coalesced events are allowed only for display refreshes where latest-state wins.

**Engine**: Godot 4.6.2 | **Risk**: HIGH
**Engine Notes**: ADR-0002 status is Accepted; verify any Godot 4.6.2 behavior named by the ADR before closing the story.

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

*From GDD `design/gdd/map-progression-system.md`, scoped to this story:*

- [ ] GIVEN: player reaches required level and prerequisite zone is cleared, **WHEN** unlock evaluation runs, **THEN** next zone becomes unlocked.
- [ ] GIVEN: player wins first encounter in an unlocked zone, **WHEN** event is processed, **THEN** zone state becomes cleared and `zone.first_cleared` emits once.
- [ ] GIVEN: recent win rate exceeds farm threshold, **WHEN** HUD queries zone state, **THEN** zone is marked farmable.

---

## Implementation Notes

*Derived from ADR-0002 Implementation Guidelines:*

- Must define event names as constants; production code must not use untracked magic strings.
- Must use exact subscriptions for production UI and gameplay consumers.
- Must restrict `subscribe_pattern` to DebugConsole and similar diagnostics.
- Must reject empty prefix pattern subscriptions.
- Must validate `Callable.is_valid()` before delivery and remove invalid callables.
- Must defer subscribe/unsubscribe mutations until after current dispatch completes.

---

## Out of Scope

- Story 002 covers the next acceptance group in this epic.

---

## QA Test Cases

*Written at story creation. The developer implements against these cases.*

- **Manual check**: GIVEN: player reaches required level and prerequisite zone is cleared, **WHEN** unlock evaluation runs, **THEN** next zone becomes unlocked.
  - Setup: player reaches required level and prerequisite zone is cleared
  - Verify: unlock evaluation runs
  - Pass condition: next zone becomes unlocked

- **Manual check**: GIVEN: player wins first encounter in an unlocked zone, **WHEN** event is processed, **THEN** zone state becomes cleared and `zone.first_cleared` emits once.
  - Setup: player wins first encounter in an unlocked zone
  - Verify: event is processed
  - Pass condition: zone state becomes cleared and `zone.first_cleared` emits once

- **Manual check**: GIVEN: recent win rate exceeds farm threshold, **WHEN** HUD queries zone state, **THEN** zone is marked farmable.
  - Setup: recent win rate exceeds farm threshold
  - Verify: HUD queries zone state
  - Pass condition: zone is marked farmable

---

## Test Evidence

**Story Type**: UI
**Required evidence**:
- `production/qa/evidence/next-zone-becomes-unlocked-evidence.md` — manual/interaction evidence with sign-off

**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: None
- Unlocks: Story 002
