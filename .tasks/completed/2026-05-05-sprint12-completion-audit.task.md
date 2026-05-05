Role: Senior Godot/GDScript engineer and release verifier.

Context: Sprint 12 was documented as 100% complete after Claude execution, but the repository contained unverified source, data, project configuration, and QA-document changes. The working tree was intentionally dirty; unrelated user or Claude changes were not reverted. This task ran under the repository AGENTS.md tool-hygiene rule: shell commands must produce useful diagnostic or verification evidence.

Objective: Determine whether `production/sprints/sprint-12.md` was actually complete, then supplement implementation or documentation and fix all evidence-backed errors needed for Sprint 12 MVP Experience Glue to be internally consistent and runnable.

Success criteria: Sprint 12 data files are valid and loadable, changed GDScript parses under Godot, autoload/project configuration is coherent, listed stories have matching implementation or honest status, regression/QA commands that are available in this repo pass or have documented non-code blockers, and discovered defects are fixed with focused changes.

Decomposition: 1. Inspect Sprint 12 plan, epic docs, changed files, scripts, and Godot executable availability. 2. Establish baseline failures through JSON validation, sprint QA scripts, Godot parse/load checks, and relevant tests. 3. Challenge the completion claim against implementation evidence and simplify scope to fixable repo defects. 4. Patch proven defects in data, scripts, docs, and GDScript. 5. Re-run relevant checks and record evidence. 6. Deliver a concise Chinese report with changed files, simplifications, verification, and residual risks.

Methodology: SCQA framed the claimed-complete Sprint 12 versus missing evidence; MECE partitioned checks into data, Godot project wiring, GDScript/UI behavior, sprint docs, and QA evidence.

Output: Repository changes plus a concise final report in Chinese covering execution result, changed files, validation evidence, simplifications made, and remaining risks.

Constraints: Did not revert unrelated dirty worktree changes. Did not make destructive git or filesystem operations. Did not add new dependencies. Did not use shell commands for progress markers or self-talk. Used focused edits only.

Non-assumptions: Did not assume `Done 19/19` in the sprint file was true. Did not assume Claude-created files compile. Did not treat missing headless screenshots as blockers when scripts could still verify layout numerically. Did not assume generated art assets were part of Sprint 12 code correctness except where data paths referenced them.

Verification: Sprint 12 data consistency passed; Godot headless scene/layout/settings/4K validations passed; `validate_sprint12_experience.gd` passed; GdUnit unit+integration passed with 132 tests and 0 failures; Godot import exited 0.

Confidence: high for the fixed and verified Sprint 12 scope; medium for future work that would require LevelSystem to consume `exp_curve.json` directly.

Reproducibility: Workspace `D:\work\Games\GUAJI_01`, current date 2026-05-05, Godot path `G:\SteamLibrary\steamapps\common\Godot Engine\godot.windows.opt.tools.64.exe`.

Baseline: Initial evidence showed `production/sprints/sprint-12.md` claiming 19/19 done while `production/session-state/active.md` still said several Sprint 12 items were pending. Godot checks exposed compile/runtime wiring errors before the fixes.

Execution: Challenge synthesis treated the sprint completion claim as untrusted until verified. Attack vectors: (1) documentation can claim completion while UI and autoload wiring fail at runtime; (2) new JSON and GDScript can drift from existing loader/event APIs; (3) fixing hard failures and status contradictions has higher value than expanding feature scope; (4) a broken autoload or parse error can make the whole game unloadable. Execution gate verdict: PASS because the target, environment, side effects, and success signal were explicit and reversible.

Result: Completed. Evidence was recorded in `production/qa/evidence/sprint-12-completion-audit-2026-05-05.md`.
