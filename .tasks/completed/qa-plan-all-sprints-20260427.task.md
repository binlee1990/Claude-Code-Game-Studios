Role: Senior QA planner and Godot verification engineer for this SRPG repository.

Context: The user explicitly invoked $reframe-and-execute and asked to run /qa-plan for all sprints, then execute verification. The repository has numeric sprint files under production/sprints/sprint-001.md through sprint-006.md, an existing production/qa/qa-plan-sprint-3.md, and /qa-plan is represented by CCGS Skill Testing Framework/skills/utility/qa-plan.md. The project uses Godot 4.6.2 with GDScript and GUT, with machine-local Godot executable configured at G:\SteamLibrary\steamapps\common\Godot Engine\godot.windows.opt.tools.64.exe.

Objective: Generate or update QA plan documents for every numeric sprint in production/sprints and run available local verification that proves the QA plan set is complete and the project remains testable.

Success criteria: production/qa contains qa-plan-sprint-1.md through qa-plan-sprint-6.md; sprint-3 is updated rather than blindly replaced; each plan classifies stories by Logic, Integration, UI, Visual/Feel, Config/Data, or Documentation and assigns BLOCKING or ADVISORY evidence per .claude/docs/coding-standards.md; missing or acceptance-criteria-poor sprint items are explicitly flagged as UNTESTABLE or source gaps; verification commands are run and their results are recorded.

Decomposition: 1. Diagnose sprint scope, existing QA artifacts, test standards, and Godot tooling. 2. Reframe /qa-plan into concrete repository writes for numeric sprints only. 3. Challenge the plan for scope creep, stale evidence, missing story files, and verification limits. 4. Create or update QA plan documents and update sprint-006 pending QA status if appropriate. 5. Validate file presence/content and run Godot parse/test plus packaged smoke where available. 6. Archive this task file to completed or failed and report evidence.

Methodology: SCQA frames the ambiguous user command into the concrete repo problem; MECE decomposes sprint QA coverage by story type and verification gate so evidence requirements do not overlap or get skipped.

Output: Markdown QA plan files in production/qa plus a concise final report with changed files, validation verdict, assumptions, and remaining risks.

Constraints: Do not revert existing unrelated working-tree changes. Do not create new dependencies. Keep edits scoped to QA plan/task artifacts and the sprint-006 QA status line if needed. Do not treat the manual human queue sprint-人工.md as a numeric sprint unless explicitly requested; it remains a separate external validation backlog.

Non-assumptions: Do not assume sprint-006 story files exist just because sprint-status.yaml references them. Do not assume older sprint evidence is current unless the sprint file has a 2026-04-27 revalidation section or matching test/evidence files exist. Do not assume Godot is on PATH; use the configured executable path.

Verification: Run the reframe task validator, check that all six QA plan files exist, grep key required labels such as BLOCKING and UNTESTABLE/source gaps, run the configured Godot check-only command, run the GUT scene runner, and run the packaged smoke executable if present.

Confidence: medium-high - the sprint source files and standards are local and readable; sprint-006 has known planning gaps that require explicit risk labels rather than complete test mappings.

Reproducibility: Windows PowerShell in D:\work\Games\SRPG on 2026-04-27; Godot executable from .claude/settings.local.json / technical preferences; task validator from C:\Users\888\.codex\skills\reframe-and-execute\scripts\validate-task.py.

Baseline: Before this task, only production/qa/qa-plan-sprint-3.md exists, sprint-006 QA plan status is PENDING, and production/sprints/sprint-001.md through sprint-006.md contain the sprint source material.

Execution: Completed 2026-04-27. Created `production/qa/qa-plan-sprint-1.md`, `qa-plan-sprint-2.md`, `qa-plan-sprint-4.md`, `qa-plan-sprint-5.md`, and `qa-plan-sprint-6.md`; updated `production/qa/qa-plan-sprint-3.md` with current Sprint-003 revalidation mappings; updated the Sprint-006 QA plan status line to GENERATED. Validation results: task validator PASS; all six QA plan files present; Godot check-only exit code 0; GUT scene runner exit code 0; Windows export exit code 0; packaged smoke exit code 0 with `PACKAGED_PLAYTHROUGH_SMOKE PASS {"battle":"chapter_01_finale","camp_report_present":true,"management_tab":"equipment","success":true}`. Verdict: PASS with noted Sprint-006 source gaps for missing equipment/base/resource story files.
