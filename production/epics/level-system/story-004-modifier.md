# Story 004: 境界跨越 + modifier

> **Epic**: 等级系统
> **Status**: Ready
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

- [ ] GIVEN: Lv.9 (fanren)，**WHEN** gain_exp 升至 Lv.10，**THEN** `get_realm == "lianqi"`，`get_realm_id == 1`，ModifierEngine 注册 10 条 source=`"level_system.realm.player.lianqi"` 的 modifier（4 OMS + 6 attribute），每条 value=0.20，发 `realm.advanced{old="fanren", new="lianqi"}`
- [ ] GIVEN: Lv.9 (fanren)，**WHEN** gain_exp 一次性跨 fanren → lianqi → zhuji 升至 Lv.31，**THEN** ModifierEngine 中**只有 1 个 source**（`"level_system.realm.player.zhuji"`，value=0.50）的 10 条 modifier；fanren / lianqi 的 source 永不出现；`realm.advanced` 仅发 1 条 (old="fanren", new="zhuji")
- [ ] GIVEN: Lv.30 (zhuji)，**WHEN** `ModifierEngine.get_multiplier("player.atk")`，**THEN** 返回 1.50（= 1.0 + 0.50 累计 MULT）

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

- **AC**: GIVEN: Lv.9 (fanren)，**WHEN** gain_exp 升至 Lv.10，**THEN** `get_realm == "lianqi"`，`get_realm_id == 1`，ModifierEngine 注册 10 条 source=`"level_system.realm.player.lianqi"` 的 modifier（4 OMS + 6 attribute），每条 value=0.20，发 `realm.advanced{old="fanren", new="lianqi"}`
  - Given: Lv.9 (fanren)
  - When: gain_exp 升至 Lv.10
  - Then: `get_realm == "lianqi"`，`get_realm_id == 1`，ModifierEngine 注册 10 条 source=`"level_system.realm.player.lianqi"` 的 modifier（4 OMS + 6 attribute），每条 value=0.20，发 `realm.advanced{old="fanren", new="lianqi"}`
  - Edge cases: boundary, invalid, missing-data, and repeat-run variants from the GDD edge-case section

- **AC**: GIVEN: Lv.9 (fanren)，**WHEN** gain_exp 一次性跨 fanren → lianqi → zhuji 升至 Lv.31，**THEN** ModifierEngine 中**只有 1 个 source**（`"level_system.realm.player.zhuji"`，value=0.50）的 10 条 modifier；fanren / lianqi 的 source 永不出现；`realm.advanced` 仅发 1 条 (old="fanren", new="zhuji")
  - Given: Lv.9 (fanren)
  - When: gain_exp 一次性跨 fanren → lianqi → zhuji 升至 Lv.31
  - Then: ModifierEngine 中只有 1 个 source（`"level_system.realm.player.zhuji"`，value=0.50）的 10 条 modifier；fanren / lianqi 的 source 永不出现；`realm.advanced` 仅发 1 条 (old="fanren", new="zhuji")
  - Edge cases: boundary, invalid, missing-data, and repeat-run variants from the GDD edge-case section

- **AC**: GIVEN: Lv.30 (zhuji)，**WHEN** `ModifierEngine.get_multiplier("player.atk")`，**THEN** 返回 1.50（= 1.0 + 0.50 累计 MULT）
  - Given: Lv.30 (zhuji)
  - When: `ModifierEngine.get_multiplier("player.atk")`
  - Then: 返回 1.50（= 1.0 + 0.50 累计 MULT）
  - Edge cases: boundary, invalid, missing-data, and repeat-run variants from the GDD edge-case section

---

## Test Evidence

**Story Type**: Logic
**Required evidence**:
- `tests/unit/level/modifier_test.gd` — must exist and pass

**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: Story 001 must be ready or done for shared test fixtures and baseline APIs
- Unlocks: Story 005
