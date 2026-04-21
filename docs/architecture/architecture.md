# Architecture Document

> 版本: v0.1 | 日期: 2026-04-20 | 状态: 初稿

---

## 1. 架构概述

本架构文档定义了SRPG游戏的核心系统架构，基于已批准的架构决策记录（ADR）。

**技术栈**:
- 引擎: Godot 4.6.2
- 语言: GDScript
- 渲染: 2.5D HD-2D（3D场景 + 像素角色）
- 目标平台: PC (Steam)

**架构原则**:
- 事件驱动解耦（ADR-001）
- 场景模块化（ADR-002）
- 数据持久化分离（ADR-003）

---

## 2. 系统层级

```
┌─────────────────────────────────────────────────────────────┐
│                    Presentation Layer                        │
│  ┌─────────┐ ┌─────────┐ ┌─────────┐ ┌─────────────────┐ │
│  │   UI    │ │  HUD    │ │ Dialog  │ │    Effects      │ │
│  └─────────┘ └─────────┘ └─────────┘ └─────────────────┘ │
├─────────────────────────────────────────────────────────────┤
│                     Gameplay Layer                          │
│  ┌─────────┐ ┌─────────┐ ┌─────────┐ ┌─────────────────┐ │
│  │ Combat  │ │   AI    │ │  Skills │ │  Equipment      │ │
│  └─────────┘ └─────────┘ └─────────┘ └─────────────────┘ │
│  ┌─────────┐ ┌─────────┐ ┌─────────┐ ┌─────────────────┐ │
│  │  Bond   │ │   Base  │ │  Story  │ │   Attributes    │ │
│  └─────────┘ └─────────┘ └─────────┘ └─────────────────┘ │
├─────────────────────────────────────────────────────────────┤
│                    Foundation Layer                          │
│  ┌─────────┐ ┌─────────┐ ┌─────────┐ ┌─────────────────┐ │
│  │  Event  │ │ Scene   │ │  Save   │ │   Input         │ │
│  │  Bus    │ │ Manager │ │  System │ │   Manager       │ │
│  └─────────┘ └─────────┘ └─────────┘ └─────────────────┘ │
│  ┌─────────┐ ┌─────────┐ ┌─────────┐                      │
│  │  Audio  │ │  Config │ │   Log   │                      │
│  └─────────┘ └─────────┘ └─────────┘                      │
└─────────────────────────────────────────────────────────────┘
```

---

## 3. 核心系统架构

### 3.1 事件总线 (ADR-001)

所有系统间通信通过GameEvents Autoload实现：

```gdscript
# GameEvents.gd (Autoload)
extends Node

# 战斗事件
signal battle_started(battle_id: String, map_id: String, difficulty: int)
signal battle_ended(battle_id: String, victory: bool, battle_stats: Dictionary)
signal turn_started(actor_id: int, turn_number: int)
signal turn_ended(actor_id: int)

# 单位事件
signal unit_spawned(unit_id: int, unit_type: String, position: Vector2i)
signal unit_died(unit_id: int, killer_id: int)
signal health_changed(unit_id: int, old_value: int, new_value: int, cause: String)

# 技能事件
signal skill_executed(unit_id: int, skill_id: String, target_ids: Array[int])
signal skill_learned(unit_id: int, skill_id: String)

# 装备事件
signal item_equipped(unit_id: int, item_id: String, slot: String, previous_item: String)
signal item_unequipped(unit_id: int, item_id: String, slot: String)

# 羁绊事件
signal bond_level_up(unit_id: int, partner_id: int, old_level: int, new_level: int)

# 存档事件
signal game_saved(slot: int, timestamp: int)
signal game_loaded(slot: int)
```

### 3.2 场景管理 (ADR-002)

```
SceneTree
├── Camera & Environment (Layer 0)
├── Game World (Layer 1) - 动态切换
│   ├── OverworldMap
│   └── BattleArena
├── Units (Layer 2) - 动态实例化
├── UI Root (Layer 3) - 常驻
└── Effects (Layer 4) - 粒子/特效
```

