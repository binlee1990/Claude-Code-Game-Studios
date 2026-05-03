# 数据配置系统 (Data Config System)

> **Status**: Approved
> **Author**: binlee1990 + agents
> **Last Updated**: 2026-05-04
> **Implements Pillar**: 4.10 数据驱动与可扩展

## Summary

数据配置系统是游戏的统一数据加载、缓存和查询服务层。所有游戏内容——角色、怪物、装备、技能、掉落表、区域、建筑、配方、公式——均通过配置表定义，由本系统加载并提供查询接口。上游系统只需"问"数据配置系统，无需知道数据如何存储和解析。

> **Quick reference** — Layer: `Core Data` · Priority: `MVP` · Key deps: `大数值系统`

## Overview

数据配置系统是游戏的统一数据加载、缓存和查询服务。所有游戏内容——角色、怪物、装备、技能、掉落表、区域、建筑、配方、公式——均通过外部配置文件定义，由本系统在启动时加载到内存，并提供 `table_name + record_id` 的查询接口。

核心定位是所有系统的"只读数据字典"。上游系统不直接解析 JSON / Resource 文件——它们通过 `DataConfig.get(table, id)` 或 `DataConfig.query(table, filter)` 获取数据。数据配置系统负责：文件加载、格式校验、BigNumber 反序列化、内存缓存和开发模式热重载。

MVP 仅支持 JSON 格式。每个 JSON 文件对应一张逻辑表（如 `enemies.json`、`items.json`、`formulas.json`）。表内记录以字符串 ID 为键，值为 Dictionary。不支持 CSV、Godot Resource、外部数据库——这些留给 Post-MVP。

不在 MVP 范围内：数据编辑器 UI、内容包 / DLC / Mod 系统、数据校验系统、运行时写入数据（配置表是只读的；玩家运行时状态由存档系统管理）。

## Player Fantasy

数据配置系统是玩家永远不会直接看到的"天道玉简"——修仙世界中记载万物本源的典籍。当玩家第一次遇到"碧眼蛟龙"时看到它的名字、属性、掉落表；当玩家升级解锁新区域时发现敌人变强、掉落变好；当版本更新加入新职业、新装备——这一切的背后都是数据配置系统在默默加载和分发数据。

锚定时刻：玩家上线后发现游戏更新了——新增了"炼器师"职业、5 件新装备、2 个新区域。不需要重新下载整个游戏，不需要等策划手写代码——设计师只改了几个 JSON 文件，数据配置系统加载后，所有系统自动读到了新数据。玩家感受到的是"这个世界在持续生长"。

支柱对应：4.10 数据驱动与可扩展——所有内容配置化是游戏长期可扩展的基础。新区域、新职业、新机制不需要改代码，添加新 JSON 记录即生效。这也是 Mod 支持和 DLC 扩展的技术前提。

## Detailed Design

### Core Rules

1. **架构形态**：`DataConfig` 作为 `RefCounted` 工具类，由 Autoload 单例持有实例。不继承 Node，不进入场景树——它是纯数据服务，生命周期由持有者管理。

2. **文件组织**：数据文件存放于 `assets/data/` 目录。每个 `.json` 文件对应一张逻辑表，文件名（去 `.json` 后缀）即表名。约定表名使用 `snake_case` 复数形式（如 `enemies`、`items`、`formulas`）。

3. **JSON 格式**：每个 JSON 文件顶层为 Object，键为记录 ID（字符串），值为记录内容（Dictionary）。
   ```json
   {
     "slime_green": {
       "name": "碧眼史莱姆",
       "level": 1,
       "hp": "100",
       "atk": "10",
       "def": "5",
       "zone": "forest_01",
       "loot_table": "slime_drops",
       "tags": ["beast", "slime"]
     }
   }
   ```
   - 记录 ID 全局唯一（表内），推荐 `snake_case` 格式
   - 字段值支持 JSON 原生类型：`string`、`number`（int/float）、`boolean`、`null`、`array`、`object`
   - 普通数值用 JSON number；BigNumber 范围的值用字符串存储（如 `"1.5e25"`）

