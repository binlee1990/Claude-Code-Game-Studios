# ADR-0009: 在线/离线战斗路径统一

## Status
Accepted

## Date
2026-05-04

## Engine Compatibility

| Field | Value |
|-------|-------|
| **Engine** | Godot 4.6.2 |
| **Domain** | Core / GDScript |
| **Knowledge Risk** | LOW — pure gameplay service composition |
| **References Consulted** | `design/gdd/combat-calculator.md`, `design/gdd/semi-auto-combat-system.md`, `design/gdd/offline-combat-simulation-system.md`, `design/gdd/random-seed-system.md` |
| **Post-Cutoff APIs Used** | None |
| **Verification Required** | Deterministic comparison test: equivalent online combat window and offline simulation produce matching combat/reward facts from same state |

## ADR Dependencies

| Field | Value |
|-------|-------|
| **Depends On** | ADR-0004, ADR-0007, ADR-0013 |
| **Enables** | ADR-0015 |
| **Blocks** | SemiAutoCombatSystem, OfflineCombatSimulation, OfflineRewardSettlement |
| **Ordering Note** | CombatCalculator is implemented before online and offline orchestrators |

## Context

### Problem Statement

Online combat and offline combat must not drift into separate rule sets. If offline combat approximates or reimplements online combat, rewards and progression will feel inconsistent and become hard to test.

### Constraints

- CombatCalculator owns damage resolution.
- SemiAutoCombatSystem owns online encounter loop orchestration.
- OfflineCombatSimulation runs batch simulation without mutating online state directly.
- RNG streams must be copied for offline path.

### Requirements

- Share CombatCalculator for online and offline damage resolution.
- Use combat and loot RNG streams consistently.
- Aggregate offline rewards before ResourceSystem settlement.

## Decision

Both online and offline combat use the same `CombatCalculator` for attack resolution and the same `LootSystem` for rewards. SemiAutoCombatSystem manages live encounter cadence and event publication. OfflineCombatSimulation uses snapshots and copied RNG states to run batched encounters, producing a draft consumed by OfflineRewardSettlement.

### Architecture Diagram

```text
Online:
SemiAutoCombatSystem -> CombatCalculator -> LootSystem -> ResourceSystem

Offline:
OfflineSimulationCore -> OfflineCombatSimulation
  -> CombatCalculator + LootSystem using copied RNG states
  -> OfflineSettlementDraft -> OfflineRewardSettlement -> ResourceSystem
```

### Key Interfaces

```gdscript
CombatCalculator.resolve_attack(attacker: Dictionary, defender: Dictionary) -> Dictionary
OfflineCombatSimulation.simulate(context: Dictionary) -> OfflinePartialResult
SemiAutoCombatSystem.run_encounter_tick(delta: float) -> void
```

## Implementation Guidelines

- Must implement combat formulas once in CombatCalculator.
- Must not duplicate damage formulas in OfflineCombatSimulation.
- Must use RNGManager copied states for offline simulation.
- Must aggregate offline rewards into a settlement draft before writing ResourceSystem.
- Must publish online combat events through EventBus; offline settlement publishes summary events after rewards are applied.
- Must not let offline simulation call SemiAutoCombatSystem directly.

## Alternatives Considered

### Alternative 1: Offline approximation formulas
- **Description**: Estimate combat wins and rewards from DPS averages.
- **Pros**: Faster to simulate.
- **Cons**: Drifts from online combat and undermines deterministic replay.
- **Rejection Reason**: MVP requires shared combat logic.

### Alternative 2: Reuse SemiAutoCombatSystem offline
- **Description**: Run the online combat system in accelerated loops.
- **Pros**: Maximum code reuse.
- **Cons**: Online system owns live events/UI cadence and mutable state, making batch simulation unsafe.
- **Rejection Reason**: Offline path needs a pure batch service.

## Consequences

### Positive
- One damage model for all combat paths.
- Offline rewards can be tested against online combat facts.
- RNG state isolation preserves online sequence.

### Negative
- CombatCalculator must stay pure enough for both callers.
- Offline performance depends on calculator efficiency.

### Risks
- If CombatCalculator reads live mutable system state directly, offline snapshots can be polluted.
- LootSystem must distinguish draft reward generation from actual ResourceSystem settlement.

## GDD Requirements Addressed

| GDD System | Requirement | How This ADR Addresses It |
|------------|-------------|--------------------------|
| `combat-calculator.md` | CombatCalculator resolves attack/damage formulas | Makes it the shared rules service |
| `semi-auto-combat-system.md` | Online combat loop uses CombatCalculator, EnemyDatabase, LootSystem, LevelSystem | Keeps online system as orchestrator |
| `offline-combat-simulation-system.md` | Offline combat reuses online combat logic without consuming online RNG | Uses calculator + copied RNG state |

## Performance Implications

- **CPU**: Offline simulation cost scales with simulated encounters and chunk count.
- **Memory**: Snapshot/draft storage is temporary.
- **Load Time**: Offline simulation may run after load; long deltas need chunking from ADR-0015.
- **Network**: None for MVP.

## Migration Plan

Implement CombatCalculator first. Add online loop and offline simulation only after calculator tests pass.

## Validation Criteria

- Tests compare online and offline combat outcomes for a fixed seed/state.
- Tests verify offline simulation does not mutate online RNG state or ResourceSystem until settlement.

## Related Decisions

- ADR-0004: 确定性随机数架构
- ADR-0015: 离线模拟 tick 粒度

