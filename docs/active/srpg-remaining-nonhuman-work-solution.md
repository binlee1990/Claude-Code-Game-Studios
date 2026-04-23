# Standard Solution: SRPG Remaining Non-Human Work Program

## 0. Metadata

- Solution ID: SRPG-RNW-2026-04-24
- Version: v1.0
- Date: 2026-04-24
- Owner / Author: Codex
- Scope: Repository-side remaining work that does not require a human to execute directly
- Status: draft
- Related documents:
  - `production/stage.txt`
  - `production/session-state/active.md`
  - `production/project-stage-report.md`
  - `docs/active/srpg-current-overall-plan.md`
  - `production/epics/index.md`
  - `design/gdd/systems-index.md`
  - `docs/architecture/architecture.md`
  - `docs/architecture/ADR-004-combat-system.md`
  - `docs/architecture/ADR-005-ai-behavior.md`
  - `docs/architecture/ADR-006-attribute-data-model.md`
  - `docs/architecture/tr-registry.yaml`
- Related data sources:
  - `production/epics/*/EPIC.md`
  - `production/epics/*/story-*.md`
  - `tests/`
  - `src/`
- Related decisions:
  - Keep the project formally in `Pre-Production` until human-only gate evidence exists
  - Exclude human visual sign-off, subjective fun validation, and approval-only actions from the executable scope

---

## 1. Original Idea

### 1.1 Raw user wording

> 抛开必须人类执行的任务，全面识别剩余的所有未完成项，使用 `idea-to-solution` 转换成标准的解决方案和子任务，保存到 `D:\work\Games\SRPG\docs\active` 目录下。

### 1.2 Reframed problem statement

> We need to help the SRPG repository move from a vague “only human gate remains” narrative to an evidence-grounded inventory of all remaining non-human unfinished work, then convert that inventory into a standard solution package and actionable subtasks without starting implementation.

### 1.3 Current problem

- Current state:
  - The project is still `Pre-Production`, but current authority files say the automatable P3 chain is already complete.
  - The repo still contains substantial remaining non-human work, but it is split between true future backlog and stale authority metadata.
- Pain points:
  - Some documents still imply work is `Ready`, `Deferred`, `Partial`, or missing evidence even when code and tests already exist.
  - Some index files still claim that control manifest or foundation GDDs do not exist, which is now false.
  - Several designed systems exist in `design/gdd/` but have never been converted into executable `production/epics/`.
  - Architecture and ADR artifacts still contain drift against current game direction and current GDDs.
- Known impact:
  - Agents and humans can mis-prioritize work or reopen already finished lanes.
  - Future implementation could start from stale requirements, stale evidence pointers, or stale phase assumptions.
  - Post-gate backlog has no authoritative packaged execution surface.
- Cost of inaction:
  - Backlog authority remains fragmented.
  - Future agents will continue to misread what is done versus what is still pending.
  - New epics may be opened with incorrect prerequisites or stale story metadata.
- Relationship to current systems or processes:
  - This work sits between the completed vertical-slice implementation and any future automation beyond the current human-only gate.

### 1.4 Non-goals

- Perform human visual sign-off or subjective fun validation.
- Upgrade `production/stage.txt` out of `Pre-Production`.
- Accept ADRs or GDDs on behalf of human decision makers.
- Implement new gameplay systems, UI, or content.
- Produce art, music, narrative content, or manual review evidence.

---

## 2. Facts, Assumptions, and Unknowns

### 2.1 Verified facts

