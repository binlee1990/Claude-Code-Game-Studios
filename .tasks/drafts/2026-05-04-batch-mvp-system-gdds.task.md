Role: Senior game systems designer and Godot-oriented technical design reviewer.

Context: The project is a Chinese idle cultivation loot RPG. The existing `design/gdd/systems-index.md` lists 30 MVP systems; 15 are already designed and 15 remain `Not Started`. The user explicitly invoked `$reframe-and-execute` and requested use of `.claude/skills/design-system`, with every user-choice gate defaulting to the recommended option.

Objective: Complete the design documentation for every remaining `Not Started` MVP system in `design/gdd/systems-index.md` without changing already authored GDDs except for required index/session-state progress updates.

Success criteria: All 15 remaining MVP systems have concrete Markdown GDD files with Overview, Player Fantasy, Detailed Design, Formulas, Edge Cases, Dependencies, Tuning Knobs, Acceptance Criteria, UI/visual notes, Cross-References, and Open Questions; no `[To be designed]`, `TBD`, or `TODO` placeholders remain; `systems-index.md` marks the 15 systems as `Designed` and links each design doc; Progress Tracker reports 30 / 30 MVP systems designed.

Decomposition: 1. Load reframe/design-system instructions and project context. 2. Identify remaining systems and filenames. 3. Build concise but implementable GDDs in dependency order. 4. Update systems index and session state. 5. Validate by scanning generated docs for required sections and placeholders. 6. Archive this task file when complete.

Methodology: SCQA for aligning the batch task with the existing MVP concept; MECE for splitting the 15 systems by Feature, Feature Integration, Simulation, and Presentation layers.

Output: Fifteen new `design/gdd/*.md` files plus updates to `design/gdd/systems-index.md`, `production/session-state/active.md`, and the archived reframe task record.

Constraints: No new dependencies. Do not overwrite existing GDD content. Preserve existing system boundaries: resources store values only, OMS computes passive tick amounts, LevelSystem owns exp consumption, CombatCalculator owns deterministic battle math, offline systems batch through the offline simulation core. Use Godot 4.6.2 / GDScript assumptions from `.claude/docs/technical-preferences.md`.

Non-assumptions: Do not assume Post-MVP systems such as equipment affixes, pets, sect economy, full breakthrough, or cloud saves exist. Do not mark new GDDs as Approved because independent review is not being run in this same session. Do not invent new MVP resources beyond the registry-backed `lingqi`, `xiuwei`, `lingshi`, `herb`, and `exp`.

Verification: Run the reframe task validator on draft/active files; scan all generated GDDs for required headings and placeholder terms; verify the systems index has no `Not Started` rows and reports `MVP systems designed | 30 / 30`; inspect `git status --short` for the final changed file set.

Confidence: medium-high. The remaining systems are well constrained by the existing concept, systems index, registry, and upstream GDDs; independent creative/QA director review is deferred to fresh-session `/design-review` per project workflow.

Reproducibility: Workspace `D:\work\Games\GUAJI_01`; date 2026-05-04; engine preferences Godot 4.6.2 + GDScript; review mode file currently `full`, but batch execution records review as deferred rather than approved.

Baseline: Before execution, `systems-index.md` has 15 / 30 MVP systems designed and rows 16-30 are `Not Started` with no design-doc paths.
