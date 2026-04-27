# Story CH3-c-001: Ch.3 Battle 1 Implementation

> **Epic**: Chapter 03 Content
> **Status**: Complete
> **Layer**: Content
> **Type**: Config/Data + Integration
> **Priority**: Must Have
> **Sprint**: Sprint-007
> **TR-ID**: TR-ch3-001
> **Manifest Version**: 2026-04-26-v2
> **Estimate**: 1.5 days

## Context

**GDD**: `design/gdd/chapter-03.md` §3.1, §3.2, §4, §7
**Sprint source**: `production/sprints/sprint-007.md` / CH3-c-001
**QA plan**: `production/qa/qa-plan-sprint-7.md`
**ADR References**: ADR-001, ADR-003, ADR-004

Implement the first playable Chapter 3 battle slice. This story creates the battle definition, battle loading route, and automated evidence that the battle can boot and resolve victory. B3-GATE runtime branching stays placeholder-only.

## Acceptance Criteria

- [x] `src/ui/combat/battle_definitions/chapter_03_act_a.json` or the chosen repo-standard battle data path exists and loads without parser errors.
- [x] The battle definition includes battle id, objective, briefing, map size, terrain, units, settlement, `progress_on_start`, and `progress_on_victory`.
- [x] Ch.3-1 contains at least 5 enemy units, 3 civilian/NPC target units, and 1 Ch.2 state influence point.
- [x] Scene routing can move from `chapter_03_intro` or current campaign progress into `chapter_03_act_a`.
- [x] Automated test covers battle boot and one victory-condition path.
- [x] B3-GATE runtime branching is not implemented; only placeholder/progress fields are written.

## QA Test Conditions

- Given the battle JSON is loaded headlessly, when the definition loader parses it, then all required keys exist and unit counts meet the GDD minimum.
- Given a save lacks Ch.3 progress fields, when Ch.3-1 is loaded, then fallback state is valid and no crash occurs.
- Given victory is simulated through the supported smoke/test path, when settlement runs, then campaign progress advances to the post-battle/base state.
- Given B3-GATE fields are inspected after Ch.3-1, then no hard-lock route is written by this story.

## Test Evidence

**Completed**: `tests/integration/prototypes/battle_arena_entry_test.gd` covers Ch.3 boot and Ch.2 finale routing; packaged smoke covers Ch.3 victory/base handoff.
**Gate**: PASS

## Dependencies

- Depends on: CH3-EPIC-001, `design/gdd/chapter-03.md`
- Unlocks: CH3-c-002, B3-GATE implementation planning, Sprint-007 packaged smoke extension

## Files to Create / Modify

| File | Action | Notes |
|---|---|---|
| `src/ui/combat/battle_definitions/chapter_03_act_a.json` | Create | Battle 1 data |
| `src/ui/menu/main_menu.gd` or campaign route owner | Modify | Route from progress to Ch.3-1 |
| `tests/integration/chapter03/battle_1_test.gd` | Create | Boot/victory evidence |
| `tests/tests_manifest.txt` | Modify | Register new test |

## Next Step

Complete 2026-04-27. Next runtime stories remain Ch.3 battle 2/3 and B3-GATE runtime branching for Sprint-008+.
