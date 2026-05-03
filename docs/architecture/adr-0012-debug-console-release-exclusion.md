# ADR-0012: DebugConsole 发布构建排除

## Status
Accepted

## Date
2026-05-04

## Engine Compatibility

| Field | Value |
|-------|-------|
| **Engine** | Godot 4.6.2 |
| **Domain** | UI / Input / GDScript |
| **Knowledge Risk** | HIGH — debug UI uses Control focus in Godot 4.6 dual-focus behavior and release-build lifecycle must be verified |
| **References Consulted** | `docs/engine-reference/godot/modules/ui.md`, `docs/engine-reference/godot/modules/input.md`, `design/gdd/debug-console.md` |
| **Post-Cutoff APIs Used** | Godot 4.6 dual-focus behavior affects `LineEdit.grab_focus()` and previous-focus restore |
| **Verification Required** | Debug and Release export behavior, pause-mode input, focus restore, event watch cleanup, command outputs |

## ADR Dependencies

| Field | Value |
|-------|-------|
| **Depends On** | ADR-0002, ADR-0003, ADR-0005, ADR-0006, ADR-0007, ADR-0010, ADR-0011, ADR-0014 |
| **Enables** | Developer diagnostics and QA support |
| **Blocks** | DebugConsole implementation only; game MVP can run without it in Release |
| **Ordering Note** | DebugConsole initializes late and must tolerate missing optional systems in early prototypes |

## Context

### Problem Statement

The project needs rich debug commands for resources, config, modifiers, attributes, production, time, save, and event watch. The console must not exist in Release exports.

### Constraints

- Release build must have zero resident console memory/listeners/UI.
- Debug build must work while the scene tree is paused.
- The physical `~` key must be stable across keyboard layouts.
- Prefix event watching is diagnostic only.

### Requirements

- Register DebugConsole as an Autoload for debug builds.
- Destroy itself immediately in non-debug builds.
- Use a CanvasLayer overlay above HUD.
- Clean up event watch subscriptions on close.

## Decision

Register `DebugConsole` as an Autoload, but make `_ready()` begin with:

```gdscript
if not OS.is_debug_build():
    queue_free()
    return
```

In debug builds, it creates a CanvasLayer overlay, sets `process_mode = Node.PROCESS_MODE_ALWAYS`, toggles on physical `KEY_QUOTELEFT`, pauses the tree only while it owns the pause, and uses EventBus prefix subscriptions for `event watch`.

### Architecture Diagram

```text
Release export: /root/DebugConsole -> _ready() -> queue_free()

Debug export:
DebugConsole Autoload -> CanvasLayer(layer 128) -> LineEdit/RichTextLabel
        |
        +-- commands query Time/Save/Data/Resource/Modifier/etc.
        +-- EventBus.subscribe_pattern for watch commands
```

### Key Interfaces

```gdscript
func _ready() -> void
func _input(event: InputEvent) -> void
func _cmd_event(args: Array[String]) -> Array[String]
func _cmd_time(args: Array[String]) -> Array[String]
func _cmd_save(args: Array[String]) -> Array[String]
```

## Implementation Guidelines

- Must call `queue_free()` immediately in non-debug builds.
- Must set `process_mode = Node.PROCESS_MODE_ALWAYS` in debug builds.
- Must use `event.physical_keycode == KEY_QUOTELEFT` for toggle.
- Must restore prior keyboard focus when closing if the previous control is still valid.
- Must unsubscribe all active `event watch` prefix subscriptions when closing.
- Must keep command handlers returning output lines; handlers must not write UI directly.
- Must not ship active DebugConsole UI, listeners, or `_process` work in Release exports.

## Alternatives Considered

### Alternative 1: Do not register DebugConsole in Release export presets
- **Description**: Rely on export preset/project setting changes.
- **Pros**: No runtime branch.
- **Cons**: Easy to misconfigure and hard to verify in code.
- **Rejection Reason**: Self-removal makes the guarantee local and testable.

### Alternative 2: Use Godot editor debugger only
- **Description**: Skip in-game debug console.
- **Pros**: Zero custom UI.
- **Cons**: Does not support QA/runtime commands such as event watch, save dump, or time speed.
- **Rejection Reason**: DebugConsole GDD requires runtime diagnostics.

## Consequences

### Positive
- Release safety is explicit.
- QA and developers get consistent runtime diagnostics.
- Prefix event watching remains isolated to debug tooling.

### Negative
- DebugConsole depends on many systems and must degrade carefully.
- UI focus behavior requires Godot 4.6-specific testing.

### Risks
- Incorrect pause ownership can unpause a tree that was already paused.
- Forgetting to unsubscribe watches can leak debug callbacks.

## GDD Requirements Addressed

| GDD System | Requirement | How This ADR Addresses It |
|------------|-------------|--------------------------|
| `debug-console.md` | Release builds call `queue_free()` immediately and leave zero resident console behavior | Defines release exclusion mechanism |
| `debug-console.md` | Console remains usable while paused | Requires `PROCESS_MODE_ALWAYS` |
| `event-bus.md` | Prefix subscriptions are debug-only | Restricts `event watch` to DebugConsole |
| `ui-framework.md` | Godot 4.6 focus behavior must be respected | Requires focus restore and dual-focus validation |

## Performance Implications

- **CPU**: Zero in Release. Debug command dispatch target under the GDD latency budget.
- **Memory**: Zero resident DebugConsole in Release; debug output buffer capped by GDD settings.
- **Load Time**: Release branch immediately queues node free.
- **Network**: None.

## Migration Plan

Implement after dependent services exist, or gate commands behind availability checks during early prototypes.

## Validation Criteria

- Release export/manual run proves node self-removal and no overlay on `~`.
- Debug run proves toggle, pause ownership, focus restore, command outputs, event watch subscribe/unsubscribe, and save dump no-write behavior.

## Related Decisions

- ADR-0002: 事件总线架构
- ADR-0011: UI 屏幕管理架构

