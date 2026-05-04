# Story 008: the output displays `real_time`, `game_time`, `effective_speed`, and `

> **Epic**: 调试控制台
> **Status**: Done
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

- [x] GIVEN: the console is open, **WHEN** the developer types `time status` and presses Enter, **THEN** the output displays `real_time`, `game_time`, `effective_speed`, and `frozen` status from `TimeManager` on separate lines.
- [x] GIVEN: the console is open, **WHEN** the developer types `time speed 0.5` and presses Enter, **THEN** `TimeManager.add_speed_source("debug_console", 0.5)` is called and the output confirms the speed change.
- [x] GIVEN: the console is open, **WHEN** the developer types `time speed 0` or `time speed -1` and presses Enter, **THEN** the output displays `[ERROR] Speed must be in range [0.1, 100.0]. Got: {N}.` in red and `TimeManager.add_speed_source` is not called.

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
- Story 009 covers the next acceptance group in this epic.

---

## QA Test Cases

*Written at story creation. The developer implements against these cases.*

- **Manual check**: GIVEN: the console is open, **WHEN** the developer types `time status` and presses Enter, **THEN** the output displays `real_time`, `game_time`, `effective_speed`, and `frozen` status from `TimeManager` on separate lines.
  - Setup: the console is open
  - Verify: the developer types `time status` and presses Enter
  - Pass condition: the output displays `real_time`, `game_time`, `effective_speed`, and `frozen` status from `TimeManager` on separate lines

- **Manual check**: GIVEN: the console is open, **WHEN** the developer types `time speed 0.5` and presses Enter, **THEN** `TimeManager.add_speed_source("debug_console", 0.5)` is called and the output confirms the speed change.
  - Setup: the console is open
  - Verify: the developer types `time speed 0.5` and presses Enter
  - Pass condition: `TimeManager.add_speed_source("debug_console", 0.5)` is called and the output confirms the speed change

- **Manual check**: GIVEN: the console is open, **WHEN** the developer types `time speed 0` or `time speed -1` and presses Enter, **THEN** the output displays `[ERROR] Speed must be in range [0.1, 100.0]. Got: {N}.` in red and `TimeManager.add_speed_source` is not called.
  - Setup: the console is open
  - Verify: the developer types `time speed 0` or `time speed -1` and presses Enter
  - Pass condition: the output displays `[ERROR] Speed must be in range [0.1, 100.0]. Got: {N}.` in red and `TimeManager.add_speed_source` is not called

---

## Test Evidence

**Story Type**: UI
**Required evidence**:
- `production/qa/evidence/the-output-displays-real-time-game-time-effective-speed-evidence.md` — manual/interaction evidence with sign-off

**Status**: [x] Executed 2026-05-04

---

## Dependencies

- Depends on: Story 001 must be ready or done for shared test fixtures and baseline APIs
- Unlocks: Story 009

## 2026-05-04 Sprint Execution Evidence

- Sprint execution order: Sprint 7, story 19/20
- Sprint source: `production/sprints/sprint-7.md`
- QA plan: `production/qa/qa-plan-sprint-7-2026-05-04.md`
- Automated evidence: `reports/report_13/results.xml` (137 tests, 0 failures, 0 skipped, 0 flaky)
- QA gate evidence: `production/qa/evidence/sprint-7-qa-result-2026-05-04.md`
- Verdict: Done; acceptance criteria reviewed against implementation, runtime tests, and sprint QA plan evidence.
- QA-plan automated tests:
  - `tests/integration/item_registry/item_registry_boundary_test.gd`
  - `tests/unit/output_multiplier_system/output_multiplier_system_config_test.gd`
  - `tests/unit/output_multiplier_system/output_multiplier_system_formula_test.gd`
  - `tests/integration/output_multiplier_system/output_multiplier_events_test.gd`
  - `tests/unit/debug_console/debug_console_command_test.gd`
  - `tests/integration/debug_console/debug_console_smoke_test.gd`