| ID | Fact | Source | Confidence | Expires? |
|----|------|--------|------------|----------|
| F1 | The authoritative stage is still `Pre-Production`. | `production/stage.txt` | high | no |
| F2 | Current session state says the automatable P3 chain is complete and the next blocker is human-only. | `production/session-state/active.md` | high | yes |
| F3 | `production/epics/index.md` marks 12 epics as `Complete`. | `production/epics/index.md` | high | yes |
| F4 | `design/gdd/systems-index.md` enumerates 23 designed systems, including 8 designed systems with no corresponding `production/epics/` directory for execution. | `design/gdd/systems-index.md`, `production/epics/` | high | yes |
| F5 | `docs/architecture/tr-registry.yaml` is still empty. | `docs/architecture/tr-registry.yaml` | high | yes |
| F6 | `production/epics/index.md` still claims that control manifest does not exist and that foundation GDDs do not exist, but `docs/architecture/control-manifest.md`, `design/gdd/art-style.md`, `design/gdd/save-system.md`, and `design/gdd/worldbuilding-narrative.md` all exist. | `production/epics/index.md`, `docs/architecture/control-manifest.md`, `design/gdd/` | high | yes |
| F7 | Multiple completed `EPIC.md` files still carry `Status: Ready` and “Next Step = /dev-story” guidance. | `production/epics/*/EPIC.md` | high | yes |
| F8 | `production/epics/camera-map-system/story-001-isometric-camera.md` is explicitly `Deferred`, and `story-003-save-load-integration.md` is explicitly `Partial`. | `production/epics/camera-map-system/story-001-isometric-camera.md`, `story-003-save-load-integration.md` | high | yes |
| F9 | `production/epics/turn-based-mode/story-005-auto-battle-mode.md` still says `Ready` and references `tests/unit/turn/auto_battle_test.gd`, but actual implementation and test evidence exist at `src/core/combat/auto_battle_controller.gd` and `tests/unit/turn/auto_battle_test.gd`. | `production/epics/turn-based-mode/story-005-auto-battle-mode.md`, `src/core/combat/auto_battle_controller.gd`, `tests/unit/turn/auto_battle_test.gd` | high | yes |
| F10 | `docs/architecture/architecture.md` still describes the presentation stack as `2.5D HD-2D (3D scene + pixel characters)`. | `docs/architecture/architecture.md` | high | yes |
| F11 | `docs/architecture/ADR-005-ai-behavior.md` uses boss thresholds `>70% / 50-70% / <50%`, while `design/gdd/boss-system.md` defines phase thresholds at `50% / 25%`. | `docs/architecture/ADR-005-ai-behavior.md`, `design/gdd/boss-system.md` | high | yes |
| F12 | `design/accessibility-requirements.md` and `design/ux/accessibility-requirements.md` both exist and are byte-identical. | repo file hash comparison | high | yes |
| F13 | `design/gdd/SRPG 核心模块设计总纲.md` still contains unresolved or stale “待细化事项” even though child GDDs now cover several of them. | `design/gdd/SRPG 核心模块设计总纲.md`, `design/gdd/gdd-cross-review-2026-04-22.md` | medium | yes |

### 2.2 Assumptions

| ID | Assumption | Why it matters | How to verify | If wrong |
|----|------------|----------------|---------------|----------|
| A1 | The designed-but-unepiced systems in `design/gdd/systems-index.md` still represent intended future scope rather than abandoned ideas. | Determines whether they belong in the remaining-work backlog. | User review or updated scope doc. | The future backlog would need pruning before epic creation. |
| A2 | Current repository state is a better authority than historical `production/session-logs/session-log.md` entries and stale placeholders. | Prevents false positives in the remaining-item inventory. | Reconcile any disputed item against current source, tests, and current authority docs. | The inventory would need a deeper evidence audit. |
| A3 | Audio content authoring, narrative approval, and art-direction approval remain human-owned even if technical integration can be scaffolded. | Keeps human-owned creative work out of the executable scope. | User confirms or later route-specific brief. | Audio or narrative tasks may need to move back into automatable scope. |
| A4 | The next safe automation lane is document and backlog authority repair, not direct feature implementation. | Shapes the recommendation away from scope expansion. | Confirm against current stage docs and user intent. | A more aggressive build-first plan might be acceptable. |

### 2.3 Unknowns

| ID | Unknown | Blocks progress? | Who confirms | Deadline |
|----|---------|------------------|--------------|----------|
| U1 | Whether the 2D top-down fallback is now the permanent direction or only the current vertical-slice fallback. | no | User / later design decision | Before camera-map story normalization is finalized |
| U2 | Whether bond, difficulty, boss, and fog-of-war should all become post-gate epics, or whether one subset should be deferred. | no | User / future backlog approval | Before epic scaffolding is implemented |
| U3 | Whether ADR-004/005/006 can be moved from `Proposed` to `Accepted` by agent-prepared evidence only, or require explicit human approval. | no | User / technical approver | Before any ADR status change |

### 2.4 Time-sensitive information

- Repository stage and backlog status are time-sensitive and were verified from the current local workspace.
- No external market, API, pricing, or policy claims are used in this solution.

---

## 3. Success and Acceptance

### 3.1 Business or user success criteria

- Produce one authoritative inventory of all remaining non-human unfinished work.
- Separate true unfinished implementation from stale documentation and metadata drift.
- Package future backlog into a reviewable, phased solution instead of an unstructured list.
- Leave clear boundaries around human-only gate tasks and human approval tasks.

