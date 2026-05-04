Role: Technical production planner for a Godot 4.6.2 idle RPG, operating under the repository's GDD-to-epic-to-story-to-sprint workflow.

Context: The workspace contains 30 approved MVP system GDDs under `design/gdd/`, accepted ADRs under `docs/architecture/`, a control manifest, and an existing partial Foundation epic set under `production/epics/`. The user explicitly requested autonomous execution using the local `create-epics`, `create-stories`, and `sprint-plan` skill contracts.

Objective: Generate complete production planning artifacts for every approved MVP system: one epic per GDD system, implementable story files for every epic, and AI-executable sprint plans covering all generated stories.

Success criteria: All 30 systems from `design/gdd/systems-index.md` have `production/epics/[slug]/EPIC.md`; every epic has at least one `story-NNN-[slug].md`; `production/epics/index.md` lists all epics; `production/sprints/` contains sprint plans with no more than 20 stories each; `production/sprint-status.yaml` tracks every planned story; generated artifacts cite the relevant GDD, TR-ID, ADR guidance, manifest version, and test evidence path.

Decomposition: 1. Read the three requested local skill contracts and repository planning inputs. 2. Parse systems, layers, GDD paths, TR registry entries, architecture module ownership, ADR coverage, engine version, and manifest rules. 3. Preserve existing Foundation epic intent while filling missing epic/story/sprint artifacts. 4. Generate epics in dependency order. 5. Generate story files from each GDD's acceptance criteria and governing ADRs. 6. Partition stories into AI-sized sprints by dependency order and context budget. 7. Validate counts, links, and traceability.

Methodology: Use MECE decomposition to keep system, epic, story, and sprint scopes non-overlapping; use thesis-antithesis-synthesis challenge before execution to avoid overbroad sprint scope and hallucinated traceability.

Output: Markdown epic files, story files, `production/epics/index.md`, sprint plan markdown files, `production/sprint-status.yaml`, and a final concise validation report.

Constraints: Do not add dependencies. Do not implement game code. Do not alter GDD/ADR source facts. Treat missing ADR coverage explicitly rather than inventing it. Keep sprint story count at or below 20. Use the existing production directory structure and Godot 4.6.2 manifest rules.

Non-assumptions: Do not assume every acceptance criterion maps to a unique TR-ID; use the stable system-level TR-ID where the registry provides only one requirement. Do not assume review gates can spawn Claude Task agents in this Codex environment; use review-mode notes and deterministic validation instead. Do not assume all existing production files are ours; preserve user-authored intent when regenerating.

Verification: Run the reframe task validator, then run repository-local validation scripts/commands that count systems, epics, stories, sprint tasks, missing links, missing ADR references, and sprint context-budget violations. Report PASS/PARTIAL/FAIL with evidence.

Confidence: medium-high. Source documents are local and approved, but story decomposition from GDD prose requires conservative grouping by acceptance criteria rather than human producer review.

Reproducibility: Windows PowerShell workspace `D:\work\Games\GUAJI_01`, current date 2026-05-04, engine Godot 4.6.2, review mode `full` found in `production/review-mode.txt`.

Baseline: Before this task, `production/epics/index.md` lists 4/30 Foundation epics and no story files; `production/sprints/` and `production/sprint-status.yaml` are absent.

Execution: Gate verdict PASS. Challenge synthesis: proceed with autonomous document generation because targets, environment, side effects, and verification are explicit; use generated QA test specs rather than spawning unavailable Claude Task gates; cap each sprint at 20 stories and label missing QA plan risk in every sprint. Generated 30 epics, 187 stories, 10 sprint plans, sprint index, and `production/sprint-status.yaml`. Validation command reported systems=30, epics=30, stories=187, sprints=10, sprint_links=187, max_sprint_stories=20, VERDICT: PASS.
