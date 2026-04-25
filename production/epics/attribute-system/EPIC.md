# Epic: Attribute & Growth System

> **Layer**: Core
> **GDD**: design/gdd/attribute-growth-system.md
> **Architecture Module**: Attributes
> **Status**: Ready
> **Stories**: 7 stories created

## Overview

Implements the foundational attribute data layer for all characters: 5 normal attributes (STR/AGI/CON/INT/CHA), 4 hidden attributes (LUK/WIL/RES/SOU), attribute potentials (E-S), the fruit-based potential upgrade system, barrier breakthrough at thresholds (50/100/150), threshold rewards, and the crush mechanic for large attribute gaps. All downstream systems (class, skill, equipment, combat, AI) read from this module.

## Governing ADRs

| ADR | Decision Summary | Engine Risk |
|-----|-----------------|-------------|
| ADR-001: Event Architecture | All inter-system communication via GameEvents autoload | LOW |
| ADR-003: Save System | Data persistence via dedicated save layer | LOW |

## GDD Requirements

| Source | Requirement | ADR Coverage |
|--------|-------------|--------------|
| Section C.1 | 9-attribute structure (5 normal + 4 hidden) with value V and potential P | ADR-001, ADR-003 |
| Section C.2 | Per-level growth formula: V_new = V_old + P_current | ADR-001 |
| Section C.3 | Fruit system: consume fruit to raise potential by 1 tier | ADR-001, ADR-003 |
| Section C.4 | Barrier breakthrough at 50/100/150 with challenge stage | ADR-001, ADR-003 |
| Section C.5 | Threshold rewards at 50/100/150 for normal attributes | ADR-001 |
| Section C.6 | Crush mechanic when attribute gap > 30 (1.5x damage, 20% defense reduction) | ADR-001 |

## TR-IDs

本 epic 实现以下技术需求（详见 `production/registries/tr-registry.yaml`）：

| Story | TR-ID | Requirement |
|-------|-------|-------------|
| story-001-data-model-init | TR-attr-001 | 9-attribute structure (5 normal STR/AGI/CON/INT/CHA + 4 hi... |
| story-002-growth-formula | TR-attr-002 | Per-level growth formula: V_new = V_old + P_current (deter... |
| story-003-fruit-system | TR-attr-003 | Fruit system: consume fruit to raise potential by 1 tier,... |
| story-004-barrier-breakthrough | TR-attr-004 | Barrier breakthrough at thresholds (50/100/150) with resou... |
| story-005-threshold-rewards | TR-attr-005 | Threshold rewards at attribute values 50/100/150 for norma... |
| story-006-crush-mechanic | TR-attr-006 | Crush mechanic: attribute gap > 30 triggers 1.5x damage +... |
| story-007-save-load-integration | TR-attr-007 | Attribute data round-trip through save/load with full fide... |

## Definition of Done

This epic is complete when:
- All stories are implemented, reviewed, and closed via `/story-done`
- All acceptance criteria from `design/gdd/attribute-growth-system.md` are verified (AC-1 through AC-15)
- All Logic stories have passing test files in `tests/unit/attributes/`
- Attribute state machine transitions are unit-tested
- Fruit usage and barrier breakthrough are integration-tested with save system

## Stories

| # | Story | Type | Status | ADR |
|---|-------|------|--------|-----|
| 001 | Attribute Data Model & Character Init | Logic | Ready | ADR-001 |
| 002 | Per-Level Growth Formula | Logic | Ready | ADR-001 |
| 003 | Fruit System (Potential Upgrade) | Logic | Ready | ADR-001 |
| 004 | Barrier Breakthrough | Logic | Ready | ADR-001 |
| 005 | Threshold Rewards | Logic | Ready | ADR-001 |
| 006 | Crush Mechanic | Logic | Ready | ADR-001 |
| 007 | Attribute Save/Load Integration | Integration | Ready | ADR-001, ADR-003 |

## Next Step

Run `/story-readiness production/epics/attribute-system/story-001-data-model-init.md` to validate the first story, then `/dev-story` to begin implementation.
