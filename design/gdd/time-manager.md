# 时间管理器 (Time Manager)

> **Status**: Designed
> **Author**: binlee1990 + agents
> **Last Updated**: 2026-05-03
> **Implements Pillar**: 4.1 数字增长就是快乐 · 4.2 放置不是无操作

## Overview

时间管理器是整个游戏的时间基础设施层。它提供统一的时间源、离线时间差计算、时间加速倍率和时间冻结能力，是所有与时间相关的游戏机制——自动产出、离线收益结算、修炼计时、生产队列——的唯一时间权威。

放置游戏的核心承诺是"你不在时世界仍在运转"。实现这一承诺的技术基础是：当玩家离开时记录一个时间戳，返回时用当前时间戳减去离开时间戳，将差值交给离线模拟内核计算收益。时间管理器负责提供精确、不可篡改的时间戳，以及将时间差安全地传递给下游系统。

Godot 的 `_process(delta)` 不是可靠的时间源——Web 导出时标签页不活跃会暂停，低帧率时 delta 会跳跃。时间管理器基于系统 Unix 时间戳（`Time.get_unix_time_from_system()`）构建，确保时间测量不依赖渲染帧率，在任何平台上都能准确计算离线时间差。

本系统提供的核心能力包括：(1) 获取当前游戏时间（经加速倍率调整后的虚拟时间）；(2) 计算真实经过时间（两个时间戳的差值）；(3) 计算游戏经过时间（乘以加速倍率）；(4) 时间冻结/解冻（暂停所有基于时间的进度）；(5) 加速倍率管理（支持多来源叠加）；(6) 退出时间戳持久化（供离线收益使用）。

## Player Fantasy

时间管理器是无形的时光长河——玩家看不到它，但每一秒的修炼、每一刻的离线产出、每一次加速的快感，都是它在流淌。

**锚定时刻**：玩家关闭游戏去睡觉。八小时后重新打开，屏幕上弹出离线收益结算——灵气增长了数百万、自动战斗获得了十几件装备、生产建筑完成了一批丹药。这八小时不是空白的，而是真实的、可计算的、有因果的进步。玩家的第一反应不是"游戏给了我奖励"，而是"我离开的这段时间，世界认真地运转了"。

时间管理器让"放置"不再是偷懒的借口，而是修仙世界观的自然延伸——修行者闭关数日、数月、数年，出关时功力大涨，这正是放置游戏离线机制的最佳叙事映射。

支柱对应：
- **4.1 数字增长就是快乐**：时间管理器确保离线收益基于真实时间差精确计算。每一秒都有价值，玩家回来时看到的不是粗略估算，而是精确的、可追溯的积累。
- **4.2 放置不是无操作，而是低频高价值决策**：时间加速是玩家手中少数能主动控制时间的手段——按下加速按钮，看到数字增长变快，这种"我在控制时间"的感觉是放置游戏中最直接的力量感。

## Detailed Design

### Core Rules

1. **架构形态**：`TimeManager` 作为 Autoload 单例（`/root/TimeManager`），全局唯一。所有系统通过 TimeManager 获取时间，不直接调用 `Time.get_unix_time_from_system()`。

2. **双时间体系**：
   - **真实时间 (real_time)**：系统 Unix 时间戳，单位秒。不可冻结、不可加速。用于离线计算和反作弊。
   - **游戏时间 (game_time)**：经加速倍率调整后的虚拟时间。用于在线自动产出、修炼计时、生产队列。

3. **时间快照模型**：TimeManager 维护一个快照 `{real_ref, game_ref, speed_multiplier}`：
   - `game_time_now = game_ref + (real_time_now - real_ref) × speed_multiplier`
   - 当加速倍率变更或时间冻结/解冻时，重新计算并更新快照

