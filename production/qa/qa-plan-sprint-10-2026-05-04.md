# Sprint 10 QA Plan

## Scope
- OfflineCombatSimulationSystem: CPU-budget degradation to expected mode, still returns reward draft only.
- OfflineRewardSettlementSystem: capacity-aware claim/loss, duplicate draft prevention, `offline.settled` event.
- UIManager: screen open/error handling, virtualized lists, coalesced layout rebuilds, modal command blocking.
- HUDSystem: NumberFormatter-backed resource text, warning state, offline summary visibility, level badge refresh, burst coalescing.

## Automated Evidence
- `tests/integration/sprint10/sprint10_settlement_ui_hud_test.gd`

## Static Gates
- `project.godot` includes OfflineRewardSettlementSystemHost, UIManagerHost, HUDSystemHost before DebugConsole.
- No deprecated Godot 3 tokens: `yield(`, `OS.get_ticks_msec(`, `connect("`.
- Offline settlement is the only Sprint 10 offline path that writes ResourceSystem rewards.

## Manual / Blocked Evidence
- Godot/GdUnit runtime is required for scene loading, real Control tree layout, modal input blocking, and EventBus delivery counts.
- Current environment has no Godot CLI in PATH, so runtime pass/fail remains blocked until the engine is installed.

## Risks
- UIManager uses lightweight logical screen records for MVP verification; actual `.tscn` scene assets remain a presentation implementation task.
- HUDSystem is a view-model layer, not final art/layout; it proves event and formatting contracts without pixel QA.
