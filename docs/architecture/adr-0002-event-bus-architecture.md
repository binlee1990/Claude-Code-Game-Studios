# ADR-0002: 事件总线架构

## Status
Accepted

## Date
2026-05-04

## Engine Compatibility

| Field | Value |
|-------|-------|
| **Engine** | Godot 4.6.2 |
| **Domain** | Core / GDScript |
| **Knowledge Risk** | HIGH — Godot 4.5/4.6 are post-cutoff, but this ADR avoids new language features and deprecated connection syntax |
| **References Consulted** | `docs/engine-reference/godot/VERSION.md`, `docs/engine-reference/godot/deprecated-apis.md`, `design/gdd/event-bus.md` |
| **Post-Cutoff APIs Used** | None |
| **Verification Required** | Confirm Callable validity cleanup, Node lifecycle cleanup, recursion guard, and coalesced emission behavior in Godot 4.6.2 |

## ADR Dependencies

| Field | Value |
|-------|-------|
| **Depends On** | None |
| **Enables** | ADR-0003, ADR-0006, ADR-0007, ADR-0010, ADR-0011, ADR-0012 |
| **Blocks** | Cross-system UI, save, resource, time, debug, and progression communication |
| **Ordering Note** | EventBus must be the first Autoload in `project.godot` |

## Context

### Problem Statement

Thirty MVP systems need to publish state changes without direct references to every consumer. UI, HUD, save notifications, offline settlement, and debug logging all depend on consistent cross-system communication.

### Constraints

- Production systems must use exact event names, not debug prefix subscriptions.
- GDScript has no try/catch, so callback errors cannot be fully isolated.
- Event payloads must remain lightweight and JSON-friendly.

### Requirements

- Provide synchronous exact event subscription and emission.
- Provide prefix subscriptions only for DebugConsole tooling.
- Support one-shot subscriptions, lifecycle cleanup, recursion guard, and optional coalesced UI refresh events.

## Decision

Use a global `EventBus` Autoload Node with string event names and `Dictionary` payloads. The bus dispatches events synchronously in the current frame. Exact subscriptions are the production path. Prefix pattern subscriptions exist only for debug tooling such as `event watch resource`. Coalesced events are allowed only for display refreshes where latest-state wins.

### Architecture Diagram

```text
Producer System
  EventBus.emit("resource.lingqi.changed", payload)
        |
        +--> HUD exact subscription
        +--> UI notification subscription
        +--> DebugConsole prefix watch (debug only)
```

### Key Interfaces

```gdscript
func emit(event_name: String, payload: Dictionary = {}) -> void
func emit_coalesced(event_name: String, payload: Dictionary, coalesce_key: String = "") -> void
func subscribe(event_name: String, callable: Callable) -> void
func subscribe_once(event_name: String, callable: Callable) -> void
func unsubscribe(event_name: String, callable: Callable) -> void
func subscribe_pattern(prefix: String, callable: Callable) -> void
func unsubscribe_pattern(prefix: String, callable: Callable) -> void
```

## Implementation Guidelines

- Must define event names as constants; production code must not use untracked magic strings.
- Must use exact subscriptions for production UI and gameplay consumers.
- Must restrict `subscribe_pattern` to DebugConsole and similar diagnostics.
- Must reject empty prefix pattern subscriptions.
- Must validate `Callable.is_valid()` before delivery and remove invalid callables.
- Must defer subscribe/unsubscribe mutations until after current dispatch completes.
- Must not use deprecated string-based Godot `connect()` syntax.
- Must not coalesce business events that carry cumulative deltas, audit semantics, or save/loot transactions.

## Alternatives Considered

### Alternative 1: Direct system references
- **Description**: ResourceSystem directly calls HUD, SaveManager, and other systems.
- **Pros**: Simple call sites.
- **Cons**: Creates tight dependency graph and hard-to-test systems.
- **Rejection Reason**: Conflicts with systems-index dependency direction and EventBus GDD.

### Alternative 2: Strongly typed event classes
- **Description**: One class per event payload.
- **Pros**: Better refactor safety.
- **Cons**: Too much boilerplate for MVP and slower content iteration.
- **Rejection Reason**: Dictionary payloads are sufficient for MVP and align with GDD.

## Consequences

### Positive
- Cross-system communication remains decoupled.
- DebugConsole can observe event streams without changing production consumers.
- Coalesced UI refreshes protect HUD from high-frequency layout rebuilds.

### Negative
- Event name typos are not compile-time errors.
- Payload Dictionary schema discipline must be maintained by tests and docs.

### Risks
- Synchronous callbacks can create hidden execution cost.
- Callback runtime errors still surface through Godot logs rather than bus-level try/catch.

## GDD Requirements Addressed

| GDD System | Requirement | How This ADR Addresses It |
|------------|-------------|--------------------------|
| `event-bus.md` | Systems communicate through publish/subscribe instead of direct references | Establishes EventBus as the global communication mechanism |
| `hud-system.md` | HUD reacts to exact resource, level, combat, zone, and offline events | Requires exact production subscriptions |
| `debug-console.md` | `event watch` can observe prefixes for diagnostics | Keeps prefix subscription as debug-only behavior |

## Performance Implications

- **CPU**: EventBus frame budget target is 0.5 ms/frame under typical emit volumes.
- **Memory**: Subscription dictionaries and callables are small compared with game state.
- **Load Time**: None.
- **Network**: None for MVP.

## Migration Plan

No existing implementation. Add EventBus before dependent systems and route all cross-system notifications through it.

## Validation Criteria

- Tests cover exact subscribe/unsubscribe, subscribe_once, invalid callable cleanup, Node lifecycle cleanup, recursion guard, prefix watch, empty prefix rejection, and coalesced UI refresh.

## Related Decisions

- ADR-0008: Autoload 初始化顺序
- ADR-0011: UI 屏幕管理架构