4. **加速倍率管理**：
   - 倍率来源通过唯一 `source_id`（字符串）注册：`TimeManager.add_speed_source(source_id, multiplier)`
   - 多来源乘法叠加：`effective_speed = source_1 × source_2 × ... × source_n`
   - 无加速来源时基础倍率为 1.0
   - 移除来源：`TimeManager.remove_speed_source(source_id)` — 倍率立即重算

5. **时间冻结**：
   - `TimeManager.freeze()` — 游戏时间停止推进，真实时间继续
   - `TimeManager.unfreeze()` — 游戏时间恢复，快照更新为当前真实时间点
   - 冻结状态下 `game_time_now == game_ref`（不增长）
   - 通过 EventBus 发布 `time.frozen` / `time.unfrozen` 事件

6. **离线时间计算**：
   - 游戏退出时（`NOTIFICATION_WM_CLOSE_REQUEST` 或存档保存时）：记录 `exit_real_timestamp = real_time_now`
   - 游戏返回时：`offline_real_delta = min(real_time_now - exit_real_timestamp, MAX_OFFLINE_SECONDS)`
   - 离线游戏时间 = `offline_real_delta × 1.0`（离线不享受加速倍率）
   - 通过 EventBus 发布 `time.offline_delta` 事件，payload 包含 `real_delta` 和 `game_delta`

7. **Tick 查询接口**：
   - `TimeManager.get_real_delta_since(last_real_time) -> float` — 返回真实时间差（秒）
   - `TimeManager.get_game_delta_since(last_game_time) -> float` — 返回游戏时间差（秒）
   - 调用方负责存储自己的上次时间戳，TimeManager 不追踪各系统的 tick 状态

8. **当前时间查询**：
   - `TimeManager.get_real_time() -> float` — 当前 Unix 时间戳
   - `TimeManager.get_game_time() -> float` — 当前游戏时间（经加速调整）
   - `TimeManager.get_effective_speed() -> float` — 当前有效加速倍率

9. **存档集成**：
   - TimeManager 在存档中写入：`{exit_real_timestamp, game_ref, real_ref, speed_sources: {id: multiplier}}`
   - 存档读取时：恢复快照，计算离线 delta，发布离线事件

### States and Transitions

| 状态 | 描述 | 转换条件 |
|------|------|---------|
| **Running** | 游戏时间正常流动，speed ≥ 1.0 | `freeze()` → Frozen |
| **Frozen** | 游戏时间暂停，真实时间继续 | `unfreeze()` → Running |
| **Offline** | 游戏已退出，仅 exit_timestamp 持久化 | 游戏启动 + 存档加载 → Running（触发离线结算） |

### Interactions with Other Systems

| 系统 | 方向 | 数据接口 | 说明 |
|------|------|---------|------|
| EventBus | 下游发布 | `time.frozen`, `time.unfrozen`, `time.speed_changed`, `time.offline_delta` | 时间状态变更通知 |
| 存档系统 | 双向 | 写入/读取 `{exit_real_timestamp, game_ref, real_ref, speed_sources}` | 退出时保存时间戳，加载时恢复并计算离线 delta |
| 自动产出系统 | 下游消费 | `get_game_delta_since(last_tick)` | 每 tick 查询经过的游戏时间，乘以产出速率计算资源增量 |
| 修炼系统 | 下游消费 | `get_game_delta_since(last_tick)` | 计算修炼进度 |
| 离线模拟内核 | 下游消费 | `offline_real_delta`（来自 `time.offline_delta` 事件） | 用真实时间差驱动批量模拟 |

## Formulas

### 1. 当前游戏时间

`game_time_now = game_ref + (real_time_now - real_ref) × effective_speed`

**变量：**
| 变量 | 符号 | 类型 | 范围 | 描述 |
|------|------|------|------|------|
| game_ref | g_ref | float | 任意正 float | 上次快照点的游戏时间（秒） |
| real_ref | r_ref | float | 任意正 float | 上次快照点的真实时间（Unix 秒） |
| real_time_now | r_now | float | 任意正 float | 当前真实时间（Unix 秒） |
| effective_speed | s | float | [0.0, 100.0] | 当前有效加速倍率 |

