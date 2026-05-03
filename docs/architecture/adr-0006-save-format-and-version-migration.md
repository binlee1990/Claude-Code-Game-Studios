# ADR-0006: 存档格式与版本迁移

## Status
Accepted

## Date
2026-05-04

## Engine Compatibility

| Field | Value |
|-------|-------|
| **Engine** | Godot 4.6.2 |
| **Domain** | Core / FileAccess |
| **Knowledge Risk** | MEDIUM — Godot 4.4 changed `FileAccess.store_*` methods to return `bool` |
| **References Consulted** | `docs/engine-reference/godot/VERSION.md`, `docs/engine-reference/godot/breaking-changes.md`, `docs/engine-reference/godot/deprecated-apis.md`, `design/gdd/save-system.md` |
| **Post-Cutoff APIs Used** | `FileAccess.store_string()` bool return must be checked |
| **Verification Required** | Save/load, atomic temp-file write, backup restore, migration chain, corrupted save fallback, provider error isolation |

## ADR Dependencies

| Field | Value |
|-------|-------|
| **Depends On** | ADR-0002, ADR-0003, ADR-0008 |
| **Enables** | ADR-0010, ADR-0012, ADR-0015 |
| **Blocks** | Any persistent player state and offline-return flow |
| **Ordering Note** | SaveManager initializes after data/time/event infrastructure and registers providers after state systems exist |

## Context

### Problem Statement

The game needs durable single-player progress, offline timestamps, RNG state, and forward-compatible migrations. SaveManager must not know every system's internal schema.

### Constraints

- MVP has one autosave slot and one JSON file.
- No encryption, compression, cloud saves, screenshots, or multi-slot UI in MVP.
- Provider failures must not corrupt the entire save.
- File writes must account for Godot 4.4+ bool-returning `store_*` methods.

### Requirements

- Use provider callback registration by namespace.
- Save one JSON object with `meta` and `systems`.
- Use temp file + backup replacement.
- Support chained migrations and corrupted-save backup recovery.

## Decision

Implement `SaveManager` as a global Autoload that owns a provider registry. Each persistent system registers `save_fn() -> Dictionary` and `restore_fn(data: Dictionary) -> void` under a namespace. SaveManager writes a JSON save to `user://save/save.json` through a temporary file and keeps `save.json.bak` for recovery.

### Architecture Diagram

```text
ResourceSystem.save_fn()
TimeManager.save_fn()
RNGManager.save_fn()
       |
       v
SaveManager {meta, systems}
       |
       v
user://save/save.json.tmp -> save.json.bak -> save.json
```

### Key Interfaces

```gdscript
func register_provider(namespace: String, save_fn: Callable, restore_fn: Callable) -> void
func save_game(slot: int = 0) -> bool
func load_game(slot: int = 0) -> bool
func collect_save_data() -> Dictionary
func is_saving() -> bool
func is_loading() -> bool
```

## Implementation Guidelines

- Must save a JSON object with top-level `meta` and `systems`.
- Must use provider callbacks; SaveManager must not import concrete system state types.
- Must check `FileAccess.store_string()` and other `store_*` return values.
- Must write to a temp file before replacing the primary save.
- Must keep a backup save when backup is enabled.
- Must continue saving other namespaces when one provider returns invalid data.
- Must dispatch `save.loaded`, `save.saved`, and `save.corrupted` through EventBus.
- Must not implement encryption, compression, cloud sync, or multi-slot UX in MVP.

## Alternatives Considered

### Alternative 1: SaveManager imports every system
- **Description**: SaveManager manually reads ResourceSystem, TimeManager, RNGManager, and later systems.
- **Pros**: Explicit and easy to inspect initially.
- **Cons**: Creates a God object and breaks extension by new systems.
- **Rejection Reason**: The save GDD requires provider registration.

### Alternative 2: One file per system
- **Description**: Each system writes a separate save fragment.
- **Pros**: Isolates write failures.
- **Cons**: Harder atomicity, migration, and backup recovery.
- **Rejection Reason**: MVP wants one compact autosave file.

## Consequences

### Positive
- Persistence stays extensible and namespaced.
- Old unknown namespaces can be preserved for forward compatibility.
- Corrupted primary saves can recover from backup.

### Negative
- Provider order must be managed during restore.
- JSON offers no built-in schema validation.

### Risks
- A provider can return non-serializable values; SaveManager must detect and warn.
- Migration gaps can strand older saves if not tested before release.

## GDD Requirements Addressed

| GDD System | Requirement | How This ADR Addresses It |
|------------|-------------|--------------------------|
| `save-system.md` | Provider registry pattern with namespace callbacks | Defines callback registration and data collection |
| `time-manager.md` | Persist exit timestamp and time snapshot | TimeManager registers provider data |
| `random-seed-system.md` | Persist RNG master seed and stream states | RNGManager registers state serialization |
| `resource-system.md` / `attribute-system.md` | State systems persist snapshots | SaveManager distributes restore data by namespace |

## Performance Implications

- **CPU**: MVP save target under 20 ms for ~15 providers.
- **Memory**: Save object expected under 50 KB.
- **Load Time**: MVP load target under 20 ms before offline settlement.
- **Network**: None for MVP.

## Migration Plan

Start at `CURRENT_SAVE_VERSION = 1`. Add versioned migration callables only when the file schema changes.

## Validation Criteria

- Tests cover first-run no-save, normal save/load, provider invalid data, primary corruption with backup recovery, migration v1→vN, future-version rejection, temp-file cleanup, duplicate save request suppression, and FileAccess bool-return checking.

## Related Decisions

- ADR-0003: 时间源与双时间体系
- ADR-0015: 离线模拟 tick 粒度

