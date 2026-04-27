# Architecture Document

> 版本: v0.3 | 日期: 2026-04-27 | 状态: Sprint-008 对齐

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
signal equipment_enhanced(item_id: String, level: int, success: bool)

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

func decompose_item(item: ItemData) -> Dictionary:
    ...

func reroll_affix(item: ItemData, affix_index: int) -> Dictionary:
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

### 5.3 基地数据流

```
BaseHub → CharacterRoster / Inventory / BondRegistry / BaseUpgradeModel → SaveManager
```

基地场景是战斗间隙的整备入口。训练、市场、酒馆、基地升级和角色管理都写入同一份 `SaveData`：

1. `BaseHub` 从当前存档恢复 `party_units`、`inventory_state`、`story_progress` 和基地升级状态。
2. Tavern 通过 `BondRegistry` 写回 `story_progress.bond_levels`。
3. Upgrade 通过 `BaseUpgradeModel` 读取成本并写回 `story_progress.base_upgrade`。
4. Management 通过 `CharacterManagement` 修改队伍、装备强化、分解和词缀 reroll，并由 `SaveManager` 保存。

### 5.4 Ch.3 内容管线

```
battle_definitions/*.json → BattleArena → Chapter03PressureModel / B3GateEvaluator → story_progress → next battle
```

Chapter 3 仍采用数据驱动战斗定义：

1. `chapter_03_act_a.json` 记录 B3-N1 runtime choice，并把结果写入 `story_progress.belief_values`。
2. `chapter_03_act_b.json` 使用 `Chapter03PressureModel` 读取 Ch.3-1 救援结果，计算敌方士气与信标目标状态；胜利后运行 B3-N2 行为计分。
3. `B3GateEvaluator` 在 Ch.3-2 胜利后写入 `story_progress.b3_gate`，只标记 soft-lock candidate，不 hard lock。
4. `chapter_03_finale.json` 根据 `b3_gate.dominant_route` 选择 Finale 变体，并复用现有 Boss 阶段处理。

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
- ADR-004: 战斗系统架构
- ADR-005: AI 行为架构
- ADR-006: 属性数据模型
- ADR-007: 信念分支系统
- ADR-008: 资源经济与升级
- ADR-009: 装备升级范围
- 设计/gdd/systems-index.md
- 技术偏好/.claude/docs/technical-preferences.md