4. **BigNumber 处理约定**：数据配置系统不执行 BigNumber 反序列化。它返回原始 Dictionary，消费方根据自身 schema 决定哪些字段需要 `BigNumber.from_string()` 转换。理由：
   - 数据配置系统不需要知道每张表的 schema，保持职责单一
   - 避免在数据加载层引入对所有消费系统的类型感知
   - 消费方最清楚自己的数据格式

5. **查询 API**：
   - `get(table: String, id: String) -> Dictionary` — 获取单条记录，不存在返回 `null`
   - `get_all(table: String) -> Dictionary` — 获取整张表的 `{id: record}` 字典，表不存在返回空字典
   - `query(table: String, filter: Callable) -> Array[Dictionary]` — 过滤返回匹配记录数组
   - `has_table(table: String) -> bool` — 表是否存在
   - `has_record(table: String, id: String) -> bool` — 记录是否存在
   - `get_table_names() -> Array[String]` — 返回所有已加载表名
   - `get_field(table: String, id: String, field: String) -> Variant` — 获取单条记录的单个字段，不存在返回 `null`
   - `is_loaded() -> bool` — 返回 `load_all()` 是否已成功完成至少一次。初始值 `false`，`load_all()` 完成（含部分失败但流程结束）后置为 `true`。供消费方在初始化期检查（如调试控制台 `config show` 命令在加载未完成时拒绝执行而非崩溃）。

6. **加载流程**：
   - 启动时：扫描 `assets/data/*.json`，逐文件 `FileAccess.open()` → `JSON.parse_string()` → 存入内存字典
   - 所有表并行加载（无依赖顺序），加载完成后打印摘要：表数量、每表记录数、总耗时
   - 加载失败的单张表跳过（记录错误日志），不影响其他表

7. **热重载**：
   - `reload_table(table: String)` — 重新加载指定表（开发/调试用）
   - `reload_all()` — 重新加载所有表
   - 热重载仅在开发模式下启用（`OS.is_debug_build()`）
   - 重载时替换内存中的旧数据；正在使用旧数据引用的系统不会自动更新——它们下次查询时获取新数据

8. **表间引用**：MVP 不做引用完整性检查。表间关系（如 `enemies.loot_table → loot_tables.id`）只是字符串值，运行时由消费方查找。引用完整性校验属于数据校验系统（game-concept #11）的职责。

9. **错误处理**：
   - 表不存在：`get()` 返回 `null`，打印警告 `"Table not found: {table}"`
   - 记录不存在：`get()` 返回 `null`，打印警告 `"Record not found: {table}/{id}"`
   - JSON 解析失败：该表标记为空（空字典），打印错误 `"Failed to parse table: {table}, error: {error}"`
   - 文件不存在：该表标记为空，打印警告 `"Data file not found: {path}"`
   - 字段不存在：`get_field()` 返回 `null`，不打印警告（字段不存在可能是正常情况）

10. **内存管理**：所有表数据常驻内存。MVP 数据量预估：~10 张表，每表 ~100-500 条记录，总内存 < 5 MB。Post-MVP 大数据量表可能需要懒加载或分页。

11. **数据目录可配置**：数据根目录路径作为构造参数传入（默认 `"res://assets/data/"`），支持测试时传入替代路径。

### States and Transitions

DataConfig 无状态机。它有两种运行时状态：

| 状态 | 说明 | 转换条件 |
|------|------|---------|
| **Unloaded** | 刚创建，内存无数据 | `load_all()` → Loaded |
| **Loaded** | 数据已加载到内存 | `reload_all()` → Loaded（重新加载） |

热重载不引入额外状态——它只是在 Loaded 状态下替换内存数据。

### Interactions with Other Systems

