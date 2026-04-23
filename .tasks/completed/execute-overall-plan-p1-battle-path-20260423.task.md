Role: Senior Godot gameplay engineer connecting the repository's battle main path to the verified vertical-slice implementation.
Context: The active overall plan defines P1 product-path integration immediately after P0 baseline repair. With the automated suite now green, the highest-value next action is to remove the disconnect between the formal `battle_arena.tscn` route and the playable prototype battle flow. The repository already has a stable route key (`battle`) and stable scene path (`src/ui/combat/battle_arena.tscn`), so the implementation should preserve those external contracts while making the scene actually functional.
Objective: Make the formal battle route instantiate the playable vertical-slice battle flow through a single canonical controller.
Success criteria: 1. Main-path scene wiring is functional. 2. Placeholder battle arena no longer blocks the main menu route. 3. Prototype and formal battle scenes use one controller source of truth. 4. Automated regression coverage verifies the main battle entry scene and the full suite stays green.
Decomposition: 1. Canonicalize battle controller ownership under `src/ui/combat`. 2. Rewire both the formal scene and prototype scene to that controller. 3. Add a main-path scene regression test and update the test manifest. 4. Run the full test suite.
Methodology: SCQA for plan alignment and MECE for separating scene routing, controller placement, and test coverage.
Output: Updated scenes/scripts/tests plus verification evidence.
Constraints: Preserve `project.godot` / `SceneManager` public routing shape. Do not expand into Camera/UI story implementation in this step. Keep diffs reversible.
Non-assumptions: Do not duplicate battle logic just to satisfy path conventions. Do not start broader UI refactors in the same step. Do not change save or scene-manager contracts unless required for the battle route to work.
Verification: Scene/script inspection plus full-suite Godot test run after the main-path regression test is added.
Confidence: High because the step reuses a battle flow that already has prototype integration coverage.
Reproducibility: Repo root `D:\work\Games\SRPG`; test manifest in `tests/tests_manifest.txt`; verification via local Godot 4.6.2 executable.
Baseline: Formal battle scene is placeholder-only; prototype battle scene is playable and already covered by `tests/integration/prototypes/vs_battle_test.gd`.
Execution: Gate verdict = PASS. Target, environment, side effects, and success signal are explicit. Challenge refinements applied: keep one controller source of truth and verify the main path directly.
