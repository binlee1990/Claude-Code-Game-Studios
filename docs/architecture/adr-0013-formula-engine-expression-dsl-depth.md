# ADR-0013: FormulaEngine 表达式 DSL 深度

## Status
Accepted

## Date
2026-05-04

## Engine Compatibility

| Field | Value |
|-------|-------|
| **Engine** | Godot 4.6.2 |
| **Domain** | Core / GDScript |
| **Knowledge Risk** | LOW — pure parser/evaluator service; no post-cutoff engine API required |
| **References Consulted** | `design/gdd/formula-engine.md`, `design/gdd/data-config-system.md`, `design/gdd/random-seed-system.md`, `design/gdd/big-number-system.md` |
| **Post-Cutoff APIs Used** | None |
| **Verification Required** | Expression parser/evaluator tests, cache hit performance, invalid expression fallback, and formula hot reload invalidation |

## ADR Dependencies

| Field | Value |
|-------|-------|
| **Depends On** | ADR-0001, ADR-0004, ADR-0005 |
| **Enables** | ADR-0007, ADR-0009 |
| **Blocks** | FormulaEngine implementation and formula-driven balance systems |
| **Ordering Note** | FormulaEngine can start with built-in expressions and later read DataConfig formula definitions |

## Context

### Problem Statement

The game needs formulas for growth, damage, soft caps, production, and balancing. A full scripting DSL is unnecessary for MVP, but simple variable replacement is too weak for softcap and cache requirements.

### Constraints

- MVP formulas return `float`; BigNumber is used by callers for absolute values.
- No user-authored arbitrary GDScript execution.
- Long expressions and invalid math degrade safely.
- Formula definitions may come from DataConfig later.

### Requirements

- Support arithmetic, comparisons, conditionals, safe functions, and variable context.
- Support `softcap`, `log_softcap`, `clamp`, `floor`, and `lerp`.
- Cache parsed formulas and invalidate on hot reload.

## Decision

Implement a bounded expression evaluator, not a general-purpose DSL. It supports arithmetic, variables, selected safe functions, boolean-to-float comparisons, simple ternary-style conditionals where specified by GDD, and formula caching. The evaluator returns `float`; systems convert to/from BigNumber where appropriate.

### Architecture Diagram

```text
formula_id or raw expression
        |
        v
FormulaEngine parse/cache
        |
        v
evaluate(context Dictionary) -> float
```

### Key Interfaces

```gdscript
static func evaluate(formula_id: String, context: Dictionary) -> float
static func evaluate_raw(expression: String, context: Dictionary) -> float
static func invalidate(formula_id: String) -> void
static func invalidate_all() -> void
```

## Implementation Guidelines

- Must return `float` results from FormulaEngine.
- Must not execute arbitrary GDScript or external code.
- Must bound expression length and clamp invalid softcap parameters.
- Must return `0.0` with warnings for invalid expressions, divide-by-zero, NaN, or Inf.
- Must cache parsed formulas and expose invalidation.
- Must keep BigNumber absolute-value math in callers, not inside the formula DSL except through explicit conversions owned by callers.

## Alternatives Considered

### Alternative 1: Full custom DSL
- **Description**: Build a rich language for formulas, functions, and control flow.
- **Pros**: Highly expressive.
- **Cons**: Parser/security/testing scope explodes.
- **Rejection Reason**: MVP does not need a full language.

### Alternative 2: Hard-code all formulas
- **Description**: Implement every formula as GDScript functions.
- **Pros**: Type-safe and fast.
- **Cons**: Slower balance iteration and poor data-driven extensibility.
- **Rejection Reason**: Conflicts with data-driven design pillar.

## Consequences

### Positive
- Designers can tune formulas without new code for common cases.
- Runtime remains safer than arbitrary script execution.
- Cache supports high-frequency evaluation.

### Negative
- Feature requests outside the bounded function set require engine work.
- Debugging formula parse errors requires good diagnostics.

### Risks
- Over-expanding the evaluator can recreate a full DSL accidentally.
- Float return values must be carefully converted when callers need BigNumber.

## GDD Requirements Addressed

| GDD System | Requirement | How This ADR Addresses It |
|------------|-------------|--------------------------|
| `formula-engine.md` | Evaluate formulas with variables, safe functions, caching, and fallbacks | Defines bounded evaluator scope |
| `data-config-system.md` | Formula definitions can be read from JSON config | Allows formula IDs through DataConfig |
| `combat-calculator.md` | Damage formulas use shared FormulaEngine | Keeps combat formula execution centralized |

## Performance Implications

- **CPU**: Cache-hit target under 0.02 ms per evaluate and 50 formulas under 0.5 ms/frame.
- **Memory**: Cache holds parsed forms for active formulas.
- **Load Time**: Optional formula prewarm can occur after DataConfig load.
- **Network**: None.

## Migration Plan

Start with MVP safe function set. Add new functions only when a GDD requires them and tests define the math.

## Validation Criteria

- Tests cover arithmetic, variables, missing variables, invalid syntax, divide by zero, NaN/Inf fallback, comparisons, conditionals, softcap/log_softcap/clamp/floor/lerp, cache hits, invalidation, and expression length cap.

## Related Decisions

- ADR-0005: 数据配置加载策略
- ADR-0007: 修正器叠加顺序