### 3.2 Measurable metrics

| Metric | Current | Target | Measurement | Review cadence |
|--------|---------|--------|-------------|----------------|
| Remaining-work categories explicitly named | 0 unified artifact | 1 authoritative solution package | `docs/active/` artifact exists and covers all categories below | Once on creation |
| Immediate automatable authority-repair tracks identified | fragmented | 100% enumerated | Main solution + subtasks file | Once on creation |
| Designed-but-unepiced automatable systems explicitly listed | implicit in `systems-index` only | 100% listed with scope notes | Main solution file | Once on creation |
| Human-only tasks mislabeled as agent-executable | unknown | 0 | Manual readback of exclusions and work breakdown | Once on creation |

### 3.3 Failure conditions

- The inventory confuses stale metadata with missing implementation.
- Human-only gate tasks are mixed into executable subtasks.
- The solution only lists items and does not recommend an ordered path.
- The subtasks are too broad to hand off or verify.

### 3.4 Acceptance owners

- Business approver: repo owner / user
- Technical approver: repo owner / technical lead
- Security or compliance approver: not applicable for this solution artifact
- Final decision maker: repo owner / user

---

## 4. Constraints

### 4.1 Time constraints

- No external deadline is provided.
- The solution must be immediately usable as the next planning surface in `docs/active/`.

### 4.2 Resource constraints

- People: one agent authoring the solution; human review still required for approval-only actions
- Budget: no new dependencies, no paid tooling
- Tools: local repository inspection only
- Data: current repository files are the grounding source
- Permissions: documentation changes only

### 4.3 Technical, process, or compliance constraints

- Technical:
  - Prefer current authority files over stale session logs.
  - Do not treat placeholder status text as truth without evidence.
- Process:
  - Current phase remains `Pre-Production`.
  - Human-only validation remains excluded from execution subtasks.
- Compliance:
  - None beyond normal repository truthfulness.
- Security:
  - No sensitive external actions involved.

---

## 5. Solution Options

### 5.1 Option A - Minimal viable solution

- Description: Produce only a remaining-item inventory and stop.
- Pros:
  - Fastest to write.
  - Low risk of overcommitting the next phase.
- Cons:
  - Does not repair authority drift.
  - Leaves future backlog unpackaged.
  - Still forces the next session to do planning work again.
- Cost: low
- Risk: medium
- Best fit: If the user only wanted a one-off audit.

### 5.2 Option B - Standard solution

- Description: Produce an authority-grounded remaining-item inventory, recommend a phased program, and decompose it into subtasks covering authority repair plus future backlog packaging without starting implementation.
- Pros:
  - Converts ambiguity into an executable planning surface.
  - Separates immediate cleanup from future epic conversion.
  - Keeps human-only tasks excluded while still surfacing dependencies.
- Cons:
  - More upfront documentation work than a simple inventory.
  - Requires later approval before any execution lane is opened.
- Cost: medium
- Risk: low to medium
- Best fit: The current request.

### 5.3 Option C - Expanded solution

- Description: Treat every designed system without an epic as ready to implement immediately and open new execution lanes now.
- Pros:
  - Maximizes forward motion if the current stage gate is intentionally ignored.
  - Produces the largest immediate backlog.
- Cons:
  - Conflicts with current repository guidance that the human-only gate still frames the next phase.
  - Blurs the line between packaging work and implementation work.
  - Risks building on stale authority docs.
- Cost: high
- Risk: high
- Best fit: Only if the user explicitly chooses to bypass the current gate logic.

### 5.4 Option comparison

| Dimension | A | B | C |
|-----------|---|---|---|
| Cost | Low | Medium | High |
| Benefit | Medium | High | Medium |
| Risk | Medium | Low-Medium | High |
| Maintainability | Low | High | Low |
| Scalability | Low | High | Medium |
| Recommendation | No | Yes | No |

---

## 6. Recommended Solution

### 6.1 Recommendation

Recommended option:

> Option B — authority repair plus phased backlog packaging

Why:

1. It captures all remaining non-human unfinished work without pretending the repository is ready for immediate new feature execution.
2. It repairs the authority surface that future agents and humans will read first.
3. It keeps future post-gate systems visible and ordered without forcing implementation before the current stage logic is reconciled.

### 6.2 Core design

