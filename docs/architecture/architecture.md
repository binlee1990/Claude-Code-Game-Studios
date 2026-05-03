# 修仙放置挂机刷宝 RPG — 主架构文档

## Document Status
- Version: 1
- Last Updated: 2026-05-04
- Engine: Godot 4.6.2
- GDDs Covered: 30 MVP systems (all Approved)
- ADRs Referenced: ADR-0001 through ADR-0015 (see Required ADRs section)
- Technical Director Sign-Off: 2026-05-04 — APPROVED
- Lead Programmer Feasibility: FEASIBLE

---

## Dialectical Architecture Review

**Thesis**: The existing document already captures the correct high-level layering and the MVP dependency direction: Foundation → Core → Feature → Presentation.

**Antithesis**: Several details drifted from the approved GDD baseline: DataConfig was described as Resource-based while its GDD locks JSON/FileAccess; BigNumber/EventBus/SaveManager APIs were abbreviated differently from their GDD contracts; `project.godet` was misspelled; and the ADR list used short numbers while the project ADR template expects zero-padded IDs.

**Synthesis**: Keep the layer map and decision set, but tighten the document into an implementable contract: API names match GDDs, engine-risk labels match Godot 4.6.2 reference docs, ADR IDs are stable (`ADR-0001`...), and traceability is delegated to the generated ADRs plus `architecture-traceability.md`.

---

## Engine Knowledge Gap Summary

Engine: Godot 4.6.2 | LLM Cutoff: ~4.3 | Post-Cutoff: 4.4 (MEDIUM), 4.5 (HIGH), 4.6 (HIGH)

### HIGH RISK Domains
- **UI/Controls**: Dual-focus system (4.6), AccessKit screen reader (4.5), FoldableContainer (4.5), Recursive Control disable (4.5)
  - Affected systems: UIFramework, HUD, DebugConsole
- **GDScript**: Variadic args (4.5), `@abstract` (4.5), script backtracing (4.5)
  - Affected: all 30 systems (language-level)

### MEDIUM RISK Domains
- **Core/FileAccess**: `store_*` returns `bool` not `void` (4.4)
  - Affected: SaveManager
- **Resources**: `duplicate_deep()` (4.5), Texture type changes (4.4)
  - Affected: DataConfig, ItemRegistry

---

## System Layer Map

```
┌─────────────────────────────────────────────────────────────┐
│  PRESENTATION LAYER (3 systems)                             │
│  UI 框架 · HUD 系统 · 调试控制台                             │
├─────────────────────────────────────────────────────────────┤
│  FEATURE LAYER (13 systems)                                 │
│  等级 · 存储上限 · 自动产出 · 敌人数据库 · 掉落               │
│  修炼 · 战斗计算器 · 半自动战斗 · 区域 · 地图推进             │
│  挂机探索 · 离线战斗模拟 · 离线收益结算                       │
├─────────────────────────────────────────────────────────────┤
│  CORE LAYER (10 systems)                                    │
│  数值格式化 · 数据配置 · 公式引擎 · 修正器引擎 · 存档         │
│  资源 · 属性 · 物品材料 · 产出乘数 · 离线模拟内核             │
├─────────────────────────────────────────────────────────────┤
│  FOUNDATION LAYER (4 systems)                               │
│  大数值系统 · 事件总线 · 时间管理器 · 随机数与种子系统         │
├─────────────────────────────────────────────────────────────┤
│  PLATFORM LAYER                                             │
│  Godot 4.6.2 Engine API                                     │
└─────────────────────────────────────────────────────────────┘
```

### Foundation Layer (4 systems)

| System | Class | Pattern | Key Owns | Engine Risk |
|--------|-------|---------|----------|-------------|
| 大数值系统 | `BigNumber` (RefCounted) | 值类型 | mantissa + exponent, 算术, 比较, 序列化 | LOW |
| 事件总线 | `EventBus` (Autoload) | 全局单例 | 事件订阅表, 发布调度, 前缀匹配 | HIGH (GDScript lifecycle) |
| 时间管理器 | `TimeManager` (Autoload) | 全局单例 | 双时间快照, 加速来源注册表, 离线 delta | LOW |
| 随机数与种子 | `RNGManager` (Autoload) | 全局单例 | 主种子, 多流 RNG, FNV-1a 推导, 状态快照 | LOW |

