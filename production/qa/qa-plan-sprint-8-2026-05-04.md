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

## Static Gates
- `project.godot` autoload order includes LevelSystemHost, StorageLimitSystemHost, AutoProductionSystemHost before DebugConsole.
- `assets/data/level_realm_config.json` parses and contains 7 realms from `fanren` through `heti`.
- `assets/data/formulas.json` includes level and attribute growth formulas.
- No deprecated Godot 3 tokens: `yield(`, `OS.get_ticks_msec(`, `connect("`.

## Manual / Blocked Evidence
- Godot/GdUnit runtime is required for real EventBus ordering, focus handling, `_process` tick cadence, and performance/memory budgets.
- Current environment has no Godot CLI in PATH, so runtime pass/fail remains blocked until the engine is installed.

## Risks
- LevelSystem registers realm modifiers into the AttributeSystem and OutputMultiplierSystem engines separately because current Sprint 7 Hosts own distinct ModifierEngine instances.
- Formula values are MVP-safe defaults designed to satisfy documented ranges; economy tuning remains a balancing pass.
