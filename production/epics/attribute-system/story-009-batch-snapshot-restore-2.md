# Story 009: Batch / Snapshot / Restore 2

> **Epic**: 属性系统
> **Status**: Ready
> **Layer**: Core Gameplay
> **Type**: UI
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

- [ ] GIVEN: snapshot 数据中某 BigNumber 字典缺 `"e"` 字段（损坏），**WHEN** `restore`，**THEN** 该属性 base = ZERO，打印警告，不崩溃
- [ ] GIVEN: `restore(data)` 写入 100 条属性，**WHEN** `SUPPRESS_RESTORE_EVENTS=true`，**THEN** 期间 EventBus 不发布任何 `base_changed` 事件
- [ ] GIVEN: `"enemy_yougui_a_session1234"`（临时实体）已注册，**WHEN** `snapshot()`，**THEN** 返回 Dictionary 包含此 entity（**不主动过滤**）；调用方（存档系统）负责过滤

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

- **Manual check**: GIVEN: snapshot 数据中某 BigNumber 字典缺 `"e"` 字段（损坏），**WHEN** `restore`，**THEN** 该属性 base = ZERO，打印警告，不崩溃
  - Setup: snapshot 数据中某 BigNumber 字典缺 `"e"` 字段（损坏）
  - Verify: `restore`
  - Pass condition: 该属性 base = ZERO，打印警告，不崩溃

- **Manual check**: GIVEN: `restore(data)` 写入 100 条属性，**WHEN** `SUPPRESS_RESTORE_EVENTS=true`，**THEN** 期间 EventBus 不发布任何 `base_changed` 事件
  - Setup: `restore(data)` 写入 100 条属性
  - Verify: `SUPPRESS_RESTORE_EVENTS=true`
  - Pass condition: 期间 EventBus 不发布任何 `base_changed` 事件

- **Manual check**: GIVEN: `"enemy_yougui_a_session1234"`（临时实体）已注册，**WHEN** `snapshot()`，**THEN** 返回 Dictionary 包含此 entity（**不主动过滤**）；调用方（存档系统）负责过滤
  - Setup: `"enemy_yougui_a_session1234"`（临时实体）已注册
  - Verify: `snapshot()`
  - Pass condition: 返回 Dictionary 包含此 entity（不主动过滤）；调用方（存档系统）负责过滤

---

## Test Evidence

**Story Type**: UI
**Required evidence**:
- `production/qa/evidence/batch-snapshot-restore-2-evidence.md` — manual/interaction evidence with sign-off

**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: Story 001 must be ready or done for shared test fixtures and baseline APIs
- Unlocks: Story 010
