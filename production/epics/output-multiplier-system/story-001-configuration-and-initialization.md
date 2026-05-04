# Story 001: Configuration and Initialization

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

- [x] AC-01: **GIVEN** `production_config.json` 包含 5 资源定义（lingqi base `"1.0"` allows_passive=true, xiuwei base `"0.1"` allows_passive=true, lingshi base `"0.1"` allows_passive=true, herb base `"0.02"` allows_passive=true, exp base `"0"` allows_passive=false），**WHEN** `OutputMultiplierSystem._ready()` 执行完毕，**THEN** `get_production_rate("lingqi") == 1.0`，`get_production_rate("xiuwei") == 0.1`，`get_production_rate("lingshi") == 0.1`，`get_production_rate("herb") == 0.02`，`get_production_rate("exp") == 0.0`，且各资源 `fractional_carry` 初始为 `0.0`
- [x] AC-02: **GIVEN** exp 的 `allows_passive = false`，且 target `"exp_production"` 下存在 realm modifier（value=1.0, MULT, pool="realm"），**WHEN** 调用 `get_production_rate("exp")`，**THEN** 返回 `0.0`（无视 modifier），且 `get_tick_amount("exp", 10.0)` 返回 `BigNumber.ZERO`，且 `activate_source({resource_id: "exp", source_type: "equipment", value: 0.15, source_id: "exp_src"})` 返回 `""` 并打印 warning
- [x] AC-03: **GIVEN** `DataConfig.get("production_config")` 返回空 Dictionary（配置缺失或不可解析），**WHEN** `load_config()` 执行，**THEN** 系统以零资源、空 base_rates / fractional_carry 初始化，`get_production_rate("lingqi")` 返回 `0.0`，`activate_source({...})` 对任何 resource_id 返回 `""`，不崩溃

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

- Story 002 covers the next acceptance group in this epic.

---

## QA Test Cases

*Written at story creation. The developer implements against these cases.*

- **Manual check**: AC-01: **GIVEN** `production_config.json` 包含 5 资源定义（lingqi base `"1.0"` allows_passive=true, xiuwei base `"0.1"` allows_passive=true, lingshi base `"0.1"` allows_passive=true, herb base `"0.02"` allows_passive=true, exp base `"0"` allows_passive=false），**WHEN** `OutputMultiplierSystem._ready()` 执行完毕，**THEN** `get_production_rate("lingqi") == 1.0`，`get_production_rate("xiuwei") == 0.1`，`get_production_rate("lingshi") == 0.1`，`get_production_rate("herb") == 0.02`，`get_production_rate("exp") == 0.0`，且各资源 `fractional_carry` 初始为 `0.0`
  - Setup: `production_config.json` 包含 5 资源定义（lingqi base `"1.0"` allows_passive=true, xiuwei base `"0.1"` allows_passive=true, lingshi base `"0.1"` allows_passive=true, herb base `"0.02"` allows_passive=true, exp base `"0"` allows_passive=false）
  - Verify: `OutputMultiplierSystem._ready()` 执行完毕
  - Pass condition: `get_production_rate("lingqi") == 1.0`，`get_production_rate("xiuwei") == 0.1`，`get_production_rate("lingshi") == 0.1`，`get_production_rate("herb") == 0.02`，`get_production_rate("exp") == 0.0`，且各资源 `fractional_carry` 初始为 `0.0`

- **Manual check**: AC-02: **GIVEN** exp 的 `allows_passive = false`，且 target `"exp_production"` 下存在 realm modifier（value=1.0, MULT, pool="realm"），**WHEN** 调用 `get_production_rate("exp")`，**THEN** 返回 `0.0`（无视 modifier），且 `get_tick_amount("exp", 10.0)` 返回 `BigNumber.ZERO`，且 `activate_source({resource_id: "exp", source_type: "equipment", value: 0.15, source_id: "exp_src"})` 返回 `""` 并打印 warning
  - Setup: exp 的 `allows_passive = false`，且 target `"exp_production"` 下存在 realm modifier（value=1.0, MULT, pool="realm"）
  - Verify: 调用 `get_production_rate("exp")`
  - Pass condition: 返回 `0.0`（无视 modifier），且 `get_tick_amount("exp", 10.0)` 返回 `BigNumber.ZERO`，且 `activate_source({resource_id: "exp", source_type: "equipment", value: 0.15, source_id: "exp_src"})` 返回 `""` 并打印 warning

- **Manual check**: AC-03: **GIVEN** `DataConfig.get("production_config")` 返回空 Dictionary（配置缺失或不可解析），**WHEN** `load_config()` 执行，**THEN** 系统以零资源、空 base_rates / fractional_carry 初始化，`get_production_rate("lingqi")` 返回 `0.0`，`activate_source({...})` 对任何 resource_id 返回 `""`，不崩溃
  - Setup: `DataConfig.get("production_config")` 返回空 Dictionary（配置缺失或不可解析）
  - Verify: `load_config()` 执行
  - Pass condition: 系统以零资源、空 base_rates / fractional_carry 初始化，`get_production_rate("lingqi")` 返回 `0.0`，`activate_source({...})` 对任何 resource_id 返回 `""`，不崩溃

---

## Test Evidence

**Story Type**: UI
**Required evidence**:
- `production/qa/evidence/configuration-and-initialization-evidence.md` — manual/interaction evidence with sign-off

**Status**: [x] Executed 2026-05-04

---

## Dependencies

- Depends on: None
- Unlocks: Story 002

## 2026-05-04 Sprint Execution Evidence

- Sprint execution order: Sprint 7, story 3/20
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
