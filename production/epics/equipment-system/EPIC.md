# Epic: Equipment System

> **Layer**: Feature
> **GDD**: design/gdd/equipment-system.md
> **Architecture Module**: Equipment
> **Status**: Ready
> **Stories**: 7 stories created (6 Logic, 1 Integration)

## Overview

Implements the ARPG-inspired equipment framework: random affix generation (1-4 affixes based on quality tier White/Green/Blue/Purple/Gold), enhancement system with safe zone (+1 to +5 guaranteed) and risk zone (+6+ with failure chance), equipment decomposition into crafting materials, and set bonuses for collecting matching pieces. Equipment provides the primary vertical progression path alongside attribute growth.

## Governing ADRs

| ADR | Decision Summary | Engine Risk |
|-----|-----------------|-------------|
| ADR-001: Event Architecture | Equipment events (item_equipped, item_unequipped) via GameEvents | LOW |
| ADR-003: Save System | Equipment inventory and loadout persisted | LOW |

## GDD Requirements

| Source | Requirement | ADR Coverage |
|--------|-------------|--------------|
| Core Rules | Quality tiers (White/Green/Blue/Purple/Gold) with affix count scaling | ADR-001, ADR-003 |
| Core Rules | Enhancement: safe zone +1~+5, risk zone +6+ with failure and downgrade | ADR-001, ADR-003 |
| Core Rules | Protection symbols prevent downgrade on failure | ADR-001 |
| Core Rules | Decomposition: convert equipment to materials | ADR-001 |
| Core Rules | Set bonuses: collect matching pieces for activated effects | ADR-001, ADR-003 |

> Note: TR-IDs not yet registered in registry. Run `/architecture-review` to populate.

## Stories

| # | Story | Type | Status | ADR |
|---|-------|------|--------|-----|
| 001 | Equipment Data Model | Logic | Ready | ADR-001 |
| 002 | Affix Generation | Logic | Ready | ADR-001 |
| 003 | Enhancement System | Logic | Ready | ADR-001 |
| 004 | Set Bonus System | Logic | Ready | ADR-001 |
| 005 | Equipment Decomposition | Logic | Ready | ADR-001 |
| 006 | Final Attribute Calculation | Logic | Ready | ADR-001 |
| 007 | Equipment Save/Load Integration | Integration | Ready | ADR-001, ADR-003 |

## Definition of Done

This epic is complete when:
- All stories are implemented, reviewed, and closed via `/story-done`
- All acceptance criteria from `design/gdd/equipment-system.md` are verified
- Affix generation produces correct quality-tier distributions
- Enhancement success/failure and protection symbol logic are unit-tested
- Equipment stat bonuses correctly merge with class bonuses in final attribute calculation

## Next Step

Run `/story-readiness production/epics/equipment-system/story-001-equipment-data-model.md` then `/dev-story` to begin implementation.
