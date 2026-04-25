# Epic: Camera & Map System

> **Layer**: Presentation
> **GDD**: design/gdd/camera-map-system.md
> **Architecture Module**: Presentation (dedicated)
> **Status**: Ready
> **Stories**: 3 stories created (2 Visual/Feel, 1 Integration)

## Overview

Implements the 2.5D isometric camera and map rendering: 45-degree oblique view over a square grid (15x15 to 25x25), 4 fixed rotation angles, height-differential terrain rendering (HD-2D style with 3D scene + pixel characters), and grid overlay for tactical readability. This is the visual foundation that all combat and exploration systems render on top of.

## Governing ADRs

| ADR | Decision Summary | Engine Risk |
|-----|-----------------|-------------|
| ADR-001: Event Architecture | Camera events (position changed, rotation changed) via GameEvents | LOW |

## GDD Requirements

| Source | Requirement | ADR Coverage |
|--------|-------------|--------------|
| Core Rules | 2.5D isometric camera at 45-degree oblique angle | ADR-001 |
| Core Rules | 4 fixed camera rotation angles | ADR-001 |
| Core Rules | Square grid (15x15 to 25x25) with HD-2D rendering | ADR-001 |
| Core Rules | Height-differential terrain: 3 levels with visual distinction | ADR-001 |
| Core Rules | Grid overlay for tactical readability | ADR-001 |

## TR-IDs

本 epic 实现以下技术需求（详见 `production/registries/tr-registry.yaml`）：

| Story | TR-ID | Requirement |
|-------|-------|-------------|
| story-001-isometric-camera | TR-camera-001 | 2.5D isometric camera at 45-degree oblique angle with 4 fi... |
| story-002-grid-map-rendering | TR-camera-002 | Grid map rendering: square grid 15x15~25x25 with 3-level h... |
| story-003-save-load-integration | TR-camera-003 | Camera state round-trip through save/load |

## Stories

| # | Story | Type | Status | ADR |
|---|-------|------|--------|-----|
| 001 | Isometric Camera | Visual/Feel | Ready | ADR-001 |
| 002 | Grid Map Rendering | Visual/Feel | Ready | ADR-001 |
| 003 | Camera Save/Load Integration | Integration | Ready | ADR-001, ADR-003 |

## Definition of Done

This epic is complete when:
- All stories are implemented, reviewed, and closed via `/story-done`
- All acceptance criteria from `design/gdd/camera-map-system.md` are verified
- Camera rotation works at all 4 angles without visual artifacts
- Grid correctly displays height differentials and terrain types
- Target 60 FPS maintained with standard map loaded

## Next Step

Run `/story-readiness production/epics/camera-map-system/story-001-isometric-camera.md` then `/dev-story` to begin implementation.
