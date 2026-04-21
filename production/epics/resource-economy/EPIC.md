# Epic: Resource Economy

> **Layer**: Core
> **GDD**: design/gdd/resource-economy.md
> **Architecture Module**: Resource
> **Status**: Ready
> **Stories**: 6 stories created (5 Logic, 1 Integration)

## Overview

Implements the dual-layer resource framework: an abundant common layer (gold, basic materials, EXP, proficiency) for frictionless daily gameplay, and a scarce rare layer (fruits, rare materials, protection symbols, barrier resources, achievement points) for strategic decision-making. Handles resource acquisition from combat rewards, consumption across multiple systems (enhancement, fruit usage, barrier breakthrough), stack limits, and overflow.

## Governing ADRs

| ADR | Decision Summary | Engine Risk |
|-----|-----------------|-------------|
| ADR-001: Event Architecture | Resource change events via GameEvents | LOW |
| ADR-003: Save System | All resource holdings persisted | LOW |

## GDD Requirements

| Source | Requirement | ADR Coverage |
|--------|-------------|--------------|
| Section C.1 | Dual-layer resource taxonomy (4 common + 5 rare types, 9 fruit subtypes) | ADR-001, ADR-003 |
| Section C.2 | Resource acquisition formulas (gold, materials, fruit drop rates) | ADR-001 |
| Section C.3 | Resource consumption rules (enhancement costs, fruit usage, protection symbols) | ADR-001 |
| Section C.4 | Stack limits and overflow handling (gold 9,999,999; materials 9,999; fruits 99) | ADR-003 |
| Section D.1-D.4 | Gold formula, material formula, fruit drop formula, enhancement cost formula | ADR-001 |

> Note: TR-IDs not yet registered in registry. Run `/architecture-review` to populate.

## Stories

| # | Story | Type | Status | ADR |
|---|-------|------|--------|-----|
| 001 | Data Model & Inventory | Logic | Ready | ADR-001, ADR-003 |
| 002 | Gold & Material Acquisition | Logic | Ready | ADR-001 |
| 003 | Rare Resource Drops | Logic | Ready | ADR-001 |
| 004 | Resource Consumption & Costs | Logic | Ready | ADR-001 |
| 005 | Enhancement System | Logic | Ready | ADR-001 |
| 006 | Resource Save/Load Integration | Integration | Ready | ADR-001, ADR-003 |

## Definition of Done

This epic is complete when:
- All stories are implemented, reviewed, and closed via `/story-done`
- All acceptance criteria from `design/gdd/resource-economy.md` are verified (AC.1 through AC.6)
- Gold and material formulas have unit tests
- Resource save/load round-trip is verified
- Stack overflow behavior is tested

## Next Step

Run `/story-readiness production/epics/resource-economy/story-001-data-model-inventory.md` then `/dev-story` to begin implementation.
