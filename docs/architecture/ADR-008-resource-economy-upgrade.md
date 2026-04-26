# ADR-008: Resource Economy Upgrade Scope

> **Status**: Draft
> **Date**: 2026-04-27
> **Author**: technical-planner
> **Systems Affected**: Resource Economy, Base, Market, Equipment Upgrade

---

## Context

Sprint-004 added a Base MVP with market buy/sell and training. The current economy is functional but shallow: gold and basic materials flow through rewards and market interactions, while future base upgrades, equipment enhancement, and Ch.3 tuning need a clearer ownership boundary.

---

## Decision

For Sprint-006+, resource economy upgrades should be split into three layers:

1. **Wallet and inventory correctness**: preserve current `Inventory` ownership for resource amounts.
2. **Price and reward tuning**: keep buy/sell prices and battle reward multipliers data-driven, reviewed per chapter.
3. **Progression sinks**: introduce base upgrades and equipment enhancement costs only after the relevant UI scope is accepted.

The market should remain usable without action-point cost. Training and tavern interactions may consume action points.

---

## Consequences

### Positive

- Prevents market tuning from being mixed with base progression implementation.
- Keeps Sprint-004 market MVP stable while Ch.3 economy is planned.
- Gives ADR-009 a clean dependency for enhancement costs.

### Negative

- Economy balance remains approximate until Ch.3 playtest data exists.
- Action-point costs cannot be finalized until Base full phase 1 is accepted.

---

## Rejected Alternatives

- **Implement all economy sinks immediately**: rejected because Base full and equipment upgrade UI are not ready.
- **Keep all prices hardcoded in UI**: rejected because Ch.3 tuning needs data ownership outside presentation code.

---

## Verification Required

- Market buy/sell regression tests continue passing.
- Future base upgrade tests verify exact resource consumption.
- Future equipment enhancement tests verify cost source and failure messaging.
