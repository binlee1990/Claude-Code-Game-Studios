# Story 008: callable 被触发一次，第一个参数等于 `"resource.lingqi.changed"`，第二个参数等于 emit 的 payl

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

- [x] GIVEN: 系统A 调用 `subscribe_pattern("resource", callable)`，**WHEN** EventBus.emit("resource.lingqi.changed", {...}) 被调用，**THEN** callable 被触发一次，第一个参数等于 `"resource.lingqi.changed"`，第二个参数等于 emit 的 payload
- [x] GIVEN: 系统A 调用 `subscribe_pattern("resource", callable)`，**WHEN** EventBus.emit("attribute.player.atk.base_changed", {...}) 被调用（前缀不匹配），**THEN** callable 不被触发
- [x] GIVEN: 系统A 调用 `subscribe_pattern("", callable)`（空 prefix），**WHEN** 注册被处理，**THEN** 注册被拒绝，控制台打印警告，后续任何 emit 都不触发该 callable

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
- Story 009 covers the next acceptance group in this epic.

---

## QA Test Cases

*Written at story creation. The developer implements against these cases.*

- **AC**: GIVEN: 系统A 调用 `subscribe_pattern("resource", callable)`，**WHEN** EventBus.emit("resource.lingqi.changed", {...}) 被调用，**THEN** callable 被触发一次，第一个参数等于 `"resource.lingqi.changed"`，第二个参数等于 emit 的 payload
  - Given: 系统A 调用 `subscribe_pattern("resource", callable)`
  - When: EventBus.emit("resource.lingqi.changed", {...}) 被调用
  - Then: callable 被触发一次，第一个参数等于 `"resource.lingqi.changed"`，第二个参数等于 emit 的 payload
  - Edge cases: boundary, invalid, missing-data, and repeat-run variants from the GDD edge-case section

- **AC**: GIVEN: 系统A 调用 `subscribe_pattern("resource", callable)`，**WHEN** EventBus.emit("attribute.player.atk.base_changed", {...}) 被调用（前缀不匹配），**THEN** callable 不被触发
  - Given: 系统A 调用 `subscribe_pattern("resource", callable)`
  - When: EventBus.emit("attribute.player.atk.base_changed", {...}) 被调用（前缀不匹配）
  - Then: callable 不被触发
  - Edge cases: boundary, invalid, missing-data, and repeat-run variants from the GDD edge-case section

- **AC**: GIVEN: 系统A 调用 `subscribe_pattern("", callable)`（空 prefix），**WHEN** 注册被处理，**THEN** 注册被拒绝，控制台打印警告，后续任何 emit 都不触发该 callable
  - Given: 系统A 调用 `subscribe_pattern("", callable)`（空 prefix）
  - When: 注册被处理
  - Then: 注册被拒绝，控制台打印警告，后续任何 emit 都不触发该 callable
  - Edge cases: boundary, invalid, missing-data, and repeat-run variants from the GDD edge-case section

---

## Test Evidence

**Story Type**: Integration
**Required evidence**:
- `tests/integration/event_bus/callable-resource-lingqi-changed-emit-payl_test.gd` — must exist and pass

**Status**: [x] Executed 2026-05-04

---

## Dependencies

- Depends on: Story 001 must be ready or done for shared test fixtures and baseline APIs
- Unlocks: Story 009

## 2026-05-04 Sprint Execution Evidence

- Sprint execution order: Sprint 2, story 12/20
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
