# 存档系统

> **Status**: Designed (pending review)
> **Author**: binlee1990 + agents
> **Last Updated**: 2026-04-22
> **Implements Pillar**: 系统互锁（持久化所有系统的状态，支撑跨会话连续性）
> **Technical Reference**: ADR-003 (Save System Architecture, Accepted)

## Overview

存档系统是 SRPG 所有游戏状态的持久化基础设施，负责将运行时状态序列化到磁盘并完整恢复。系统服务于两个目标：**进度保护**（玩家不会因关闭游戏而丢失进度）和**状态连续性**（多会话间保持一致的游戏世界状态）。

该系统对玩家大部分时间是隐形的。玩家通过"游戏进度不会丢失"这一安全感间接体验存档系统。仅在存档槽位选择界面（手动存档/读档）时，玩家与系统产生直接交互。

技术实现由 **ADR-003**（Accepted）定义：采用 Godot Resource 序列化 + JSON 双格式，8 个手动存档槽位 + 1 个自动存档专用槽，支持存档版本迁移。本 GDD 描述存档系统作为游戏子系统的**行为规则**——包括数据契约定义、存档/读档生命周期、自动存档触发策略、版本迁移规则，以及与 12 个下游系统的数据接口。

核心职责：
1. **数据捕获与恢复**：在存档时刻采集所有系统的可序列化状态，在读档时刻完整恢复
2. **槽位管理**：维护 8 个手动槽位 + 1 个自动存档槽，支持查询、删除、覆盖
3. **自动存档**：在关键游戏节点（战斗结束、章节完成、重大选择）自动触发存档
4. **版本迁移**：当存档版本低于当前版本时，执行增量迁移保证向后兼容
5. **数据完整性保护**：写前备份、加载前校验、损坏时回退

## Player Fantasy

存档系统的成功表现为玩家**从不担心进度丢失**。

- **进度安全感幻想**：无论何时关闭游戏，玩家确信下次启动时能从上次离开的地方继续。这种感觉不是通过频繁的"存档成功"提示实现，而是通过可靠的自动存档让玩家**从未意识到需要手动存档**。
- **多周目传承幻想**：一周目的成就点数、解锁的职业、收集的物品在二周目中仍然存在。存档系统承载的不是"一局游戏的数据"，而是**整个游戏生涯的积累**。
- **实验自由幻想**：8 个存档槽位让玩家敢于尝试不同选择——在关键分支前存一个档，走一条路线，不满意就回退。槽位是"决策的安全网"。

存档系统失败时，玩家会感到焦虑（"我刚才的进度存了吗？"）或愤怒（"存档损坏了！"）——负面情绪远强于正面。因此存档系统的设计目标是**零可见故障**，而非创造积极体验。

## Detailed Design

### Core Rules

**规则 1 — 存档数据契约**

每个系统的可序列化数据必须通过 `SaveData` Resource 中的对应字段持久化。数据契约定义如下：

| 数据域 | SaveData 字段 | 类型 | 来源系统 | 内容 |
|--------|---------------|------|----------|------|
| 队伍 | `party_units` | `Array[UnitSaveData]` | 角色管理 | 所有角色属性/等级/技能/装备 |
| 背包 | `inventory_items` | `Array[ItemSaveData]` | 资源经济 | 所有物品/材料/金币 |
| 剧情 | `story_progress` | `Dictionary` | 叙事系统 | 章节/事件/信念值/选择记录 |
| 成就 | `achievement_points` | `int` | 多周目 | 累积成就点数 |
| 多周目 | `new_game_plus` | `Dictionary` | 多周目 | 已解锁开关/周目计数 |
| 基地 | `base` | `BaseSaveData` | 基地系统 | 基地等级/解锁区域 |
| 羁绊 | `bond_levels` (story_progress 内) | `Dictionary` | 羁绊系统 | 角色对→羁绊等级映射 |
| 设置 | `settings` | `Dictionary` | UI 系统 | 音量/亮度/控制方案 |

**新增系统的数据注册规则**：任何需要持久化的新系统必须在 `SaveData` 中添加对应的 `@export` 字段，并在 `_create_save_data()` 和 `_apply_save_data()` 中实现捕获/恢复逻辑。不能使用全局单例直接写入存档文件——所有数据流经 SaveManager 统一管理。

**规则 2 — 存档生命周期**

