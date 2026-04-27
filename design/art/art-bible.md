# Art Bible — SRPG_MINI

*Created: 2026-04-28*
*Status: Draft (lean mode — director sign-off skipped)*
*Visual Identity Anchor: Programmer Art Functional (locked in `design/gdd/game-concept.md`)*

> **Art Director Sign-Off (AD-ART-BIBLE)**: SKIPPED — Lean mode (per `production/review-mode.txt`). The art bible authority is delegated to the user-as-art-director.

> **Scope**: This is a deliberately minimal art bible. Sections §2, §3, §5, §6, §7 are marked **N/A** because the project's Anti-Pillars explicitly forbid the territory those sections cover (mood, shape philosophy, character design, environment design, decorated UI). Only §1 (Identity), §4 (Color), §8 (Assets), §9 (References) carry binding rules.

---

## Section 1: Visual Identity Statement

**One-Line Rule:** *"Every visual element exists to make the board state legible. Aesthetic consistency is not a goal."*

### Supporting Principles

**Principle 1 — Faction Color Is Signal, Not Style**
Faction color is a single flat color. Player = blue. Enemy = red.
*Design test*: at a glance, can you tell which side a unit is on? If no, the color is wrong.

**Principle 2 — Grid Lines Are Always Visible**
Grid lines are always visible.
*Design test*: can you count tiles between two units without moving the camera? If no, the grid is too subtle.

**Principle 3 — Debug Overlays Default to ON**
Debug overlays (coordinates, HP) are on by default.
*Design test*: can a developer tell which tile is `(5, 3)` without code? If no, the overlay is broken.

### What This Rule Is For

This project is a system skeleton, not a shipped game. Aesthetic consistency creates false couplings: a contributor who makes the UI "feel like Fire Emblem" has embedded visual conventions that belong to that franchise, not to a generic SRPG vocabulary. Anti-aesthetic discipline enforces **System Orthogonality** (Pillar 2) — each module is visually naked so that its interfaces, not its presentation, define its contract. The visual layer must carry zero meaning that a replacement layer would need to replicate. This is also a direct enactment of the Anti-Pillar **NOT a flavored SRPG**.

### Replaceability Clause

The entire visual layer — all colors, all geometry, all font choices, all overlay layouts — must be swappable wholesale without modifying any module that is not strictly inside `src/ui/` or `assets/`. If a visual change requires editing a non-UI module, the coupling is a bug in the architecture, not a constraint of art direction.

---

## Section 2: Mood & Atmosphere

**N/A** — see Anti-Pillars (`NOT a flavored SRPG`) and §4.4 (atmospheric tint forbidden). The project deliberately has no mood and no atmosphere. Game states are differentiated by HUD label text ("Player Turn" / "Enemy Turn" / "Victory" / "Defeat"), not by visual mood.

---

## Section 3: Shape Language

**N/A** — see §8.2 (units are minimum-vertex code-drawn polygons; faction shape difference is colorblind backup, not aesthetic philosophy). The project has no shape philosophy beyond the colorblind-required `Player = square / Enemy = circle` distinction.

---

## Section 4: Color System

### 4.1 Faction Colors

Blue and red is the standard pairing for **Deuteranopia** safety (the most common form, ~6% of males) — the two hues remain distinguishable. The pairing is **not** safe for **Protanopia** edge cases or **Tritanopia** (rare, ~0.01%). The backup cue for all faction colors is **unit shape**: Player units render as squares; Enemy units render as circles. Shape is colorblind-safe and does not require any color signal to function.

### 4.2 Tile State Colors

`TILE_MOVE_RANGE` (cyan) vs. `TILE_ATTACK_RANGE` (orange-red) is the critical overlapping semantic pair. Both are distinguishable for Deuteranopia and Protanopia. They are potentially confused under Tritanopia. **Backup cue**: move-range tiles render with a solid fill; attack-range tiles render with a hatched or dotted border pattern at the rendering layer. This pattern cue must be implemented even if Tritanopia support is considered optional — it costs nothing in a code-drawn system.

### 4.3 Color Token Table

