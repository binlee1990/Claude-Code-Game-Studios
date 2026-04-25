Role: Senior Godot SRPG production engineer and technical lead.

Context: The project is already in Production with a playable formal battle path, Chapter 1 tutorial content, SaveManager integration, P3 core systems, and post-battle settlement rewards. The user explicitly requested `$reframe-and-execute`, wants all systems completed, and authorized default recommended choices when a decision would otherwise require user input. Existing working-tree changes must be preserved; no new dependencies should be added without a direct need.

Objective: Complete the remaining SRPG systems by turning already implemented core logic into player-visible, saveable, test-covered production paths until the game has a coherent playable loop beyond a single tutorial battle.

Success criteria: The game can progress from main menu into Chapter 1, complete at least two battles, apply settlement rewards, enter a camp/campaign management path, use party/equipment/class/skill growth affordances from UI, apply tactical modifiers and AI/Boss behavior in formal battle, save/load those states, and pass Godot check-only, full automated tests, diff checks, Windows export, and launch smoke.

Decomposition: 1. Inventory existing systems and identify exact code targets. 2. Materialize campaign progression and battle-definition selection. 3. Add camp/campaign UI path with default recommended actions for growth and loadout. 4. Integrate tactical terrain/height/weapon/element modifiers into formal damage and AI context using existing core modules. 5. Improve formal enemy and Boss behavior by reusing existing AI modules where possible. 6. Add dedicated or richer settlement/campaign transition presentation. 7. Add regression coverage for each player-visible loop. 8. Update production evidence and stage docs after verification.

Methodology: SCQA frames the production gap from a single battle into a complete loop; MECE decomposes the remaining systems into campaign, camp, combat integration, AI, persistence, UI, content, and verification lanes.

Output: Code changes, tests, production evidence files, and a concise Chinese final report with changed files, simplifications, verification, and remaining risks.

Constraints: Do not revert user or prior-agent changes. Do not introduce new dependencies. Prefer existing core systems over new abstractions. Keep edits scoped to production paths and tests. Use default recommended choices instead of asking the user unless an action is destructive or externally visible. Keep packaged artifacts local and do not publish or deploy.

Non-assumptions: Do not assume “all systems” means release-quality art/audio/localization/live-ops; treat it as all already designed/implemented gameplay systems having a coherent player path. Do not assume every design document feature can be fully content-complete in one batch. Do not assume dirty files are safe to overwrite without reading them first.

Verification: Run `godot --headless --check-only project.godot`, `godot --headless res://tests/test_runner.tscn`, `git diff --check`, Windows release export, and process launch smoke. Add targeted integration tests for new campaign/camp/combat system paths before claiming completion.

Confidence: medium — the current repo has many core systems already implemented, but “all systems” is broad and final completeness depends on available local code and existing scene structure.

Reproducibility: Windows PowerShell workspace `D:\work\Games\SRPG`; Godot executable `G:\SteamLibrary\steamapps\common\Godot Engine\godot.windows.opt.tools.64.exe`; current date 2026-04-25.

Baseline: Before this task, Chapter 1 tutorial battle and settlement rewards are playable and tested, but Chapter 1 follow-up content, campaign/camp flow, full tactical integration, richer AI/Boss behavior, and polished transition screens are not yet complete.
