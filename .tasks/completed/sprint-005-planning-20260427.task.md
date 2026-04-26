Role: Senior producer / technical planner for the SRPG Production phase.
Context: Sprint 1-4 are complete under the non-human execution scope. Current remaining evidence points to localization, credits/legal attribution, stale authority docs, Ch.3 readiness, and deferred system packaging. The user explicitly invoked reframe-and-execute and asked to continue planning Sprint 5.
Objective: Create a grounded `production/sprints/sprint-005.md` plan that defines the next executable sprint without starting feature implementation.
Success criteria: `production/sprints/sprint-005.md` exists; it names a coherent sprint goal, entry assumptions, tasks, dependencies, risks, execution order, and Definition of Done; scope excludes human-only validation and does not contradict Sprint 1-4 revalidation notes.
Decomposition: 1. Inspect Sprint 1-4, current epics, GDDs, and active backlog evidence. 2. Select a Sprint 5 theme from competing options. 3. Challenge the theme for overreach and dependency risk. 4. Write the sprint plan. 5. Validate references, status claims, and markdown consistency.
Methodology: SCQA to frame the post-Sprint-4 situation and MECE to separate release hygiene, localization, governance, and future-content readiness.
Output: A Markdown sprint plan at `production/sprints/sprint-005.md`, plus a concise final report with validation evidence.
Constraints: Documentation-only planning; no game implementation changes; no manual/human screenshot/playtest gates as blockers; no new dependencies; preserve existing dirty worktree changes outside the sprint planning files.
Non-assumptions: Do not assume Ch.2 human playtest data exists; do not assume public release is legally safe until Credits attribution is visible in-game; do not assume all designed systems can fit into Sprint 5 implementation.
Verification: Check the new sprint file exists, grep for key sections and story IDs, run markdown/diff sanity checks, and confirm only intended planning files were changed by this task.
Confidence: medium-high because the plan is grounded in local repository docs, but Sprint 5 priority still depends on product direction choices not explicitly restated by the user.
Baseline: Before this task there is no `production/sprints/sprint-005.md`; Sprint 4 lists base full, bond, ADR-008/009, and Ch.3 GDD as Sprint-005+ candidates; localization epic exists in Planning.