### Core Layer (10 systems)

| System | Class | Pattern | Key Owns | Engine Risk |
|--------|-------|---------|----------|-------------|
| 数值格式化 | `NumberFormatter` | 工具类 | 格式化规则, 缩写映射 | LOW |
| 数据配置 | `DataConfig` (RefCounted) | Autoload 持有 | JSON 配置表缓存, 加载/热重载 | MEDIUM (FileAccess/JSON) |
| 公式引擎 | `FormulaEngine` | 静态工具 | 表达式解析, 变量上下文 | LOW |
| 修正器引擎 | `ModifierEngine` (RefCounted) | Autoload 持有 | 修正器注册表, 叠加顺序, 倍率计算 | LOW |
| 存档系统 | `SaveManager` (Autoload) | 全局单例 | 注册表, 序列化, 版本迁移 | MEDIUM (FileAccess) |
| 资源系统 | `ResourceSystem` (RefCounted) | Autoload 持有 | 资源 ID→BigNumber CRUD, 变更事件 | LOW |
| 属性系统 | `AttributeSystem` (RefCounted) | Autoload 持有 | 属性基础值, 修正器整合查询 | LOW |
| 物品材料 | `ItemRegistry` (RefCounted) | Autoload 持有 | 静态物品定义查询 | LOW (DataConfig consumer) |
| 产出乘数 | `OutputMultiplierSystem` (RefCounted) | Autoload 持有 | 每秒产出率计算 | LOW |
| 离线模拟内核 | `OfflineSimCore` | 服务 | 批量模拟框架, tick 步进 | LOW |

### Feature Layer (13 systems)

| System | Class | Pattern | Key Owns | Engine Risk |
|--------|-------|---------|----------|-------------|
| 等级系统 | `LevelSystem` (RefCounted) | Autoload 持有 | 等级/经验状态, 升级触发 | LOW |
| 存储上限 | `StorageLimitSystem` | Autoload | 上限计算公式 | LOW |
| 自动产出 | `AutoProductionSystem` | Autoload | tick 循环, 产出调度 | LOW |
| 敌人数据库 | `EnemyDatabase` | Autoload | 敌人模板查询 | LOW |
| 掉落系统 | `LootSystem` | 服务 | 掉落表解析, 加权结算 | LOW |
| 修炼系统 | `CultivationSystem` | 服务 | 修炼姿态, 凝练逻辑 | LOW |
| 战斗计算器 | `CombatCalculator` | 服务 | 伤害公式执行 | LOW |
| 半自动战斗 | `SemiAutoCombatSystem` | Autoload | 在线战斗循环 | LOW |
| 区域系统 | `ZoneSystem` | Autoload | 区域数据查询 | LOW |
| 地图推进 | `MapProgressionSystem` | 服务 | 区域解锁逻辑 | LOW |
| 挂机探索 | `IdleExplorationSystem` | 服务 | 在线挂机循环 | LOW |
| 离线战斗模拟 | `OfflineCombatSimulation` | 服务 | 离线批量战斗 | LOW |
| 离线收益结算 | `OfflineRewardSettlement` | 服务 | 离线奖励应用 | LOW |

### Presentation Layer (3 systems)

| System | Class | Pattern | Key Owns | Engine Risk |
|--------|-------|---------|----------|-------------|
| UI 框架 | `UIManager` (Autoload) + Control scenes | 屏幕管理 | 导航栈, 屏幕切换 | HIGH (4.5/4.6) |
| HUD 系统 | HUD (Control scene) | 事件订阅 | 资源面板, 战斗状态 | HIGH (4.5/4.6) |
| 调试控制台 | `DebugConsole` (Autoload) | CanvasLayer overlay | 命令解析, 日志缓冲 | HIGH (4.5/4.6) |

---

## Module Ownership

### Foundation Layer — 关键所有权

