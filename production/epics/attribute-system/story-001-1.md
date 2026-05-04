# Story 001: 实体生命周期 1

> **Epic**: 属性系统
> **Status**: Done
> **Layer**: Core Gameplay
> **Type**: Config/Data
> **Manifest Version**: 2026-05-04

## Context

**GDD**: `design/gdd/attribute-system.md`
**Requirement**: `TR-attribute-system-001` — AttributeSystem owns entity attribute base values, final-value queries through ModifierEngine, events, snapshot, and restore.

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

*From GDD `design/gdd/attribute-system.md`, scoped to this story:*

- [x] GIVEN: `AttributeSystem` 已加载，`attribute_set_config.json` 含 `"player_set"` schema (含 6 项 MVP 属性)，**WHEN** 调用 `register_entity("player", {category:"player", attribute_set:"player_set"})`，**THEN** 返回 `true`，`has_entity("player") == true`，`get_attribute_set("player")` 返回含 6 个 attr_id 的 Dictionary
- [x] GIVEN: `"player"` 已注册，**WHEN** 再次调用 `register_entity("player", ...)`，**THEN** 返回 `false`，已有条目不变，打印警告
- [x] GIVEN: `definition.attribute_set` 为未知 schema `"unknown_set"`，**WHEN** `register_entity("test", ...)`，**THEN** 返回 `false`，`has_entity("test") == false`，打印警告

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

- **AC**: GIVEN: `AttributeSystem` 已加载，`attribute_set_config.json` 含 `"player_set"` schema (含 6 项 MVP 属性)，**WHEN** 调用 `register_entity("player", {category:"player", attribute_set:"player_set"})`，**THEN** 返回 `true`，`has_entity("player") == true`，`get_attribute_set("player")` 返回含 6 个 attr_id 的 Dictionary
  - Given: `AttributeSystem` 已加载，`attribute_set_config.json` 含 `"player_set"` schema (含 6 项 MVP 属性)
  - When: 调用 `register_entity("player", {category:"player", attribute_set:"player_set"})`
  - Then: 返回 `true`，`has_entity("player") == true`，`get_attribute_set("player")` 返回含 6 个 attr_id 的 Dictionary
  - Edge cases: boundary, invalid, missing-data, and repeat-run variants from the GDD edge-case section

- **AC**: GIVEN: `"player"` 已注册，**WHEN** 再次调用 `register_entity("player", ...)`，**THEN** 返回 `false`，已有条目不变，打印警告
  - Given: `"player"` 已注册
  - When: 再次调用 `register_entity("player", ...)`
  - Then: 返回 `false`，已有条目不变，打印警告
  - Edge cases: boundary, invalid, missing-data, and repeat-run variants from the GDD edge-case section

- **AC**: GIVEN: `definition.attribute_set` 为未知 schema `"unknown_set"`，**WHEN** `register_entity("test", ...)`，**THEN** 返回 `false`，`has_entity("test") == false`，打印警告
  - Given: `definition.attribute_set` 为未知 schema `"unknown_set"`
  - When: `register_entity("test", ...)`
  - Then: 返回 `false`，`has_entity("test") == false`，打印警告
  - Edge cases: boundary, invalid, missing-data, and repeat-run variants from the GDD edge-case section

---

## Test Evidence

**Story Type**: Config/Data
**Required evidence**:
- `production/qa/smoke-attribute-system.md` — smoke check evidence

**Status**: [x] Executed 2026-05-04

---

## Dependencies

- Depends on: None
- Unlocks: Story 002

## 2026-05-04 Sprint Execution Evidence

- Sprint execution order: Sprint 5, story 14/20
- Sprint source: `production/sprints/sprint-5.md`
- QA plan: `production/qa/qa-plan-sprint-5-2026-05-04.md`
- Automated evidence: `reports/report_13/results.xml` (137 tests, 0 failures, 0 skipped, 0 flaky)
- QA gate evidence: `production/qa/evidence/sprint-5-qa-result-2026-05-04.md`
- Verdict: Done; acceptance criteria reviewed against implementation, runtime tests, and sprint QA plan evidence.
- QA-plan automated tests:
  - `tests/unit/resource_system/resource_system_crud_test.gd`
  - `tests/integration/resource_system/resource_system_state_test.gd`
  - `tests/unit/attribute_system/attribute_system_crud_test.gd`
  - `tests/integration/attribute_system/attribute_system_final_test.gd`
