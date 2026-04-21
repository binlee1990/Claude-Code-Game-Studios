# Story 007: Attribute Save/Load Integration

> **Epic**: Attribute & Growth System
> **Status**: Ready
> **Layer**: Core
> **Type**: Integration
> **Manifest Version**: N/A — manifest not yet created

> **Estimate**: 2-3 hours

## Context

**GDD**: `design/gdd/attribute-growth-system.md`
**Requirement**: Full attribute state persistence across save/load cycles

**ADR Governing Implementation**: ADR-001 (Event Architecture), ADR-003 (Save System)
**ADR Decision Summary**: Save system uses Resource + JSON serialization. UnitSaveData stores attributes (Dictionary), hidden_attributes (Dictionary), potential (Dictionary). SaveManager emits game_saved/game_loaded signals.

**Engine**: Godot 4.6.2 | **Risk**: LOW

---

## Acceptance Criteria

- [ ] AC-S1: All 9 attribute values (V) correctly saved and restored after load
- [ ] AC-S2: All 9 attribute potentials (P) correctly saved and restored
- [ ] AC-S3: Barrier breakthrough states per attribute per stage correctly persisted
- [ ] AC-S4: Threshold reward flags (first_reach per attribute per threshold) correctly persisted
- [ ] AC-S5: Multiple save/load cycles produce identical attribute state (round-trip integrity)

---

## Implementation Notes

From ADR-003:
- UnitSaveData.attributes stores normal attribute V values as Dictionary
- UnitSaveData.hidden_attributes stores hidden attribute V values
- UnitSaveData.potential stores all 9 P values
- Need to extend UnitSaveData with: barrier_states (per attribute, per stage), threshold_flags (per attribute, per threshold)
- AttributeComponent provides serialization methods: `to_save_data() -> Dictionary` and `from_save_data(data: Dictionary)`

---

## Out of Scope

- Save system UI (UI epic)
- Auto-save triggering (save system epic)
- Other system save/load (each system handles its own)

---

## QA Test Cases

- **AC-S1**: Attribute values round-trip
  - Given: Character with STR=85, AGI=72, CON=60, INT=45, CHA=33, LUK=28, WIL=15, RES=22, SOU=10
  - When: Save game → Load game
  - Then: All 9 V values match exactly
  - Edge cases: V=0, V=999 boundary values

- **AC-S2**: Attribute potentials round-trip
  - Given: Character with mixed potentials (STR P=B(4), AGI P=S(6), others P=E(1))
  - When: Save game → Load game
  - Then: All 9 P values match exactly
  - Edge cases: All P=S(6), all P=E(1)

- **AC-S3**: Barrier states round-trip
  - Given: STR stage 1 broken, stage 2 not broken; AGI stage 1 broken, stage 2 broken
  - When: Save game → Load game
  - Then: All barrier states match exactly per attribute per stage

- **AC-S4**: Threshold flags round-trip
  - Given: STR triggered at 50 but not 100; INT triggered at 50 and 100
  - When: Save game → Load game
  - Then: All threshold flags match exactly

- **AC-S5**: Multiple round-trips
  - Given: Character with complex state (mixed barriers, thresholds, varied V/P)
  - When: Save → Load → Save → Load (two cycles)
  - Then: Final state identical to state after first load
  - Edge cases: No drift across multiple cycles

---

## Test Evidence

**Story Type**: Integration
**Required evidence**: `tests/integration/attributes/save_load_integration_test.gd` — must exist and pass
**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: Story 001 (data model), Story 002 (growth), Story 003 (fruit), Story 004 (barrier), Story 005 (thresholds) — all attribute state must be defined before it can be serialized
- Unlocks: Attribute system is fully persistable
