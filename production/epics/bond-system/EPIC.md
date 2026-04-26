# Epic: Bond System MVP

> **Layer**: Feature
> **GDD**: `design/gdd/bond-system.md`
> **Status**: Ready for Sprint-006 Planning
> **Created**: 2026-04-27
> **Sprint Source**: Sprint-005 / BOND-001

## Goal

Create the smallest implementation slice of the designed bond system that can support Ch.3 special dialogue and future base tavern interactions without implementing the full relationship network, combo skills, or visual effects.

## Scope Boundary

This epic is readiness only. Sprint-005 does not implement bond runtime logic.

## Stories

| ID | Title | Type | Est. | Dependencies | Status |
|---|---|---|---|---|---|
| BOND-001 | Bond data model + save payload | Logic | 0.5d | SaveData / `design/gdd/bond-system.md` | Ready |
| BOND-002 | Affinity gain event hooks | Integration | 0.5d | GameEvents / battle settlement | Ready |
| BOND-003 | Base tavern dialogue trigger MVP | UI/Integration | 0.5d | Base full phase 1 | Ready |
| BOND-004 | Character detail bond summary | UI | 0.25d | Character management UI | Ready |

## MVP Acceptance Criteria

- Bond pairs persist across save/load.
- Affinity can increase from at least one combat or camp event.
- Ch.3 dialogue can query whether a pair meets a threshold.
- Character management can display a compact bond summary.
- No full combo-skill implementation is required for MVP.

## Out of Scope

- S-rank romance content
- Full relationship network graph
- Combination skill animations
- Route-exclusive bond events beyond Ch.3 placeholders

## Sprint-006 Handoff

Start with BOND-001 and BOND-002 if Ch.3 GDD requires character-pair conditions. Delay BOND-003 until Base full phase 1 defines tavern UI ownership.
