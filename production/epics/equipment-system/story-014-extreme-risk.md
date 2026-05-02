# Story 014: Equipment +11+ Extreme-Risk Tuning

> **Epic**: Equipment System
> **Status**: Complete
> **Layer**: Feature
> **Type**: Config + Logic
> **Priority**: Nice to Have
> **Sprint**: Sprint-009
> **TR-ID**: TR-equip-014
> **ADR References**: ADR-009

## Context

Sprint-009 closes the equipment tuning gap above the Sprint-007 +6~+10 risk-zone slice. This story keeps the existing enhancement contract but extends the probability and protection-cost behavior to the +11+ extreme-risk zone.

## Acceptance Criteria

- [x] +11+ enhancement uses a lower success-rate curve than +6~+10.
- [x] Success chance never reaches zero, preserving a long-tail upgrade path.
- [x] Protection symbol cost increases in the extreme-risk zone.
- [x] Enhancement cannot exceed the item quality cap.
- [x] UI no longer hard-caps blue+ equipment at +10 when the item quality supports higher levels.

## QA Test Conditions

- Given a +11 blue item with enough protection symbols, when a protected failure occurs, then the item stays +11 and consumes 2 symbols.
- Given a +11 blue item with only 1 protection symbol, when protected enhancement is requested, then no gold/material/item mutation occurs.
- Given a +10 blue item with enough symbols, then the management UI exposes the +11 enhancement action.

## Test Evidence

- `tests/unit/equipment/extreme_risk_test.gd`
- `tests/integration/ui/character_management_test.gd`
- `src/core/equipment/equipment_definitions.gd`
- `src/core/equipment/equipment_component.gd`
- `src/ui/management/character_management.gd`

## Next Step

Human subjective tuning for "feels fair" remains in MAN-013. The deterministic AI-verifiable rules above are complete.
