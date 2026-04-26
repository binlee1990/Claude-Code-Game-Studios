# Base Full Readiness Brief

> Date: 2026-04-27
> Sprint: 005 / BASE-FULL-001
> Status: Ready for Sprint-006+ Planning

## Current Baseline

Sprint-004 delivered Base MVP:

- Base hub route from main menu and settlement.
- Training tab for skill proficiency.
- Market tab for buy/sell.
- Management tab embedding character management.

## Proposed Base Full Phase 1

| Slice | Purpose | Recommended Timing |
|---|---|---|
| Action points | Gate training/tavern/chapter select choices | Before Ch.3 implementation if Ch.3 depends on base preparation |
| Tavern | Bond dialogue and relationship events | After Bond BOND-001/BOND-002 |
| Intel room | Chapter briefing, route tendency, next battle preview | Before Ch.3 finale |
| Base upgrades | Long-term resource sink | After ADR-008 is accepted |

## Constraints

- Market remains no-cost in action points.
- Existing training/market tests must keep passing.
- Base full work should not block Credits/localization release gates.

## Sprint-006 Candidate Order

1. Action point model + save/load.
2. Intel room read-only briefing.
3. Tavern placeholder route with Bond dialogue list.
4. Base upgrade costs after economy tuning.

## Risks

- Adding all base features at once will compete with Ch.3 content work.
- Bond tavern UI depends on Bond data model ownership.
- Resource sinks need balance data that human playtest has not supplied yet.
