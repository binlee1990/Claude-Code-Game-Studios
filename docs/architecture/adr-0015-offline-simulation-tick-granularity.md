# ADR-0015: 离线模拟 tick 粒度

## Status
Accepted

## Date
2026-05-04

## Engine Compatibility

| Field | Value |
|-------|-------|
| **Engine** | Godot 4.6.2 |
| **Domain** | Core / Simulation |
| **Knowledge Risk** | LOW — pure service orchestration; depends on Time/RNG behavior verified elsewhere |
| **References Consulted** | `design/gdd/offline-simulation-core.md`, `design/gdd/offline-combat-simulation-system.md`, `design/gdd/offline-reward-settlement-system.md`, `design/gdd/time-manager.md`, `design/gdd/random-seed-system.md` |
| **Post-Cutoff APIs Used** | None |
| **Verification Required** | Offline chunk plan tests, simulator priority ordering, zero delta skip, failed simulator partial result handling, online/offline deterministic comparison |

## ADR Dependencies

| Field | Value |
|-------|-------|
| **Depends On** | ADR-0003, ADR-0004, ADR-0009, ADR-0010 |
| **Enables** | Offline reward settlement and Pre-Production vertical-slice idle return prototype |
| **Blocks** | OfflineSimulationCore, OfflineCombatSimulation, OfflineRewardSettlement implementation |
| **Ordering Note** | Implement after TimeManager, RNGManager, CombatCalculator path, and ResourceSystem settlement path |

## Context

### Problem Statement

Offline progress can cover seconds to hours. The simulation needs predictable chunking and deterministic results without locking the game for too long or drifting from online behavior.

### Constraints

- TimeManager caps offline duration to 8 hours.
- OfflineSimulationCore only creates simulation drafts; it does not write ResourceSystem directly.
- OfflineRewardSettlement applies actual rewards.
- Offline combat uses copied RNG states.

### Requirements

- Split offline time into bounded chunks.
- Run registered simulators by priority.
- Use 1-second business tick semantics for MVP where systems need per-second accumulation.
- Return draft partial results and warnings.

## Decision

Use fixed MVP offline simulation granularity: clamp total offline delta through TimeManager, then split into chunks up to `MAX_CHUNK_SECONDS` (GDD example: 1800 seconds). Within each chunk, simulators use 1-second logical tick semantics or closed-form aggregation if they can prove equivalence. OfflineSimulationCore merges partial results into an `OfflineSimulationDraft`; OfflineRewardSettlement is the only system that writes rewards to ResourceSystem.

### Architecture Diagram

```text
time.offline_delta
      |
      v
OfflineSimulationCore
  build chunks: min(delta, MAX_OFFLINE_SECONDS) / MAX_CHUNK_SECONDS
      |
      +--> registered simulators by priority
      |
      v
OfflineSimulationDraft -> OfflineRewardSettlement -> ResourceSystem.batch_add
```

### Key Interfaces

```gdscript
func register_simulator(id: String, priority: int, simulate_fn: Callable) -> void
func build_plan(offline_seconds: float) -> Array[Dictionary]
func run_simulation(context: Dictionary) -> Dictionary
```

## Implementation Guidelines

- Must clamp offline duration through TimeManager before simulation.
- Must split simulation into bounded chunks no larger than `MAX_CHUNK_SECONDS`.
- Must run simulators in ascending priority, then registration order.
- Must use 1-second business tick semantics unless a simulator documents an equivalent closed-form aggregation.
- Must collect failed non-critical simulator warnings without discarding successful partial results.
- Must not write ResourceSystem from OfflineSimulationCore or OfflineCombatSimulation.
- Must apply rewards only through OfflineRewardSettlement and ResourceSystem.batch_add.
- Must not consume online RNG state during offline simulation.

## Alternatives Considered

### Alternative 1: One giant offline tick
- **Description**: Simulate the entire offline delta in a single call.
- **Pros**: Simple.
- **Cons**: Poor progress reporting, failure isolation, and performance control.
- **Rejection Reason**: Chunking is required for predictable batch simulation.

### Alternative 2: Adaptive tick size immediately
- **Description**: Choose dynamic tick size per simulator based on delta and complexity.
- **Pros**: Potentially faster.
- **Cons**: More correctness risk before online/offline equivalence is proven.
- **Rejection Reason**: MVP needs fixed semantics first; optimize later with evidence.

## Consequences

### Positive
- Offline simulation is bounded and testable.
- Reward application is centralized and capacity-aware.
- Failed simulators can produce warnings without losing all offline progress.

### Negative
- Fixed 1-second semantics may be slower than closed-form math for long deltas.
- Simulators must be carefully written to aggregate without side effects.

### Risks
- Large offline deltas can still be expensive if simulators do per-second loops naively.
- Closed-form shortcuts can drift from online behavior if not proven.

## GDD Requirements Addressed

| GDD System | Requirement | How This ADR Addresses It |
|------------|-------------|--------------------------|
| `offline-simulation-core.md` | Clamp offline time and split into chunks; register simulators by priority | Defines chunking and priority plan |
| `offline-combat-simulation-system.md` | Offline combat runs through shared combat logic with copied RNG | Depends on ADR-0009 and ADR-0004 |
| `offline-reward-settlement-system.md` | Settlement applies claimable rewards and reports lost capacity | Keeps ResourceSystem writes in settlement |
| `time-manager.md` | Offline duration cap is 8 hours | Uses TimeManager's cap as input boundary |

## Performance Implications

- **CPU**: Simulation cost scales with chunk count and simulator complexity; profiling required before vertical slice.
- **Memory**: Draft stores aggregated partial results and warnings.
- **Load Time**: Offline simulation runs after load and may delay presentation of the settlement summary.
- **Network**: None for MVP.

## Migration Plan

Start with fixed chunking and 1-second logical ticks. Add adaptive chunking only after deterministic equivalence tests and profiling identify a real need.

## Validation Criteria

- Tests cover 0 delta skip, 7200s → 4 chunks at 1800s, simulator priority ordering, non-critical simulator failure, draft merge, settlement idempotence, capacity loss, RNG state preservation, and online/offline comparison for fixed seeds.

## Related Decisions

- ADR-0003: 时间源与双时间体系
- ADR-0009: 在线/离线战斗路径统一
- ADR-0010: ResourceSystem 不可变 BigNumber 策略