- Structure:
  - Workstream A: authority and metadata repair
  - Workstream B: architecture and traceability sync
  - Workstream C: post-gate vertical-slice extension backlog packaging
  - Workstream D: deferred alpha backlog packaging
- Core flow:
  - Inventory remaining work -> repair authority docs -> package future systems -> run consistency review -> hand off for approval
- Key components:
  - Current authority files (`production/`, `docs/active/`)
  - Execution backlog (`production/epics/`)
  - Design inventory (`design/gdd/`)
  - Architecture and traceability (`docs/architecture/`)
- Data flow:
  - Evidence from current repo files -> normalized remaining-work matrix -> phased solution -> subtasks
- Human and AI collaboration:
  - AI prepares inventory, sync plan, epic packaging, and consistency review artifacts
  - Human approves priorities, ADR acceptance, and any creative or approval-only decisions
- External dependencies:
  - None

### 6.3 Operating model

- Inputs:
  - Current stage docs
  - Current production epics and stories
  - Current design GDD inventory
  - Current architecture and traceability docs
- Processing:
  - Separate real incomplete work from stale placeholders
  - Group remaining work by executable lane
  - Preserve excluded human-only tasks as explicit out-of-scope items
- Outputs:
  - One standard solution package
  - One subtask register
  - A phased backlog boundary for future execution
- Feedback:
  - Human review on priorities and excluded scopes
  - Later reframe-and-execute pass for the approved phase
- Monitoring:
  - Consistency grep over `Status`, `Manifest Version`, `TR-IDs`, and evidence fields
- Rollback:
  - Revert or replace the planning docs if the program boundary is rejected

### 6.4 MVP boundary

Must include:

- A complete inventory of remaining non-human unfinished work
- Explicit distinction between true backlog and documentation drift
- A phased recommendation and ordered subtasks

Explicitly excludes:

- Human playtest execution and subjective validation
- Human acceptance of ADRs or creative decisions
- New gameplay implementation
- Art or audio asset production

### 6.5 Remaining-item inventory

#### A. Immediate authority-repair work

1. `docs/active/srpg-current-overall-plan.md` is stale relative to current sprint and phase evidence.
2. `production/epics/index.md` summary and known gaps are stale.
3. Completed `EPIC.md` files still marked `Ready` need normalization.
4. Completed story files still contain stale evidence placeholders, wrong test paths, or `N/A` manifest placeholders.
5. `docs/architecture/architecture.md` still describes a 2.5D / 3D presentation path that no longer matches the current vertical slice.
6. `docs/architecture/ADR-005-ai-behavior.md` conflicts with `design/gdd/boss-system.md`.
7. `docs/architecture/tr-registry.yaml` is still empty, so TR-backed story readiness remains incomplete.
8. `design/accessibility-requirements.md` and `design/ux/accessibility-requirements.md` need one canonical location.
9. `design/gdd/systems-index.md` and `design/gdd/SRPG 核心模块设计总纲.md` still contain stale tracker / TBD language.

#### B. Real remaining implementation backlog that is automatable in principle

1. `bond-system` — designed, no execution epic yet
2. `difficulty-system` — designed, no execution epic yet
3. `boss-system` — designed, no execution epic yet
4. `fog-of-war-system` — designed, no execution epic yet
5. `base-system` — designed, no execution epic yet
6. `new-game-plus-system` — designed, no execution epic yet
7. `event-system` — designed, no execution epic yet
8. `audio-system` technical integration shell — designed, but creative asset authoring remains human-owned

#### C. Real remaining partial or deferred implementation states

1. `camera-map-system/story-001-isometric-camera.md` is explicitly deferred under the current top-down fallback.
2. `camera-map-system/story-003-save-load-integration.md` is explicitly partial because rotation persistence remains deferred with the top-down fallback.

#### D. Explicit exclusions from executable scope

1. Human visual sign-off
2. Human subjective fun validation
3. Human acceptance of ADR status changes
4. Narrative/content approval
5. Art direction approval
6. Music and sound asset creation

---

## 7. Decomposition Decision

### 7.1 DDI scorecard

| Dimension | Score 0-3 | Notes |
|-----------|-----------|-------|
| Scope complexity | 3 | Spans multiple systems, documents, and backlog surfaces |
| Dependency count | 3 | Depends on current stage docs, epics, stories, design indexes, and architecture |
| Uncertainty | 2 | Some items are clearly stale, but some require distinction between drift and real backlog |
| Risk | 2 | Wrong classification will mislead future execution |
| Duration | 3 | Full execution would exceed one day if carried through |
| Roles involved | 2 | Agent authoring plus later human approval |
| Verification difficulty | 2 | Requires multi-part consistency checks |
| Reversibility | 1 | Documentation-only, but broad enough to cause process churn if wrong |
| Compliance or security impact | 0 | None |
| Change coupling | 3 | Touches planning, production tracking, and architecture surfaces |

