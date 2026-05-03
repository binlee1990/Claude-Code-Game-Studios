# Control Manifest

> **Engine**: Godot 4.6.2
> **Last Updated**: 2026-05-04
> **Manifest Version**: 2026-05-04
> **ADRs Covered**: ADR-0001, ADR-0002, ADR-0003, ADR-0004, ADR-0005, ADR-0006, ADR-0007, ADR-0008, ADR-0009, ADR-0010, ADR-0011, ADR-0012, ADR-0013, ADR-0014, ADR-0015
> **Status**: Active — regenerate with `/create-control-manifest update` when ADRs change

`Manifest Version` is the date this manifest was generated. Story files embed this date when created. `/story-readiness` compares a story's embedded version to this field to detect stories written against stale rules. Always matches `Last Updated`.

This manifest is a programmer's quick-reference extracted from all Accepted ADRs, technical preferences, and Godot 4.6.2 engine reference docs. For the reasoning behind each rule, see the referenced ADR.

---

## Foundation Layer Rules

*Applies to: BigNumber, EventBus, TimeManager, RNGManager, Autoload order*

### Required Patterns

- **Use `BigNumber` for all game absolute quantities** — source: ADR-0001
- **Keep BigNumber arithmetic immutable; every operation returns a new instance** — source: ADR-0001
- **Serialize BigNumber as `{"m": mantissa, "e": exponent}`** — source: ADR-0001
- **Route cross-system notifications through EventBus exact subscriptions in production** — source: ADR-0002
- **Use EventBus prefix subscriptions only for debug tooling** — source: ADR-0002
- **Use `Time.get_unix_time_from_system()` through TimeManager as the authoritative real-time source** — source: ADR-0003
- **Use TimeManager game-time deltas for online timed systems** — source: ADR-0003
- **Clamp offline duration to 28,800 seconds before simulation** — source: ADR-0003
- **Route all gameplay randomness through RNGManager streams** — source: ADR-0004
- **Use copied RNG states for offline simulation** — source: ADR-0004
- **Set EventBus first in `project.godot` Autoload order** — source: ADR-0008
- **Keep BigNumber as a value script, not an Autoload** — source: ADR-0008

### Forbidden Approaches

- **Never store resources, attributes, damage, experience, or rewards as raw `int` / `float` absolute values** — source: ADR-0001
- **Never introduce GDExtension BigNumber before the GDScript performance gate fails with measured evidence** — source: ADR-0001
- **Never use EventBus prefix subscriptions for production UI/gameplay behavior** — source: ADR-0002
- **Never coalesce business events that carry cumulative deltas, audit semantics, save events, or loot transactions** — source: ADR-0002
- **Never use `_process(delta)` as the source of truth for idle progress or offline rewards** — source: ADR-0003
- **Never call global `randi()` or `randf()` from gameplay systems** — source: ADR-0004
- **Never initialize Feature or Presentation Autoloads before their Foundation/Core dependencies** — source: ADR-0008

### Performance Guardrails

- **BigNumber**: 1000 instances × 50 operations must fit within a 16.6 ms frame before GDExtension is deferred long term — source: ADR-0001
- **EventBus**: typical frame cost target is <= 0.5 ms/frame — source: ADR-0002
- **TimeManager**: 1000 `get_game_time()` calls target <= 0.1 ms — source: ADR-0003
- **RNGManager**: single random call target <= 0.015 ms; 1024-weight `weighted_pick` target <= 0.1 ms — source: ADR-0004

---

## Core Layer Rules

*Applies to: DataConfig, SaveManager, ModifierEngine, ResourceSystem, FormulaEngine*

### Required Patterns

