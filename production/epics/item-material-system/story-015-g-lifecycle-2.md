# Story 015: G. Lifecycle 事件（2 条）

> **Epic**: 物品/材料系统
> **Status**: Ready
> **Layer**: Core Gameplay
> **Type**: Config/Data
> **Manifest Version**: 2026-05-04

## Context

**GDD**: `design/gdd/item-material-system.md`
**Requirement**: `TR-item-material-001` — ItemRegistry loads immutable item/material definitions from DataConfig and exposes query-only metadata APIs.

**ADR Governing Implementation**: ADR-0005: 数据配置加载策略
**ADR Decision Summary**: Implement `DataConfig` as a `RefCounted` service held by an Autoload host. It scans JSON files under `res://assets/data/`, parses them with Godot JSON APIs, stores raw dictionaries in memory, and returns raw values to consumers. BigNumber conversion is performed by consumers according to their schemas.

**Engine**: Godot 4.6.2 | **Risk**: MEDIUM
**Engine Notes**: ADR-0005 status is Accepted; verify any Godot 4.6.2 behavior named by the ADR before closing the story.

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

*From GDD `design/gdd/item-material-system.md`, scoped to this story:*

- [ ] AC-G1: GIVEN ItemRegistry 启动加载成功（`get_count() > 0`，含 5 条 resource_material + 1 条 `item_class="unknown_cat"` 被 AC-A4 跳过），WHEN `_ready()` 完成，THEN EventBus 收到一次 `item_registry.loaded` 事件，payload 严格符合 schema `{count: int, item_classes: Dictionary[String, int]}`：① `count == get_count() == 5`（不含被跳过的记录）；② `item_classes.keys()` 仅含 4 元锁定枚举内的值；③ `item_classes["resource_material"] == 5`；④ 所有未出现 item_class 的 key 不在 `item_classes` 中（即 keys.size() == 实际加载的 distinct item_class 数）；⑤ `item_classes` **不包含** `"unknown_cat"` key（被拒绝记录的 item_class 不出现）。事件**同步发布**（不使用 `call_deferred` / `await`，确保订阅者在第 1 帧结束前可处理）
- [ ] AC-G2: GIVEN AC-E1 的 reload 实际执行路径，WHEN reload 完成，THEN EventBus 收到一次 `item_registry.reloaded` 事件

---

## Implementation Notes

*Derived from ADR-0005 Implementation Guidelines:*

- Must use JSON files in `res://assets/data/` for MVP configuration.
- Must not use Godot Resource files as the MVP content format.
- Must keep DataConfig schema-agnostic; consumers parse BigNumber strings themselves.
- Must keep all loaded tables in memory for MVP.
- Must allow one failed table to degrade to an empty table without stopping other tables.
- Must restrict `reload_table` and `reload_all` to debug builds.

---

## Out of Scope

- Story 001 covers the baseline contract for this epic; do not duplicate its setup work here.
- Story 016 covers the next acceptance group in this epic.

---

## QA Test Cases

*Written at story creation. The developer implements against these cases.*

- **AC**: AC-G1: GIVEN ItemRegistry 启动加载成功（`get_count() > 0`，含 5 条 resource_material + 1 条 `item_class="unknown_cat"` 被 AC-A4 跳过），WHEN `_ready()` 完成，THEN EventBus 收到一次 `item_registry.loaded` 事件，payload 严格符合 schema `{count: int, item_classes: Dictionary[String, int]}`：① `count == get_count() == 5`（不含被跳过的记录）；② `item_classes.keys()` 仅含 4 元锁定枚举内的值；③ `item_classes["resource_material"] == 5`；④ 所有未出现 item_class 的 key 不在 `item_classes` 中（即 keys.size() == 实际加载的 distinct item_class 数）；⑤ `item_classes` **不包含** `"unknown_cat"` key（被拒绝记录的 item_class 不出现）。事件**同步发布**（不使用 `call_deferred` / `await`，确保订阅者在第 1 帧结束前可处理）
  - Given: ItemRegistry 启动加载成功（`get_count() > 0`，含 5 条 resource_material + 1 条 `item_class="unknown_cat"` 被 AC-A4 跳过）
  - When: `_ready()` 完成
  - Then: EventBus 收到一次 `item_registry.loaded` 事件，payload 严格符合 schema `{count: int, item_classes: Dictionary[String, int]}`：① `count == get_count() == 5`（不含被跳过的记录）；② `item_classes.keys()` 仅含 4 元锁定枚举内的值；③ `item_classes["resource_material"] == 5`；④ 所有未出现 item_class 的 key 不在 `item_classes` 中（即 keys.size() == 实际加载的 distinct item_class 数）；⑤ `item_classes` 不包含 `"unknown_cat"` key（被拒绝记录的 item_class 不出现）。事件同步发布（不使用 `call_deferred` / `await`，确保订阅者在第 1 帧结束前可处理）
  - Edge cases: boundary, invalid, missing-data, and repeat-run variants from the GDD edge-case section

- **AC**: AC-G2: GIVEN AC-E1 的 reload 实际执行路径，WHEN reload 完成，THEN EventBus 收到一次 `item_registry.reloaded` 事件
  - Given: AC-E1 的 reload 实际执行路径
  - When: reload 完成
  - Then: EventBus 收到一次 `item_registry.reloaded` 事件
  - Edge cases: boundary, invalid, missing-data, and repeat-run variants from the GDD edge-case section

---

## Test Evidence

**Story Type**: Config/Data
**Required evidence**:
- `production/qa/smoke-item-material-system.md` — smoke check evidence

**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: Story 001 must be ready or done for shared test fixtures and baseline APIs
- Unlocks: Story 016
