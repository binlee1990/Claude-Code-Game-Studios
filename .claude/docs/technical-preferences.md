# Technical Preferences

<!-- Populated by /setup-engine. Updated as the user makes decisions throughout development. -->
<!-- All agents reference this file for project-specific standards and conventions. -->

## Engine & Language

- **Engine**: Godot 4.6.2-stable
- **Language**: GDScript
- **Rendering**: Forward+ (default for D3D12 on Windows in 4.6)
- **Physics**: Jolt (default in 4.6) — note: 4.6 made Jolt the default, replacing Godot Physics

## Input & Platform

<!-- Written by /setup-engine. Read by /ux-design, /ux-review, /test-setup, /team-ui, and /dev-story -->
<!-- to scope interaction specs, test helpers, and implementation to the correct input methods. -->

- **Target Platforms**: PC (Windows; Linux/macOS untested)
- **Input Methods**: Keyboard/Mouse
- **Primary Input**: Mouse
- **Gamepad Support**: None (MVP). InputMap will define abstract actions (`select`, `cancel`, `confirm`, `end_turn`) so future gamepad support is binding-only — no logic refactor.
- **Touch Support**: None
- **Platform Notes**: PC-only at MVP. UI may assume hover/click. Do NOT gate logic on hover-only interactions if cross-platform expansion is considered later.

## Naming Conventions

- **Classes**: PascalCase (e.g., `PlayerUnit`, `GridMap`)
- **Variables**: snake_case (e.g., `move_speed`, `current_hp`)
- **Signals/Events**: snake_case past tense (e.g., `health_changed`, `turn_ended`)
- **Files**: snake_case matching class (e.g., `player_unit.gd`)
- **Scenes/Prefabs**: PascalCase matching root node (e.g., `PlayerUnit.tscn`)
- **Constants**: UPPER_SNAKE_CASE (e.g., `MAX_HEALTH`, `GRID_TILE_SIZE`)

## Performance Budgets

- **Target Framerate**: 60fps
- **Frame Budget**: 16.6ms
- **Draw Calls**: < 500 (Godot 4.6 D3D12 default; SRPG turn-based load is well below this)
- **Memory Ceiling**: 512 MB (placeholder — revisit if/when content layer expands beyond MVP)

## Testing

- **Framework**: GdUnit4
- **Minimum Coverage**: Not enforced at MVP. Raise after architecture stabilizes (post-`/architecture-review`).
- **Required Tests**:
  - BFS move-range computation (Module 4)
  - Damage formula `max(ATK - DEF, 1)` (Module 5)
  - Turn rotation state machine (Module 3)
  - Victory/defeat condition checks (Module 7)

## Forbidden Patterns

<!-- Add patterns that should never appear in this project's codebase -->
- [None configured yet — add as architectural decisions are made]

## Allowed Libraries / Addons

<!-- Add approved third-party dependencies here -->
- **GdUnit4** — testing framework (introduced at engine setup, 2026-04-28)

## Architecture Decisions Log

<!-- Quick reference linking to full ADRs in docs/architecture/ -->
- [No ADRs yet — use /architecture-decision to create one]

## Engine Specialists

<!-- Written by /setup-engine when engine is configured. -->
<!-- Read by /code-review, /architecture-decision, /architecture-review, and team skills -->
<!-- to know which specialist to spawn for engine-specific validation. -->

- **Primary**: godot-specialist
- **Language/Code Specialist**: godot-gdscript-specialist (all .gd files)
- **Shader Specialist**: godot-shader-specialist (.gdshader files, VisualShader resources)
- **UI Specialist**: godot-specialist (no dedicated UI specialist — primary covers all UI)
- **Additional Specialists**: godot-gdextension-specialist (GDExtension / native C++ bindings only — not expected at MVP)
- **Routing Notes**: Invoke primary for architecture decisions, ADR validation, and cross-cutting code review. Invoke GDScript specialist for code quality, signal architecture, static typing enforcement, and GDScript idioms. Invoke shader specialist only when shaders are introduced (post-MVP — Programmer Art Functional anchor uses flat colors, no custom shaders). Invoke GDExtension specialist only if native extensions are explicitly required.

### File Extension Routing

<!-- Skills use this table to select the right specialist per file type. -->
<!-- If a row says [TO BE CONFIGURED], fall back to Primary for that file type. -->

| File Extension / Type | Specialist to Spawn |
|-----------------------|---------------------|
| Game code (.gd files) | godot-gdscript-specialist |
| Shader / material files (.gdshader, VisualShader) | godot-shader-specialist |
| UI / screen files (Control nodes, CanvasLayer) | godot-specialist |
| Scene / prefab / level files (.tscn, .tres) | godot-specialist |
| Native extension / plugin files (.gdextension, C++) | godot-gdextension-specialist |
| General architecture review | godot-specialist |
