# Systems Index: SRPG_MINI — Generic Tactics RPG Skeleton

> **Status**: Draft (lean mode — director sign-off skipped)
> **Created**: 2026-04-28
> **Last Updated**: 2026-04-28
> **Source Concept**: `design/gdd/game-concept.md`

> **Creative Director Sign-Off (CD-SYSTEMS)**: SKIPPED — Lean mode (per `production/review-mode.txt`).
> **Technical Director Sign-Off (TD-SYSTEM-BOUNDARY)**: SKIPPED — Lean mode.
> **Producer Sign-Off (PR-SCOPE)**: SKIPPED — Lean mode.

---

## Overview

SRPG_MINI is a generic tactics RPG skeleton: 8 orthogonal systems that together form the universal SRPG kernel (grid · unit · faction-rotation turn · move · range-attack · pluggable AI · victory check · input/HUD). The system set is bounded by the project's Anti-Pillars — **NOT a flavored SRPG**, **NOT a story system**, **NOT audio** — so the index is unusually flat: there is no progression layer, no economy layer, no narrative layer, no audio layer. Every system serves the core loop directly. The pillar **System Orthogonality** constrains how these 8 systems interact: changes in one must not require edits in another, which forces every dependency to be expressed as an explicit interface rather than an internal call.

---

## Systems Enumeration

| # | System Name | Category | Priority | Status | Design Doc | Depends On |
|---|-------------|----------|----------|--------|------------|------------|
| 1 | Map / Coordinates | Core | MVP | Designed | `design/gdd/map.md` | (none) |
| 2 | Unit *(includes Faction enum at MVP)* | Core | MVP | Designed | `design/gdd/unit.md` | Map |
| 3 | Turn System | Core | MVP | Designed | `design/gdd/turn.md` | Unit |
| 4 | Movement | Gameplay | MVP | Designed | `design/gdd/movement.md` | Map, Unit |
| 5 | Attack | Gameplay | MVP | Designed | `design/gdd/attack.md` | Map, Unit |
| 6 | Victory | Gameplay | MVP | Not Started | — | Unit |
| 7 | AI *(AIController interface + NullAI default)* | Gameplay | MVP | Not Started | — | Turn System, Movement, Attack |
| 8 | UI / Input | UI | MVP | Not Started | — | Map, Unit, Turn System, Movement, Attack, Victory |
| — | Faction *(extracted)* | Core | Tier 2 | Pre-registered | — | (none) |
| — | BasicAI | Gameplay | Tier 2 | Pre-registered | — | AI (interface), Map, Unit, Movement, Attack |
| — | Terrain (one type) | Gameplay | Tier 2 | Pre-registered | — | Map, Movement |
| — | Class Triangle | Gameplay | Tier 2 | Pre-registered | — | Unit, Attack |
| — | Save / Load | Persistence | Tier 3 | Pre-registered | — | All MVP gameplay systems |
| — | Main Menu | UI | Tier 3 | Pre-registered | — | (none) |
| — | Multi-Level | Gameplay | Tier 3 | Pre-registered | — | All MVP + Save/Load |
| — | XP / Level-up | Progression | Tier 3 | Pre-registered | — | Unit, Attack, Victory |

> **Inferred-vs-explicit note**: All 8 MVP systems are explicit from `game-concept.md` Module Decisions. The Faction split is pre-registered (Tier 2) because the user chose "embed for MVP, extract on Tier 2" — at MVP, Faction is an enum/Resource defined inside the Unit GDD.

---

## Categories Used

| Category | Description | This Project's Systems |
|----------|-------------|-----------------------|
| **Core** | Foundation systems that everything depends on | Map, Unit, Turn System |
| **Gameplay** | The systems that make the game work | Movement, Attack, Victory, AI |
| **UI** | Player-facing information display + input | UI / Input |
| **Persistence** | Save state | (Tier 3 only) |
| **Progression** | Player growth over time | (Tier 3 only) |

> Categories deliberately omitted: **Audio**, **Narrative**, **Meta**, **Economy** — explicit Anti-Pillars or out of MVP scope.

---

## Priority Tiers

| Tier | Definition | Status |
|------|------------|--------|
| **MVP** | The 8 modules that constitute the universal SRPG skeleton. Without all 8, the core loop (boot → board → move → attack → victory) does not function end-to-end. | Active design target |
| **Tier 2 (Vertical Slice)** | Additive extensions that turn the MVP from "abstract skeleton" into "feels like an SRPG": real AI, terrain, class triangle, Faction split. | Pre-registered, no GDD |
| **Tier 3 (Alpha)** | Wrapper systems that turn Tier 2 into a self-contained product: menus, save, progression, multiple levels. | Pre-registered, no GDD |
| **Full Vision** | N/A — this project does not commit to one. The skeleton ships at MVP, OR a flavored fork builds on it later. | Not applicable |

---

## Dependency Map

### Foundation Layer (no dependencies)

1. **Map / Coordinates** — Provides grid topology, tile state, and the world↔grid coordinate boundary that every other system reads through. Pillar served: System Orthogonality (the GridSpace interface is the firewall against coordinate logic leaking into rendering).

### Core Layer (depends on Foundation)

1. **Unit** — depends on: Map (units are placed at grid coordinates). Embeds Faction enum at MVP. Five downstream systems consume the Unit interface — interface stability is a precondition for design proceeding past this point.
2. **Turn System** — depends on: Unit (iterates units within active faction). Faction-rotation state machine.

