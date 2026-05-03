# ADR-0011: UI 屏幕管理架构

## Status
Accepted

## Date
2026-05-04

## Engine Compatibility

| Field | Value |
|-------|-------|
| **Engine** | Godot 4.6.2 |
| **Domain** | UI / Controls / Input |
| **Knowledge Risk** | HIGH — Godot 4.6 introduced dual-focus behavior and Godot 4.5 added AccessKit/FoldableContainer/recursive Control disable |
| **References Consulted** | `docs/engine-reference/godot/modules/ui.md`, `docs/engine-reference/godot/modules/input.md`, `docs/engine-reference/godot/current-best-practices.md`, `design/gdd/ui-framework.md`, `design/gdd/hud-system.md` |
| **Post-Cutoff APIs Used** | Godot 4.6 dual-focus behavior must be explicitly tested; AccessKit support affects accessibility expectations |
| **Verification Required** | Mouse and keyboard/gamepad focus tests, modal input blocking, coalesced HUD refresh, list virtualization, and screen path error state |

## ADR Dependencies

| Field | Value |
|-------|-------|
| **Depends On** | ADR-0002, ADR-0014 |
| **Enables** | ADR-0012 and player-facing HUD/screen prototype |
| **Blocks** | UI Framework and HUD implementation |
| **Ordering Note** | UIManager initializes late; it consumes events and command APIs, but does not own core state |

## Context

### Problem Statement

The game needs a lightweight screen system for menus, HUD, modal panels, progressive unlocks, and offline reward summaries. Godot 4.6's dual-focus model must be accounted for before UI implementation starts.

### Constraints

- UI must not directly write core state.
- UI displays all numbers through NumberFormatter.
- High-frequency resource/attribute refreshes must be coalesced or locally throttled.
- Mouse and keyboard/gamepad focus must both be tested.

### Requirements

- Use Godot Control scenes and a UIManager Autoload.
- Register screens by ID, scene path, and unlock condition.
- Support open, close, replace, modal, focus restore, error states, and list virtualization.

## Decision

Implement UI with Godot `Control` scene files managed by `UIManager` Autoload. UIManager owns screen registration, navigation stack, modal stack, and progressive unlock state. Screens subscribe to EventBus and query read-only APIs. Player commands are sent through explicit command methods on owning systems.

### Architecture Diagram

```text
EventBus events + read-only queries
        |
        v
UIManager -> screen stack -> Control scenes
        |
        +-- HUD permanent screen
        +-- modal stack
        +-- offline summary panel
```

### Key Interfaces

```gdscript
func register_screen(screen_id: String, scene_path: String, unlock_condition: Callable) -> void
func open_screen(screen_id: String) -> void
func close_screen(screen_id: String = "") -> void
func replace_screen(screen_id: String) -> void
func open_modal(screen_id: String, payload: Dictionary = {}) -> void
func is_screen_unlocked(screen_id: String) -> bool
```

## Implementation Guidelines

- Must build screens as Godot `Control` scenes managed by UIManager.
- Must test both mouse and keyboard/gamepad focus paths in Godot 4.6.
- Must use EventBus subscriptions and read-only queries for display state.
- Must route player actions through explicit command methods on owning systems.
- Must format every BigNumber through NumberFormatter.
- Must coalesce or throttle high-frequency resource/HUD refreshes.
- Must virtualize large lists such as logs, inventory, or bestiary rows.
- Must not let UI directly mutate ResourceSystem or AttributeSystem state.

## Alternatives Considered

### Alternative 1: Each screen self-loads and manages navigation
- **Description**: Screens instantiate other screens directly.
- **Pros**: Fewer central APIs.
- **Cons**: Navigation behavior and focus restore become inconsistent.
- **Rejection Reason**: UI Framework GDD requires a central UIManager stack.

### Alternative 2: Immediate-mode custom UI
- **Description**: Render HUD/menus manually outside Control scene patterns.
- **Pros**: Potentially leaner for simple HUD.
- **Cons**: Loses Godot Control accessibility, focus, and theme infrastructure.
- **Rejection Reason**: Godot Control is the correct MVP UI layer.

## Consequences

### Positive
- One screen lifecycle model for HUD, menus, and modals.
- Godot Control accessibility and focus behavior are first-class.
- UI remains decoupled from core state writes.

### Negative
- UIManager becomes a central presentation dependency.
- Focus testing is mandatory because Godot 4.6 changed behavior.

### Risks
- Incorrect focus restore can break gamepad/keyboard navigation.
- Event storms can trigger excessive layout rebuilds if coalescing is skipped.

## GDD Requirements Addressed

| GDD System | Requirement | How This ADR Addresses It |
|------------|-------------|--------------------------|
| `ui-framework.md` | UI Framework uses Control scenes plus UIManager Autoload | Defines the screen management model |
| `ui-framework.md` | UI does not directly modify core systems | Restricts UI to events, queries, and explicit commands |
| `hud-system.md` | HUD displays MVP resources and listens to gameplay events | Makes HUD a permanent UI-managed screen |
| `number-formatting-system.md` | UI must not format BigNumber itself | Requires NumberFormatter |

## Performance Implications

- **CPU**: Coalesced HUD updates prevent high-frequency layout rebuilds.
- **Memory**: Screen stack and virtualized lists avoid instantiating all rows.
- **Load Time**: Scene loading may be deferred per screen.
- **Network**: None for MVP.

## Migration Plan

Implement UIManager and HUD after EventBus and NumberFormatter are available. Record dual-focus manual evidence during the first UI prototype.

## Validation Criteria

- Tests/manual evidence cover screen registration, missing scene error, navigation stack, modal blocking, focus restore, dual-focus input modes, list virtualization, coalesced HUD refresh, and NumberFormatter usage.

## Related Decisions

- ADR-0002: 事件总线架构
- ADR-0014: NumberFormatter 缩写映射策略

