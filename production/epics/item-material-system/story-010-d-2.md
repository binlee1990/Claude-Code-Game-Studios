# Story 010: D. 启动时序（2 条）

> **Epic**: 物品/材料系统
> **Status**: Ready
> **Layer**: Core Gameplay
> **Type**: UI
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

- [ ] AC-D1: GIVEN ItemRegistry 实例已创建，通过 `set_data_config(null)` 注入空依赖（模拟 DataConfig Autoload 缺失/被禁用，**避免 mutate `project.godot`——CI 不支持**），WHEN 触发 `_initialize()` / `_ready()` 重入路径，THEN `push_error("ItemRegistry: DataConfig autoload missing or unavailable; falling back to empty registry")` 被触发 + `_items=={}` + `get_count()==0` + 所有查询返回零值，游戏不崩溃，控制台错误便于定位 Autoload 配置问题。**注**：Autoload 顺序的实际验证属于集成 playtest，应在 `production/qa/evidence/` 记录一次手动测试截图（修改 project.godot → 启动 → 观察控制台报错 → 恢复 project.godot），不要求 CI 自动覆盖
- [ ] AC-D2: GIVEN ItemRegistry 尚未发布 `item_registry.loaded` 事件，WHEN 任意外部代码调 `get(id)`/`peek_field(id, ..)`，THEN 返回零值（`{}` / `null`），不崩溃。GDD 要求依赖 metadata 显示的下游应等待事件后再渲染（避免空名 UI 漏洞）

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
- Story 011 covers the next acceptance group in this epic.

---

## QA Test Cases

*Written at story creation. The developer implements against these cases.*

- **Manual check**: AC-D1: GIVEN ItemRegistry 实例已创建，通过 `set_data_config(null)` 注入空依赖（模拟 DataConfig Autoload 缺失/被禁用，**避免 mutate `project.godot`——CI 不支持**），WHEN 触发 `_initialize()` / `_ready()` 重入路径，THEN `push_error("ItemRegistry: DataConfig autoload missing or unavailable; falling back to empty registry")` 被触发 + `_items=={}` + `get_count()==0` + 所有查询返回零值，游戏不崩溃，控制台错误便于定位 Autoload 配置问题。**注**：Autoload 顺序的实际验证属于集成 playtest，应在 `production/qa/evidence/` 记录一次手动测试截图（修改 project.godot → 启动 → 观察控制台报错 → 恢复 project.godot），不要求 CI 自动覆盖
  - Setup: ItemRegistry 实例已创建，通过 `set_data_config(null)` 注入空依赖（模拟 DataConfig Autoload 缺失/被禁用，避免 mutate `project.godot`——CI 不支持）
  - Verify: 触发 `_initialize()` / `_ready()` 重入路径
  - Pass condition: `push_error("ItemRegistry: DataConfig autoload missing or unavailable; falling back to empty registry")` 被触发 + `_items=={}` + `get_count()==0` + 所有查询返回零值，游戏不崩溃，控制台错误便于定位 Autoload 配置问题。注：Autoload 顺序的实际验证属于集成 playtest，应在 `production/qa/evidence/` 记录一次手动测试截图（修改 project.godot → 启动 → 观察控制台报错 → 恢复 project.godot），不要求 CI 自动覆盖

- **Manual check**: AC-D2: GIVEN ItemRegistry 尚未发布 `item_registry.loaded` 事件，WHEN 任意外部代码调 `get(id)`/`peek_field(id, ..)`，THEN 返回零值（`{}` / `null`），不崩溃。GDD 要求依赖 metadata 显示的下游应等待事件后再渲染（避免空名 UI 漏洞）
  - Setup: ItemRegistry 尚未发布 `item_registry.loaded` 事件
  - Verify: 任意外部代码调 `get(id)`/`peek_field(id, ..)`
  - Pass condition: 返回零值（`{}` / `null`），不崩溃。GDD 要求依赖 metadata 显示的下游应等待事件后再渲染（避免空名 UI 漏洞）

---

## Test Evidence

**Story Type**: UI
**Required evidence**:
- `production/qa/evidence/d-2-evidence.md` — manual/interaction evidence with sign-off

**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: Story 001 must be ready or done for shared test fixtures and baseline APIs
- Unlocks: Story 011
