# Active Session State

> Living checkpoint. Updated after each significant milestone.
> Read this file first after any compaction, crash, or `/clear`.

**Last Updated**: 2026-04-29
**Project Stage**: Pre-Production / Concept → Systems Design

---

## Current Task

UI / Input GDD started (Overview written). 7/8 MVP systems complete.

## Status

- ✅ `/start` — onboarded, review-mode = `lean`
- ✅ `/brainstorm SRPG` — `design/gdd/game-concept.md` (322 lines)
- ✅ `/setup-engine` — Godot 4.6.2-stable / GDScript / GdUnit4 testing
- ✅ `/art-bible` — `design/art/art-bible.md`
- ✅ `/map-systems` — `design/gdd/systems-index.md` (8 MVP + 8 Tier 2/3)
- ✅ `/design-system map` → `design/gdd/map.md`
- ✅ `/design-system unit` → `design/gdd/unit.md`
- ✅ `/design-system turn` → `design/gdd/turn.md`
- ✅ `/design-system movement` → `design/gdd/movement.md`
- ✅ `/design-system attack` → `design/gdd/attack.md`
- ✅ `/design-system victory` → `design/gdd/victory.md`
- ✅ `/design-system ai` → `design/gdd/ai.md` (433 lines, 30 AC, registry updated)
- 🟡 `/design-system ui` — `design/gdd/ui.md` (skeleton + Overview written; Player Fantasy next)
- Remaining: Turn GDD has 5 flagged inconsistencies from Victory+AI GDDs → `/consistency-check`

## Attack GDD Summary

- **File**: `design/gdd/attack.md` (570 lines)
- **Sections**: All 8 required + Visual/Audio + UI + Open Questions
- **Key decisions**: Manhattan distance for range; auto-enter targeting after move; direct attack from SELECTED allowed; floor=1 guarantee; no counter-attack (reserved signal)
- **Registry**: `damage_formula`, `damage_floor`, `rng_metric` registered; `turn_cap` referenced_by updated
- **Map GDD erratum flagged**: `get_neighbors()` for Attack replaced by Manhattan + `get_unit_at()`
- **Unit GDD update needed**: state machine table needs SELECTED → ACTED path added

## Key Decisions Made

- **Engine**: Godot 4.6.2 / GDScript / Forward+ / Jolt physics (defaults). Local binary at `G:\SteamLibrary\steamapps\common\Godot Engine\godot.windows.opt.tools.64.exe`.
- **MVP scope**: 8 orthogonal modules (Map · Unit · Turn · Movement · Attack · AI[NullAI] · Victory · UI/Input). Hot-seat playable; no audio; no story; no flavor.
- **Faction handling**: embedded in Unit GDD at MVP, pre-registered for Tier 2 extraction.
- **Visual stance**: Programmer Art Functional. All visual assets code-drawn at MVP. Tile size = 64×64. 16 color tokens locked.
- **Architecture risks tracked**: Map coordinate boundary leakage (R4), Unit interface stability (5 downstream consumers), AIController interface design (R5 — Tier 2 AI rewrite risk).

## Files Being Worked On

| File | Status | Purpose |
|------|--------|---------|
| `design/gdd/game-concept.md` | Approved (lean — no director sign-off) | Concept + 8-module decisions |
| `design/art/art-bible.md` | Approved | Visual identity + color tokens + asset standards |
| `design/gdd/systems-index.md` | Approved | Dependency map + design order + risk register |
| `.claude/docs/technical-preferences.md` | Populated | Engine + naming + performance + testing + specialists |
| `docs/engine-reference/godot/VERSION.md` | Updated | Pinned to 4.6.2; Steam binary recorded |
| `CLAUDE.md` | Updated | Technology Stack populated |

## Open Questions

- Q1 (from game-concept): turn-cap value — data-driven from day 1 (Pillar 1) confirmed; specific N to be set in Turn System GDD
- Q2 (from game-concept): AIController location — per-faction strategy node vs per-unit child? → resolve in `/architecture-decision` after AI GDD
- Q3 (from game-concept): obstacle tiles → RESOLVED in Map GDD: same TileMapLayer, different atlas cell; blocked/obstacle distinct states provisioned for future LOS

## Next Steps (in order)

1. `/design-system map` — Order 1 (Foundation, S effort)
2. `/design-system unit` — Order 2 (Core, M, embeds Faction enum, locks interface)
3. `/design-system turn` — Order 3 (Core, S)
4. `/design-system movement` `/design-system attack` `/design-system victory` — Orders 4-6 (parallelizable)
5. `/design-system ai` — Order 7 (Feature, M, AIController interface is the deliverable)
6. `/design-system ui` — Order 8 (Presentation, L, last)
7. `/review-all-gdds` after all 8 MVP GDDs exist
8. `/prototype ai-controller` — validate interface admits NullAI + BasicAI stub
9. `/gate-check pre-production` — green-light implementation
