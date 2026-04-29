# ADR-0002: Dependency Injection Architecture

## Status
Proposed

## Date
2026-04-30

## Engine Compatibility

| Field | Value |
|-------|-------|
| **Engine** | Godot 4.6.2-stable |
| **Domain** | Core (architecture pattern, object lifecycle) |
| **Knowledge Risk** | LOW — `RefCounted`, constructor injection, no post-cutoff API dependencies |
| **References Consulted** | `docs/engine-reference/godot/VERSION.md`, `docs/engine-reference/godot/current-best-practices.md`, `.claude/docs/technical-preferences.md` |
| **Post-Cutoff APIs Used** | None |
| **Verification Required** | None |

## ADR Dependencies

| Field | Value |
|-------|-------|
| **Depends On** | None (cross-cutting pattern — independent of specific system ADRs) |
| **Enables** | ADR-0003 (Unit Interface — Unit placement uses DI), ADR-0004 (Turn System — TurnManager via DI), all Feature-layer ADRs (Movement, Attack, Victory, AI) |
| **Blocks** | All epics — no system can be implemented until the DI pattern is established |
| **Ordering Note** | Must be Accepted second (after ADR-0001), before any Core or Feature-layer ADRs that specify DI in their constructor signatures |

## Context

### Problem Statement

The architecture document mandates that all logic objects (TurnManager, MovementResolver, AttackResolver, VictoryChecker, AIController) be `RefCounted` instances created by a composition root and passed via dependency injection. Without a codified DI pattern, each system ADR would invent its own wiring strategy — producing inconsistent constructors, hidden singletons, or accidental Autoload usage. This ADR establishes the single pattern that all 7 downstream system ADRs (and their implementations) must follow.

### Constraints

- Godot's scene tree naturally encourages `@onready var` and `$NodePath` — but these create hidden coupling
- GDScript has no formal DI framework — the pattern must be manual but consistent
- Logic objects (TurnManager, all Resolvers) must be testable without a running scene
- MVP has no SignalBus — signals are connected directly between known instances
- Game scene is the only Node2D in the project that orchestrates system creation (it is the composition root)

### Requirements

- Every logic object must receive its dependencies explicitly via constructor or setter
- No logic object may use `get_node()`, `$NodePath`, `get_tree()`, or Autoload references
- The composition root (Game scene) is solely responsible for creating and wiring all objects
- The pattern must be consistent across all 8 systems

## Decision

**All logic objects are `RefCounted`. The Game scene (`game.tscn`) is the composition root: it creates every RefCounted instance in `_ready()`, injects dependencies via constructor arguments or public properties, and connects signals directly between known instances. No Autoloads. No SignalBus. No `get_node()` outside of Node2D scene code.**

### Composition Root (Game._ready())

```gdscript
# src/game/game.gd
extends Node2D

func _ready() -> void:
    # ── Foundation ──
    var grid_space := GridSpace.new()

    # ── Map (Node2D, already in scene tree) ──
    var map: Map = %Map
    map.initialize(grid_space, "test_map")  # loads CSV, sets TileMapLayer

    # ── Units (Node2D, instantiated from .tscn) ──
    var all_units: Array[Unit] = []
    for unit_data in _unit_configs:
        var unit := load("res://src/unit/unit.tscn").instantiate() as Unit
        unit.initialize(unit_data.stats, unit_data.faction, unit_data.grid_pos)
        map.place_unit(unit, unit_data.grid_pos)
        all_units.append(unit)

    # ── Core ──
    var turn_config := load("res://assets/data/turn_config.tres") as TurnConfig
    var victory_checker := VictoryChecker.new()
    var ai_controller: AIController = NullAI.new()  # MVP default
    var turn_manager := TurnManager.new()
    turn_manager.initialize(all_units, turn_config, victory_checker, ai_controller)

    # ── Feature ──
    var movement_resolver := MovementResolver.new()
    var attack_resolver := AttackResolver.new()
    var attack_range_resolver := AttackRangeResolver.new()

    # ── Presentation ──
    var input_handler := InputHandler.new()
    input_handler.initialize(
        map, grid_space, turn_manager,
        movement_resolver, attack_resolver, attack_range_resolver
    )

    # ── Highlight Layers (Node2D children of Board) ──
    %MoveHighlightLayer.initialize(grid_space)
    %PathHighlightLayer.initialize(grid_space)
    %AttackHighlightLayer.initialize(grid_space)

    # ── HUD ──
    %HUD.initialize(turn_manager)

    # ── Signal Wiring ──
    for unit in all_units:
        unit.unit_died.connect(turn_manager._on_unit_died)
    turn_manager.match_started.connect(%HUD._on_match_started)
    turn_manager.turn_started.connect(%HUD._on_turn_started)
    turn_manager.faction_activated.connect(%HUD._on_faction_activated)
    turn_manager.faction_phase_ended.connect(%HUD._on_faction_phase_ended)
    turn_manager.match_ended.connect(%HUD._on_match_ended)

    # ── Start ──
    turn_manager.start_match(all_units)
```