- **Use JSON files under `res://assets/data/` as the MVP configuration source** — source: ADR-0005
- **Keep DataConfig schema-agnostic; consumers parse BigNumber strings themselves** — source: ADR-0005
- **Keep all MVP config tables resident in DataConfig memory after startup load** — source: ADR-0005
- **Use SaveManager provider callbacks by namespace for persistence** — source: ADR-0006
- **Write save files through a temp file and preserve a backup save** — source: ADR-0006
- **Check `FileAccess.store_*` return values when writing save data** — source: ADR-0006
- **Apply modifiers in ADD → same-pool additive MULT → cross-pool MULT order** — source: ADR-0007
- **Use `"{entity_id}.{attr_id}"` for attribute modifier targets** — source: ADR-0007
- **Use `"{resource_id}_production"` for production modifier targets** — source: ADR-0007
- **Replace stored ResourceSystem BigNumber values rather than mutating them** — source: ADR-0010
- **Treat `ResourceSystem.batch_add` as sequential and non-atomic** — source: ADR-0010
- **Use a bounded FormulaEngine evaluator with cache invalidation** — source: ADR-0013

### Forbidden Approaches

- **Never use Godot Resource files as the MVP content format** — source: ADR-0005
- **Never write runtime player state through DataConfig** — source: ADR-0005
- **Never make SaveManager import or understand concrete system state types** — source: ADR-0006
- **Never multiply same-pool modifiers individually** — source: ADR-0007
- **Never evaluate source-specific business conditions inside ModifierEngine** — source: ADR-0007
- **Never put production, multiplier, loot, level, or economy business logic inside ResourceSystem** — source: ADR-0010
- **Never execute arbitrary GDScript or external code from FormulaEngine expressions** — source: ADR-0013

### Performance Guardrails

- **DataConfig**: MVP load target <= 100 ms and cache <= 5 MB — source: ADR-0005
- **SaveManager**: MVP save/load target <= 20 ms and save object <= 50 KB — source: ADR-0006
- **ModifierEngine**: cached 1000 `get_multiplier()` calls target <= 1 ms — source: ADR-0007
- **ResourceSystem**: 5-resource `batch_add` target <= 0.15 ms — source: ADR-0010
- **FormulaEngine**: cache-hit evaluation target <= 0.02 ms; 50 formulas/frame <= 0.5 ms — source: ADR-0013

---

## Feature Layer Rules

*Applies to: combat, loot, progression, auto-production, cultivation, offline gameplay features*

### Required Patterns

- **Use CombatCalculator as the single damage-resolution service for online and offline combat** — source: ADR-0009
- **Use RNGManager COMBAT and LOOT streams consistently for combat and drops** — source: ADR-0004, ADR-0009
- **Aggregate offline combat/reward facts into a draft before settlement** — source: ADR-0009, ADR-0015
- **Use OutputMultiplierSystem/ModifierEngine for production multipliers; ResourceSystem only receives settled amounts** — source: ADR-0007, ADR-0010
- **Use FormulaEngine for formula-driven growth, damage, soft caps, and balance math** — source: ADR-0013

### Forbidden Approaches

- **Never duplicate combat damage formulas inside OfflineCombatSimulation** — source: ADR-0009
- **Never let OfflineCombatSimulation call SemiAutoCombatSystem directly** — source: ADR-0009
- **Never let feature systems write resources by bypassing ResourceSystem APIs** — source: ADR-0010
- **Never consume online RNG state during offline simulation** — source: ADR-0004, ADR-0015

### Performance Guardrails

- **Offline simulation**: chunk long deltas and profile before vertical slice — source: ADR-0015
- **Combat/offline equivalence**: fixed-seed online/offline replay tests are mandatory before Pre-Production prototype confidence — source: ADR-0009, ADR-0015

---

## Presentation Layer Rules

*Applies to: UI Framework, HUD, DebugConsole, numeric display*

### Required Patterns

- **Build UI screens as Godot `Control` scenes managed by UIManager** — source: ADR-0011
- **Test both mouse and keyboard/gamepad focus paths under Godot 4.6 dual-focus behavior** — source: ADR-0011, ADR-0012
- **Use EventBus subscriptions and read-only queries for display state** — source: ADR-0011
- **Route player actions through explicit command methods on owning systems** — source: ADR-0011
- **Format every player-facing BigNumber through NumberFormatter** — source: ADR-0014
- **Use the MVP hard-coded Chinese unit table through `极`, then scientific notation above `10^48`** — source: ADR-0014
- **Queue-free DebugConsole immediately in non-debug builds** — source: ADR-0012
- **Set DebugConsole `process_mode = Node.PROCESS_MODE_ALWAYS` in debug builds** — source: ADR-0012

