# Story 001: Terrain Data Model

> **Epic**: Tactical Mechanism
> **Status**: Complete
> **Layer**: Core
> **Type**: Logic
> **Manifest Version**: N/A — manifest not yet created

> **Estimate**: 2-3 hours

## Context

**GDD**: `design/gdd/tactical-mechanism.md`
**Requirement**: AC.4.1-4.3 (terrain types, movement costs, obstacles)

**ADR Governing Implementation**: ADR-001 (Event Architecture)
**Engine**: Godot 4.6.2 | **Risk**: LOW

---

## Acceptance Criteria

- [ ] AC.4.1: Sand terrain movement cost +100% (consumes double movement points)
- [ ] AC.4.2: Obstacles block movement and ranged attacks
- [ ] AC.4.3: Highland terrain provides correct height value (2)

---

## Implementation Notes

From GDD C.4: 7 terrain types — normal, grass, water puddle, sand, mud, highland (height=2), obstacle. Standard battlefield 15×15 grid, large 25×25. Each cell stores terrain type and height level (0/1/2). Grass is ignitable; water puddles can evaporate or conduct; sand increases movement cost by 100%; mud applies AGI -50%.

---

## Out of Scope

- Element interaction effects (Story 004)
- Height advantage calculations (Story 003)
- Battlefield rendering / visual representation

---

## QA Test Cases

- **AC.4.1**: Sand movement cost
  - Given: Unit with 4 movement points, sand terrain ahead
  - When: Unit enters sand cell
  - Then: Movement cost = 2 (double normal cost of 1)
  - Edge cases: Unit with exactly 1 movement point cannot enter sand

- **AC.4.2**: Obstacle blocking
  - Given: Obstacle cell between ranged attacker and target
  - When: Ranged attack attempted through obstacle
  - Then: Attack blocked, path invalid
  - Edge cases: Melee adjacency to obstacle is fine; obstacle blocks only path traversal and line-of-sight

- **AC.4.3**: Highland height value
  - Given: Highland terrain cell
  - When: Height queried
  - Then: Returns height = 2
  - Edge cases: Normal terrain returns 1, low terrain returns 0

---

## Test Evidence

**Story Type**: Logic
**Required evidence**: `tests/unit/tactical/terrain_data_model_test.gd`
**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: None (foundational story)
- Unlocks: Story 003 (height advantage), Story 004 (elemental interactions)