**输出范围：** `g_ref` 到 `g_ref + (MAX_SPEED × real_delta)`
**示例：** g_ref = 1000, r_ref = 1700000, r_now = 1700060, s = 2.0 → game_time_now = 1000 + (60 × 2.0) = 1120 秒

### 2. 有效加速倍率

`effective_speed = ∏(source_i.multiplier)` for all registered sources

**变量：**
| 变量 | 符号 | 类型 | 范围 | 描述 |
|------|------|------|------|------|
| source_i.multiplier | m_i | float | [1.0, 10.0] | 第 i 个加速来源的倍率 |
| source count | N | int | [0, 10] | 已注册的加速来源数量 |

**输出范围：** 1.0（无加速）到 10^10（理论上限，实际由 MAX_SPEED 约束）
**约束：** `effective_speed = min(effective_speed, MAX_SPEED)` — 超过上限截断
**示例：** VIP 倍率 1.5x × 广告加速 2.0x × 丹药加速 1.2x = 3.6x

### 3. 离线游戏时间差

`offline_game_delta = min(real_time_now - exit_timestamp, MAX_OFFLINE_SECONDS)`

**变量：**
| 变量 | 符号 | 类型 | 范围 | 描述 |
|------|------|------|------|------|
| real_time_now | r_now | float | 任意正 float | 当前真实 Unix 时间戳 |
| exit_timestamp | t_exit | float | 任意正 float | 游戏退出时记录的真实时间戳 |
| MAX_OFFLINE_SECONDS | T_max | float | 28800 | 离线最大计算时间（8 小时 = 28800 秒） |

**输出范围：** 0.0 秒到 28800 秒（8 小时）
**示例：** 离线 10 小时（36000 秒）→ min(36000, 28800) = 28800 秒（按 8 小时计算）

### 4. 游戏 Tick 时间差

`game_delta = game_time_now - last_game_time`

**变量：**
| 变量 | 符号 | 类型 | 范围 | 描述 |
|------|------|------|------|------|
| game_time_now | g_now | float | 当前游戏时间 | 由公式 1 计算得出 |
| last_game_time | g_last | float | 调用方记录的上次 tick 时间 | 由调用方在上一帧存储 |

**输出范围：** 0.0（冻结或同一帧）到 `MAX_SPEED × real_delta`（理论最大值）
**示例：** g_now = 1120, g_last = 1118 → game_delta = 2.0 秒（在 2x 加速下实际只过了 1 真实秒）

## Edge Cases

- **If 系统时钟被回拨**（NTP 校正或手动调整导致 `real_time_now < exit_timestamp`）：离线 delta 钳位到 0.0 秒，不产生负数收益。打印警告 `"System clock went backwards: delta={negative_value}s"`。不进行离线结算。
- **If 系统时钟大幅前跳**（如 CMOS 电池故障导致重置到 2000 年后修正）：真实 delta 由 `MAX_OFFLINE_SECONDS` 截断，不会产生异常大的离线收益。超过 8 小时的部分被静默忽略。
- **If 存档中无 exit_timestamp**（首次启动或存档损坏）：跳过离线结算，游戏时间从当前真实时间开始计算。`game_ref = 0`, `real_ref = current_real_time`。
- **If 加速倍率来源注册了 0 或负数值**：钳位到 1.0（等效于无加速）。打印警告 `"Invalid speed multiplier: {value} from source {source_id}, clamped to 1.0"`。
- **If 移除从未注册的 speed_source**：静默忽略，无副作用。
- **If 同一帧内多次 freeze/unfreeze**：只有最终状态生效。每次 freeze/unfreeze 都更新快照点，确保 game_time 连续。
- **If 冻结状态下查询 game_delta**：返回 0.0 — 游戏时间未推进。
- **If 冻结状态下加速倍率变更**：倍率变更立即生效（更新快照），但解冻前 game_time 仍不推进。解冻时使用新倍率。
- **If 有效倍率超过 MAX_SPEED**：截断到 MAX_SPEED。快照更新后通知下游：`time.speed_changed` 事件携带 `effective_speed`（已截断值）。
- **If 同一 source_id 重复注册不同倍率**：覆盖旧倍率，更新快照并重算。视为"倍率升级"，不叠加。
- **If 存档读取时 speed_sources 包含已失效的来源**（如限时加速已过期）：恢复存档时由加速来源的拥有系统决定是否重新注册。TimeManager 只负责数学计算，不理解业务语义。
- **If 离线时间恰好等于 0 秒**（立即返回）：跳过离线结算，不发布 `time.offline_delta` 事件。
- **If `_process` 的 delta 与 Unix 时间差不一致**（帧率波动）：以 Unix 时间戳为准，忽略 `_process` delta。TimeManager 从不依赖帧 delta 做计时。

