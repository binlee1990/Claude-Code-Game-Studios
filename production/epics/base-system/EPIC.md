# Epic: Base System Phase 1

> **Layer**: Feature
> **GDD**: `design/gdd/base-system.md`
> **Status**: Sprint-007 Phase 1 Complete
> **Created**: 2026-04-27
> **Sprint Source**: Sprint-006 / Base Phase 1

## Goal

Turn the Sprint-004 Base MVP into the first bounded "base full" slice: action points for pacing, an Intel Room read-only briefing, and Sprint-007 player-facing Tavern/Upgrade extensions.

## Scope Boundary

Sprint-006 included Action Points and Intel Room only. Sprint-007 adds Tavern and Base Upgrade UI. World map, base visual upgrades, and release sign-off remain out of scope.

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
| BASE-TAVERN-001 | Base Tavern tab | UI + Integration | Must Have | Complete |
| BASE-UPGRADE-001 | Base Upgrade tab | Logic + UI + Config/Data | Must Have | Complete |

## MVP Acceptance Criteria

- Action points reset per chapter and persist through save/load.
- Training consumes AP; market remains AP-free.
- Base UI displays the current AP value.
- Intel Room can show current chapter briefing and next battle preview without consuming AP.
- Tavern tab can list available conversations when unlocked.
- Upgrade tab consumes the data-owned base upgrade cost table and persists level/unlocks.

## Out of Scope

- Full world map exploration
- Base visual upgrade stages

## Next Step

Sprint-007 delivered Tavern + Upgrade with `tests/unit/base/base_upgrade_model_test.gd` and `tests/integration/ui/base_hub_test.gd` coverage.