### Feature Layer (depends on Core; designable in parallel within layer)

1. **Movement** — depends on: Map (BFS topology), Unit (position + MOV stat). Produces reachable-tile set + path preview.
2. **Attack** — depends on: Map (range computation), Unit (HP / ATK / DEF / RNG stats). Produces damage application; counter-attack hook reserved but disabled.
3. **Victory** — depends on: Unit (HP / death state). Produces faction-elimination + turn-cap checks.

### Feature Layer 2 (depends on Feature Layer 1)

1. **AI / AIController** — depends on: Turn System (called from), Movement (chooses move target), Attack (chooses attack target). MVP ships only `NullAI` (hot-seat). The interface itself is the design deliverable; the implementation is trivial.

### Presentation Layer (depends on everything)

1. **UI / Input** — depends on: Map (renders grid + tile-state colors per art bible), Unit (renders unit + HP), Turn System (turn indicator + End-Turn button), Movement (range/path highlights), Attack (range highlight + damage preview), Victory (win/lose screen). This layer aggregates every upstream system; it is also the latest-designed and most volatile.

### Polish Layer

(None at MVP — debug coordinate overlay is part of UI / Input baseline, not polish.)

---

## Recommended Design Order

| Order | System | Priority | Layer | Agent(s) | Est. Effort |
|-------|--------|----------|-------|----------|-------------|
| 1 | Map / Coordinates | MVP | Foundation | game-designer + godot-specialist (TileMap consultation) | S |
| 2 | Unit *(includes Faction enum)* | MVP | Core | game-designer | M |
| 3 | Turn System | MVP | Core | game-designer + systems-designer (state machine) | S |
| 4 | Movement | MVP | Feature | systems-designer (BFS over typed grid) | M |
| 5 | Attack | MVP | Feature | systems-designer (damage formula) | M |
| 6 | Victory | MVP | Feature | game-designer | S |
| 7 | AI *(AIController interface + NullAI)* | MVP | Feature | game-designer + technical-director (interface) | M |
| 8 | UI / Input | MVP | Presentation | ux-designer + ui-programmer (consultation) | L |

> Effort: **S** = 1 session, **M** = 2-3 sessions, **L** = 4+ sessions.

> Parallelism note: Movement, Attack, Victory (orders 4-6) all depend only on Map + Unit and are independent of each other — they can be designed in parallel sessions if desired. AI (order 7) must wait for Movement and Attack to be designed because the AIController interface needs both as parameters.

---

## Circular Dependencies

**None found.**

The dependency graph is a DAG with maximum depth 5 (Map → Unit → Turn System → AI → UI / Input). The closest thing to a cycle is the AI ↔ Turn System relationship: Turn System invokes AIController, but AIController must call back into the Turn System to signal "my turn is done." This is resolved by treating AIController as a stateless function `take_turn(units, world_state) -> ActionList` that returns a list of intended actions; Turn System owns execution. **This resolution is binding** — AI GDD must specify it.

---

## High-Risk Systems

| System | Risk Type | Risk Description | Mitigation |
|--------|-----------|------------------|------------|
| **Map / Coordinates** | Technical | World↔grid coordinate conversion logic leaks into rendering (`pixel_position * tile_size` math scattered across modules). See game-concept.md R4. | GDD must specify a single `GridSpace` boundary with `world_to_grid` / `grid_to_world` methods; forbid inline conversion in code review (Forbidden Patterns). |
| **Unit** | Design | Unit interface is consumed by 5 downstream systems. Late changes cascade into Movement/Attack/Turn/AI/UI rewrites. | GDD must define the public Unit interface (stats, methods, signals) explicitly and lock it before downstream design begins. Treat changes as breaking. |
| **AI / AIController** | Design | If the AIController interface is wrong, every Tier 2 AI implementation (BasicAI, future heuristic AI) requires editing the Turn System. See game-concept.md R5. | After AI GDD is drafted, run `/prototype` to scaffold both `NullAI` AND a stub `BasicAI` to prove the interface admits at least two distinct behaviors without Turn System edits. |
| **UI / Input** | Scope | UI / Input depends on every gameplay system; if any upstream system's interface shifts late, UI must rework. | Author UI / Input last (Order 8) AND treat its GDD as a delta from upstream interfaces — do not over-specify until upstream is locked. |

---

## Progress Tracker

| Metric | Count |
|--------|-------|
| Total systems identified (MVP) | 8 |
| Total systems pre-registered (Tier 2) | 4 |
| Total systems pre-registered (Tier 3) | 4 |
| Design docs started | 5 |
| Design docs reviewed | 0 |
| Design docs approved | 0 |
| MVP systems designed | 5 / 8 |
| Tier 2 systems designed | 0 / 4 |

---

## Next Steps

- [x] Approve this systems index (this document)
- [ ] Run `/design-system map` to author the first GDD (Order 1: Map / Coordinates)
- [ ] Author MVP GDDs in design order (1 → 8); systems at Orders 4–6 may be parallelized
- [ ] Run `/design-review design/gdd/<system>.md` after each GDD
- [ ] Run `/review-all-gdds` once all 8 MVP GDDs exist (cross-system consistency)
- [ ] Run `/prototype ai-controller` after AI GDD to validate the AIController interface admits two behaviors (NullAI + BasicAI stub)
- [ ] Run `/gate-check pre-production` when all MVP GDDs are reviewed
