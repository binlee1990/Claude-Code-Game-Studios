# Story 011: E. 热重载（4 条） 1

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

- [ ] AC-E1a: 参数化测试（CI 可覆盖） — GIVEN debug build（CI 默认），`DataConfig.HOT_RELOAD_ENABLED` 的 2 种取值 `{true, false}`，WHEN 调 `reload()`，THEN：仅 `true` 时实际执行 reload + 发布 `item_registry.reloaded` 事件；`false` 时 `_items` 快照不变、`get_count()` 不变、EventBus 未收到 `item_registry.reloaded`、控制台打印 `"hot reload disabled in DataConfig"` 提示
- [ ] AC-E1b: 手动验证（CI 跳过） — GIVEN release build（`OS.is_debug_build() == false`）的 2 种取值 `{HOT_RELOAD_ENABLED=true, HOT_RELOAD_ENABLED=false}`，WHEN 调 `reload()`，THEN：两种均 no-op，`_items` 快照不变、EventBus 未收到 `item_registry.reloaded`、控制台打印 `"reload disabled in release build"`。**注**：`OS.is_debug_build()` 是引擎静态方法，无法在 GDUnit4 中被 mock；本 AC 需在 `production/qa/evidence/` 记录一次手动验证截图（导出 release build → 启动 → 控制台调 reload → 观察提示 → 确认 _items 不变）。
- [ ] AC-E2: GIVEN `(debug=true, HOT_RELOAD_ENABLED=true)` 条件下（同 AC-E1a true 分支），修改 items.json 添加新 id `"test_new_item"`，调 `reload()` 后，WHEN `has_item("test_new_item")`，THEN `true`

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
- Story 012 covers the next acceptance group in this epic.

---

## QA Test Cases

*Written at story creation. The developer implements against these cases.*

- **Manual check**: AC-E1a: 参数化测试（CI 可覆盖） — GIVEN debug build（CI 默认），`DataConfig.HOT_RELOAD_ENABLED` 的 2 种取值 `{true, false}`，WHEN 调 `reload()`，THEN：仅 `true` 时实际执行 reload + 发布 `item_registry.reloaded` 事件；`false` 时 `_items` 快照不变、`get_count()` 不变、EventBus 未收到 `item_registry.reloaded`、控制台打印 `"hot reload disabled in DataConfig"` 提示
  - Setup: debug build（CI 默认），`DataConfig.HOT_RELOAD_ENABLED` 的 2 种取值 `{true, false}`
  - Verify: 调 `reload()`
  - Pass condition: 仅 `true` 时实际执行 reload + 发布 `item_registry.reloaded` 事件；`false` 时 `_items` 快照不变、`get_count()` 不变、EventBus 未收到 `item_registry.reloaded`、控制台打印 `"hot reload disabled in DataConfig"` 提示

- **Manual check**: AC-E1b: 手动验证（CI 跳过） — GIVEN release build（`OS.is_debug_build() == false`）的 2 种取值 `{HOT_RELOAD_ENABLED=true, HOT_RELOAD_ENABLED=false}`，WHEN 调 `reload()`，THEN：两种均 no-op，`_items` 快照不变、EventBus 未收到 `item_registry.reloaded`、控制台打印 `"reload disabled in release build"`。**注**：`OS.is_debug_build()` 是引擎静态方法，无法在 GDUnit4 中被 mock；本 AC 需在 `production/qa/evidence/` 记录一次手动验证截图（导出 release build → 启动 → 控制台调 reload → 观察提示 → 确认 _items 不变）。
  - Setup: release build（`OS.is_debug_build() == false`）的 2 种取值 `{HOT_RELOAD_ENABLED=true, HOT_RELOAD_ENABLED=false}`
  - Verify: 调 `reload()`
  - Pass condition: 两种均 no-op，`_items` 快照不变、EventBus 未收到 `item_registry.reloaded`、控制台打印 `"reload disabled in release build"`。注：`OS.is_debug_build()` 是引擎静态方法，无法在 GDUnit4 中被 mock；本 AC 需在 `production/qa/evidence/` 记录一次手动验证截图（导出 release build → 启动 → 控制台调 reload → 观察提示 → 确认 _items 不变）

- **Manual check**: AC-E2: GIVEN `(debug=true, HOT_RELOAD_ENABLED=true)` 条件下（同 AC-E1a true 分支），修改 items.json 添加新 id `"test_new_item"`，调 `reload()` 后，WHEN `has_item("test_new_item")`，THEN `true`
  - Setup: `(debug=true, HOT_RELOAD_ENABLED=true)` 条件下（同 AC-E1a true 分支），修改 items.json 添加新 id `"test_new_item"`，调 `reload()` 后
  - Verify: `has_item("test_new_item")`
  - Pass condition: `true`

---

## Test Evidence

**Story Type**: UI
**Required evidence**:
- `production/qa/evidence/e-4-1-evidence.md` — manual/interaction evidence with sign-off

**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: Story 001 must be ready or done for shared test fixtures and baseline APIs
- Unlocks: Story 012
