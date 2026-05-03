# 存档系统 (Save System)

> **Status**: Draft
> **Author**: binlee1990 + agents
> **Last Updated**: 2026-05-03
> **Implements Pillar**: 4.1 数字增长就是快乐 · 4.2 放置不是无操作

## Summary

存档系统是游戏的持久化基础设施，采用注册表模式：各系统通过 `register_provider()` 注册 save/restore 回调，SaveManager 聚合所有数据写入单个 JSON 文件。支持自动保存、版本迁移、损坏恢复和离线时间戳持久化。MVP 为单存档位、无加密、无云存档。

> **Quick reference** — Layer: `Core Data` · Priority: `MVP` · Key deps: `数据配置系统, 时间管理器`

## Overview

存档系统是游戏的持久化基础设施。它采用注册表模式：各游戏系统通过 `register_provider()` 注册序列化/反序列化回调，SaveManager 不感知任何具体数据结构——只负责收集、组装、写入和读取一个 JSON 文件。每个系统拥有独立的存档数据段（namespace），读写互不干扰。

MVP 采用单存档位（autosave）+ 单 JSON 文件。存档文件存放于 `user://save/`，包含所有注册系统的序列化数据、全局元数据（版本号、时间戳）和迁移历史。

核心能力：(1) 注册表式序列化——系统自管数据的存/取 (2) 自动保存——定时、事件触发、退出时 (3) 版本迁移——存档版本号与迁移脚本链 (4) 损坏恢复——备份文件 + JSON 校验 (5) 离线时间戳持久化——与时间管理器协作。

不在 MVP 范围内：多存档位、云存档、加密/压缩、存档截图、存档比较工具、跨平台存档同步。

## Player Fantasy

存档系统是玩家的"玉简"——修仙世界中记载修行历程的器物。玩家不会直接"看到"存档系统，但能感受到它的存在：每次打开游戏，世界精准地从上次离开的地方继续，灵气数字、修炼进度、战斗队伍——一切都像从未中断过。

**锚定时刻**：玩家关闭游戏去睡觉，八小时后重新打开——离线收益精确结算、修炼进度如实增长、背包里的稀有装备安然无恙。玩家的感受不是"游戏帮我记住了"，而是"这个世界从未停止运转，我的每一步都被天地玉简忠实记录"。

支柱对应：
- **4.1 数字增长就是快乐**：存档系统确保每一次数字增长都被持久化，不会因关闭游戏而丢失。玩家的积累是永久的。
- **4.2 放置不是无操作**：存档系统记录退出时间戳，使离线收益计算成为可能。没有可靠的存档，就没有可靠的离线收益。

## Detailed Design

### Core Rules

1. **架构形态**：`SaveManager` 作为 Autoload 单例（`/root/SaveManager`），全局唯一。提供统一的注册、保存、加载、迁移和恢复接口。

2. **注册表模式**：
   - `register_provider(namespace: String, save_fn: Callable, restore_fn: Callable) -> void`
   - 每个系统用唯一 namespace 注册一对回调：
     - `save_fn() -> Dictionary`：系统返回自己的序列化数据
     - `restore_fn(data: Dictionary) -> void`：系统接收数据并恢复状态
   - namespace 推荐 snake_case（如 `resource_system`、`time_manager`）
   - 重复注册同一 namespace 覆盖旧的，打印警告
   - 保存/加载顺序按注册顺序执行

3. **存档文件结构**（单 JSON）：
   ```json
   {
     "meta": {
       "version": 1,
       "saved_at": 1714713600.0,
       "data_version": "0.0.3",
       "play_time_seconds": 3600.0
     },
     "systems": {
       "time_manager": { "exit_real_timestamp": 1714713600.0, "game_ref": 1000.0, ... },
       "resource_system": { "lingqi": "1.5e25", ... },
       ...
     }
   }
   ```

4. **元数据字段**：
   - `version`：存档格式版本号（int），用于迁移
   - `saved_at`：保存时的 Unix 时间戳
   - `data_version`：游戏数据版本（对应 git tag 或 build 号）
   - `play_time_seconds`：累计游玩时长

5. **保存流程（原子写入）**：
   - (a) 调用所有已注册 provider 的 `save_fn()`，收集返回的 Dictionary
   - (b) 组装完整存档对象（meta + systems）
   - (c) 序列化为 JSON 字符串
   - (d) 写入 `user://save/save.json.tmp`（临时文件）
   - (e) `FileAccess.flush()` 确保落盘
   - (f) 将旧 `save.json` 重命名为 `save.json.bak`（备份）
   - (g) 将 `save.json.tmp` 重命名为 `save.json`（原子替换）
   - 任何步骤失败，打印错误，不损坏已有存档

