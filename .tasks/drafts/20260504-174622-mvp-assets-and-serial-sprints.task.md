Role: Senior Godot MVP delivery engineer and technical art integrator.

Context: The workspace is D:\work\Games\GUAJI_01, a Godot 4.6 project with existing production sprint plans, QA plans, gameplay systems, and tests. The requested source asset plan is docs/plans/游戏资源生成.md. The sprint plans live under production/sprints and the QA gates live under production/qa. Existing AGENTS guidance requires autonomous execution, no new dependencies without explicit request, small reversible diffs, and verification before claiming completion.

Objective: Determine whether the asset-generation plan can satisfy the whole MVP's game-resource needs, improve the plan or implementation where needed, generate all required MVP resources, then execute production/sprints/sprint-1.md through sprint-10.md serially with each matching qa-plan passing or being fixed before the next sprint begins.

Success criteria: All MVP resource files required by docs/plans/游戏资源生成.md and by current data/UI consumers exist at their expected paths with valid dimensions/alpha or documented fallback status. The project data references these resources where useful for MVP runtime. For every sprint 1-10, the matching production/qa/qa-plan-sprint-N-2026-05-04.md has been executed as a gate, failures have been fixed when locally fixable, and evidence is recorded. Final verification includes Godot import/load checks, JSON parse checks, relevant tests or documented environment blockers, and git status summary.

Decomposition: 1. Baseline the current repo, assets, data, tests, and Godot availability. 2. Audit docs/plans/游戏资源生成.md against MVP consumers and identify missing or over-scoped assets. 3. Produce a deterministic asset manifest and generation pipeline that fills the required paths without adding dependencies. 4. Generate the assets, prompts, metadata, and QA evidence. 5. Wire art_path or equivalent references into data/config when the existing runtime benefits from it. 6. Execute sprint QA gates serially from sprint 1 to sprint 10, fixing code/config/test issues before advancing. 7. Run final validation and archive this task file.

Methodology: SCQA frames the mismatch between planned resources and actual MVP consumers. MECE decomposes work into assets, data wiring, sprint gates, fixes, and verification so no sprint or asset family is skipped. A dialectical challenge is used before execution to avoid mistaking a draft art list for a sufficient MVP resource contract.

Output: Code/config/asset changes in the repository, evidence files under production/qa/evidence, an active task log under .tasks/active, and a concise final report with changed files, simplifications made, validation verdict, and remaining risks.

Constraints: No new project dependencies. No destructive git operations. Do not skip sprint order. Do not claim visual image-generation fidelity if the local path uses deterministic fallback art. Preserve existing behavior unless a QA gate exposes a defect. Prefer existing Godot/data patterns and keep edits reversible.

Non-assumptions: Do not assume docs/plans/游戏资源生成.md is complete merely because it lists assets. Do not assume the previous .reframe-state.yml "complete" status means resource files exist or sprint QA has been freshly executed. Do not assume GdUnit4 or Godot CLI are available until verified. Do not assume image_gen output is saved to the repo unless the generated files are actually present.

Verification: Validate the task file with the reframe-and-execute validator. Validate generated PNG files with a local image parser, checking existence, dimensions, and alpha where required. Validate JSON configs parse. Run Godot headless/editor checks and test commands when available. Execute each QA plan's listed checks or closest local equivalent, record evidence, and re-run after fixes.

Confidence: Medium. The requested end state is clear, but full photoreal/hand-painted generation may be constrained by available local image-generation persistence and Godot/GdUnit availability.

Reproducibility: Windows PowerShell in D:\work\Games\GUAJI_01 on 2026-05-04. Generated artifacts should be deterministic where local scripts are used. External image generation, if used, is non-deterministic and must be recorded through prompt and metadata files.

Baseline: At start, assets contains only data JSON files and no UI/character/map/item/vfx PNG resources. production/sprints contains sprint-1.md through sprint-10.md. production/qa contains qa-plan-sprint-1 through qa-plan-sprint-10.
