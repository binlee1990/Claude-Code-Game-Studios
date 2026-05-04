# Story 010: the output displays exactly the `event` command's full help text: `eve

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

- [ ] GIVEN: the console is open, **WHEN** the developer types `help event` and presses Enter, **THEN** the output displays exactly the `event` command's full help text: `event watch <prefix> | event unwatch <prefix>`.
- [ ] GIVEN: the console is open, **WHEN** the developer types `clear` and presses Enter, **THEN** the `RichTextLabel` output area is emptied and `_output_buffer` contains zero lines.
- [ ] GIVEN: the console is open, **WHEN** the developer types an unrecognized command such as `foo`, **THEN** the output displays `[ERROR] Unknown command: 'foo'. Type 'help' for a list.` in red, and `"foo"` is not written to command history.

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
- Story 011 covers the next acceptance group in this epic.

---

## QA Test Cases

*Written at story creation. The developer implements against these cases.*

- **Manual check**: GIVEN: the console is open, **WHEN** the developer types `help event` and presses Enter, **THEN** the output displays exactly the `event` command's full help text: `event watch <prefix> | event unwatch <prefix>`.
  - Setup: the console is open
  - Verify: the developer types `help event` and presses Enter
  - Pass condition: the output displays exactly the `event` command's full help text: `event watch <prefix> | event unwatch <prefix>`

- **Manual check**: GIVEN: the console is open, **WHEN** the developer types `clear` and presses Enter, **THEN** the `RichTextLabel` output area is emptied and `_output_buffer` contains zero lines.
  - Setup: the console is open
  - Verify: the developer types `clear` and presses Enter
  - Pass condition: the `RichTextLabel` output area is emptied and `_output_buffer` contains zero lines

- **Manual check**: GIVEN: the console is open, **WHEN** the developer types an unrecognized command such as `foo`, **THEN** the output displays `[ERROR] Unknown command: 'foo'. Type 'help' for a list.` in red, and `"foo"` is not written to command history.
  - Setup: the console is open
  - Verify: the developer types an unrecognized command such as `foo`
  - Pass condition: the output displays `[ERROR] Unknown command: 'foo'. Type 'help' for a list.` in red, and `"foo"` is not written to command history

---

## Test Evidence

**Story Type**: UI
**Required evidence**:
- `production/qa/evidence/the-output-displays-exactly-the-event-command-s-full-hel-evidence.md` — manual/interaction evidence with sign-off

**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: Story 001 must be ready or done for shared test fixtures and baseline APIs
- Unlocks: Story 011
