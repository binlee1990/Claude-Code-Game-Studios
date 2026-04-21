# Story 001: Resource Data Model & Inventory

> **Epic**: Resource Economy
> **Status**: Complete
> **Layer**: Core
> **Type**: Logic
> **Manifest Version**: N/A — manifest not yet created

> **Estimate**: 2-3 hours

## Context

**GDD**: `design/gdd/resource-economy.md`
**Requirement**: AC.1 (resource data management)

**ADR Governing Implementation**: ADR-001 (Event Architecture), ADR-003 (Save System)
**Engine**: Godot 4.6.2 | **Risk**: LOW

---

## Acceptance Criteria

- [ ] AC.1.1: All resource holdings correctly saved to save data, load restores exact values
- [ ] AC.1.2: Resources do not exceed stack limits (gold: 9,999,999; basic materials: 9,999; fruits: 99; rare materials: 999; protection symbols: 99; barrier resources: 99); excess discarded with warning
- [ ] AC.1.3: Achievement points have no upper limit, accumulate across playthroughs

---

## Implementation Notes

From GDD C.1: Dual-layer resource taxonomy. 4 common types (gold, basic_material, exp, proficiency) + 5 rare types (9 fruit subtypes, rare_material, protect_symbol, barrier_resource, achievement). Exp and proficiency are not囤积 resources — consumed immediately by attribute/skill systems. This story manages the囤积 resources only.

From ADR-001: Resource changes emit `resource_changed` signal. From ADR-003: Inventory persisted via ItemSaveData in UnitSaveData.

---

## Out of Scope

- Story 002-003: Acquisition formulas
- Story 004-005: Consumption logic
- UI display of resources

---

## QA Test Cases

- **AC.1.2**: Stack limit enforcement — gold
  - Given: Player gold = 9,999,998
  - When: Gaining 5 gold
  - Then: Gold = 9,999,999 (2 discarded), warning emitted
  - Edge cases: Gold at exactly 9,999,999 — no gain possible

- **AC.1.2**: Stack limit — fruits
  - Given: Player has 98 STR fruits
  - When: Gaining 3 STR fruits
  - Then: STR fruits = 99 (1 discarded)

- **AC.1.3**: Achievement points unlimited
  - Given: Achievement points = 999,999
  - When: Gaining 100 more
  - Then: Achievement points = 1,000,099 (no cap)

---

## Test Evidence

**Story Type**: Logic
**Required evidence**: `tests/unit/resource/data_model_inventory_test.gd`
**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: attribute-system Epic (exp/proficiency consumed by those systems)
- Unlocks: Stories 002-006
