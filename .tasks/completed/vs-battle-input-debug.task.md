---
task_id: vs-battle-input-debug
created_at: 2026-04-23T01:35:00+08:00
complexity: L3
status: active
execution_gate:
  verdict: pass
  basis:
    - target scene and script are explicit
    - environment is known well enough for repo inspection and test execution
    - side effects are local and reversible
    - success signals are testable through controller state and battle flow
challenge:
  thesis: Fix prototype input so player units can be selected and acted with.
  antithesis:
    - The click bug may be downstream of initial actor selection, not raw input alone.
    - The symptom may recur after selection if enemy-turn progression is broken.
    - Directly patching UI controls without tests could hide a broader state-machine issue.
  synthesis: Fix the full interaction chain minimally by covering input reception, deterministic/valid first-turn behavior, and enemy-turn correctness with focused regression tests.
final_verdict:
  verdict: PASS
  basis: The prototype now initializes into a playable player turn, receives click input correctly, progresses through move and attack states, and enemy turns acquire a player target again.
  blocking_issues: []
  revision_history:
    - round: 1
      reason: Baseline tests exposed broken input routing, invalid initial turn flow, and null enemy target acquisition.
---

Role: Senior Godot gameplay engineer responsible for making the prototype battle loop verifiably playable again.
Context: `prototypes/vertical-slice/vs_battle.gd` owns both UI construction and combat flow. The player reports that blue units are not clickable and cannot move or attack. Initial inspection shows a root `Control._gui_input()` handler under a tree of dynamically created `Control` children, a first-turn prompt that may disagree with the actual current actor, and enemy AI code that appears incomplete.
Objective: Repair the vertical-slice battle prototype so the active player unit can be selected and progress through move and attack interactions without being blocked by broken input or turn-state logic.
Success criteria: 1. The prototype accepts click or hotkey-driven selection for the current player actor. 2. Moving an active player unit advances into attack selection as designed. 3. Attacking an enemy in range applies damage and ends the player's turn. 4. Battle flow does not deadlock on an enemy turn. 5. Regression tests cover the repaired flow.
Decomposition: 1. Confirm root causes by code inspection. 2. Add tests for active-player initialization and click-to-select/move/attack progression. 3. Patch the prototype controller with the smallest coherent fix set. 4. Run targeted validation. 5. Report evidence and residual risk.
Methodology: SCQA to keep the real user pain centered on playable interaction; MECE to isolate input, turn-order initialization, and AI progression so each fix has a clear reason.
Output: Updated prototype controller, new regression tests, task evidence, and a concise completion report.
Constraints: Keep the diff small and reversible; do not add dependencies; do not alter unrelated core combat logic; if runtime execution is unavailable, compensate with stronger automated tests and explicit reporting.
Non-assumptions: Do not assume clicks reach the root control; do not assume equal-AGI units produce a player-first turn; do not assume enemy AI target acquisition currently works; do not assume the user's complaint is fully explained by a single bug.
Verification: Use focused automated tests against prototype controller behavior and supporting battle flow, inspect changed code paths, and attempt local engine execution if a Godot binary is discoverable.

Confidence: High for the intended fix direction because the current code shows concrete interaction-path defects; medium for full runtime parity until engine execution is confirmed.
Reproducibility: Repo root `D:\work\Games\SRPG`; validate task file with `python C:\Users\888\.codex\skills\reframe-and-execute\scripts\validate-task.py`; run project tests via the existing scene-mode test runner if a Godot executable is available.
Baseline: Before changes, the prototype processes clicks via `_gui_input`, only allows selection when the clicked unit equals `CombatSystem.get_current_actor()`, gives all units default AGI unless explicitly set, and enemy-turn target acquisition leaves `nearest_player` null.
Execution: 2026-04-23T01:35+08:00 diagnosed the prototype controller and materialized this task. 2026-04-23T01:43+08:00 added `tests/integration/prototypes/vs_battle_test.gd` and registered it in `tests/tests_manifest.txt` to lock initial player-turn readiness, click-to-move flow, attack damage, and enemy targeting. 2026-04-23T01:47+08:00 updated `prototypes/vertical-slice/vs_battle.gd` to route gameplay input through `_input`, mark grid visuals as non-interactive, process the initial turn immediately, keep labels synchronized on movement, and restore enemy nearest-target assignment. 2026-04-23T01:49+08:00 verified the scene loads in Godot headless mode and confirmed the four prototype regression tests pass under the project test runner.