6. **加载流程**：
   - (a) 尝试读取 `user://save/save.json`
   - (b) JSON 解析，校验顶层结构（必须有 `meta` 和 `systems`）
   - (c) 检查 `meta.version`，执行迁移链（如需要）
   - (d) 遍历 `systems`，按 namespace 分发给对应 provider 的 `restore_fn()`
   - (e) 未注册 provider 的 namespace 数据保留但不处理（向前兼容）
   - (f) 已注册但存档中无对应 namespace 的 provider，收到空 Dictionary
   - (g) 发布 `save.loaded` 事件

7. **自动保存触发条件**：
   - **退出时**：`NOTIFICATION_WM_CLOSE_REQUEST` → 强制保存
   - **定时**：可配置间隔（默认 60 秒），由内部 Timer 驱动
   - **手动**：`SaveManager.save_game()` 随时可调用

8. **版本迁移**：
   - `register_migration(from_version: int, migration_fn: Callable) -> void`
   - `migration_fn(data: Dictionary) -> Dictionary`：接收存档数据，返回转换后的数据
   - 迁移链按版本号顺序执行：v1→v2→v3→...
   - 迁移完成后更新 `meta.version` 为当前版本
   - 迁移失败不覆盖原文件，打印错误

9. **损坏恢复**：
   - `save.json` 解析失败 → 尝试加载 `save.json.bak`
   - `save.json.bak` 也失败 → 创建新存档（新游戏），打印警告
   - 恢复时发布 `save.corrupted` 事件，payload 含 `recovered_from_backup: bool`

10. **错误隔离**：
    - 单个 provider 的 `save_fn()` 抛异常 → 该系统存档段记为 `null`，打印警告，继续其余系统
    - 单个 provider 的 `restore_fn()` 抛异常 → 跳过该系统恢复，打印警告，继续其余系统
    - 不因单个系统失败导致整体保存/加载中止

11. **数据目录可配置**：存档根目录路径作为参数（默认 `"user://save/"`），支持测试时传入替代路径。

### States and Transitions

| 状态 | 描述 | 转换条件 |
|------|------|---------|
| **Idle** | 空闲，等待保存/加载请求 | `save_game()` → Saving |
| **Saving** | 正在收集数据并写入文件 | 写入完成 → Idle；写入失败 → Error |
| **Loading** | 正在读取文件并恢复状态 | 恢复完成 → Idle；加载失败 → Error |
| **Error** | 上次操作失败，等待处理 | `save_game()` / `load_game()` → Saving / Loading |

### Interactions with Other Systems

| 系统 | 方向 | 数据接口 | 说明 |
|------|------|---------|------|
| 时间管理器 | 双向 | provider namespace: `time_manager` | TimeManager 注册 provider 保存/恢复时间快照和 exit_timestamp；SaveManager 在保存前通知 TimeManager 刷新 exit_timestamp |
| 数据配置系统 | 协作 | SaveManager 读取 `meta.data_version` | 加载存档时校验数据版本一致性，不匹配时打印警告 |
| EventBus | 上游依赖 | 发布 `save.loaded`, `save.saved`, `save.corrupted` 事件 | 存档状态变更通知 |
| 资源系统 | 下游注册 | provider namespace: `resource_system` | 注册 provider 保存/恢复资源数据 |
| 属性系统 | 下游注册 | provider namespace: `attribute_system` | 注册 provider 保存/恢复属性数据 |
| 物品/材料系统 | 下游注册 | provider namespace: `inventory_system` | 注册 provider 保存/恢复背包数据 |
| 等级系统 | 下游注册 | provider namespace: `level_system` | 注册 provider 保存/恢复等级数据 |
| 区域系统 | 下游注册 | provider namespace: `zone_system` | 注册 provider 保存/恢复当前区域和进度 |
| 离线模拟内核 | 下游消费 | 监听 `save.loaded` 事件 | 加载完成后触发离线结算流程 |

## Formulas

### 1. 存档文件大小估算

`file_size = meta_size + Σ(provider_data_size_i)`

