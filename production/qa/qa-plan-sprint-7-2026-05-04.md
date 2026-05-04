# Sprint 7 QA Plan

## Scope
- ItemRegistry: cross-system boundary with ResourceSystem, internal class/id consistency.
- OutputMultiplierSystem: production config load, source activation/deactivation, pool math, tick carry, event emission, invalid input handling.
- DebugConsole: debug-only lifecycle, command registry, event watch, config/resource/modifier/attribute/product/time/save command smoke coverage.

## Automated Evidence
- `tests/integration/item_registry/item_registry_boundary_test.gd`
- `tests/unit/output_multiplier_system/output_multiplier_system_config_test.gd`
- `tests/unit/output_multiplier_system/output_multiplier_system_formula_test.gd`
- `tests/integration/output_multiplier_system/output_multiplier_events_test.gd`
- `tests/unit/debug_console/debug_console_command_test.gd`
- `tests/integration/debug_console/debug_console_smoke_test.gd`

## 2026-05-04 执行记录
- Godot CLI 已通过 Steam 安装路径执行：`G:\SteamLibrary\steamapps\common\Godot Engine\godot.windows.opt.tools.64.exe`。
- `reports/report_8/results.xml`：137 个测试，0 个失败，0 个跳过，0 个 flaky。
- Sprint 7 gate 证据：`production/qa/evidence/sprint-7-qa-result-2026-05-04.md`。

## Static Gates
- `project.godot` autoload order: DataConfigHost before OutputMultiplierSystemHost before DebugConsole.
- `assets/data/production_config.json` parses and includes the 5 MVP resource ids.
- `DataConfig.get_table_names()` exists for `config list`.
- No deprecated Godot 3 tokens: `yield(`, `OS.get_ticks_msec(`, `connect("`.

## Manual / Runtime Evidence
- Godot/GdUnit runtime is required to prove real UI focus behavior, Release export queue-free behavior, and timing-sensitive OMS event expiry.
- 本轮已通过本机 Godot 4.6.2 CLI 完成 runtime 证据，不再因 PATH 未配置而阻塞。

## Risks
- DebugConsole builds its CanvasLayer/LineEdit/RichTextLabel in code instead of instancing a `.tscn`; this avoids adding editor-authored scene assets while preserving the Sprint 7 behavioral contract.
- OutputMultiplierSystem is exposed as `OutputMultiplierSystemHost` to avoid singleton/class-name collision and match the project’s existing Host pattern.
