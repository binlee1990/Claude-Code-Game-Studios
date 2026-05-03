# ADR-0007: 修正器叠加顺序

## Status
Accepted

## Date
2026-05-04

## Engine Compatibility

| Field | Value |
|-------|-------|
| **Engine** | Godot 4.6.2 |
| **Domain** | Core / GDScript |
| **Knowledge Risk** | LOW — pure GDScript data processing; no post-cutoff engine API dependency |
| **References Consulted** | `docs/engine-reference/godot/VERSION.md`, `design/gdd/modifier-engine.md`, `design/gdd/output-multiplier-system.md`, `design/gdd/attribute-system.md` |
| **Post-Cutoff APIs Used** | None |
| **Verification Required** | Stacking-order tests, target naming tests, cache invalidation tests, and expired modifier event tests |

## ADR Dependencies

| Field | Value |
|-------|-------|
| **Depends On** | ADR-0001, ADR-0002 |
| **Enables** | ADR-0009, ADR-0010, ADR-0013 |
| **Blocks** | Attribute final values, production multipliers, combat stat calculation |
| **Ordering Note** | Implement after BigNumber and EventBus, before AttributeSystem, OutputMultiplierSystem, and CombatCalculator |

## Context

### Problem Statement

Growth, equipment, realm, zone, buff, and combat systems all need the same stacking semantics. If each feature implements its own multiplier order, balance becomes impossible to reason about.

### Constraints

- Attribute and production systems use shared target strings.
- Conditions are owned by source systems, not ModifierEngine.
- Target results must be cached for hot paths.

### Requirements

- Apply flat ADD modifiers first.
- Apply same-pool percentage modifiers additively into one pool multiplier.
- Multiply independent pools together.
- Support duration expiry and source-based unregister.

## Decision

Use one `ModifierEngine` service with a three-stage pipeline: `base + add_sum`, then same-pool additive percentage multipliers, then cross-pool multiplication. MVP pools are `equipment`, `realm`, `zone`, and `buff`. Targets are strings such as `player.atk` and `lingqi_production`.

### Architecture Diagram

```text
base BigNumber
   + ADD sum
   * pool(equipment: 1 + sum)
   * pool(realm: 1 + sum)
   * pool(zone: 1 + sum)
   * pool(buff: 1 + sum)
   = final BigNumber
```

### Key Interfaces

```gdscript
func register(data: Dictionary) -> String
func unregister(id: String) -> bool
func unregister_by_source(source_id: String) -> int
func get_add_sum(target: String) -> float
func get_pool_multiplier(target: String, pool: String) -> float
func get_multiplier(target: String) -> float
func apply(target: String, base_value: BigNumber) -> BigNumber
func get_breakdown(target: String) -> Dictionary
```

## Implementation Guidelines

- Must apply modifiers in the order ADD, same-pool additive MULT, cross-pool multiplicative MULT.
- Must use `"{entity_id}.{attr_id}"` for attribute targets.
- Must use `"{resource_id}_production"` for production targets.
- Must cache clean target multiplier results and invalidate on register/unregister/expiry.
- Must emit `modifier_expired` when duration-based modifiers expire.
- Must not evaluate business-specific conditions in ModifierEngine.
- Must not multiply modifiers inside the same pool individually.

## Alternatives Considered

### Alternative 1: All multipliers multiply independently
- **Description**: `1.1 × 1.1 × 1.1` for three +10% bonuses.
- **Pros**: Simple math.
- **Cons**: Over-amplifies same-source stacking and conflicts with OutputMultiplier GDD.
- **Rejection Reason**: Same-pool additivity is required.

### Alternative 2: Each system owns its own modifiers
- **Description**: Attribute, production, and combat systems each implement stacking.
- **Pros**: Local specialization.
- **Cons**: Balance rules diverge.
- **Rejection Reason**: One shared pipeline is the only maintainable MVP baseline.

## Consequences

### Positive
- Designers can reason about pools consistently.
- Attribute and production consumers share breakdown/debug tooling.
- Cache makes hot queries cheap.

### Negative
- Target naming becomes a cross-system contract.
- Source systems must manage condition activation/deactivation.

### Risks
- Wrong target names create silent missing modifiers.
- Cache invalidation bugs can create stale combat or production values.

## GDD Requirements Addressed

| GDD System | Requirement | How This ADR Addresses It |
|------------|-------------|--------------------------|
| `modifier-engine.md` | Three-stage stacking pipeline with pool semantics | Establishes the canonical stacking order |
| `attribute-system.md` | Attribute final values use `"{entity_id}.{attr_id}"` targets | Defines target naming convention |
| `output-multiplier-system.md` | Production uses `"{resource_id}_production"` and shared pools | Reuses modifier pools for production rates |

## Performance Implications

- **CPU**: Cached `get_multiplier()` hot path target is under 1 ms for 1000 calls.
- **Memory**: Modifier registry and target cache are proportional to active modifier count.
- **Load Time**: Minimal.
- **Network**: None for MVP.

## Migration Plan

No existing implementation. Implement target naming tests alongside AttributeSystem and OutputMultiplierSystem.

## Validation Criteria

- Tests cover ADD sum, same-pool additivity, cross-pool multiplication, `apply`, unregister, source unregister, duration expiry, invalid values, cache hits, and breakdown output.

## Related Decisions

- ADR-0010: ResourceSystem 不可变 BigNumber 策略
- ADR-0013: FormulaEngine 表达式 DSL 深度

