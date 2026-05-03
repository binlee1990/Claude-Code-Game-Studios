Role: Senior game systems designer and Godot technical design reviewer.
Context: The cross-GDD review in design/gdd/reviews reports a FAIL verdict. Some findings are stale because later edits already added debug-console support APIs; other findings still hold, especially OMS sub-unit base rates and EventBus contract gaps.
Objective: Apply evidence-backed GDD fixes for still-valid review findings without pretending unresolved future-system design work is complete.
Success criteria: OMS no longer routes sub-unit production rates through BigNumber before accumulation; EventBus no longer promises impossible GDScript try/catch behavior and lists missing event namespaces; stale debug-console gap language is resolved; systems-index and production session state reflect the new status and remaining blockers.
Decomposition: 1. Compare review findings against current GDD text. 2. Patch still-valid consistency defects. 3. Refresh index/session state. 4. Run text-level consistency searches and task validation.
Methodology: SCQA to separate stale review context from current blockers; dialectical thesis-antithesis-synthesis to avoid blindly applying every review recommendation.
Output: Markdown GDD patches plus refreshed production/session-state/active.md and archived task record.
Constraints: No new dependencies; keep edits scoped to design docs and task state; do not create full new MVP bridge-system GDDs without a dedicated design pass; preserve existing approved decisions unless contradicted by current evidence.
Non-assumptions: Do not assume every review item is still valid; do not assume EventBus can catch GDScript runtime exceptions; do not assume BigNumber should be changed to support exponent < 0 after its approval decision.
Verification: Validate this task file with the skill validator, search for stale phrases and contradictory signatures, inspect git diff, and ensure session state names the completed fixes plus remaining risks.
Confidence: medium-high because the fixes are grounded in local review evidence and current GDD text; remaining game-loop design blockers need separate system GDDs.
Baseline: production/session-state/active.md recorded review verdict FAIL with OMS sub-unit zeroing, EventBus gaps, and bridge systems not designed.
Execution: Patched OMS, EventBus, debug-console, reverse interaction references, systems-index, and production session state. Deliberately did not create new level/auto-production/cultivation GDDs because those are bridge-system design tasks, not consistency repair.

## Challenge

Thesis: Apply the cross-review required actions directly.

Antithesis 1: Some required actions are stale. Debug-console upstream APIs and EventBus pattern subscription already exist, so rewriting them as missing would regress status accuracy.

Antithesis 2: The suggested OMS fix "convert float to BigNumber at the end" is insufficient when the final per-tick amount is still below 1, because BigNumber intentionally clamps exponent < 0 to ZERO.

Synthesis: Keep BigNumber's approved boundary, store production rates as float, add fractional tick carry to OMS, resolve EventBus implementability and namespace gaps, refresh stale status, and leave new bridge-system GDDs as explicit remaining blockers rather than inventing them inside a repair pass.

execution_gate.verdict: PASS
