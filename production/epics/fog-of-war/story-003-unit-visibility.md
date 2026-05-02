# Story FOG-003: Unit Visibility Integration

> **Epic**: Fog-of-war MVP
> **Status**: Complete
> **Type**: Integration

## Acceptance Criteria

- [x] Enemy units outside player visibility are hidden.
- [x] Hidden enemies cannot be selected by player targeting UI.
- [x] Enemy AI behavior remains deterministic in MVP.
- [x] Entering visibility reveals the enemy without corrupting turn order.

## Evidence

- `src/core/fog/fog_target_filter.gd`
- `src/core/fog/fog_battle_integration.gd`
- `tests/unit/fog/target_filter_test.gd`
- `tests/unit/fog/battle_integration_test.gd`