```
玩家触发存档（手动/自动）
  ↓
1. 暂停游戏逻辑（防止存档期间状态变化）
  ↓
2. 调用各系统的 capture_state() → 收集数据到 SaveData
  ↓
3. 写前备份：将当前槽位的旧存档重命名为 .bak
  ↓
4. 序列化 SaveData → ResourceSaver.save() 写入 .tres
  ↓
5. 验证：立即读回写入的文件，与内存数据对比
  ↓
6. 验证通过 → 删除 .bak，emit game_saved 信号
   验证失败 → 恢复 .bak，push_error，返回 false
  ↓
7. 恢复游戏逻辑
```

**规则 3 — 读档生命周期**

```
玩家触发读档（手动/启动时）
  ↓
1. 加载 .tres 文件 → ResourceLoader
  ↓
2. 版本检查：save_data.version vs CURRENT_VERSION
   版本匹配 → 继续
   版本较低 → 执行版本迁移（规则 5）
   版本较高 → 拒绝加载，提示"存档来自更新版本"
  ↓
3. 数据校验：检查必需字段存在性和类型正确性
  ↓
4. 场景重置：加载目标场景（ADR-002 场景管理）
  ↓
5. 恢复状态：按依赖顺序调用各系统的 restore_state(data)
   恢复顺序：设置 → 属性 → 职业技能 → 装备 → 背包 → 羁绊 → 剧情 → 基地
  ↓
6. emit game_loaded 信号
```

**规则 4 — 自动存档触发策略**

自动存档使用专用槽位 0（与 8 个手动槽位分离）。触发条件：

| 触发事件 | 信号 | 触发时机 |
|----------|------|----------|
| 战斗结束 | `GameEvents.combat_ended` | 战斗结算完成后 |
| 章节完成 | `GameEvents.chapter_completed` | 章节过渡动画前 |
| 重大选择 | `GameEvents.major_choice_made` | 玩家确认选择后 |
| 基地升级 | `GameEvents.base_upgraded` | 升级动画完成后 |
| 场景切换 | `GameEvents.scene_changed` | 新场景加载完成后（非战斗场景） |
| 手动存档同步 | `SaveManager.save_game(0)` | 手动存档时同步更新槽位 0 |

**防抖规则**：同一触发事件在 30 秒内不重复存档。自动存档不阻塞游戏——使用后台线程执行（Godot 4.6 `Thread` + `ResourceSaver`）。

**规则 5 — 版本迁移**

存档版本号（`SaveData.version`）是单调递增的整数。每次新增持久化字段或修改数据格式时递增版本号。

```
迁移链：version N → version N+1 → ... → CURRENT_VERSION
```

迁移规则：
- 迁移函数 `migrate_N_to_Nplus1(data)` 只负责一步升级
- 新增字段使用默认值填充
- 删除字段静默忽略（不报错）
- 修改字段执行显式转换（如 int → float）
- 迁移后更新 `data.version` 到目标版本

**规则 6 — 数据完整性保护**

| 保护措施 | 实现方式 | 触发条件 |
|----------|----------|----------|
| 写前备份 | 旧存档重命名为 `.bak` | 每次覆盖存档前 |
| 写后验证 | 读回文件并与内存数据对比 | 每次存档后 |
| 加载校验 | 检查必需字段和类型 | 每次读档前 |
| 损坏恢复 | 从 `.bak` 恢复 | 加载校验失败时 |
| 最终兜底 | 提示用户存档损坏，建议删除 | `.bak` 也损坏时 |

### States and Transitions

**存档管理器状态机**：

```
Idle ──[save_game()]──> Saving ──[success]──> Idle
  │                        │
  └──[load_game()]──> Loading ──[success]──> Scene Transition
                           │
                     [fail]──> Idle (with error)
```

| 状态 | 行为 | 允许的操作 |
|------|------|------------|
| **Idle** | 等待触发 | save_game, load_game, delete_save, has_save |
| **Saving** | 执行存档流程（规则 2） | 无（排队等待） |
| **Loading** | 执行读档流程（规则 3） | 无（排队等待） |
| **Scene Transition** | 等待场景加载完成 | 无 |

**槽位状态**：

| 状态 | 含义 |
|------|------|
| **Empty** | 无存档文件 |
| **Occupied** | 有有效存档 |
| **Corrupted** | 存档文件存在但校验失败 |

### Interactions with Other Systems

