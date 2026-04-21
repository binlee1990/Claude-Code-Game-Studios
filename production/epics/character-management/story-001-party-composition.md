# Story 001: Party Composition

> **Epic**: Character Management
> **Status**: Ready
> **Layer**: Feature
> **Type**: Logic
> **Manifest Version**: N/A — manifest not yet created

> **Estimate**: 2-3 hours

## Context

**GDD**: `design/gdd/character-management.md`
**Requirement**: AC.1.1-1.3 (party size, reserve roster, adjustment)

**ADR Governing Implementation**: ADR-001 (Event Architecture)
**Engine**: Godot 4.6.2 | **Risk**: LOW

---

## Acceptance Criteria

- [ ] AC.1.1: Player selects up to 4 characters from available roster for battle deployment
- [ ] AC.1.2: Characters not selected remain in reserve (retain all stats and equipment)
- [ ] AC.1.3: Party composition adjustable outside battle at any time

---

## Implementation Notes

From GDD C.1: Max deployment = 4. Total roster = 6-8 characters (MVP fixed at 6). Reserve characters keep all attributes, equipment, skills. Deployment selection produces an ordered party list used by turn-based mode. Party composition changes emit events for downstream systems.

---

## Out of Scope

- Departure/recall mechanics (Story 002)
- Party selection UI
- In-battle party changes

---

## QA Test Cases

- **AC.1.1**: Max deployment limit
  - Given: 6 available characters
  - When: Selecting 5 characters for deployment
  - Then: Rejected — max 4 allowed
  - Edge cases: Selecting exactly 4 → accepted; selecting 1 → accepted (minimum not enforced)

- **AC.1.2**: Reserve preservation
  - Given: Character A deployed, Character B in reserve
  - When: Check reserve character stats
  - Then: Character B retains all attributes, equipment, skills unchanged
  - Edge cases: Swap A and B → both keep their data

- **AC.1.3**: Out-of-battle adjustment
  - Given: Current party [A, B, C, D]
  - When: Player swaps B for E
  - Then: New party = [A, E, C, D], B returns to reserve
  - Edge cases: Attempting change mid-battle → blocked

---

## Test Evidence

**Story Type**: Logic
**Required evidence**: `tests/unit/character/party_composition_test.gd`
**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: None (standalone logic)
- Unlocks: Story 002 (departure affects roster), Story 003 (save/load)
