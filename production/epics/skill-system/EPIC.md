# Epic: Skill System

> **Layer**: Core
> **GDD**: design/gdd/skill-system.md
> **Architecture Module**: Skills
> **Status**: Complete
> **Stories**: 7 stories created (6 Logic, 1 Integration)

## Overview

Implements the proficiency-driven skill growth framework: skills gain proficiency through combat, leveling up when thresholds are met (base_cost * level^1.5). Skills have rank ceilings (Basic/Master) requiring advancement challenges. At levels 10/20/30, players choose one trait from 2-3 options to permanently specialize the skill. Class-specific skills unlock on class change.

## Governing ADRs

| ADR | Decision Summary | Engine Risk |
|-----|-----------------|-------------|
| ADR-001: Event Architecture | Skill events (skill_executed, skill_learned) via GameEvents | LOW |
| ADR-003: Save System | Skill levels, proficiency, selected traits persisted | LOW |

## GDD Requirements

| Source | Requirement | ADR Coverage |
|--------|-------------|--------------|
| Section C.1 | Skill classification: normal/class, active/passive | ADR-001 |
| Section C.3 | Proficiency system: gained per battle, formula with synergy/talent bonuses | ADR-001, ADR-003 |
| Section C.4 | Rank system: Basic(10) / Intermediate(20) / Advanced(30) / Master(99) | ADR-003 |
| Section C.5 | Trait selection at levels 10/20/30 (2-3 choices, permanent) | ADR-003 |
| Section C.6 | Per-class skill list (12 classes, 12 unique skills) | ADR-001 |
| Section D.3 | Damage formula: base * level_mult * trait_mult * (1 + attr_bonus) | ADR-001 |

> Note: TR-IDs not yet registered in registry. Run `/architecture-review` to populate.

## Stories

| # | Story | Type | Status | ADR |
|---|-------|------|--------|-----|
| 001 | Skill Data Model | Logic | Complete | ADR-001 |
| 002 | Proficiency & Leveling | Logic | Complete | ADR-001 |
| 003 | Rank System | Logic | Complete | ADR-001 |
| 004 | Trait Selection | Logic | Complete | ADR-001 |
| 005 | Skill Damage Calculation | Logic | Complete | ADR-001 |
| 006 | Class Skills | Logic | Complete | ADR-001 |
| 007 | Skill Save/Load Integration | Integration | Complete | ADR-001, ADR-003 |

## Definition of Done

This epic is complete when:
- All stories are implemented, reviewed, and closed via `/story-done`
- All acceptance criteria from `design/gdd/skill-system.md` are verified (AC.1 through AC.4)
- Proficiency gain and level-up formulas have unit tests
- Trait selection correctly applies to skill damage calculations
- Class change triggers correct skill unlock/lock behavior

## Next Step

Epic complete. Next ordered execution item is `production/epics/equipment-system/`.
