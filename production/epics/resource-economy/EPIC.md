# Epic: Resource Economy

> **Layer**: Core
> **GDD**: design/gdd/resource-economy.md
> **Architecture Module**: Resource
> **Status**: Complete
> **Stories**: 7 stories

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

## TR-IDs

本 epic 实现以下技术需求（详见 `production/registries/tr-registry.yaml`）：

| Story | TR-ID | Requirement |
|-------|-------|-------------|
| story-001-data-model-inventory | TR-resource-001 | Dual-layer resource taxonomy: 4 common types + 5 rare type... |
| story-002-gold-material-acquisition | TR-resource-002 | Gold and material acquisition formulas from combat rewards |
| story-003-rare-drops | TR-resource-003 | Rare drops: fruit drop probability, protection symbol acqu... |
| story-004-consumption-costs | TR-resource-004 | Consumption costs: enhancement, fruit usage, barrier break... |
| story-005-enhancement-system | TR-resource-005 | Enhancement system: safe zone +1~+5, risk zone +6+ with fa... |
| story-006-save-load-integration | TR-resource-006 | Resource state round-trip through save/load with stack lim... |
| story-007-base-upgrade-cost-config | TR-resource-007 | Base upgrade cost data table for future upgrade UI |

## Stories

| # | Story | Type | Status | ADR |
|---|-------|------|--------|-----|
| 001 | Data Model & Inventory | Logic | Complete | ADR-001, ADR-003 |
| 002 | Gold & Material Acquisition | Logic | Complete | ADR-001 |
| 003 | Rare Resource Drops | Logic | Complete | ADR-001 |
| 004 | Resource Consumption & Costs | Logic | Complete | ADR-001 |
| 005 | Enhancement System | Logic | Complete | ADR-001 |
| 006 | Resource Save/Load Integration | Integration | Complete | ADR-001, ADR-003 |
| 007 | Base Upgrade Cost Config | Config/Data | Complete | ADR-008 |

## Definition of Done

This epic is complete when:
- All stories are implemented, reviewed, and closed via `/story-done`
- All acceptance criteria from `design/gdd/resource-economy.md` are verified (AC.1 through AC.6)
- Gold and material formulas have unit tests
- Resource save/load round-trip is verified
- Stack overflow behavior is tested

## Next Step

Future Base Upgrade UI should consume `assets/data/economy/base-upgrade-costs.json` rather than hardcoding upgrade prices in UI code.
