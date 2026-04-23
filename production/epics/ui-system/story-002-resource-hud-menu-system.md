# Story 002: Resource HUD & Menu System

> **Epic**: UI System
> **Status**: Complete
> **Layer**: Presentation
> **Type**: UI
> **Manifest Version**: N/A — manifest not yet created

> **Estimate**: 3-4 hours

## Context

**GDD**: `design/gdd/ui-system.md`
**Requirement**: AC.1.2-1.3 (resource display, menu system, keyboard navigation)

**ADR Governing Implementation**: ADR-001 (Event Architecture), ADR-002 (Scene Management)
**Engine**: Godot 4.6.2 | **Risk**: LOW

---

## Acceptance Criteria

- [ ] AC.1.2: HUD displays gold and resource quantities (materials, fruits, protection symbols) at screen top
- [ ] AC.1.3: Menu system (character, inventory, save/load, settings) opens and responds to keyboard input
- [ ] AC-M1: All menus navigable via keyboard (arrows + Enter + Escape)

---

## Implementation Notes

From GDD C.3: Top bar shows gold, current stage, pause button. Top-left shows key resource icons. From C.4: 4 menu screens — character (status/equipment/skills), inventory (items/equipment), save/load, settings (volume/graphics/controls). All menus use CanvasLayer for proper layering. Menus pause gameplay when opened.

---

## Out of Scope

- Battle HUD (Story 001)
- Save/load backend logic (ADR-003 implementation)
- Art assets for menu backgrounds

---

## QA Test Cases

- **AC.1.2**: Resource display
  - Setup: Player has 500 gold, 3 STR fruits, 2 protection symbols
  - Verify: Top bar shows gold=500; resource icons show correct quantities
  - Pass condition: Values update within 1 frame of resource change events

- **AC.1.3**: Menu functionality
  - Setup: Game running, press menu key
  - Verify: Character menu opens, shows current unit stats/equipment/skills; all tabs functional
  - Pass condition: Each menu screen loads and displays correct data from game systems

- **AC-M1**: Keyboard navigation
  - Setup: Menu open
  - Verify: Arrow keys move selection, Enter activates, Escape closes/back
  - Pass condition: All menus fully operable without mouse

---

## Test Evidence

**Story Type**: UI
**Required evidence**: `production/qa/evidence/resource-menu-evidence.md` + manual walkthrough doc
**Status**: [x] `production/qa/evidence/resource-menu-evidence.md` created; manual walkthrough pending

---

## Dependencies

- Depends on: Story 001 (HUD framework)
- Cross-epic: Resource Economy (resource data), Equipment System (inventory data), Save System (save/load)
