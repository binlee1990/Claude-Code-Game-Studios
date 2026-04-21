# Story 004: Material & Equipment Drops

> **Epic**: Battle Settlement
> **Status**: Ready
> **Layer**: Feature
> **Type**: Logic
> **Manifest Version**: N/A — manifest not yet created

> **Estimate**: 2-3 hours

## Context

**GDD**: `design/gdd/battle-settlement.md`
**Requirement**: AC.2.2-2.3, C.3-C.4 (gold, materials, equipment drops)

**ADR Governing Implementation**: ADR-001 (Event Architecture)
**Engine**: Godot 4.6.2 | **Risk**: LOW

---

## Acceptance Criteria

- [ ] AC.2.2: Gold correctly calculated using resource economy formula
- [ ] AC.2.3: Materials correctly dropped based on enemy tier and drop rates
- [ ] AC-D1: Equipment drops follow quality probability (White common, Gold 0.5%)

---

## Implementation Notes

From GDD C.3: Gold formula from resource economy (D.1). From C.4: Equipment drop rates — normal enemy 10%, elite 50%, boss 100%. Quality probability: Blue 10%, Purple 2%, Gold 0.5%. Fruit drops from resource economy D.3. Settlement aggregates all drops from all defeated enemies and presents as a single reward bundle.

---

## Out of Scope

- Drop animation/visual feedback
- Resource inventory management (resource economy epic)
- Equipment affix generation (equipment-system epic)

---

## QA Test Cases

- **AC.2.2**: Gold calculation
  - Given: base_reward=100, total_damage=500, kill_bonus=20 (boss kill)
  - When: Gold reward calculated
  - Then: gold = 100 + floor(500×0.1) + 20 = 170
  - Edge cases: Zero damage → gold = base_reward only

- **AC.2.3**: Material drops
  - Given: Normal enemy (tier=1), defeat
  - When: Material drop calculated
  - Then: 1-3 materials (random in range), 10% equipment drop chance
  - Edge cases: Boss → 100% equipment drop, higher quality probability

- **AC-D1**: Equipment quality distribution
  - Given: 100 boss kills simulated
  - When: Equipment quality tallied
  - Then: White/Green majority, Blue ~10%, Purple ~2%, Gold ~0-1%
  - Edge cases: Normal enemy → much lower equipment drop rate (10%)

---

## Test Evidence

**Story Type**: Logic
**Required evidence**: `tests/unit/settlement/material_drops_test.gd`
**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: Story 001 (settlement trigger)
- Cross-epic: Resource Economy Stories 002-003 (gold/material/fruit formulas)
