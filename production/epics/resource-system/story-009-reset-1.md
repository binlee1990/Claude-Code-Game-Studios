# Story 009: Reset 1

> **Epic**: 资源系统
> **Status**: Ready
> **Layer**: Core Gameplay
> **Type**: Integration
> **Manifest Version**: 2026-05-04

## Context

**GDD**: `design/gdd/resource-system.md`
**Requirement**: `TR-resource-system-001` — ResourceSystem owns resource CRUD, BigNumber balances, caps, overflow events, reset scopes, batch_add, snapshot, and restore.

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

*From GDD `design/gdd/resource-system.md`, scoped to this story:*

- [ ] GIVEN: MVP 5 资源均有非零 current，**WHEN** `reset_by_scope("breakthrough")`，**THEN** 返回 3（lingqi/xiuwei/exp 被重置；reset_scope=breakthrough 的全部 3 项），`lingshi/herb` 不变
- [ ] GIVEN: MVP 5 资源均有非零 current，**WHEN** `reset_by_scope("rebirth")`，**THEN** 返回 5，所有资源 current==ZERO，同帧投递 5 次 `changed` 事件，总耗时 < 0.333 ms
- [ ] GIVEN: 任意状态，**WHEN** `reset_by_scope("none")`，**THEN** 返回 0，所有 current 不变，不发布事件

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

- **AC**: GIVEN: MVP 5 资源均有非零 current，**WHEN** `reset_by_scope("breakthrough")`，**THEN** 返回 3（lingqi/xiuwei/exp 被重置；reset_scope=breakthrough 的全部 3 项），`lingshi/herb` 不变
  - Given: MVP 5 资源均有非零 current
  - When: `reset_by_scope("breakthrough")`
  - Then: 返回 3（lingqi/xiuwei/exp 被重置；reset_scope=breakthrough 的全部 3 项），`lingshi/herb` 不变
  - Edge cases: boundary, invalid, missing-data, and repeat-run variants from the GDD edge-case section

- **AC**: GIVEN: MVP 5 资源均有非零 current，**WHEN** `reset_by_scope("rebirth")`，**THEN** 返回 5，所有资源 current==ZERO，同帧投递 5 次 `changed` 事件，总耗时 < 0.333 ms
  - Given: MVP 5 资源均有非零 current
  - When: `reset_by_scope("rebirth")`
  - Then: 返回 5，所有资源 current==ZERO，同帧投递 5 次 `changed` 事件，总耗时 < 0.333 ms
  - Edge cases: boundary, invalid, missing-data, and repeat-run variants from the GDD edge-case section

- **AC**: GIVEN: 任意状态，**WHEN** `reset_by_scope("none")`，**THEN** 返回 0，所有 current 不变，不发布事件
  - Given: 任意状态
  - When: `reset_by_scope("none")`
  - Then: 返回 0，所有 current 不变，不发布事件
  - Edge cases: boundary, invalid, missing-data, and repeat-run variants from the GDD edge-case section

---

## Test Evidence

**Story Type**: Integration
**Required evidence**:
- `tests/integration/resource/reset-1_test.gd` — must exist and pass

**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: Story 001 must be ready or done for shared test fixtures and baseline APIs
- Unlocks: Story 010
