# Sprint 6 QA Plan

## Scope
- AttributeSystem: batch set, snapshot/restore, edge cases, restore event suppression, performance/memory contracts.
- ItemRegistry: DataConfig-backed item metadata load, query API, copy-safety, hot reload guardrails, lifecycle events.

## Automated Evidence
- `tests/unit/attribute_system/attribute_system_batch_snapshot_test.gd`
- `tests/unit/item_registry/item_registry_load_test.gd`
- `tests/unit/item_registry/item_registry_query_test.gd`
- `tests/integration/item_registry/item_registry_lifecycle_test.gd`
- `tests/performance/item_registry_performance_test.gd`

## 2026-05-04 执行记录

- Godot CLI 已通过 Steam 安装路径执行：`G:\SteamLibrary\steamapps\common\Godot Engine\godot.windows.opt.tools.64.exe`。
- 本 sprint 已按 story 顺序执行并关闭 20 个 story。
- `reports/report_13/results.xml`：137 个测试，0 个失败，0 个跳过，0 个 flaky。
- Sprint 6 gate 证据：`production/qa/evidence/sprint-6-qa-result-2026-05-04.md`。

## Static Gates
- `project.godot` autoload order includes DataConfigHost before ItemRegistryHost.
- `assets/data/items.json` parses as JSON and contains the 5 MVP item ids: `lingqi`, `xiuwei`, `lingshi`, `herb`, `exp`.
- No deprecated Godot 3 tokens: `yield(`, `OS.get_ticks_msec(`, `connect("`.

## Manual / Runtime Evidence
- Godot/GdUnit runtime execution is required for real timing, memory, and EventBus lifecycle proof.
- 本轮已通过本机 Godot 4.6.2 CLI 完成 runtime 证据，不再因 PATH 未配置而阻塞。

## Risks
- Autoload singleton is named `ItemRegistryHost` to match existing Host-suffix project convention and avoid a `class_name ItemRegistry` singleton name collision.
- `peek_field()` intentionally exposes container fields by reference per GDD contract; callers must use `get(id)` or duplicate containers before mutation.
