# ADR-0004: 确定性随机数架构

## Status
Accepted

## Date
2026-05-04

## Engine Compatibility

| Field | Value |
|-------|-------|
| **Engine** | Godot 4.6.2 |
| **Domain** | Core / Randomness |
| **Knowledge Risk** | MEDIUM — `RandomNumberGenerator` is stable but seed/state determinism must be verified in the pinned runtime |
| **References Consulted** | `docs/engine-reference/godot/VERSION.md`, `design/gdd/random-seed-system.md` |
| **Post-Cutoff APIs Used** | None |
| **Verification Required** | Replay tests proving same master seed + same call sequence yields identical COMBAT/LOOT/EVENT/AFFIX streams |

## ADR Dependencies

| Field | Value |
|-------|-------|
| **Depends On** | None |
| **Enables** | ADR-0009, ADR-0013, ADR-0015 |
| **Blocks** | Combat crit/hit rolls, loot rolls, deterministic offline simulation |
| **Ordering Note** | Initialize before combat, loot, formula, save, and offline systems |

## Context

### Problem Statement

Combat, loot, affixes, and offline simulation all need randomness without hidden coupling. One system consuming random calls must not change another system's sequence.

### Constraints

- Random results must be reproducible from saved seed/state.
- Offline simulation must not consume online RNG state.
- Streams must be serializable by SaveManager.
- Direct use of global `randi()` / `randf()` is forbidden.

### Requirements

- Use one master seed and independent derived streams.
- Support deterministic weighted picks, bool/int/float draws, shuffle, and pick_random.
- Save and restore every stream state.

## Decision

Implement `RNGManager` as an Autoload with a 64-bit master seed and independent `RandomNumberGenerator` instances for `COMBAT`, `LOOT`, `EVENT`, and `AFFIX`, plus optional named extension streams. Derive stream seeds from master seed using FNV-1a. Offline simulations operate on saved state copies and discard them after settlement.

### Architecture Diagram

```text
master_seed
  ├─ fnv1a(master, COMBAT) -> combat RNG
  ├─ fnv1a(master, LOOT)   -> loot RNG
  ├─ fnv1a(master, EVENT)  -> event RNG
  └─ fnv1a(master, AFFIX)  -> affix RNG

offline simulation: save_states() -> copied streams -> discard copy
```

### Key Interfaces

```gdscript
enum CoreStream { COMBAT, LOOT, EVENT, AFFIX }
func rand_int(stream_id: int, min_val: int, max_val: int) -> int
func rand_float(stream_id: int, min_val: float = 0.0, max_val: float = 1.0) -> float
func rand_bool(stream_id: int, probability: float = 0.5) -> bool
func weighted_pick(stream_id: int, weights: Array[float]) -> int
func save_states() -> Dictionary
func load_states(data: Dictionary) -> void
```

## Implementation Guidelines

- Must route all gameplay randomness through `RNGManager`.
- Must not call global `randi()` or `randf()` from gameplay systems.
- Must keep COMBAT and LOOT streams independent.
- Must serialize master seed and per-stream seed/state.
- Must use copied RNG states for offline simulation.
- Must clamp invalid probabilities and weights rather than crashing.
- Must return deterministic defaults when uninitialized, with warnings.

## Alternatives Considered

### Alternative 1: Single global RNG stream
- **Description**: All systems draw from one RNG.
- **Pros**: Easiest implementation.
- **Cons**: Combat calls alter loot outcomes and offline/online paths diverge.
- **Rejection Reason**: Violates stream isolation requirement.

### Alternative 2: Per-system unmanaged RNGs
- **Description**: Each system owns its own random generator.
- **Pros**: Local control.
- **Cons**: Save/replay/debug determinism becomes fragmented.
- **Rejection Reason**: Central manager is required for reproducibility and save integration.

## Consequences

### Positive
- Combat, loot, event, and affix randomness are isolated.
- Offline simulation can be deterministic without consuming online state.
- DebugConsole can reproduce sequences by master seed.

### Negative
- Every random call must pass stream IDs correctly.
- FNV-1a implementation needs tests to avoid accidental seed collisions or signed overflow mistakes.

### Risks
- Godot `RandomNumberGenerator.seed/state` behavior must be verified for 4.6.2.
- High-frequency weighted_pick on large tables may need alias-method optimization later.

## GDD Requirements Addressed

| GDD System | Requirement | How This ADR Addresses It |
|------------|-------------|--------------------------|
| `random-seed-system.md` | Multi-stream deterministic RNG with master seed | Defines master seed and isolated stream derivation |
| `combat-calculator.md` | Combat probabilities use COMBAT stream | Reserves stream semantics for combat calls |
| `loot-system.md` | Weighted drops use LOOT stream | Prevents combat rolls from changing drop outcomes |
| `offline-combat-simulation-system.md` | Offline simulation must not consume online RNG | Requires state-copy simulation |

## Performance Implications

- **CPU**: Single random calls should stay under 0.015 ms; weighted_pick for 1024 weights under 0.1 ms.
- **Memory**: Four core streams plus extension streams are small; serialized state for six streams should stay under 1 KB.
- **Load Time**: Minimal.
- **Network**: None for MVP.

## Migration Plan

No existing implementation. Add RNGManager before FormulaEngine, CombatCalculator, LootSystem, SaveManager, and OfflineSimulationCore.

## Validation Criteria

- Tests cover reproducible sequences, stream independence, weighted distribution, invalid inputs, save/load state, offline copy isolation, and uninitialized fallback warnings.

## Related Decisions

- ADR-0009: 在线/离线战斗路径统一
- ADR-0015: 离线模拟 tick 粒度