| Token | Hex | Role | Pillar Served | Colorblind Backup |
|---|---|---|---|---|
| `FACTION_PLAYER` | `#2563EB` | Player unit fill color | Visual Identity Principle 1 | Unit shape: square |
| `FACTION_ENEMY` | `#DC2626` | Enemy unit fill color | Visual Identity Principle 1 | Unit shape: circle |
| `TILE_DEFAULT` | `#374151` | Unoccupied, passable tile | Visual Identity Principle 2 | N/A — base state |
| `TILE_GRID_LINE` | `#6B7280` | Grid line separating tiles | Visual Identity Principle 2 | N/A — structural |
| `TILE_BLOCKED` | `#111827` | Impassable tile (wall/void) | Visual Identity Principle 2 | Darker value contrast |
| `TILE_OBSTACLE` | `#1F2937` | Terrain obstacle (blocks pathing only) | Visual Identity Principle 2 | Slightly raised poly or outline |
| `TILE_MOVE_RANGE` | `#0891B2` | Tiles reachable by selected unit this turn | Minimum Complete (single-pass legible) | Solid fill pattern |
| `TILE_ATTACK_RANGE` | `#EA580C` | Tiles attackable by selected unit | Minimum Complete (single-pass legible) | Hatched border pattern |
| `TILE_PATH_PREVIEW` | `#FBBF24` | Preview of unit's intended move path | Visual Identity Principle 2 | Arrow glyph overlay |
| `UI_HP_TEXT` | `#F9FAFB` | HP value label on unit | Visual Identity Principle 3 (debug-on) | High contrast on dark background |
| `UI_TURN_PLAYER` | `#2563EB` | "Your Turn" phase indicator | Visual Identity Principle 1 | Label text: "PLAYER" |
| `UI_TURN_ENEMY` | `#DC2626` | "Enemy Turn" phase indicator | Visual Identity Principle 1 | Label text: "ENEMY" |
| `UI_WIN` | `#22C55E` | Win screen text | Minimum Complete (terminal state obvious) | Label text: "VICTORY" |
| `UI_LOSE` | `#EF4444` | Lose screen text | Minimum Complete (terminal state obvious) | Label text: "DEFEAT" |
| `UI_DEBUG_OVERLAY` | `#E5E7EB` | Coordinate and stat overlay text | Visual Identity Principle 3 (debug-on) | High contrast on all tile colors |

### 4.4 Forbidden Palette Additions

- **Gradients are forbidden.** Gradients require a shader or a multi-stop texture; both add implementation cost and create a visual layer that is not code-drawn. *Pillar served*: **Minimum Complete** — a gradient produces no additional information that a flat color does not already carry on a turn-based grid.
- **Transparency below 90% opacity is forbidden.** Semi-transparent overlays stack unpredictably when multiple tile states are active simultaneously (e.g., a unit standing on a move-range tile inside an attack-range zone). The blended color carries no readable meaning and breaks the one-line visual rule: it makes the board state *less* legible, not more.
- **More than two colors per faction are forbidden.** A faction has exactly one primary color (fill) and may derive an outline from that color at full saturation plus brightness shift. A second independent faction color creates an encoding problem.
- **Mood lighting and atmospheric tint are forbidden.** Anti-Pillar `NOT a flavored SRPG`. Any screen-space color grade, ambient light color, or scene fog value that is not neutral white (`#FFFFFF`) is rejected.

---

## Section 5: Character Design Direction

**N/A** — there are no characters. Game tokens called "units" exist; their visual representation is fully defined in §4.1, §4.3, and §8.2 (faction-color polygon + single-letter type label). Adding character design here would directly violate the Anti-Pillar `NOT a flavored SRPG`.

---

## Section 6: Environment Design Language

**N/A** — there is no environment. There is a grid. Grid appearance is fully defined in §4.3 (`TILE_*` tokens) and §8.5 (tile size). Adding environmental design (architecture, biomes, props) would directly violate the Anti-Pillar `NOT a flavored SRPG` and the Pillar **Minimum Complete**.

---

## Section 7: UI/HUD Visual Direction

**N/A as a separate section** — UI visual rules are defined entirely in §4.3 (UI color tokens) and §8.2 (Godot built-in `Button`/`Label`/`StyleBoxFlat`, no icons, no custom fonts). The project has no diegetic UI; everything is screen-space. There is no animated UI feel beyond Godot's default button hover/press states.

---

## Section 8: Asset Standards

### 8.1 Asset Format Philosophy

The default state of every visual element in this project is **code-drawn**. A `ColorRect`, `Polygon2D`, or `Label` node configured from data is the correct implementation of any asset that can be expressed as flat geometry plus a token from the color system. Code-drawn assets serve **Data-Driven** (their values come from external config, not baked into a texture file) and **Minimum Complete** (zero import pipeline, zero export packaging, zero file management).

