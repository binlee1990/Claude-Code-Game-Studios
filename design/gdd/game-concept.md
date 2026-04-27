# Game Concept: SRPG_MINI — Generic Tactics RPG Skeleton

*Created: 2026-04-28*
*Status: Draft*

---

## Elevator Pitch

> A grid-based, turn-taking tactics RPG **skeleton** that abstracts the universal SRPG system set (grid, unit, faction, turn, move, range, AI, victory) into a minimum playable framework. Two factions alternate turns moving units and attacking until one side is eliminated — no story, no audio, no genre-specific flourishes. The goal is **to make the SRPG system primitives explicit, named, and orthogonal** so any future SRPG variation (Fire Emblem-style, FFT-style, XCOM-style…) can be built on top by additive extension, never rewrite.

---

## Core Identity

| Aspect | Detail |
| ---- | ---- |
| **Genre** | Tactics RPG (SRPG) — engineering reference template |
| **Platform** | PC (Godot 4.6 export) |
| **Target Audience** | Developers — primarily self, secondarily peers seeking an SRPG starter kit |
| **Player Count** | Single-player (hot-seat for MVP; AI replaceable post-MVP) |
| **Session Length** | 5-15 min per match (a single board) |
| **Monetization** | None — internal template / learning project |
| **Estimated Scope** | Small (AI-assisted development, no fixed timeline — gated by module-by-module sign-off) |
| **Comparable Titles** | Fire Emblem (movement+attack action model), Final Fantasy Tactics (job-as-pluggable-interface ethos), Into the Breach (transparent minimal grid) |

---

## Core Fantasy

This project's "fantasy" is engineering, not player-emotional. The promise is to the **developer-as-user**:

> *"I have a clean, named, orthogonal SRPG skeleton that runs end-to-end. Every concept the genre takes for granted (grid, unit, faction, turn, action budget, range, AI controller, victory check) is a separate, swappable module. I can extend in any SRPG direction — Fire Emblem, FFT, XCOM, Into the Breach — by addition, never by rewriting the core."*

Player-side, the secondary fantasy is the universal SRPG kernel: **"I see a board, I move units, I kill the other side, I win."** Stripped of all flavor, this kernel is the project.

---

## Unique Hook

It's a tactics RPG, **AND ALSO** every system maps 1-to-1 to a named primitive that appears in ≥3 canonical SRPGs, AND ALSO every system has a swap-in interface (e.g., `NullAI → BasicAI → HeuristicAI`, `FlatTerrain → CostedTerrain → TypedTerrain`) so extension is additive.

The hook is not a player-facing gimmick — it is an architectural commitment. The unique value is **what is deliberately absent**: no flavor, no narrative, no proprietary mechanics, no genre-bending twist. The skeleton itself is the artifact.

---

## Player Experience Analysis (MDA Framework)

> **Note**: This project's primary user is the *developer*, not the player. The MDA framework is included for completeness, but most aesthetic categories are intentionally N/A. The dominant aesthetic is **mechanical clarity**, which is not in MDA's eight categories — we treat it as a developer-facing property documented in the Pillars section.

### Target Aesthetics (What the player FEELS)

| Aesthetic | Priority | How We Deliver It |
| ---- | ---- | ---- |
| **Sensation** | N/A | No audio, programmer-art visuals |
| **Fantasy** | N/A | No theme, no narrative |
| **Narrative** | N/A | No story |
| **Challenge** | 1 (only ranked aesthetic) | Hot-seat tactical decisions: position, attack order, ending the turn |
| **Fellowship** | N/A | Single-player; hot-seat is local but uninstrumented |
| **Discovery** | N/A | All systems are deliberately transparent (debug-grid coordinates always visible) |
| **Expression** | N/A | No build/customization layer |
| **Submission** | N/A | Not designed for relaxation |

### Key Dynamics (Emergent player behaviors)

- Hot-seat players will naturally negotiate fairness rules ("you go first", "no ganging up") — **out of scope for MVP**, recorded as a Tier-3 concern.
- Developers using this codebase will reach for a specific module (e.g., AIController) and replace it without touching the others. If they cannot, an interface is wrong.

### Core Mechanics (Systems we build)

The eight modules of the MVP — see Module Decisions table below.

---

## Player Motivation Profile

### Primary Psychological Needs Served

| Need | How This Game Satisfies It | Strength |
| ---- | ---- | ---- |
| **Autonomy** | Hot-seat: full freedom over both sides | Supporting (incidental, not designed) |
| **Competence** | Tactical decisions are legible (BFS preview path, damage formula visible) | Supporting |
| **Relatedness** | None — single-device, no narrative attachment | Minimal |

