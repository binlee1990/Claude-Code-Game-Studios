# Epic: UI System

> **Layer**: Presentation
> **GDD**: design/gdd/ui-system.md
> **Architecture Module**: UI / HUD
> **Status**: Ready
> **Stories**: 3 stories created (2 UI, 1 Integration)

## Overview

Implements the unified UI layer for all game interfaces: battle HUD (HP/MP bars, skill bar, turn order), character panels (attributes, class, equipment, skills), menu screens (save/load, settings), and in-game HUD (resource display, notifications). Follows HD-2D Chinese aesthetic. All UI must support keyboard navigation per technical preferences.

## Governing ADRs

| ADR | Decision Summary | Engine Risk |
|-----|-----------------|-------------|
| ADR-001: Event Architecture | UI reacts to all game events for real-time updates | LOW |
| ADR-002: Scene Management | UI scene transitions managed by SceneManager | LOW |

## GDD Requirements

| Source | Requirement | ADR Coverage |
|--------|-------------|--------------|
| Core Rules | Battle HUD: HP/MP bars, skill cooldowns, turn order display | ADR-001 |
| Core Rules | Character panel: attributes, class info, equipment, skill list | ADR-001 |
| Core Rules | Menu system: save/load, settings, system options | ADR-001, ADR-002 |
| Core Rules | Resource display: gold, materials, rare items in top bar | ADR-001 |
| Core Rules | Keyboard navigation: all menus accessible without mouse | ADR-001 |

> Note: TR-IDs not yet registered in registry. Run `/architecture-review` to populate.

## Stories

| # | Story | Type | Status | ADR |
|---|-------|------|--------|-----|
| 001 | Battle HUD | UI | Ready | ADR-001 |
| 002 | Resource HUD & Menu System | UI | Ready | ADR-001, ADR-002 |
| 003 | UI Save/Load Integration | Integration | Ready | ADR-001, ADR-003 |

## Definition of Done

This epic is complete when:
- All stories are implemented, reviewed, and closed via `/story-done`
- All acceptance criteria from `design/gdd/ui-system.md` are verified
- All screens are fully keyboard-navigable
- UI updates reactively to all game state changes via event system
- HD-2D Chinese aesthetic is consistent across all screens

## Next Step

Run `/story-readiness production/epics/ui-system/story-001-battle-hud.md` then `/dev-story` to begin implementation.
