# ADR-009: Equipment Upgrade Scope

> **Status**: Draft
> **Date**: 2026-04-27
> **Author**: technical-planner
> **Systems Affected**: Equipment System, Resource Economy, Character Management, Base

---

## Context

The equipment system already supports enhancement, affixes, decomposition, set bonuses, final attribute calculation, and save/load. Sprint-004 exposed equipment viewing and swapping, but full enhancement / enchant / decomposition UI was explicitly deferred.

---

## Decision

For Sprint-006+, equipment upgrade work should enter in this order:

1. **Enhancement MVP**: expose existing enhancement logic for equipped items only.
2. **Cost clarity**: source cost from resource economy constants, not UI literals.
3. **Failure states**: show insufficient gold/material/protection-symbol feedback before mutation.
4. **Persistence**: verify enhanced item state survives save/load.

Affix rerolling, decomposition UI, set crafting, and sockets remain outside the first upgrade slice.

---

## Consequences

### Positive

- Reuses implemented equipment logic without opening every designed feature.
- Gives players a clear Ch.3 preparation sink.
- Keeps UI blast radius small by starting from equipped items.

### Negative

- Inventory-wide equipment management remains incomplete.
- Balance depends on ADR-008 resource tuning.

---

## Rejected Alternatives

- **Implement full forge UI immediately**: rejected because enhancement, affix, decomposition, and set systems would exceed one sprint.
- **Leave enhancement hidden indefinitely**: rejected because Ch.2 feedback identified missing cultivation/preparation as a pain point.

---

## Verification Required

- Unit tests for enhancement cost and result remain green.
- UI test equips or enhances a deterministic item.
- Save/load integration confirms enhancement level persists.
