# Sprint 11 UI Completion Task

## Intent

真正完成 Sprint 11 UI Scene Layer：让 Godot 启动后拥有完整 HUD shell、5 个 MVP 主屏、Toast、Offline Drawer、Settings/Confirm/Stance modals、Debug Console UI，并产生可验证的 smoke、coverage、walkthrough、测试证据。

## Reframe

当前不是“修几个加载错误”，而是把已存在的 Sprint 11 规格落实成可运行、可截图、可审计的 UI 场景层。代码实现优先于文档勾选；文档只在验证通过后更新。

## Challenge

- Goal alignment: Sprint 11 DoD 要求 First Playable，不允许只做 placeholder 并标完成。
- Simpler path: 不扩展 27 个逻辑系统，不改 GDD/ADR；仅用现有服务和数据接 UI 层。
- Catastrophic risk: 伪造 completion 证据会继续掩盖 First Playable 缺口；必须用 Godot 脚本生成截图和 coverage。

## Execution Gate

- Target explicit: `src/ui/**`, `src/tools/debug_console/debug_console.gd`, Sprint 11 docs/evidence, validation scripts.
- Environment known: Godot 4.6.2 Steam tools at `G:\SteamLibrary\steamapps\common\Godot Engine\godot.windows.opt.tools.64.exe`.
- Side effects acceptable: repo-local UI/docs/test artifacts only; no destructive git operations.
- Success verifiable: `MAIN_SCENE_LOAD_OK`, screenshot artifacts, asset coverage report, GdUnit 0 failures.

Verdict: PROCEED

## Work Log

- 2026-05-05: Started after Godot load audit showed Sprint 11 partial/not done.
- 2026-05-05: Added asset catalog, OfflineDrawer, UI shell hooks, typed toasts, resource/backpack presentation, save slot UI, settings/stance modals, debug console overlay, and first-playable visual smoke.
- 2026-05-05: Fixed Godot load regressions, combat sheet overflow, drawer animation evidence timing, backpack item labels, and screenshot coverage.
- 2026-05-05: Completed 7 epic docs, 16 story docs, Sprint 11 QA plan/result, Sprint 11 DoD, and systems-index milestone update.

## Evaluation

VERDICT: PASS

Basis: Sprint 11 now has runnable UI scenes, 12 screenshot evidence files, 108/108 asset coverage, `MAIN_SCENE_LOAD_OK`, Godot import pass, and `reports/report_21/results.xml` with 137 tests, 0 failures.

Blocking Issues: None.

Revision History: Headless visual capture was rejected as invalid because the dummy renderer returns empty textures; the visual smoke is run in normal render mode.