| 变量 | 符号 | 类型 | 范围 | 描述 |
|------|------|------|------|------|
| meta_size | S_meta | int | [200, 500] bytes | 元数据固定开销 |
| provider_data_size_i | S_i | int | [100, 5000] bytes | 第 i 个系统序列化数据大小 |
| provider_count | N | int | [5, 30] | 注册的 provider 数量 |

MVP 预估：300 + 15 × 800 ≈ 12.3 KB

### 2. 保存耗时估算

`save_time = collect_time + serialize_time + write_time`

| 变量 | 符号 | 类型 | 范围 | 描述 |
|------|------|------|------|------|
| collect_time | t_col | float | [0.1, 2.0] ms | 调用所有 provider save_fn 的总耗时 |
| serialize_time | t_ser | float | [0.5, 3.0] ms | JSON.stringify() 耗时 |
| write_time | t_w | float | [0.5, 5.0] ms | 文件写入 + flush + rename 耗时 |

MVP 预估：1.0 + 1.0 + 2.0 = 4.0 ms

### 3. 加载耗时估算

`load_time = read_time + parse_time + migrate_time + restore_time`

| 变量 | 符号 | 类型 | 范围 | 描述 |
|------|------|------|------|------|
| read_time | t_r | float | [0.1, 2.0] ms | 文件读取耗时 |
| parse_time | t_p | float | [0.5, 3.0] ms | JSON.parse_string() 耗时 |
| migrate_time | t_m | float | [0.0, 10.0] ms | 迁移链执行耗时（无迁移时为 0） |
| restore_time | t_rest | float | [0.5, 5.0] ms | 调用所有 provider restore_fn 的总耗时 |

MVP 预估（无迁移）：0.5 + 1.0 + 0 + 2.0 = 3.5 ms

### 4. 自动保存帧影响

`autosave_frame_impact = save_time / autosave_interval_seconds`

| 变量 | 符号 | 类型 | 范围 | 描述 |
|------|------|------|------|------|
| save_time | t_save | float | [2.0, 10.0] ms | 单次保存耗时 |
| autosave_interval_seconds | T_auto | float | [30, 300] s | 自动保存间隔 |

MVP 预估：4.0 ms / 60 s ≈ 0.067 ms/s，帧影响可忽略

## Edge Cases

- **If `save.json` 不存在**（首次启动）：跳过加载，所有 provider 不被调用，游戏以默认状态开始。不视为错误。
- **If `save.json` 为空文件**：JSON 解析失败，触发损坏恢复流程 → 尝试 backup → 新游戏。
- **If `save.json` JSON 语法错误**：解析失败，触发损坏恢复流程。
- **If `save.json` 缺少 `meta` 或 `systems` 顶层键**：视为格式错误，触发损坏恢复流程。
- **If `save.json` 和 `save.json.bak` 都损坏**：创建新游戏，发布 `save.corrupted` 事件（`recovered_from_backup: false`），打印警告。不阻塞游戏启动。
- **If 某 provider 的 `save_fn()` 抛异常**：该 namespace 数据记为 `null`，打印警告含 namespace 和异常信息，继续其余 provider。保存不中止。
- **If 某 provider 的 `restore_fn()` 抛异常**：跳过该系统恢复，打印警告含 namespace 和异常信息，继续其余 provider。该系统以默认状态运行。
- **If 存档中包含未注册 namespace 的数据**（游戏版本删除了某系统）：数据保留在存档中不被删除，但不分发给任何 provider。下次保存时该数据随存档一起写出，不会丢失。
- **If 已注册 provider 在存档中无对应 namespace**（新系统加载旧存档）：该 provider 的 `restore_fn()` 收到空 Dictionary `{}`。Provider 应以默认值初始化。
- **If 存档 `meta.version` 大于当前游戏版本**（未来版本存档）：拒绝加载，打印警告 `"Save version {v} is newer than game version {current}"`，创建新游戏。
- **If 迁移链中间缺少迁移脚本**（gap）：迁移中止，打印错误 `"Migration gap: no script for version {v}"`，回退到 backup 或新游戏。
- **If 迁移函数抛异常**：迁移中止，不覆盖原文件，打印错误含版本号和异常信息，回退到 backup 或新游戏。
- **If 磁盘空间不足导致写入失败**：`FileAccess` 写入返回错误，打印警告，不执行 rename，原有存档不受影响。
- **If 正在保存时收到新的保存请求**：忽略重复请求，打印调试日志。同一时间只允许一个保存操作。
- **If 正在加载时收到保存请求**：忽略保存请求，打印警告。
- **If `meta.data_version` 与当前数据版本不匹配**：打印警告，继续加载。版本校验仅做提示，不阻止加载。
- **If provider 返回的 Dictionary 包含不可 JSON 序列化的值**（如 Object 引用）：`JSON.stringify()` 跳过或转为 null，打印警告。

