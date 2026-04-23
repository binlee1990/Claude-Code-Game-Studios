# Story 002: Affix Generation

> **Epic**: Equipment System
> **Status**: Complete
> **Layer**: Feature
> **Type**: Logic
> **Manifest Version**: 2026-04-23-v1

> **Estimate**: 2-3 hours

## Context

**GDD**: `design/gdd/equipment-system.md`
**Requirement**: C.3, D.2 (quality-based affix count and value ranges)

**ADR Governing Implementation**: ADR-001 (Event Architecture)
**Engine**: Godot 4.6.2 | **Risk**: LOW

---

## Acceptance Criteria

- [ ] AC-A1: Affix value = random(min, max) × quality_multiplier
- [ ] AC-A2: Affix types include attack (+STR/AGI/INT/crit), defense (+CON/def/resist), survival (+HP/regen), special (+movement/+range/+skill_effect)
- [ ] AC-A3: Quality determines affix value ranges (White +1~+3, Gold +12~+30 for attack)

---

## Implementation Notes

From GDD C.3: 4 affix categories — attack, defense, survival, special (rare). From D.2: `affix_value = random_range(min_affix, max_affix) × quality_multiplier` where quality_multiplier = {White=1.0, Green=1.5, Blue=2.0, Purple=3.0, Gold=5.0}. Example: Blue attack affix range 4-12 × 2.0 = 8~24.

---

## Out of Scope

- Equipment data model (Story 001)
- Enhancement system (Story 003)
- UI for affix display

---

## QA Test Cases

- **AC-A1**: Affix value formula
  - Given: Blue quality, attack affix type (range 4-12), quality_multiplier=2.0
  - When: Affix generated
  - Then: Value ∈ [8, 24]
  - Edge cases: White quality → multiplier 1.0, range unchanged

- **AC-A2**: Affix type variety
  - Given: Generate 100 affixes
  - When: Types tallied
  - Then: Attack, defense, survival types all appear; special is rarest
  - Edge cases: Special affixes have lower selection weight

- **AC-A3**: Quality-range mapping
  - Given: Purple quality, attack affix
  - When: Affix value generated
  - Then: Base range 8-20 × 3.0 = [24, 60]
  - Edge cases: Gold quality +30 × 5.0 = 150 maximum single affix

---

## Test Evidence

**Story Type**: Logic
**Required evidence**: `tests/unit/equipment/affix_generation_test.gd`
**Status**: [x] `tests/unit/equipment/affix_generation_test.gd` created and passing

---

## Dependencies

- Depends on: Story 001 (equipment data model stores affixes)
- Unlocks: Story 006 (affix values feed into attribute calculation)