**Must be code-drawn (no external file permitted in MVP):**
- All tile fill geometry
- All grid lines
- All unit representations
- All range-highlight overlays
- All path-preview overlays
- All debug overlay text and coordinate labels
- Turn indicator, win/lose screen backgrounds

External resources are permitted only where code-drawn output is categorically insufficient. That threshold: where a font renderer or pixel-precise sprite is required and Godot's built-in primitives cannot produce an equivalent at zero implementation cost.

### 8.2 External Assets Allowed List

- **Tile textures**: **No.** Tile appearance is defined entirely by `TILE_DEFAULT` and `TILE_GRID_LINE` color tokens rendered as `ColorRect` and `Line2D` nodes. Rationale: **Minimum Complete**.
- **Unit sprites**: **No** for MVP. Units are code-drawn `Polygon2D` (Player: square, Enemy: circle per §4.1) with a single-letter `Label` child node displaying abbreviated type (e.g., "S" for Soldier, "A" for Archer). The letter is drawn in `UI_HP_TEXT` color against the faction fill. Rationale: **Generic Vocabulary** — no sprite art embeds franchise identity.
- **UI icons**: **No** for MVP. All interactive elements are `StyleBoxFlat`-styled `Button` and `Label` nodes. No icon sheet, no SVG import. Rationale: **Minimum Complete**.
- **Fonts**: Godot built-in `ThemeDB` default font only for MVP. If the built-in font fails Principle 3's design test (developer reads coordinates at standard scaling), a single monospace `.ttf` may be added — candidate: **JetBrains Mono** (OFL-licensed; distinguishes `0`/`O` and `1`/`I` at small sizes).

### 8.3 Naming Conventions for External Assets

If an external asset is introduced under the allowed list, it must follow GDScript snake_case conventions matching `.claude/docs/technical-preferences.md`:

```
[category]_[name]_[variant]_[size].[ext]

Examples:
  font_mono_regular_16.ttf
  tile_default_normal_64.png
  unit_placeholder_square_64.png
  ui_btn_primary_default.png
```

All asset file names are lowercase. No spaces. No camelCase. No version numbers in file names (version control handles versioning). Category tokens must be drawn from: `tile`, `unit`, `ui`, `font`, `vfx` (vfx is reserved — no VFX in MVP).

### 8.4 Performance Constraints

The <500 draw call budget is not a meaningful constraint for this project at MVP scale (≤8 units per faction). The binding constraint is **implementation simplicity**, not GPU throughput.

- **Per-node poly budget**: Code-drawn `Polygon2D` nodes use ≤8 vertices. A square is 4. A circle approximation is 8. Maximum for placeholder unit geometry.
- **Texture memory per scene**: If external textures are introduced, the scene budget is 4MB total uncompressed. At 64×64 RGBA8 (16KB each), this allows ~256 tiles — sufficient for any MVP grid up to 16×16.
- **Importer settings for any external PNG**: Format = Lossless (PNG), compression = VRAM Uncompressed, filter = Nearest, mipmaps = off. Set once in `.import` files; must not be overridden per-asset.

### 8.5 Tile Size Standard

**Tile size: 64×64 pixels.**

Justification: at 1920×1080 with a standard SRPG grid of 10×10 to 16×12, a 64px tile produces a footprint of 640×640 to 1024×768 pixels, leaving margin for the UI panel without scaling the viewport. At 64px, a single-letter unit label at 20–24pt font is legible without zoom. At 32px, the letter becomes illegible at standard DPI, and the coordinate overlay (Principle 3) requires sub-pixel rendering. At 96px, a 16×12 grid overflows 1080p height. **64px satisfies Minimum Complete**: it is the smallest tile size at which Principle 3 (debug overlays default ON, coordinates readable) passes its design test on a 1920×1080 display.

### 8.6 Forbidden Asset Categories

- **Shaders**: forbidden until Tier 2+. Any shader requires a `ShaderMaterial`, a `.gdshader` file, technical-artist review, and a compilation step. Zero MVP visual goals require shader-level processing. Rationale: **Minimum Complete**.
- **Particle effects**: forbidden. `GPUParticles2D` / `CPUParticles2D` produce visual output that communicates nothing about board state. They exist to create atmosphere. Atmosphere is an Anti-Pillar violation: `NOT a flavored SRPG`.
- **Normal maps**: forbidden. Forward+ 2D pipeline does not consume normal maps without a shader. See shader prohibition above. Additionally, normal maps imply surface material language. Rationale: `NOT a flavored SRPG`.
- **PBR textures**: forbidden. PBR requires metallic/roughness channels with no valid mapping to a flat-color grid. Any PBR texture import would be dead data. Rationale: **Minimum Complete** + `NOT a flavored SRPG`.
- **Skeletal or frame animation**: forbidden. Units do not animate. A unit moving across the grid is represented by an instant position update or a linear tween on the `Polygon2D` position — not a spritesheet, not an `AnimationPlayer` with skeletal data. Rationale: **Minimum Complete** + `NOT a flavored SRPG`.