| 系统 | 方向 | 数据接口 | 说明 |
|------|------|---------|------|
| 大数值系统 | 上游依赖 | 消费方通过 `BigNumber.from_string()` 解析配置中的 BigNumber 字段 | DataConfig 不直接操作 BigNumber，仅存储字符串 |
| 公式引擎 | 下游消费 | `DataConfig.get("formulas", id)` 获取公式定义 | 公式 ID、表达式、变量列表从配置表加载 |
| 修正器/倍率引擎 | 下游消费 | `DataConfig.get("modifiers", id)` 获取修正器池定义 | 池名、修正器条目、叠乘规则从配置表加载 |
| 物品/材料系统 | 下游消费 | `DataConfig.get_all("items")` 获取物品定义 | 物品属性、品质、堆叠上限等从配置表加载 |
| 敌人数据库 | 下游消费 | `DataConfig.get_all("enemies")` 获取敌人定义 | 敌人属性、技能、掉落表引用从配置表加载 |
| 区域系统 | 下游消费 | `DataConfig.get_all("zones")` 获取区域定义 | 区域敌人列表、掉落倍率、解锁条件从配置表加载 |
| 调试控制台 | 下游消费 | `get_table_names()` + `get_all()` 列出和查看所有配置数据 | 支持运行时检查加载的数据 |
| 存档系统 | 协作 | 存档存储内容包版本号；加载存档时校验数据版本一致性 | 数据配置系统不参与存档读写，但提供版本查询 |

## Formulas

### 1. 内存占用估算

`memory = table_count × avg_record_size × avg_records_per_table`

| 变量 | 符号 | 类型 | 范围 | 说明 |
|------|------|------|------|------|
| table_count | t | int | [5, 30] | 表数量 |
| avg_record_size | s | int | [200, 500] bytes | 单条记录平均大小 |
| avg_records_per_table | n | int | [50, 500] | 每表平均记录数 |

MVP 预估：10 × 300 × 200 ≈ 600 KB。

### 2. 加载耗时估算

`load_time = file_count × (read_time + parse_time)`

| 变量 | 符号 | 类型 | 范围 | 说明 |
|------|------|------|------|------|
| file_count | f | int | [5, 30] | JSON 文件数量 |
| read_time | t_r | float | [0.1, 2.0] ms | 单文件磁盘读取耗时 |
| parse_time | t_p | float | [0.5, 5.0] ms | JSON.parse_string() 解析耗时 |

MVP 预估：10 × (1 + 2) = 30 ms，单帧内完成。

### 3. 查询耗时模型

`query_time = base_lookup + filter ? (n × comparison_cost) : 0`

| 变量 | 符号 | 类型 | 范围 | 说明 |
|------|------|------|------|------|
| base_lookup | t_b | float | [0.001, 0.01] ms | Dictionary 键查找 O(1) |
| n | n | int | [0, 500] | 过滤遍历记录数 |
| comparison_cost | t_c | float | [0.001, 0.005] ms | 单次过滤函数调用 |

- `get()` / `get_field()`：O(1) ~0.01 ms
- `query()`：O(n) ~0.5–2.5 ms（全表过滤 500 条）

## Edge Cases

- **If JSON 文件不存在**：该表标记为空字典，打印警告。不崩溃，其他表正常加载。
- **If JSON 文件为空（`{}`）**：正常加载为空表。`has_table()` 返回 `true`，`get_all()` 返回空字典。
- **If JSON 解析失败**（语法错误）：该表标记为空，打印错误含文件路径和解析错误信息。不阻塞其他表加载。
- **If 记录 ID 重复**（同一表内）：后者覆盖前者，打印警告 `"Duplicate ID '{id}' in table '{table}', using last definition"`。
- **If 记录内容为 null**（`"id": null`）：跳过该条记录，打印警告。
- **If 查询不存在的表**：`get()` 返回 `null`，`get_all()` 返回空字典，`has_table()` 返回 `false`，均打印警告。
- **If 查询不存在的记录**：`get()` 返回 `null`，`has_record()` 返回 `false`，打印警告。
- **If `get_field()` 的字段不存在**：返回 `null`，不打印警告（字段缺失可能是正常业务逻辑）。
- **If `query()` 的过滤 callable 无效或返回非 bool**：跳过该记录，打印警告，继续过滤剩余记录。GDScript 无 `try/catch`，过滤函数不得依赖异常流。
- **If 数据目录不存在**：`load_all()` 打印错误并返回，所有查询返回空结果。不阻止游戏启动。
- **If 在 `load_all()` 完成前调用查询 API**：`get` / `get_all` / `query` / `has_*` 返回各自的"空"结果（`null` / `{}` / `[]` / `false`），不崩溃但消费方无法区分"加载未完成"与"表/记录不存在"。消费方可先调用 `is_loaded()` 判别——返回 `false` 时应延迟操作或显示加载提示。
- **If JSON 文件编码不是 UTF-8**：可能产生乱码但不崩溃。打印警告建议检查文件编码。
- **If 热重载期间有并发查询**：Godot 单线程无并发问题。热重载是同步操作，替换后立即生效。
- **If JSON 值为超大数字**（超出 float 精确表示范围）：精度可能丢失。建议使用字符串格式（如 `"9.99e19"`），由消费方 BigNumber 解析。
- **If 热重载删除了某张表**：旧表数据从内存移除，后续查询该表返回 `null`。正在持有旧数据引用的系统仍可使用（Dictionary 引用不变），但下次查询将得到 `null`。

