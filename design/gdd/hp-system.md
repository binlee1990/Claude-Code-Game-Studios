# HP 系统

> **Status**: Designed
> **Author**: user + agents
> **Last Updated**: 2026-04-26
> **Implements Pillar**: 系统互锁 —— HP 由属性、职业、等级、装备共同派生
> **Creative Director Review (CD-GDD-ALIGN)**: SKIPPED — Solo mode

## Overview

HP（生命值）系统定义角色的最大生命值与战斗内的当前生命值管理。HP 不是独立属性，而是从体力(CON)、职业基础、职业等级、装备四个维度派生的复合数值。战斗外角色永远满血——current HP 仅在 `combat_system._combat_units` 字典中存在，存档不持久化 current_hp（与战败 HP=0 自动恢复 AVAILABLE 的角色管理规则一致）。

## Player Fantasy

**直觉一致**: 玩家训练 CON 看到 HP 上升，换上重甲职业看到 HP 提升，强化装备看到 HP 提升 —— 所有"耐久"投入都立刻可见。

**零冗余决策**: 战斗结束自动满血意味着玩家无需在战斗外管理"医疗资源"，注意力集中在战斗策略与养成路径，不被恢复性消耗品分散。

**职业差异感知**: Mage(base=25) 与 Knight(base=50) 的 HP 差异在角色管理界面一眼可见，传达"前排坦克 vs 后排脆皮"的职业定位。

## Detailed Rules

### R-1 战斗外
- 单位永远满血。`character_management` 显示 `HP max_hp / max_hp`
- 不追踪 current_hp，不持久化到存档
- 单位定义文件不再硬编码玩家 max_hp，由公式派生

### R-2 战斗内（玩家单位）
- 单位创建时调用 `Unit.get_max_hp()`（即 `HpFormula.calculate_max_hp(unit)`）
- 流程顺序: 创建 Unit Node → 应用 stats → `configure_starting_class` → `_seed_equipment_from_definition` → `unit.get_max_hp()` → `combat_system.register_unit(unit, team, max_hp)`
- 之后 `_combat_units[unit].hp/max_hp` 由战斗系统独立追踪

### R-3 战斗内（敌人单位）
- 敌人 max_hp 仍由 battle definition 显式提供（`entry.hp`），通过 `BattleDifficultyProfile.scale_enemy_hp` 应用难度倍率
- 不走派生公式 —— 敌人调参在战斗定义里直接控制
- Boss 阶段切换以战斗中的 max_hp 为基准计算阈值（HP%）

### R-4 战斗结束
- combat_system 状态丢弃，所有单位回到"满血"概念
- 战败单位 → `CharacterRoster` 标记为 DEPLOYED 或 AVAILABLE（继续可上场）
- 不存在"带血结算"或"战外受伤"

### R-5 装备 HP 加成
- 装备词缀 `AffixType.HP`（stat_key="hp"）已存在于 `equipment_definitions.gd`
- 套装 4 件加成 `WARRIOR_POWER` 提供 `stats.hp = 100`
- `EquipmentComponent.get_stat_bonus("hp")` 已聚合词缀和套装加成
- `HpFormula.equipment_hp_bonus(unit)` 直接返回该值

## Formulas

### F-1 max_hp 派生公式

```text
max_hp = class_base_hp(class_id)
       + CON × CON_COEFFICIENT
       + class_level × LEVEL_COEFFICIENT
       + equipment_hp_bonus
```

| 变量 | 符号 | 类型 | 范围 | 说明 |
|------|------|------|------|------|
| class_base_hp | b | int | [25, 60] | 来自 `ClassNames.CLASS_BASE_HP[class_id]`，按职业耐久档位划分 |
| CON | c | int | [0, 999] | 战斗外有效 CON（base + 职业加成 + 装备加成 + 壁障加成）。来自 `unit.get_effective_attribute(AttributeNames.Attribute.CON)` |
| CON_COEFFICIENT | k₁ | int | 5 (常量) | 每点 CON 提供的 HP |
| class_level | L | int | [1, ∞) | 当前职业等级 = `class_component.get_class_level()` |
| LEVEL_COEFFICIENT | k₂ | int | 3 (常量) | 每职业等级提供的 HP |
| equipment_hp_bonus | e | int | [0, ∞) | `equipment_component.get_stat_bonus("hp")` |

