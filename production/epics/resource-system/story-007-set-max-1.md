# Story 007: set_max 1

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

- [ ] GIVEN: `lingqi` cap=1000, current=600，**WHEN** `set_max("lingqi", BigNumber.from_int(2000))`，**THEN** `get_max==2000`，`get_value` 不变，仅发布 `cap_changed`，不发布 `changed/overflow`
- [ ] GIVEN: `lingqi` cap=1000, current=800，**WHEN** `set_max("lingqi", BigNumber.from_int(500))`，**THEN** `get_value==500`，事件顺序严格为 ① `cap_changed` → ② `changed` → ③ `overflow`（lost=300）
- [ ] GIVEN: `lingqi` cap=1000，**WHEN** `set_max("lingqi", BigNumber.from_int(1000))`（与现 cap 相同），**THEN** EventBus 不发布任何事件，调用静默 no-op

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

- **AC**: GIVEN: `lingqi` cap=1000, current=600，**WHEN** `set_max("lingqi", BigNumber.from_int(2000))`，**THEN** `get_max==2000`，`get_value` 不变，仅发布 `cap_changed`，不发布 `changed/overflow`
  - Given: `lingqi` cap=1000, current=600
  - When: `set_max("lingqi", BigNumber.from_int(2000))`
  - Then: `get_max==2000`，`get_value` 不变，仅发布 `cap_changed`，不发布 `changed/overflow`
  - Edge cases: boundary, invalid, missing-data, and repeat-run variants from the GDD edge-case section

- **AC**: GIVEN: `lingqi` cap=1000, current=800，**WHEN** `set_max("lingqi", BigNumber.from_int(500))`，**THEN** `get_value==500`，事件顺序严格为 ① `cap_changed` → ② `changed` → ③ `overflow`（lost=300）
  - Given: `lingqi` cap=1000, current=800
  - When: `set_max("lingqi", BigNumber.from_int(500))`
  - Then: `get_value==500`，事件顺序严格为 ① `cap_changed` → ② `changed` → ③ `overflow`（lost=300）
  - Edge cases: boundary, invalid, missing-data, and repeat-run variants from the GDD edge-case section

- **AC**: GIVEN: `lingqi` cap=1000，**WHEN** `set_max("lingqi", BigNumber.from_int(1000))`（与现 cap 相同），**THEN** EventBus 不发布任何事件，调用静默 no-op
  - Given: `lingqi` cap=1000
  - When: `set_max("lingqi", BigNumber.from_int(1000))`（与现 cap 相同）
  - Then: EventBus 不发布任何事件，调用静默 no-op
  - Edge cases: boundary, invalid, missing-data, and repeat-run variants from the GDD edge-case section

---

## Test Evidence

**Story Type**: Integration
**Required evidence**:
- `tests/integration/resource/set-max-1_test.gd` — must exist and pass

**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: Story 001 must be ready or done for shared test fixtures and baseline APIs
- Unlocks: Story 008
