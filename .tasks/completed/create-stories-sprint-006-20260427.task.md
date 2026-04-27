Role: Senior production engineer running the repository's /create-stories workflow for Sprint-006.

Context: The user invoked $reframe-and-execute and asked to run /create-stories for Sprint-006. Sprint-006 references story paths in production/sprint-status.yaml, and the QA plan generated earlier shows missing story artifacts for equipment enhancement, base action points/intel room, and resource economy base upgrade cost config. The repository review mode is solo, so QL-STORY-READY gates are skipped with notes rather than spawned.

Objective: Produce developer-ready Sprint-006 story artifacts for all sprint-status entries that target production/epics story files, without starting implementation.

Success criteria: Existing Bond Sprint-006 story files are upgraded with full story metadata; missing equipment/resource/base story files are created; base-system has a minimal EPIC container if required by the target paths; each story has title, epic, layer, priority, status, TR-ID or traceability note, ADR references, acceptance criteria, definition of done, test evidence, dependencies, and next-step handoff; Sprint-006 QA source gaps are updated to reflect the new artifacts.

Decomposition: 1. Read /create-stories contract plus Sprint-006, sprint-status, QA plan, EPICs, GDDs, ADRs, manifest, TR registry, and review mode. 2. Reframe missing artifacts into bounded story writes. 3. Challenge for unsupported scope, missing epic source, and stale TR registry. 4. Write story files and any minimal parent metadata needed for file routing. 5. Verify every sprint-status story path now exists and contains required sections. 6. Archive this task file with execution evidence.

Methodology: SCQA frames the ambiguous "run /create-stories for a sprint" request into concrete repository artifacts; MECE splits output by epic/system so story files are complete without implementing runtime code.

Output: Markdown story files under production/epics plus small metadata updates to QA/Sprint artifacts where needed.

Constraints: Do not implement gameplay code. Do not add dependencies. Do not revert unrelated working-tree changes. Keep writes scoped to Sprint-006 story/epic/QA/task artifacts and avoid changing human-only sprint queue semantics.

Non-assumptions: Do not assume missing story files are complete because sprint-status points to them. Do not assume readiness skeletons are developer-ready. Do not assume full Base system implementation is authorized; Sprint-006 scope is Action Points and Intel Room only.

Verification: Validate this task file, check all production/sprint-status.yaml story paths that point to production/epics exist, grep created/updated story files for required sections, run Godot check-only to ensure markdown/data edits did not disturb project parse, and report Sprint-006 source gap closure.

Confidence: medium-high - sprint, QA, GDD, ADR, and existing story patterns are local; the only judgment call is creating a minimal base-system EPIC container because Sprint-006 already references base story paths but no base epic exists.

Reproducibility: Windows PowerShell in D:\work\Games\SRPG on 2026-04-27; reframe validator at C:\Users\888\.codex\skills\reframe-and-execute\scripts\validate-task.py.

Baseline: Before this task, equipment-system story-008/009/010, resource-economy story-007, and base-system story-001/002 are missing; Bond Sprint-006 story files exist but are minimal readiness skeletons; production/qa/qa-plan-sprint-6.md lists these gaps as UNTESTABLE.

Execution: Completed 2026-04-27. Upgraded Sprint-006 Bond story files, created equipment story-008/009/010, created base-system EPIC plus story-001/002, created resource-economy story-007, updated relevant EPIC/index metadata, added TR-bond/TR-equip/TR-base/TR-resource entries to production/registries/tr-registry.yaml, and updated production/qa/qa-plan-sprint-6.md source gaps from missing to created. Verification results: task validator PASS; all production/sprint-status.yaml production/epics story paths exist; all 9 Sprint-006 story files contain required /create-stories sections; Godot check-only exit code 0; GUT scene runner exit code 0. Verdict: PASS.