| Module | Owns | Exposes | Consumes | Engine APIs |
|--------|------|---------|----------|-------------|
| **BigNumber** | mantissa: float, exponent: int | `add/subtract/multiply/divide/power/compare/to_dict/from_dict` | 无 | 纯数学，无 Engine API |
| **EventBus** | {event_name → [Callable]} 订阅表 | `emit/emit_coalesced/subscribe/subscribe_once/unsubscribe/subscribe_pattern/unsubscribe_pattern` | 无 | Node (Autoload lifecycle) |
| **TimeManager** | {real_ref, game_ref, speed_sources} | `get_real_time/get_game_time/freeze/unfreeze/add_speed_source` | EventBus | `Time.get_unix_time_from_system()` |
| **RNGManager** | master_seed, {stream_id → RNG} | `rand_int/rand_float/rand_bool/weighted_pick/save_states/load_states` | 无 | `RandomNumberGenerator` |

### Core Layer — 关键所有权

| Module | Owns | Exposes | Consumes | Engine APIs |
|--------|------|---------|----------|-------------|
| **DataConfig** | JSON 配置表缓存 | `get/get_all/query/has_table/has_record/get_field/reload_table` | BigNumber 字符串约定 | `FileAccess.open()`, `JSON.parse_string()` |
| **FormulaEngine** | 表达式缓存（无状态） | `evaluate/evaluate_raw` | BigNumber, RNGManager | 无 |
| **ModifierEngine** | 修正器注册表 | `register/unregister/get_multiplier/apply` | BigNumber, FormulaEngine, EventBus | 无 |
| **SaveManager** | provider 回调注册表 | `register_provider/save_game/load_game/collect_save_data/is_saving/is_loading` | DataConfig, TimeManager, EventBus | `FileAccess` |
| **ResourceSystem** | {resource_id → BigNumber} | `register/add/spend/get_value/set_max/batch_add/snapshot/restore` | BigNumber, EventBus, DataConfig | 无 |
| **AttributeSystem** | {attr_id → {base, modifiers}} | `register_entity/get_base/set_base/get_final/snapshot/restore` | BigNumber, ModifierEngine, EventBus, DataConfig | 无 |
| **ItemRegistry** | 静态物品定义缓存 | `get/has_item/get_all_ids/query_by_item_class/query_by_tag/reload` | DataConfig | 无直接 Engine API |
| **OutputMultiplierSystem** | 产出速率计算规则 | `get_tick_amount/get_production_rate` | ModifierEngine, DataConfig, EventBus, BigNumber | 无 |
| **OfflineSimulationCore** | 模拟框架（chunk + simulator registry） | `register_simulator/run_simulation/build_plan` | TimeManager | 无 |
| **NumberFormatter** | 格式化规则 | `format/format_short` | BigNumber | 无 |

### Autoload 初始化顺序

```
EventBus → RNGManager → TimeManager
→ DataConfigHost → ItemRegistry → ModifierEngine
→ ResourceSystem → AttributeSystem → SaveManager
→ LevelSystem → ... → DebugConsole → UIManager
```

顺序约束：EventBus 必须第一个；DataConfigHost 必须在 ItemRegistry、EnemyDatabase、ZoneSystem 等静态数据消费者之前。BigNumber 是值类型脚本，不作为 Autoload 排序项。DebugConsole 和 UIManager 通过 `has_node()` / `is_instance_valid()` 惰性检查，不依赖严格顺序。

---

## Data Flow

### 场景 1: 在线自动产出帧更新

```
TimeManager.get_game_delta_since(last_tick)
    │
    ▼
AutoProductionSystem._process()
    │ get_tick_amount(resource_id, delta)
    ├──→ OutputMultiplierSystem → ModifierEngine → FormulaEngine
    │
    ├──→ ResourceSystem.batch_add({lingqi: amt, xiuwei: amt})
    │       └──→ EventBus.emit("resource.lingqi.changed")
    │
    └──→ HUD.refresh_resource_panel()  ← EventBus 订阅
```

### 场景 2: 在线战斗循环

