# Story 002: Grid Map Rendering

> **Epic**: Camera & Map System
> **Status**: Complete
> **Layer**: Presentation
> **Type**: Visual/Feel
> **Manifest Version**: N/A — manifest not yet created

> **Estimate**: 3-4 hours

## Context

**GDD**: `design/gdd/camera-map-system.md`
**Requirement**: AC.1.3 (grid rendering, map sizes, height visualization)

**ADR Governing Implementation**: ADR-001 (Event Architecture)
**Engine**: Godot 4.6.2 | **Risk**: LOW

---

## Acceptance Criteria

- [ ] AC.1.3: Maps render correctly at all supported sizes (15×15, 20×20, 25×25)
- [ ] AC-G1: Height differentials (low/plain/high) visually distinct via elevation and shadow
- [ ] AC-G2: Grid overlay toggleable for tactical readability

---

## Implementation Notes

From GDD C.3: Three map sizes — standard 15×15, large 20×20, extra-large 25×25. From C.4: Square grid, 1 unit per cell. Height levels from tactical mechanism (0/1/2) rendered as visual elevation with appropriate shadow/lighting. Grid lines drawn as semi-transparent overlay. Different terrain types have distinct visual representations.

---

## Out of Scope

- Terrain interaction logic (tactical mechanism epic)
- Unit placement on grid (turn-based epic)
- Map design/content

---

## QA Test Cases

- **AC.1.3**: Map size rendering
  - Setup: Load 15×15 map, 20×20 map, 25×25 map
  - Verify: Each renders fully within viewport, no clipping, all cells visible
  - Pass condition: All sizes render at 60 FPS with grid overlay on

- **AC-G1**: Height visualization
  - Setup: Map with lowland(0), plain(1), highland(2) cells
  - Verify: Visual elevation difference clear, shadows consistent with light direction
  - Pass condition: Height levels distinguishable without reading numbers

- **AC-G2**: Grid overlay toggle
  - Setup: Battle scene with grid
  - Verify: Toggle grid on/off → grid lines appear/disappear
  - Pass condition: Grid lines semi-transparent, do not obscure units or terrain

---

## Test Evidence

**Story Type**: Visual/Feel
**Required evidence**: `production/qa/evidence/grid-map-rendering-evidence.md` + screenshot sign-off
**Status**: [x] `production/qa/evidence/grid-map-rendering-evidence.md` created; screenshot sign-off pending

---

## Dependencies

- Depends on: Story 001 (camera provides the viewpoint)
- Cross-epic: Tactical Mechanism Story 001 (terrain data provides height values)
