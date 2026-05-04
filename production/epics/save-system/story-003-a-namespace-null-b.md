# Story 003: 系统 A 的 namespace 数据为 `null`，系统 B 的数据正常保存，打印警告

> **Epic**: 存档系统
> **Status**: Done
> **Layer**: Core Data
> **Type**: Integration
> **Manifest Version**: 2026-05-04

## Context

**GDD**: `design/gdd/save-system.md`
**Requirement**: `TR-save-system-001` — SaveManager persists namespaced provider data to a versioned JSON autosave with temp-write, backup recovery, and migrations.

**ADR Governing Implementation**: ADR-0008: Autoload 初始化顺序
**ADR Decision Summary**: Use explicit Autoload order in `project.godot`:

**Engine**: Godot 4.6.2 | **Risk**: MEDIUM
**Engine Notes**: ADR-0008 status is Accepted; verify any Godot 4.6.2 behavior named by the ADR before closing the story.

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

*From GDD `design/gdd/save-system.md`, scoped to this story:*

- [x] GIVEN: 系统 A 的 `save_fn()` 返回 `null` 或非 Dictionary，**WHEN** 调用 `save_game()`，**THEN** 系统 A 的 namespace 数据为 `null`，系统 B 的数据正常保存，打印警告
- [x] GIVEN: 系统 A 的 `restore_fn()` 返回 `false`，**WHEN** 调用 `load_game()`，**THEN** 系统 A 以默认状态运行，系统 B 正常恢复，打印警告
- [x] GIVEN: 存档含 namespace `removed_system` 但无对应 provider，**WHEN** 加载，**THEN** 数据保留不分发，无错误；保存时该数据随存档写出

---

## Implementation Notes

*Derived from ADR-0008 Implementation Guidelines:*

- Must put EventBus first in Autoload order.
- Must put DataConfigHost before ItemRegistry and other config consumers.
- Must not add BigNumber as an Autoload.
- Must use lightweight Autoload host Nodes for shared `RefCounted` services where needed.
- Must use `has_node()` or `is_instance_valid()` for optional DebugConsole/UIManager dependencies.
- Must not let a Feature or Presentation Autoload initialize before its Foundation/Core dependencies.

---

## Out of Scope

- Story 001 covers the baseline contract for this epic; do not duplicate its setup work here.
- Story 004 covers the next acceptance group in this epic.

---

## QA Test Cases

*Written at story creation. The developer implements against these cases.*

- **AC**: GIVEN: 系统 A 的 `save_fn()` 返回 `null` 或非 Dictionary，**WHEN** 调用 `save_game()`，**THEN** 系统 A 的 namespace 数据为 `null`，系统 B 的数据正常保存，打印警告
  - Given: 系统 A 的 `save_fn()` 返回 `null` 或非 Dictionary
  - When: 调用 `save_game()`
  - Then: 系统 A 的 namespace 数据为 `null`，系统 B 的数据正常保存，打印警告
  - Edge cases: boundary, invalid, missing-data, and repeat-run variants from the GDD edge-case section

- **AC**: GIVEN: 系统 A 的 `restore_fn()` 返回 `false`，**WHEN** 调用 `load_game()`，**THEN** 系统 A 以默认状态运行，系统 B 正常恢复，打印警告
  - Given: 系统 A 的 `restore_fn()` 返回 `false`
  - When: 调用 `load_game()`
  - Then: 系统 A 以默认状态运行，系统 B 正常恢复，打印警告
  - Edge cases: boundary, invalid, missing-data, and repeat-run variants from the GDD edge-case section

- **AC**: GIVEN: 存档含 namespace `removed_system` 但无对应 provider，**WHEN** 加载，**THEN** 数据保留不分发，无错误；保存时该数据随存档写出
  - Given: 存档含 namespace `removed_system` 但无对应 provider
  - When: 加载
  - Then: 数据保留不分发，无错误；保存时该数据随存档写出
  - Edge cases: boundary, invalid, missing-data, and repeat-run variants from the GDD edge-case section

---

## Test Evidence

**Story Type**: Integration
**Required evidence**:
- `tests/integration/save/a-namespace-null-b_test.gd` — must exist and pass

**Status**: [x] Executed 2026-05-04

---

## Dependencies

- Depends on: Story 001 must be ready or done for shared test fixtures and baseline APIs
- Unlocks: Story 004

## 2026-05-04 Sprint Execution Evidence

- Sprint execution order: Sprint 4, story 15/20
- Sprint source: `production/sprints/sprint-4.md`
- QA plan: `production/qa/qa-plan-sprint-4-2026-05-04.md`
- Automated evidence: `reports/report_13/results.xml` (137 tests, 0 failures, 0 skipped, 0 flaky)
- QA gate evidence: `production/qa/evidence/sprint-4-qa-result-2026-05-04.md`
- Verdict: Done; acceptance criteria reviewed against implementation, runtime tests, and sprint QA plan evidence.
- QA-plan automated tests:
  - `tests/unit/formula_engine/formula_engine_edges_test.gd`
  - `tests/unit/modifier_engine/modifier_engine_test.gd`
  - `tests/unit/save_system/save_manager_collect_test.gd`
  - `tests/integration/save_system/save_manager_file_contract_test.gd`
