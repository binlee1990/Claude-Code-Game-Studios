# Story 001: the scene is loaded and becomes active

> **Epic**: UI 框架
> **Status**: Done
> **Layer**: Presentation
> **Type**: UI
> **Manifest Version**: 2026-05-04

## Context

**GDD**: `design/gdd/ui-framework.md`
**Requirement**: `TR-ui-framework-001` — UIFramework uses UIManager and Control scenes for screen registration, navigation, modals, events, read-only queries, and command routing.

**ADR Governing Implementation**: ADR-0011: UI 屏幕管理架构
**ADR Decision Summary**: Implement UI with Godot `Control` scene files managed by `UIManager` Autoload. UIManager owns screen registration, navigation stack, modal stack, and progressive unlock state. Screens subscribe to EventBus and query read-only APIs. Player commands are sent through explicit command methods on owning systems.

**Engine**: Godot 4.6.2 | **Risk**: HIGH
**Engine Notes**: ADR-0011 status is Accepted; verify any Godot 4.6.2 behavior named by the ADR before closing the story.

**Control Manifest Rules (this layer)**:
- Required: **Build UI screens as Godot `Control` scenes managed by UIManager** — source: ADR-0011
- Required: **Test both mouse and keyboard/gamepad focus paths under Godot 4.6 dual-focus behavior** — source: ADR-0011, ADR-0012
- Required: **Use EventBus subscriptions and read-only queries for display state** — source: ADR-0011
- Required: **Route player actions through explicit command methods on owning systems** — source: ADR-0011
- Forbidden: **Never let UI directly mutate ResourceSystem or AttributeSystem state** — source: ADR-0011
- Forbidden: **Never let UI/HUD/DebugConsole implement duplicate BigNumber formatting** — source: ADR-0014
- Forbidden: **Never ship active DebugConsole UI, listeners, or `_process` work in Release exports** — source: ADR-0012
- Guardrail: **HUD/UI**: coalesce or throttle high-frequency resource/attribute refreshes — source: ADR-0011
- Guardrail: **Lists**: virtualize large logs, inventory, and bestiary rows — source: ADR-0011
- Guardrail: **NumberFormatter**: 1000 formatting calls target <= 1 ms — source: ADR-0014

---

## Acceptance Criteria

*From GDD `design/gdd/ui-framework.md`, scoped to this story:*

- [x] GIVEN: a screen is registered and unlocked, **WHEN** `open_screen(id)` is called, **THEN** the scene is loaded and becomes active.
- [x] GIVEN: screen path missing, **WHEN** opened, **THEN** error state appears and app does not crash.
- [x] GIVEN: 1000 log rows, **WHEN** list renders, **THEN** only visible rows plus overscan are instantiated.

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

- **Manual check**: GIVEN: a screen is registered and unlocked, **WHEN** `open_screen(id)` is called, **THEN** the scene is loaded and becomes active.
  - Setup: a screen is registered and unlocked
  - Verify: `open_screen(id)` is called
  - Pass condition: the scene is loaded and becomes active

- **Manual check**: GIVEN: screen path missing, **WHEN** opened, **THEN** error state appears and app does not crash.
  - Setup: screen path missing
  - Verify: opened
  - Pass condition: error state appears and app does not crash

- **Manual check**: GIVEN: 1000 log rows, **WHEN** list renders, **THEN** only visible rows plus overscan are instantiated.
  - Setup: 1000 log rows
  - Verify: list renders
  - Pass condition: only visible rows plus overscan are instantiated

---

## Test Evidence

**Story Type**: UI
**Required evidence**:
- `production/qa/evidence/the-scene-is-loaded-and-becomes-active-evidence.md` — manual/interaction evidence with sign-off

**Status**: [x] Executed 2026-05-04

---

## Dependencies

- Depends on: None
- Unlocks: Story 002

## 2026-05-04 Sprint Execution Evidence

- Sprint execution order: Sprint 10, story 4/8
- Sprint source: `production/sprints/sprint-10.md`
- QA plan: `production/qa/qa-plan-sprint-10-2026-05-04.md`
- Automated evidence: `reports/report_13/results.xml` (137 tests, 0 failures, 0 skipped, 0 flaky)
- QA gate evidence: `production/qa/evidence/sprint-10-qa-result-2026-05-04.md`
- Verdict: Done; acceptance criteria reviewed against implementation, runtime tests, and sprint QA plan evidence.
- QA-plan automated tests:
  - `tests/integration/sprint10/sprint10_settlement_ui_hud_test.gd`
