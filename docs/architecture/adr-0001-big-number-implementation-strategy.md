# ADR-0001: BigNumber 实现策略

## Status
Accepted

## Date
2026-05-04

## Engine Compatibility

| Field | Value |
|-------|-------|
| **Engine** | Godot 4.6.2 |
| **Domain** | Core / GDScript |
| **Knowledge Risk** | HIGH — Godot 4.5/4.6 post-cutoff language/runtime changes exist, but this ADR uses conservative GDScript 4.x features only |
| **References Consulted** | `docs/engine-reference/godot/VERSION.md`, `docs/engine-reference/godot/current-best-practices.md`, `docs/engine-reference/godot/deprecated-apis.md`, `design/gdd/big-number-system.md` |
| **Post-Cutoff APIs Used** | None |
| **Verification Required** | GDUnit arithmetic/serialization tests plus a performance prototype for 1000 instances × 50 arithmetic ops under 16.6 ms |

## ADR Dependencies

| Field | Value |
|-------|-------|
| **Depends On** | None |
| **Enables** | ADR-0005, ADR-0007, ADR-0010, ADR-0013, ADR-0014 |
| **Blocks** | Foundation and Core data implementation until Accepted |
| **Ordering Note** | Implement before every system that stores resources, attributes, damage, experience, or rewards |

## Context

### Problem Statement

The game needs values from small integers through at least `1e300+`. Native `int` and `float` cannot represent late-game idle RPG quantities with stable comparison, serialization, and display semantics.

### Constraints

- All game quantities representing absolute values must share one numeric abstraction.
- MVP must remain simple enough to implement and test in GDScript.
- GDExtension/C++ must remain an upgrade path, not the first implementation.
- BigNumber represents non-negative absolute quantities; ratios and percentages stay as `float`.

### Requirements

- Support mantissa/exponent representation, saturated arithmetic, comparison, powers, log10, and JSON-compatible dictionary serialization.
- Arithmetic methods return new instances and do not mutate operands.
- Invalid input must degrade to `ZERO` or `MAX`, not crash runtime logic.

## Decision

Implement `BigNumber` as an immutable `RefCounted` GDScript value type using `mantissa: float` and `exponent: int`. Normalized non-zero values keep `mantissa` in `[1.0, 10.0)` and `exponent` in `[0, 308]`. Zero is `{0.0, 0}`. Overflow saturates to `MAX`; negative or sub-unit absolute results clamp to `ZERO`.

### Architecture Diagram

```text
GDD/config string -> BigNumber.from_string/from_dict
                         |
                         v
 ResourceSystem / AttributeSystem / Combat / Rewards
                         |
                         v
              NumberFormatter / SaveManager
```

### Key Interfaces

```gdscript
class_name BigNumber extends RefCounted
static func from_int(value: int) -> BigNumber
static func from_float(value: float) -> BigNumber
static func from_string(value: String) -> BigNumber
static func from_dict(data: Dictionary) -> BigNumber
func add(other: BigNumber) -> BigNumber
func subtract(other: BigNumber) -> BigNumber
func multiply(other: BigNumber) -> BigNumber
func multiply_float(value: float) -> BigNumber
func divide(other: BigNumber) -> BigNumber
func power(exponent: float) -> BigNumber
func log10() -> float
func compare(other: BigNumber) -> int
func to_dict() -> Dictionary
```

## Implementation Guidelines

- Must store game absolute quantities as `BigNumber`, not raw `int` or `float`.
- Must return a new `BigNumber` from every arithmetic method.
- Must serialize as `{"m": mantissa, "e": exponent}`.
- Must clamp negative results and sub-unit absolute results to `ZERO`.
- Must treat division by zero and overflow as saturated `MAX`.
- Must not introduce GDExtension until the GDScript performance gate fails with measured evidence.

## Alternatives Considered

### Alternative 1: Native int/float only
- **Description**: Use Godot numeric primitives everywhere.
- **Pros**: Simple, fast, no custom math.
- **Cons**: Cannot represent late-game values; precision fails beyond native limits.
- **Rejection Reason**: Violates the Big Number GDD and the player fantasy of uncapped numeric growth.

### Alternative 2: GDExtension/C++ first
- **Description**: Implement BigNumber in native code immediately.
- **Pros**: Higher performance ceiling.
- **Cons**: More setup complexity and cross-language testing before there is evidence GDScript is insufficient.
- **Rejection Reason**: Premature for MVP; retain only as a measured fallback.

## Consequences

### Positive
- One numeric model governs resources, attributes, combat values, and rewards.
- Save/load and formatting have stable dictionary/string inputs.
- GDScript implementation is inspectable and easy to test early.

### Negative
- Immutable arithmetic allocates more objects than in-place mutation.
- Sub-unit absolute values cannot be represented and must be handled as `float` ratios elsewhere.

### Risks
- Bulk offline simulation may exceed frame budget if arithmetic allocation is too high.
- Catastrophic cancellation remains possible when subtracting close large numbers.

## GDD Requirements Addressed

| GDD System | Requirement | How This ADR Addresses It |
|------------|-------------|--------------------------|
| `big-number-system.md` | Support values up to `1e300+` with mantissa/exponent math | Defines the canonical representation and clamp range |
| `big-number-system.md` | Operations must return immutable value results | Mandates new instances for arithmetic |
| `resource-system.md` / `attribute-system.md` | Resource and attribute values use BigNumber | Establishes BigNumber as the only absolute game quantity type |

## Performance Implications

- **CPU**: Target prototype gate is 1000 instances × 50 operations under one 16.6 ms frame.
- **Memory**: More allocation than mutable values; acceptable until profiling proves otherwise.
- **Load Time**: Minimal; values deserialize from dictionaries and strings.
- **Network**: None for MVP.

## Migration Plan

No existing game code migration. Implement BigNumber first, then downstream systems use it from their first commit.

## Validation Criteria

- GDUnit covers normalization, add/subtract/multiply/divide/power/log10, clamp behavior, string/dict conversion, invalid input, and MAX/ZERO constants.
- Performance prototype records whether GDScript passes the GDExtension decision gate.

## Related Decisions

- ADR-0010: ResourceSystem 不可变 BigNumber 策略
- ADR-0014: NumberFormatter 缩写映射策略

