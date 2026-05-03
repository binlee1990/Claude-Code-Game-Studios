# ADR-0005: 数据配置加载策略

## Status
Accepted

## Date
2026-05-04

## Engine Compatibility

| Field | Value |
|-------|-------|
| **Engine** | Godot 4.6.2 |
| **Domain** | Core / FileAccess / JSON |
| **Knowledge Risk** | MEDIUM — FileAccess has post-cutoff return-type changes in 4.4, but this ADR mostly reads files |
| **References Consulted** | `docs/engine-reference/godot/VERSION.md`, `docs/engine-reference/godot/breaking-changes.md`, `docs/engine-reference/godot/deprecated-apis.md`, `design/gdd/data-config-system.md` |
| **Post-Cutoff APIs Used** | `FileAccess.store_*` return type note is relevant to adjacent save code; DataConfig uses `FileAccess.open()` and `JSON.parse_string()` |
| **Verification Required** | JSON load, parse-failure fallback, missing table/record behavior, debug hot reload, and load-time/memory budgets |

## ADR Dependencies

| Field | Value |
|-------|-------|
| **Depends On** | None |
| **Enables** | ADR-0006, ADR-0008, ADR-0010, ADR-0013 |
| **Blocks** | Enemy, item, zone, formula, production, and balance data consumers |
| **Ordering Note** | DataConfigHost must initialize before static-data consumers such as ItemRegistry, EnemyDatabase, and ZoneSystem |

## Context

### Problem Statement

The game needs one read-only content data service for enemies, items, formulas, zones, production config, and future tables. The architecture document previously drifted toward Godot Resources, but the approved GDD specifies JSON for MVP.

### Constraints

- MVP supports JSON only.
- DataConfig must stay schema-agnostic and not directly parse BigNumber fields.
- Runtime writes are forbidden; player state belongs to SaveManager and state systems.
- Hot reload is debug-only.

### Requirements

- Load `assets/data/*.json` at startup.
- Store each table as a Dictionary keyed by record ID.
- Expose `get`, `get_all`, `query`, `get_field`, and table/record existence checks.
- Fail per table without blocking the rest of the game.

## Decision

Implement `DataConfig` as a `RefCounted` service held by an Autoload host. It scans JSON files under `res://assets/data/`, parses them with Godot JSON APIs, stores raw dictionaries in memory, and returns raw values to consumers. BigNumber conversion is performed by consumers according to their schemas.

### Architecture Diagram

```text
assets/data/*.json
      |
      v
DataConfigHost -> DataConfig cache {table -> {id -> record}}
      |
      +--> ItemRegistry
      +--> EnemyDatabase / ZoneSystem
      +--> FormulaEngine / OutputMultiplierSystem
```

### Key Interfaces

```gdscript
func get(table_name: String, id: String) -> Dictionary
func get_all(table_name: String) -> Dictionary
func query(table_name: String, filter: Callable) -> Array[Dictionary]
func has_table(table_name: String) -> bool
func has_record(table_name: String, id: String) -> bool
func get_field(table_name: String, id: String, field: String) -> Variant
func is_loaded() -> bool
func reload_table(table_name: String) -> void
```

## Implementation Guidelines

- Must use JSON files in `res://assets/data/` for MVP configuration.
- Must not use Godot Resource files as the MVP content format.
- Must keep DataConfig schema-agnostic; consumers parse BigNumber strings themselves.
- Must keep all loaded tables in memory for MVP.
- Must allow one failed table to degrade to an empty table without stopping other tables.
- Must restrict `reload_table` and `reload_all` to debug builds.
- Must not write runtime state through DataConfig.

## Alternatives Considered

### Alternative 1: Godot Resource-based data
- **Description**: Author `.tres` resources and load them through ResourceLoader.
- **Pros**: Stronger editor integration.
- **Cons**: Contradicts current GDD, adds schema coupling, and complicates designer-friendly JSON iteration.
- **Rejection Reason**: MVP GDD explicitly chooses JSON.

### Alternative 2: Per-system JSON parsing
- **Description**: Each system opens and parses its own data files.
- **Pros**: Local ownership.
- **Cons**: Duplicate error handling and inconsistent cache semantics.
- **Rejection Reason**: The project needs a single data access layer.

## Consequences

### Positive
- Simple MVP content pipeline.
- All content consumers share one cache and fallback model.
- BigNumber parsing remains owned by the system that knows the schema.

### Negative
- JSON lacks compile-time schema checks.
- Large Post-MVP content may need validation, indexing, or lazy loading later.

### Risks
- Bad table names or record IDs are runtime warnings, not compile-time errors.
- Hot reload can leave consumers holding stale dictionary references.

## GDD Requirements Addressed

| GDD System | Requirement | How This ADR Addresses It |
|------------|-------------|--------------------------|
| `data-config-system.md` | MVP data lives in JSON tables under `assets/data/` | Locks JSON/FileAccess loading |
| `item-material-system.md` | ItemRegistry reads static item definitions through DataConfig | Defines initialization and access dependency |
| `enemy-database.md` / `zone-system.md` | Static enemy/zone data is config-driven | Provides the shared table cache |
| `formula-engine.md` | Formula definitions can be config-driven | Gives FormulaEngine table lookup path |

## Performance Implications

- **CPU**: MVP target load is under 100 ms for 10 tables × 200 records.
- **Memory**: MVP expected data cache under 5 MB.
- **Load Time**: Startup loads all data synchronously.
- **Network**: None for MVP.

## Migration Plan

Use JSON for MVP. Re-evaluate CSV/import tools or Resource-based authoring only after content scale or tooling needs justify it.

## Validation Criteria

- Tests cover successful table load, missing file, parse error, duplicate ID, missing table/record, `get_field`, query filter, custom root path, and debug hot reload behavior.

## Related Decisions

- ADR-0008: Autoload 初始化顺序
- ADR-0013: FormulaEngine 表达式 DSL 深度

