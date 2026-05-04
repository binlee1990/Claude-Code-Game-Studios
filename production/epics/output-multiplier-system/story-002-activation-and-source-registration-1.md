# Story 002: Activation and Source Registration 1

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

- [x] AC-04: **GIVEN** target `"lingqi_production"` 下无任何 modifier（`get_multiplier("lingqi")` 返回 `1.0`），**WHEN** 调用 `activate_source({resource_id: "lingqi", source_type: "equipment", value: 0.15, source_id: "equip_ring_001"})`，**THEN** 返回非空 modifier ID 字符串，且 `get_multiplier("lingqi")` 返回 `1.15`，且 `get_production_rate("lingqi")` 返回 `1.15`
- [x] AC-05: **GIVEN** target `"lingqi_production"` 下无 modifier，**WHEN** 调用 `activate_source({resource_id: "lingqi", source_type: "realm", value: 1.0, source_id: "realm_liandan"})`，然后 `get_breakdown("lingqi")`，**THEN** `pools["realm"]` 等于 `2.0`（1.0 + 1.0），且 modifier 在 ModifierEngine 中以 `pool = "realm"` 和 `target = "lingqi_production"` 注册
- [x] AC-06: **GIVEN** `activate_source({..., source_id: "equip_ring_001"})` 已成功执行，**WHEN** 再次以相同 `source_id` 调用 `activate_source`（中间未 deactivate），**THEN** 返回 `""`，打印 warning，`get_multiplier("lingqi")` 保持首次激活的值不变

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
- Story 003 covers the next acceptance group in this epic.

---

## QA Test Cases

*Written at story creation. The developer implements against these cases.*

- **Manual check**: AC-04: **GIVEN** target `"lingqi_production"` 下无任何 modifier（`get_multiplier("lingqi")` 返回 `1.0`），**WHEN** 调用 `activate_source({resource_id: "lingqi", source_type: "equipment", value: 0.15, source_id: "equip_ring_001"})`，**THEN** 返回非空 modifier ID 字符串，且 `get_multiplier("lingqi")` 返回 `1.15`，且 `get_production_rate("lingqi")` 返回 `1.15`
  - Setup: target `"lingqi_production"` 下无任何 modifier（`get_multiplier("lingqi")` 返回 `1.0`）
  - Verify: 调用 `activate_source({resource_id: "lingqi", source_type: "equipment", value: 0.15, source_id: "equip_ring_001"})`
  - Pass condition: 返回非空 modifier ID 字符串，且 `get_multiplier("lingqi")` 返回 `1.15`，且 `get_production_rate("lingqi")` 返回 `1.15`

- **Manual check**: AC-05: **GIVEN** target `"lingqi_production"` 下无 modifier，**WHEN** 调用 `activate_source({resource_id: "lingqi", source_type: "realm", value: 1.0, source_id: "realm_liandan"})`，然后 `get_breakdown("lingqi")`，**THEN** `pools["realm"]` 等于 `2.0`（1.0 + 1.0），且 modifier 在 ModifierEngine 中以 `pool = "realm"` 和 `target = "lingqi_production"` 注册
  - Setup: target `"lingqi_production"` 下无 modifier
  - Verify: 调用 `activate_source({resource_id: "lingqi", source_type: "realm", value: 1.0, source_id: "realm_liandan"})`，然后 `get_breakdown("lingqi")`
  - Pass condition: `pools["realm"]` 等于 `2.0`（1.0 + 1.0），且 modifier 在 ModifierEngine 中以 `pool = "realm"` 和 `target = "lingqi_production"` 注册

- **Manual check**: AC-06: **GIVEN** `activate_source({..., source_id: "equip_ring_001"})` 已成功执行，**WHEN** 再次以相同 `source_id` 调用 `activate_source`（中间未 deactivate），**THEN** 返回 `""`，打印 warning，`get_multiplier("lingqi")` 保持首次激活的值不变
  - Setup: `activate_source({..., source_id: "equip_ring_001"})` 已成功执行
  - Verify: 再次以相同 `source_id` 调用 `activate_source`（中间未 deactivate）
  - Pass condition: 返回 `""`，打印 warning，`get_multiplier("lingqi")` 保持首次激活的值不变

---

## Test Evidence

**Story Type**: UI
**Required evidence**:
- `production/qa/evidence/activation-and-source-registration-1-evidence.md` — manual/interaction evidence with sign-off

**Status**: [x] Executed 2026-05-04

---

## Dependencies

- Depends on: Story 001 must be ready or done for shared test fixtures and baseline APIs
- Unlocks: Story 003

## 2026-05-04 Sprint Execution Evidence

- Sprint execution order: Sprint 7, story 4/20
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
