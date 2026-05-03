# ADR-0008: Autoload 初始化顺序

## Status
Accepted

## Date
2026-05-04

## Engine Compatibility

| Field | Value |
|-------|-------|
| **Engine** | Godot 4.6.2 |
| **Domain** | Core / SceneTree / Autoload |
| **Knowledge Risk** | MEDIUM — Autoload lifecycle is stable, but all startup ordering must be manually verified in project settings |
| **References Consulted** | `docs/engine-reference/godot/VERSION.md`, `docs/architecture/architecture.md`, `design/gdd/systems-index.md` |
| **Post-Cutoff APIs Used** | None |
| **Verification Required** | Startup integration test or manual evidence that `project.godot` Autoload order matches this ADR |

## ADR Dependencies

| Field | Value |
|-------|-------|
| **Depends On** | None |
| **Enables** | All Autoload-backed systems |
| **Blocks** | Implementation of global services until order is configured |
| **Ordering Note** | This ADR is itself the ordering baseline and should be checked by future story readiness |

## Context

### Problem Statement

Many services are global Autoloads or Autoload-held `RefCounted` services. If they initialize in the wrong order, systems can read missing dependencies, emit before EventBus exists, or query config before DataConfig is loaded.

### Constraints

- BigNumber is a value script, not an Autoload.
- EventBus must be first so other services can publish readiness/errors.
- DataConfigHost must precede static-data consumers.
- DebugConsole and UIManager should degrade gracefully with lazy checks.

### Requirements

- Define one explicit `project.godot` order.
- Avoid circular hard initialization dependencies.
- Require lazy validity checks for optional debug/presentation services.

## Decision

Use explicit Autoload order in `project.godot`:

```text
EventBus
RNGManager
TimeManager
DataConfigHost
ItemRegistry
ModifierEngineHost
ResourceSystem
AttributeSystem
SaveManager
LevelSystem ...
DebugConsole
UIManager
```

`RefCounted` services may be held by lightweight Autoload host Nodes where Godot requires a global entry. BigNumber remains a normal `class_name` value script and is not placed in the Autoload list.

### Architecture Diagram

```text
Foundation globals -> core data hosts -> state systems -> feature systems -> debug/UI
```

### Key Interfaces

This ADR does not create a runtime API. It creates a project configuration contract and a validation checklist for `project.godot`.

## Implementation Guidelines

- Must put EventBus first in Autoload order.
- Must put DataConfigHost before ItemRegistry and other config consumers.
- Must not add BigNumber as an Autoload.
- Must use lightweight Autoload host Nodes for shared `RefCounted` services where needed.
- Must use `has_node()` or `is_instance_valid()` for optional DebugConsole/UIManager dependencies.
- Must not let a Feature or Presentation Autoload initialize before its Foundation/Core dependencies.

## Alternatives Considered

### Alternative 1: Lazy global lookup only
- **Description**: Let every system look up dependencies when first used.
- **Pros**: Less brittle startup order.
- **Cons**: Moves errors to runtime paths and hides missing setup.
- **Rejection Reason**: Foundation/Core systems need deterministic startup for save/offline flows.

### Alternative 2: Dependency injection container
- **Description**: A central container constructs and wires every service.
- **Pros**: Explicit graph and easier testing.
- **Cons**: More infrastructure than the MVP needs.
- **Rejection Reason**: Godot Autoload order is sufficient for this project scale.

## Consequences

### Positive
- Startup dependencies are visible and reviewable.
- Foundation systems become available before consumers.
- Future stories can embed an order checklist.

### Negative
- `project.godot` becomes a critical integration artifact.
- Reordering Autoloads can break startup without touching code.

### Risks
- Manual project setting changes may drift from this ADR.
- Headless tests may not load exactly like the exported project if not configured.

## GDD Requirements Addressed

| GDD System | Requirement | How This ADR Addresses It |
|------------|-------------|--------------------------|
| `systems-index.md` | Dependency chain must flow Foundation → Core → Feature → Presentation | Converts the dependency map into startup order |
| `event-bus.md` | EventBus is Foundation and globally available | Places EventBus first |
| `item-material-system.md` | DataConfig must initialize before ItemRegistry | Locks ordering rule |
| `debug-console.md` | DebugConsole depends on many systems but is removable in Release | Places DebugConsole late and requires lazy checks |

## Performance Implications

- **CPU**: No runtime cost beyond normal Autoload initialization.
- **Memory**: Autoload hosts keep singleton services resident.
- **Load Time**: Startup order can add synchronous DataConfig load before downstream systems.
- **Network**: None.

## Migration Plan

When code begins, configure `project.godot` Autoloads from this ADR before implementing dependent features.

## Validation Criteria

- Integration or manual test confirms startup order and that DataConfig is loaded before ItemRegistry queries.
- Release build confirms DebugConsole removes itself without leaving listeners or UI nodes.

## Related Decisions

- ADR-0002: 事件总线架构
- ADR-0005: 数据配置加载策略

