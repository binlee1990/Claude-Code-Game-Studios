# Epic: Turn-Based Mode

> **Layer**: Core
> **GDD**: design/gdd/turn-based-mode.md
> **Architecture Module**: Combat
> **Status**: Ready
> **Stories**: 7 stories created (6 Logic, 1 Integration)

## Overview

Implements the speed-sequence turn-based combat framework: all units act in AGI-sorted order, visualized by an action order bar. Each turn allows move + skill/attack + standby. Supports auto-battle and speed-up modes for convenience. Speed investment gives explicit tactical payoff — high-AGI units act more frequently and can chain actions before enemies respond.

## Governing ADRs

| ADR | Decision Summary | Engine Risk |
|-----|-----------------|-------------|
| ADR-001: Event Architecture | Turn events (turn_started, turn_ended) via GameEvents | LOW |
| ADR-002: Scene Management | Combat scene lifecycle managed by SceneManager | LOW |

## GDD Requirements

| Source | Requirement | ADR Coverage |
|--------|-------------|--------------|
| Core Rules | Speed-sequence ordering based on AGI attribute | ADR-001 |
| Core Rules | Per-turn action budget: move + skill/attack or standby | ADR-001 |
| Core Rules | Visual action order bar showing all unit positions | ADR-001 |
| Core Rules | Auto-battle mode (AI controls player units) | ADR-001 |
| Core Rules | Speed-up mode (accelerated animations/timers) | ADR-001 |
| Core Rules | Turn flow: start -> actions -> end -> next unit | ADR-001, ADR-002 |

> Note: TR-IDs not yet registered in registry. Run `/architecture-review` to populate.

## Stories

| # | Story | Type | Status | ADR |
|---|-------|------|--------|-----|
| 001 | Turn Order & Speed Sequence | Logic | Ready | ADR-001 |
| 002 | Action System | Logic | Ready | ADR-001 |
| 003 | Movement System | Logic | Ready | ADR-001 |
| 004 | Combat Flow State Machine | Logic | Ready | ADR-001, ADR-002 |
| 005 | Auto Battle Mode | Logic | Ready | ADR-001 |
| 006 | Speed-Up Mode | Logic | Ready | ADR-001 |
| 007 | Turn-Based Save/Load Integration | Integration | Ready | ADR-001, ADR-003 |

## Definition of Done

This epic is complete when:
- All stories are implemented, reviewed, and closed via `/story-done`
- All acceptance criteria from `design/gdd/turn-based-mode.md` are verified
- Turn order sorting by AGI is unit-tested
- Turn flow state machine transitions are tested
- Auto-battle and speed-up modes function correctly

## Next Step

Run `/story-readiness production/epics/turn-based-mode/story-001-turn-order-speed-sequence.md` then `/dev-story` to begin implementation.
