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

- ADR-0001: BigNumber 实现策略 — accepted 2026-05-04
- ADR-0002: 事件总线架构 — accepted 2026-05-04
- ADR-0003: 时间源与双时间体系 — accepted 2026-05-04
- ADR-0004: 确定性随机数架构 — accepted 2026-05-04
- ADR-0005: 数据配置加载策略 — accepted 2026-05-04
- ADR-0006: 存档格式与版本迁移 — accepted 2026-05-04
- ADR-0007: 修正器叠加顺序 — accepted 2026-05-04
- ADR-0008: Autoload 初始化顺序 — accepted 2026-05-04
- ADR-0009: 在线/离线战斗路径统一 — accepted 2026-05-04
- ADR-0010: ResourceSystem 不可变 BigNumber 策略 — accepted 2026-05-04
- ADR-0011: UI 屏幕管理架构 — accepted 2026-05-04
- ADR-0012: DebugConsole 发布构建排除 — accepted 2026-05-04
- ADR-0013: FormulaEngine 表达式 DSL 深度 — accepted 2026-05-04
- ADR-0014: NumberFormatter 缩写映射策略 — accepted 2026-05-04
- ADR-0015: 离线模拟 tick 粒度 — accepted 2026-05-04

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
