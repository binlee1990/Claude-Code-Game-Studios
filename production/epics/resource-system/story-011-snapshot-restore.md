# Story 011: Snapshot / Restore

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

- [ ] GIVEN: `lingqi` current=500/cap=1000；`lingshi` current=2000（has_cap=false），**WHEN** `snapshot()`，**THEN** 返回 `{version:1, resources: {lingqi:{current:{...},cap:{...}}, ...}}` 可被 `BigNumber.from_dict` 还原
- [ ] GIVEN: snapshot 数据中 `lingqi.cap=1000, lingqi.current=800`，初始注册 cap=500，**WHEN** `restore(data)`，**THEN** `get_max==1000` 且 `get_value==800`（验证 set_max 在 set_value 之前执行——否则 current 会被旧 cap 500 截断）
- [ ] GIVEN: `restore(data)` 含未在配置中的 id `"ancient_ore"`，**WHEN** 调用，**THEN** 跳过该条目并打印警告，其他 5 资源正常恢复，不崩溃
- [ ] GIVEN: `restore(data)` 中 `herb.current` 缺少 `"e"` 字段（存档损坏），**WHEN** 调用，**THEN** `get_value("herb")==ZERO`，打印警告，不崩溃

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

- Story 001 covers the baseline contract for this epic; do not duplicate its setup work here.
- Story 012 covers the next acceptance group in this epic.

---

## QA Test Cases

*Written at story creation. The developer implements against these cases.*

- **AC**: GIVEN: `lingqi` current=500/cap=1000；`lingshi` current=2000（has_cap=false），**WHEN** `snapshot()`，**THEN** 返回 `{version:1, resources: {lingqi:{current:{...},cap:{...}}, ...}}` 可被 `BigNumber.from_dict` 还原
  - Given: `lingqi` current=500/cap=1000；`lingshi` current=2000（has_cap=false）
  - When: `snapshot()`
  - Then: 返回 `{version:1, resources: {lingqi:{current:{...},cap:{...}}, ...}}` 可被 `BigNumber.from_dict` 还原
  - Edge cases: boundary, invalid, missing-data, and repeat-run variants from the GDD edge-case section

- **AC**: GIVEN: snapshot 数据中 `lingqi.cap=1000, lingqi.current=800`，初始注册 cap=500，**WHEN** `restore(data)`，**THEN** `get_max==1000` 且 `get_value==800`（验证 set_max 在 set_value 之前执行——否则 current 会被旧 cap 500 截断）
  - Given: snapshot 数据中 `lingqi.cap=1000, lingqi.current=800`，初始注册 cap=500
  - When: `restore(data)`
  - Then: `get_max==1000` 且 `get_value==800`（验证 set_max 在 set_value 之前执行——否则 current 会被旧 cap 500 截断）
  - Edge cases: boundary, invalid, missing-data, and repeat-run variants from the GDD edge-case section

- **AC**: GIVEN: `restore(data)` 含未在配置中的 id `"ancient_ore"`，**WHEN** 调用，**THEN** 跳过该条目并打印警告，其他 5 资源正常恢复，不崩溃
  - Given: `restore(data)` 含未在配置中的 id `"ancient_ore"`
  - When: 调用
  - Then: 跳过该条目并打印警告，其他 5 资源正常恢复，不崩溃
  - Edge cases: boundary, invalid, missing-data, and repeat-run variants from the GDD edge-case section

- **AC**: GIVEN: `restore(data)` 中 `herb.current` 缺少 `"e"` 字段（存档损坏），**WHEN** 调用，**THEN** `get_value("herb")==ZERO`，打印警告，不崩溃
  - Given: `restore(data)` 中 `herb.current` 缺少 `"e"` 字段（存档损坏）
  - When: 调用
  - Then: `get_value("herb")==ZERO`，打印警告，不崩溃
  - Edge cases: boundary, invalid, missing-data, and repeat-run variants from the GDD edge-case section

---

## Test Evidence

**Story Type**: Config/Data
**Required evidence**:
- `production/qa/smoke-resource-system.md` — smoke check evidence

**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: Story 001 must be ready or done for shared test fixtures and baseline APIs
- Unlocks: Story 012
