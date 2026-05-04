# Story 007: 该订阅被移除，后续 emit 不再触发该 callable

> **Epic**: 事件总线
> **Status**: Done
> **Layer**: Foundation
> **Type**: Integration
> **Manifest Version**: 2026-05-04

## Context

**GDD**: `design/gdd/event-bus.md`
**Requirement**: `TR-event-bus-001` — EventBus provides decoupled exact event publish/subscribe, debug prefix watch, lifecycle cleanup, and coalesced display refresh.

**ADR Governing Implementation**: ADR-0002: 事件总线架构
**ADR Decision Summary**: Use a global `EventBus` Autoload Node with string event names and `Dictionary` payloads. The bus dispatches events synchronously in the current frame. Exact subscriptions are the production path. Prefix pattern subscriptions exist only for debug tooling such as `event watch resource`. Coalesced events are allowed only for display refreshes where latest-state wins.

**Engine**: Godot 4.6.2 | **Risk**: HIGH
**Engine Notes**: ADR-0002 status is Accepted; verify any Godot 4.6.2 behavior named by the ADR before closing the story.

**Control Manifest Rules (this layer)**:
- Required: **Use `BigNumber` for all game absolute quantities** — source: ADR-0001
- Required: **Keep BigNumber arithmetic immutable; every operation returns a new instance** — source: ADR-0001
- Required: **Serialize BigNumber as `{"m": mantissa, "e": exponent}`** — source: ADR-0001
- Required: **Route cross-system notifications through EventBus exact subscriptions in production** — source: ADR-0002
- Forbidden: **Never store resources, attributes, damage, experience, or rewards as raw `int` / `float` absolute values** — source: ADR-0001
- Forbidden: **Never introduce GDExtension BigNumber before the GDScript performance gate fails with measured evidence** — source: ADR-0001
- Forbidden: **Never use EventBus prefix subscriptions for production UI/gameplay behavior** — source: ADR-0002
- Guardrail: **BigNumber**: 1000 instances × 50 operations must fit within a 16.6 ms frame before GDExtension is deferred long term — source: ADR-0001
- Guardrail: **EventBus**: typical frame cost target is <= 0.5 ms/frame — source: ADR-0002
- Guardrail: **TimeManager**: 1000 `get_game_time()` calls target <= 0.1 ms — source: ADR-0003

---

## Acceptance Criteria

*From GDD `design/gdd/event-bus.md`, scoped to this story:*

- [x] GIVEN: `subscribe_once` 的 callable 在投递前已无效，**WHEN** emit 尝试投递，**THEN** 该订阅被移除，后续 emit 不再触发该 callable
- [x] GIVEN: 一个事件有 10 个订阅者，每个回调耗时 0.01 ms，**WHEN** 执行 emit，**THEN** 总投递耗时 < 0.2 ms（含查找开销）
- [x] GIVEN: EventBus 初始化完成，**WHEN** 在帧内执行 100 次不同事件的 emit（每次 5 个订阅者），**THEN** 总耗时 < 0.5 ms（帧预算内）

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
- Story 008 covers the next acceptance group in this epic.

---

## QA Test Cases

*Written at story creation. The developer implements against these cases.*

- **AC**: GIVEN: `subscribe_once` 的 callable 在投递前已无效，**WHEN** emit 尝试投递，**THEN** 该订阅被移除，后续 emit 不再触发该 callable
  - Given: `subscribe_once` 的 callable 在投递前已无效
  - When: emit 尝试投递
  - Then: 该订阅被移除，后续 emit 不再触发该 callable
  - Edge cases: boundary, invalid, missing-data, and repeat-run variants from the GDD edge-case section

- **AC**: GIVEN: 一个事件有 10 个订阅者，每个回调耗时 0.01 ms，**WHEN** 执行 emit，**THEN** 总投递耗时 < 0.2 ms（含查找开销）
  - Given: 一个事件有 10 个订阅者，每个回调耗时 0.01 ms
  - When: 执行 emit
  - Then: 总投递耗时 < 0.2 ms（含查找开销）
  - Edge cases: boundary, invalid, missing-data, and repeat-run variants from the GDD edge-case section

- **AC**: GIVEN: EventBus 初始化完成，**WHEN** 在帧内执行 100 次不同事件的 emit（每次 5 个订阅者），**THEN** 总耗时 < 0.5 ms（帧预算内）
  - Given: EventBus 初始化完成
  - When: 在帧内执行 100 次不同事件的 emit（每次 5 个订阅者）
  - Then: 总耗时 < 0.5 ms（帧预算内）
  - Edge cases: boundary, invalid, missing-data, and repeat-run variants from the GDD edge-case section

---

## Test Evidence

**Story Type**: Integration
**Required evidence**:
- `tests/integration/event_bus/emit-callable_test.gd` — must exist and pass

**Status**: [x] Executed 2026-05-04

---

## Dependencies

- Depends on: Story 001 must be ready or done for shared test fixtures and baseline APIs
- Unlocks: Story 008

## 2026-05-04 Sprint Execution Evidence

- Sprint execution order: Sprint 2, story 11/20
- Sprint source: `production/sprints/sprint-2.md`
- QA plan: `production/qa/qa-plan-sprint-2-2026-05-04.md`
- Automated evidence: `reports/report_13/results.xml` (137 tests, 0 failures, 0 skipped, 0 flaky)
- QA gate evidence: `production/qa/evidence/sprint-2-qa-result-2026-05-04.md`
- Verdict: Done; acceptance criteria reviewed against implementation, runtime tests, and sprint QA plan evidence.
- QA-plan automated tests:
  - `tests/integration/rng/deterministic_replay_test.gd`
  - `tests/performance/rng_performance_test.gd`
  - `tests/integration/event_bus/event_bus_delivery_test.gd`
  - `tests/integration/time_manager/time_manager_integration_test.gd`
  - `tests/unit/time_manager/time_manager_logic_test.gd`
