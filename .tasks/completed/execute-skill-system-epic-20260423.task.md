Role: Senior Godot gameplay engineer implementing the Skill System epic as the next roadmap step.
Context: The active roadmap and session state show that the battle slice is stable enough to proceed into the first post-slice backlog epic. The next ordered epic is `skill-system`. The repository already has patterns for stateful per-unit components, formula-driven unit tests, and save/load integration that should be reused instead of inventing a new subsystem architecture from scratch.
Objective: Complete the Skill System epic end-to-end so the repository moves from a stable vertical slice into the next substantive progression system.
Success criteria: 1. Skill state exists as first-class per-unit data. 2. All seven skill-system stories are represented in implementation and test evidence. 3. Save/load round-trips cover skill progression, traits, cooldown, and frozen class skills. 4. Full-suite verification passes.
Decomposition: 1. Create skill data model + skill component. 2. Implement progression/rank/trait/damage logic. 3. Hook class change behavior into class skills. 4. Add serialization and integration tests. 5. Update production status documents from evidence.
Methodology: SCQA for sequencing and MECE for splitting the epic into non-overlapping code/test concerns.
Output: Source, tests, and synced docs for the Skill System epic.
Constraints: Keep work within the skill-system epic. Do not fabricate UI screens that belong to other layers. Prefer deletion/reuse over extra abstraction. Maintain a passing repository.
Non-assumptions: Do not treat “Ready” docs as done. Do not under-scope the epic to a single story. Do not leave story 007 implicit under generic unit serialization without dedicated tests.
Verification: `godot.windows.opt.tools.64.exe --headless res://tests/test_runner.tscn` and `godot.windows.opt.tools.64.exe --headless --check-only project.godot`.
Confidence: Medium-high.
Reproducibility: Repo root `D:\work\Games\SRPG`.
Baseline: No implemented skill-system module exists yet; this pass creates it.
Execution: Gate verdict = PASS. Target, environment, side effects, and success signal are explicit. Challenge refinements applied: finish the whole next epic, not just the first story.
