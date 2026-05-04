# Story 010: Edge Cases

> **Epic**: 属性系统
> **Status**: Ready
> **Layer**: Core Gameplay
> **Type**: Integration
> **Manifest Version**: 2026-05-04

## Context

**GDD**: `design/gdd/attribute-system.md`
**Requirement**: `TR-attribute-system-001` — AttributeSystem owns entity attribute base values, final-value queries through ModifierEngine, events, snapshot, and restore.

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

*From GDD `design/gdd/attribute-system.md`, scoped to this story:*

- [ ] GIVEN: `BigNumber` 实例由 NaN 创建（已归一化为 ZERO），**WHEN** `set_base("player", "atk", that_bn)`，**THEN** 写入 ZERO，根据旧值是否非 ZERO 决定是否发事件
- [ ] GIVEN: `make_target("", "atk")` 入参空，**WHEN** 调用，**THEN** 返回空 StringName，打印警告
- [ ] GIVEN: `get_final("player", "atk")` 在 base_changed 回调内被同步调用，**WHEN** 触发，**THEN** 正常返回当前最终值，不死锁，不递归阻断
- [ ] GIVEN: `set_base("player", "atk", ...)` 在 `attribute.player.atk.base_changed` 自身回调内被调用 (同名递归)，**WHEN** 调用，**THEN** 写入已执行，但事件不再投递（EventBus 阻断）

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
- Story 011 covers the next acceptance group in this epic.

---

## QA Test Cases

*Written at story creation. The developer implements against these cases.*

- **AC**: GIVEN: `BigNumber` 实例由 NaN 创建（已归一化为 ZERO），**WHEN** `set_base("player", "atk", that_bn)`，**THEN** 写入 ZERO，根据旧值是否非 ZERO 决定是否发事件
  - Given: `BigNumber` 实例由 NaN 创建（已归一化为 ZERO）
  - When: `set_base("player", "atk", that_bn)`
  - Then: 写入 ZERO，根据旧值是否非 ZERO 决定是否发事件
  - Edge cases: boundary, invalid, missing-data, and repeat-run variants from the GDD edge-case section

- **AC**: GIVEN: `make_target("", "atk")` 入参空，**WHEN** 调用，**THEN** 返回空 StringName，打印警告
  - Given: `make_target("", "atk")` 入参空
  - When: 调用
  - Then: 返回空 StringName，打印警告
  - Edge cases: boundary, invalid, missing-data, and repeat-run variants from the GDD edge-case section

- **AC**: GIVEN: `get_final("player", "atk")` 在 base_changed 回调内被同步调用，**WHEN** 触发，**THEN** 正常返回当前最终值，不死锁，不递归阻断
  - Given: `get_final("player", "atk")` 在 base_changed 回调内被同步调用
  - When: 触发
  - Then: 正常返回当前最终值，不死锁，不递归阻断
  - Edge cases: boundary, invalid, missing-data, and repeat-run variants from the GDD edge-case section

- **AC**: GIVEN: `set_base("player", "atk", ...)` 在 `attribute.player.atk.base_changed` 自身回调内被调用 (同名递归)，**WHEN** 调用，**THEN** 写入已执行，但事件不再投递（EventBus 阻断）
  - Given: `set_base("player", "atk", ...)` 在 `attribute.player.atk.base_changed` 自身回调内被调用 (同名递归)
  - When: 调用
  - Then: 写入已执行，但事件不再投递（EventBus 阻断）
  - Edge cases: boundary, invalid, missing-data, and repeat-run variants from the GDD edge-case section

---

## Test Evidence

**Story Type**: Integration
**Required evidence**:
- `tests/integration/attribute/edge-cases_test.gd` — must exist and pass

**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: Story 001 must be ready or done for shared test fixtures and baseline APIs
- Unlocks: Story 011
