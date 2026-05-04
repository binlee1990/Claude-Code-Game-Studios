# Story 001: all are queryable by id and sorted by order

> **Epic**: 区域系统
> **Status**: Ready
> **Layer**: Feature Integration
> **Type**: Integration
> **Manifest Version**: 2026-05-04

## Context

**GDD**: `design/gdd/zone-system.md`
**Requirement**: `TR-zone-system-001` — ZoneSystem exposes current and unlocked zone data from DataConfig and coordinates with combat/progression consumers.

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

*From GDD `design/gdd/zone-system.md`, scoped to this story:*

- [ ] GIVEN: three valid zone records, **WHEN** ZoneSystem loads, **THEN** all are queryable by id and sorted by order.
- [ ] GIVEN: zone references a missing enemy but has other valid enemies, **WHEN** loaded, **THEN** zone remains available but degraded warning is recorded.
- [ ] GIVEN: player selects an unlocked zone, **WHEN** selection succeeds, **THEN** `zone.changed` is emitted.

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

- **AC**: GIVEN: three valid zone records, **WHEN** ZoneSystem loads, **THEN** all are queryable by id and sorted by order.
  - Given: three valid zone records
  - When: ZoneSystem loads
  - Then: all are queryable by id and sorted by order
  - Edge cases: boundary, invalid, missing-data, and repeat-run variants from the GDD edge-case section

- **AC**: GIVEN: zone references a missing enemy but has other valid enemies, **WHEN** loaded, **THEN** zone remains available but degraded warning is recorded.
  - Given: zone references a missing enemy but has other valid enemies
  - When: loaded
  - Then: zone remains available but degraded warning is recorded
  - Edge cases: boundary, invalid, missing-data, and repeat-run variants from the GDD edge-case section

- **AC**: GIVEN: player selects an unlocked zone, **WHEN** selection succeeds, **THEN** `zone.changed` is emitted.
  - Given: player selects an unlocked zone
  - When: selection succeeds
  - Then: `zone.changed` is emitted
  - Edge cases: boundary, invalid, missing-data, and repeat-run variants from the GDD edge-case section

---

## Test Evidence

**Story Type**: Integration
**Required evidence**:
- `tests/integration/zone/all-are-queryable-by-id-and-sorted-by-order_test.gd` — must exist and pass

**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: None
- Unlocks: Story 002
