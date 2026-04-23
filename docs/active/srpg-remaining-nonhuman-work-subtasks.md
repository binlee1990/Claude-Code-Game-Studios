# Subtasks: SRPG Remaining Non-Human Work Program

## Subtask Register

This file expands the recommended solution in `srpg-remaining-nonhuman-work-solution.md` into independently actionable subtasks.

---

## ST-01 Authority Inventory

- Type: discovery
- Priority: P0
- Goal:
  - Build the authoritative remaining-work matrix from the current repository.
- Inputs:
  - `production/stage.txt`
  - `production/session-state/active.md`
  - `production/epics/index.md`
  - `design/gdd/systems-index.md`
  - `docs/architecture/`
- Outputs:
  - One matrix that labels each item as drift, real partial, future backlog, or excluded human work
- Includes:
  - Evidence collection
  - Classification rules
- Excludes:
  - File edits outside planning artifacts
- Acceptance:
  - Every remaining non-human item mentioned in the standard solution is traceable to repo evidence

## ST-02 Summary Doc Drift Repair

- Type: design
- Priority: P0
- Goal:
  - Sync the high-signal planning docs to the current repo truth.
- Inputs:
  - ST-01 matrix
  - `docs/active/srpg-current-overall-plan.md`
  - `production/project-stage-report.md`
  - `production/epics/index.md`
- Outputs:
  - Updated summary docs with no stale “missing control manifest / missing foundation GDD” claims
- Includes:
  - Stage-summary corrections
  - Backlog-summary corrections
- Excludes:
  - Human gate verdict changes
- Acceptance:
  - Summary docs no longer contradict current files in `design/gdd/` or `docs/architecture/`

## ST-03 Epic and Story Metadata Normalization

- Type: design
- Priority: P0
- Goal:
  - Normalize completed epic and story metadata so the backlog surface stops reopening completed work.
- Inputs:
  - ST-01 matrix
  - `production/epics/*/EPIC.md`
  - `production/epics/*/story-*.md`
  - `tests/`
  - `src/`
- Outputs:
  - Correct epic statuses
  - Correct story statuses
  - Correct evidence pointers and test paths
- Includes:
  - `Ready` -> `Complete` normalization for built epics
  - Fixing stale evidence placeholders
  - Fixing `story-005-auto-battle-mode.md` test-path drift
- Excludes:
  - Changing true partial/deferred camera-map items into complete
- Acceptance:
  - Only real deferred/partial items remain non-complete

## ST-04 Architecture and ADR Sync Package

- Type: design
- Priority: P0
- Goal:
  - Bring architecture surfaces back into alignment with the current GDD and current presentation direction.
- Inputs:
  - `docs/architecture/architecture.md`
  - `docs/architecture/ADR-004-combat-system.md`
  - `docs/architecture/ADR-005-ai-behavior.md`
  - `docs/architecture/ADR-006-attribute-data-model.md`
  - `design/gdd/boss-system.md`
  - `design/accessibility-requirements.md`
  - `design/ux/accessibility-requirements.md`
- Outputs:
  - A corrected architecture narrative
  - Resolved boss-threshold drift
  - One canonical accessibility requirements location
- Includes:
  - 2D top-down versus 2.5D architecture sync
  - ADR content repair
  - duplicate-file decision
- Excludes:
  - Flipping ADR status to `Accepted`
- Acceptance:
  - Architecture docs stop conflicting with current GDDs and current build direction

## ST-05 Traceability and Registry Readiness

- Type: design
- Priority: P1
- Goal:
  - Remove the “TR-IDs not yet registered” blind spot from the built backlog.
- Inputs:
  - `docs/architecture/tr-registry.yaml`
  - `docs/architecture/architecture-traceability.md`
  - built epic and story files
- Outputs:
  - A populated or explicitly phased TR coverage plan
  - Updated traceability notes for built systems
- Includes:
  - Registry population planning
  - Traceability synchronization
- Excludes:
  - New feature implementation
- Acceptance:
  - Future story readiness no longer depends on an empty registry

## ST-06 Vertical Slice-Extension Epic Packaging

- Type: design
- Priority: P1
- Goal:
  - Convert the non-human designed systems closest to the current slice into post-gate epics or readiness briefs.
- Inputs:
  - `design/gdd/bond-system.md`
  - `design/gdd/difficulty-system.md`
  - `design/gdd/boss-system.md`
  - `design/gdd/fog-of-war-system.md`
  - ST-04 outputs
- Outputs:
  - Epic surfaces or readiness briefs for bond, difficulty, boss, and fog-of-war
- Includes:
  - Dependency ordering
  - Story skeletons
  - Explicit gate notes
- Excludes:
  - Implementation work
  - Human-only balance approval
- Acceptance:
  - Each post-gate vertical-slice extension system has an executable planning surface

## ST-07 Deferred Alpha Backlog Packaging

- Type: design
- Priority: P2
- Goal:
  - Package the later Alpha backlog without mixing in human-owned creative production.
- Inputs:
  - `design/gdd/base-system.md`
  - `design/gdd/new-game-plus-system.md`
  - `design/gdd/event-system.md`
  - `design/gdd/audio-system.md`
- Outputs:
  - Deferred epic or readiness package for base, NG+, event, and audio technical shell
- Includes:
  - system boundary notes
  - explicit exclusions for art/audio content creation
- Excludes:
  - Music composition
  - voice direction
  - narrative approval
- Acceptance:
  - Deferred systems are visible in backlog planning without pretending creative work is agent-executable

## ST-08 Systems Index and Concept Doc Refresh

- Type: design
- Priority: P1
- Goal:
  - Update `systems-index` and the concept doc so they stop advertising stale review and TBD states.
- Inputs:
  - `design/gdd/systems-index.md`
  - `design/gdd/SRPG 核心模块设计总纲.md`
  - child GDDs
- Outputs:
  - Updated tracker counts
  - Reduced stale TBD list
  - Correct next-step language
- Includes:
  - tracker refresh
  - concept-doc cleanup for now-resolved items
- Excludes:
  - Creating new game design that has no grounding in child GDDs
- Acceptance:
  - Parent design index and concept doc reflect the current designed landscape

## ST-09 Consistency Review and Handoff

- Type: review
- Priority: P1
- Goal:
  - Verify that the repaired authority surface and packaged backlog no longer fight each other.
- Inputs:
  - Outputs from ST-02 through ST-08
- Outputs:
  - Consistency review summary
  - Human approval packet for next execution choice
- Includes:
  - grep-based status review
  - contradiction scan
  - phase handoff summary
- Excludes:
  - Human approval itself
- Acceptance:
  - A later execution pass can choose a phase without rediscovering repo truth

---

## Recommended Order

1. ST-01
2. ST-02
3. ST-03
4. ST-04
5. ST-05
6. ST-08
7. ST-06
8. ST-07
9. ST-09

## Parallel Notes

- ST-02 and ST-03 can run in parallel after ST-01.
- ST-08 can overlap with ST-04 once the inventory is stable.
- ST-06 and ST-07 can run in parallel after ST-08.

## Human-Owned Exclusions

- Visual sign-off
- Fun validation
- ADR acceptance
- Narrative approval
- Art direction approval
- Music and sound asset creation
