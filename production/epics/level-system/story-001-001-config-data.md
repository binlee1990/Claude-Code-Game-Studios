# Story 001: 实体生命周期

> **Epic**: 等级系统
> **Status**: Ready
> **Layer**: Feature
> **Type**: Config/Data
> **Manifest Version**: 2026-05-04

## Context

**GDD**: `design/gdd/level-system.md`
**Requirement**: `TR-level-system-001` — LevelSystem handles level/experience/realm progression using approved data, formulas, resource, modifier, event, and save boundaries.

**ADR Governing Implementation**: ADR-0013: FormulaEngine 表达式 DSL 深度
**ADR Decision Summary**: Implement a bounded expression evaluator, not a general-purpose DSL. It supports arithmetic, variables, selected safe functions, boolean-to-float comparisons, simple ternary-style conditionals where specified by GDD, and formula caching. The evaluator returns `float`; systems convert to/from BigNumber where appropriate.

**Engine**: Godot 4.6.2 | **Risk**: LOW
**Engine Notes**: ADR-0013 status is Accepted; verify any Godot 4.6.2 behavior named by the ADR before closing the story.

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

- [ ] GIVEN: `LevelSystem` 已加载，`level_realm_config.json` 含 7 境界，**WHEN** `register_entity("player")`，**THEN** 返回 `true`，`get_level == 1`，`get_realm == "fanren"`，`get_realm_id == 0`
- [ ] GIVEN: `"player"` 已注册，**WHEN** 再次 `register_entity("player")`，**THEN** 返回 `false`，已有条目不变，打印警告
- [ ] GIVEN: `"player"` Lv.30 (zhuji)，已注册 10 条 realm modifier，**WHEN** `unregister_entity("player")`，**THEN** 返回 10，`has_entity == false`，ModifierEngine 中 source `"level_system.realm.player.zhuji"` 全消失
- [ ] GIVEN: `unregister_entity("never_registered")`，**WHEN** 调用，**THEN** 返回 0，不崩溃，不打印警告

---

## Implementation Notes

*Derived from ADR-0013 Implementation Guidelines:*

- Must return `float` results from FormulaEngine.
- Must not execute arbitrary GDScript or external code.
- Must bound expression length and clamp invalid softcap parameters.
- Must return `0.0` with warnings for invalid expressions, divide-by-zero, NaN, or Inf.
- Must cache parsed formulas and expose invalidation.
- Must keep BigNumber absolute-value math in callers, not inside the formula DSL except through explicit conversions owned by callers.

---

## Out of Scope

- Story 002 covers the next acceptance group in this epic.

---

## QA Test Cases

*Written at story creation. The developer implements against these cases.*

- **AC**: GIVEN: `LevelSystem` 已加载，`level_realm_config.json` 含 7 境界，**WHEN** `register_entity("player")`，**THEN** 返回 `true`，`get_level == 1`，`get_realm == "fanren"`，`get_realm_id == 0`
  - Given: `LevelSystem` 已加载，`level_realm_config.json` 含 7 境界
  - When: `register_entity("player")`
  - Then: 返回 `true`，`get_level == 1`，`get_realm == "fanren"`，`get_realm_id == 0`
  - Edge cases: boundary, invalid, missing-data, and repeat-run variants from the GDD edge-case section

- **AC**: GIVEN: `"player"` 已注册，**WHEN** 再次 `register_entity("player")`，**THEN** 返回 `false`，已有条目不变，打印警告
  - Given: `"player"` 已注册
  - When: 再次 `register_entity("player")`
  - Then: 返回 `false`，已有条目不变，打印警告
  - Edge cases: boundary, invalid, missing-data, and repeat-run variants from the GDD edge-case section

- **AC**: GIVEN: `"player"` Lv.30 (zhuji)，已注册 10 条 realm modifier，**WHEN** `unregister_entity("player")`，**THEN** 返回 10，`has_entity == false`，ModifierEngine 中 source `"level_system.realm.player.zhuji"` 全消失
  - Given: `"player"` Lv.30 (zhuji)，已注册 10 条 realm modifier
  - When: `unregister_entity("player")`
  - Then: 返回 10，`has_entity == false`，ModifierEngine 中 source `"level_system.realm.player.zhuji"` 全消失
  - Edge cases: boundary, invalid, missing-data, and repeat-run variants from the GDD edge-case section

- **AC**: GIVEN: `unregister_entity("never_registered")`，**WHEN** 调用，**THEN** 返回 0，不崩溃，不打印警告
  - Given: `unregister_entity("never_registered")`
  - When: 调用
  - Then: 返回 0，不崩溃，不打印警告
  - Edge cases: boundary, invalid, missing-data, and repeat-run variants from the GDD edge-case section

---

## Test Evidence

**Story Type**: Config/Data
**Required evidence**:
- `production/qa/smoke-level-system.md` — smoke check evidence

**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: None
- Unlocks: Story 002
