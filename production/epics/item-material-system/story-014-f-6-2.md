# Story 014: F. 性能（6 条） 2

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

- [ ] AC-F4: Alpha 规模性能门槛 — GIVEN mock items 含 N=500 条记录（其中 50 条 item_class="resource_material"），WHEN 单次执行 `query_by_item_class("resource_material")`，THEN 单次耗时 < 2.5 ms（公式 3a 典型值上界）。**MVP 实施时此 AC 可标 `@tag("alpha_perf")` 跳过，Alpha 数据集准备完毕后启用**
- [ ] AC-F5: Alpha 倒排索引门槛 — GIVEN mock items 含 N=500 条记录（每条 tags 平均 5 项，匹配 50 条），WHEN 单次执行 `query_by_tag("low_tier")`，THEN 单次耗时 < 5 ms（暗示已实现倒排索引）。**MVP 实施时此 AC 可标 `@tag("alpha_perf")` 跳过；Alpha 数据集启用后若该 AC 失败则要求实现倒排索引（详见 §Tuning Knobs `INVERTED_INDEX_THRESHOLD`）**
- [ ] AC-F6: `get_all_ids()` 调用约束（契约 AC，非运行时检测） — **注**：GDScript 无运行时调用栈自省 API（无 `get_stack()` 等），无法在 ItemRegistry 内部检测调用者是否在 `_process` 中。本 AC 验证的是代码约定而非运行时行为：① API doc-comment 中明确写有 "不得在 `_process` / `_physics_process` 内调用此方法，应在 `item_registry.loaded` 事件回调中缓存结果"；② code-review checklist（见 AC-C3 的 checklist）中包含 "所有 `get_all_ids()` 调用点是否出现在 `_process` / `_physics_process` 中" 检查项。**Alpha 扩展**（N > INVERTED_INDEX_THRESHOLD 时）：ItemRegistry 内部维护 `_get_all_ids_last_frame: int` 帧计数器，若同一帧内被重复调用且 N > THRESHOLD 则 `push_warning` 提示缓存（仅检测重复调用频率，不检测调用栈）

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
- Story 015 covers the next acceptance group in this epic.

---

## QA Test Cases

*Written at story creation. The developer implements against these cases.*

- **AC**: AC-F4: Alpha 规模性能门槛 — GIVEN mock items 含 N=500 条记录（其中 50 条 item_class="resource_material"），WHEN 单次执行 `query_by_item_class("resource_material")`，THEN 单次耗时 < 2.5 ms（公式 3a 典型值上界）。**MVP 实施时此 AC 可标 `@tag("alpha_perf")` 跳过，Alpha 数据集准备完毕后启用**
  - Given: mock items 含 N=500 条记录（其中 50 条 item_class="resource_material"）
  - When: 单次执行 `query_by_item_class("resource_material")`
  - Then: 单次耗时 < 2.5 ms（公式 3a 典型值上界）。MVP 实施时此 AC 可标 `@tag("alpha_perf")` 跳过，Alpha 数据集准备完毕后启用
  - Edge cases: boundary, invalid, missing-data, and repeat-run variants from the GDD edge-case section

- **AC**: AC-F5: Alpha 倒排索引门槛 — GIVEN mock items 含 N=500 条记录（每条 tags 平均 5 项，匹配 50 条），WHEN 单次执行 `query_by_tag("low_tier")`，THEN 单次耗时 < 5 ms（暗示已实现倒排索引）。**MVP 实施时此 AC 可标 `@tag("alpha_perf")` 跳过；Alpha 数据集启用后若该 AC 失败则要求实现倒排索引（详见 §Tuning Knobs `INVERTED_INDEX_THRESHOLD`）**
  - Given: mock items 含 N=500 条记录（每条 tags 平均 5 项，匹配 50 条）
  - When: 单次执行 `query_by_tag("low_tier")`
  - Then: 单次耗时 < 5 ms（暗示已实现倒排索引）。MVP 实施时此 AC 可标 `@tag("alpha_perf")` 跳过；Alpha 数据集启用后若该 AC 失败则要求实现倒排索引（详见 §Tuning Knobs `INVERTED_INDEX_THRESHOLD`）
  - Edge cases: boundary, invalid, missing-data, and repeat-run variants from the GDD edge-case section

- **AC**: AC-F6: `get_all_ids()` 调用约束（契约 AC，非运行时检测） — **注**：GDScript 无运行时调用栈自省 API（无 `get_stack()` 等），无法在 ItemRegistry 内部检测调用者是否在 `_process` 中。本 AC 验证的是代码约定而非运行时行为：① API doc-comment 中明确写有 "不得在 `_process` / `_physics_process` 内调用此方法，应在 `item_registry.loaded` 事件回调中缓存结果"；② code-review checklist（见 AC-C3 的 checklist）中包含 "所有 `get_all_ids()` 调用点是否出现在 `_process` / `_physics_process` 中" 检查项。**Alpha 扩展**（N > INVERTED_INDEX_THRESHOLD 时）：ItemRegistry 内部维护 `_get_all_ids_last_frame: int` 帧计数器，若同一帧内被重复调用且 N > THRESHOLD 则 `push_warning` 提示缓存（仅检测重复调用频率，不检测调用栈）
  - Given: the story preconditions from the linked GDD are set up
  - When: the behavior under this acceptance criterion is exercised
  - Then: AC-F6: `get_all_ids()` 调用约束（契约 AC，非运行时检测） — **注**：GDScript 无运行时调用栈自省 API（无 `get_stack()` 等），无法在 ItemRegistry 内部检测调用者是否在 `_process` 中。本 AC 验证的是代码约定而非运行时行为：① API doc-comment 中明确写有 "不得在 `_process` / `_physics_process` 内调用此方法，应在 `item_registry.loaded` 事件回调中缓存结果"；② code-review checklist（见 AC-C3 的 checklist）中包含 "所有 `get_all_ids()` 调用点是否出现在 `_process` / `_physics_process` 中" 检查项。**Alpha 扩展**（N > INVERTED_INDEX_THRESHOLD 时）：ItemRegistry 内部维护 `_get_all_ids_last_frame: int` 帧计数器，若同一帧内被重复调用且 N > THRESHOLD 则 `push_warning` 提示缓存（仅检测重复调用频率，不检测调用栈）
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
- Unlocks: Story 015