### Constructor Pattern

```gdscript
# Pattern A: Simple RefCounted (no dependencies beyond what's passed per-call)
class_name VictoryChecker extends RefCounted
func determine_winner(units: Array[Unit], turn_number: int, turn_cap: int) -> Dictionary:
    # Pure function — all state passed as arguments
    pass

# Pattern B: RefCounted with constructor injection (dependencies held for lifetime)
class_name TurnManager extends RefCounted
var _all_units: Array[Unit]
var _turn_config: TurnConfig
var _victory_checker: VictoryChecker
var _ai_controller: AIController

func initialize(units: Array[Unit], config: TurnConfig, victory: VictoryChecker, ai: AIController) -> void:
    _all_units = units
    _turn_config = config
    _victory_checker = victory
    _ai_controller = ai

# Pattern C: RefCounted with per-call Map reference (stateless resolver)
class_name MovementResolver extends RefCounted
func compute_reachable(unit: Unit, map: Map) -> MovementResult:
    # Map passed per-call — resolver holds no state
    pass
```

### What This Replaces

| Anti-Pattern | Replacement |
|-------------|-------------|
| `Autoload` singleton | `RefCounted` instance created by Game, injected |
| `SignalBus` Autoload | Direct signal connections in Game._ready() |
| `get_node("/root/SomeManager")` | Constructor-injected reference |
| `$SomeChild` in logic code | Parameter passed from composition root |
| `@onready var manager = %Manager` in RefCounted | Constructor injection |

### Why Not SignalBus (MVP)

At MVP scale (8 systems, ~8 cross-system signals), direct connections are traceable: every signal connection is visible in one file (`game.gd`). A SignalBus Autoload would add an indirection layer with no benefit at this scale. If Tier 2+ adds 4+ more systems with complex signal routing, a SignalBus ADR can be proposed then — but it would be an addition, not a retrofit, since all signals already use typed Callable connections.

## Alternatives Considered

### Alternative 1: Autoload Singletons

- **Description**: TurnManager, MovementResolver, etc. as Autoloads accessible globally
- **Pros**: Zero wiring; familiar Godot pattern; less code in Game._ready()
- **Cons**: Hidden dependencies — any file can silently depend on any Autoload; impossible to unit test without a running engine; load order bugs; coupling that violates System Orthogonality
- **Rejection Reason**: Architecture Principle 1 explicitly mandates DI over Service Location. Autoloads make dependencies invisible and untestable.

### Alternative 2: Node-Based Managers (Scene Tree Hierarchy)

- **Description**: TurnManager, MovementResolver as Node children of Game, accessed via `%UniqueName`
- **Pros**: Visible in scene tree; uses Godot's built-in node lifecycle
- **Cons**: Coupled to scene tree — cannot unit test without instantiating a scene; `_ready()` order controls initialization (fragile); `get_node()` calls scattered across systems
- **Rejection Reason**: Logic objects should not depend on scene tree lifecycle. RefCounted with explicit `initialize()` gives deterministic initialization order.

### Alternative 3: SignalBus Autoload

