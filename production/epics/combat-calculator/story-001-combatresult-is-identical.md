# Story 001: CombatResult is identical

> **Epic**: 战斗计算器
> **Status**: Done
> **Layer**: Feature Integration
> **Type**: Integration
> **Manifest Version**: 2026-05-04

## Context

**GDD**: `design/gdd/combat-calculator.md`
**Requirement**: `TR-combat-calculator-001` — CombatCalculator provides the shared attack/damage resolution path for online and offline combat.

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

*From GDD `design/gdd/combat-calculator.md`, scoped to this story:*

- [x] GIVEN: identical snapshots and seed, **WHEN** simulate runs twice, **THEN** CombatResult is identical.
- [x] GIVEN: player atk increases while enemy unchanged, **WHEN** simulate runs, **THEN** average time-to-kill does not increase over enough seeded samples.
- [x] GIVEN: defender def exceeds attacker atk, **WHEN** attack resolves, **THEN** damage is at least MIN_DAMAGE.

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

- **AC**: GIVEN: identical snapshots and seed, **WHEN** simulate runs twice, **THEN** CombatResult is identical.
  - Given: identical snapshots and seed
  - When: simulate runs twice
  - Then: CombatResult is identical
  - Edge cases: boundary, invalid, missing-data, and repeat-run variants from the GDD edge-case section

- **AC**: GIVEN: player atk increases while enemy unchanged, **WHEN** simulate runs, **THEN** average time-to-kill does not increase over enough seeded samples.
  - Given: player atk increases while enemy unchanged
  - When: simulate runs
  - Then: average time-to-kill does not increase over enough seeded samples
  - Edge cases: boundary, invalid, missing-data, and repeat-run variants from the GDD edge-case section

- **AC**: GIVEN: defender def exceeds attacker atk, **WHEN** attack resolves, **THEN** damage is at least MIN_DAMAGE.
  - Given: defender def exceeds attacker atk
  - When: attack resolves
  - Then: damage is at least MIN_DAMAGE
  - Edge cases: boundary, invalid, missing-data, and repeat-run variants from the GDD edge-case section

---

## Test Evidence

**Story Type**: Integration
**Required evidence**:
- `tests/integration/combat_calculator/combatresult-is-identical_test.gd` — must exist and pass

**Status**: [x] Executed 2026-05-04

---

## Dependencies

- Depends on: None
- Unlocks: Story 002

## 2026-05-04 Sprint Execution Evidence

- Sprint execution order: Sprint 9, story 6/20
- Sprint source: `production/sprints/sprint-9.md`
- QA plan: `production/qa/qa-plan-sprint-9-2026-05-04.md`
- Automated evidence: `reports/report_13/results.xml` (137 tests, 0 failures, 0 skipped, 0 flaky)
- QA gate evidence: `production/qa/evidence/sprint-9-qa-result-2026-05-04.md`
- Verdict: Done; acceptance criteria reviewed against implementation, runtime tests, and sprint QA plan evidence.
- QA-plan automated tests:
  - `tests/integration/sprint9/sprint9_feature_stack_test.gd`