### Forbidden Approaches

- **Never let UI directly mutate ResourceSystem or AttributeSystem state** — source: ADR-0011
- **Never let UI/HUD/DebugConsole implement duplicate BigNumber formatting** — source: ADR-0014
- **Never ship active DebugConsole UI, listeners, or `_process` work in Release exports** — source: ADR-0012
- **Never leave DebugConsole `event watch` prefix subscriptions active after the console closes** — source: ADR-0012

### Performance Guardrails

- **HUD/UI**: coalesce or throttle high-frequency resource/attribute refreshes — source: ADR-0011
- **Lists**: virtualize large logs, inventory, and bestiary rows — source: ADR-0011
- **NumberFormatter**: 1000 formatting calls target <= 1 ms — source: ADR-0014
- **DebugConsole**: zero resident CPU/memory behavior in Release exports — source: ADR-0012

---

## Global Rules (All Layers)

### Naming Conventions

| Element | Convention | Example |
|---------|-----------|---------|
| Classes | PascalCase | `PlayerController` |
| Variables | snake_case | `move_speed` |
| Signals/Events | snake_case past tense for signals; dotted namespaces for EventBus events | `health_changed`, `resource.lingqi.changed` |
| Files | snake_case matching class | `player_controller.gd` |
| Scenes | PascalCase matching root node | `PlayerController.tscn` |
| Constants | UPPER_SNAKE_CASE | `MAX_HEALTH` |

Source: `.claude/docs/technical-preferences.md`, ADR-0002.

### Performance Budgets

| Target | Value |
|--------|-------|
| Framerate | 60 fps |
| Frame budget | 16.6 ms |
| Draw calls | 100 |
| Memory ceiling | 512 MB |
| Logic/Integration story coverage target | 80% |

Source: `.claude/docs/technical-preferences.md`.

### Approved Libraries / Addons

- None configured for MVP — source: `.claude/docs/technical-preferences.md`

### Forbidden APIs (Godot 4.6.2)

These APIs or patterns are deprecated or superseded for this project:

- `TileMap` — use `TileMapLayer` — source: `docs/engine-reference/godot/deprecated-apis.md`
- `VisibilityNotifier2D` / `VisibilityNotifier3D` — use `VisibleOnScreenNotifier2D/3D` — source: `docs/engine-reference/godot/deprecated-apis.md`
- `YSort` — use `Node2D.y_sort_enabled` — source: `docs/engine-reference/godot/deprecated-apis.md`
- `Navigation2D` / `Navigation3D` — use `NavigationServer2D/3D` — source: `docs/engine-reference/godot/deprecated-apis.md`
- `yield()` — use `await signal` — source: `docs/engine-reference/godot/deprecated-apis.md`
- String-based `connect("signal", obj, "method")` — use typed signal connections / Callable-based connections — source: `docs/engine-reference/godot/deprecated-apis.md`
- `instance()` / `PackedScene.instance()` — use `instantiate()` — source: `docs/engine-reference/godot/deprecated-apis.md`
- `OS.get_ticks_msec()` — use `Time.get_ticks_msec()` — source: `docs/engine-reference/godot/deprecated-apis.md`
- `duplicate()` for nested resources — use `duplicate_deep()` when deep duplication is needed — source: `docs/engine-reference/godot/deprecated-apis.md`
- `AnimationPlayer.playback_active` — use `AnimationMixer.active` — source: `docs/engine-reference/godot/deprecated-apis.md`

### Cross-Cutting Constraints

- **No new dependencies without explicit request** — source: workspace working agreements
- **All ADRs must keep Engine Compatibility and GDD Requirements Addressed sections** — source: `docs/architecture/architecture.md`
- **All implementation stories must cite relevant ADRs and this manifest version** — source: control manifest lifecycle contract
- **Do not assume Godot 4.6 UI focus or FileAccess write behavior from older model knowledge; verify against engine reference and tests** — source: ADR-0006, ADR-0011, Godot reference docs

