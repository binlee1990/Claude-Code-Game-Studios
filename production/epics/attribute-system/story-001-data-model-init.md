# Story 001: Attribute Data Model & Character Init

> **Epic**: Attribute & Growth System
> **Status**: Ready
> **Layer**: Core
> **Type**: Logic
> **Manifest Version**: N/A — manifest not yet created

> **Estimate**: 2-3 hours

## Context

**GDD**: `design/gdd/attribute-growth-system.md`
**Requirement**: AC-1 — New character creation initializes all V=10, all P=E, 9 attributes complete

**ADR Governing Implementation**: ADR-001: Event Architecture
**ADR Decision Summary**: All inter-system communication via GameEvents autoload. Attribute changes emit `attribute_changed` signal. Systems read attribute data via provided interfaces, never direct property access.

**Engine**: Godot 4.6.2 | **Risk**: LOW
**Engine Notes**: Signal system is core Godot feature, no post-cutoff APIs needed.

---

## Acceptance Criteria

- [ ] AC-1.1: New character has 5 normal attributes (STR/AGI/CON/INT/CHA) all initialized to V=10, P=E(1)
- [ ] AC-1.2: New character has 4 hidden attributes (LUK/WIL/RES/SOU) all initialized to V=10, P=E(1)
- [ ] AC-1.3: `get_attribute_value(character_id, attribute_name) -> int` returns correct V
- [ ] AC-1.4: `get_attribute_potential(character_id, attribute_name) -> int` returns correct P (1-6)
- [ ] AC-1.5: `get_character_attributes(character_id) -> AttributeSnapshot` returns all 9 attributes with V and P

---

## Implementation Notes

From ADR-001:
- Define attribute enums/constants in `attribute_names.gd`
- `AttributeComponent` holds per-character attribute state (V and P for each of 9 attributes)
- Expose read-only interfaces for downstream systems
- Emit `attribute_changed` signal when attributes change (for this story, only on init)
- No direct property mutation from external systems — use provided methods

---

## Out of Scope

- Story 002: Growth formula and level-up logic
- Story 003: Fruit usage mechanics
- Story 007: Save/load persistence

---

## QA Test Cases

- **AC-1.1**: Character initialization — normal attributes
  - Given: A new character is created
  - When: Reading all 5 normal attribute values and potentials
  - Then: STR/AGI/CON/INT/CHA all have V=10, P=1 (E rank)
  - Edge cases: Verify each attribute independently

- **AC-1.2**: Character initialization — hidden attributes
  - Given: A new character is created
  - When: Reading all 4 hidden attribute values and potentials
  - Then: LUK/WIL/RES/SOU all have V=10, P=1 (E rank)
  - Edge cases: Verify each attribute independently

- **AC-1.3**: get_attribute_value returns correct V
  - Given: A character with initialized attributes
  - When: Calling get_attribute_value for each attribute name
  - Then: Returns 10 for all 9 attributes
  - Edge cases: Invalid attribute name should return error/handle gracefully

- **AC-1.4**: get_attribute_potential returns correct P
  - Given: A character with initialized attributes
  - When: Calling get_attribute_potential for each attribute name
  - Then: Returns 1 for all 9 attributes
  - Edge cases: Invalid attribute name should return error/handle gracefully

- **AC-1.5**: get_character_attributes returns complete snapshot
  - Given: A character with initialized attributes
  - When: Calling get_character_attributes
  - Then: Returns dictionary/object with all 9 attributes, each containing V=10 and P=1
  - Edge cases: Verify snapshot is a copy, not a reference

---

## Test Evidence

**Story Type**: Logic
**Required evidence**: `tests/unit/attributes/data_model_init_test.gd` — must exist and pass
**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: None (foundational story)
- Unlocks: Story 002, Story 003, Story 004, Story 005, Story 006, Story 007
