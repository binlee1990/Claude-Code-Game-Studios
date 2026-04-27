# Epic: Equipment System

> **Layer**: Feature
> **GDD**: design/gdd/equipment-system.md
> **Architecture Module**: Equipment
> **Status**: Complete
> **Stories**: 10 stories

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

## TR-IDs

本 epic 实现以下技术需求（详见 `production/registries/tr-registry.yaml`）：

| Story | TR-ID | Requirement |
|-------|-------|-------------|
| story-001-equipment-data-model | TR-equip-001 | Equipment data model: 5 quality tiers (White/Green/Blue/Pu... |
| story-002-affix-generation | TR-equip-002 | Affix generation: 1-4 random affixes based on quality tier |
| story-003-enhancement-system | TR-equip-003 | Enhancement: safe zone +1~+5 guaranteed, risk zone +6+ wit... |
| story-004-set-bonus-system | TR-equip-004 | Set bonus system: collect matching pieces for activated st... |
| story-005-equipment-decomposition | TR-equip-005 | Equipment decomposition: convert equipment to crafting mat... |
| story-006-final-attribute-calculation | TR-equip-006 | Final attribute calculation: base + growth + class bonus +... |
| story-007-save-load-integration | TR-equip-007 | Equipment state round-trip through save/load (inventory, l... |
| story-008-enhancement-ui-mvp | TR-equip-008 | Equipment enhancement UI exposes equipped-item +1~+5 flow |
| story-009-enhancement-cost-source | TR-equip-009 | Enhancement costs and shortage/failure feedback use resource economy ownership |
| story-010-enhancement-round-trip | TR-equip-010 | Enhancement result feedback and +5 round-trip persistence |

## Stories

| # | Story | Type | Status | ADR |
|---|-------|------|--------|-----|
| 001 | Equipment Data Model | Logic | Complete | ADR-001 |
| 002 | Affix Generation | Logic | Complete | ADR-001 |
| 003 | Enhancement System | Logic | Complete | ADR-001 |
| 004 | Set Bonus System | Logic | Complete | ADR-001 |
| 005 | Equipment Decomposition | Logic | Complete | ADR-001 |
| 006 | Final Attribute Calculation | Logic | Complete | ADR-001 |
| 007 | Equipment Save/Load Integration | Integration | Complete | ADR-001, ADR-003 |
| 008 | Enhancement UI MVP | UI + Integration | Complete | ADR-008, ADR-009 |
| 009 | Enhancement Cost Source + Failure Feedback | Logic + Integration | Complete | ADR-008, ADR-009 |
| 010 | Enhancement Round-Trip + Failure UI | UI + Integration | Complete | ADR-003, ADR-009 |

## Definition of Done

This epic is complete when:
- All stories are implemented, reviewed, and closed via `/story-done`
- All acceptance criteria from `design/gdd/equipment-system.md` are verified
- Affix generation produces correct quality-tier distributions
- Enhancement success/failure and protection symbol logic are unit-tested
- Equipment stat bonuses correctly merge with class bonuses in final attribute calculation

## Sprint-006 Extension

Sprint-006 reopened and completed a narrow player-facing upgrade slice without changing the completed equipment core:

1. `story-008-enhancement-ui-mvp.md` exposes existing enhancement logic for equipped items only.
2. `story-009-enhancement-cost-source.md` keeps costs and shortage checks owned by resource economy.
3. `story-010-enhancement-round-trip.md` closes feedback and persistence polish.

## Next Step

Sprint-007+ may implement +6 risk-zone UI, affix reroll, decomposition UI, or set crafting as separate scoped stories.
