# Story 005: Equipment Decomposition

> **Epic**: Equipment System
> **Status**: Ready
> **Layer**: Feature
> **Type**: Logic
> **Manifest Version**: N/A — manifest not yet created

> **Estimate**: 2 hours

## Context

**GDD**: `design/gdd/equipment-system.md`
**Requirement**: AC.4.1-4.2, C.6 (material output by quality)

**ADR Governing Implementation**: ADR-001 (Event Architecture)
**Engine**: Godot 4.6.2 | **Risk**: LOW

---

## Acceptance Criteria

- [ ] AC.4.1: Decomposition produces correct materials based on quality tier
- [ ] AC.4.2: Enhancement level does not affect decomposition output
- [ ] AC.4.3: Decomposed equipment is removed from player inventory

---

## Implementation Notes

From GDD C.6: White=2 basic materials, Green=5 basic, Blue=10 basic + 20% rare, Purple=20 basic + 50% rare×2, Gold=50 basic + 100% rare×5. From E.5: Enhancement level does NOT increase decomposition output — decomposition is independent of upgrade history. Decomposed equipment is destroyed.

---

## Out of Scope

- Decomposition UI
- Material inventory management (resource economy)

---

## QA Test Cases

- **AC.4.1**: Quality-based output
  - Given: Blue quality equipment
  - When: Decomposed
  - Then: 10 basic materials, 20% chance of 1 rare material
  - Edge cases: Gold → 50 basic + guaranteed 5 rare materials

- **AC.4.2**: Enhancement independence
  - Given: Same White equipment at +0 and at +5
  - When: Both decomposed
  - Then: Same output (2 basic materials each)
  - Edge cases: +20 Purple → same as +0 Purple

---

## Test Evidence

**Story Type**: Logic
**Required evidence**: `tests/unit/equipment/decomposition_test.gd`
**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: Story 001 (equipment data model)
- Cross-epic: Resource Economy Story 001 (material inventory receives output)
