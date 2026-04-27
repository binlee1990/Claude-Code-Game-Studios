# Epic: Base System Phase 1

> **Layer**: Feature
> **GDD**: `design/gdd/base-system.md`
> **Status**: Complete
> **Created**: 2026-04-27
> **Sprint Source**: Sprint-006 / Base Phase 1

## Goal

Turn the Sprint-004 Base MVP into the first bounded "base full" slice: action points for pacing and an Intel Room read-only briefing. This epic container exists so Sprint-006 story files have a stable parent path.

## Scope Boundary

Sprint-006 includes Action Points and Intel Room only. Tavern, base upgrade UI, world map, base visual upgrades, and release sign-off remain out of scope.

## Governing References

| Source | Relevance |
|---|---|
| `design/gdd/base-system.md` | Action point rules, function areas, UI requirements |
| `docs/active/base-full-readiness-brief.md` | Sprint-006 slice order |
| ADR-003 | Save/load persistence |
| ADR-008 | Market remains AP-free; progression sinks are data-driven |

## Stories

| ID | Title | Type | Priority | Status |
|---|---|---|---|---|
| BASE-AP-001 | Action Point model + save | Logic + Integration + UI | Must Have | Complete |
| BASE-INTEL-001 | Intel Room read-only briefing | UI + Config/Data | Should Have | Complete |

## MVP Acceptance Criteria

- Action points reset per chapter and persist through save/load.
- Training consumes AP; market remains AP-free.
- Base UI displays the current AP value.
- Intel Room can show current chapter briefing and next battle preview without consuming AP.

## Out of Scope

- Tavern and Bond dialogue execution
- Base upgrade UI and upgrade purchase flow
- Full world map exploration
- Base visual upgrade stages

## Next Step

Sprint-007 can add Tavern and Base Upgrade UI on top of `ActionPoints` and the read-only Intel tab.
