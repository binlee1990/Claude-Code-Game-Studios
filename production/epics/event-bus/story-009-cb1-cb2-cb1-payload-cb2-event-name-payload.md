# Story 009: cb1 与 cb2 均被触发；cb1 收到一个参数（payload），cb2 收到两个参数（event_name + payload）

> **Epic**: 事件总线
> **Status**: Ready
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

- [ ] GIVEN: 系统A 同时调用 `subscribe("test.event", cb1)` 与 `subscribe_pattern("test", cb2)`，**WHEN** EventBus.emit("test.event", {...}) 被调用，**THEN** cb1 与 cb2 均被触发；cb1 收到一个参数（payload），cb2 收到两个参数（event_name + payload）
- [ ] GIVEN: 系统A `subscribe_pattern("resource", callable)`，**WHEN** 调用 `unsubscribe_pattern("resource", callable)` 后再 emit `resource.lingqi.changed`，**THEN** callable 不再被触发
- [ ] GIVEN: 系统A `subscribe_pattern("resource", callable)`，**WHEN** 错误地调用 `unsubscribe("resource", callable)`，**THEN** 该 pattern 订阅仍然有效（unsubscribe 与 unsubscribe_pattern 互不影响）

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
- Story 010 covers the next acceptance group in this epic.

---

## QA Test Cases

*Written at story creation. The developer implements against these cases.*

- **AC**: GIVEN: 系统A 同时调用 `subscribe("test.event", cb1)` 与 `subscribe_pattern("test", cb2)`，**WHEN** EventBus.emit("test.event", {...}) 被调用，**THEN** cb1 与 cb2 均被触发；cb1 收到一个参数（payload），cb2 收到两个参数（event_name + payload）
  - Given: 系统A 同时调用 `subscribe("test.event", cb1)` 与 `subscribe_pattern("test", cb2)`
  - When: EventBus.emit("test.event", {...}) 被调用
  - Then: cb1 与 cb2 均被触发；cb1 收到一个参数（payload），cb2 收到两个参数（event_name + payload）
  - Edge cases: boundary, invalid, missing-data, and repeat-run variants from the GDD edge-case section

- **AC**: GIVEN: 系统A `subscribe_pattern("resource", callable)`，**WHEN** 调用 `unsubscribe_pattern("resource", callable)` 后再 emit `resource.lingqi.changed`，**THEN** callable 不再被触发
  - Given: 系统A `subscribe_pattern("resource", callable)`
  - When: 调用 `unsubscribe_pattern("resource", callable)` 后再 emit `resource.lingqi.changed`
  - Then: callable 不再被触发
  - Edge cases: boundary, invalid, missing-data, and repeat-run variants from the GDD edge-case section

- **AC**: GIVEN: 系统A `subscribe_pattern("resource", callable)`，**WHEN** 错误地调用 `unsubscribe("resource", callable)`，**THEN** 该 pattern 订阅仍然有效（unsubscribe 与 unsubscribe_pattern 互不影响）
  - Given: 系统A `subscribe_pattern("resource", callable)`
  - When: 错误地调用 `unsubscribe("resource", callable)`
  - Then: 该 pattern 订阅仍然有效（unsubscribe 与 unsubscribe_pattern 互不影响）
  - Edge cases: boundary, invalid, missing-data, and repeat-run variants from the GDD edge-case section

---

## Test Evidence

**Story Type**: Integration
**Required evidence**:
- `tests/integration/event_bus/cb1-cb2-cb1-payload-cb2-event-name-payload_test.gd` — must exist and pass

**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: Story 001 must be ready or done for shared test fixtures and baseline APIs
- Unlocks: Story 010
