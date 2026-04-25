# Epic: Class System

> **Layer**: Core
> **GDD**: design/gdd/class-system.md
> **Architecture Module**: Attributes
> **Status**: Ready
> **Stories**: 6 stories created

## Overview

Implements the three-tier class progression framework: 6 basic classes (default unlock), 6 advanced classes (attribute + experience gate), and special classes (achievement-point exchange). Each class provides stat bonuses applied to the attribute system. Class experience is gained through combat performance. Class changes trigger skill unlock/lock events and equipment revalidation.

## Governing ADRs

| ADR | Decision Summary | Engine Risk |
|-----|-----------------|-------------|
| ADR-001: Event Architecture | Class change signals via GameEvents (class_changed, class_level_up) | LOW |
| ADR-003: Save System | Class state, experience, and unlock history persisted | LOW |

## GDD Requirements

| Source | Requirement | ADR Coverage |
|--------|-------------|--------------|
| Section C.1 | Three-tier class architecture (Basic/Advanced/Special) with 6+6+3 classes | ADR-001, ADR-003 |
| Section C.2 | CAN_UNLOCK formula: primary attr >= threshold AND secondary attr >= threshold AND class_exp >= 500 | ADR-001 |
| Section C.3 | Class experience formula: floor(damage*0.02) + kill_bonus + battle_bonus | ADR-001 |
| Section C.4 | Class change flow: preserve attributes, reset new class exp, apply bonuses immediately | ADR-001, ADR-003 |
| Section C.5 | Per-class stat bonus table (STR/AGI/CON/INT/CHA/LUK/WIL/RES/SOU) | ADR-001 |

## TR-IDs

本 epic 实现以下技术需求（详见 `production/registries/tr-registry.yaml`）：

| Story | TR-ID | Requirement |
|-------|-------|-------------|
| story-001-data-model-state-machine | TR-class-001 | Three-tier class architecture: 6 basic + 6 advanced + 3 sp... |
| story-002-unlock-judgment | TR-class-002 | Unlock judgment: primary attr >= threshold AND secondary a... |
| story-003-experience-level | TR-class-003 | Class experience formula: floor(damage*0.02) + kill_bonus... |
| story-004-class-change-flow | TR-class-004 | Class change flow: preserve attributes, reset new class ex... |
| story-005-stat-bonuses | TR-class-005 | Per-class stat bonus table applied to 9 attributes |
| story-006-save-load-integration | TR-class-006 | Class state round-trip through save/load |

## Definition of Done

This epic is complete when:
- All stories are implemented, reviewed, and closed via `/story-done`
- All acceptance criteria from `design/gdd/class-system.md` are verified (AC.1 through AC.8)
- CAN_UNLOCK formula, class experience formula, and class level formula have unit tests
- Class change signal propagation to skill/equipment systems is integration-tested

## Stories

| # | Story | Type | Status | ADR |
|---|-------|------|--------|-----|
| 001 | Class Data Model & State Machine | Logic | Ready | ADR-001 |
| 002 | Class Unlock Judgment (CAN_UNLOCK) | Logic | Ready | ADR-001 |
| 003 | Class Experience & Level System | Logic | Ready | ADR-001 |
| 004 | Class Change Flow | Logic | Ready | ADR-001 |
| 005 | Class Stat Bonuses | Logic | Ready | ADR-001 |
| 006 | Class Save/Load Integration | Integration | Ready | ADR-001, ADR-003 |

## Next Step

Run `/story-readiness production/epics/class-system/story-001-data-model-state-machine.md` to validate, then `/dev-story` to begin implementation.