## Dependencies

| 系统 | 方向 | 依赖性质 | 数据接口 |
|------|------|---------|---------|
| 大数值系统 | 上游依赖 | 软依赖 | 消费方通过 `BigNumber.from_string()` 解析配置中的 BigNumber 字段；DataConfig 本身不导入 BigNumber |
| 公式引擎 | 下游消费 | 硬依赖 | 公式定义从 `formulas` 表加载 |
| 修正器/倍率引擎 | 下游消费 | 硬依赖 | 修正器池定义从 `modifiers` 表加载 |
| 物品/材料系统 | 下游消费 | 硬依赖 | 物品定义从 `items` 表加载 |
| 敌人数据库 | 下游消费 | 硬依赖 | 敌人定义从 `enemies` 表加载 |
| 区域系统 | 下游消费 | 硬依赖 | 区域定义从 `zones` 表加载 |
| 掉落系统 | 下游消费 | 硬依赖 | 掉落表从 `loot_tables` 表加载 |
| 存档系统 | 协作 | 软依赖 | 存档存储数据版本号；加载时校验一致性 |

上游依赖：仅大数值系统（软依赖）。DataConfig 是 Core Data 层基础设施。

双向一致性：大数值系统 GDD 的 Interactions 表已列出数据配置系统为下游消费方。公式引擎 GDD 声明对数据配置系统的硬依赖（Post-MVP），本 GDD 的 Interactions 表与之对应。

## Tuning Knobs

| 参数 | 当前值 | 安全范围 | 增大影响 | 减小影响 |
|------|--------|---------|---------|---------|
| `DATA_ROOT_DIR` | `"res://assets/data/"` | 任何 `res://` 路径 | 改变数据文件加载位置 | 同左 |
| `WARN_ON_MISSING_TABLE` | `true` | [true, false] | 缺失表打印警告，辅助调试 | 静默返回 null，减少日志噪音 |
| `WARN_ON_MISSING_RECORD` | `true` | [true, false] | 缺失记录打印警告 | 静默返回 null |
| `WARN_ON_DUPLICATE_ID` | `true` | [true, false] | 重复 ID 打印警告 | 静默使用后者覆盖 |
| `WARN_ON_PARSE_ERROR` | `true` | [true, false] | JSON 解析失败打印错误 | 静默跳过 |
| `HOT_RELOAD_ENABLED` | `false` | [true, false] | 启用热重载（仅开发模式） | 不支持运行时数据更新 |
| `MAX_FILE_SIZE_KB` | `1024` | [256, 10240] | 允许更大的单文件 | 限制单表数据量，防止加载过慢 |

上述参数为开发者/工程参数。设计师通过修改 JSON 配置文件内容来调参（改敌人血量、掉落权重等），而非修改数据配置系统本身的行为参数。

## Acceptance Criteria