- **Description**: A single Autoload that declares all project signals; producers emit via SignalBus; consumers connect via SignalBus
- **Pros**: Decouples signal producers from consumers; no direct references needed; well-known Godot pattern
- **Cons**: At MVP scale (4 signals from TurnManager, 1 from Unit, 1 from Attack), the indirection adds complexity without benefit. Signal signatures are implicit (no compiler check on string-based connections)
- **Rejection Reason**: Deferred, not rejected. MVP's 6 cross-system signals are manageable with direct connections. If Tier 2+ adds complex routing, a SignalBus ADR can be proposed as an additive change.

## Consequences

### Positive

- Every dependency is visible in the constructor/initialize signature — no hidden coupling
- All logic objects are unit-testable without a scene tree (instantiate, inject mocks, call methods)
- Initialization order is explicit and deterministic (sequential in Game._ready())
- Adding a new system: create RefCounted, add one line to Game._ready(), inject where needed

### Negative

- Game._ready() becomes the "wiring file" — grows linearly with system count (~40 lines at MVP, manageable)
- No lazy initialization — all objects created at scene load (acceptable: RefCounted construction is negligible)
- Manual DI without a framework means constructor signatures must be maintained by hand

### Risks

- **Risk**: Large Game._ready() becomes hard to maintain at Tier 2+ scale.
  - **Mitigation**: If wiring exceeds ~80 lines, extract a `GameWiring` helper class or adopt SignalBus. MVP's ~40 lines is well within comfortable range.

- **Risk**: A developer accidentally uses `get_node()` in a RefCounted class.
  - **Mitigation**: Code review rule. Forbidden pattern in `.claude/docs/technical-preferences.md`: "RefCounted logic classes must not call `get_node()`, `get_tree()`, or reference Autoloads."

## GDD Requirements Addressed

| GDD System | Requirement | How This ADR Addresses It |
|------------|-------------|--------------------------|
| turn.md | Rule 9: TurnManager as RefCounted, DI, no Autoload | Codifies the exact DI pattern TurnManager must follow |
| map.md | OQ2: GridSpace as RefCounted with DI | Establishes the pattern GridSpace OQ2 references |
| movement.md | External Dependencies: MovementResolver (RefCounted, DI) | Standardizes the resolver creation and injection pattern |
| attack.md | Core Rule 10: AttackResolver as RefCounted | Standardizes creation and injection |
| victory.md | Core Rule 1: VictoryChecker as RefCounted, DI | Standardizes creation and injection |
| ai.md | Core Rule 9: AIController as RefCounted, DI | Standardizes creation and injection |
| ui.md | External Dependencies: InputHandler (RefCounted, DI) | Standardizes creation and injection |
| game-concept.md | Pillar 2: System Orthogonality | DI makes inter-system boundaries explicit — no hidden coupling |
| architecture.md | Principle 1: Dependency Injection, Never Service Location | Codifies the principle into a concrete, implementable pattern |

## Performance Implications

- **CPU**: Negligible — RefCounted construction is a heap allocation + vtable init. 8 RefCounted objects at startup <0.1ms.
- **Memory**: 8 RefCounted instances + their references = negligible (<1KB).
- **Load Time**: Zero measurable impact.

## Migration Plan

Greenfield — no migration needed. All systems will be built with this pattern from day one. Implementation order:
1. Create `src/game/game.gd` with the composition root structure
2. Each system ADR's implementation follows the constructor pattern defined here
3. Code review checklist: verify no RefCounted class uses `get_node()` or Autoload

## Validation Criteria

- [ ] Game scene creates all RefCounted instances in `_ready()`
- [ ] No `extends RefCounted` class contains `get_node()`, `$`, `%`, `get_tree()`, or Autoload name references
- [ ] No Autoload is defined in `project.godot` (except engine-defaults)
- [ ] Each logic class can be instantiated in a unit test with mock dependencies
- [ ] Grep for `Autoload` in `src/` returns zero results (excluding engine defaults in project.godot)

## Related Decisions

- ADR-0001: GridSpace Coordinate Boundary (first DI-managed RefCounted)
- ADR-0003: Unit Public Interface (Unit placement uses DI)
- ADR-0004: Turn System Architecture (TurnManager follows this DI pattern)
- `.claude/docs/technical-preferences.md` — Forbidden Patterns section
