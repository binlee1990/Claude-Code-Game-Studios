# Story 002: `CanvasLayer.visible` becomes `true`, `get_tree().paused` becomes `tru

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

- [ ] GIVEN: the console is Hidden and the game is running normally, **WHEN** the developer presses the physical `~` key (`KEY_QUOTELEFT`), **THEN** `CanvasLayer.visible` becomes `true`, `get_tree().paused` becomes `true`, `LineEdit` receives keyboard focus, and the `~` character does not appear in the `LineEdit` text.
- [ ] GIVEN: the console is Visible and `get_tree().paused == true`, **WHEN** the developer presses the physical `~` key (`KEY_QUOTELEFT`), **THEN** `CanvasLayer.visible` becomes `false`, `get_tree().paused` becomes `false`, and no further input is consumed by the console.
- [ ] GIVEN: a UI control `ButtonA` holds keyboard focus before the console opens, **WHEN** the developer opens the console and then closes it, **THEN** `ButtonA.has_focus()` returns `true` after close, provided `ButtonA` was not freed during that interval.

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

- Story 001 covers the baseline contract for this epic; do not duplicate its setup work here.
- Story 003 covers the next acceptance group in this epic.

---

## QA Test Cases

*Written at story creation. The developer implements against these cases.*

- **Manual check**: GIVEN: the console is Hidden and the game is running normally, **WHEN** the developer presses the physical `~` key (`KEY_QUOTELEFT`), **THEN** `CanvasLayer.visible` becomes `true`, `get_tree().paused` becomes `true`, `LineEdit` receives keyboard focus, and the `~` character does not appear in the `LineEdit` text.
  - Setup: the console is Hidden and the game is running normally
  - Verify: the developer presses the physical `~` key (`KEY_QUOTELEFT`)
  - Pass condition: `CanvasLayer.visible` becomes `true`, `get_tree().paused` becomes `true`, `LineEdit` receives keyboard focus, and the `~` character does not appear in the `LineEdit` text

- **Manual check**: GIVEN: the console is Visible and `get_tree().paused == true`, **WHEN** the developer presses the physical `~` key (`KEY_QUOTELEFT`), **THEN** `CanvasLayer.visible` becomes `false`, `get_tree().paused` becomes `false`, and no further input is consumed by the console.
  - Setup: the console is Visible and `get_tree().paused == true`
  - Verify: the developer presses the physical `~` key (`KEY_QUOTELEFT`)
  - Pass condition: `CanvasLayer.visible` becomes `false`, `get_tree().paused` becomes `false`, and no further input is consumed by the console

- **Manual check**: GIVEN: a UI control `ButtonA` holds keyboard focus before the console opens, **WHEN** the developer opens the console and then closes it, **THEN** `ButtonA.has_focus()` returns `true` after close, provided `ButtonA` was not freed during that interval.
  - Setup: a UI control `ButtonA` holds keyboard focus before the console opens
  - Verify: the developer opens the console and
  - Pass condition: closes it, THEN `ButtonA.has_focus()` returns `true` after close, provided `ButtonA` was not freed during that interval

---

## Test Evidence

**Story Type**: UI
**Required evidence**:
- `production/qa/evidence/canvaslayer-visible-becomes-true-get-tree-paused-becomes-evidence.md` — manual/interaction evidence with sign-off

**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: Story 001 must be ready or done for shared test fixtures and baseline APIs
- Unlocks: Story 003
