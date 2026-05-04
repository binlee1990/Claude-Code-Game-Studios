# Story 014: Test Strategy Notes 2

> **Epic**: 调试控制台
> **Status**: Ready
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

- [ ] 推荐 fixtures: `FakeEventBus`（记录 subscribe/unsubscribe_pattern 调用 + 触发合成事件）、`FakeResourceSystem`（返回 5 个确定性 BigNumber 资源）、`FakeSaveManager`（stub `save_game`/`collect_save_data`/`is_saving`）、`FakeTimeManager`（记录 `add_speed_source`/`remove_speed_source` 参数）。所有 fakes 通过 GDUnit4 `register_scene_runner` 或等价 DI 机制注册为 Autoload 替身。
- [ ] 性能基准（最后一条 P95 < 50ms）: 在 `tests/integration/debug_console/test_dispatch_performance.gd` 实现 1000 次 headless 迭代，`Time.get_ticks_usec()` 采样，计算 P95 并断言 < 50.0 ms。阈值常量化以适配 CI 慢机器抗噪。

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

---

## QA Test Cases

*Written at story creation. The developer implements against these cases.*

- **AC**: 推荐 fixtures: `FakeEventBus`（记录 subscribe/unsubscribe_pattern 调用 + 触发合成事件）、`FakeResourceSystem`（返回 5 个确定性 BigNumber 资源）、`FakeSaveManager`（stub `save_game`/`collect_save_data`/`is_saving`）、`FakeTimeManager`（记录 `add_speed_source`/`remove_speed_source` 参数）。所有 fakes 通过 GDUnit4 `register_scene_runner` 或等价 DI 机制注册为 Autoload 替身。
  - Given: the story preconditions from the linked GDD are set up
  - When: the behavior under this acceptance criterion is exercised
  - Then: 推荐 fixtures: `FakeEventBus`（记录 subscribe/unsubscribe_pattern 调用 + 触发合成事件）、`FakeResourceSystem`（返回 5 个确定性 BigNumber 资源）、`FakeSaveManager`（stub `save_game`/`collect_save_data`/`is_saving`）、`FakeTimeManager`（记录 `add_speed_source`/`remove_speed_source` 参数）。所有 fakes 通过 GDUnit4 `register_scene_runner` 或等价 DI 机制注册为 Autoload 替身。
  - Edge cases: boundary, invalid, missing-data, and repeat-run variants from the GDD edge-case section

- **AC**: 性能基准（最后一条 P95 < 50ms）: 在 `tests/integration/debug_console/test_dispatch_performance.gd` 实现 1000 次 headless 迭代，`Time.get_ticks_usec()` 采样，计算 P95 并断言 < 50.0 ms。阈值常量化以适配 CI 慢机器抗噪。
  - Given: the story preconditions from the linked GDD are set up
  - When: the behavior under this acceptance criterion is exercised
  - Then: 性能基准（最后一条 P95 < 50ms）: 在 `tests/integration/debug_console/test_dispatch_performance.gd` 实现 1000 次 headless 迭代，`Time.get_ticks_usec()` 采样，计算 P95 并断言 < 50.0 ms。阈值常量化以适配 CI 慢机器抗噪。
  - Edge cases: boundary, invalid, missing-data, and repeat-run variants from the GDD edge-case section

---

## Test Evidence

**Story Type**: Integration
**Required evidence**:
- `tests/integration/debug_console/test-strategy-notes-2_test.gd` — must exist and pass

**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: Story 001 must be ready or done for shared test fixtures and baseline APIs
- Unlocks: None
