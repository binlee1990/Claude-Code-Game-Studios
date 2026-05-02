# Technical Preferences

## Engine & Language

- **Engine**: Godot 4.6.2
- **Language**: GDScript
- **Rendering**: Forward+ (default)
- **Physics**: Jolt (default since 4.6)

## Input & Platform

- **Target Platforms**: PC (Steam / Epic)
- **Input Methods**: Keyboard/Mouse, Gamepad
- **Primary Input**: Keyboard/Mouse
- **Gamepad Support**: Partial
- **Touch Support**: None
- **Platform Notes**: 离线收益必须使用时间戳差值计算，不能依赖 _process 实时循环（Web 导出时标签页不活跃会暂停）

## Naming Conventions

- **Classes**: PascalCase (e.g., `PlayerController`)
- **Variables**: snake_case (e.g., `move_speed`)
- **Signals**: snake_case past tense (e.g., `health_changed`)
- **Files**: snake_case matching class (e.g., `player_controller.gd`)
- **Scenes**: PascalCase matching root node (e.g., `PlayerController.tscn`)
- **Constants**: UPPER_SNAKE_CASE (e.g., `MAX_HEALTH`)

## Performance Budgets

- **Target Framerate**: 60 fps
- **Frame Budget**: 16.6 ms
- **Draw Calls**: 100
- **Memory Ceiling**: 512 MB

## Testing

- **Framework**: GDUnit4
- **Minimum Coverage**: 80% for Logic/Integration stories
- **Required Tests**: Balance formulas, offline income calculation, save/load, resource growth

## Forbidden Patterns

- [None configured yet — add as architectural decisions are made]

## Allowed Libraries / Addons

- [None configured yet — add as dependencies are approved]

## Architecture Decisions Log

- [No ADRs yet — use /architecture-decision to create one]

## Engine Specialists

- **Primary**: godot-specialist
- **Language/Code Specialist**: godot-gdscript-specialist (all .gd files)
- **Shader Specialist**: godot-shader-specialist (.gdshader files, VisualShader resources)
- **UI Specialist**: godot-specialist (no dedicated UI specialist — primary covers all UI)
- **Additional Specialists**: godot-gdextension-specialist (GDExtension / native C++ bindings only)
- **Routing Notes**: Invoke primary for architecture decisions, ADR validation, and cross-cutting code review. Invoke GDScript specialist for code quality, signal architecture, static typing enforcement, and GDScript idioms. Invoke shader specialist for material design and shader code. Invoke GDExtension specialist only when native extensions are involved.

### File Extension Routing

| File Extension / Type | Specialist to Spawn |
|-----------------------|---------------------|
| Game code (.gd files) | godot-gdscript-specialist |
| Shader / material files (.gdshader, VisualShader) | godot-shader-specialist |
| UI / screen files (Control nodes, CanvasLayer) | godot-specialist |
| Scene / prefab / level files (.tscn, .tres) | godot-specialist |
| Native extension / plugin files (.gdextension, C++) | godot-gdextension-specialist |
| General architecture review | godot-specialist |
