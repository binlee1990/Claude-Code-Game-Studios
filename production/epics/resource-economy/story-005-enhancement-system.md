# Story 005: Enhancement System

> **Epic**: Resource Economy
> **Status**: Ready
> **Layer**: Core
> **Type**: Logic
> **Manifest Version**: N/A — manifest not yet created

> **Estimate**: 2-3 hours

## Context

**GDD**: `design/gdd/resource-economy.md`
**Requirement**: AC.4.1-4.4 (enhancement success/failure)

**ADR Governing Implementation**: ADR-001 (Event Architecture)
**Engine**: Godot 4.6.2 | **Risk**: LOW

---

## Acceptance Criteria

- [ ] AC.4.1: Enhancement +1 to +5: 100% success rate (safe zone)
- [ ] AC.4.2: Enhancement +6 and above: failure probability applies (30% at +6, 50% at +10); failure causes downgrade by 5 levels
- [ ] AC.4.3: With protection symbol: failure does not downgrade, protection symbol consumed
- [ ] AC.4.4: On failure without protection: 50% of consumed materials returned

---

## Implementation Notes

From GDD C.3: Safe zone is +1 to +5. Risk zone starts at +6. Failure rate increases with level. Downgrade is fixed at 5 levels. Material return is 50% rounded down. Protection symbol is consumed BEFORE the outcome is determined (paid regardless of outcome).

---

## Out of Scope

- Equipment system (stat changes from enhancement)
- UI for enhancement result popup

---

## QA Test Cases

- **AC.4.1**: Safe zone success
  - Given: Equipment at +3
  - When: Enhancement attempted (+3 → +4)
  - Then: 100% success, equipment becomes +4

- **AC.4.2**: Risk zone failure
  - Given: Equipment at +7, no protection symbol, failure occurs
  - When: Enhancement fails
  - Then: Equipment becomes +2 (downgrade 5 levels)
  - Edge cases: +6 fails → +1; +10 fails → +5

- **AC.4.3**: Protection symbol saves equipment
  - Given: Equipment at +7, protection symbol available, failure occurs
  - When: Enhancement fails
  - Then: Equipment stays +7, protection symbol consumed (-1)

- **AC.4.4**: Material return on failure
  - Given: Enhancement consumed 50 materials, fails without protection
  - When: Failure processed
  - Then: 25 materials returned (50 * 0.5)

---

## Test Evidence

**Story Type**: Logic
**Required evidence**: `tests/unit/resource/enhancement_system_test.gd`
**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: Story 001 (inventory), Story 004 (consumption cost calculation)
- Unlocks: Equipment system can use enhancement results
