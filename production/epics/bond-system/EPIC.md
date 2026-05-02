# Epic: Bond System MVP

> **Layer**: Feature
> **GDD**: `design/gdd/bond-system.md`
> **Status**: Complete
> **Created**: 2026-04-27
> **Sprint Source**: Sprint-005 / BOND-001

## Goal

Create the smallest implementation slice of the designed bond system that can support Ch.3 special dialogue and future base tavern interactions without implementing the full relationship network, combo skills, or visual effects.

## Scope Boundary

Sprint-006 implements the bounded MVP: pair-keyed bond data, combat affinity gain, save payload, and character detail summary. Sprint-007 adds tavern dialogue. Sprint-008 completes combo-skill design. Sprint-009 completes combo-skill runtime validation and battle UI integration. Full relationship network graph remains future work.

## Stories

| ID | Title | Type | Est. | Dependencies | Status |
|---|---|---|---|---|---|
| BOND-DATA-001 | Bond data model + save payload | Logic + Integration | 0.5d | SaveData / `design/gdd/bond-system.md` | Complete |
| BOND-EVT-001 | Affinity gain event hooks | Integration | 0.5d | BOND-DATA-001 / GameEvents / battle settlement | Complete |
| BOND-003 | Base tavern dialogue trigger MVP | UI/Integration | 0.5d | Base full phase 1 | Complete |
| BOND-UI-001 | Character detail bond summary | UI + Integration | 0.25d | BOND-DATA-001 / Character management UI | Complete |
| BOND-COMBO-DESIGN | Combo skill GDD refinement | Design | 0.5d | Bond GDD / Sprint-008 | Complete |
| BOND-COMBO-001 | Combo skill data model + trigger | Logic | 0.5d | Bond GDD / Sprint-009 | Complete |
| BOND-COMBO-002 | Combo skill battle UI + integration | Integration/UI | 0.5d | BOND-COMBO-001 | Complete |

## TR-IDs

| Story | TR-ID | Requirement |
|---|---|---|
| story-001-data-model-save | TR-bond-001 | Bond pair data model and SaveData payload |
| story-002-affinity-event-hooks | TR-bond-002 | Deterministic affinity gain event hooks |
| story-003-base-tavern-dialogue | TR-bond-003 | Future tavern dialogue trigger |
| story-004-character-summary | TR-bond-004 | Character detail Bond summary |

## MVP Acceptance Criteria

- Bond pairs persist across save/load.
- Affinity can increase from at least one combat or camp event.
- Ch.3 dialogue can query whether a pair meets a threshold.
- Character management can display a compact bond summary.
- No full combo-skill implementation is required for MVP.

## Out of Scope

- S-rank romance content
- Full relationship network graph
- Combination skill animations
- Route-exclusive bond events beyond Ch.3 placeholders

## Sprint-006 Handoff

Completion evidence: `src/core/bond/bond_registry.gd`, `GameEvents.bond_level_up`, `tests/unit/bond/bond_data_model_test.gd`, `tests/integration/bond/affinity_event_hooks_test.gd`, character detail coverage in `tests/integration/ui/character_management_test.gd`, and Sprint-007 Tavern coverage in `tests/integration/ui/base_hub_test.gd`.

## Sprint-008 Handoff

Combo-skill trigger conditions, effect types, rank gates, cooldown scope, and failure feedback are specified in `design/gdd/bond-system.md`. Runtime implementation is intentionally deferred to Sprint-009.

## Completion Evidence

- `src/core/bond/combo_skill_data.gd`
- `src/core/bond/combo_validator.gd`
- `tests/unit/bond/combo_validator_test.gd`
- `tests/integration/bond/combo_battle_ui_test.gd`
