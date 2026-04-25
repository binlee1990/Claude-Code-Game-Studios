# Epic: AI System

> **Layer**: Core
> **GDD**: design/gdd/ai-system.md
> **Architecture Module**: AI
> **Status**: Ready
> **Stories**: 6 stories created (5 Logic, 1 Integration)

## Overview

Implements the layered AI decision architecture: tactical layer (target selection via threat scoring), strategic layer (skill selection via expected value calculation), and execution layer (position scoring considering height, elements, support). Four AI personality types (aggressive, defensive, support, control) with different decision weights. Boss AI adds phase transitions and enrage mechanics.

## Governing ADRs

| ADR | Decision Summary | Engine Risk |
|-----|-----------------|-------------|
| ADR-001: Event Architecture | AI decisions output as structured actions to turn-based system | LOW |

## GDD Requirements

| Source | Requirement | ADR Coverage |
|--------|-------------|--------------|
| Section C.1 | Three-level behavior tree (tactical/strategic/execution) | ADR-001 |
| Section C.2 | Four AI types with different decision weights | ADR-001 |
| Section C.3 | Threat/hate system: base_threat + damage_recent + skill_threat + position_threat | ADR-001 |
| Section C.4 | Target selection priority: highest threat -> lowest killable -> lowest HP | ADR-001 |
| Section C.7 | Boss AI: phase switching at HP thresholds, enrage with +30% damage | ADR-001 |

## TR-IDs

本 epic 实现以下技术需求（详见 `production/registries/tr-registry.yaml`）：

| Story | TR-ID | Requirement |
|-------|-------|-------------|
| story-001-threat-hate-system | TR-ai-001 | Threat/hate system: threat_score = damage_potential*1.0 +... |
| story-002-ai-type-decision-weights | TR-ai-002 | 4 AI types (aggressive/defensive/support/control) with con... |
| story-003-target-skill-selection | TR-ai-003 | Target and skill selection: highest threat -> lowest killa... |
| story-004-position-scoring | TR-ai-004 | Position scoring: terrain evaluation + height advantage +... |
| story-005-boss-ai | TR-ai-005 | Boss AI: phase switching at 70%/50% HP thresholds, enrage... |
| story-006-save-load-integration | TR-ai-006 | AI state round-trip through save/load |

## Stories

| # | Story | Type | Status | ADR |
|---|-------|------|--------|-----|
| 001 | Threat/Hate System | Logic | Ready | ADR-001 |
| 002 | AI Type Decision Weights | Logic | Ready | ADR-001 |
| 003 | Target & Skill Selection | Logic | Ready | ADR-001 |
| 004 | Position Scoring | Logic | Ready | ADR-001 |
| 005 | Boss AI | Logic | Ready | ADR-001 |
| 006 | AI Save/Load Integration | Integration | Ready | ADR-001, ADR-003 |

## Definition of Done

This epic is complete when:
- All stories are implemented, reviewed, and closed via `/story-done`
- All acceptance criteria from `design/gdd/ai-system.md` are verified (AC.1 through AC.4)
- Threat calculation and target selection have unit tests
- AI type behaviors produce distinct action patterns in integration tests
- Boss phase transitions trigger correctly

## Next Step

Run `/story-readiness production/epics/ai-system/story-001-threat-hate-system.md` then `/dev-story` to begin implementation.
