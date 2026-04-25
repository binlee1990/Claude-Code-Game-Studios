# Epic: Battle Settlement

> **Layer**: Feature
> **GDD**: design/gdd/battle-settlement.md
> **Architecture Module**: Combat
> **Status**: Ready
> **Stories**: 5 stories created (4 Logic, 1 Integration)

## Overview

Implements the post-battle reward pipeline that closes the gameplay loop: calculates and distributes experience, gold, materials, fruits, and achievement points based on combat performance (damage dealt, kills, enemy tier). Ties the resource economy system to actual gameplay outcomes, ensuring player effort translates to tangible progression.

## Governing ADRs

| ADR | Decision Summary | Engine Risk |
|-----|-----------------|-------------|
| ADR-001: Event Architecture | Battle result events (battle_ended) trigger settlement calculation | LOW |
| ADR-003: Save System | Reward state and post-battle progression persisted | LOW |

## GDD Requirements

| Source | Requirement | ADR Coverage |
|--------|-------------|--------------|
| Core Rules | Reward categories: EXP, gold, materials, fruits, achievement points | ADR-001, ADR-003 |
| Core Rules | Performance-linked rewards: damage dealt and kill count affect payouts | ADR-001 |
| Core Rules | Boss vs normal reward differentiation | ADR-001 |
| Core Rules | Settlement UI: display all rewards with animations | ADR-001 |

## TR-IDs

本 epic 实现以下技术需求（详见 `production/registries/tr-registry.yaml`）：

| Story | TR-ID | Requirement |
|-------|-------|-------------|
| story-001-settlement-trigger-flow | TR-settle-001 | Settlement trigger: battle_ended signal initiates reward p... |
| story-002-experience-distribution | TR-settle-002 | Experience distribution: performance-linked EXP based on d... |
| story-003-battle-evaluation | TR-settle-003 | Battle evaluation: S/A/B/C/D grade based on turns, losses,... |
| story-004-material-equipment-drops | TR-settle-004 | Material and equipment drops: gold, materials, rare items... |
| story-005-save-load-integration | TR-settle-005 | Settlement state round-trip through save/load (rewards, b... |

## Stories

| # | Story | Type | Status | ADR |
|---|-------|------|--------|-----|
| 001 | Settlement Trigger & Flow | Logic | Ready | ADR-001 |
| 002 | Experience Distribution | Logic | Ready | ADR-001 |
| 003 | Battle Evaluation | Logic | Ready | ADR-001 |
| 004 | Material & Equipment Drops | Logic | Ready | ADR-001 |
| 005 | Settlement Save/Load Integration | Integration | Ready | ADR-001, ADR-003 |

## Definition of Done

This epic is complete when:
- All stories are implemented, reviewed, and closed via `/story-done`
- All acceptance criteria from `design/gdd/battle-settlement.md` are verified
- Reward formulas (gold, materials, fruit drops) match resource economy GDD
- Settlement correctly triggers attribute growth, class experience, and skill proficiency

## Next Step

Run `/story-readiness production/epics/battle-settlement/story-001-settlement-trigger-flow.md` then `/dev-story` to begin implementation.
