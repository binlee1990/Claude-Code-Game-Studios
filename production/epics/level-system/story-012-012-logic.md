# Story 012: 性能 / 内存

> **Epic**: 等级系统
> **Status**: Done
> **Layer**: Feature
> **Type**: Logic
> **Manifest Version**: 2026-05-04

## Context

**GDD**: `design/gdd/level-system.md`
**Requirement**: `TR-level-system-001` — LevelSystem handles level/experience/realm progression using approved data, formulas, resource, modifier, event, and save boundaries.

**ADR Governing Implementation**: ADR-0007: 修正器叠加顺序
**ADR Decision Summary**: Use one `ModifierEngine` service with a three-stage pipeline: `base + add_sum`, then same-pool additive percentage multipliers, then cross-pool multiplication. MVP pools are `equipment`, `realm`, `zone`, and `buff`. Targets are strings such as `player.atk` and `lingqi_production`.

**Engine**: Godot 4.6.2 | **Risk**: LOW
**Engine Notes**: ADR-0007 status is Accepted; verify any Godot 4.6.2 behavior named by the ADR before closing the story.

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

*From GDD `design/gdd/level-system.md`, scoped to this story:*

- [x] GIVEN: Lv.10，**WHEN** 单次 `gain_exp` 升 1 级（不跨境界），**THEN** 总耗时 < 0.333 ms（帧预算）
- [x] GIVEN: Lv.1 连升 100 级跨 1 境界（最坏路径），**WHEN** 单次 `gain_exp`，**THEN** 总耗时 < 3.0 ms（接受单帧超支）
- [x] GIVEN: Lv.30 jindan，**WHEN** 内存采样，**THEN** `_entries["player"]` < 200 bytes；ModifierEngine 中 realm modifier 共 10 条 ≈ 1.2 KB
- [x] GIVEN: 1000 次连续 `get_level("player")` 查询，**WHEN** 完成，**THEN** 平均单次 < 0.005 ms

---

## Implementation Notes

*Derived from ADR-0007 Implementation Guidelines:*

- Must apply modifiers in the order ADD, same-pool additive MULT, cross-pool multiplicative MULT.
- Must use `"{entity_id}.{attr_id}"` for attribute targets.
- Must use `"{resource_id}_production"` for production targets.
- Must cache clean target multiplier results and invalidate on register/unregister/expiry.
- Must emit `modifier_expired` when duration-based modifiers expire.
- Must not evaluate business-specific conditions in ModifierEngine.

---

## Out of Scope

- Story 001 covers the baseline contract for this epic; do not duplicate its setup work here.

---

## QA Test Cases

*Written at story creation. The developer implements against these cases.*

- **AC**: GIVEN: Lv.10，**WHEN** 单次 `gain_exp` 升 1 级（不跨境界），**THEN** 总耗时 < 0.333 ms（帧预算）
  - Given: Lv.10
  - When: 单次 `gain_exp` 升 1 级（不跨境界）
  - Then: 总耗时 < 0.333 ms（帧预算）
  - Edge cases: boundary, invalid, missing-data, and repeat-run variants from the GDD edge-case section

- **AC**: GIVEN: Lv.1 连升 100 级跨 1 境界（最坏路径），**WHEN** 单次 `gain_exp`，**THEN** 总耗时 < 3.0 ms（接受单帧超支）
  - Given: Lv.1 连升 100 级跨 1 境界（最坏路径）
  - When: 单次 `gain_exp`
  - Then: 总耗时 < 3.0 ms（接受单帧超支）
  - Edge cases: boundary, invalid, missing-data, and repeat-run variants from the GDD edge-case section

- **AC**: GIVEN: Lv.30 jindan，**WHEN** 内存采样，**THEN** `_entries["player"]` < 200 bytes；ModifierEngine 中 realm modifier 共 10 条 ≈ 1.2 KB
  - Given: Lv.30 jindan
  - When: 内存采样
  - Then: `_entries["player"]` < 200 bytes；ModifierEngine 中 realm modifier 共 10 条 ≈ 1.2 KB
  - Edge cases: boundary, invalid, missing-data, and repeat-run variants from the GDD edge-case section

- **AC**: GIVEN: 1000 次连续 `get_level("player")` 查询，**WHEN** 完成，**THEN** 平均单次 < 0.005 ms
  - Given: 1000 次连续 `get_level("player")` 查询
  - When: 完成
  - Then: 平均单次 < 0.005 ms
  - Edge cases: boundary, invalid, missing-data, and repeat-run variants from the GDD edge-case section

---

## Test Evidence

**Story Type**: Logic
**Required evidence**:
- `tests/unit/level/012-logic_test.gd` — must exist and pass

**Status**: [x] Executed 2026-05-04

---

## Dependencies

- Depends on: Story 001 must be ready or done for shared test fixtures and baseline APIs
- Unlocks: None

## 2026-05-04 Sprint Execution Evidence

- Sprint execution order: Sprint 8, story 20/20
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
