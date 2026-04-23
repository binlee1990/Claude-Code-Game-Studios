# Story 003: UI Save/Load Integration

> **Epic**: UI System
> **Status**: Complete
> **Layer**: Presentation
> **Type**: Integration
> **Manifest Version**: N/A — manifest not yet created

> **Estimate**: 2-3 hours

## Context

**GDD**: `design/gdd/ui-system.md`
**Requirement**: UI preferences persistence

**ADR Governing Implementation**: ADR-001, ADR-003 (Save System)
**Engine**: Godot 4.6.2 | **Risk**: LOW

---

## Acceptance Criteria

- [ ] AC-S1: UI preferences (volume, display settings, control bindings) saved and restored
- [ ] AC-S2: Last-used menu tab/screen remembered across sessions
- [ ] AC-S3: Multiple save/load cycles produce identical UI settings

---

## Implementation Notes

From ADR-003: UI settings stored as user preferences separate from game save data. Includes: master_volume, sfx_volume, bgm_volume, screen_mode, key_bindings. Settings persist across all save slots.

---

## Out of Scope

- Save UI screen design
- Auto-save triggering

---

## QA Test Cases

- **AC-S1**: Settings persistence
  - Given: Volume set to 70%, screen mode = windowed
  - When: Save → close → reopen → Load
  - Then: Volume 70%, windowed mode

- **AC-S2**: Menu state memory
  - Given: Last opened menu tab was "Equipment"
  - When: Save → Load → open menu
  - Then: Menu opens on "Equipment" tab

- **AC-S3**: Double round-trip
  - Given: Custom key bindings and volume settings
  - When: Save → Load → Save → Load
  - Then: All settings match

---

## Test Evidence

**Story Type**: Integration
**Required evidence**: `tests/integration/ui/save_load_integration_test.gd`
**Status**: [x] `tests/integration/ui/save_load_integration_test.gd` created and passing

---

## Dependencies

- Depends on: Stories 001-002 (UI must exist before persisting preferences)
