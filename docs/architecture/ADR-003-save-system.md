# ADR-003: 存档系统架构

## Status

Accepted

## Date

2026-04-20

## Last Verified

2026-04-20

## Decision Makers

技术总监

## Summary

游戏存档采用Resource + JSON序列化模式，数据与逻辑分离，支持多槽位存档（8槽）。存档数据封装为Resource对象，通过ResourceSaver/ResourceLoader持久化，实现存档/读档/加密/云同步基础架构。

## Engine Compatibility

| Field | Value |
|-------|-------|
| **Engine** | Godot 4.6.2 |
| **Domain** | Core / Data Persistence |
| **Knowledge Risk** | LOW — Resource系统和文件I/O是Godot核心机制 |
| **References Consulted** | `docs/engine-reference/godot/` |
| **Post-Cutoff APIs Used** | None |
| **Verification Required** | None |

## ADR Dependencies

| Field | Value |
|-------|-------|
| **Depends On** | ADR-001 (事件架构), ADR-002 (场景管理) |
| **Enables** | None |
| **Blocks** | 所有需要持久化的GDD系统 |
| **Ordering Note** | 存档系统依赖事件架构（GameEvents.game_saved） |

## Context

### Problem Statement

SRPG游戏需要保存：角色属性/等级/技能、装备/背包、基地状态、剧情进度、多周目成就点、羁绊数据。数据量大且类型复杂，需要统一的存档格式和版本管理。

### Current State

项目初期，无现有实现。

### Constraints

- Godot 4.6.2的Resource系统是标准持久化方案
- PC平台存储空间充足，但需要防作弊（存档加密）
- Steam Cloud支持需要特定集成

### Requirements

- 至少8个存档槽位
- 存档必须包含版本号，支持向后兼容
- 存档数据与逻辑代码分离
- 支持自动存档（关键节点）

## Decision

### 存档数据结构

```gdscript
# SaveData.gd
class_name SaveData
extends Resource

@export var version: int = 1  # 存档版本，用于迁移
@export var timestamp: int = 0  # Unix时间戳
@export var playtime: int = 0  # 秒

@export var party: Array[UnitSaveData]  # 队伍数据
@export var inventory: Array[ItemSaveData]  # 背包数据
@export var base: BaseSaveData  # 基地数据
@export var story_progress: StorySaveData  # 剧情进度
@export var settings: Dictionary  # 游戏设置

@export var achievement_points: int = 0  # 成就点数
@export var new_game_plus: Dictionary  # 多周目数据

class UnitSaveData:
    extends RefCounted
    var unit_id: int
    var unit_type: String
    var level: int
    var exp: int
    var attributes: Dictionary  # 五维属性
    var hidden_attributes: Dictionary  # 隐藏属性
    var potential: Dictionary  # 潜质
    var skills: Array[String]  # 技能列表
    var equipment: Dictionary  # 装备槽位

class ItemSaveData:
    extends RefCounted
    var item_id: String
    var quantity: int
    var enchantments: Array[String]

class BaseSaveData:
    extends RefCounted
    var level: int
    var unlocked_areas: Array[String]

class StorySaveData:
    extends RefCounted
    var current_chapter: int
    var completed_events: Array[String]
    var choices_made: Dictionary  # 信念值记录
    var bond_levels: Dictionary  # 羁绊等级记录
```

### 存档管理器

```gdscript
# SaveManager.gd (Autoload)
extends Node

const SAVE_DIR := "user://saves/"
const MAX_SLOTS := 8
const ENCRYPT_KEY := "SRPG_2026"  # 简单XOR加密

var _current_slot: int = -1

func save_game(slot: int) -> bool:
    var save_data := _create_save_data()
    save_data.timestamp = Time.get_unix_time_from_system()

    var path := SAVE_DIR + "save_%d.tres" % slot
    var result := ResourceSaver.save(save_data, path)
    if result == OK:
        _current_slot = slot
        GameEvents.game_saved.emit(slot, save_data.timestamp)
        return true
    return false

func load_game(slot: int) -> bool:
    var path := SAVE_DIR + "save_%d.tres" % slot
    if not FileAccess.file_exists(path):
        return false

    var save_data := load(path) as SaveData
    if save_data == null:
        push_error("Failed to load save from slot ", slot)
        return false

    _apply_save_data(save_data)
    _current_slot = slot
    GameEvents.game_loaded.emit(slot)
    return true

func _create_save_data() -> SaveData:
    var data := SaveData.new()
    data.party = _capture_party_data()
    data.inventory = _capture_inventory_data()
    data.base = _capture_base_data()
    data.story_progress = _capture_story_data()
    data.playtime = _calculate_playtime()
    return data

func _apply_save_data(data: SaveData) -> void:
    # 版本迁移检查
    if data.version < SaveData.version:
        data = _migrate_save_data(data)

    _restore_party_data(data.party)
    _restore_inventory_data(data.inventory)
    _restore_base_data(data.base)
    _restore_story_data(data.story_progress)
```

