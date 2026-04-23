# Story 003: Enhancement System

> **Epic**: Equipment System
> **Status**: Complete
> **Layer**: Feature
> **Type**: Logic
> **Manifest Version**: 2026-04-23-v1

> **Estimate**: 2-3 hours

## Context

**GDD**: `design/gdd/equipment-system.md`
**Requirement**: AC.2.1-2.4, D.3, D.4 (safe zone, risk zone, protection symbol)

**ADR Governing Implementation**: ADR-001 (Event Architecture)
**Engine**: Godot 4.6.2 | **Risk**: LOW

---

## Acceptance Criteria

- [ ] AC.2.1: Enhancement +1 to +5: 100% success rate
- [ ] AC.2.2: Enhancement +6+: failure probability applies; success rate decreases per level (D.3)
- [ ] AC.2.3: Failure without protection symbol: downgrade 5 levels (D.4)
- [ ] AC.2.4: Failure with protection symbol: no downgrade, symbol consumed (-1)

---

## Implementation Notes

From GDD D.3: `success_rate = 1.0 - (level - 5) × 0.05` for +6 and above. From D.4: `new_level = max(0, current_level - 5)` on failure. Protection symbol consumed before outcome determined. Cost: gold = base_cost × level, materials = 5 × level. From E.1: Cannot enhance beyond quality cap (White +5, Green +10, etc.). From E.3: No protection symbol → warning, player can still proceed.

---

## Out of Scope

- Enhancement UI/animation
- Protection symbol acquisition (resource economy)
- Equipment data model (Story 001)

---

## QA Test Cases

- **AC.2.1**: Safe zone success
  - Given: Equipment at +3
  - When: Enhancement attempted (+3 → +4)
  - Then: 100% success, equipment becomes +4
  - Edge cases: +4 → +5 also 100%; +5 → +6 is risk zone

- **AC.2.2**: Risk zone failure rate
  - Given: Equipment at +10, no protection
  - When: Enhancement attempted
  - Then: Success rate = 1.0 - (10-5)×0.05 = 75%
  - Edge cases: +15 → 50%; +20 → 25%

- **AC.2.3**: Failure downgrade
  - Given: Equipment at +10, no protection, failure occurs
  - When: Enhancement fails
  - Then: Equipment becomes +5 (10-5)
  - Edge cases: +6 fails → +1; +8 fails → +3

- **AC.2.4**: Protection symbol
  - Given: Equipment at +7, protection symbol available, failure occurs
  - When: Enhancement fails
  - Then: Equipment stays +7, protection symbol -1
  - Edge cases: Last protection symbol → consumed, no more remaining

---

## Test Evidence

**Story Type**: Logic
**Required evidence**: `tests/unit/equipment/enhancement_test.gd`
**Status**: [x] `tests/unit/equipment/enhancement_test.gd` created and passing

---

## Dependencies

- Depends on: Story 001 (equipment data model), Cross-epic: Resource Economy Stories 004-005 (cost, protection symbol)
- Unlocks: Story 006 (enhanced equipment contributes to attributes)
