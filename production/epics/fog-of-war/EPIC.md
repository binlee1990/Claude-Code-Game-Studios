# Epic: Fog-of-war MVP

> **Layer**: Feature
> **GDD**: `design/gdd/fog-of-war-system.md`
> **Status**: Ready for Sprint-006+ Planning
> **Created**: 2026-04-27
> **Sprint Source**: Sprint-005 / FOG-001

## Goal

Prepare a bounded fog-of-war implementation path for future chapter maps that require night battle, ambush, or scouting gameplay. Sprint-005 creates readiness artifacts only.

## Stories

| ID | Title | Type | Est. | Dependencies | Status |
|---|---|---|---|---|---|
| FOG-001 | Visibility data model | Logic | 0.5d | tactical grid positions | Ready |
| FOG-002 | Fog rendering overlay MVP | UI/Visual | 0.5d | battle grid renderer | Ready |
| FOG-003 | Unit visibility integration | Integration | 0.5d | AI / combat targeting | Ready |
| FOG-004 | Save/load fog state | Integration | 0.25d | SaveData battle_state | Ready |

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
