# Epic: Character Management

> **Layer**: Feature
> **GDD**: design/gdd/character-management.md
> **Architecture Module**: Attributes
> **Status**: Ready
> **Stories**: 3 stories created (2 Logic, 1 Integration)

## Overview

Implements party composition and roster management: players maintain a roster of characters, select up to 4 for battle deployment, and manage character departures/recalls driven by narrative events. Integrates with the attribute, class, skill, and equipment systems to present a unified character status view.

## Governing ADRs

| ADR | Decision Summary | Engine Risk |
|-----|-----------------|-------------|
| ADR-001: Event Architecture | Roster change events (unit_spawned, unit_died) via GameEvents | LOW |
| ADR-003: Save System | Roster state, deployment history, and departure status persisted | LOW |

## GDD Requirements

| Source | Requirement | ADR Coverage |
|--------|-------------|--------------|
| Core Rules | Party composition: max 4 deployed characters per battle | ADR-001, ADR-003 |
| Core Rules | Roster management: view all owned characters, stats, equipment | ADR-001 |
| Core Rules | Narrative departure: characters leave based on story events | ADR-001, ADR-003 |
| Core Rules | Character recall: departed characters can return via specific quests | ADR-003 |

> Note: TR-IDs not yet registered in registry. Run `/architecture-review` to populate.

## Stories

| # | Story | Type | Status | ADR |
|---|-------|------|--------|-----|
| 001 | Party Composition | Logic | Ready | ADR-001 |
| 002 | Character Departure & Recall | Logic | Ready | ADR-001 |
| 003 | Character Save/Load Integration | Integration | Ready | ADR-001, ADR-003 |

## Definition of Done

This epic is complete when:
- All stories are implemented, reviewed, and closed via `/story-done`
- All acceptance criteria from `design/gdd/character-management.md` are verified
- Party size limit (4) is enforced
- Departure/recall state is correctly persisted and restored

## Next Step

Run `/story-readiness production/epics/character-management/story-001-party-composition.md` then `/dev-story` to begin implementation.
