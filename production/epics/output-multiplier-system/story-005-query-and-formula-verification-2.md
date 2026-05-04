# Story 005: Query and Formula Verification 2

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

- [ ] AC-12: **GIVEN** AC-10 的 4 池配置对 lingqi 生效，**WHEN** 调用 `get_multiplier("lingqi")`，**THEN** 返回 `3.30`，匹配 `M_total = 2.0 × 1.25 × 1.10 × 1.20`（Formula 3 文档化期望值）
- [ ] AC-13: **GIVEN** realm（value=1.0, source_id="realm_lianqi"）和 equipment（value=0.25, source_id="equip_ring"）对 lingqi 生效，base_rate = `1.0`，**WHEN** 调用 `get_breakdown("lingqi")`，**THEN** 返回 Dictionary 其中 `base_rate` = `1.0`，`add_sum` = `0.0`，`pools.realm` = `2.0`，`pools.equipment` = `1.25`，`pools.zone` = `1.0`（空池），`pools.buff` = `1.0`（空池），`final_multiplier` = `2.50`，`rate_per_second` = `2.50`，`fractional_carry` 为当前余数

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

- **Manual check**: AC-12: **GIVEN** AC-10 的 4 池配置对 lingqi 生效，**WHEN** 调用 `get_multiplier("lingqi")`，**THEN** 返回 `3.30`，匹配 `M_total = 2.0 × 1.25 × 1.10 × 1.20`（Formula 3 文档化期望值）
  - Setup: AC-10 的 4 池配置对 lingqi 生效
  - Verify: 调用 `get_multiplier("lingqi")`
  - Pass condition: 返回 `3.30`，匹配 `M_total = 2.0 × 1.25 × 1.10 × 1.20`（Formula 3 文档化期望值）

- **Manual check**: AC-13: **GIVEN** realm（value=1.0, source_id="realm_lianqi"）和 equipment（value=0.25, source_id="equip_ring"）对 lingqi 生效，base_rate = `1.0`，**WHEN** 调用 `get_breakdown("lingqi")`，**THEN** 返回 Dictionary 其中 `base_rate` = `1.0`，`add_sum` = `0.0`，`pools.realm` = `2.0`，`pools.equipment` = `1.25`，`pools.zone` = `1.0`（空池），`pools.buff` = `1.0`（空池），`final_multiplier` = `2.50`，`rate_per_second` = `2.50`，`fractional_carry` 为当前余数
  - Setup: realm（value=1.0, source_id="realm_lianqi"）和 equipment（value=0.25, source_id="equip_ring"）对 lingqi 生效，base_rate = `1.0`
  - Verify: 调用 `get_breakdown("lingqi")`
  - Pass condition: 返回 Dictionary 其中 `base_rate` = `1.0`，`add_sum` = `0.0`，`pools.realm` = `2.0`，`pools.equipment` = `1.25`，`pools.zone` = `1.0`（空池），`pools.buff` = `1.0`（空池），`final_multiplier` = `2.50`，`rate_per_second` = `2.50`，`fractional_carry` 为当前余数

---

## Test Evidence

**Story Type**: UI
**Required evidence**:
- `production/qa/evidence/query-and-formula-verification-2-evidence.md` — manual/interaction evidence with sign-off

**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: Story 001 must be ready or done for shared test fixtures and baseline APIs
- Unlocks: Story 006