```
SemiAutoCombatSystem._process()
    │
    ├──→ CombatCalculator.resolve_attack(attacker, defender)
    │       ├──→ AttributeSystem.get_total("attack"/"defense")
    │       ├──→ FormulaEngine.evaluate("damage_formula", context)
    │       └──→ RNGManager.rand_bool(COMBAT, crit_chance)
    │
    ├──→ [enemy defeated] → LootSystem.resolve_drop(enemy_id, zone_id)
    │       ├──→ EnemyDatabase → loot_table_id
    │       └──→ RNGManager.weighted_pick(LOOT, weights) → reward_bundle
    │
    └──→ ResourceSystem.batch_add(reward_bundle) → EventBus → HUD
```

### 场景 3: 离线收益结算

```
SaveManager.load_game()
    │
    ├──→ TimeManager → offline_delta = min(now - exit_timestamp, 28800)
    │
    ├──→ RNGManager.save_states() → snapshot_online
    │
    ├──→ OfflineSimCore.simulate(offline_delta, tick_callback)
    │       └──→ OfflineCombatSimulation.run_tick(snapshot_copy)
    │             └──→ CombatCalculator + LootSystem (共享在线战斗逻辑)
    │
    ├──→ RNGManager.load_states(snapshot_online)  ← 恢复在线 RNG
    │
    ├──→ ResourceSystem.batch_add(aggregated_rewards)
    │
    └──→ UIManager.show_offline_summary_screen()
```

关键：在线 RNG 通过 save_states/load_states 快照隔离，离线模拟不影响在线序列。

### 场景 4: 存档保存/加载

```
SaveManager.save_game()
    │ 调用所有 provider save_fn:
    │   ResourceSystem → {resources: {id: serialized_bn}}
    │   AttributeSystem → {attributes: {id: {base, mods}}}
    │   LevelSystem → {level, exp, realm}
    │   TimeManager → {exit_timestamp, game_ref, speed_sources}
    │   RNGManager → {master_seed, streams: {...}}
    │
    └──→ FileAccess.store_string(JSON.stringify(data))
            ⚠️ 4.4+ 返回 bool — 必须检查

SaveManager.load_game()
    │ FileAccess.get_as_text() → JSON.parse_string()
    │ 版本检查 → migration_chain
    └──→ 按 namespace 分发给各 provider restore_fn(data)
```

### 场景 5: 初始化顺序

```
App 启动
  │
  ├──→ [Autoload _ready() 按 project.godot 顺序]
  │     EventBus → RNGManager → TimeManager → DataConfig → ...
  │
  ├──→ SaveManager.has_save()?
  │     ├── [Yes] → load_game() → 各系统恢复 → 离线结算(场景3)
  │     └── [No]  → new_game() → RNG set_master_seed(random)
  │                             → ResourceSystem.add("lingqi", start)
  │                             → EventBus.emit("game.new_game")
  └──→ UIManager.show_main_screen()
```

---

## API Boundaries

### Foundation Layer

#### BigNumber（值类型 — RefCounted）

```gdscript
class_name BigNumber extends RefCounted
func _init(mantissa: float = 0.0, exponent: int = 0) -> void
static func from_int(value: int) -> BigNumber
static func from_float(value: float) -> BigNumber
static func from_string(s: String) -> BigNumber
static func from_dict(d: Dictionary) -> BigNumber
static func zero() -> BigNumber
func add(other: BigNumber) -> BigNumber         # 返回新实例（不可变）
func subtract(other: BigNumber) -> BigNumber
func multiply(other: BigNumber) -> BigNumber
func multiply_float(value: float) -> BigNumber
func divide(other: BigNumber) -> BigNumber
func power(exponent: float) -> BigNumber
func log10() -> float
func compare(other: BigNumber) -> int        # -1, 0, 1
func equals(other: BigNumber) -> bool
func is_zero() -> bool
func is_max() -> bool
func magnitude() -> int
func to_dict() -> Dictionary                  # {m: float, e: int}
func to_string() -> String
func to_scientific() -> String
```

#### EventBus（全局单例 — Autoload）

```gdscript
class_name EventBus extends Node
func emit(event_name: String, payload: Dictionary = {}) -> void
func emit_coalesced(event_name: String, payload: Dictionary, coalesce_key: String = "") -> void
func subscribe(event_name: String, callable: Callable) -> void
func subscribe_once(event_name: String, callable: Callable) -> void
func unsubscribe(event_name: String, callable: Callable) -> void
func subscribe_pattern(prefix: String, callable: Callable) -> void    # 仅调试
func unsubscribe_pattern(prefix: String, callable: Callable) -> void  # 仅调试
func set_debug_enabled(enabled: bool) -> void
```

