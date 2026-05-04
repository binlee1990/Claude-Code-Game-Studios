# Story 001: Core CRUD 1

> **Epic**: 资源系统
> **Status**: Ready
> **Layer**: Core Gameplay
> **Type**: Config/Data
> **Manifest Version**: 2026-05-04

## Context

**GDD**: `design/gdd/resource-system.md`
**Requirement**: `TR-resource-system-001` — ResourceSystem owns resource CRUD, BigNumber balances, caps, overflow events, reset scopes, batch_add, snapshot, and restore.

**ADR Governing Implementation**: ADR-0010: ResourceSystem 不可变 BigNumber 策略
**ADR Decision Summary**: ResourceSystem stores BigNumber values as immutable value objects. Operations calculate new BigNumber instances and replace the stored value. `add()` returns the actual added amount. `spend()` is atomic per resource. `batch_add()` executes sequential per-resource adds and returns a dictionary of actual additions; it does not roll back earlier successful changes.

**Engine**: Godot 4.6.2 | **Risk**: LOW
**Engine Notes**: ADR-0010 status is Accepted; verify any Godot 4.6.2 behavior named by the ADR before closing the story.

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

- [ ] GIVEN: `ResourceSystem` 已加载，`resource_config.json` 包含 `lingqi/xiuwei/lingshi/herb/exp` 五条定义，**WHEN** 游戏启动完成，**THEN** `get_all_ids()` 返回恰好包含这 5 个 id 的 Array，且每条资源 `current == BigNumber.ZERO`
- [ ] GIVEN: 调用 `register({id: "lingqi", category: "regenerative", has_cap: true, reset_scope: "breakthrough", cap: BigNumber.from_int(1000)})` 成功，**WHEN** 再次调用相同 id 的 register，**THEN** 返回 `false`，已有条目不变
- [ ] GIVEN: `lingqi` current=`BigNumber.from_int(800)`，cap=`BigNumber.from_int(1000)`，**WHEN** `add("lingqi", BigNumber.from_int(150))`，**THEN** 返回 `BigNumber.from_int(150)`，`get_value("lingqi") == BigNumber.from_int(950)`

---

## Implementation Notes

*Derived from ADR-0010 Implementation Guidelines:*

- Must store resource values as `BigNumber`.
- Must replace stored values with newly calculated BigNumber instances.
- Must not mutate BigNumber instances in place.
- Must keep ResourceSystem limited to resource CRUD, caps, reset, events, and snapshot/restore.
- Must not include production, multiplier, loot, level, or economy business logic.
- Must emit `resource.{id}.changed` only when actual value changes.

---

## Out of Scope

- Story 002 covers the next acceptance group in this epic.

---

## QA Test Cases

*Written at story creation. The developer implements against these cases.*

- **AC**: GIVEN: `ResourceSystem` 已加载，`resource_config.json` 包含 `lingqi/xiuwei/lingshi/herb/exp` 五条定义，**WHEN** 游戏启动完成，**THEN** `get_all_ids()` 返回恰好包含这 5 个 id 的 Array，且每条资源 `current == BigNumber.ZERO`
  - Given: `ResourceSystem` 已加载，`resource_config.json` 包含 `lingqi/xiuwei/lingshi/herb/exp` 五条定义
  - When: 游戏启动完成
  - Then: `get_all_ids()` 返回恰好包含这 5 个 id 的 Array，且每条资源 `current == BigNumber.ZERO`
  - Edge cases: boundary, invalid, missing-data, and repeat-run variants from the GDD edge-case section

- **AC**: GIVEN: 调用 `register({id: "lingqi", category: "regenerative", has_cap: true, reset_scope: "breakthrough", cap: BigNumber.from_int(1000)})` 成功，**WHEN** 再次调用相同 id 的 register，**THEN** 返回 `false`，已有条目不变
  - Given: 调用 `register({id: "lingqi", category: "regenerative", has_cap: true, reset_scope: "breakthrough", cap: BigNumber.from_int(1000)})` 成功
  - When: 再次调用相同 id 的 register
  - Then: 返回 `false`，已有条目不变
  - Edge cases: boundary, invalid, missing-data, and repeat-run variants from the GDD edge-case section

- **AC**: GIVEN: `lingqi` current=`BigNumber.from_int(800)`，cap=`BigNumber.from_int(1000)`，**WHEN** `add("lingqi", BigNumber.from_int(150))`，**THEN** 返回 `BigNumber.from_int(150)`，`get_value("lingqi") == BigNumber.from_int(950)`
  - Given: `lingqi` current=`BigNumber.from_int(800)`，cap=`BigNumber.from_int(1000)`
  - When: `add("lingqi", BigNumber.from_int(150))`
  - Then: 返回 `BigNumber.from_int(150)`，`get_value("lingqi") == BigNumber.from_int(950)`
  - Edge cases: boundary, invalid, missing-data, and repeat-run variants from the GDD edge-case section

---

## Test Evidence

**Story Type**: Config/Data
**Required evidence**:
- `production/qa/smoke-resource-system.md` — smoke check evidence

**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: None
- Unlocks: Story 002
