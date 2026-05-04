# Story 006: Within-Pool Additivity and Cross-Pool Multiplicativity

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

- [ ] AC-14: **GIVEN** 两个 equipment modifier 对 lingqi 生效：source "equip_a" value=0.15 + source "equip_b" value=0.10，无其他 modifier，**WHEN** 调用 ModifierEngine 的 `get_pool_multiplier("lingqi_production", "equipment")` 和 OMS 的 `get_multiplier("lingqi")`，**THEN** equipment 池倍率为 `1.25`（1.0 + 0.15 + 0.10），**NOT** `1.265`（1.15 × 1.10），且 `get_multiplier("lingqi")` 返回 `1.25`
- [ ] AC-15: **GIVEN** lingqi 下 realm modifier（value=1.0, 池倍率 2.0）和 zone modifier（value=0.10, 池倍率 1.10）生效，无其他 modifier，**WHEN** 调用 `get_multiplier("lingqi")`，**THEN** 返回 `2.20`（2.0 × 1.10），确认两池独立相乘而非值先加总

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
- Story 007 covers the next acceptance group in this epic.

---

## QA Test Cases

*Written at story creation. The developer implements against these cases.*

- **Manual check**: AC-14: **GIVEN** 两个 equipment modifier 对 lingqi 生效：source "equip_a" value=0.15 + source "equip_b" value=0.10，无其他 modifier，**WHEN** 调用 ModifierEngine 的 `get_pool_multiplier("lingqi_production", "equipment")` 和 OMS 的 `get_multiplier("lingqi")`，**THEN** equipment 池倍率为 `1.25`（1.0 + 0.15 + 0.10），**NOT** `1.265`（1.15 × 1.10），且 `get_multiplier("lingqi")` 返回 `1.25`
  - Setup: 两个 equipment modifier 对 lingqi 生效：source "equip_a" value=0.15 + source "equip_b" value=0.10，无其他 modifier
  - Verify: 调用 ModifierEngine 的 `get_pool_multiplier("lingqi_production", "equipment")` 和 OMS 的 `get_multiplier("lingqi")`
  - Pass condition: equipment 池倍率为 `1.25`（1.0 + 0.15 + 0.10），NOT `1.265`（1.15 × 1.10），且 `get_multiplier("lingqi")` 返回 `1.25`

- **Manual check**: AC-15: **GIVEN** lingqi 下 realm modifier（value=1.0, 池倍率 2.0）和 zone modifier（value=0.10, 池倍率 1.10）生效，无其他 modifier，**WHEN** 调用 `get_multiplier("lingqi")`，**THEN** 返回 `2.20`（2.0 × 1.10），确认两池独立相乘而非值先加总
  - Setup: lingqi 下 realm modifier（value=1.0, 池倍率 2.0）和 zone modifier（value=0.10, 池倍率 1.10）生效，无其他 modifier
  - Verify: 调用 `get_multiplier("lingqi")`
  - Pass condition: 返回 `2.20`（2.0 × 1.10），确认两池独立相乘而非值先加总

---

## Test Evidence

**Story Type**: UI
**Required evidence**:
- `production/qa/evidence/within-pool-additivity-and-cross-pool-multiplicativity-evidence.md` — manual/interaction evidence with sign-off

**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: Story 001 must be ready or done for shared test fixtures and baseline APIs
- Unlocks: Story 007
