# Story 002: 获得同一个全局单例实例

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

- [ ] GIVEN: EventBus 作为 Autoload 加载，**WHEN** 任意系统访问 `EventBus`，**THEN** 获得同一个全局单例实例
- [ ] GIVEN: 系统A 订阅了 `test.event`，**WHEN** 系统B 调用 `EventBus.emit("test.event", {"key": "value"})`，**THEN** 系统A 的回调被调用，且 payload 等于 `{"key": "value"}`
- [ ] GIVEN: 系统A 未订阅 `test.event`，**WHEN** `EventBus.emit("test.event")` 被调用，**THEN** 静默完成，无错误、无副作用

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
- Story 003 covers the next acceptance group in this epic.

---

## QA Test Cases

*Written at story creation. The developer implements against these cases.*

- **AC**: GIVEN: EventBus 作为 Autoload 加载，**WHEN** 任意系统访问 `EventBus`，**THEN** 获得同一个全局单例实例
  - Given: EventBus 作为 Autoload 加载
  - When: 任意系统访问 `EventBus`
  - Then: 获得同一个全局单例实例
  - Edge cases: boundary, invalid, missing-data, and repeat-run variants from the GDD edge-case section

- **AC**: GIVEN: 系统A 订阅了 `test.event`，**WHEN** 系统B 调用 `EventBus.emit("test.event", {"key": "value"})`，**THEN** 系统A 的回调被调用，且 payload 等于 `{"key": "value"}`
  - Given: 系统A 订阅了 `test.event`
  - When: 系统B 调用 `EventBus.emit("test.event", {"key": "value"})`
  - Then: 系统A 的回调被调用，且 payload 等于 `{"key": "value"}`
  - Edge cases: boundary, invalid, missing-data, and repeat-run variants from the GDD edge-case section

- **AC**: GIVEN: 系统A 未订阅 `test.event`，**WHEN** `EventBus.emit("test.event")` 被调用，**THEN** 静默完成，无错误、无副作用
  - Given: 系统A 未订阅 `test.event`
  - When: `EventBus.emit("test.event")` 被调用
  - Then: 静默完成，无错误、无副作用
  - Edge cases: boundary, invalid, missing-data, and repeat-run variants from the GDD edge-case section

---

## Test Evidence

**Story Type**: Integration
**Required evidence**:
- `tests/integration/event_bus/002-integration_test.gd` — must exist and pass

**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: Story 001 must be ready or done for shared test fixtures and baseline APIs
- Unlocks: Story 003
