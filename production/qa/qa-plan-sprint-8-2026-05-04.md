# Sprint 8 QA Plan

## Scope
- DebugConsole: help/clear/unknown/invalid-handler branches, history navigation, output buffer behavior, missing system warnings.
- LevelSystem: entity lifecycle, exp spend/refund, realm derivation, realm modifiers, save.loaded rebuild, reset, formula edge cases.
- StorageLimitSystem: base caps, warning/full/uncapped states, realm cap multiplier recompute through ResourceSystem.
- AutoProductionSystem: online passive tick, fractional ZERO skip, frozen-time skip, no passive exp request, invalid resource isolation.

## Automated Evidence
- `tests/unit/debug_console/debug_console_history_test.gd`
- `tests/unit/level_system/level_system_formula_test.gd`
- `tests/integration/level_system/level_system_progression_test.gd`
- `tests/integration/storage_limit_system/storage_limit_system_test.gd`
- `tests/integration/auto_production_system/auto_production_system_test.gd`

## 2026-05-04 执行记录
- Godot CLI 已通过 Steam 安装路径执行：`G:\SteamLibrary\steamapps\common\Godot Engine\godot.windows.opt.tools.64.exe`。
- `reports/report_8/results.xml`：137 个测试，0 个失败，0 个跳过，0 个 flaky。
- Sprint 8 gate 证据：`production/qa/evidence/sprint-8-qa-result-2026-05-04.md`。

## Static Gates
- `project.godot` autoload order includes LevelSystemHost, StorageLimitSystemHost, AutoProductionSystemHost before DebugConsole.
- `assets/data/level_realm_config.json` parses and contains 7 realms from `fanren` through `heti`.
- `assets/data/formulas.json` includes level and attribute growth formulas.
- No deprecated Godot 3 tokens: `yield(`, `OS.get_ticks_msec(`, `connect("`.

## Manual / Runtime Evidence
- Godot/GdUnit runtime is required for real EventBus ordering, focus handling, `_process` tick cadence, and performance/memory budgets.
- 本轮已通过本机 Godot 4.6.2 CLI 完成 runtime 证据，不再因 PATH 未配置而阻塞。

## Risks
- LevelSystem registers realm modifiers into the AttributeSystem and OutputMultiplierSystem engines separately because current Sprint 7 Hosts own distinct ModifierEngine instances.
- Formula values are MVP-safe defaults designed to satisfy documented ranges; economy tuning remains a balancing pass.