- [ ] **GIVEN** `assets/data/enemies.json` 含 `{"slime": {"name": "史莱姆", "hp": "100"}}`，**WHEN** 执行 `DataConfig.get("enemies", "slime")`，**THEN** 返回 `{"name": "史莱姆", "hp": "100"}`
- [ ] **GIVEN** 表 `enemies` 已加载，**WHEN** 执行 `DataConfig.get("enemies", "nonexistent")`，**THEN** 返回 `null`，打印警告
- [ ] **GIVEN** 表 `nonexistent` 未加载，**WHEN** 执行 `DataConfig.get("nonexistent", "any")`，**THEN** 返回 `null`，打印警告
- [ ] **GIVEN** 表 `enemies` 含 3 条记录，**WHEN** 执行 `DataConfig.get_all("enemies")`，**THEN** 返回含 3 个键的 Dictionary
- [ ] **GIVEN** 表 `items` 含 10 条记录（5 个 level >= 5），**WHEN** 执行 `DataConfig.query("items", func(r): return r["level"] >= 5)`，**THEN** 返回 5 条记录的数组
- [ ] **GIVEN** `enemies.json` 文件不存在，**WHEN** 执行 `load_all()`，**THEN** `has_table("enemies")` 返回 `false`，其他表正常加载
- [ ] **GIVEN** 某表 JSON 语法错误，**WHEN** 执行 `load_all()`，**THEN** 该表为空，其他表正常加载，打印错误含文件路径
- [ ] **GIVEN** 表 `enemies` 含 `{"slime": {"name": "史莱姆", "hp": "100"}}`，**WHEN** 执行 `DataConfig.get_field("enemies", "slime", "hp")`，**THEN** 返回 `"100"`（字符串类型保持原样）
- [ ] **GIVEN** 记录中不含字段 `mp`，**WHEN** 执行 `DataConfig.get_field("enemies", "slime", "mp")`，**THEN** 返回 `null`，不打印警告
- [ ] **GIVEN** 同一表内有重复 ID `"slime"`，**WHEN** 加载完成，**THEN** 后者覆盖前者，打印警告
- [ ] **GIVEN** 10 张表各 200 条记录，**WHEN** 执行 `load_all()`，**THEN** 总耗时 < 100 ms，总内存 < 5 MB
- [ ] **GIVEN** `HOT_RELOAD_ENABLED = true`，**WHEN** 修改 `enemies.json` 后执行 `reload_table("enemies")`，**THEN** 后续 `get("enemies", ...)` 返回新数据
- [ ] **GIVEN** `HOT_RELOAD_ENABLED = false`，**WHEN** 执行 `reload_table("enemies")`，**THEN** 无操作
- [ ] **GIVEN** 数据目录路径为 `"res://test/fixtures/data/"`，**WHEN** 用该路径构造 DataConfig 并加载，**THEN** 从测试目录加载数据
- [ ] **GIVEN** JSON 含嵌套对象 `{"boss": {"stats": {"atk": "500"}}}`，**WHEN** 执行 `get("enemies", "boss")`，**THEN** 返回含嵌套 Dictionary 的记录
- [ ] **GIVEN** JSON 含数组字段 `{"slime": {"tags": ["beast", "slime"]}}`，**WHEN** 执行 `get("enemies", "slime")`，**THEN** `tags` 为 `["beast", "slime"]`（Array 类型）
- [ ] **GIVEN** DataConfig 新建未调用 `load_all()`，**WHEN** 调用 `is_loaded()`，**THEN** 返回 `false`；调用 `load_all()` 后再次调用 `is_loaded()`，**THEN** 返回 `true`（无论加载过程中是否有单表失败）

## Open Questions

| Question | Owner | Deadline | Resolution |
|----------|-------|----------|------------|
| Post-MVP 是否需要支持 CSV/表格导入，还是继续统一 JSON？ | 设计师 | Post-MVP 内容工具规划 | 保留：MVP 统一 JSON；表格导入属于内容管线扩展。 |
| 是否需要表级 schema 定义与自动校验系统？ | 设计师 + 开发者 | 数据校验系统 GDD | 保留：MVP 先用字段约定；独立数据校验系统再决定 schema 形态。 |
| BigNumber 字符串字段是否需要解析缓存以避免重复解析成本？ | 开发者 | 性能验证阶段 | 保留：先由消费方解析；只有 profile 显示热点后才缓存。 |