## Dependencies

| 系统 | 方向 | 依赖性质 | 数据接口 |
|------|------|---------|---------|
| 时间管理器 | 上游依赖 | 硬依赖 | TimeManager 注册为 provider，保存/恢复 `{exit_real_timestamp, game_ref, real_ref, speed_sources}`；SaveManager 保存前通知 TimeManager 刷新 `exit_timestamp` |
| EventBus | 上游依赖 | 硬依赖 | 发布 `save.loaded`、`save.saved`、`save.corrupted` 事件 |
| 数据配置系统 | 协作 | 软依赖 | SaveManager 在 `meta.data_version` 中记录数据版本；加载时校验一致性 |
| 资源系统 | 下游注册 | 硬依赖（save 侧） | 注册 provider 保存/恢复资源数据 |
| 属性系统 | 下游注册 | 硬依赖（save 侧） | 注册 provider 保存/恢复属性数据 |
| 物品/材料系统 | 下游注册 | 硬依赖（save 侧） | 注册 provider 保存/恢复背包数据 |
| 等级系统 | 下游注册 | 硬依赖（save 侧） | 注册 provider 保存/恢复等级数据 |
| 区域系统 | 下游注册 | 硬依赖（save 侧） | 注册 provider 保存/恢复区域进度 |
| 离线模拟内核 | 下游消费 | 硬依赖 | 监听 `save.loaded` 事件，触发离线结算 |

**双向一致性说明**：
- 时间管理器 GDD 的 Interactions 表已列出存档系统为双向协作方。本 GDD 与之一致。
- 数据配置系统 GDD 的 Interactions 表已列出存档系统为协作方（版本校验）。本 GDD 与之一致。
- EventBus GDD 的事件名空间约定中需补充 `save.*` 系列事件。

## Tuning Knobs

| 参数 | 当前值 | 安全范围 | 增大影响 | 减小影响 |
|------|--------|---------|---------|---------|
| `AUTOSAVE_INTERVAL_SECONDS` | 60 | [30, 300] | 存档更频繁，数据丢失风险降低，I/O 开销略增 | 存档间隔拉长，异常退出时损失更多进度 |
| `CURRENT_SAVE_VERSION` | 1 | [1, ∞] | 每次存档格式变更递增，触发迁移链 | — |
| `SAVE_DIR` | `"user://save/"` | 任何 `user://` 路径 | 改变存档文件存放位置 | 同左 |
| `MAX_SAVE_FILE_SIZE_KB` | 512 | [64, 4096] | 允许更大的存档文件 | 限制存档大小，防止异常膨胀 |
| `WARN_ON_VERSION_MISMATCH` | `true` | [true, false] | data_version 不匹配时打印警告 | 静默跳过版本校验 |
| `WARN_ON_UNKNOWN_NAMESPACE` | `true` | [true, false] | 存档含未注册 namespace 时打印警告 | 静默忽略未知数据段 |
| `BACKUP_ENABLED` | `true` | [true, false] | 每次保存前创建备份文件 | 不创建备份，损坏时无法恢复 |

## Acceptance Criteria

