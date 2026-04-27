Role: Senior Godot/GDScript engineer owning Sprint-008 implementation, verification, and production tracking.
Context: The repository is D:\work\Games\SRPG on branch 0.0.1. Sprint-007 is complete and pushed. Sprint-008 is defined by production/sprints/sprint-008.md and production/qa/qa-plan-sprint-8.md. The active scope is Chapter 3 battle 2, B3-GATE runtime branch persistence, Chapter 3 finale boss, equipment decompose/reroll UI, architecture/status documentation, and GDD-only handoff work for Bond combo and fog-of-war.
Objective: Execute every Sprint-008 item to COMPLETE without adding dependencies or expanding into Sprint-009 implementation scope.
Success criteria: Sprint-008 DoD is checked complete; Must/Should/Nice tasks have matching docs or code; required automated tests exist and pass; Godot check-only passes; GUT passes; Windows export succeeds; packaged smoke covers Ch.3 battle 2, B3-GATE, finale boss, decompose, and reroll; sprint-status and epic/story docs are synchronized.
Decomposition: Diagnose existing Ch.3, belief, save, equipment, and UI patterns; implement battle 2 data plus pressure evaluation; implement B3-GATE evaluator and SaveData round-trip; implement finale battle data and boss phase/route integration; implement equipment decompose/reroll UI and tests; update architecture, sprint, epic, QA, and handoff docs; run verification and archive this task.
Methodology: SCQA frames the sprint as a scoped production completion problem; MECE splits content, branch-state, equipment UI, governance, and verification so each acceptance path is testable.
Output: Code changes, data files, tests, production documentation updates, verification evidence, and a final concise completion report.
Constraints: No new dependencies or addons. Do not implement Bond combo skills, fog-of-war runtime, Ch.4, NG+, or equipment +11+. Preserve existing save compatibility. Keep changes aligned with existing Godot/GDScript patterns. Do not revert unrelated user or tool changes.
Non-assumptions: Do not assume sprint stories are complete merely because files exist. Do not assume B3-GATE state can be recomputed after save/load if the sprint requires persistence. Do not assume decompose/reroll UI can skip SaveData round-trip tests. Do not assume manual screenshot/playtest evidence blocks automated sprint completion unless the sprint marks it external.
Verification: Validate task files; run targeted tests during implementation; run project check-only; run full GUT scene runner; run Windows export; run packaged smoke; run git diff --check; confirm documentation status and DoD evidence.
Confidence: medium-high because Sprint-007 patterns exist, but risk remains around B3-GATE persistence and equipment UI integration in large scenes.
Reproducibility: Godot executable is expected at G:\SteamLibrary\steamapps\common\Godot Engine\godot.windows.opt.tools.64.exe. Test runner scene is res://tests/test_runner.tscn. Export script is tools/package_windows_release.ps1.
Baseline: Sprint-008 starts with sprint status PLANNING, battle 2/finale absent, B3-GATE placeholder only, equipment decompose/reroll UI incomplete, and GUT baseline reported by Sprint-007 as 855/855.

Execution:
Phase 3 challenge synthesis:
- Goal alignment: complete all Sprint-008 tasks, including Should/Nice, but keep Bond combo and fog-of-war to GDD only.
- Assumption validity: inspect actual code paths before adding new systems; reuse battle definition, SaveData, equipment, and UI patterns.
- Simpler alternative rejected: docs-only closure is insufficient because sprint DoD requires playable Ch.3 battle 2/finale, B3-GATE persistence, equipment UI, and automated tests.
- Catastrophic risk: save schema or battle flow regression. Safeguard with round-trip tests, full GUT, packaged smoke, and no dependency changes.
Execution gate verdict: PASS. Target is explicit, environment is known, side effects are repo-local and expected, and success signals are verifiable.

Phase 4 execution summary:
- Implemented Chapter 3 battle 2 data, pressure evaluation, beacon hold logic, and B3-N2 behavior scoring.
- Implemented B3-GATE evaluator, runtime narrative-choice belief deltas, persisted `story_progress.b3_gate`, and deterministic fallback routing.
- Implemented Chapter 3 finale battle data with B3-GATE route variants and three-phase boss smoke coverage.
- Implemented equipment decomposition and single-affix reroll UI in character management with resource costs, shortages, localization, and SaveData-friendly mutation.
- Updated architecture, Chapter 3/equipment/bond/fog epics, Sprint-008 QA plan, sprint status, and Sprint-009 handoff docs.
- Kept Bond combo runtime, fog-of-war runtime, Ch.4, NG+, and +11 equipment risk outside Sprint-008 scope.

Verification results:
- Task validation: PASS for draft and active task files.
- Godot check-only: PASS.
- Full GUT scene runner: `Total: 879 | Pass: 879 | Fail: 0`.
- Windows export: PASS, `builds/windows/SRPG.exe`, 124,334,616 bytes, SHA256 `A472CE209E17ABEB74D8281E4CEEA8B099665FA4026F4FE1E3C568A76DF2FD64`.
- Packaged smoke: PASS with Ch.3 battle 2, B3-GATE, finale boss, decompose, and reroll fields.

Completion verdict: PASS. Sprint-008 is complete. Final repository hygiene checks passed (`git diff --check` exit 0; status reviewed with expected Sprint-008 code, data, test, and documentation changes).
