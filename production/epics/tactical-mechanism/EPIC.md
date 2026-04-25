# Epic: Tactical Mechanism

> **Layer**: Core
> **GDD**: design/gdd/tactical-mechanism.md
> **Architecture Module**: Combat
> **Status**: Ready
> **Stories**: 5 stories created (4 Logic, 1 Integration)

## Overview

Implements the three-layer tactical system on a 2.5D isometric grid (15x15 to 25x25): weapon triangle (sword>axe>spear>sword with 1.5x damage), elemental interactions (fire burns oil, water conducts electricity, wind fans flames, earth+water creates mud), and height advantage (range +/-1, hit +/-10% per level). These layers combine to create emergent tactical depth in positioning and unit composition.

## Governing ADRs

| ADR | Decision Summary | Engine Risk |
|-----|-----------------|-------------|
| ADR-001: Event Architecture | Tactical events (element triggered, terrain changed) via GameEvents | LOW |

## GDD Requirements

| Source | Requirement | ADR Coverage |
|--------|-------------|--------------|
| Section C.1 | Weapon triangle: sword>axe>spear>sword, 1.5x damage multiplier | ADR-001 |
| Section C.2 | Elemental interactions: fire/oil burn, water/electric chain, wind/fire spread, water/earth mud | ADR-001 |
| Section C.3 | Height system: 3 levels (0/1/2), range +/-1 and hit +/-10% per level difference | ADR-001 |
| Section C.4 | Terrain types: normal, grass, water, sand, mud, highland, obstacle | ADR-001 |
| Section D.1 | Crush + restraint stacking: max 2.25x multiplier | ADR-001 |

## TR-IDs

本 epic 实现以下技术需求（详见 `production/registries/tr-registry.yaml`）：

| Story | TR-ID | Requirement |
|-------|-------|-------------|
| story-001-terrain-data-model | TR-tactical-001 | Terrain data model: 7 terrain types with movement cost, de... |
| story-002-weapon-triangle | TR-tactical-002 | Weapon triangle: sword>axe>spear>sword with 1.5x damage mu... |
| story-003-height-advantage | TR-tactical-003 | Height advantage: 3 levels, range +/-1 and hit +/-10% per... |
| story-004-elemental-interactions | TR-tactical-004 | Elemental interactions: fire/oil burn, water/electric chai... |
| story-005-save-load-integration | TR-tactical-005 | Tactical state round-trip through save/load |

## Stories

| # | Story | Type | Status | ADR |
|---|-------|------|--------|-----|
| 001 | Terrain Data Model | Logic | Ready | ADR-001 |
| 002 | Weapon Triangle | Logic | Ready | ADR-001 |
| 003 | Height Advantage | Logic | Ready | ADR-001 |
| 004 | Elemental Interactions | Logic | Ready | ADR-001 |
| 005 | Tactical Save/Load Integration | Integration | Ready | ADR-001, ADR-003 |

## Definition of Done

This epic is complete when:
- All stories are implemented, reviewed, and closed via `/story-done`
- All acceptance criteria from `design/gdd/tactical-mechanism.md` are verified (AC.1 through AC.4)
- Weapon triangle and height modifiers have unit tests
- Elemental interaction chains are integration-tested
- Terrain effects on movement are tested

## Next Step

Run `/story-readiness production/epics/tactical-mechanism/story-001-terrain-data-model.md` then `/dev-story` to begin implementation.
