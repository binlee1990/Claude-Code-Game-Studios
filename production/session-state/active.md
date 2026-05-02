# Active Session State

> Living checkpoint. Updated after each significant milestone.
> Read this file first after any compaction, crash, or `/clear`.

**Last Updated**: 2026-05-03
**Project Stage**: Pre-Production — MVP signed off; Tier 2 BasicAI, Map Variant Pack, Runtime Map Selection, and Weighted Terrain Movement implemented
**Active Sprint**: Sprint 9 — Weighted Terrain Movement complete

<!-- STATUS -->
Epic: Map / Coordinates
Feature: Weighted Terrain Movement
Task: Sprint 9 implemented and verified with automated runner plus rough terrain scene smokes
<!-- /STATUS -->

---

## Sprint Planning Rule

Future sprints should be sized for AI execution, not human-day capacity. Prefer batching 3-6 coherent stories per sprint when they share a verification surface and can be completed in one automated pass.

Use these boundaries:
- Group work by integration risk and test surface, not by how long a human would need.
- Include multiple independent data/content/test stories in one sprint when the runner can prove them together.
- Split only when a story changes architecture boundaries, runtime UX, asset pipeline defaults, or requires a separate product decision.
- Every AI-sized sprint still needs a crisp Definition of Done, automated verification, and a clean final status update.

---

## Sprint Status Summary

### Sprint 1 — Foundation + Core MVP
- Implementation: complete
- QA Plan: `production/qa/qa-plan-sprint-1-2026-04-30.md`
- QA Sign-Off: `production/qa/qa-signoff-sprint-1-2026-05-02.md`
- Current revalidation: ✅ clean

### Sprint 2 — Feature Layer MVP
- Implementation: complete
- QA Plan: `production/qa/qa-plan-sprint-2-2026-05-02.md`
- QA Sign-Off: `production/qa/qa-signoff-sprint-2-2026-05-02.md`
- Current revalidation: ✅ clean

### Sprint 3 — Presentation Layer
- Implementation: 8-1 through 8-8 done in `production/sprint-status.yaml`
- 8-8 Unit 已行动灰色 modulate: ✅ verified by `tests/unit/unit/unit_scene_visual_test.gd`
- QA Plan: `production/qa/qa-plan-sprint-3-2026-05-02.md`
- QA Sign-Off: `production/qa/qa-signoff-sprint-3-2026-05-02.md`
- Current revalidation: ✅ clean

### Sprint 7 — Map Variant Pack
- Implementation: complete
- Story: `production/epics/map/story-005-map-variant-pack.md`
- Scope: 3 project-native CSV map variants + automated validation
- Evidence: `tests/unit/map/map_variant_pack_test.gd`, default runner `Total Passed: 297`
- Explicitly out of scope: decorative raster maps, prop packs, unit sprites, map-selection UI

### Sprint 8 — Runtime Map Selection
- Implementation: complete
- Sprint: `production/sprints/sprint-8.md`
- QA Plan: `production/qa/qa-plan-sprint-8-2026-05-03.md`
- Scope: manifest query, runtime map selection, spawn fixture consumption, multi-map scene smoke
- Sprint sizing: 4 coherent stories, planned as one AI-sized integration batch
- Evidence: `tests/unit/map/map_variant_manifest_test.gd`, `tests/unit/ui/game_map_mode_test.gd`, default runner `Total Passed: 297`, clean scene smokes for default, `--map=crossroads`, and `--map=split_lanes --enemy-ai=basic`

### Sprint 9 — Weighted Terrain Movement
- Implementation: complete
- Sprint: `production/sprints/sprint-9.md`
- QA Plan: `production/qa/qa-plan-sprint-9-2026-05-03.md`
- Scope: rough terrain cost model, weighted MovementResolver, rough map fixture, BasicAI terrain awareness, rough terrain scene smoke
- Sprint sizing: 5 coherent stories, implemented as one AI-sized rules/validation batch
- Evidence: `tests/unit/map/map_loading_test.gd`, `tests/unit/movement/movement_bfs_test.gd`, `tests/unit/ai/basic_ai_test.gd`, `tests/unit/map/map_variant_pack_test.gd`, default runner `Total Passed: 297`, clean scene smokes for default, `--map=rough_pass`, and `--map=rough_pass --enemy-ai=basic`

---

## MVP Status

```text
Implementation coverage:
  Foundation:   Map/Grid implemented
  Core:         Unit, Turn implemented
  Feature:      Movement, Attack, Victory, AI implemented
  Presentation: UI/Input implemented

QA status:
  Automated MVP QA signed off for Sprint 1-3.
  Sprint 3 should-have visual state story 8-8 is implemented and covered by automated structural test.
  Human editor QA is complete: CP1-CP10 and综合检查 all passed in production/qa/visual-verification-checklist.md.
  Sprint 8 Runtime Map Selection is implemented and covered by automated tests plus multi-map scene smokes.
  Sprint 9 Weighted Terrain Movement is implemented and covered by automated tests plus rough terrain scene smokes.
```

