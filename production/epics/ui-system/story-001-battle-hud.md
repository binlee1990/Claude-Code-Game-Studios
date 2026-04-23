# Story 001: Battle HUD

> **Epic**: UI System
> **Status**: Complete
> **Layer**: Presentation
> **Type**: UI
> **Manifest Version**: N/A — manifest not yet created

> **Estimate**: 3-4 hours

## Context

**GDD**: `design/gdd/ui-system.md`
**Requirement**: AC.1.1 (turn order, skill bar, character status, range overlays)

**ADR Governing Implementation**: ADR-001 (Event Architecture)
**Engine**: Godot 4.6.2 | **Risk**: LOW

---

## Acceptance Criteria

- [ ] AC.1.1: Battle HUD displays turn order bar, skill bar, character status panel, and range overlays
- [ ] AC-B1: All HUD elements update reactively to game events (HP change, turn advance, skill used)
- [ ] AC-B2: HUD supports keyboard navigation between actions

---

## Implementation Notes

From GDD C.1: 4-layer UI hierarchy — bottom (map), middle (battle info), upper (controls), top (floating text). From C.2: Turn order bar (screen right), skill bar (screen bottom), character panel (screen left), range overlay (battlefield layer). All elements listen to GameEvents for reactive updates. Keyboard navigation required per technical preferences.

---

## Out of Scope

- Resource HUD (Story 002)
- Menu system (Story 002)
- HD-2D aesthetic styling (art direction)
- Damage floating numbers animation

---

## QA Test Cases

- **AC.1.1**: HUD component display
  - Setup: Enter battle with 4 player units and 4 enemy units
  - Verify: Turn order bar shows 8 units sorted by AGI; skill bar shows current unit's skills; status panel shows HP/MP; range overlay appears when selecting move/attack
  - Pass condition: All 4 components visible and correctly populated

- **AC-B1**: Reactive updates
  - Setup: Battle in progress, enemy deals damage to player unit
  - Verify: HP bar decreases in real-time, turn order advances, skill cooldowns update
  - Pass condition: No manual refresh needed; all changes propagate within 1 frame

- **AC-B2**: Keyboard navigation
  - Setup: Battle HUD active
  - Verify: Tab/arrows navigate between skill bar, actions, and turn order; Enter selects
  - Pass condition: Full battle playable without mouse

---

## Test Evidence

**Story Type**: UI
**Required evidence**: `production/qa/evidence/battle-hud-evidence.md` + manual walkthrough doc
**Status**: [x] `production/qa/evidence/battle-hud-evidence.md` created; manual walkthrough pending

---

## Dependencies

- Depends on: Camera & Map System (visual foundation)
- Cross-epic: Turn-Based Mode (turn order data), Skill System (skill data), Resource Economy (MP display)