| 下游系统 | 提供的接口 | 数据方向 | 说明 |
|----------|------------|----------|------|
| **属性系统** | `capture_attributes() / restore_attributes(data)` | 双向 | 保存/恢复五维属性、潜质、壁障状态 |
| **职业系统** | `capture_class() / restore_class(data)` | 双向 | 保存/恢复职业、职业经验 |
| **资源经济** | `capture_inventory() / restore_inventory(data)` | 双向 | 保存/恢复背包、金币、材料 |
| **战术机制** | — | — | 无持久化需求（战斗状态瞬态） |
| **AI 系统** | — | — | 无持久化需求 |
| **技能系统** | `capture_skills() / restore_skills(data)` | 双向 | 保存/恢复技能熟练度、位阶、特性选择 |
| **装备系统** | `capture_equipment() / restore_equipment(data)` | 双向 | 保存/恢复装备实例（含词缀）、强化等级 |
| **回合制模式** | — | — | 无持久化需求（战斗内瞬态） |
| **羁绊系统** | `capture_bonds() / restore_bonds(data)` | 双向 | 保存/恢复羁绊等级、类型 |
| **战斗结算** | — | 存档←结算 | 战斗结束触发自动存档 |
| **角色管理** | `capture_party() / restore_party(data)` | 双向 | 保存/恢复队伍组成、退场状态 |
| **视角地图** | — | — | 无持久化需求（地图状态由关卡设计定义） |
| **UI 系统** | `capture_settings() / restore_settings(data)` | 双向 | 保存/恢复游戏设置 |
| **场景管理** | `GameEvents.scene_changed` | 场景→存档 | 场景切换完成后触发自动存档 |

**恢复顺序约束**（按依赖关系）：
1. 游戏设置（无依赖）
2. 属性数据（无依赖）
3. 职业数据（依赖属性门槛）
4. 技能数据（依赖职业）
5. 装备数据（依赖属性+资源）
6. 背包数据（独立，但装备已从背包中取出）
7. 羁绊数据（依赖角色存在）
8. 剧情数据（依赖羁绊和选择记录）
9. 基地数据（依赖资源解锁）

## Formulas

**F1 — 存档大小估算**

```
estimated_save_size = sum(field_sizes) + overhead
```

```
overhead = 512 bytes (Resource 元数据)
field_sizes = party_units_count × unit_record_size + inventory_count × item_record_size + story_dict_size + settings_dict_size
```

| 变量 | 符号 | 类型 | 范围 | 说明 |
|------|------|------|------|------|
| party_units_count | N_party | int | 1 ~ 30 | 队伍角色数 |
| unit_record_size | S_unit | int | ~200 bytes | 单个角色数据（属性+技能+装备） |
| inventory_count | N_items | int | 0 ~ 500 | 背包物品数 |
| item_record_size | S_item | int | ~50 bytes | 单个物品数据（ID+数量+词缀） |
| story_dict_size | S_story | int | ~2KB | 剧情进度字典 |
| settings_dict_size | S_settings | int | ~1KB | 游戏设置字典 |

**输出范围**：正常游戏 ~50KB ~ 200KB。极端情况（500 物品 + 30 角色）~350KB。均远低于 1MB 预算。

**F2 — 自动存档防抖**

```
actual_save_time = max(trigger_time, last_save_time + debounce_interval)
```

| 变量 | 符号 | 类型 | 范围 | 说明 |
|------|------|------|------|------|
| trigger_time | T_trigger | float | — | 自动存档触发时刻 |
| last_save_time | T_last | float | — | 上次存档完成时刻 |
| debounce_interval | D_auto | float | 30s | 最小存档间隔 |

**输出范围**：如果 `T_trigger - T_last < 30s`，则跳过本次存档。

**F3 — 游戏时间累计**

```
cumulative_playtime = saved_playtime + (current_time - session_start_time)
```

```
playtime_display = "%d小时%d分" % [cumulative_playtime / 3600, (cumulative_playtime % 3600) / 60]
```

| 变量 | 符号 | 类型 | 范围 | 说明 |
|------|------|------|------|------|
| saved_playtime | T_saved | int | 0 ~ INT_MAX | 存档中已累计的秒数 |
| session_start_time | T_start | float | — | 本次会话启动时刻 |
| current_time | T_now | float | — | 当前时刻 |

**精度**：秒级。`session_start_time` 在场景首次 `_ready` 时记录，排除加载时间。

**F4 — 版本兼容性检查**

