# Story 001: `get_count() == 3`

> **Epic**: 敌人数据库
> **Status**: Ready
> **Layer**: Feature
> **Type**: Config/Data
> **Manifest Version**: 2026-05-04

## Context

**GDD**: `design/gdd/enemy-database.md`
**Requirement**: `TR-enemy-database-001` — EnemyDatabase exposes static enemy template data from DataConfig without owning combat-local mutable state.

**ADR Governing Implementation**: ADR-0005: 数据配置加载策略
**ADR Decision Summary**: Implement `DataConfig` as a `RefCounted` service held by an Autoload host. It scans JSON files under `res://assets/data/`, parses them with Godot JSON APIs, stores raw dictionaries in memory, and returns raw values to consumers. BigNumber conversion is performed by consumers according to their schemas.

**Engine**: Godot 4.6.2 | **Risk**: MEDIUM
**Engine Notes**: ADR-0005 status is Accepted; verify any Godot 4.6.2 behavior named by the ADR before closing the story.

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

*From GDD `design/gdd/enemy-database.md`, scoped to this story:*

- [ ] GIVEN: `enemies` table contains three valid records, **WHEN** EnemyDatabase loads, **THEN** `get_count() == 3`.
- [ ] GIVEN: enemy has all MVP attributes, **WHEN** `create_combat_snapshot`, **THEN** snapshot contains hp_max, atk, def, spd, crit_rate, crit_dmg.
- [ ] GIVEN: enemy has invalid attribute id, **WHEN** loading, **THEN** that record is skipped and warning includes the id.

---

## Implementation Notes

*Derived from ADR-0005 Implementation Guidelines:*

- Must use JSON files in `res://assets/data/` for MVP configuration.
- Must not use Godot Resource files as the MVP content format.
- Must keep DataConfig schema-agnostic; consumers parse BigNumber strings themselves.
- Must keep all loaded tables in memory for MVP.
- Must allow one failed table to degrade to an empty table without stopping other tables.
- Must restrict `reload_table` and `reload_all` to debug builds.

---

## Out of Scope

- Story 002 covers the next acceptance group in this epic.

---

## QA Test Cases

*Written at story creation. The developer implements against these cases.*

- **AC**: GIVEN: `enemies` table contains three valid records, **WHEN** EnemyDatabase loads, **THEN** `get_count() == 3`.
  - Given: `enemies` table contains three valid records
  - When: EnemyDatabase loads
  - Then: `get_count() == 3`
  - Edge cases: boundary, invalid, missing-data, and repeat-run variants from the GDD edge-case section

- **AC**: GIVEN: enemy has all MVP attributes, **WHEN** `create_combat_snapshot`, **THEN** snapshot contains hp_max, atk, def, spd, crit_rate, crit_dmg.
  - Given: enemy has all MVP attributes
  - When: `create_combat_snapshot`
  - Then: snapshot contains hp_max, atk, def, spd, crit_rate, crit_dmg
  - Edge cases: boundary, invalid, missing-data, and repeat-run variants from the GDD edge-case section

- **AC**: GIVEN: enemy has invalid attribute id, **WHEN** loading, **THEN** that record is skipped and warning includes the id.
  - Given: enemy has invalid attribute id
  - When: loading
  - Then: that record is skipped and warning includes the id
  - Edge cases: boundary, invalid, missing-data, and repeat-run variants from the GDD edge-case section

---

## Test Evidence

**Story Type**: Config/Data
**Required evidence**:
- `production/qa/smoke-enemy-database.md` — smoke check evidence

**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: None
- Unlocks: Story 002