场景切换流程：SceneManager.switch_scene() → 显示loading → 异步加载 → 切换场景 → 初始化

### 3.3 存档系统 (ADR-003)

```
SaveData (Resource)
├── version: int
├── party: Array[UnitSaveData]
├── inventory: Array[ItemSaveData]
├── base: BaseSaveData
├── story_progress: StorySaveData
└── achievement_points: int
```

---

## 4. 子系统接口

### 4.1 CombatSystem

```gdscript
# CombatSystem.gd
class_name CombatSystem
extends Node

func start_battle(map_id: String, difficulty: int) -> void:
    ...

func end_turn() -> void:
    ...

func execute_skill(unit_id: int, skill_id: String, target_ids: Array[int]) -> void:
    ...

func calculate_damage(attacker: UnitData, defender: UnitData, skill: SkillData) -> int:
    ...
```

### 4.2 AttributeSystem

```gdscript
# AttributeSystem.gd
class_name AttributeSystem
extends Node

const ATTRIBUTES := ["strength", "agility", "physique", "intelligence", "charisma"]
const HIDDEN_ATTRIBUTES := ["luck", "willpower", "anomaly_resist", "soul_strength"]

func calculate_growth(unit: UnitData, level: int) -> Dictionary:
    ...

func apply_fruit(unit: UnitData, attribute: String, fruit_id: String) -> void:
    ...

func check_wall_break(unit: UnitData, attribute: String) -> bool:
    ...
```

### 4.3 SkillSystem

```gdscript
# SkillSystem.gd
class_name SkillSystem
extends Node

func learn_skill(unit: UnitData, skill_id: String) -> bool:
    ...

func execute_skill(unit: UnitData, skill: SkillData, targets: Array) -> Dictionary:
    ...

func rank_up_skill(unit: UnitData, skill_id: String) -> bool:
    ...
```

### 4.4 EquipmentSystem

```gdscript
# EquipmentSystem.gd
class_name EquipmentSystem
extends Node

const EQUIP_SLOTS := ["weapon", "armor", "helmet", "accessory1", "accessory2"]

func equip_item(unit: UnitData, item: ItemData, slot: String) -> ItemData:
    ...

func enhance_item(item: ItemData, level: int) -> bool:
    ...

func reforge_item(item: ItemData, material: MaterialData) -> bool:
    ...
```

### 4.5 BondSystem

```gdscript
# BondSystem.gd
class_name BondSystem
extends Node

const BOND_TYPES := ["comrade", "master", "rival", "lover"]
const BOND_LEVELS := ["C", "B", "A", "S"]

func increase_bond(unit_id: int, partner_id: int, bond_type: String, amount: int) -> void:
    ...

func trigger_combo_skill(unit_id: int, partner_id: int) -> SkillData:
    ...
```

---

## 5. 数据流

### 5.1 战斗数据流

```
Input → InputManager → GameEvents → CombatSystem → GameEvents → HUD/Effects
```

1. 玩家选择技能目标
2. InputManager捕获并转发
3. GameEvents.skill_executed.emit()
4. CombatSystem处理逻辑
5. GameEvents.health_changed.emit()
6. HUD更新显示，Effects播放粒子

### 5.2 存档数据流

```
GameEvents → SaveManager → SaveData → ResourceSaver → user://saves/
```

---

## 6. 技术约束

- **帧率**: 60 FPS (16.6ms帧预算)
- **Draw Calls**: 探索<100, 战斗<150, 含UI<200
- **内存**: 纹理<512MB, 总内存TBD
- **存档**: 8槽位, <1MB/槽

---

## 7. 开放问题

- [ ] 网络多人模式架构（未来扩展）
- [ ] DLC内容架构（未来扩展）
- [ ] Mod支持架构（未来扩展）

---

## 8. 相关文档

- ADR-001: 事件架构
- ADR-002: 场景管理架构
- ADR-003: 存档系统架构
- 设计/gdd/systems-index.md
- 技术偏好/.claude/docs/technical-preferences.md