### Player Type Appeal (Bartle Taxonomy)

- [x] **Achievers** — Win/lose state is a clear binary
- [x] **Explorers** — Developers exploring the codebase will find each system named after its canonical SRPG concept
- [ ] **Socializers** — N/A
- [ ] **Killers/Competitors** — N/A (no PvP infrastructure)

### Flow State Design

- **Onboarding curve**: There is no in-game onboarding. The *developer* onboards via the README and module-by-module concept doc. The *player* (hot-seat) is assumed to know SRPG conventions.
- **Difficulty scaling**: N/A (no difficulty system in MVP).
- **Feedback clarity**: Every action surfaces visible state changes (HP text updates, unit greys out after acting, turn indicator updates).
- **Recovery from failure**: Restart the match (via win/lose screen → restart button).

---

## Core Loop

### Moment-to-Moment (30 seconds)

> **Click a player unit → see move-range highlights → hover a target tile (preview path) → click to move → (if enemy adjacent / in RNG) click target to attack → unit greys out.**

The core verb is **commit**: each click finalizes a small decision and exposes the next.

### Short-Term (5-15 minutes)

> **Resolve all units in the active faction → press "End Turn" or auto-advance → opposite faction acts → repeat.**

This is where the tactical "puzzle" of the round forms: which order to act, who absorbs hits, who kills first.

### Session-Level (30-120 minutes)

> **Play one full match.** ~10-30 rounds. Match ends on faction-elimination or turn-cap.

### Long-Term Progression

**N/A in MVP.** The Tier 3 scope adds inter-match progression (XP, levels, save). The MVP intentionally has no out-of-match state.

### Retention Hooks

**N/A in MVP.** This is a skeleton — retention is an extension concern. Documented for posterity:
- **Curiosity**: would be served by added content (multiple maps, classes) in Tier 2+
- **Investment**: would be served by progression in Tier 3
- **Social / Mastery**: out of scope

---

## Module Decisions (8 Modules)

Decisions made during `/brainstorm SRPG`, 2026-04-28. Each module is a separately-specifiable system; later GDDs will live in `design/gdd/<module>.md`.

| # | Module | Decision |
| - | ------ | -------- |
| 1 | **Map / Coordinates** | 4-neighbor square grid · Godot `TileMap` node · Three states only (walkable / blocked / obstacle) · No terrain effects |
| 2 | **Unit** | Stats: `HP / ATK / DEF / MOV / RNG` · Two factions (Player / Enemy) · Manually placed in Godot scenes |
| 3 | **Turn System** | Faction-rotation (Player→Enemy→Player) · Move+Attack packed into one action · Auto-advance + manual "End Turn" button |
| 4 | **Movement** | BFS range computation · Highlight reachable tiles + preview path on hover · Teleport (instant `set_position`) |
| 5 | **Attack** | Range from per-unit `RNG` attribute (data-driven) · `damage = max(ATK - DEF, 1)` · No counter-attack in MVP |
| 6 | **AI** | `AIController` interface reserved · MVP defaults to `NullAI` (hot-seat) · `BasicAI` is Tier-2 |
| 7 | **Victory** | Faction elimination · Turn cap as deadlock guard |
| 8 | **Input + UI** | Mouse only · Unit-head HP text · Turn/faction indicator + End-Turn button · Win/lose text screen · Debug grid coordinate overlay (toggleable) |

> **Rule**: Each module is implemented behind an interface. No module reaches into another's internals — they coordinate through named events / function signatures only. This is enforced in code review (Pillar 2: System Orthogonality).

---

## Game Pillars

### Pillar 1: Data-Driven

All values (unit stats, map layout, damage formula constants) live in **external data**. Code does not embed gameplay numbers.

*Design test*: When debating "should X be a code constant or a data field," choose **data**.

### Pillar 2: System Orthogonality

Each module is independent, has minimal dependencies, and interacts with others only through explicit interfaces.

*Design test*: If a change to module A forces a same-PR edit to module B, the interface is wrong — fix the interface before merging.

### Pillar 3: Minimum Complete

Each module has a *"good enough, stop"* boundary. We do not stack features.

*Design test*: For each proposed feature, ask "is this required for SRPG-as-a-genre, or is it a flavor of Fire Emblem / FFT?" If flavor, defer to Tier 2+.

### Pillar 4: Generic Vocabulary

System and identifier names follow industry-common SRPG terms (`grid`, `unit`, `faction`, `turn`, `range`, `move`, `action`). No proprietary or work-specific names.

