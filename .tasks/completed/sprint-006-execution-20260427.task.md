Role: Senior Godot SRPG production engineer implementing Sprint-006 end to end.

Context: The workspace is `D:\work\Games\SRPG` in Production stage. Sprint-006 is defined in `production/sprints/sprint-006.md` and already has QA/story artifacts generated for Bond, equipment enhancement, Base Phase 1, economy config, Ch.3 design, governance, and regression hardening. The worktree is dirty from prior accepted documentation/planning work, so existing changes must be preserved and modified in place only when they are part of Sprint-006.

Objective: Complete every Sprint-006 task and acceptance criterion, from implementation through automated verification and governance/status updates, without expanding into explicitly out-of-scope Sprint-007+ systems.

Success criteria: All Sprint-006 Must/Should/Nice tasks are implemented or documented as design-only where specified; Bond affinity can grow and round-trip through save data; equipment enhancement +1 through +5 is available from the character equipment UI with precise cost/shortage feedback and save round-trip; Base AP and Intel Room MVP are saveable and visible; Ch.3 battle 1 GDD is detailed; production status/epic/story/QA artifacts are synchronized; `godot --headless --check-only project.godot`, the GUT scene runner, Windows export, and packaged smoke pass.

Decomposition: 1. Inspect current save, events, inventory, equipment, character management, base, tests, and story/status boundaries. 2. Implement Bond domain model, GameEvents signal, save helpers, affinity hook, character summary UI, and tests. 3. Implement equipment enhancement UI integration, cost source helpers, failure/shortage feedback, event emission, and round-trip tests. 4. Implement Base ActionPoints model, save integration, training AP consumption, Intel read-only tab, base upgrade cost config, and tests. 5. Expand Ch.3 GDD and update Sprint-006 governance/story/QA/status files. 6. Run full verification and archive this active task with evidence.

Methodology: SCQA frames the gap between Sprint-006 planning and complete production evidence; MECE partitions work into Bond, Equipment, Base/Economy, Design/Governance, and Verification lanes.

Output: Code, data, tests, documentation/status updates, a completed task archive, and a concise final Chinese report listing changed files, simplifications, verification evidence, and remaining risks.

Constraints: Do not revert unrelated user/prior-agent changes. Do not add new dependencies. Stay inside Sprint-006 scope and keep Ch.3 combat implementation, Tavern, Base Upgrade UI, Fog-of-war, +6 equipment risk zone, and release sign-off out of scope. Prefer existing Godot/GDScript patterns and current UI/test infrastructure. Use local verification only; do not publish or deploy.

Non-assumptions: Do not assume skeleton docs imply runtime implementation outside the sprint. Do not assume existing dirty docs can be overwritten wholesale. Do not assume UI needs art assets beyond existing controls. Do not assume +6+ enhancement should be enabled just because core logic has risk-zone support.

Verification: Validate this task file with the reframe-and-execute validator; run targeted new unit/integration tests through the repo test runner; run `godot --headless --check-only project.godot`; run the GUT scene runner; run `git diff --check`; run Windows export and packaged smoke; inspect failures and iterate until PASS or a non-recoverable blocker is recorded.

Confidence: medium-high because Sprint-006 is already decomposed into stories and QA plans, but UI integration details require inspection before edits.

Reproducibility: Windows PowerShell workspace `D:\work\Games\SRPG`; current date 2026-04-27; local Godot executable discovered from existing verification commands or project scripts.

Baseline: Sprint-006 planning, QA plan, and stories exist, but runtime Bond/Base AP/Intel and player-facing enhancement UI are not yet complete.

Execution: Gate verdict PASS. Challenge refinements: treat existing Sprint/story/QA docs as the approved design gate; keep implementation minimal and domain-specific; reject new dependencies and large UI rewrites; verify with local Godot checks before claiming completion.

Completion update: Sprint-006 is complete as of 2026-04-27. Implemented Bond data/event/UI MVP, equipment enhancement +1~+5 UI/cost/round-trip, Base ActionPoints + Intel Room, base upgrade cost JSON, Ch.3 full GDD, story/epic/status/QA synchronization, and packaged smoke coverage.

Verification evidence: `godot --headless --check-only project.godot` PASS; `godot --headless res://tests/test_runner.tscn` PASS; `git diff --check` PASS; `godot --headless --export-release "Windows Desktop" builds/windows/SRPG.exe` PASS; `builds/windows/SRPG.exe --headless --srpg-playthrough-smoke` PASS with `{"base_enhanced_level":5,"battle":"chapter_01_finale","bond_growth_present":true,"camp_report_present":true,"management_tab":"equipment","success":true}`; process launch smoke PASS with exported exe still running after 5 seconds.

Remaining risks: Sprint-007+ still owns Tavern/Bond dialogue, Base Upgrade UI, +6 risk-zone equipment UI, Ch.3 runtime battles, Fog-of-war, and human subjective visual/release sign-off.
