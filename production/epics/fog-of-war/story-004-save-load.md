# Story FOG-004: Save/load Fog State

> **Epic**: Fog-of-war MVP
> **Status**: Complete
> **Type**: Integration

## Acceptance Criteria

- [x] Fog enabled flag persists in battle_state.
- [x] Explored cells persist when saving mid-battle.
- [x] Missing fog state in old saves defaults to disabled.

## Evidence

- `tests/integration/fog/fog_save_load_test.gd`
- `tests/unit/fog/battle_integration_test.gd`
