# ADR-0014: NumberFormatter 缩写映射策略

## Status
Accepted

## Date
2026-05-04

## Engine Compatibility

| Field | Value |
|-------|-------|
| **Engine** | Godot 4.6.2 |
| **Domain** | Presentation / GDScript |
| **Knowledge Risk** | LOW — pure string formatting and BigNumber consumption |
| **References Consulted** | `design/gdd/number-formatting-system.md`, `design/gdd/big-number-system.md`, `.claude/docs/technical-preferences.md` |
| **Post-Cutoff APIs Used** | None |
| **Verification Required** | Unit thresholds, rounding across unit boundaries, MAX/ZERO/NaN formatting, and 1000-format performance budget |

## ADR Dependencies

| Field | Value |
|-------|-------|
| **Depends On** | ADR-0001 |
| **Enables** | ADR-0011, ADR-0012 |
| **Blocks** | HUD/resource display implementation |
| **Ordering Note** | Implement before UI/HUD screens that display BigNumber values |

## Context

### Problem Statement

BigNumber values must be readable in a Chinese idle RPG UI. The formatter needs stable unit thresholds and rounding semantics before HUD and DebugConsole render numeric state.

### Constraints

- MVP can use a hard-coded Chinese unit table.
- UI must not implement its own BigNumber formatting.
- Values beyond the Chinese unit table switch to scientific notation.

### Requirements

- Direct display under `10^4`.
- Chinese units from `万` through `极` for `10^4` to `10^48`.
- Scientific notation above `10^48`.
- Stable rounding and MAX/ZERO handling.

## Decision

Implement `NumberFormatter` as a utility service with a hard-coded MVP Chinese unit table: `万, 亿, 兆, 京, 垓, 秭, 穰, 沟, 涧, 正, 载, 极`. Values above `10^48` use scientific notation. This table stays code-owned for MVP; DataConfig-driven formatting can be revisited Post-MVP if localization or content scale requires it.

### Architecture Diagram

```text
BigNumber {m,e}
   |
   +-- e < 4       -> direct number
   +-- 4 <= e <=48 -> Chinese unit table
   +-- e > 48      -> scientific notation
```

### Key Interfaces

```gdscript
static func format(value: BigNumber) -> String
static func format_short(value: BigNumber) -> String
static func format_scientific(value: BigNumber) -> String
static func get_display_unit(value: BigNumber) -> String
```

## Implementation Guidelines

- Must route all player-facing BigNumber display through NumberFormatter.
- Must use the MVP hard-coded Chinese unit table.
- Must switch to scientific notation above `10^48`.
- Must return `"0"` for zero/invalid BigNumber values.
- Must return `"MAX"` for BigNumber.MAX.
- Must handle rounding across unit thresholds.
- Must not let UI/HUD/DebugConsole implement duplicate BigNumber formatting.

## Alternatives Considered

### Alternative 1: DataConfig-driven unit table for MVP
- **Description**: Load number abbreviations from JSON.
- **Pros**: Easier localization and tuning.
- **Cons**: Extra data dependency for a stable small table.
- **Rejection Reason**: MVP unit table is fixed and simple.

### Alternative 2: Scientific notation only
- **Description**: Display every large value as `1.23eN`.
- **Pros**: Easy and universal.
- **Cons**: Worse thematic fit for Chinese cultivation fantasy.
- **Rejection Reason**: GDD requires Chinese unit progression through `极`.

## Consequences

### Positive
- Numeric display is consistent across HUD, debug, and UI.
- Hard-coded MVP table avoids data load ordering issues.
- Thematic Chinese units support player fantasy.

### Negative
- Localization of unit names requires code changes until Post-MVP.
- The table must be kept in sync with design copy if terms change.

### Risks
- Rounding across boundaries can produce wrong unit jumps if not tested.
- UI can drift if developers bypass NumberFormatter.

## GDD Requirements Addressed

| GDD System | Requirement | How This ADR Addresses It |
|------------|-------------|--------------------------|
| `number-formatting-system.md` | Direct, Chinese-unit, and scientific notation thresholds | Defines thresholds and MVP unit table |
| `hud-system.md` | HUD resource values use NumberFormattingSystem | Makes formatter mandatory for HUD display |
| `debug-console.md` | Debug resource output uses formatted BigNumber values | Prevents debug-specific formatting drift |

## Performance Implications

- **CPU**: 1000 formatting calls should stay under 1 ms.
- **Memory**: Static table only.
- **Load Time**: None.
- **Network**: None.

## Migration Plan

Use hard-coded MVP table. Consider DataConfig-driven table only when localization or Post-MVP content requires it.

## Validation Criteria

- Tests cover zero, direct numbers, every unit boundary, rounding across boundaries, scientific fallback, `MAX`, NaN/invalid input, and 1000-call performance budget.

## Related Decisions

- ADR-0001: BigNumber 实现策略
- ADR-0011: UI 屏幕管理架构

