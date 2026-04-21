# Story 004: Resource Consumption & Costs

> **Epic**: Resource Economy
> **Status**: Ready
> **Layer**: Core
> **Type**: Logic
> **Manifest Version**: N/A — manifest not yet created

> **Estimate**: 2-3 hours

## Context

**GDD**: `design/gdd/resource-economy.md`
**Requirement**: AC.3.1-3.4 (consumption), AC.5.1-5.4 (barrier resource)

**ADR Governing Implementation**: ADR-001 (Event Architecture)
**Engine**: Godot 4.6.2 | **Risk**: LOW

---

## Acceptance Criteria

- [ ] AC.3.1: Equipment purchase deducts gold correctly; insufficient gold disables purchase
- [ ] AC.3.2: Enhancement cost: gold = base_cost * (current_level + 1), materials = 5 * target_level (formula D.4)
- [ ] AC.3.3: Fruit consumption: deducts 1 fruit, triggers attribute system potential upgrade
- [ ] AC.3.4: Protection symbol: deducts 1 on enhancement failure to prevent downgrade
- [ ] AC.5.1-5.2: Barrier breakthrough consumes 1 barrier resource; insufficient shows warning
- [ ] AC.5.3-5.4: Breakthrough success removes attribute cap; failure when no resource

---

## Implementation Notes

From GDD D.4: Enhancement cost formula. All consumption operations should be atomic — either full deduction succeeds or nothing happens. Insufficient resources should prevent the action, not partially consume.

---

## Out of Scope

- Story 005: Enhancement success/failure probability (this story handles cost calculation only)
- UI for purchase/enhancement confirmation

---

## QA Test Cases

- **AC.3.1**: Purchase with sufficient gold
  - Given: Player gold=500, item costs 200
  - When: Purchase executes
  - Then: Gold = 300, item acquired

- **AC.3.1**: Insufficient gold
  - Given: Player gold=100, item costs 200
  - When: Purchase attempted
  - Then: Gold unchanged, purchase rejected

- **AC.3.2**: Enhancement cost +4 to +5
  - Given: Equipment at +4, base_cost=100
  - When: Enhancement cost calculated
  - Then: gold = 100*(4+1)=500, materials = 5*5=25

- **AC.3.3**: Fruit consumption
  - Given: 3 STR fruits, character STR P=D(2), V=30
  - When: Consume 1 STR fruit
  - Then: Fruits = 2, attribute system triggered for STR potential upgrade

- **AC.5.2**: Barrier resource consumed on breakthrough
  - Given: 1 barrier resource, character attribute at threshold
  - When: Breakthrough triggered
  - Then: Barrier resources = 0, breakthrough proceeds

---

## Test Evidence

**Story Type**: Logic
**Required evidence**: `tests/unit/resource/consumption_costs_test.gd`
**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: Story 001 (inventory), attribute-system Epic (fruit effect, barrier breakthrough)
- Unlocks: Story 005 (enhancement uses consumption logic)
