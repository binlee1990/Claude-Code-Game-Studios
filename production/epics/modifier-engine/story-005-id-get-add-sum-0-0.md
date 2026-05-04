# Story 005: 成功返回 ID，`get_add_sum` 包含 `0.0` 贡献

> **Epic**: 修正器/倍率引擎
> **Status**: Done
> **Layer**: Core Data
> **Type**: Logic
> **Manifest Version**: 2026-05-04

## Context

**GDD**: `design/gdd/modifier-engine.md`
**Requirement**: `TR-modifier-engine-001` — ModifierEngine owns modifier registration, target naming, ADD and MULT pool stacking, cache invalidation, and expiry events.

**ADR Governing Implementation**: ADR-0007: 修正器叠加顺序
**ADR Decision Summary**: Use one `ModifierEngine` service with a three-stage pipeline: `base + add_sum`, then same-pool additive percentage multipliers, then cross-pool multiplication. MVP pools are `equipment`, `realm`, `zone`, and `buff`. Targets are strings such as `player.atk` and `lingqi_production`.

**Engine**: Godot 4.6.2 | **Risk**: LOW
**Engine Notes**: ADR-0007 status is Accepted; verify any Godot 4.6.2 behavior named by the ADR before closing the story.

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

*From GDD `design/gdd/modifier-engine.md`, scoped to this story:*

- [x] GIVEN: 修正器 value=0，**WHEN** 注册，**THEN** 成功返回 ID，`get_add_sum` 包含 `0.0` 贡献
- [x] GIVEN: 同一 source 注册两个不同 target 的修正器，**WHEN** 调用 `unregister_by_source()`，**THEN** 两个 target 的修正器均被移除
- [x] GIVEN: target 有修正器，**WHEN** 调用 `get_breakdown("atk")`，**THEN** 返回包含 `add_sum`、`pools` 字典和 `final_mult` 的 Dictionary

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
- Story 006 covers the next acceptance group in this epic.

---

## QA Test Cases

*Written at story creation. The developer implements against these cases.*

- **AC**: GIVEN: 修正器 value=0，**WHEN** 注册，**THEN** 成功返回 ID，`get_add_sum` 包含 `0.0` 贡献
  - Given: 修正器 value=0
  - When: 注册
  - Then: 成功返回 ID，`get_add_sum` 包含 `0.0` 贡献
  - Edge cases: boundary, invalid, missing-data, and repeat-run variants from the GDD edge-case section

- **AC**: GIVEN: 同一 source 注册两个不同 target 的修正器，**WHEN** 调用 `unregister_by_source()`，**THEN** 两个 target 的修正器均被移除
  - Given: 同一 source 注册两个不同 target 的修正器
  - When: 调用 `unregister_by_source()`
  - Then: 两个 target 的修正器均被移除
  - Edge cases: boundary, invalid, missing-data, and repeat-run variants from the GDD edge-case section

- **AC**: GIVEN: target 有修正器，**WHEN** 调用 `get_breakdown("atk")`，**THEN** 返回包含 `add_sum`、`pools` 字典和 `final_mult` 的 Dictionary
  - Given: target 有修正器
  - When: 调用 `get_breakdown("atk")`
  - Then: 返回包含 `add_sum`、`pools` 字典和 `final_mult` 的 Dictionary
  - Edge cases: boundary, invalid, missing-data, and repeat-run variants from the GDD edge-case section

---

## Test Evidence

**Story Type**: Logic
**Required evidence**:
- `tests/unit/modifier_engine/id-get-add-sum-0-0_test.gd` — must exist and pass

**Status**: [x] Executed 2026-05-04

---

## Dependencies

- Depends on: Story 001 must be ready or done for shared test fixtures and baseline APIs
- Unlocks: Story 006

## 2026-05-04 Sprint Execution Evidence

- Sprint execution order: Sprint 4, story 10/20
- Sprint source: `production/sprints/sprint-4.md`
- QA plan: `production/qa/qa-plan-sprint-4-2026-05-04.md`
- Automated evidence: `reports/report_13/results.xml` (137 tests, 0 failures, 0 skipped, 0 flaky)
- QA gate evidence: `production/qa/evidence/sprint-4-qa-result-2026-05-04.md`
- Verdict: Done; acceptance criteria reviewed against implementation, runtime tests, and sprint QA plan evidence.
- QA-plan automated tests:
  - `tests/unit/formula_engine/formula_engine_edges_test.gd`
  - `tests/unit/modifier_engine/modifier_engine_test.gd`
  - `tests/unit/save_system/save_manager_collect_test.gd`
  - `tests/integration/save_system/save_manager_file_contract_test.gd`
