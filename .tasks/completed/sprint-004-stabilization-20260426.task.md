Role: Senior Godot/GDScript engineer and regression investigator.
Context: Sprint 004 added management UI and base MVP on top of an already-dirty worktree. Claude reported several fixed issues plus remaining runtime crashes, test code errors, possible cascades, and five failing tests. The repository uses Godot 4.6.2 via `G:\SteamLibrary\steamapps\common\Godot Engine\godot.windows.opt.tools.64.exe`, an in-tree GUT-compatible runner at `tests/gdunit4_runner.gd`, and autoloaded `Inventory`.
Objective: Stabilize Sprint 004 by fixing confirmed runtime and test-suite regressions, then perform an independent full audit for undiscovered Sprint 004 issues.
Success criteria: Godot parse/check succeeds; GUT runner completes without parse/load/runtime crashes; previously reported `_battle._inventory`, `Inventory.new()`, dictionary access, equipment/HP/class cascade, stack overflow, division by zero, and settlement restore failures are either fixed or explicitly disproven by current evidence; final report lists changed files, simplifications, verification, and residual risks.
Decomposition: 1. Establish current baseline with explicit Godot executable and repository searches. 2. Fix confirmed P0/P1 blockers before interpreting P2 failures. 3. Re-run tests and use failures to locate remaining true defects. 4. Independently scan Sprint 004 touched code for risky patterns such as autoload shadowing, invalid child indexing, null component access, missing methods, stale field references, and parse-only failures. 5. Patch narrowly using existing patterns and no new dependencies. 6. Verify with parse/check and full GUT suite.
Methodology: SCQA to separate Claude's stale/cascade claims from current evidence; MECE to divide blockers into runtime entry crashes, test harness/model errors, logic assertion failures, and audit-only warnings.
Output: Code/test patches plus a concise final engineering report with files changed, simplifications, test evidence, and remaining risks.
Constraints: Preserve existing dirty user/Claude work; do not revert unrelated changes; do not add dependencies; keep diffs small and reversible; use `apply_patch` for manual edits; no destructive git operations.
Non-assumptions: Do not assume Claude's issue list is complete or still accurate; do not assume all reported cascade errors are root causes; do not assume `Inventory` can be instantiated via autoload name; do not assume a passing targeted test proves the full sprint is stable.
Verification: Use explicit Godot 4.6.2 executable for `--check-only` and scene-mode `res://tests/test_runner.tscn`; inspect test output for failures, load errors, stack traces, and engine warnings; rerun after each blocker class.
Confidence: medium because the baseline is dirty and Sprint 004 code is newly added, but the repo contains a deterministic test runner and clear failure reports.
Reproducibility: Windows PowerShell in `D:\work\Games\SRPG`; Godot executable `G:\SteamLibrary\steamapps\common\Godot Engine\godot.windows.opt.tools.64.exe`; current date 2026-04-26.
Baseline: Initial user-reported trend was 753/758 passing after partial Claude fixes; current baseline will be measured before patching.

Challenge:
Thesis: Follow Claude's proposed order and patch the known failures first.
Antithesis: Claude's report may be stale after partial edits; patching reported cascades directly could mask true root causes or overfit tests.
Synthesis: Establish current baseline first, fix only reproduced root causes, then audit Sprint 004 code for the same classes of defects.

Challenge:
Thesis: Test failures are mostly stale test code and can be fixed by rewriting tests to use autoloads.
Antithesis: Autoload state is global and shared; simply switching tests to global `Inventory` can introduce order dependence and hide production bugs.
Synthesis: Prefer loading the inventory script resource directly for isolated inventory model tests; use the autoload only where the production surface intentionally uses autoload state, and reset it around those tests.

Execution gate:
Target is explicit: yes, Sprint 004 UI/base/management/resource regressions and current failing tests.
Environment is known: yes, Windows PowerShell plus explicit Godot 4.6.2 executable.
Side effects are acceptable: yes, local code/test edits only in a dirty working tree, no destructive git operations.
Success signal is verifiable: yes, parse/check and GUT output.
Verdict: PASS.

Execution log:
- Created task boundary before code edits.
- Baseline confirmed scene-mode GUT at 758 total, 753 pass, 5 failures, 2 load errors, plus stack overflow/underflow noise.
- Reframed Claude's list into root causes: stale private inventory field access, autoload-as-class misuse, global inventory state leakage, management tab recursion, missing equipment UI method, and stale CI runner.
- Patched Inventory reset/deserialize behavior, BattleArena inventory use, management tab state handling, equipment/character management guards, isolated resource tests, and CI runner command.
- Added BaseHub and Chapter 2 entry regressions.
- Final verification: `--check-only project.godot` passed; scene-mode GUT passed 792/792 with 0 failures and no load errors; headless main menu and base scene smoke produced no script errors, warnings, or engine errors after headless BGM guards.

Evaluation:
VERDICT: PASS
Basis: All targeted runtime/test failures are fixed, undiscovered runner/state/zero-HP risks were addressed, and full scene-mode GUT is green.
Blocking Issues: none.
Revision History: One test-load parse issue in new BaseHub test was revised by replacing `:= find_child()` with dynamic `var`.
