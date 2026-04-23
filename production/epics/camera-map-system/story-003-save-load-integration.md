# Story 003: Camera Save/Load Integration

> **Epic**: Camera & Map System
> **Status**: Complete
> **Layer**: Presentation
> **Type**: Integration
> **Manifest Version**: N/A — manifest not yet created

> **Estimate**: 2-3 hours

## Context

**GDD**: `design/gdd/camera-map-system.md`
**Requirement**: Camera preferences persistence

**ADR Governing Implementation**: ADR-001, ADR-003 (Save System)
**Engine**: Godot 4.6.2 | **Risk**: LOW

---

## Acceptance Criteria

- [ ] AC-S1: Last camera rotation angle saved and restored on reload
- [ ] AC-S2: Grid overlay preference (on/off) persisted
- [ ] AC-S3: Multiple save/load cycles produce identical camera state

---

## Implementation Notes

From ADR-003: Camera preferences stored as user settings. Includes: rotation_angle (0/90/180/270), grid_overlay_enabled (bool). Settings are separate from battle state — persist across sessions regardless of save slot.

---

## Out of Scope

- Save UI
- Auto-save triggering

---

## QA Test Cases

- **AC-S1**: Rotation preference
  - Given: Camera rotated to 180°
  - When: Save → Load
  - Then: Camera at 180° angle

- **AC-S2**: Grid overlay preference
  - Given: Grid overlay toggled OFF
  - When: Save → Load
  - Then: Grid overlay remains OFF

- **AC-S3**: Double round-trip
  - Given: Camera at 90°, grid ON
  - When: Save → Load → Save → Load
  - Then: Camera 90°, grid ON

---

## Test Evidence

**Story Type**: Integration
**Required evidence**: `tests/integration/camera/save_load_integration_test.gd`
**Status**: [x] `tests/integration/camera/save_load_integration_test.gd` created and passing

---

## Dependencies

- Depends on: Stories 001-002 (camera and grid must exist before persisting state)
