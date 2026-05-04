# Story 001: loot is rolled and combat finished event includes victory

> **Epic**: 半自动战斗系统
> **Status**: Done
> **Layer**: Feature Integration
> **Type**: Integration
> **Manifest Version**: 2026-05-04

## Context

**GDD**: `design/gdd/semi-auto-combat-system.md`
**Requirement**: `TR-semi-auto-combat-001` — SemiAutoCombatSystem orchestrates online encounter loops through CombatCalculator, EnemyDatabase, LootSystem, LevelSystem, and EventBus.

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

*From GDD `design/gdd/semi-auto-combat-system.md`, scoped to this story:*

- [x] GIVEN: current zone has valid enemies and player wins, **WHEN** encounter resolves, **THEN** loot is rolled and combat finished event includes victory.
- [x] GIVEN: player loses, **WHEN** encounter resolves, **THEN** no loot is rolled and failure cooldown starts.
- [x] GIVEN: same seed context and same snapshots, **WHEN** online combat and offline combat call calculator, **THEN** result parity is possible.

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

- Story 002 covers the next acceptance group in this epic.

---

## QA Test Cases

*Written at story creation. The developer implements against these cases.*

- **AC**: GIVEN: current zone has valid enemies and player wins, **WHEN** encounter resolves, **THEN** loot is rolled and combat finished event includes victory.
  - Given: current zone has valid enemies and player wins
  - When: encounter resolves
  - Then: loot is rolled and combat finished event includes victory
  - Edge cases: boundary, invalid, missing-data, and repeat-run variants from the GDD edge-case section

- **AC**: GIVEN: player loses, **WHEN** encounter resolves, **THEN** no loot is rolled and failure cooldown starts.
  - Given: player loses
  - When: encounter resolves
  - Then: no loot is rolled and failure cooldown starts
  - Edge cases: boundary, invalid, missing-data, and repeat-run variants from the GDD edge-case section

- **AC**: GIVEN: same seed context and same snapshots, **WHEN** online combat and offline combat call calculator, **THEN** result parity is possible.
  - Given: same seed context and same snapshots
  - When: online combat and offline combat call calculator
  - Then: result parity is possible
  - Edge cases: boundary, invalid, missing-data, and repeat-run variants from the GDD edge-case section

---

## Test Evidence

**Story Type**: Integration
**Required evidence**:
- `tests/integration/semi_auto_combat/loot-is-rolled-and-combat-finished-event-includes-victor_test.gd` — must exist and pass

**Status**: [x] Executed 2026-05-04

---

## Dependencies

- Depends on: None
- Unlocks: Story 002

## 2026-05-04 Sprint Execution Evidence

- Sprint execution order: Sprint 9, story 12/20
- Sprint source: `production/sprints/sprint-9.md`
- QA plan: `production/qa/qa-plan-sprint-9-2026-05-04.md`
- Automated evidence: `reports/report_13/results.xml` (137 tests, 0 failures, 0 skipped, 0 flaky)
- QA gate evidence: `production/qa/evidence/sprint-9-qa-result-2026-05-04.md`
- Verdict: Done; acceptance criteria reviewed against implementation, runtime tests, and sprint QA plan evidence.
- QA-plan automated tests:
  - `tests/integration/sprint9/sprint9_feature_stack_test.gd`