#### TimeManager（全局单例 — Autoload）

```gdscript
class_name TimeManager extends Node
func get_real_time() -> float
func get_game_time() -> float
func get_effective_speed() -> float
func get_game_delta_since(last_game_time: float) -> float
func get_real_delta_since(last_real_time: float) -> float
func freeze() -> void
func unfreeze() -> void
func is_frozen() -> bool
func add_speed_source(source_id: String, multiplier: float) -> void
func remove_speed_source(source_id: String) -> void
func collect_save_data() -> Dictionary
func restore_save_data(data: Dictionary) -> void
```

#### RNGManager（全局单例 — Autoload）

```gdscript
class_name RNGManager extends Node
enum CoreStream { COMBAT, LOOT, EVENT, AFFIX }
func rand_int(stream_id: int, min_val: int, max_val: int) -> int
func rand_float(stream_id: int, min_val: float = 0.0, max_val: float = 1.0) -> float
func rand_bool(stream_id: int, probability: float = 0.5) -> bool
func weighted_pick(stream_id: int, weights: Array[float]) -> int
func shuffle(stream_id: int, array: Array) -> Array
func pick_random(stream_id: int, array: Array) -> Variant
func register_stream(stream_name: String) -> void
func set_master_seed(seed: int) -> void         # 仅调试
func save_states() -> Dictionary
func load_states(data: Dictionary) -> void
```

### Core Layer

#### DataConfig（Autoload 持有 RefCounted）

```gdscript
class_name DataConfig extends RefCounted
func get(table_name: String, id: String) -> Dictionary
func get_all(table_name: String) -> Dictionary
func query(table_name: String, filter: Callable) -> Array[Dictionary]
func has_table(table_name: String) -> bool
func has_record(table_name: String, id: String) -> bool
func get_field(table_name: String, id: String, field: String) -> Variant
func is_loaded() -> bool
func reload_table(table_name: String) -> void   # 热重载，Debug only
```

#### FormulaEngine（静态工具 — 无状态）

```gdscript
class_name FormulaEngine
static func evaluate(formula_id: String, context: Dictionary) -> float
static func evaluate_raw(expression: String, context: Dictionary) -> float
# context: {"attack": 150.0, "defense": 80.0, "rng": Callable(prob) -> bool}
```

#### ModifierEngine（Autoload 持有 RefCounted）

```gdscript
class_name ModifierEngine extends RefCounted
func register(data: Dictionary) -> String
func unregister(id: String) -> bool
func unregister_by_source(source_id: String) -> int
func get_add_sum(target: String) -> float
func get_pool_multiplier(target: String, pool: String) -> float
func get_multiplier(target: String) -> float
func apply(target: String, base_value: BigNumber) -> BigNumber
func get_breakdown(target: String) -> Dictionary
func get_all_targets() -> Array[String]
```

#### ResourceSystem（Autoload 持有 RefCounted）

```gdscript
class_name ResourceSystem extends RefCounted
func register(definition: Dictionary) -> bool
func add(resource_id: String, amount: BigNumber) -> BigNumber
func spend(resource_id: String, amount: BigNumber) -> bool
func get_value(resource_id: String) -> BigNumber
func get_max(resource_id: String) -> BigNumber
func set_value(resource_id: String, value: BigNumber) -> bool
func set_max(resource_id: String, cap: BigNumber) -> bool
func batch_add(resources: Dictionary) -> Dictionary   # {id: BigNumber actual_added}
func reset_by_scope(scope: String) -> int
func snapshot() -> Dictionary
func restore(data: Dictionary) -> void
```

#### SaveManager（全局单例 — Autoload）

```gdscript
class_name SaveManager extends Node
func register_provider(namespace: String, save_fn: Callable, restore_fn: Callable) -> void
func save_game(slot: int = 0) -> bool
func load_game(slot: int = 0) -> bool
func has_save(slot: int = 0) -> bool
func delete_save(slot: int = 0) -> void
func collect_save_data() -> Dictionary
func is_saving() -> bool
func is_loading() -> bool
```

