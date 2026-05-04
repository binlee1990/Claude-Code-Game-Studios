# Story 004: `EventBus.subscribe_pattern("resource", <callable>)` is called exactly

> **Epic**: 调试控制台
> **Status**: Done
> **Layer**: Core Gameplay
> **Type**: Integration
> **Manifest Version**: 2026-05-04

## Context

**GDD**: `design/gdd/debug-console.md`
**Requirement**: `TR-debug-console-001` — DebugConsole provides debug-only runtime commands, event watching, pause-safe overlay behavior, and release-build self-removal.

**ADR Governing Implementation**: ADR-0002: 事件总线架构
**ADR Decision Summary**: Use a global `EventBus` Autoload Node with string event names and `Dictionary` payloads. The bus dispatches events synchronously in the current frame. Exact subscriptions are the production path. Prefix pattern subscriptions exist only for debug tooling such as `event watch resource`. Coalesced events are allowed only for display refreshes where latest-state wins.

**Engine**: Godot 4.6.2 | **Risk**: HIGH
**Engine Notes**: ADR-0002 status is Accepted; verify any Godot 4.6.2 behavior named by the ADR before closing the story.

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

- [x] GIVEN: the console is open, **WHEN** the developer types `event watch resource` and presses Enter, **THEN** `EventBus.subscribe_pattern("resource", <callable>)` is called exactly once, the prefix `"resource"` is recorded in `_watching_prefixes`, and the output confirms the watch is active.
- [x] GIVEN: an active `event watch resource` subscription, **WHEN** EventBus fires an event whose name begins with `"resource"` (e.g. `resource.lingqi.changed`) with payload `{"delta": 10}`, **THEN** the output area appends a cyan line matching `[WATCH] resource.lingqi.changed → {delta: 10}` within the same frame.
- [x] GIVEN: an active `event watch resource` subscription and the console is open, **WHEN** the developer presses `~` to close the console, **THEN** `EventBus.unsubscribe_pattern("resource", <callable>)` is called and `_watching_prefixes` is empty after close.

---

## Implementation Notes

*Derived from ADR-0002 Implementation Guidelines:*

- Must define event names as constants; production code must not use untracked magic strings.
- Must use exact subscriptions for production UI and gameplay consumers.
- Must restrict `subscribe_pattern` to DebugConsole and similar diagnostics.
- Must reject empty prefix pattern subscriptions.
- Must validate `Callable.is_valid()` before delivery and remove invalid callables.
- Must defer subscribe/unsubscribe mutations until after current dispatch completes.

---

## Out of Scope

- Story 001 covers the baseline contract for this epic; do not duplicate its setup work here.
- Story 005 covers the next acceptance group in this epic.

---

## QA Test Cases

*Written at story creation. The developer implements against these cases.*

- **AC**: GIVEN: the console is open, **WHEN** the developer types `event watch resource` and presses Enter, **THEN** `EventBus.subscribe_pattern("resource", <callable>)` is called exactly once, the prefix `"resource"` is recorded in `_watching_prefixes`, and the output confirms the watch is active.
  - Given: the console is open
  - When: the developer types `event watch resource` and presses Enter
  - Then: `EventBus.subscribe_pattern("resource", <callable>)` is called exactly once, the prefix `"resource"` is recorded in `_watching_prefixes`, and the output confirms the watch is active
  - Edge cases: boundary, invalid, missing-data, and repeat-run variants from the GDD edge-case section

- **AC**: GIVEN: an active `event watch resource` subscription, **WHEN** EventBus fires an event whose name begins with `"resource"` (e.g. `resource.lingqi.changed`) with payload `{"delta": 10}`, **THEN** the output area appends a cyan line matching `[WATCH] resource.lingqi.changed → {delta: 10}` within the same frame.
  - Given: an active `event watch resource` subscription
  - When: EventBus fires an event whose name begins with `"resource"` (e.g. `resource.lingqi.changed`) with payload `{"delta": 10}`
  - Then: the output area appends a cyan line matching `[WATCH] resource.lingqi.changed → {delta: 10}` within the same frame
  - Edge cases: boundary, invalid, missing-data, and repeat-run variants from the GDD edge-case section

- **AC**: GIVEN: an active `event watch resource` subscription and the console is open, **WHEN** the developer presses `~` to close the console, **THEN** `EventBus.unsubscribe_pattern("resource", <callable>)` is called and `_watching_prefixes` is empty after close.
  - Given: an active `event watch resource` subscription and the console is open
  - When: the developer presses `~` to close the console
  - Then: `EventBus.unsubscribe_pattern("resource", <callable>)` is called and `_watching_prefixes` is empty after close
  - Edge cases: boundary, invalid, missing-data, and repeat-run variants from the GDD edge-case section

---

## Test Evidence

**Story Type**: Integration
**Required evidence**:
- `tests/integration/debug_console/eventbus-subscribe-pattern-resource-callable-is-called-e_test.gd` — must exist and pass

**Status**: [x] Executed 2026-05-04

---

## Dependencies

- Depends on: Story 001 must be ready or done for shared test fixtures and baseline APIs
- Unlocks: Story 005

## 2026-05-04 Sprint Execution Evidence

- Sprint execution order: Sprint 7, story 15/20
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
