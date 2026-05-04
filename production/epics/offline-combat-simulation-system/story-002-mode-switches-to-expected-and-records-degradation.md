# Story 002: mode switches to expected and records degradation

> **Epic**: 离线战斗模拟系统
> **Status**: Ready
> **Layer**: Simulation
> **Type**: Integration
> **Manifest Version**: 2026-05-04

## Context

**GDD**: `design/gdd/offline-combat-simulation-system.md`
**Requirement**: `TR-offline-combat-001` — OfflineCombatSimulation reuses the online combat calculation path with copied RNG state and returns partial results.

**ADR Governing Implementation**: ADR-0009: 在线/离线战斗路径统一
**ADR Decision Summary**: Both online and offline combat use the same `CombatCalculator` for attack resolution and the same `LootSystem` for rewards. SemiAutoCombatSystem manages live encounter cadence and event publication. OfflineCombatSimulation uses snapshots and copied RNG states to run batched encounters, producing a draft consumed by OfflineRewardSettlement.

**Engine**: Godot 4.6.2 | **Risk**: LOW
**Engine Notes**: ADR-0009 status is Accepted; verify any Godot 4.6.2 behavior named by the ADR before closing the story.

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

*From GDD `design/gdd/offline-combat-simulation-system.md`, scoped to this story:*

- [ ] GIVEN: CPU budget exceeded, **WHEN** simulation continues, **THEN** mode switches to expected and records degradation.
- [ ] GIVEN: generated rewards exist, **WHEN** simulation completes, **THEN** no ResourceSystem writes have occurred.

---

## Implementation Notes

*Derived from ADR-0009 Implementation Guidelines:*

- Must implement combat formulas once in CombatCalculator.
- Must not duplicate damage formulas in OfflineCombatSimulation.
- Must use RNGManager copied states for offline simulation.
- Must aggregate offline rewards into a settlement draft before writing ResourceSystem.
- Must publish online combat events through EventBus; offline settlement publishes summary events after rewards are applied.
- Must not let offline simulation call SemiAutoCombatSystem directly.

---

## Out of Scope

- Story 001 covers the baseline contract for this epic; do not duplicate its setup work here.

---

## QA Test Cases

*Written at story creation. The developer implements against these cases.*

- **AC**: GIVEN: CPU budget exceeded, **WHEN** simulation continues, **THEN** mode switches to expected and records degradation.
  - Given: CPU budget exceeded
  - When: simulation continues
  - Then: mode switches to expected and records degradation
  - Edge cases: boundary, invalid, missing-data, and repeat-run variants from the GDD edge-case section

- **AC**: GIVEN: generated rewards exist, **WHEN** simulation completes, **THEN** no ResourceSystem writes have occurred.
  - Given: generated rewards exist
  - When: simulation completes
  - Then: no ResourceSystem writes have occurred
  - Edge cases: boundary, invalid, missing-data, and repeat-run variants from the GDD edge-case section

---

## Test Evidence

**Story Type**: Integration
**Required evidence**:
- `tests/integration/offline_combat_simulation/mode-switches-to-expected-and-records-degradation_test.gd` — must exist and pass

**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: Story 001 must be ready or done for shared test fixtures and baseline APIs
- Unlocks: None
