# Sprint 9 QA Plan

## Scope
- AutoProductionSystem: passive resource list excludes `exp`, invalid ids do not block valid resources.
- EnemyDatabase, LootSystem, CultivationSystem, CombatCalculator, SemiAutoCombatSystem.
- ZoneSystem, MapProgressionSystem, OfflineSimulationCore, IdleExplorationSystem, OfflineCombatSimulationSystem.

## Automated Evidence
- `tests/integration/sprint9/sprint9_feature_stack_test.gd`

## Static Gates
- `assets/data/enemies.json` contains 3 valid MVP enemies with all 6 combat attributes.
- `assets/data/loot_tables.json` contains deterministic exp-bearing MVP loot tables.
- `assets/data/zones.json` contains 3 ordered zones with valid enemy pools or degraded warnings.
- `project.godot` includes Sprint 9 feature Hosts before `DebugConsole`.
- No deprecated Godot 3 tokens: `yield(`, `OS.get_ticks_msec(`, `connect("`.

## Manual / Blocked Evidence
- Godot/GdUnit runtime is required for true event counts, seeded RNG replay, and online/offline combat parity execution.
- Current environment has no Godot CLI in PATH, so runtime pass/fail remains blocked until the engine is installed.

## Risks
- Semi-auto combat picks the first valid enemy in the pool for MVP determinism; weighted random selection is deferred to the balancing pass.
- Offline combat produces reward drafts only; it intentionally does not write ResourceSystem state before Sprint 10 settlement.
