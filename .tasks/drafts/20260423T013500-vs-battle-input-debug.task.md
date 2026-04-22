---
task_id: vs-battle-input-debug
created_at: 2026-04-23T01:35:00+08:00
complexity: L3
status: draft
frameworks:
  - SCQA
  - MECE
target:
  scene: res://prototypes/vertical-slice/vs_battle.tscn
  script: res://prototypes/vertical-slice/vs_battle.gd
---

Role: Senior Godot gameplay engineer debugging a prototype battle scene with mixed UI and board interaction.
Context: Claude produced a vertical-slice battle prototype under `prototypes/vertical-slice`. In the current scene, the player reports that the Swordsman and Archer cannot be clicked, cannot move, and cannot attack. The prototype is built in Godot 4.6 on top of existing combat/unit systems in `src/core/`.
Objective: Restore the prototype's intended player interaction loop so the current player-controlled actor can be selected, moved, and used to attack according to the scene README.
Success criteria: Clicking or hotkey flow can reliably enter selection/move/attack states for the active player unit; the prototype no longer blocks the player behind broken input routing or invalid initial turn setup; code-level regression coverage exists for the fixed behavior.
Decomposition: 1. Inspect scene/controller/core combat code to isolate where interaction breaks. 2. Translate the user complaint into explicit failure modes: click selection, move state progression, attack state progression, first-turn ownership, and enemy turn continuity. 3. Add regression tests that fail on the current behavior. 4. Apply minimal reversible fixes in the prototype controller. 5. Run targeted validation and summarize remaining risks.
Methodology: SCQA to reframe the user complaint into concrete technical failures; MECE to separate input-routing, turn-initialization, and AI-turn issues so the fix is not hand-wavy.
Output: Code changes in the prototype scene controller plus focused regression tests and a concise validation report.
Constraints: No new dependencies; keep changes localized to the prototype/test surface unless a core-system defect is proven; do not rewrite the battle prototype architecture; preserve existing combat system contracts.
Non-assumptions: Do not assume the root `Control._gui_input()` is receiving clicks; do not assume the first actor is always a player; do not assume enemy AI is healthy just because the user reported a player-input symptom; do not assume runtime verification is available on PATH.
Verification: Inspect the interaction path from input to `_handle_grid_click`, prove the failure with regression tests where feasible, run targeted tests, and record any environment gap if full scene execution is unavailable.

Confidence: Medium — the main failure is likely input interception and/or invalid turn initialization, but scene execution still needs targeted validation.
Reproducibility: Workspace `D:\work\Games\SRPG`, scene `res://prototypes/vertical-slice/vs_battle.tscn`, tests run through the in-tree GUT runner.
Baseline: Current prototype uses root `Control._gui_input()` with multiple child `Control` overlays, random tie-break turn ordering for equal AGI, and enemy-turn logic that appears to leave `nearest_player` unset.