---

## Technical Requirements Baseline

Extracted from 30 approved MVP GDDs. The detailed matrix is maintained in `docs/architecture/architecture-traceability.md`; this document records the architectural coverage groups that drive ADR creation.

| Coverage Group | GDD Systems | Primary ADRs | Status |
|----------------|-------------|--------------|--------|
| Foundation numeric/time/random/event infrastructure | BigNumber, EventBus, TimeManager, RNGManager | ADR-0001 to ADR-0004 | Required before coding |
| Core data and persistence infrastructure | DataConfig, SaveManager, ItemRegistry | ADR-0005, ADR-0006, ADR-0008 | Required before coding |
| Core gameplay state ownership | ResourceSystem, AttributeSystem, ModifierEngine, OutputMultiplierSystem | ADR-0007, ADR-0010 | Required before core gameplay implementation |
| Online/offline loop determinism | CombatCalculator, SemiAutoCombatSystem, OfflineSimulationCore, OfflineCombatSimulation, OfflineRewardSettlement | ADR-0003, ADR-0004, ADR-0009, ADR-0015 | Required before vertical slice prototype |
| UI/debug presentation contracts | UIFramework, HUD, DebugConsole, NumberFormatter | ADR-0002, ADR-0011, ADR-0012, ADR-0014 | Required before player-facing prototype |
| Formula and balance execution | FormulaEngine, LevelSystem, AutoProduction, Cultivation, Zone/Map progression, Loot/Enemy systems | ADR-0005, ADR-0007, ADR-0009, ADR-0013 | Required before feature implementation |

---

## ADR Audit

本轮架构优化后，以下决策均需要并将由 ADR-0001 至 ADR-0015 固化。所有 ADR 必须包含 Engine Compatibility、ADR Dependencies、GDD Requirements Addressed、Implementation Guidelines 和 Validation Criteria，供 `control-manifest.md` 与 gate-check 使用。

| Decision Point | Documented In | ADR Required |
|---------------|---------------|-------------|
| BigNumber 实现策略 | System Layer Map + API | Yes |
| EventBus 架构选型 | Module Ownership | Yes |
| 时间源策略 | Data Flow 场景 1,5 | Yes |
| RNG 多流架构 | API Boundaries | Yes |
| 数据加载策略 | Module Ownership | Yes |
| 存档格式与序列化 | Data Flow 场景 4 | Yes |
| 修正器叠加顺序 | API Boundaries | Yes |
| Autoload 初始化顺序 | Module Ownership | Yes |
| 在线/离线战斗路径统一 | Data Flow 场景 2,3 | Yes |
| UI 屏幕管理架构 | System Layer Map | Yes |
| DebugConsole 发布构建排除 | System Layer Map | Yes |
| RefCounted 服务 vs 纯 Autoload | System Layer Map | Yes |

---

## Required ADRs

### Must have before coding starts (Foundation & Core decisions)

| Priority | ADR Title | Covers GDD Systems | Key Decision |
|----------|-----------|-------------------|--------------|
| 1 | ADR-0001: BigNumber 实现策略 | 大数值系统 | GDScript RefCounted class，算术返回新实例；GDExtension 仅在性能门失败时升级 |
| 2 | ADR-0002: 事件总线架构 | 事件总线 | Autoload 单例 + 字符串事件名 + Dictionary 负载。前缀订阅仅限调试路径 |
| 3 | ADR-0003: 时间源与双时间体系 | 时间管理器 | Unix 时间戳（非 `_process(delta)`），双时间快照模型，加速倍率乘法叠加 |
| 4 | ADR-0004: 确定性随机数架构 | 随机数与种子 | 多流隔离 + 主种子推导 + FNV-1a 哈希。离线模拟状态快照隔离 |
| 5 | ADR-0005: 数据配置加载策略 | 数据配置系统 | JSON/FileAccess 加载 + 启动时全量缓存。支持热重载（Debug only） |
| 6 | ADR-0006: 存档格式与版本迁移 | 存档系统 | JSON Dictionary + provider 回调注册制 + 链式版本迁移 |
| 7 | ADR-0007: 修正器叠加顺序 | 修正器引擎 | ADD → 同池加算 MULT → 跨池乘算 MULT，缓存 target 结果 |
| 8 | ADR-0008: Autoload 初始化顺序 | 全局 | `project.godot` 显式注册顺序。EventBus 第一，DataConfigHost 先于数据消费者 |

