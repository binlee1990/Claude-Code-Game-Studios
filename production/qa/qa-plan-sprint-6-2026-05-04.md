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

## Static Gates
- `project.godot` autoload order includes DataConfigHost before ItemRegistryHost.
- `assets/data/items.json` parses as JSON and contains the 5 MVP item ids: `lingqi`, `xiuwei`, `lingshi`, `herb`, `exp`.
- No deprecated Godot 3 tokens: `yield(`, `OS.get_ticks_msec(`, `connect("`.

## Manual / Blocked Evidence
- Godot/GdUnit runtime execution is required for real timing, memory, and EventBus lifecycle proof.
- Current environment has no Godot CLI in PATH, so runtime pass/fail remains blocked until the engine is installed.

## Risks
- Autoload singleton is named `ItemRegistryHost` to match existing Host-suffix project convention and avoid a `class_name ItemRegistry` singleton name collision.
- `peek_field()` intentionally exposes container fields by reference per GDD contract; callers must use `get(id)` or duplicate containers before mutation.
