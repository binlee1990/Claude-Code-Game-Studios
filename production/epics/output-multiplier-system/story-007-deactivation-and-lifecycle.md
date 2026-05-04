# Story 007: Deactivation and Lifecycle

> **Epic**: 产出乘数系统
> **Status**: Ready
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

- [ ] AC-16: **GIVEN** equipment modifier `source_id: "equip_ring_001"`（value=0.15）对 lingqi 生效，`get_multiplier("lingqi")` = `1.15`，**WHEN** 调用 `deactivate_source("equip_ring_001")`，**THEN** 返回 `1`（一个 modifier 被移除），且 `get_multiplier("lingqi")` 返回 `1.0`，且 `get_production_rate("lingqi")` 返回 `1.0`
- [ ] AC-17: **GIVEN** buff modifier 对 lingqi 生效：`source_id: "buff_pill_001"`, `duration: 5.0`, `value: 0.20`，`get_multiplier("lingqi")` = `1.20`，**WHEN** `ModifierEngine.update(6.0)` 被调用（耗尽 duration 触发过期），`"modifier_expired"` 事件发射，**THEN** OMS 发射 `"production_multiplier_changed"` 事件 `action: "deactivated"`, `source_id: "buff_pill_001"`，且 `get_multiplier("lingqi")` 返回 `1.0`

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
- Story 008 covers the next acceptance group in this epic.

---

## QA Test Cases

*Written at story creation. The developer implements against these cases.*

- **Manual check**: AC-16: **GIVEN** equipment modifier `source_id: "equip_ring_001"`（value=0.15）对 lingqi 生效，`get_multiplier("lingqi")` = `1.15`，**WHEN** 调用 `deactivate_source("equip_ring_001")`，**THEN** 返回 `1`（一个 modifier 被移除），且 `get_multiplier("lingqi")` 返回 `1.0`，且 `get_production_rate("lingqi")` 返回 `1.0`
  - Setup: equipment modifier `source_id: "equip_ring_001"`（value=0.15）对 lingqi 生效，`get_multiplier("lingqi")` = `1.15`
  - Verify: 调用 `deactivate_source("equip_ring_001")`
  - Pass condition: 返回 `1`（一个 modifier 被移除），且 `get_multiplier("lingqi")` 返回 `1.0`，且 `get_production_rate("lingqi")` 返回 `1.0`

- **Manual check**: AC-17: **GIVEN** buff modifier 对 lingqi 生效：`source_id: "buff_pill_001"`, `duration: 5.0`, `value: 0.20`，`get_multiplier("lingqi")` = `1.20`，**WHEN** `ModifierEngine.update(6.0)` 被调用（耗尽 duration 触发过期），`"modifier_expired"` 事件发射，**THEN** OMS 发射 `"production_multiplier_changed"` 事件 `action: "deactivated"`, `source_id: "buff_pill_001"`，且 `get_multiplier("lingqi")` 返回 `1.0`
  - Setup: buff modifier 对 lingqi 生效：`source_id: "buff_pill_001"`, `duration: 5.0`, `value: 0.20`，`get_multiplier("lingqi")` = `1.20`
  - Verify: `ModifierEngine.update(6.0)` 被调用（耗尽 duration 触发过期），`"modifier_expired"` 事件发射
  - Pass condition: OMS 发射 `"production_multiplier_changed"` 事件 `action: "deactivated"`, `source_id: "buff_pill_001"`，且 `get_multiplier("lingqi")` 返回 `1.0`

---

## Test Evidence

**Story Type**: UI
**Required evidence**:
- `production/qa/evidence/deactivation-and-lifecycle-evidence.md` — manual/interaction evidence with sign-off

**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: Story 001 must be ready or done for shared test fixtures and baseline APIs
- Unlocks: Story 008
