# Story 001: Isometric Camera

> **Epic**: Camera & Map System
> **Status**: Complete
> **Layer**: Presentation
> **Type**: Visual/Feel
> **Manifest Version**: N/A — manifest not yet created

> **Estimate**: 3-4 hours

## Context

**GDD**: `design/gdd/camera-map-system.md`
**Requirement**: AC.1.1-1.2 (2.5D isometric view, 4 rotation angles)

**ADR Governing Implementation**: ADR-001 (Event Architecture)
**Engine**: Godot 4.6.2 | **Risk**: LOW

---

## Acceptance Criteria

- [ ] AC.1.1: 2.5D isometric camera at 45-degree oblique angle renders correctly
- [ ] AC.1.2: Camera rotates between 4 fixed angles (0°/90°/180°/270°) via keyboard shortcut or UI button
- [ ] AC.1.3: Camera maintains consistent framing across all 4 rotation angles

---

## Implementation Notes

From GDD C.1: 2.5D oblique 45-degree isometric view. From C.2: 4 fixed rotation angles triggered by shortcut or UI button. Camera should maintain consistent framing across all rotations. Rotation should be smooth (animated transition, not instant snap). HD-2D style: 3D scene environment with pixel-art style characters.

---

## Out of Scope

- Grid rendering (Story 002)
- Camera follow behavior (follow active unit)
- Minimap

---

## QA Test Cases

- **AC.1.1**: Isometric view
  - Setup: Load a battle scene with terrain
  - Verify: Camera angle produces clear 45-degree isometric perspective
  - Pass condition: All terrain layers visible, no occlusion of gameplay-critical elements

- **AC.1.2**: 4-angle rotation
  - Setup: Battle scene loaded, camera at default 0°
  - Verify: Press rotation key/button → camera smoothly transitions to 90°, 180°, 270°, and back to 0°
  - Pass condition: All 4 angles render correctly, rotation animation ≤ 0.5s, no frame drops

---

## Test Evidence

**Story Type**: Visual/Feel
**Required evidence**: `production/qa/evidence/camera-isometric-evidence.md` + screenshot sign-off
**Status**: [x] `production/qa/evidence/camera-isometric-evidence.md` created; screenshot sign-off pending

---

## Dependencies

- Depends on: None
- Unlocks: Story 002 (grid rendered under camera), Story 003 (save/load)
