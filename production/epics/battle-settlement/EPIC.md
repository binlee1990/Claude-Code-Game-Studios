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

> Note: TR-IDs not yet registered in registry. Run `/architecture-review` to populate.

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