- [ ] **GIVEN** 两个系统已注册 provider（`time_manager`、`resource_system`），**WHEN** 调用 `save_game()`，**THEN** `user://save/save.json` 包含 `meta` 和 `systems`，且 `systems.time_manager` 和 `systems.resource_system` 均为非空 Dictionary
- [ ] **GIVEN** `save.json` 含有效存档数据，**WHEN** 调用 `load_game()`，**THEN** 所有已注册 provider 的 `restore_fn()` 被调用，参数为对应 namespace 的 Dictionary
- [ ] **GIVEN** `save.json` 不存在，**WHEN** 调用 `load_game()`，**THEN** 所有 provider 的 `restore_fn()` 不被调用，游戏以默认状态开始，无错误
- [ ] **GIVEN** `save.json` JSON 语法错误，**WHEN** 调用 `load_game()`，**THEN** 尝试加载 `save.json.bak`，若 backup 有效则从 backup 恢复，发布 `save.corrupted` 事件
- [ ] **GIVEN** `save.json` 和 `save.json.bak` 都损坏，**WHEN** 调用 `load_game()`，**THEN** 游戏以默认状态开始，发布 `save.corrupted` 事件（`recovered_from_backup: false`）
- [ ] **GIVEN** `save.json` 缺少 `meta` 顶层键，**WHEN** 调用 `load_game()`，**THEN** 视为格式错误，触发损坏恢复流程
- [ ] **GIVEN** 系统 A 的 `save_fn()` 抛出异常，**WHEN** 调用 `save_game()`，**THEN** 系统 A 的 namespace 数据为 `null`，系统 B 的数据正常保存，打印警告
- [ ] **GIVEN** 系统 A 的 `restore_fn()` 抛出异常，**WHEN** 调用 `load_game()`，**THEN** 系统 A 以默认状态运行，系统 B 正常恢复，打印警告
- [ ] **GIVEN** 存档含 namespace `removed_system` 但无对应 provider，**WHEN** 加载，**THEN** 数据保留不分发，无错误；保存时该数据随存档写出
- [ ] **GIVEN** 新系统注册了 provider 但存档中无对应 namespace，**WHEN** 加载，**THEN** 该 provider 的 `restore_fn()` 收到空 Dictionary `{}`
- [ ] **GIVEN** 存档 `meta.version = 1`，当前 `CURRENT_SAVE_VERSION = 3`，注册了 v1→v2 和 v2→v3 迁移，**WHEN** 加载，**THEN** 迁移链按序执行，最终 `meta.version = 3`
- [ ] **GIVEN** 存档 `meta.version = 5`，当前 `CURRENT_SAVE_VERSION = 3`，**WHEN** 加载，**THEN** 拒绝加载，创建新游戏，打印版本过高警告
- [ ] **GIVEN** 迁移脚本 v1→v2 抛异常，**WHEN** 加载，**THEN** 迁移中止，不覆盖原文件，回退到 backup 或新游戏
- [ ] **GIVEN** `BACKUP_ENABLED = true`，**WHEN** 调用 `save_game()`，**THEN** 保存成功后 `save.json.bak` 包含上一次的存档数据
- [ ] **GIVEN** 正在执行保存操作，**WHEN** 再次调用 `save_game()`，**THEN** 忽略重复请求，打印调试日志
- [ ] **GIVEN** SaveManager 收到 `NOTIFICATION_WM_CLOSE_REQUEST`，**WHEN** 退出流程触发，**THEN** 在关闭前完成一次保存
- [ ] **GIVEN** 自动保存间隔设为 60 秒，**WHEN** 游戏运行 180 秒，**THEN** 至少触发 2 次自动保存（不含退出保存）
- [ ] **GIVEN** `meta.data_version` 与当前游戏数据版本不一致，**WHEN** 加载，**THEN** 打印版本不匹配警告，继续加载不中止
- [ ] **GIVEN** 存档目录路径为 `"user://test_save/"`，**WHEN** 用该路径构造 SaveManager 并保存，**THEN** 文件写入 `user://test_save/save.json`
- [ ] **GIVEN** 15 个 provider 各返回 ~800 bytes 数据，**WHEN** 保存，**THEN** 文件大小 < 50 KB，保存耗时 < 20 ms
- [ ] **GIVEN** 对同一 namespace 重复调用 `register_provider()`，**WHEN** 保存，**THEN** 使用最后一次注册的回调，打印覆盖警告
- [ ] **GIVEN** 保存成功完成，**WHEN** 检查文件系统，**THEN** 存在 `save.json` 和 `save.json.bak`，不存在 `save.json.tmp`（临时文件已清理）

## Open Questions

| Question | Owner | Deadline | Resolution |
|----------|-------|----------|-----------|
| provider 保存/恢复顺序是否需要显式控制（如依赖链排序）？当前按注册顺序，TimeManager 是否需在所有资源系统之前恢复？ | 开发者 | 实现阶段前 | — |
| 迁移脚本是否应存放在独立目录（如 `assets/migrations/`）还是代码内注册？ | 开发者 | 首次迁移需求时 | — |
| 自动保存是否需要区分"静默保存"和"显式保存"事件（如 UI 显示"已保存"提示）？ | 设计师 | HUD 系统 GDD 时 | — |
| 存档文件是否需要校验和（如 SHA256）用于检测篡改？MVP 是否需要反作弊？ | 开发者 | 反作弊需求明确时 | — |
| `play_time_seconds` 是由 SaveManager 追踪还是由 TimeManager 提供？ | 开发者 | 实现阶段前 | — |
