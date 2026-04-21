# Story 006: Crush Mechanic

> **Epic**: Attribute & Growth System
> **Status**: Complete
> **Layer**: Core
> **Type**: Logic
> **Manifest Version**: N/A — manifest not yet created

> **Estimate**: 2-3 hours

## Context

**GDD**: `design/gdd/attribute-growth-system.md`
**Requirement**: AC-11 (crush trigger), AC-12 (no crush), AC-13 (no healing crush)

**ADR Governing Implementation**: ADR-001: Event Architecture
**ADR Decision Summary**: Crush evaluation is a read-only operation called by combat system. Results returned via function, not signal.

**Engine**: Godot 4.6.2 | **Risk**: LOW

---

## Acceptance Criteria

- [ ] AC-11.1: `evaluate_crush(attacker_id, defender_id, attribute_name) -> CrushResult` returns crush when |Δv| > 30
- [ ] AC-11.2: CrushResult contains: is_crushed=TRUE, damage_multiplier=1.5, defense_multiplier=0.8, direction (attacker or defender crushes)
- [ ] AC-12.1: When |Δv| <= 30, CrushResult returns is_crushed=FALSE, multipliers=1.0
- [ ] AC-13.1: CrushResult has a field `applicable: bool` — FALSE for non-damage actions (healing, buffs)

---

## Implementation Notes

From GDD C.6 and D.4:
- Crush checks only the relevant attribute axis for the attack type
- If multiple axes qualify, take the highest — no stacking
- Crush direction matters: attacker crushes defender OR defender crushes attacker
- This is a READ-ONLY function — it evaluates and returns result, does not modify state
- Combat system is responsible for applying the multipliers

---

## Out of Scope

- Combat system integration (applying crush multipliers to damage)
- Visual effects of crush (VFX/UI epic)
- Multi-axis crush resolution (future enhancement)

---

## QA Test Cases

- **AC-11.1**: Crush triggers when gap > 30
  - Given: Attacker STR=80, Defender STR=45
  - When: evaluate_crush called with "STR"
  - Then: is_crushed=TRUE, damage_multiplier=1.5, defense_multiplier=0.8
  - Edge cases: |Δv|=31 triggers; |Δv|=30 does NOT trigger

- **AC-11.2**: Crush direction
  - Given: Attacker STR=45, Defender STR=80
  - When: evaluate_crush called with "STR"
  - Then: is_crushed=TRUE, direction=defender_crushes_attacker
  - Edge cases: Defender's crush affects the attacker's defense

- **AC-12.1**: No crush when gap <= 30
  - Given: Attacker AGI=60, Defender AGI=35
  - When: evaluate_crush called with "AGI"
  - Then: is_crushed=FALSE, damage_multiplier=1.0, defense_multiplier=1.0
  - Edge cases: |Δv|=30 exactly — no crush (strict >)

- **AC-13.1**: Not applicable for healing
  - Given: Any attacker/defender with large attribute gap
  - When: Action type is "heal" or "buff"
  - Then: applicable=FALSE regardless of attribute values

---

## Test Evidence

**Story Type**: Logic
**Required evidence**: `tests/unit/attributes/crush_mechanic_test.gd` — must exist and pass
**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: Story 001 (data model — reads attribute values)
- Unlocks: Combat system can consume evaluate_crush results

## Completion Notes

**Completed**: 2026-04-22
**Criteria**: 4/4 passing (all auto-verified)
**Deviations**: ADVISORY — Returns Dictionary instead of typed CrushResult. Contains all required fields.
**Test Evidence**: Logic — `tests/unit/attributes/crush_mechanic_test.gd` (11 test functions)
**Code Review**: Skipped (Solo mode)
