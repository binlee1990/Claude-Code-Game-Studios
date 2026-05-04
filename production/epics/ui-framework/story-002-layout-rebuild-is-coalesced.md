# Story 002: layout rebuild is coalesced

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

- [x] GIVEN: resource events emit 50 times in one frame, **WHEN** HUD refreshes, **THEN** layout rebuild is coalesced.
- [x] GIVEN: modal open, **WHEN** background command button is clicked, **THEN** command is blocked unless modal allows passthrough.

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

---

## QA Test Cases

*Written at story creation. The developer implements against these cases.*

- **Manual check**: GIVEN: resource events emit 50 times in one frame, **WHEN** HUD refreshes, **THEN** layout rebuild is coalesced.
  - Setup: resource events emit 50 times in one frame
  - Verify: HUD refreshes
  - Pass condition: layout rebuild is coalesced

- **Manual check**: GIVEN: modal open, **WHEN** background command button is clicked, **THEN** command is blocked unless modal allows passthrough.
  - Setup: modal open
  - Verify: background command button is clicked
  - Pass condition: command is blocked unless modal allows passthrough

---

## Test Evidence

**Story Type**: UI
**Required evidence**:
- `production/qa/evidence/layout-rebuild-is-coalesced-evidence.md` — manual/interaction evidence with sign-off

**Status**: [x] Executed 2026-05-04

---

## Dependencies

- Depends on: Story 001 must be ready or done for shared test fixtures and baseline APIs
- Unlocks: None

## 2026-05-04 Sprint Execution Evidence

- Sprint execution order: Sprint 10, story 5/8
- Sprint source: `production/sprints/sprint-10.md`
- QA plan: `production/qa/qa-plan-sprint-10-2026-05-04.md`
- Automated evidence: `reports/report_13/results.xml` (137 tests, 0 failures, 0 skipped, 0 flaky)
- QA gate evidence: `production/qa/evidence/sprint-10-qa-result-2026-05-04.md`
- Verdict: Done; acceptance criteria reviewed against implementation, runtime tests, and sprint QA plan evidence.
- QA-plan automated tests:
  - `tests/integration/sprint10/sprint10_settlement_ui_hud_test.gd`