---

## Test Summary (Current Audit)

Command:

```powershell
& 'G:\SteamLibrary\steamapps\common\Godot Engine\godot.windows.opt.tools.64.exe' --headless --path . --script res://tests/test_runner.gd
```

Observed output summary:

```text
Total Passed: 297
SCRIPT ERROR: 0
Assertion failed: 0
ERROR lines: 0
WARNING lines: 0
```

Scene smoke:

```powershell
& 'G:\SteamLibrary\steamapps\common\Godot Engine\godot.windows.opt.tools.64.exe' --headless --path . --scene res://src/Game.tscn --quit-after 2
& 'G:\SteamLibrary\steamapps\common\Godot Engine\godot.windows.opt.tools.64.exe' --headless --path . --scene res://src/Game.tscn --quit-after 2 -- --map=rough_pass
& 'G:\SteamLibrary\steamapps\common\Godot Engine\godot.windows.opt.tools.64.exe' --headless --path . --scene res://src/Game.tscn --quit-after 2 -- --map=rough_pass --enemy-ai=basic
```

```text
SCRIPT ERROR: 0
Assertion failed: 0
ERROR lines: 0
WARNING lines: 0
```

---

## Current Audit Artifacts

| File | Action | Purpose |
|------|--------|---------|
| `production/qa/qa-execution-audit-2026-05-02.md` | Updated | Sprint 1-3 QA execution audit, resolved blocker list, and 8-8 status alignment |
| `production/qa/qa-signoff-sprint-2-2026-05-02.md` | Created | Sprint 2 sign-off |
| `production/qa/qa-signoff-sprint-3-2026-05-02.md` | Updated | Sprint 3/MVP automated QA sign-off including 8-8 |
| `tests/unit/unit/unit_scene_visual_test.gd` | Created | Unit scene visual regression coverage |
| `production/sprints/sprint-1.md` | Updated | Clean revalidation status |
| `production/sprints/sprint-2.md` | Updated | DoD and QA status |
| `production/sprints/sprint-3.md` | Updated | DoD and QA status including 8-8 |
| `production/qa/qa-plan-sprint-1-2026-04-30.md` | Updated | Current clean DoD evidence |
| `production/qa/qa-plan-sprint-2-2026-05-02.md` | Updated | Executed QA plan evidence |
| `production/qa/qa-plan-sprint-3-2026-05-02.md` | Updated | Executed QA plan evidence including 8-8 automated test |
| `production/qa/evidence/story-8-7/playtest-notes.md` | Updated | 10-checkpoint automated evidence |
| `production/sprint-status.yaml` | Updated | QA audit metadata and per-story QA status, including 8-8 verified |
| `docs/architecture/architecture-review-2026-04-30.md` | Updated | Current architecture review refresh |
| `design/gdd/game-concept.md` | Updated | MVP status and next-step convergence |
| `src/unit/Unit.tscn` | Updated | Unit visual controls ignore mouse so board clicks reach InputHandler |
| `src/ui/debug_overlay.gd` | Updated | Grid boundary lines and full row/column coordinate coverage |
| `src/ui/HUD.tscn` | Updated | HUD moved outside the 1024px board into a right-side panel |
| `project.godot` | Updated | Viewport widened to provide HUD panel space |
| `tests/unit/ui/debug_overlay_test.gd` | Created | Regression coverage for grid lines and `(5,12)` coordinate |
| `production/qa/visual-verification-checklist.md` | Updated | Final manual QA pass: CP1-CP10 and综合检查 all passed |
| `src/ai/basic_ai.gd` | Created | Tier 2 BasicAI pure ActionList planner |
| `tests/unit/ai/basic_ai_test.gd` | Created | BasicAI behavior, no-TurnManager import, and WorldState immutability coverage |
| `production/sprints/sprint-4.md` | Created | Tier 2 BasicAI interface validation sprint |
| `production/epics/ai/story-003-basic-ai-nearest-target.md` | Created | BasicAI implementation story |
| `src/turn/ai_action_executor.gd` | Created | Turn-layer executor for AI ActionPlan movement/attack/wait semantics |
| `src/turn/turn_manager.gd` | Updated | ENEMY phase now invokes AIController and executes non-empty ActionLists |
| `src/game.gd` | Updated | TurnManager receives Map and shared AttackResolver while default scene remains NullAI |
| `tests/unit/turn/turn_ai_execution_test.gd` | Created | NullAI hotseat preservation, BasicAI runtime execution, WorldState handoff, and wrong-faction guard coverage |
| `production/sprints/sprint-5.md` | Created | Runtime AI ActionList execution sprint |
| `production/epics/ai/story-004-runtime-actionlist-execution.md` | Created | Runtime AI execution story |
| `project.godot` | Updated | Adds `srpg_mini/enemy_ai_mode="hotseat"` default |
| `src/game.gd` | Updated | Selects NullAI or BasicAI from project setting / command-line override |
| `tests/unit/ui/game_ai_mode_test.gd` | Created | AI mode selection coverage for project setting and `--enemy-ai` arguments |
| `production/sprints/sprint-6.md` | Created | Runtime AI mode selection sprint |
| `production/epics/ai/story-005-runtime-ai-mode-selection.md` | Created | Runtime AI mode selection story |
| `production/sprints/sprint-7.md` | Created | Completed Map Variant Pack sprint using `$generate2dmap` as a tactical data workflow |
| `production/epics/map/story-005-map-variant-pack.md` | Created | Completed map-variant content/data story |
| `assets/data/maps/crossroads.csv` | Created | Sprint 7 tactical map variant |
| `assets/data/maps/central_choke.csv` | Created | Sprint 7 tactical map variant |
| `assets/data/maps/split_lanes.csv` | Created | Sprint 7 tactical map variant |
| `assets/data/maps/map_variants.json` | Created | Map variant spawn fixture manifest |
| `tests/unit/map/map_variant_pack_test.gd` | Created | CSV load, spawn legality, connectivity, and blocked/obstacle validation |
| `production/sprints/sprint-8.md` | Created | Completed AI-sized Runtime Map Selection sprint |
| `production/qa/qa-plan-sprint-8-2026-05-03.md` | Created | Executed QA plan for manifest, runtime map selection, spawn fixture consumption, and scene smoke matrix |
| `production/epics/map/story-006-mapvariantmanifest.md` | Created | Completed manifest query boundary story |
| `production/epics/map/story-007-runtime-map-selection.md` | Created | Completed runtime map selection story |
| `production/epics/map/story-008-game-spawn-fixture-consumption.md` | Created | Completed spawn fixture consumption story |
| `production/epics/map/story-009-multimap-runtime-smoke.md` | Created | Completed multi-map smoke story |
| `src/map/map_variant_manifest.gd` | Created | Runtime query boundary for map variant names, dimensions, and spawn fixtures |
| `tests/unit/map/map_variant_manifest_test.gd` | Created | Manifest load/query/fallback coverage |
| `tests/unit/ui/game_map_mode_test.gd` | Created | Runtime map selection, spawn fixture placement, and invalid spawn fallback coverage |
| `src/game.gd` | Updated | Selects map by project setting / CLI override and places units from selected-map fixtures |
| `project.godot` | Updated | Adds `srpg_mini/map_name="test_map"` default |
| `production/sprints/sprint-9.md` | Created | Completed AI-sized Weighted Terrain Movement sprint |
| `production/qa/qa-plan-sprint-9-2026-05-03.md` | Created | Executed QA plan for rough terrain cost model, weighted movement, BasicAI terrain awareness, and scene smoke matrix |
| `production/epics/map/story-010-rough-terrain-cost-model.md` | Created | Completed rough terrain cost model story |
| `production/epics/map/story-011-rough-pass-map-variant.md` | Created | Completed rough terrain map fixture story |
| `production/epics/movement/story-004-weighted-terrain-movement.md` | Created | Completed weighted movement resolver story |
| `production/epics/ai/story-006-basic-ai-terrain-awareness.md` | Created | Completed BasicAI terrain awareness story |
| `assets/data/maps/rough_pass.csv` | Created | Rough terrain map variant |
| `assets/data/maps/map_variants.json` | Updated | Adds `rough_pass` map entry and spawn fixture |
| `src/map/map.gd` | Updated | Adds `ROUGH` tile state and `get_movement_cost()` |
| `src/movement/movement_resolver.gd` | Updated | Upgrades reachability from uniform BFS to movement-cost aware search |
| `tests/unit/movement/movement_bfs_test.gd` | Updated | Covers rough terrain budget limits and lower-cost path reconstruction |
| `tests/unit/ai/basic_ai_test.gd` | Updated | Covers BasicAI rough terrain cost-awareness through MovementResolver |

---

## Architecture

- 10 ADR files present (0001-0010); `docs/architecture/architecture.md` records 63/65 ADR coverage (97%)
- 8/8 MVP systems implemented + integrated at implementation layer
- `docs/architecture/architecture-review-2026-04-30.md` refreshed to current PASS / no blocking architecture gaps
- Sprint 8 preserved architecture boundaries: map selection lives in the `Game` composition root and manifest parsing lives behind `src/map/map_variant_manifest.gd`
- Sprint 9 preserved architecture boundaries: terrain cost lookup lives in `Map`, movement cost search lives in `MovementResolver`, and BasicAI consumes terrain only through MovementResolver
