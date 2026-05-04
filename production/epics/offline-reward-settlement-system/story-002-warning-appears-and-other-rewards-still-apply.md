# Story 002: warning appears and other rewards still apply

> **Epic**: 离线收益结算系统
> **Status**: Done
> **Layer**: Simulation
> **Type**: Integration
> **Manifest Version**: 2026-05-04

## Context

**GDD**: `design/gdd/offline-reward-settlement-system.md`
**Requirement**: `TR-offline-settlement-001` — OfflineRewardSettlement applies claimable offline rewards through ResourceSystem and reports gross, claimed, lost, and warnings.

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

*From GDD `design/gdd/offline-reward-settlement-system.md`, scoped to this story:*

- [x] GIVEN: one simulator failed, **WHEN** summary is generated, **THEN** warning appears and other rewards still apply.
- [x] GIVEN: settlement completes, **WHEN** event bus is checked, **THEN** exactly one `offline.settled` event is emitted.

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

- **AC**: GIVEN: one simulator failed, **WHEN** summary is generated, **THEN** warning appears and other rewards still apply.
  - Given: one simulator failed
  - When: summary is generated
  - Then: warning appears and other rewards still apply
  - Edge cases: boundary, invalid, missing-data, and repeat-run variants from the GDD edge-case section

- **AC**: GIVEN: settlement completes, **WHEN** event bus is checked, **THEN** exactly one `offline.settled` event is emitted.
  - Given: settlement completes
  - When: event bus is checked
  - Then: exactly one `offline.settled` event is emitted
  - Edge cases: boundary, invalid, missing-data, and repeat-run variants from the GDD edge-case section

---

## Test Evidence

**Story Type**: Integration
**Required evidence**:
- `tests/integration/offline_reward_settlement/warning-appears-and-other-rewards-still-apply_test.gd` — must exist and pass

**Status**: [x] Executed 2026-05-04

---

## Dependencies

- Depends on: Story 001 must be ready or done for shared test fixtures and baseline APIs
- Unlocks: None

## 2026-05-04 Sprint Execution Evidence

- Sprint execution order: Sprint 10, story 3/8
- Sprint source: `production/sprints/sprint-10.md`
- QA plan: `production/qa/qa-plan-sprint-10-2026-05-04.md`
- Automated evidence: `reports/report_13/results.xml` (137 tests, 0 failures, 0 skipped, 0 flaky)
- QA gate evidence: `production/qa/evidence/sprint-10-qa-result-2026-05-04.md`
- Verdict: Done; acceptance criteria reviewed against implementation, runtime tests, and sprint QA plan evidence.
- QA-plan automated tests:
  - `tests/integration/sprint10/sprint10_settlement_ui_hud_test.gd`
