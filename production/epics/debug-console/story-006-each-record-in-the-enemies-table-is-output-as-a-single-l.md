# Story 006: each record in the `enemies` table is output as a single-line compact

> **Epic**: 调试控制台
> **Status**: Done
> **Layer**: Core Gameplay
> **Type**: Config/Data
> **Manifest Version**: 2026-05-04

## Context

**GDD**: `design/gdd/debug-console.md`
**Requirement**: `TR-debug-console-001` — DebugConsole provides debug-only runtime commands, event watching, pause-safe overlay behavior, and release-build self-removal.

**ADR Governing Implementation**: ADR-0012: DebugConsole 发布构建排除
**ADR Decision Summary**: Register `DebugConsole` as an Autoload, but make `_ready()` begin with:

**Engine**: Godot 4.6.2 | **Risk**: HIGH
**Engine Notes**: ADR-0012 status is Accepted; verify any Godot 4.6.2 behavior named by the ADR before closing the story.

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

- [x] GIVEN: the console is open, **WHEN** the developer types `config show enemies` and presses Enter, **THEN** each record in the `enemies` table is output as a single-line compact JSON string (no indentation), with one record per output line.
- [x] GIVEN: the console is open, **WHEN** the developer types `modifier list` and presses Enter, **THEN** the output lists all registered modifier targets returned by `ModifierEngine.get_all_targets()`, one per line.
- [x] GIVEN: the console is open, **WHEN** the developer types `modifier breakdown lingqi_production` and presses Enter, **THEN** the output shows each pool's contribution in the format `pool[{name}]: ×{mult}`, plus `add_sum: {v}` and `final_mult: {f}`.

---

## Implementation Notes

*Derived from ADR-0012 Implementation Guidelines:*

- Must call `queue_free()` immediately in non-debug builds.
- Must set `process_mode = Node.PROCESS_MODE_ALWAYS` in debug builds.
- Must use `event.physical_keycode == KEY_QUOTELEFT` for toggle.
- Must restore prior keyboard focus when closing if the previous control is still valid.
- Must unsubscribe all active `event watch` prefix subscriptions when closing.
- Must keep command handlers returning output lines; handlers must not write UI directly.

---

## Out of Scope

- Story 001 covers the baseline contract for this epic; do not duplicate its setup work here.
- Story 007 covers the next acceptance group in this epic.

---

## QA Test Cases

*Written at story creation. The developer implements against these cases.*

- **AC**: GIVEN: the console is open, **WHEN** the developer types `config show enemies` and presses Enter, **THEN** each record in the `enemies` table is output as a single-line compact JSON string (no indentation), with one record per output line.
  - Given: the console is open
  - When: the developer types `config show enemies` and presses Enter
  - Then: each record in the `enemies` table is output as a single-line compact JSON string (no indentation), with one record per output line
  - Edge cases: boundary, invalid, missing-data, and repeat-run variants from the GDD edge-case section

- **AC**: GIVEN: the console is open, **WHEN** the developer types `modifier list` and presses Enter, **THEN** the output lists all registered modifier targets returned by `ModifierEngine.get_all_targets()`, one per line.
  - Given: the console is open
  - When: the developer types `modifier list` and presses Enter
  - Then: the output lists all registered modifier targets returned by `ModifierEngine.get_all_targets()`, one per line
  - Edge cases: boundary, invalid, missing-data, and repeat-run variants from the GDD edge-case section

- **AC**: GIVEN: the console is open, **WHEN** the developer types `modifier breakdown lingqi_production` and presses Enter, **THEN** the output shows each pool's contribution in the format `pool[{name}]: ×{mult}`, plus `add_sum: {v}` and `final_mult: {f}`.
  - Given: the console is open
  - When: the developer types `modifier breakdown lingqi_production` and presses Enter
  - Then: the output shows each pool's contribution in the format `pool[{name}]: ×{mult}`, plus `add_sum: {v}` and `final_mult: {f}`
  - Edge cases: boundary, invalid, missing-data, and repeat-run variants from the GDD edge-case section

---

## Test Evidence

**Story Type**: Config/Data
**Required evidence**:
- `production/qa/smoke-debug-console.md` — smoke check evidence

**Status**: [x] Executed 2026-05-04

---

## Dependencies

- Depends on: Story 001 must be ready or done for shared test fixtures and baseline APIs
- Unlocks: Story 007

## 2026-05-04 Sprint Execution Evidence

- Sprint execution order: Sprint 7, story 17/20
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
