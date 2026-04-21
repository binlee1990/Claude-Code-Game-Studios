# ADR-002: 场景管理架构

## Status

Accepted

## Date

2026-04-20

## Last Verified

2026-04-20

## Decision Makers

技术总监

## Summary

游戏场景采用PackedScene+ResourceLoader异步加载模式，主场景管理SceneTree切换，子场景通过实例化复用。地图场景与UI场景分层，UI层常驻根节点，实现HD-2D视觉一致性。

## Engine Compatibility

| Field | Value |
|-------|-------|
| **Engine** | Godot 4.6.2 |
| **Domain** | Core / Scene Management |
| **Knowledge Risk** | LOW — 场景系统是Godot核心机制 |
| **References Consulted** | `docs/engine-reference/godot/` |
| **Post-Cutoff APIs Used** | None |
| **Verification Required** | None |

## ADR Dependencies

| Field | Value |
|-------|-------|
| **Depends On** | ADR-001 (事件架构) |
| **Enables** | ADR-003 (存档系统) |
| **Blocks** | 地图系统、UI系统实现 |
| **Ordering Note** | 场景管理架构基于事件架构，两者协同设计 |

## Context

### Problem Statement

HD-2D游戏需要同时管理：3D地图场景（地形、建筑、装饰）、2D像素角色（Sprite2D）、UI层（HUD、菜单）。这些层需要协调切换、状态保持、内存管理。传统单场景模式无法满足模块化和内存优化需求。

### Current State

项目初期，无现有实现。

### Constraints

- Godot 4.6.2的PackedScene和ResourceLoader是标准方案
- HD-2D要求像素渲染设置（filter: Nearest, repeat: Disabled）
- PC平台内存相对宽松，但需要控制纹理显存

### Requirements

- 场景切换必须平滑（加载时显示loading提示）
- 场景状态必须可持久化（存档/读档）
- UI层不得与游戏逻辑层耦合
- 支持场景预加载优化

## Decision

### 场景层次架构

```
[SceneTree]
├── [Layer 0] Camera & Environment
│   └── Camera3D (跟随系统)
│   └── WorldEnvironment (光照/雾效)
│   └── DirectionalLight3D (主光源)
│
├── [Layer 1] Game World
│   └── [State: Overworld]
│       └── OverworldMap (主世界场景)
│   └── [State: Battle]
│       └── BattleArena (战斗地图场景)
│
├── [Layer 2] Units (角色层)
│   └── UnitManager (单位管理节点)
│       └── [动态实例化各角色单元]
│
├── [Layer 3] UI Root
│   └── UIRoot (常驻)
│       ├── HUDLayer (战斗HUD)
│       ├── MenuLayer (菜单)
│       └── DialogLayer (对话)
│
└── [Layer 4] Effects
    └── EffectsRoot (粒子、特效)
```

### 场景类型定义

| 场景类型 | 加载策略 | 示例 |
|----------|----------|------|
| **主场景** | 预加载 | OverworldMap, BattleArena |
| **子场景** | 实例化复用 | Unit, SkillEffect, Projectile |
| **UI场景** | 按需加载 | HUD, Inventory, SkillTree |
| **过渡场景** | 独立加载 | LoadingScreen, TransitionFade |

### 场景切换流程

```gdscript
# SceneManager.gd (Autoload)
extends Node

const SCENES := {
    "overworld": "res://scenes/world/overworld_map.tscn",
    "battle": "res://scenes/battle/battle_arena.tscn",
    "main_menu": "res://scenes/ui/main_menu.tscn",
}

var _current_scene: Node = null
var _loading_screen: Node = null

func switch_scene(scene_key: String, context: Dictionary = {}) -> void:
    GameEvents.scene_switch_started.emit(scene_key, context)

    # 1. 显示加载画面
    _show_loading_screen()

    # 2. 异步加载新场景
    var scene_path := SCENES.get(scene_key, "")
    if scene_path.is_empty():
        push_error("Unknown scene: ", scene_key)
        return

    await _load_scene_async(scene_path)

    # 3. 卸载旧场景
    if _current_scene:
        _current_scene.tree_exited.connect(_on_old_scene_exited)
        _current_scene.queue_free()

    # 4. 切换到新场景
    get_tree().root.add_child(_current_scene)
    get_tree().current_scene = _current_scene

    # 5. 初始化场景上下文
    if _current_scene.has_method("setup"):
        (_current_scene as Node).setup(context)

    GameEvents.scene_switch_completed.emit(scene_key)
    _hide_loading_screen()

func _load_scene_async(path: String) -> void:
    var packed := load(path)
    _current_scene = packed.instantiate()
```