### 自动存档

```gdscript
# AutoSaveTrigger.gd
extends Node

@export var auto_save_on_events: Array[String] = [
    "chapter_completed",
    "major_choice_made",
    "base_upgraded"
]

func _ready() -> void:
    for event_name in auto_save_on_events:
        GameEvents.get(event_name).connect(_on_auto_save_event)

func _on_auto_save_event(_context: Dictionary = {}) -> void:
    var last_save_slot := UserSettings.get_last_save_slot()
    SaveManager.save_game(last_save_slot)
```

### 存档槽位UI

```gdscript
# SaveSlotButton.gd (UI组件)
extends Button

@export var slot_index: int = 0

func _ready() -> void:
    pressed.connect(_on_slot_selected)
    _update_display()

func _update_display() -> void:
    var path := SaveManager.SAVE_DIR + "save_%d.tres" % slot_index
    if FileAccess.file_exists(path):
        var save_data := load(path) as SaveData
        var date := Time.get_datetime_string_from_unix_time(save_data.timestamp)
        var playtime_hours := save_data.playtime / 3600
        text = "Slot %d\n%s\n%d小时" % [slot_index, date, playtime_hours]
        disabled = false
    else:
        text = "Slot %d\n空" % slot_index
        disabled = false
```

## Alternatives Considered

### Alternative 1: JSON文件存档

- **Description**: 使用JSON文件存储存档数据
- **Pros**: 可读性好，跨平台兼容
- **Cons**: 需要手动序列化/反序列化，无类型检查
- **Estimated Effort**: 低
- **Rejection Reason**: Resource系统提供更好的类型安全和编辑器支持

### Alternative 2: SQLite数据库

- **Description**: 使用SQLite存储游戏数据
- **Pros**: 查询能力强，支持复杂关系数据
- **Cons**: 过度工程化，SRPG存档结构简单
- **Estimated Effort**: 高
- **Rejection Reason**: 架构不匹配，Resource系统足够

### Alternative 3: 云端存档服务

- **Description**: 使用Steam Cloud或自建服务器同步存档
- **Pros**: 防丢失，多设备同步
- **Cons**: 需要网络，需要Steam集成
- **Estimated Effort**: 中
- **Rejection Reason**: MVP阶段不考虑，基础架构支持后续扩展

## Consequences

### Positive

- Resource系统提供类型安全
- 版本号支持存档迁移
- 基础架构支持Steam Cloud扩展

### Negative

- ResourceSaver有平台差异
- 存档文件路径跨平台需测试

### Neutral

- XOR加密仅防小白，非真正加密

## Risks

| Risk | Probability | Impact | Mitigation |
|------|------------|--------|------------|
| 存档损坏 | 低 | 高 | 写前备份，加载前校验 |
| 版本迁移bug | 中 | 高 | 完整测试覆盖 |

## Performance Implications

| Metric | Before | Expected After | Budget |
|--------|--------|---------------|--------|
| 存档写入 | N/A | <500ms | <1s |
| 存档读取 | N/A | <200ms | <500ms |
| 存档大小 | N/A | <1MB/槽 | <2MB |

## Migration Plan

1. 创建SaveData Resource类
2. 实现SaveManager Autoload
3. 实现存档槽位UI
4. 添加自动存档触发器
5. 测试存档迁移（版本1→2）

**Rollback plan**: 删除损坏存档，从备份恢复

## Validation Criteria

- [ ] 8个存档槽位全部可读写
- [ ] 存档/读档后数据完整恢复
- [ ] 版本迁移后无数据丢失
- [ ] 自动存档在关键节点触发
- [ ] 存档文件不包含作弊数据

## GDD Requirements Addressed

| GDD Document | System | Requirement | How This ADR Satisfies It |
|-------------|--------|-------------|--------------------------|
| `attribute-growth-system.md` | 属性系统 | 属性/等级/技能必须持久化 | UnitSaveData保存完整属性数据 |
| `class-system.md` | 职业系统 | 职业解锁状态持久化 | 职业数据包含在UnitSaveData中 |
| `resource-economy.md` | 资源系统 | 双层资源持久化 | inventory保存资源数据 |
| `character-management.md` | 角色管理 | 羁绊数据持久化 | StorySaveData.bond_levels保存羁绊 |
| `character-management.md` | 多周目 | 成就点数跨周目 | achievement_points持久化 |
| Foundational | Foundation | 所有GDD系统的数据持久化 | 统一存档格式 |

## Related

- ADR-001: 事件架构（GameEvents.game_saved/game_loaded）
- ADR-002: 场景管理架构（场景切换时触发存档检查）