### F-2 职业基础 HP 表

| ClassID | base | 档位 | 范例参考 |
|---------|------|------|----------|
| BASIC_MAGE | 25 | 极脆 | 远程法术输出 |
| BASIC_ARCHER | 28 | 脆 | 远程物理 |
| BASIC_ROGUE | 28 | 脆 | 高敏单体 |
| ADV_BATTLEMAGE | 30 | 脆 | 双系混合 |
| ADV_ASSASSIN | 30 | 脆 | 极敏单体 |
| BASIC_CLERIC | 32 | 中等 | 治疗辅助 |
| ADV_MARKSMAN | 32 | 中等 | 远程主力 |
| SPC_NIGHTSHADE | 35 | 中等 | 高敏特职 |
| ADV_HIGHCLERIC | 38 | 中坚 | 进阶治疗 |
| BASIC_WARRIOR | 40 | 中坚 | 前排物理 |
| ADV_SWORDMASTER | 45 | 中坚 | 进阶剑士 |
| SPC_SOVEREIGN | 45 | 中坚 | 全能特职 |
| BASIC_KNIGHT | 50 | 厚 | 前排坦克 |
| ADV_PALADIN | 55 | 厚 | 进阶坦克 |
| SPC_DRAGONKNIGHT | 60 | 极厚 | 顶级坦克 |

### F-3 范例计算

| 角色 | class | level | CON | equip_hp | max_hp |
|------|-------|-------|-----|----------|--------|
| 新手剑士 | BASIC_WARRIOR(40) | 1 | 10 | 0 | 40 + 50 + 3 + 0 = 93 |
| Lv5 法师 | BASIC_MAGE(25) | 5 | 10 | 0 | 25 + 50 + 15 + 0 = 90 |
| Lv5 骑士（无装备） | BASIC_KNIGHT(50) | 5 | 20 | 0 | 50 + 100 + 15 + 0 = 165 |
| Lv5 骑士 + WARRIOR_POWER 2 件 | BASIC_KNIGHT(50) | 5 | 20 | 100 | 50 + 100 + 15 + 100 = 265 |
| Lv5 骑士 + WARRIOR_POWER 4 件 | BASIC_KNIGHT(50) | 5 | 20 | 100 | 同上 = 265 (4 件比 2 件多的是 `double_damage_chance` 效果，不再加 hp) |
| Lv10 龙骑 + HP 词缀 50 | SPC_DRAGONKNIGHT(60) | 10 | 30 | 50 | 60 + 150 + 30 + 50 = 290 |

## Edge Cases

- **If 职业未在 `CLASS_BASE_HP` 中找到** → `get_class_base_hp()` 返回默认 30。理由：防御性兜底，避免 KeyError。
- **If `unit.equipment_component == null`** → `equipment_hp_bonus(unit)` 返回 0。理由：HpFormula 必须独立可调用，不依赖装备初始化时序。
- **If CON 为 0**（被诅咒/未初始化）→ HP = base + 0 + level × 3 + equip。理由：CON 系数无下限钳制，但 base + level 分量保证 HP > 0。
- **If 战斗中职业切换** → max_hp 不重新计算（战斗内 max_hp 已在 register 时锁定）。HP% 按旧 max_hp 计算。理由：战斗中变更 max_hp 会破坏 Boss 阶段切换语义。
- **If 装备在战斗中被替换**（未来功能）→ 当前不支持，max_hp 在 register 时一次性锁定。
- **If 多个装备词缀都加 hp** → 全部累加，无上限。`get_stat_bonus("hp")` 已经做了求和。
- **If 战败状态读取 HP** → `combat_system._combat_units` 中 hp 字段保留为 0；战外 `unit.get_max_hp()` 仍返回完整公式值（与"战外满血"语义一致）。

## Dependencies

