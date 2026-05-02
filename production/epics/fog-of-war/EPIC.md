# Epic: Fog-of-war MVP

> **Layer**: Feature
> **GDD**: `design/gdd/fog-of-war-system.md`
> **Status**: Complete
> **Created**: 2026-04-27
> **Sprint Source**: Sprint-005 / FOG-001

## Goal

Implement a bounded fog-of-war path for maps that require night battle, ambush, or scouting gameplay. Sprint-009 completed the MVP data, reveal, unit visibility, rendering, battle integration, and save/load rules.

## Stories

| ID | Title | Type | Est. | Dependencies | Status |
|---|---|---|---|---|---|
| FOG-001 | Visibility data model | Logic | 0.5d | tactical grid positions | Complete |
| FOG-002 | Fog rendering overlay MVP | UI/Visual | 0.5d | battle grid renderer | Complete |
| FOG-003 | Unit visibility integration | Integration | 0.5d | AI / combat targeting | Complete |
| FOG-004 | Save/load fog state | Integration | 0.25d | SaveData battle_state | Complete |
| FOG-GDD | Fog-of-war GDD refinement | Design | 0.5d | Sprint-008 | Complete |

## MVP Acceptance Criteria

- Visibility states support unknown, explored, and visible.
- Player units reveal cells by vision range.
- Hidden enemies are not rendered until visible.
- Fog state can be reset per battle and optionally serialized.
- Non-fog battles behave exactly as before.

## Out of Scope

- Minimap
- Advanced light-source effects
- Enemy AI vision parity
- Performance optimization beyond MVP map sizes

## Sprint-006+ Handoff

Do not implement this epic until a specific chapter map needs fog. The first implementation should be map-opt-in, not global.

## Sprint-008 Handoff

`design/gdd/fog-of-war-system.md` now defines the Sprint-009 MVP entry point: map-opt-in `fog.enabled`, unknown/explored/visible cell states, reveal triggers, player/NPC/enemy unit rules, overlay expectations, battle_state save scope, and test gates.

## Completion Evidence

- `src/core/fog/fog_state_manager.gd`
- `src/core/fog/fog_renderer.gd`
- `src/core/fog/fog_target_filter.gd`
- `src/core/fog/fog_battle_integration.gd`
- `tests/unit/fog/visibility_model_test.gd`
- `tests/unit/fog/rendering_overlay_test.gd`
- `tests/unit/fog/target_filter_test.gd`
- `tests/unit/fog/battle_integration_test.gd`
- `tests/integration/fog/fog_save_load_test.gd`