Total score: 21

- 0-6: one task may be enough
- 7-12: split into 3-7 subtasks
- 13-20: split into phases plus subtasks
- 21+: treat as a project or epic and require discovery first

### 7.2 Decision

- Split required: yes
- Decomposition level: phases plus subtasks
- Rationale:
  - The work mixes discovery, authority repair, architecture sync, and backlog packaging.
  - Several forced-split rules apply: multi-system scope, more than three artifact types, verification cannot be stated in one sentence, and the work would exceed one day if executed as a single stream.
- Risk of not splitting:
  - Remaining work would be misclassified or reopened repeatedly by future agents.

---

## 8. Work Breakdown

| ID | Task | Type | Priority | Dependency | Acceptance | Owner | Status |
|----|------|------|----------|------------|------------|-------|--------|
| T1 | Build the authoritative remaining-work matrix from current repo state | discovery | P0 | — | Every remaining non-human item is classified as drift, real partial, future backlog, or excluded human work | Agent | proposed |
| T2 | Repair top-level active planning docs so they match current stage and backlog truth | design | P0 | T1 | `docs/active/` and `production/` summary docs no longer contradict the current repo state | Agent | proposed |
| T3 | Normalize completed `EPIC.md` headers, next-step text, and stale `Ready` statuses | design | P0 | T1 | Completed epics stop advertising `/dev-story` as the next step | Agent | proposed |
| T4 | Backfill story evidence metadata, manifest placeholders, and wrong test paths; isolate the real partials | design | P0 | T1 | Completed stories point to real evidence or tests, and only true partials remain non-complete | Agent | proposed |
| T5 | Repair architecture sync artifacts: top-down direction, boss-threshold mismatch, traceability gaps, duplicate accessibility file policy | design | P0 | T1 | Architecture docs no longer conflict with current GDDs and current presentation direction | Agent | proposed |
| T6 | Populate or plan-populate TR registry coverage for the already-built epics | design | P1 | T5 | TR gap is either filled or turned into an explicit bounded follow-up package | Agent | proposed |
| T7 | Refresh `systems-index` and the concept doc tracker/TBD sections from current child GDD evidence | design | P1 | T1 | Designed-system tracker stops advertising stale review and TBD states | Agent | proposed |
| T8 | Convert `bond-system`, `difficulty-system`, `boss-system`, and `fog-of-war-system` into a post-gate epic package | design | P1 | T5, T7 | Each system has an execution-ready epic surface or readiness brief | Agent | proposed |
| T9 | Convert `base-system`, `new-game-plus-system`, `event-system`, and `audio-system` technical shell into a deferred alpha package | design | P2 | T7 | Deferred systems have explicit backlog packaging with human-owned content excluded | Agent | proposed |
| T10 | Run a repository consistency review over planning, epics, stories, and architecture after packaging | review | P1 | T2, T3, T4, T5, T6, T7, T8, T9 | No remaining contradictory high-signal authority file is left unclassified | Agent | proposed |
| T11 | Prepare an approval handoff for ADR acceptance and post-gate priority selection | review | P1 | T5, T8, T9 | Human approver can choose priorities without rediscovering repo state | Agent + Human | proposed |

---

## 9. Delivery Plan

### 9.1 Phases

| Phase | Goal | Tasks | Output | Exit criteria |
|-------|------|-------|--------|---------------|
| Phase 1 | Repair authority before any new execution lane opens | T1-T7 | Corrected planning, epic, story, and architecture surfaces | Remaining drift is bounded and documented |
| Phase 2 | Package future automatable backlog without implementing it | T8-T9 | Post-gate vertical-slice package and deferred alpha package | Every designed-but-unepiced non-human system has a bounded future surface |
| Phase 3 | Validate and hand off | T10-T11 | Consistency review + approval packet | A later execution pass can start from a stable planning surface |

### 9.2 Sequence

1. Build the authoritative matrix.
2. Repair high-signal planning and metadata drift.
3. Repair architecture and traceability sync.
4. Package post-gate and deferred future backlog.
5. Run consistency review and prepare handoff.

### 9.3 Parallel versus sequential work