```
compatibility = CASE
    save_version == CURRENT_VERSION → "compatible"
    save_version < CURRENT_VERSION  → "migration_required"
    save_version > CURRENT_VERSION  → "incompatible"
END
```

| 变量 | 符号 | 类型 | 范围 | 说明 |
|------|------|------|------|------|
| save_version | V_save | int | 1 ~ N | 存档中的版本号 |
| CURRENT_VERSION | V_current | int | 单调递增 | 当前游戏支持的存档版本 |

**F5 — 存档写入性能预算**

```
write_time = serialization_time + io_time + verification_time
```

```
serialization_time ≤ 200ms
io_time ≤ 100ms（SSD）/ 300ms（HDD）
verification_time = io_time（需读回）
total ≤ 500ms（SSD）/ 800ms（HDD）
```

| 阶段 | 预算 | 说明 |
|------|------|------|
| 序列化 | 200ms | SaveData → Resource |
| 磁盘写入 | 100-300ms | 取决于存储介质 |
| 验证读回 | 100-300ms | 同上 |
| **总计** | **≤500ms (SSD) / ≤800ms (HDD)** | ADR-003 预算 <1s |

## Edge Cases

- **If 存档期间游戏崩溃**（进程在步骤 4 写入中终止）：`.bak` 文件仍存在于磁盘。下次启动时 SaveManager 检测到 `.bak`，恢复备份并通知用户"上次存档可能不完整，已恢复备份"。原因是写前备份保证至少有上一个有效版本可回退。

- **If 读档时发现存档版本高于当前游戏版本**（如旧版游戏读取新版存档）：拒绝加载，弹出提示"此存档需要游戏版本 X.X 或更高"。不尝试降级迁移（降级可能导致数据丢失）。原因是向前兼容不可靠，不如提示玩家更新游戏。

- **If 槽位 0（自动存档）和手动槽位指向同一时刻**：自动存档使用独立槽位 0，不影响手动槽位 1-8。手动存档时同步更新槽位 0，确保"继续游戏"始终指向最新进度。

- **If 玩家在存档进行中触发读档**：SaveManager 状态机在 Saving 状态下拒绝 load_game() 调用。读档请求被排队，存档完成后自动执行。原因是存档和读档不能并发操作同一文件。

- **If 存档文件被外部修改（作弊/损坏）**：加载校验检查必需字段存在性和类型正确性。If 校验失败且 `.bak` 可用，恢复备份。If `.bak` 也损坏，标记槽位为 Corrupted，UI 显示"存档损坏"并建议删除。不尝试修复损坏数据。

- **If 游戏时间溢出**（累积游戏时间超过 INT_MAX 秒 ≈ 68 年）：使用 64 位整数（Godot 4 的 int 为 64 位）。在实际游戏场景中不会溢出。

- **If 新系统添加的持久化字段在旧存档中不存在**：版本迁移函数 `migrate_N_to_Nplus1()` 为新字段填充默认值。如果存档未迁移（版本号匹配但缺字段），`Dictionary.get()` 和 `@export` 默认值机制保证不会崩溃。

- **If 存档目录不存在**（首次启动）：SaveManager._ready() 检查 `user://saves/` 目录，If 不存在则创建。Godot 的 `DirAccess.make_dir_recursive_absolute()` 可安全处理已存在目录。

- **If 玩家删除所有存档文件**（通过文件系统手动删除）：SaveManager 检测所有槽位为 Empty，返回主菜单"新游戏"状态。不崩溃，不报错。

## Dependencies

### 上游依赖（本系统依赖）

| 依赖 | 类型 | 说明 |
|------|------|------|
| **ADR-001 事件架构** | 硬依赖 | `GameEvents.game_saved` / `game_loaded` 信号 |
| **ADR-002 场景管理** | 硬依赖 | 场景切换后触发自动存档；读档时加载目标场景 |
| **Godot ResourceSaver/ResourceLoader** | 硬依赖 | 存档文件的序列化/反序列化 |

### 下游依赖（其他系统依赖本系统）

12 个系统通过 `capture_*() / restore_*()` 接口与存档系统交互（详见 Section C Interactions 表）。所有需要持久化的系统均为硬依赖。

### 双向一致性要求
- 每个下游系统的 GDD 中必须在 Dependencies 节注明"数据持久化通过存档系统 SaveManager 实现"
- 下游系统不得自行实现文件 I/O 持久化——所有持久化流经 SaveManager