| 系统 | 关系 | 描述 |
|------|------|------|
| **属性与成长系统** | 硬依赖 | 公式从 CON 派生 |
| **职业系统** | 硬依赖 | 公式从 class_id (CLASS_BASE_HP) 与 class_level 派生 |
| **装备系统** | 硬依赖 | 公式从 equipment.get_stat_bonus("hp") 累加 |
| **回合制模式** | 单向调用 | combat_system.register_unit 在战斗开始时取一次 max_hp |
| **战斗结算** | 反向消费 | 战败判定 `所有HP=0` 由 combat_system 输出 |
| **角色管理** | 反向消费 | UI 通过 `unit.get_max_hp()` 显示静态满血 |
| **Boss战** | 反向消费 | Boss 阶段切换以战斗内 max_hp 为基准 |
| **难度系统** | 反向消费 | 敌人 max_hp 由 difficulty 倍率作用于 entry.hp（不影响玩家公式） |
| **羁绊系统** | 反向消费 | "誓约守护"消耗 30% HP 基于 max_hp |
| **AI系统** | 反向消费 | 仇恨用 100/HP，目标筛选用 HP% |

## Tuning Knobs

| 旋钮 ID | 名称 | 当前值 | 安全范围 | 影响 |
|---------|------|--------|----------|------|
| `TK-HP-01` | CON_COEFFICIENT | 5 | 3 ~ 8 | 提高 → CON 投入回报变高，鼓励堆 CON Build |
| `TK-HP-02` | LEVEL_COEFFICIENT | 3 | 1 ~ 6 | 提高 → 等级差影响放大，低级角色被淘汰更快 |
| `TK-HP-03` | CLASS_BASE_HP[*] | 25-60 | 20-80 | 提高某职业 → 该职业前排化；降低 → 后排化 |
| `TK-HP-04` | 套装 4 件 hp 加成 | WARRIOR_POWER: 100 | 50-200 | 影响装备组件相对吸引力 |
| `TK-HP-05` | 装备 HP 词缀范围 | QUALITY_AFFIX_RANGES | — | 见 equipment-system.md |

## Acceptance Criteria

- [ ] **AC-1** 公式落地：`HpFormula.calculate_max_hp(unit)` 输出 = `class_base + CON × 5 + level × 3 + equip_hp`，与 F-3 范例值一致
- [ ] **AC-2** Unit API：`unit.get_max_hp()` 调用 HpFormula，无错误
- [ ] **AC-3** 战外 UI：`character_management.gd` 调用 `unit.get_max_hp()` 显示 `HP max/max` 格式
- [ ] **AC-4** 战内玩家：`battle_arena._create_unit_from_definition` 玩家分支用 `unit.get_max_hp()` 注册到 combat_system
- [ ] **AC-5** 战内敌人：敌人分支仍走 `entry.hp + scale_enemy_hp`，未受影响
- [ ] **AC-6** 装备加成：装备 HP 词缀变更时 `unit.get_max_hp()` 输出变化（注：战斗内已锁定，仅战外查询）
- [ ] **AC-7** 装备空：`equipment_component == null` 时 `equipment_hp_bonus()` 返回 0，不报错
- [ ] **AC-8** 存档：保存与读取流程不出现 current_hp 字段（作为正反验证：grep `current_hp` 在 save 相关文件应只出现在 combat_system 内部）
- [ ] **AC-9** Godot --check-only 无解析错误
- [ ] **AC-10** Boss 系统兼容：F2"血量保留 15%" 基于战斗内 max_hp，未受公式改动影响

## 实现引用

- `src/core/hp_formula.gd` — 公式实现
- `src/core/class/class_names.gd` — `CLASS_BASE_HP` 字典 + `get_class_base_hp()`
- `src/core/unit.gd` — `Unit.get_max_hp()`
- `src/ui/management/character_management.gd` — 战外 HP 显示
- `src/ui/combat/battle_arena.gd:_create_unit_from_definition` — 战内玩家 max_hp 注册流程
- `src/core/equipment/equipment_component.gd:get_stat_bonus("hp")` — 装备 HP 加成入口
