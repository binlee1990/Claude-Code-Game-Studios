# Story 004: Query and Formula Verification 1

> **Epic**: 产出乘数系统
> **Status**: Done
> **Layer**: Core Gameplay
> **Type**: UI
> **Manifest Version**: 2026-05-04

## Context

**GDD**: `design/gdd/output-multiplier-system.md`
**Requirement**: `TR-output-multiplier-001` — OutputMultiplierSystem translates production config and modifier pools into per-resource production rates and tick amounts.

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

*From GDD `design/gdd/output-multiplier-system.md`, scoped to this story:*

- [x] AC-09: **GIVEN** target `"lingqi_production"` 下无任何 modifier，**WHEN** 调用 `get_production_rate("lingqi")`，**THEN** 返回 `1.0`（base_rate × 1.0）
- [x] AC-10: **GIVEN** lingqi 下 4 个来源均激活：realm value=1.0（池倍率 2.0）、equipment 两件 value=0.15+0.10（池倍率 1.25）、zone value=0.10（池倍率 1.10）、buff value=0.20（池倍率 1.20），总 final_mult = 2.0 × 1.25 × 1.10 × 1.20 = 3.30，**WHEN** 调用 `get_production_rate("lingqi")`，**THEN** 返回 `3.30`
- [x] AC-11: **GIVEN** `get_production_rate("lingshi")` 返回 `0.33`（base 0.1 × multiplier 3.30），**WHEN** 在 fresh carry 状态下调用 `get_tick_amount("lingshi", 0.5)`，**THEN** 返回 `BigNumber.ZERO` 且 `fractional_carry["lingshi"] == 0.165`；**WHEN** 在 fresh carry 状态下调用 `get_tick_amount("lingshi", 1800.0)`，**THEN** 返回 `BigNumber.from_float(594.0)` 且 carry 归零

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
- Story 005 covers the next acceptance group in this epic.

---

## QA Test Cases

*Written at story creation. The developer implements against these cases.*

- **Manual check**: AC-09: **GIVEN** target `"lingqi_production"` 下无任何 modifier，**WHEN** 调用 `get_production_rate("lingqi")`，**THEN** 返回 `1.0`（base_rate × 1.0）
  - Setup: target `"lingqi_production"` 下无任何 modifier
  - Verify: 调用 `get_production_rate("lingqi")`
  - Pass condition: 返回 `1.0`（base_rate × 1.0）

- **Manual check**: AC-10: **GIVEN** lingqi 下 4 个来源均激活：realm value=1.0（池倍率 2.0）、equipment 两件 value=0.15+0.10（池倍率 1.25）、zone value=0.10（池倍率 1.10）、buff value=0.20（池倍率 1.20），总 final_mult = 2.0 × 1.25 × 1.10 × 1.20 = 3.30，**WHEN** 调用 `get_production_rate("lingqi")`，**THEN** 返回 `3.30`
  - Setup: lingqi 下 4 个来源均激活：realm value=1.0（池倍率 2.0）、equipment 两件 value=0.15+0.10（池倍率 1.25）、zone value=0.10（池倍率 1.10）、buff value=0.20（池倍率 1.20），总 final_mult = 2.0 × 1.25 × 1.10 × 1.20 = 3.30
  - Verify: 调用 `get_production_rate("lingqi")`
  - Pass condition: 返回 `3.30`

- **Manual check**: AC-11: **GIVEN** `get_production_rate("lingshi")` 返回 `0.33`（base 0.1 × multiplier 3.30），**WHEN** 在 fresh carry 状态下调用 `get_tick_amount("lingshi", 0.5)`，**THEN** 返回 `BigNumber.ZERO` 且 `fractional_carry["lingshi"] == 0.165`；**WHEN** 在 fresh carry 状态下调用 `get_tick_amount("lingshi", 1800.0)`，**THEN** 返回 `BigNumber.from_float(594.0)` 且 carry 归零
  - Setup: `get_production_rate("lingshi")` 返回 `0.33`（base 0.1 × multiplier 3.30）
  - Verify: 在 fresh carry 状态下调用 `get_tick_amount("lingshi", 0.5)`
  - Pass condition: 返回 `BigNumber.ZERO` 且 `fractional_carry["lingshi"] == 0.165`；WHEN 在 fresh carry 状态下调用 `get_tick_amount("lingshi", 1800.0)`，THEN 返回 `BigNumber.from_float(594.0)` 且 carry 归零

---

## Test Evidence

**Story Type**: UI
**Required evidence**:
- `production/qa/evidence/query-and-formula-verification-1-evidence.md` — manual/interaction evidence with sign-off

**Status**: [x] Executed 2026-05-04

---

## Dependencies

- Depends on: Story 001 must be ready or done for shared test fixtures and baseline APIs
- Unlocks: Story 005

## 2026-05-04 Sprint Execution Evidence

- Sprint execution order: Sprint 7, story 6/20
- Sprint source: `production/sprints/sprint-7.md`
- QA plan: `production/qa/qa-plan-sprint-7-2026-05-04.md`
- Automated evidence: `reports/report_13/results.xml` (137 tests, 0 failures, 0 skipped, 0 flaky)
- QA gate evidence: `production/qa/evidence/sprint-7-qa-result-2026-05-04.md`
- Verdict: Done; acceptance criteria reviewed against implementation, runtime tests, and sprint QA plan evidence.
- QA-plan automated tests:
  - `tests/integration/item_registry/item_registry_boundary_test.gd`
  - `tests/unit/output_multiplier_system/output_multiplier_system_config_test.gd`
  - `tests/unit/output_multiplier_system/output_multiplier_system_formula_test.gd`
  - `tests/integration/output_multiplier_system/output_multiplier_events_test.gd`
  - `tests/unit/debug_console/debug_console_command_test.gd`
  - `tests/integration/debug_console/debug_console_smoke_test.gd`
