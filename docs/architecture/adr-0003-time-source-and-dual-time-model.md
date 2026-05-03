# ADR-0003: 时间源与双时间体系

## Status
Accepted

## Date
2026-05-04

## Engine Compatibility

| Field | Value |
|-------|-------|
| **Engine** | Godot 4.6.2 |
| **Domain** | Core / Time |
| **Knowledge Risk** | LOW — `Time.get_unix_time_from_system()` is stable; project risk is design correctness, not API churn |
| **References Consulted** | `docs/engine-reference/godot/VERSION.md`, `docs/engine-reference/godot/deprecated-apis.md`, `design/gdd/time-manager.md` |
| **Post-Cutoff APIs Used** | None |
| **Verification Required** | Verify timestamp delta behavior across pause, close/load, system clock rollback, and offline cap |

## ADR Dependencies

| Field | Value |
|-------|-------|
| **Depends On** | ADR-0002 |
| **Enables** | ADR-0006, ADR-0015 |
| **Blocks** | Auto-production, cultivation timers, offline simulation, save/load offline settlement |
| **Ordering Note** | TimeManager must initialize after EventBus and before save/offline consumers |

## Context

### Problem Statement

Idle progress and offline rewards must be based on real elapsed time. `_process(delta)` is frame-dependent and can pause or jump, especially during low frame rate, background tabs, or paused trees.

### Constraints

- Real time cannot be frozen or accelerated.
- Game time can be frozen and accelerated.
- Offline rewards do not receive online speed multipliers in MVP.
- The maximum offline duration is capped at 8 hours.

### Requirements

- Provide real Unix time, virtual game time, speed sources, freeze/unfreeze, and offline delta events.
- Persist timestamp snapshots through SaveManager.
- Clamp negative or excessive offline deltas safely.

## Decision

Implement `TimeManager` as an Autoload that owns a dual-time snapshot: real Unix time and derived game time. All gameplay timing uses `TimeManager`, never direct `_process(delta)` as authority. Online ticks use `get_game_delta_since`; offline settlement uses `min(real_now - exit_timestamp, MAX_OFFLINE_SECONDS)` with speed multiplier ignored.

### Architecture Diagram

```text
Time.get_unix_time_from_system()
        |
        v
TimeManager snapshot {real_ref, game_ref, speed_sources}
        |
        +--> online get_game_delta_since()
        +--> save exit timestamp
        +--> offline_delta event -> OfflineSimulationCore
```

### Key Interfaces

```gdscript
func get_real_time() -> float
func get_game_time() -> float
func get_effective_speed() -> float
func get_game_delta_since(last_game_time: float) -> float
func freeze() -> void
func unfreeze() -> void
func add_speed_source(source_id: String, multiplier: float) -> void
func remove_speed_source(source_id: String) -> void
func collect_save_data() -> Dictionary
func restore_save_data(data: Dictionary) -> void
```

## Implementation Guidelines

- Must use `Time.get_unix_time_from_system()` as the authoritative real-time source.
- Must not use `_process(delta)` as the source of truth for idle progress or offline rewards.
- Must multiply online game time by registered speed sources.
- Must ignore speed multipliers for MVP offline reward time.
- Must clamp offline duration to `MAX_OFFLINE_SECONDS = 28800`.
- Must publish `time.frozen`, `time.unfrozen`, `time.speed_changed`, and `time.offline_delta` through EventBus.
- Must clamp negative offline delta to `0.0` and skip settlement.

## Alternatives Considered

### Alternative 1: Use frame delta everywhere
- **Description**: Let each system integrate `_process(delta)`.
- **Pros**: Direct and familiar in Godot.
- **Cons**: Fails offline returns, pause behavior, and background-tab cases.
- **Rejection Reason**: Violates TimeManager GDD and idle-game offline promise.

### Alternative 2: Single mutable game clock only
- **Description**: Store one accelerated clock and derive everything from it.
- **Pros**: Smaller API.
- **Cons**: Cannot distinguish real offline time from accelerated online time.
- **Rejection Reason**: MVP needs both real and game time semantics.

## Consequences

### Positive
- Offline reward math is deterministic and independent of frame rate.
- Pause/freeze semantics are explicit.
- All timed systems share one speed-source model.

### Negative
- Consumers must store their own last tick timestamp.
- System clock tampering can still affect offline delta, though capped.

### Risks
- Restore ordering can affect when offline settlement runs.
- Future anti-cheat may require checksum or server time if leaderboards are added.

## GDD Requirements Addressed

| GDD System | Requirement | How This ADR Addresses It |
|------------|-------------|--------------------------|
| `time-manager.md` | Use Unix timestamp rather than `_process(delta)` as authoritative time | Locks TimeManager around `Time.get_unix_time_from_system()` |
| `auto-production-system.md` | Online tick uses `get_game_delta_since(last_tick_game_time)` | Defines online game-time delta path |
| `offline-simulation-core.md` | Offline delta is clamped and passed to simulation | Defines offline real-time calculation and cap |

## Performance Implications

- **CPU**: Timestamp math is constant time; 1000 `get_game_time()` calls should remain under 0.1 ms.
- **Memory**: Small snapshot and speed-source dictionary.
- **Load Time**: None.
- **Network**: None for MVP.

## Migration Plan

No existing implementation. Implement TimeManager after EventBus and before SaveManager/offline systems.

## Validation Criteria

- Tests cover speed multiplication, freeze/unfreeze, source overwrite/removal, offline cap, clock rollback, save/restore snapshot, and EventBus emissions.

## Related Decisions

- ADR-0006: 存档格式与版本迁移
- ADR-0015: 离线模拟 tick 粒度

