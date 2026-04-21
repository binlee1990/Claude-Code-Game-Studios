# Story 003: Fruit System (Potential Upgrade)

> **Epic**: Attribute & Growth System
> **Status**: Complete
> **Layer**: Core
> **Type**: Logic
> **Manifest Version**: N/A — manifest not yet created

> **Estimate**: 2-3 hours

## Context

**GDD**: `design/gdd/attribute-growth-system.md`
**Requirement**: AC-4 (fruit raises P), AC-5 (S-reject), AC-6 (barrier-reject)

**ADR Governing Implementation**: ADR-001: Event Architecture
**ADR Decision Summary**: Fruit usage should emit `attribute_changed` signal for the affected attribute's potential change.

**Engine**: Godot 4.6.2 | **Risk**: LOW

---

## Acceptance Criteria

- [ ] AC-4.1: Consuming a fruit for attribute with P < S raises P by 1 tier (e.g., D→C, E→D)
- [ ] AC-4.2: Fruit consumption only affects the target attribute's potential
- [ ] AC-5.1: Using fruit on attribute with P=S(6) produces no change and does not consume the fruit
- [ ] AC-6.1: Using fruit on attribute where V >= current barrier limit AND barrier not broken — fruit is rejected (not consumed)

---

## Implementation Notes

From GDD C.3:
- Fruit is a consumable item; the resource economy system manages inventory
- This story handles the EFFECT of fruit usage on potential, not the inventory management
- Potential tiers: E(1) → D(2) → C(3) → B(4) → A(5) → S(6)
- Conditions for valid fruit use: P_old < S(6) AND V < current BARRIER_LIMIT (or barrier broken)

---

## Out of Scope

- Resource economy: fruit inventory management (handled by resource-economy epic)
- Visual effects of fruit usage (handled by UI epic)

---

## QA Test Cases

- **AC-4.1**: Fruit raises potential
  - Given: Character with STR P=D(2), V=30, barrier 1 not broken
  - When: Fruit (STR) is used
  - Then: STR P becomes C(3), fruit consumed
  - Edge cases: P=E→D, P=A→S boundary transitions

- **AC-4.2**: Fruit only affects target attribute
  - Given: Character with all P=E(1)
  - When: STR fruit is used
  - Then: Only STR P changes to D(2); AGI/CON/INT/CHA/LUK/WIL/RES/SOU remain E(1)

- **AC-5.1**: Fruit rejected at max potential
  - Given: Character with STR P=S(6)
  - When: Fruit (STR) is used
  - Then: STR P remains S(6), fruit NOT consumed
  - Edge cases: Verify no signal emitted when rejected

- **AC-6.1**: Fruit rejected at barrier cap
  - Given: Character with STR V=50, barrier 1 NOT broken
  - When: Fruit (STR) is used
  - Then: STR P unchanged, fruit NOT consumed
  - Edge cases: V=49 (below cap) — fruit should succeed; V=50 exactly — reject

---

## Test Evidence

**Story Type**: Logic
**Required evidence**: `tests/unit/attributes/fruit_system_test.gd` — must exist and pass
**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: Story 001 (data model)
- Unlocks: None (fruit system is self-contained within attribute system)

## Completion Notes

**Completed**: 2026-04-22
**Criteria**: 4/4 passing (all auto-verified)
**Deviations**: ADVISORY — Interface uses `Unit.use_fruit()` instead of dedicated fruit method. Functionally equivalent.
**Test Evidence**: Logic — `tests/unit/attributes/fruit_system_test.gd` (12 test functions)
**Code Review**: Skipped (Solo mode)
