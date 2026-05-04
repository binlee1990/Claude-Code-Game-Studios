# Sprint 9 QA Plan

## Scope
- AutoProductionSystem: passive resource list excludes `exp`, invalid ids do not block valid resources.
- EnemyDatabase, LootSystem, CultivationSystem, CombatCalculator, SemiAutoCombatSystem.
- ZoneSystem, MapProgressionSystem, OfflineSimulationCore, IdleExplorationSystem, OfflineCombatSimulationSystem.

## Automated Evidence
- `tests/integration/sprint9/sprint9_feature_stack_test.gd`

## 2026-05-04 执行记录
- Godot CLI 已通过 Steam 安装路径执行：`G:\SteamLibrary\steamapps\common\Godot Engine\godot.windows.opt.tools.64.exe`。
- `reports/report_8/results.xml`：137 个测试，0 个失败，0 个跳过，0 个 flaky。
- Sprint 9 gate 证据：`production/qa/evidence/sprint-9-qa-result-2026-05-04.md`。

## Static Gates
- `assets/data/enemies.json` contains 3 valid MVP enemies with all 6 combat attributes.
- `assets/data/loot_tables.json` contains deterministic exp-bearing MVP loot tables.
- `assets/data/zones.json` contains 3 ordered zones with valid enemy pools or degraded warnings.
- `project.godot` includes Sprint 9 feature Hosts before `DebugConsole`.
- No deprecated Godot 3 tokens: `yield(`, `OS.get_ticks_msec(`, `connect("`.

## Manual / Runtime Evidence
- Godot/GdUnit runtime is required for true event counts, seeded RNG replay, and online/offline combat parity execution.
- 本轮已通过本机 Godot 4.6.2 CLI 完成 runtime 证据，不再因 PATH 未配置而阻塞。

## Risks
- Semi-auto combat picks the first valid enemy in the pool for MVP determinism; weighted random selection is deferred to the balancing pass.
- Offline combat produces reward drafts only; it intentionally does not write ResourceSystem state before Sprint 10 settlement.