Can run in parallel:

- T2, T3, and T4 after T1
- T7 alongside T2-T5 once the inventory is stable
- T8 and T9 after T7

Must remain sequential:

- T1 before all other work
- T5 before T6 and before final backlog packaging
- T10 after all repair and packaging tasks
- T11 after T5, T8, and T9

---

## 10. Validation

### 10.1 Deterministic checks

- Re-run grep for non-complete epic and story statuses after authority repair.
- Re-run grep for stale `Not yet created`, `Manifest Version: N/A`, and `TR-IDs not yet registered`.
- Verify `docs/active/` contains the solution artifact and subtask register.
- Verify each designed-but-unepiced system is explicitly categorized in the solution package.
- Verify excluded human-only tasks are present only in exclusions, not in executable subtasks.

### 10.2 AI-assisted review

- Requirement coverage review:
  - Check that all remaining non-human categories from current repo state appear in the solution.
- Risk review:
  - Re-check that drift items are not mislabeled as missing implementation.
- Hallucination check:
  - Any claim must be traceable to a local repo file.
- Citation or source check:
  - Facts must mention the authoritative file path.
- Consistency review:
  - Check that recommendation, work breakdown, and exclusions agree with each other.

### 10.3 Human review

- Business review:
  - Confirm whether the listed future systems still belong to scope.
- Technical review:
  - Confirm whether the authority-repair order is acceptable.
- Security review:
  - Not required for this artifact.
- Legal or compliance review:
  - Not required for this artifact.

### 10.4 Acceptance cases

| Case | Input | Expected output | Pass condition |
|------|-------|-----------------|----------------|
| AC1 | Current repo stage + backlog docs | One remaining-work inventory | All non-human remaining work is categorized without mixing in human-only tasks |
| AC2 | Completed epics with stale statuses | A drift-repair lane | The solution explicitly treats stale `Ready` / evidence placeholders as repair work |
| AC3 | Designed systems without epics | Future backlog package | Every non-human designed system without an epic is listed and phased |
| AC4 | Human-only gate tasks | Explicit exclusions | Human-only tasks appear only in exclusions and approval notes |

---

## 11. Risks and Rollback

### 11.1 Risk register

| Risk | Probability | Impact | Prevention | Response |
|------|-------------|--------|------------|----------|
| Drift is mistaken for missing implementation | medium | high | Always verify against current code/tests and current authority docs | Reclassify the item and rerun the inventory |
| Future backlog is over-expanded | medium | medium | Keep human-owned creative work excluded | Prune the backlog package and mark systems as deferred |
| Current gate intent is ignored | low | high | Keep the recommendation solution-only and post-gate aware | Re-scope to authority repair only |
| Architecture mismatch remains after packaging | medium | medium | Include a dedicated sync workstream | Re-run T5 before any future execution |

### 11.2 Common failure modes

- Producing only a list, not a usable solution.
- Treating historical logs as authority.
- Mixing approval tasks with agent-executable work.
- Forgetting to package the designed-but-unepiced systems.

### 11.3 Rollback plan

- Rollback trigger:
  - The user rejects the classification or the proposed phase boundaries.
- Rollback steps:
  - Remove or replace the `docs/active/` artifacts.
  - Regenerate a narrower solution artifact from the corrected scope.
- Rollback owner:
  - Agent or repo owner
- Rollback verification:
  - `docs/active/` only contains accepted active planning documents.

---

## 12. Feedback and Evolution

### 12.1 What to capture after execution

- Which remaining items were confirmed as real implementation backlog
- Which items turned out to be pure metadata drift
- Which designed systems were intentionally deferred or pruned
- Which human-only tasks still needed explicit exclusion language
- Which validation checks caught the most stale signals

### 12.2 Update suggestions

| Problem | Frequency | Suggested update | Include in next version? |
|---------|-----------|------------------|--------------------------|
| Completed epics still advertise `/dev-story` | high | Add a repo-wide post-story-close normalization pass | yes |
| Story evidence placeholders remain after implementation | high | Add evidence-field sync to the definition of done | yes |
| Architecture and design docs drift after presentation pivots | medium | Add an architecture sync checkpoint after major product-direction changes | yes |

---

## 13. Final Decision

- Recommended path: Option B — authority repair plus phased backlog packaging
- Ready for implementation? no
- Needs human approval? yes
- Needs more research? no
- Next step: Execute Phase 1 authority-repair subtasks, then prepare the post-gate backlog package for user review.