## Tuning Knobs

| Knob ID | 名称 | 类型 | 默认值 | 安全范围 | 极端行为 | 影响 |
|---------|------|------|--------|----------|----------|------|
| `TK-SAVE-01` | 手动存档槽位数 | int | 8 | 3 ~ 16 | 过少=玩家无法分支存档；过多=管理负担 | 槽位管理 |
| `TK-SAVE-02` | 自动存档防抖间隔 | float | 30s | 10 ~ 120s | 过短=频繁IO；过长=进度丢失风险 | 自动存档 |
| `TK-SAVE-03` | 写入超时阈值 | int | 2000ms | 500 ~ 5000ms | 过短=正常存档被取消；过长=卡顿久 | 存档流程 |
| `TK-SAVE-04` | 存档大小上限 | int | 2MB | 512KB ~ 5MB | 过小=未来系统无法存档；过大=占用过多磁盘 | 数据完整性 |
| `TK-SAVE-05` | 最大备份保留数 | int | 1 | 0 ~ 3 | 0=无备份保护；3=磁盘占用增加 | 数据完整性 |

## Visual/Audio Requirements

本系统无直接视觉/音频需求。存档成功/失败的 UI 反馈由 UI 系统负责。

## UI Requirements

存档系统需要以下 UI 界面（由 UI 系统实现，此处定义行为需求）：

- **存档槽位列表**：显示 8+1 个槽位，每个槽位显示：槽位编号、存档时间戳、游戏时间、当前章节名称、空/CORRUPTED 状态
- **存档操作**：手动存档时选择空槽位或确认覆盖已有存档
- **读档操作**：从非空槽位加载，Corrupted 槽位显示警告
- **自动存档提示**：自动存档完成时显示短暂提示（2 秒后淡出），不阻塞操作

## Acceptance Criteria

**GIVEN** 玩家在游戏中处于任意状态，**WHEN** 触发手动存档到槽位 N（1-8），**THEN** 存档在 500ms 内完成（SSD），旧存档被备份为 `.bak`，新存档通过验证，`game_saved` 信号发出。

**GIVEN** 槽位 N 有有效存档，**WHEN** 触发读档，**THEN** 存档版本兼容性检查通过，所有系统按依赖顺序恢复状态，`game_loaded` 信号发出，游戏进入存档时的场景和状态。

**GIVEN** 战斗结束，**WHEN** `combat_ended` 信号触发且距上次自动存档超过 30 秒，**THEN** 自动存档写入槽位 0，不阻塞游戏流程。

**GIVEN** 存档版本 V=1，当前版本 V=3，**WHEN** 加载该存档，**THEN** 按序执行 migrate_1_to_2 → migrate_2_to_3，所有新字段填充默认值，无数据丢失，最终版本号为 3。

**GIVEN** 存档文件被外部损坏，**WHEN** 尝试加载，**THEN** 校验失败，尝试从 `.bak` 恢复。If `.bak` 可用则恢复成功；If 不可用则标记槽位为 Corrupted。

**GIVEN** SaveManager 处于 Saving 状态，**WHEN** 玩家触发读档，**THEN** 读档请求排队，存档完成后自动执行，不产生并发冲突。

**GIVEN** 首次启动游戏，**WHEN** `user://saves/` 目录不存在，**THEN** SaveManager 自动创建目录，不报错。

**GIVEN** 玩家读取版本号高于当前版本的存档，**WHEN** 版本检查，**THEN** 拒绝加载并提示"此存档需要更新版本"，不尝试降级迁移。

**GIVEN** 12 个下游系统各有 capture/restore 接口，**WHEN** 执行完整存档+读档循环，**THEN** 所有系统状态与存档前完全一致（属性值、装备、背包数量、剧情进度、羁绊等级、成就点数逐一验证）。

## Open Questions

- **OQ-1**：Steam Cloud 同步是否纳入 MVP？ADR-003 标注"MVP 不考虑"，但多设备需求可能在正式发布前需要。影响存档文件格式选择。
- **OQ-2**：多周目数据是否与单周目存档合并存储？当前设计将 `new_game_plus` 作为 SaveData 的顶级字段，但"周目结算后重置单周目数据但保留成就点数"的具体流程需与多周目系统 GDD 对齐。
- **OQ-3**：存档加密方案（当前为 XOR）是否需要升级为 AES？影响防作弊策略和性能。XOR 在 Solo 单机游戏中可能足够。
