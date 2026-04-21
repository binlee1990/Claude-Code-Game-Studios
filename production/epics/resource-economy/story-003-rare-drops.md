# Story 003: Rare Resource Drops

> **Epic**: Resource Economy
> **Status**: Ready
> **Layer**: Core
> **Type**: Logic
> **Manifest Version**: N/A — manifest not yet created

> **Estimate**: 2-3 hours

## Context

**GDD**: `design/gdd/resource-economy.md`
**Requirement**: AC.2.3-2.4 (fruit drops, rare drops)

**ADR Governing Implementation**: ADR-001 (Event Architecture)
**Engine**: Godot 4.6.2 | **Risk**: LOW

---

## Acceptance Criteria

- [ ] AC.2.3a: Normal battle fruit drop rate = 5% (0.05 probability)
- [ ] AC.2.3b: Boss battle fruit drop rate = 100% (always drops 1-2 fruits)
- [ ] AC.2.4: Rare material drop: hard difficulty 10%, hidden boss 100%, hell difficulty 20%; protection symbol: hell difficulty 2%

---

## Implementation Notes

From GDD D.3: Fruit attribute selection prefers the attribute with best battle performance; if indeterminate, random selection. Drop checks are independent per resource type — a boss battle can drop gold + materials + fruits + rare materials simultaneously.

---

## Out of Scope

- Story 002: Gold/material formulas
- Story 004: Consumption logic

---

## QA Test Cases

- **AC.2.3a**: Normal battle fruit drop
  - Given: Normal battle, drop_rate=0.05
  - When: 1000 drop checks simulated
  - Then: ~50 drops (statistical test within acceptable range)
  - Edge cases: 0% and 100% boundary values

- **AC.2.3b**: Boss battle fruit drop
  - Given: Boss battle, drop_rate=1.0
  - When: Drop check
  - Then: Always drops 1 or 2 fruits

- **AC.2.4**: Rare material probability
  - Given: Hard difficulty battle (10% rate)
  - When: Drop check
  - Then: 10% chance of rare material drop
  - Edge cases: Hell difficulty 2% protection symbol — very rare but possible

---

## Test Evidence

**Story Type**: Logic
**Required evidence**: `tests/unit/resource/rare_drops_test.gd`
**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: Story 001 (inventory model)
- Unlocks: Story 004 (fruit consumption), Story 005 (protection symbol usage)