## Dependencies

| 系统 | 方向 | 依赖性质 | 数据接口 |
|------|------|---------|---------|
| EventBus | 上游依赖 | 硬依赖 | 发布 `time.frozen`, `time.unfrozen`, `time.speed_changed`, `time.offline_delta` 事件 |
| 存档系统 | 下游依赖 TimeManager | 硬依赖 | 写入/读取时间快照数据和 exit_timestamp |
| 自动产出系统 | 下游依赖 TimeManager | 硬依赖 | 调用 `get_game_delta_since()` 计算每 tick 产出 |
| 修炼系统 | 下游依赖 TimeManager | 硬依赖 | 调用 `get_game_delta_since()` 计算修炼进度 |
| 离线模拟内核 | 下游依赖 TimeManager | 硬依赖 | 通过 `time.offline_delta` 事件获取离线时间差 |

**注**：原始 systems-index 中时间管理器的"Depends On"列为空。本 GDD 设计中 TimeManager 使用 EventBus 发布事件，实际存在一个上游依赖。Systems index 需更新。

**双向一致性**：EventBus GDD 的 Interactions 表需补充 `time.*` 系列事件。存档系统、自动产出系统、修炼系统、离线模拟内核的 GDD 完成后需各自列出"上游依赖 TimeManager"。

## Tuning Knobs

| 参数 | 当前值 | 安全范围 | 增大影响 | 减小影响 |
|------|--------|---------|---------|---------|
| `MAX_OFFLINE_SECONDS` | 28800 (8h) | [3600 (1h), 86400 (24h)] | 离线收益更高，但可能造成数值膨胀 | 玩家无法获得过夜收益，体验下降 |
| `MAX_SPEED` | 100.0 | [2.0, 1000.0] | 允许更高加速，游戏节奏更快 | 限制加速上限，后期数值增长受限 |
| `MAX_SPEED_SOURCES` | 10 | [3, 20] | 允许更多加速来源叠加 | 限制叠加层数，简化加速系统 |
| `MIN_SPEED` | 0.0 | [0.0, 0.5] | 允许降至完全停止 | 最低倍率不低于某值，保证基础进度 |
| `SPEED_CHANGE_LOG_THRESHOLD` | 2.0 | [1.5, 5.0] | 倍率变化超过此值才打印日志 | 更敏感，更多调试信息 |

**说明**：`MAX_OFFLINE_SECONDS` 是设计师可调的平衡参数。`MAX_SPEED` 和 `MAX_SPEED_SOURCES` 是开发者参数，运行时不应动态修改。

## Acceptance Criteria

