# Story 001: the node calls `queue_free()` and returns immediately, leaving zero re

> **Epic**: 调试控制台
> **Status**: Ready
> **Layer**: Core Gameplay
> **Type**: UI
> **Manifest Version**: 2026-05-04

## Context

**GDD**: `design/gdd/debug-console.md`
**Requirement**: `TR-debug-console-001` — DebugConsole provides debug-only runtime commands, event watching, pause-safe overlay behavior, and release-build self-removal.

**ADR Governing Implementation**: ADR-0011: UI 屏幕管理架构
**ADR Decision Summary**: Implement UI with Godot `Control` scene files managed by `UIManager` Autoload. UIManager owns screen registration, navigation stack, modal stack, and progressive unlock state. Screens subscribe to EventBus and query read-only APIs. Player commands are sent through explicit command methods on owning systems.

**Engine**: Godot 4.6.2 | **Risk**: HIGH
**Engine Notes**: ADR-0011 status is Accepted; verify any Godot 4.6.2 behavior named by the ADR before closing the story.

**Control Manifest Rules (this layer)**:
- Required: **Use JSON files under `res://assets/data/` as the MVP configuration source** — source: ADR-0005
- Required: **Keep DataConfig schema-agnostic; consumers parse BigNumber strings themselves** — source: ADR-0005
- Required: **Keep all MVP config tables resident in DataConfig memory after startup load** — source: ADR-0005
- Required: **Use SaveManager provider callbacks by namespace for persistence** — source: ADR-0006
- Forbidden: **Never use Godot Resource files as the MVP content format** — source: ADR-0005
- Forbidden: **Never write runtime player state through DataConfig** — source: ADR-0005
- Forbidden: **Never make SaveManager import or understand concrete system state types** — source: ADR-0006
- Guardrail: **DataConfig**: MVP load target <= 100 ms and cache <= 5 MB — source: ADR-0005
- Guardrail: **SaveManager**: MVP save/load target <= 20 ms and save object <= 50 KB — source: ADR-0006
- Guardrail: **ModifierEngine**: cached 1000 `get_multiplier()` calls target <= 1 ms — source: ADR-0007

---

## Acceptance Criteria

*From GDD `design/gdd/debug-console.md`, scoped to this story:*

- [ ] GIVEN: the game is exported as a Release build, **WHEN** the Godot runtime calls `DebugConsole._ready()`, **THEN** the node calls `queue_free()` and returns immediately, leaving zero resident memory, zero active `_process` calls, and no `CanvasLayer` in the scene tree.
- [ ] GIVEN: a Release build is running, **WHEN** the player presses the physical `~` key (`KEY_QUOTELEFT`), **THEN** no console overlay appears and no input is consumed by the debug system.
- [ ] GIVEN: the game is running as a Debug build, **WHEN** the scene tree initializes, **THEN** `/root/DebugConsole` exists as an Autoload node with `process_mode == Node.PROCESS_MODE_ALWAYS` and `CanvasLayer.layer == 128` and `CanvasLayer.visible == false`.

---

## Implementation Notes

*Derived from ADR-0011 Implementation Guidelines:*

- Must build screens as Godot `Control` scenes managed by UIManager.
- Must test both mouse and keyboard/gamepad focus paths in Godot 4.6.
- Must use EventBus subscriptions and read-only queries for display state.
- Must route player actions through explicit command methods on owning systems.
- Must format every BigNumber through NumberFormatter.
- Must coalesce or throttle high-frequency resource/HUD refreshes.

---

## Out of Scope

- Story 002 covers the next acceptance group in this epic.

---

## QA Test Cases

*Written at story creation. The developer implements against these cases.*

- **Manual check**: GIVEN: the game is exported as a Release build, **WHEN** the Godot runtime calls `DebugConsole._ready()`, **THEN** the node calls `queue_free()` and returns immediately, leaving zero resident memory, zero active `_process` calls, and no `CanvasLayer` in the scene tree.
  - Setup: the game is exported as a Release build
  - Verify: the Godot runtime calls `DebugConsole._ready()`
  - Pass condition: the node calls `queue_free()` and returns immediately, leaving zero resident memory, zero active `_process` calls, and no `CanvasLayer` in the scene tree

- **Manual check**: GIVEN: a Release build is running, **WHEN** the player presses the physical `~` key (`KEY_QUOTELEFT`), **THEN** no console overlay appears and no input is consumed by the debug system.
  - Setup: a Release build is running
  - Verify: the player presses the physical `~` key (`KEY_QUOTELEFT`)
  - Pass condition: no console overlay appears and no input is consumed by the debug system

- **Manual check**: GIVEN: the game is running as a Debug build, **WHEN** the scene tree initializes, **THEN** `/root/DebugConsole` exists as an Autoload node with `process_mode == Node.PROCESS_MODE_ALWAYS` and `CanvasLayer.layer == 128` and `CanvasLayer.visible == false`.
  - Setup: the game is running as a Debug build
  - Verify: the scene tree initializes
  - Pass condition: `/root/DebugConsole` exists as an Autoload node with `process_mode == Node.PROCESS_MODE_ALWAYS` and `CanvasLayer.layer == 128` and `CanvasLayer.visible == false`

---

## Test Evidence

**Story Type**: UI
**Required evidence**:
- `production/qa/evidence/the-node-calls-queue-free-and-returns-immediately-leavin-evidence.md` — manual/interaction evidence with sign-off

**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: None
- Unlocks: Story 002
