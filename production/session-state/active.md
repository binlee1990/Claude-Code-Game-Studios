# Active Session State

> Living checkpoint. Updated after each significant milestone.
> Read this file first after any compaction, crash, or `/clear`.

**Last Updated**: 2026-04-28
**Project Stage**: Pre-Production / Concept → Systems Design

---

## Current Task

Systems decomposition complete. Next milestone: author MVP system GDDs in design order.

## Status

- ✅ `/start` — onboarded, review-mode = `lean`
- ✅ `/brainstorm SRPG` — `design/gdd/game-concept.md` (322 lines)
- ✅ `/setup-engine` — Godot 4.6.2-stable / GDScript / GdUnit4 testing / Performance budgets default
- ✅ `/art-bible` — `design/art/art-bible.md` (Programmer Art Functional, 4 sections + 5 N/A)
- ✅ `/map-systems` — `design/gdd/systems-index.md` (8 MVP systems + 8 pre-registered Tier 2/3)
- 🟡 Next: `/design-system map` (Order 1, Foundation, S effort)

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
- Q3 (from game-concept): obstacle tiles in TileMap layer vs separate occupancy layer? → resolve in Map GDD

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
