# Story 003: Movement System

> **Epic**: Turn-Based Mode
> **Status**: Complete
> **Layer**: Core
> **Type**: Logic
> **Manifest Version**: N/A — manifest not yet created

> **Estimate**: 2-3 hours

## Context

**GDD**: `design/gdd/turn-based-mode.md`
**Requirement**: C.2, D.3 (movement points, terrain costs, pathfinding)

**ADR Governing Implementation**: ADR-001 (Event Architecture)
**Engine**: Godot 4.6.2 | **Risk**: LOW

---

## Acceptance Criteria

- [ ] AC-M1: Base movement = 5 cells per turn
- [ ] AC-M2: Sand terrain costs 2× movement points
- [ ] AC-M3: Obstacles block movement entirely
- [ ] AC-M4: Movement can be interrupted (unit stops at any valid cell)

---

## Implementation Notes

From GDD C.2: Base movement 5 cells/turn. Terrain affects cost: sand = 2×, normal = 1×. Obstacles impassable. Movement uses grid pathfinding (no diagonal). After moving, unit can still attack/use skill. From D.3: `movement_cost = terrain_cost × base_movement` per cell entered. From tactical mechanism epic: mud reduces AGI (not movement cost directly).

---

## Out of Scope

- Visual movement range overlay (UI)
- Movement animation
- Attack-after-move (handled by action system)

---

## QA Test Cases

- **AC-M1**: Base movement range
  - Given: Unit with base_movement=5, all normal terrain
  - When: Movement range calculated
  - Then: Can reach any cell within 5 steps
  - Edge cases: Surrounded by obstacles → cannot move at all

- **AC-M2**: Sand terrain cost
  - Given: Unit with 5 movement, 3 normal cells then 1 sand cell
  - When: Path cost calculated
  - Then: Normal cells cost 1 each (total 3), sand cell costs 2 (total 5) → can reach
  - Edge cases: 2 sand cells in path → cost 4, leaves 1 movement remaining

- **AC-M3**: Obstacle blocking
  - Given: Obstacle directly in front of unit
  - When: Movement range calculated
  - Then: Obstacle cell excluded from reachable cells
  - Edge cases: Unit must pathfind around obstacle

- **AC-M4**: Interrupted movement
  - Given: Unit can move 5 cells, moves 3
  - When: Player stops movement at cell 3
  - Then: Unit positioned at cell 3, 2 movement points unused
  - Edge cases: Moving 0 cells = staying in place (valid)

---

## Test Evidence

**Story Type**: Logic
**Required evidence**: `tests/unit/turn/movement_system_test.gd`
**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: Story 001 (turn order)
- Cross-epic: Tactical Mechanism Story 001 (terrain data provides terrain costs)
- Unlocks: Story 004 (combat flow includes movement phase)

## Completion Notes

**Completed**: 2026-04-22
**Criteria**: 4/4 passing (all auto-verified)
**Deviations**: None
**Test Evidence**: Logic — `tests/unit/turn/movement_system_test.gd` (18 test functions)
**Code Review**: Skipped (Solo mode)
