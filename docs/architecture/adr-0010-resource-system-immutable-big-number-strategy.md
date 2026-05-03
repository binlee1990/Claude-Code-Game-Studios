# ADR-0010: ResourceSystem 不可变 BigNumber 策略

## Status
Accepted

## Date
2026-05-04

## Engine Compatibility

| Field | Value |
|-------|-------|
| **Engine** | Godot 4.6.2 |
| **Domain** | Core / GDScript |
| **Knowledge Risk** | LOW — pure data/service logic |
| **References Consulted** | `design/gdd/resource-system.md`, `design/gdd/big-number-system.md`, `design/gdd/event-bus.md`, `design/gdd/save-system.md` |
| **Post-Cutoff APIs Used** | None |
| **Verification Required** | CRUD, caps, overflow, event order, snapshot/restore, batch_add non-atomic semantics, and BigNumber immutability tests |

## ADR Dependencies

| Field | Value |
|-------|-------|
| **Depends On** | ADR-0001, ADR-0002, ADR-0005, ADR-0006 |
| **Enables** | ADR-0011, ADR-0012, ADR-0015 |
| **Blocks** | ResourceSystem implementation and all systems that grant/spend resources |
| **Ordering Note** | ResourceSystem initializes after DataConfig and before systems that write resources |

## Context

### Problem Statement

ResourceSystem owns mutable resource balances while BigNumber values themselves are immutable. The architecture must define how values are changed, capped, emitted, and serialized without leaking mutable numeric references.

### Constraints

- ResourceSystem only owns resource ID → value CRUD and events.
- It must not contain production logic, multiplier math, or business rules.
- `batch_add` is non-atomic by design.
- All resource values use BigNumber.

### Requirements

- Use BigNumber-returning arithmetic and replace stored values.
- Enforce caps and overflow reporting.
- Emit events only when actual values change, with explicit overflow exceptions.
- Snapshot/restore with BigNumber dictionaries.

## Decision

ResourceSystem stores BigNumber values as immutable value objects. Operations calculate new BigNumber instances and replace the stored value. `add()` returns the actual added amount. `spend()` is atomic per resource. `batch_add()` executes sequential per-resource adds and returns a dictionary of actual additions; it does not roll back earlier successful changes.

### Architecture Diagram

```text
ResourceSystem entry {current: BigNumber, cap: BigNumber, has_cap}
      |
      +-- add(amount) -> current.add(amount) -> cap clamp -> replace current
      +-- spend(amount) -> compare -> replace current or reject
      +-- snapshot() -> BigNumber.to_dict()
```

### Key Interfaces

```gdscript
func register(definition: Dictionary) -> bool
func add(resource_id: String, amount: BigNumber) -> BigNumber
func spend(resource_id: String, amount: BigNumber) -> bool
func get_value(resource_id: String) -> BigNumber
func set_max(resource_id: String, cap: BigNumber) -> bool
func batch_add(changes: Dictionary) -> Dictionary
func snapshot() -> Dictionary
func restore(data: Dictionary) -> void
```

## Implementation Guidelines

- Must store resource values as `BigNumber`.
- Must replace stored values with newly calculated BigNumber instances.
- Must not mutate BigNumber instances in place.
- Must keep ResourceSystem limited to resource CRUD, caps, reset, events, and snapshot/restore.
- Must not include production, multiplier, loot, level, or economy business logic.
- Must emit `resource.{id}.changed` only when actual value changes.
- Must emit `resource.{id}.overflow` when attempted addition is capped or fully lost.
- Must preserve `batch_add` as sequential and non-atomic.

## Alternatives Considered

### Alternative 1: Mutable BigNumber in place
- **Description**: ResourceSystem mutates mantissa/exponent fields directly.
- **Pros**: Less allocation.
- **Cons**: Aliasing bugs when other systems hold references.
- **Rejection Reason**: Violates BigNumber value semantics and makes event old/new payloads unsafe.

### Alternative 2: ResourceSystem owns production and multipliers
- **Description**: Combine resource balances, production rates, and modifiers in one service.
- **Pros**: Fewer classes.
- **Cons**: Creates the God Object risk already flagged by TD-SYSTEM-BOUNDARY.
- **Rejection Reason**: Production belongs to OutputMultiplier/AutoProduction systems.

## Consequences

### Positive
- Resource ownership stays narrow.
- Old/new event payloads are stable snapshots.
- Save/load serialization is straightforward.

### Negative
- More object allocations than mutable values.
- Callers must inspect actual added amount for capped resources.

### Risks
- High-frequency resource changes may need batching/coalesced UI updates.
- Non-atomic batch semantics must be clear to future transaction-like features.

## GDD Requirements Addressed

| GDD System | Requirement | How This ADR Addresses It |
|------------|-------------|--------------------------|
| `resource-system.md` | ResourceSystem exposes pure CRUD + event interface and owns no production logic | Narrows scope and forbids business logic |
| `resource-system.md` | `add` clamps caps and reports actual added / overflow | Defines immutable replacement and return semantics |
| `big-number-system.md` | BigNumber arithmetic returns new instances | Carries value semantics into ResourceSystem |
| `save-system.md` | ResourceSystem registers snapshot/restore data | Defines snapshot serialization path |

## Performance Implications

- **CPU**: Single add/spend budget under 0.333 ms for hot MVP paths; batch of 5 resources under 0.15 ms.
- **Memory**: MVP 5 resources should remain under 2 KB excluding event payloads.
- **Load Time**: Config-based registration at startup.
- **Network**: None for MVP.

## Migration Plan

No existing implementation. Build ResourceSystem only after BigNumber, EventBus, DataConfig, and SaveManager contracts are available.

## Validation Criteria

- Tests cover register, add, cap clamp, uncapped add, spend reject, set_max event order, reset scopes, snapshot/restore, invalid IDs, zero-amount no-op, overflow behavior, and non-atomic batch_add.

## Related Decisions

- ADR-0001: BigNumber 实现策略
- ADR-0002: 事件总线架构