- [ ] **GIVEN** TimeManager 作为 Autoload 加载，**WHEN** 调用 `get_real_time()`，**THEN** 返回当前 Unix 时间戳（精度 ±1 秒）
- [ ] **GIVEN** speed = 2.0，**WHEN** 真实时间经过 60 秒，**THEN** `get_game_delta_since(last_game_time)` 返回约 120.0 秒
- [ ] **GIVEN** speed = 1.0（无加速），**WHEN** 真实时间经过 60 秒，**THEN** `get_game_delta_since(last_game_time)` 返回约 60.0 秒
- [ ] **GIVEN** 注册速度来源 A=1.5x 和 B=2.0x，**WHEN** 查询 `get_effective_speed()`，**THEN** 返回 3.0（乘法叠加）
- [ ] **GIVEN** 已注册来源 A=1.5x，**WHEN** 移除来源 A，**THEN** `get_effective_speed()` 返回 1.0
- [ ] **GIVEN** 已注册来源 A=1.5x，**WHEN** 用同一 source_id "A" 注册新倍率 2.0x，**THEN** `get_effective_speed()` 返回 2.0（覆盖，非叠加）
- [ ] **GIVEN** speed = 10.0x，**WHEN** 注册新来源使乘积超过 MAX_SPEED(100)，**THEN** `get_effective_speed()` 返回 100.0（截断）
- [ ] **GIVEN** 注册倍率为 0 或 -1 的来源，**WHEN** 执行 `add_speed_source()`，**THEN** 该来源倍率钳位到 1.0，打印警告
- [ ] **GIVEN** Running 状态，**WHEN** 调用 `freeze()`，**THEN** `get_game_time()` 停止增长，发布 `time.frozen` 事件
- [ ] **GIVEN** Frozen 状态下真实时间经过 30 秒，**WHEN** 查询 `get_game_delta_since(last_game_time)`，**THEN** 返回 0.0
- [ ] **GIVEN** Frozen 状态，**WHEN** 调用 `unfreeze()`，**THEN** 游戏时间恢复推进，发布 `time.unfrozen` 事件
- [ ] **GIVEN** exit_timestamp 存在于存档中，**WHEN** 玩家离线 5 小时后返回，**THEN** 发布 `time.offline_delta` 事件，payload.real_delta ≈ 18000 秒
- [ ] **GIVEN** exit_timestamp 存在，**WHEN** 玩家离线 12 小时后返回，**THEN** offline_delta 钳位到 28800 秒（MAX_OFFLINE_SECONDS），超过部分忽略
- [ ] **GIVEN** 系统时钟回拨导致 real_time_now < exit_timestamp，**WHEN** 计算离线 delta，**THEN** delta = 0.0，打印警告，不进行离线结算
- [ ] **GIVEN** 存档中无 exit_timestamp，**WHEN** 首次加载游戏，**THEN** 跳过离线结算，game_ref = 0，real_ref = current_real_time
- [ ] **GIVEN** Frozen 状态，**WHEN** 变更加速倍率，**THEN** 倍率立即更新，但 game_time 仍不推进，解冻后使用新倍率
- [ ] **GIVEN** 倍率变更生效，**WHEN** 调用 `add_speed_source()` 或 `remove_speed_source()`，**THEN** 发布 `time.speed_changed` 事件，payload 包含 `effective_speed`
- [ ] **GIVEN** TimeManager 初始化完成，**WHEN** 在 1 秒内执行 1000 次 `get_game_time()`，**THEN** 总耗时 < 0.1 ms（纯数学计算，无 I/O）
- [ ] **GIVEN** 移除从未注册的 source_id，**WHEN** 执行 `remove_speed_source("nonexistent")`，**THEN** 静默忽略，无错误

## Open Questions

| Question | Owner | Deadline | Resolution |
|----------|-------|----------|-----------|
| 加速来源是否需要自动过期机制（如限时 30 分钟加速）？还是由拥有系统自行移除？ | 设计师 | 修正器/倍率引擎 GDD 时决定 | — |
| MAX_OFFLINE_SECONDS 是否应随游戏阶段动态调整（如飞升后可延长到 24 小时）？ | 设计师 | 飞升系统 GDD 时决定 | — |
| game_time 的起点（game_ref = 0）是否有语义含义？是否需要一个"游戏开始时间"概念？ | 设计师 | 存档系统 GDD 时决定 | — |
