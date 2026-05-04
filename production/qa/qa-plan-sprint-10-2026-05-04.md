# Sprint 10 QA Plan

## Scope
- OfflineCombatSimulationSystem: CPU-budget degradation to expected mode, still returns reward draft only.
- OfflineRewardSettlementSystem: capacity-aware claim/loss, duplicate draft prevention, `offline.settled` event.
- UIManager: screen open/error handling, virtualized lists, coalesced layout rebuilds, modal command blocking.
- HUDSystem: NumberFormatter-backed resource text, warning state, offline summary visibility, level badge refresh, burst coalescing.

## Automated Evidence
- `tests/integration/sprint10/sprint10_settlement_ui_hud_test.gd`

## 2026-05-04 执行记录
- Godot CLI 已通过 Steam 安装路径执行：`G:\SteamLibrary\steamapps\common\Godot Engine\godot.windows.opt.tools.64.exe`。
- `reports/report_8/results.xml`：137 个测试，0 个失败，0 个跳过，0 个 flaky。
- Sprint 10 gate 证据：`production/qa/evidence/sprint-10-qa-result-2026-05-04.md`。
- 资源校验报告：`production/qa/evidence/asset-validation-report.json`。

## Static Gates
- `project.godot` includes OfflineRewardSettlementSystemHost, UIManagerHost, HUDSystemHost before DebugConsole.
- No deprecated Godot 3 tokens: `yield(`, `OS.get_ticks_msec(`, `connect("`.
- Offline settlement is the only Sprint 10 offline path that writes ResourceSystem rewards.

## Manual / Runtime Evidence
- Godot/GdUnit runtime is required for scene loading, real Control tree layout, modal input blocking, and EventBus delivery counts.
- 本轮已通过本机 Godot 4.6.2 CLI 完成 runtime 证据，不再因 PATH 未配置而阻塞。

## Risks
- UIManager uses lightweight logical screen records for MVP verification; actual `.tscn` scene assets remain a presentation implementation task.
- HUDSystem is a view-model layer, not final art/layout; it proves event and formatting contracts without pixel QA.