### Should have before the relevant system is built

| Priority | ADR Title | Covers GDD Systems | Key Decision |
|----------|-----------|-------------------|--------------|
| 9 | ADR-0009: 在线/离线战斗路径统一 | 战斗计算器, 半自动战斗, 离线战斗模拟 | 共享 CombatCalculator，离线模拟使用 RNG 状态副本 |
| 10 | ADR-0010: ResourceSystem 不可变 BigNumber 策略 | 资源系统 | ResourceSystem 存储 BigNumber 值，所有算术返回新实例；batch_add 非原子 |
| 11 | ADR-0011: UI 屏幕管理架构 | UI 框架 | UIManager Autoload + Control 场景栈。显式验证 Godot 4.6 dual-focus |
| 12 | ADR-0012: DebugConsole 发布构建排除 | 调试控制台 | `_ready()` 中 `queue_free()` 模式。`process_mode = ALWAYS` 保证暂停可用 |

### Can defer to implementation

| Priority | ADR Title | Covers GDD Systems | Key Decision |
|----------|-----------|-------------------|--------------|
| 13 | ADR-0013: FormulaEngine 表达式 DSL 深度 | 公式引擎 | MVP 支持安全表达式、软上限函数和缓存；不构建完整 DSL |
| 14 | ADR-0014: NumberFormatter 缩写映射策略 | 数值格式化 | MVP 硬编码中文单位表；超过 10^48 切换科学计数法 |
| 15 | ADR-0015: 离线模拟 tick 粒度 | 离线模拟内核 | 固定 chunk/tick 策略，先按 1s 业务 tick + 最大 chunk 分块，Post-MVP 再自适应 |

---

## Architecture Principles

1. **BigNumber 是唯一的数值类型** — 所有游戏数值（资源、属性、伤害、经验）统一使用 BigNumber。GDScript 原生 `int`/`float` 仅用于索引、概率、时间差等无量纲值。

2. **EventBus 解耦一切跨系统通信** — 系统间不直接持有引用（Autoload 单例除外）。生产代码通过精确事件名订阅，前缀订阅仅限 DebugConsole。

3. **时间基于 Unix 时间戳，不依赖帧** — `_process(delta)` 不是可靠时间源。所有计时通过 `TimeManager` 的 `Time.get_unix_time_from_system()` 接口。离线收益用时间戳差值计算。

4. **在线/离线共享核心战斗逻辑** — `CombatCalculator` 是在线战斗和离线模拟的唯一伤害裁决者。离线模拟通过 RNG 状态快照隔离，不影响在线随机序列。

5. **数据驱动优于硬编码** — 所有游戏平衡数值（敌人属性、掉落表、成长公式、资源上限）从 DataConfig 外部表加载。代码只提供框架和规则，不含具体数值。

---

## Open Questions

| Question | Affects | Resolution |
|----------|---------|------------|
| BigNumber 是否需要 GDExtension C++ 实现？ | 全局 | 需性能原型验证：GDScript RefCounted 在高频运算下的帧预算占用 |
| Godot 4.6 RandomNumberGenerator 行为是否与确定性需求一致？ | RNGManager, 离线模拟 | 需最小回放测试确认 |
| 10-20 个 RNG 实例在离线批量调用下是否满足帧预算？ | 离线模拟 | 需在离线模拟原型中 profile |
| UI dual-focus system (4.6) 对键盘导航的影响？ | UI 框架, HUD | 需在 UI 原型中验证 |
| 存档反作弊/校验和策略？ | 存档系统 | 单机优先，MVP 可不含校验。Post-MVP 按需添加 |
| Autoload 服务类 class_name 冲突处理？ | 多个系统 | 推荐：内部服务类命名 `{Name}Service`，Autoload 对外用 `{Name}` |