*Design test*: Search the proposed name. Does it appear in ≥3 canonical SRPGs (FE, FFT, Tactics Ogre, XCOM, Into the Breach, Banner Saga…)? If yes, use it. If no, find a generic synonym.

### Anti-Pillars (What This Project Is NOT)

- **NOT a story / dialogue system** — Orthogonal to the core loop. Defer indefinitely.
- **NOT audio** — Explicit user requirement; MVP and scope tiers all skip audio integration.
- **NOT a flavored SRPG** — No FE-style supports, no FFT-style jobs, no XCOM-style cover. Any "wouldn't it be cool if…" goes to backlog, not MVP.

---

## Visual Identity Anchor

> Captured during brainstorm before art-bible authoring. This anchor is the seed of `design/art-bible/`.

- **Direction Name**: **Programmer Art Functional**
- **One-line Visual Rule**: *Every visual element exists to make the board state legible. Aesthetic consistency is not a goal.*
- **Supporting Principles**:
  1. **Faction color = single flat color** (Player = blue, Enemy = red). *Test*: At a glance, can you tell which side a unit is on without reading text? If no, the color is wrong.
  2. **Grid lines are always visible**. *Test*: Can you count tiles between two units without moving the camera? If no, grid is too subtle.
  3. **Debug overlays default to ON** (coordinates, HP). *Test*: Can a developer tell which tile is `(5, 3)` without code? If no, overlay is broken.
- **Color Philosophy**: High-contrast functional palette. No theming, no mood, no atmosphere. The art bible can later replace this anchor wholesale; the code must not depend on visual styling.

---

## Inspiration and References

| Reference | What We Take From It | What We Do Differently | Why It Matters |
| ---- | ---- | ---- | ---- |
| Fire Emblem (any GBA/3DS entry) | Faction rotation; Move+Attack as one action; visual move-range highlight | We keep only the kernel — no weapon triangle, no supports, no permadeath UX | Validates the "Move+Attack packed = 1 action" loop is the SRPG default |
| Final Fantasy Tactics | "Job as pluggable role" instinct → in our codebase, `AIController` and future `UnitClass` are interfaces | We don't ship a job system; we ship the slot for one | Validates a swap-in interface design matches genre expectations |
| Into the Breach | Total information transparency; small grid; minimal UI | We don't lift the puzzle/precognition concept; we keep the legibility ethos | Validates that a "skeletal" SRPG can feel complete without content padding |

**Non-game inspirations**: API design literature (orthogonal primitives, composable interfaces). The project is closer in spirit to a reference implementation than to a game.

---

## Target Player Profile

| Attribute | Detail |
| ---- | ---- |
| **Primary user** | The developer building the project (self) |
| **Secondary user** | Other developers wanting an SRPG starter / teaching sample |
| **Gaming experience** | Familiar with the SRPG genre (FE / FFT / XCOM) — assumes player knows what "move and attack" means |
| **Time availability** | Short test-fixture matches (5-15 min) |
| **Platform preference** | Desktop, mouse |
| **Current games they play** | Fire Emblem, FFT, Tactics Ogre, Into the Breach, XCOM |
| **What they're looking for** | A clean, named, orthogonal SRPG kernel they can extend |
| **What would turn them away** | Code with hidden coupling, flavor leaking into the core, missing interfaces for AI / terrain / classes |

---

## Technical Considerations

| Consideration | Assessment |
| ---- | ---- |
| **Recommended Engine** | **Godot 4.6** (GDScript) — confirmed implicitly via Module 1 (TileMap node) |
| **Key Technical Challenges** | (1) Drawing clean module boundaries from day one. (2) Keeping Godot scene/node coordinate conversion isolated to a single boundary so logic doesn't leak into the presentation layer. |
| **Art Style** | Programmer Art Functional (placeholder geometric shapes + flat colors + text) |
| **Art Pipeline Complexity** | Low (no external assets needed — flat color rectangles + Godot built-in fonts) |
| **Audio Needs** | **None** (explicitly excluded) |
| **Networking** | None |
| **Content Volume** | MVP: 1 test map, 2-4 unit prefabs per faction |
| **Procedural Systems** | None in MVP |

---

## Risks and Open Questions

### Design Risks

- **R1**: "Generic" is itself an aesthetic stance. If we cannot resist adding flavor, the project becomes a Fire Emblem clone instead of a skeleton. → Pillar 3 + 4 are the defense.
- **R2**: Hot-seat without negotiation rules is inherently unfair. We accept this for MVP — the goal is to verify the *system*, not the *match*.

