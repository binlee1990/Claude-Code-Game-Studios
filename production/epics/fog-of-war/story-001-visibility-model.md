# Story FOG-001: Visibility Data Model

> **Epic**: Fog-of-war MVP
> **Status**: Complete
> **Type**: Logic

## Acceptance Criteria

- [x] Each map cell can be unknown, explored, or visible.
- [x] Vision reveal is deterministic from unit position and vision range.
- [x] Non-fog maps return all cells visible.
- [x] Unit tests cover reveal, persistence payload, and disabled mode.

## Evidence

- `tests/unit/fog/visibility_model_test.gd`
- `tests/integration/fog/fog_save_load_test.gd`