### 地图场景内部结构

```gdscript
# BattleArena.gd
extends Node3D

@onready var _tile_map: TileMapLayer = $TileMapLayer
@onready var _units_container: Node3D = $Units
@onready var _effects_container: Node3D = $Effects

func setup(context: Dictionary) -> void:
    var map_id: String = context.get("map_id", "")
    var difficulty: int = context.get("difficulty", 1)

    # 加载地图数据
    var map_data := MapData.load(map_id)
    _tile_map.clear()
    _tile_map.set_cells_terrain_set(map_data.terrain_data)

    # 生成单位
    for spawn_point in map_data.enemy_spawns:
        _spawn_enemy(spawn_point)

func _spawn_enemy(spawn_data: Dictionary) -> void:
    var unit_scene := load("res://scenes/world/unit.tscn")
    var unit := unit_scene.instantiate()
    unit.initialize(spawn_data)
    _units_container.add_child(unit)
```

### HD-2D渲染设置

```gdscript
# ProjectSettings.gd (项目启动时设置)
func _ready() -> void:
    # 像素完美渲染设置
    get_viewport().texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
    get_viewport().rendering_stretch_factor = 3.0  # 3D像素比
    get_viewport().rendering_stretch_mode = Viewport.STRETCH_MODE_INTEGER
```

## Alternatives Considered

### Alternative 1: 单一大场景

- **Description**: 所有内容放在一个场景中，通过节点显隐切换
- **Pros**: 简单，无场景切换开销
- **Cons**: 内存占用大，难以按需加载，违背模块化原则
- **Estimated Effort**: 低
- **Rejection Reason**: 内存和模块化不满足需求

### Alternative 2: 地址资源系统（ResourceUID）

- **Description**: 使用Godot 4.4+的ResourceUID系统管理场景
- **Pros**: 更现代，类型安全
- **Cons**: Godot 4.6.2中ResourceUID仅用于脚本资源，非场景资源
- **Estimated Effort**: 中
- **Rejection Reason**: 不适用，ResourceUID用于脚本而非场景

## Consequences

### Positive

- 场景按需加载，内存使用优化
- 模块化设计，便于独立测试
- UI与游戏逻辑分离，职责清晰

### Negative

- 场景切换有短暂黑屏/加载时间
- 需要维护场景注册表

### Neutral

- 场景路径硬编码在SCENES字典中

## Risks

| Risk | Probability | Impact | Mitigation |
|------|------------|--------|------------|
| 场景循环引用 | 低 | 高 | 通过事件解耦，禁止直接场景引用 |
| 加载卡顿 | 中 | 中 | 实现进度条显示，提供取消选项 |

## Performance Implications

| Metric | Before | Expected After | Budget |
|--------|--------|---------------|--------|
| 场景切换 | N/A | <2s (含加载画面) | <2s |
| 内存占用 | N/A | <500MB (战斗场景) | <512MB |

## Migration Plan

1. 创建SceneManager Autoload
2. 创建BaseScene基类（所有场景继承）
3. 迁移现有场景到新架构
4. 添加单元测试验证场景切换

**Rollback plan**: 回退到直接`get_tree().change_scene_to_file()`

## Validation Criteria

- [ ] SceneManager.gd是Autoload
- [ ] 所有场景切换通过SceneManager
- [ ] 场景切换有loading画面
- [ ] UI层与游戏逻辑层节点无交叉引用
- [ ] HD-2D渲染设置正确（Nearest filter）

## GDD Requirements Addressed

| GDD Document | System | Requirement | How This ADR Satisfies It |
|-------------|--------|-------------|--------------------------|
| `camera-map-system.md` | 地图系统 | 2.5D斜45度方形网格 | 场景架构支持TileMap和3D节点 |
| `ui-system.md` | UI系统 | UI层常驻根节点 | UI层与游戏逻辑分离 |
| Foundational | Foundation | 场景管理基础 | 所有GDD系统的场景载体 |

## Related

- ADR-001: 事件架构
- ADR-003: 存档系统架构