### Technical Risks

- **R3**: Module boundaries drawn poorly — extending in Tier 2 still requires core rewrites. → Each module GDD must specify its public interface before implementation.
- **R4**: Godot `TileMap` ↔ unit `Node2D` coordinate conversion leaks logic into rendering. → Concentrate the conversion in a single named boundary (`GridSpace.world_to_grid` / `grid_to_world`); forbid inline `position * tile_size` math elsewhere.
- **R5**: The `AIController` interface is the most critical one — designed wrong, every Tier-2 AI requires editing the turn system. → Prototype it twice (NullAI + BasicAI scaffold) before committing.

### Market Risks

- N/A (no market — this is a template).

### Scope Risks

- **R6**: Module-by-module sign-off rhythm could stall. Mitigate by writing each module GDD in ≤1 session.

### Open Questions

- **Q1**: Should the turn-cap value be data-driven (Pillar 1) or a code constant for MVP? → Lean toward data-driven from day one to avoid retrofitting.
- **Q2**: Where does the *hot-seat → AI* swap live in the scene tree? Per-unit `AIController` child node, or a per-faction strategy object? → Resolve in `/architecture-decision`.
- **Q3**: Should "obstacle" tiles be part of TileMap or a separate occupancy layer? → Resolve in Module 1 GDD.

---

## MVP Definition

**Core hypothesis**: *A grid-based turn-taking tactical battle skeleton, built from 8 named-primitive orthogonal modules and zero genre-flavor, runs end-to-end (boot → board → moves → attacks → victory) and feels like an SRPG.*

**Required for MVP** (the 8 modules, all):

1. Square-grid map via Godot TileMap, three-state passability
2. Units with `HP/ATK/DEF/MOV/RNG`, two factions, scene-placed
3. Faction-rotation turn system, packed Move+Attack action, End-Turn button
4. BFS move-range computation, highlight + path preview, teleport movement
5. Attack at `RNG` distance, `max(ATK-DEF, 1)` damage, no counter
6. `AIController` interface + `NullAI` (hot-seat) only
7. Faction-elimination + turn-cap victory
8. Mouse input + unit HP text + faction/turn indicator + win-lose text screen + debug coord overlay

**Explicitly NOT in MVP** (deferred):

- Any AI behavior beyond "do nothing" (`NullAI`)
- Terrain effects (movement cost, defense / evasion bonus)
- Weapon triangle / class triangle / elemental relations
- Counter-attack
- Critical hits / accuracy / RNG in damage
- XP / levels / class change
- Multiple maps / map selection
- Main menu, save / load
- Audio (any)
- Story, dialogue, character supports

### Scope Tiers

| Tier | Content | Features | Status |
| ---- | ---- | ---- | ---- |
| **MVP** | 1 map, 2-4 units/faction | 8 modules, hot-seat playable | **Current target** |
| **Tier 2 (Vertical Slice)** | Same map | + `BasicAI` (nearest-target heuristic) · 1 terrain type · simple class triangle | Post-MVP, additive |
| **Tier 3 (Alpha)** | 3 maps, main menu | + multi-level progression · save/load · XP & levelups | Optional extension |
| **Full Vision** | N/A — this project does not have a "full vision" | Ship MVP and stop, OR fork into a flavored SRPG project that builds on this skeleton | Decision deferred |

---

## Next Steps

- [ ] (lean: skipping concept-level director sign-off)
- [ ] Run `/setup-engine` to populate `.claude/docs/technical-preferences.md` with Godot 4.6 / GDScript / TileMap config
- [ ] Run `/art-bible` to formalize the Visual Identity Anchor
- [ ] Run `/design-review design/gdd/game-concept.md` to validate concept completeness
- [ ] Run `/map-systems` to decompose the 8 modules into a system dependency graph
- [ ] Author per-module GDDs with `/design-system` (one per module, in dependency order: Map → Unit → Turn → Movement → Attack → AI → Victory → UI)
- [ ] Run `/create-architecture` to produce the master architecture blueprint and Required ADR list
- [ ] Run `/architecture-decision` for each ADR (interface contracts: AIController, GridSpace boundary, Faction enum location)
- [ ] Run `/gate-check pre-production` before committing to implementation
- [ ] Prototype the riskiest interface (`AIController` with NullAI + BasicAI scaffold) via `/prototype`
- [ ] Run `/playtest-report` after the prototype to confirm core loop validity
- [ ] If validated, plan first sprint with `/sprint-plan new`