---

## Section 9: Reference Direction (Reversed)

For this project, §9 is a **negative document** — it lists what the project must NOT look like, and why.

### 9.1 Forbidden Visual Reference Set

**Fire Emblem: Three Houses (Nintendo, 2019)**
Avoid: the character portrait system and watercolor/painterly map aesthetic. Every map tile in Three Houses carries a texture, a lighting layer, and an atmospheric color grade establishing a European fantasy identity. This project has no portraits, no map theming, no identity. If a contributor says "the tiles could look a bit more like the grass tiles in Three Houses," that is an Anti-Pillar violation: `NOT a flavored SRPG` means not emulating *any* franchise's visual grammar.

**Final Fantasy Tactics: The War of the Lions (Square Enix, 2007)**
Avoid: the isometric perspective with hand-painted tile height levels and unit sprites with distinct silhouettes per job class. FFT's visual language is inseparable from its class system. Adopting even a suggestion of isometric rendering would embed a perspective convention implying height layers, which this MVP does not implement. **Generic Vocabulary** forbids proprietary character archetypes in visual form.

**XCOM 2 (Firaxis, 2016)**
Avoid: gritty tactical realism palette, fog-of-war darkness gradient, and camera tilt implying a 3D battlefield. XCOM establishes military-fiction tone through desaturated olive/grey environments broken by faction color. Reaching for a "military" palette or tilted camera imports XCOM's identity. This project's camera is orthographic top-down and does not tilt.

**Advance Wars (Intelligent Systems, 2001)**
Avoid: bright saturated cartoon style with terrain tiles carrying national identity (factories, cities, forests as icons). Advance Wars is the reference most likely to be cited as "the simple SRPG look" because its art appears minimal. It is not minimal — it is deliberately branded. The moment terrain tiles gain hue variety, the project drifts toward Advance Wars.

**Into the Breach (Subset Games, 2018)**
Avoid: colored terrain tiles communicating type by hue, and pixel-art mech sprites with distinct silhouettes per class. Into the Breach is the closest game philosophically, which makes it the **most dangerous** reference: a contributor can reasonably argue "we want to look like Into the Breach." The answer is no. Into the Breach has a visual identity (consistent pastel palette, distinctive mech art, isometric pseudo-3D tiles). Taking any element creates a flavored derivative.

### 9.2 Allowed Reference Set

**Allowed (one reference): A game engine's built-in debug visualizer — specifically, the Godot 4 editor's collision shape and navigation region overlay rendering.**

What to take: the aesthetic of engine debug views is entirely functional. Collision shapes render as wireframe polygons in a single solid color against the scene background. Navigation meshes render as flat tinted polygons. No texture, no shadow, no material. Color is an arbitrary high-contrast hue chosen for readability against the scene, not for mood. Grid snap overlays are uniform lines at fixed intervals. **This is exactly what the tile grid should look like: a debug view that happens to be the game itself.**

What to leave: the editor debug view is not intended as player-facing UI. Its label font sizes are calibrated for editor resolution. Its overlay density is higher than appropriate for gameplay. Its grid color is editor-theme-dependent. This project must define its own fixed token values rather than inheriting editor theme values, because the game must look the same regardless of whether the developer runs a light or dark editor theme.

**Operational instruction**: if a new visual element would look at home as a Godot debug overlay in the editor viewport, it is appropriate. If it would look out of place as a debug overlay — too decorative, too polished, too evocative of a specific genre — it does not belong.

### 9.3 Reference Review Clause

**Any proposed visual element must be justifiable from §1 alone, not from a reference. References are inadmissible as justification.**

If a contributor proposes a visual change supported by "this is how [game name] does it" or "this would look like [game name]," that justification is **rejected on procedural grounds before the proposal is evaluated on its merits**. The only valid justification form is: *"This element makes the board state more legible because [specific legibility argument], which is required by the one-line rule in §1."* If that argument cannot be made without appealing to a reference game's visual identity, the element does not belong in this project.
