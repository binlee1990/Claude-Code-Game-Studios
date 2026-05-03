Role: Senior game systems designer and cross-GDD consistency editor for a Godot idle cultivation RPG.

Context: The project already has 30 MVP system GDDs under `design/gdd/`, plus `game-concept.md`, `systems-index.md`, `design/registry/entities.yaml`, and `production/session-state/active.md`. The user explicitly invoked `$reframe-and-execute` and asked to optimize every GDD system, remove or simplify low-value unresolved questions, then apply the local `.claude` skills `consistency-check`, `review-all-gdds`, and targeted `design-review` repairs before refreshing status files.

Objective: Turn the 30 system GDDs into a cleaner, internally consistent, implementation-ready set by resolving stale or meaningless Open Questions, fixing cross-document issues, and updating the relevant index/session/review status records.

Success criteria: Every system GDD keeps the required core sections; stale "already resolved" questions are removed or converted into explicit decisions; remaining Open Questions are only real implementation, tuning, or Post-MVP risks; cross-GDD registry/index/session-state facts are consistent; review reports and review logs reflect the final pass; validation commands show no unresolved placeholder text, duplicate registry references, or missing required section headings.

Decomposition: 1. Diagnose current GDD structure, Open Questions, registry state, and status files. 2. Reframe and challenge the repair scope before edits. 3. Normalize system GDDs, especially `Open Questions`, without inventing new mechanics. 4. Run the consistency-check workflow against the registry and fix conflicts/stale registry data. 5. Run the review-all-gdds workflow, write a cross-GDD report, and fix blocking or simple warning findings. 6. Run targeted design-review-style checks on any GDDs still structurally risky, fix them, append review logs, and refresh index/session/task status.

Methodology: MECE decomposition by document surface (`Open Questions`, registry, cross-GDD relationships, targeted single-GDD review) plus dialectical challenge to prevent over-editing approved design content.

Output: Edited Markdown/YAML state in `design/gdd/`, `design/registry/entities.yaml`, `production/session-state/active.md`, `.tasks/active|completed/`, and any necessary `design/gdd/reviews/*.md` reports/logs.

Constraints: Do not revert user-made deletions or unrelated worktree changes. Do not add new dependencies. Do not create new gameplay scope. Do not mark systems Approved unless a design-review-style pass has actually found no blocking issues. Keep edits small, reversible, and focused on clarity, stale-question removal, consistency, and status freshness.

Non-assumptions: Do not assume every Open Question is bad; performance probes, implementation choices, and Post-MVP design risks may remain if they are real. Do not assume missing review-log files should be restored unless a fresh review produces a new log. Do not assume local Claude skill AskUserQuestion gates apply when the user's direct instruction is autonomous execution and the requested action is local documentation editing.

Verification: Validate draft and active task files with `validate-task.py`; scan all system GDDs for required headings and placeholder/question noise; run registry-focused consistency checks; run holistic cross-GDD review checks; run targeted single-GDD design-review checks for documents with missing sections or unresolved blockers; inspect `git diff --check` and `git status --short` before reporting.

Confidence: medium. The document set is fully local and inspectable, but review findings may require judgment because some open questions are intentionally deferred to Post-MVP or implementation profiling.

Reproducibility: Workspace `D:\work\Games\GUAJI_01`; date 2026-05-04 Asia/Shanghai; target directory `design/gdd`; local skills loaded from `.claude/skills/consistency-check`, `.claude/skills/review-all-gdds`, and `.claude/skills/design-review`.

Baseline: Before this task, 30 system GDDs exist; many docs contain stale or low-value `Open Questions`; `number-formatting-system.md` is the only detected system using `## Detailed Rules` instead of the project-wide `## Detailed Design`; `design/registry/entities.yaml` has duplicate `referenced_by` entries for several resources; prior review logs under `design/gdd/reviews/` are currently deleted in the worktree by pre-existing changes.

Execution: Gate verdict PASS. Challenge refinements: preserve meaningful performance/sign-off/Post-MVP risks; remove resolved rows instead of retaining ✅ noise; treat the registry as authoritative only where its source GDD still agrees; create fresh reports/logs for this run rather than restoring deleted historical logs.

Completion: 2026-05-04. Removed or simplified low-value Open Questions across all 30 system GDDs; retained only real profiling, tuning, implementation, or Post-MVP risks. Fixed registry category enum drift and duplicate `referenced_by` entries. Fixed EventBus/HUD subscription wording, SaveSystem/EventBus dependency, TimeManager stale systems-index note, FormulaEngine dependency note, Systems Index dependency map, and EnemyDatabase HP ownership ambiguity. Wrote fresh review records to `design/gdd/reviews/gdd-cross-review-2026-05-04.md` and `design/gdd/reviews/targeted-design-review-2026-05-04.md`. Refreshed `systems-index.md` reviewed count to 30 / 30 and cleared all deferred design-review markers from system GDDs.

Continuation: User requested continuing until all system statuses in `systems-index.md` are `Approved`. After the cleanup/review evidence showed no blocking issues, promoted all 30 system index rows and all 30 system GDD header statuses to `Approved`, updated `Design docs approved` to 30, and added `design/gdd/reviews/all-systems-approval-2026-05-04.md` as the final approval record.
