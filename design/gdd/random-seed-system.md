# 随机数与种子系统 (Random Seed System)

> **Status**: Designed
> **Author**: binlee1990 + agents
> **Last Updated**: 2026-05-03
> **Implements Pillar**: 4.3 刷宝提供惊喜 · 4.10 数据驱动与可扩展

## Overview

随机数与种子系统是整个游戏的确定性随机数基础设施层。它提供统一的、可复现的随机数生成服务，使战斗判定、装备掉落、词条生成、奇遇触发等所有含随机要素的游戏机制都能基于可追踪的种子产生确定性结果。

核心价值是**可复现性**：给定相同的种子和调用序列，随机结果完全一致。这一特性支撑三个关键需求——(1) 离线模拟与在线战斗的结果一致性（离线模拟内核需要用确定性 RNG 重现战斗）；(2) 调试和回放能力（开发者和玩家可以重现任何一次掉落或战斗的完整随机序列）；(3) 反作弊检测（验证存档中的随机结果是否符合种子推导）。

系统采用多流（multi-stream）架构：不同游戏子系统（战斗、掉落、事件、词条）使用独立的 RNG 流，每个流维护自己的种子和内部状态。流的隔离保证一个子系统的随机调用不会影响另一个子系统的随机序列——战斗中一次暴击判定不会改变下一次掉落的物品。

本系统管理所有 RNG 流的生命周期：创建、种子设置、状态保存/恢复、调用接口。下游系统（公式引擎、掉落系统、战斗计算器）通过流 ID 获取专用的 RNG 实例，不直接使用 Godot 全局 `randi()`/`randf()` 函数。

## Player Fantasy

随机数与种子系统是无形的命数——玩家永远看不到它，但每一次掉落的惊喜、每一次暴击的判定、每一次奇遇的出现，都是它在编织因果。

**锚定时刻**：玩家在某个区域挂机刷怪。战斗日志滚动，装备不断进仓——然后，一件传说品质的装备出现了。那一刻的惊喜是真实的，但背后并非混沌——而是由种子确定的命数。这件装备的出现不是"系统施舍"，而是概率规则下的必然降临。玩家感受到的是"天道有常"——运气不是黑箱，而是可信赖的公平规则。当玩家看到掉落率从 0.1% 涨到 5% 后，传说装备真的更频繁出现，这种"我的选择影响了概率"的因果感，正是随机数系统在背后保障的。

作为基础设施，随机数系统不创造惊喜本身，但它是惊喜的公正裁判。没有它，掉落可能被不可预测的 RNG 状态污染（战斗消耗了本属于掉落的"好运气"），离线收益可能与在线战斗结果不一致（同样的队伍配置在线打赢、离线却输了），玩家对"这把掉落是否合法"的信任将崩塌。有了它，修仙世界的随机性是受天道约束的混沌——不可预测，但公平、一致、可追溯。

支柱对应：
- **4.3 刷宝提供惊喜**：随机数系统确保每一次掉落都基于正确的概率权重，玩家的气运加成和区域掉落倍率真正生效。惊喜不是假象，是数学规则下的真实运气。
- **4.10 数据驱动与可扩展**：种子机制使所有随机过程可复现、可调试、可验证，支持开发阶段的平衡测试和长期内容扩展。

## Detailed Design

### Core Rules

1. **架构形态**：`RNGManager` 作为 Autoload 单例（`/root/RNGManager`），全局唯一。所有系统通过 RNGManager 获取随机数，禁止直接使用 Godot 全局 `randi()`/`randf()`。

2. **主种子 (Master Seed)**：
   - 新游戏开始时由 `Time.get_unix_time_from_system()` 的低 32 位 + 计数器组合生成 64 位主种子
   - 主种子是整个游戏随机性的唯一根源——所有 RNG 流的种子均由主种子推导而来
   - 主种子写入存档，加载时恢复

3. **多流架构**：
   - 每个游戏子系统拥有独立的 RNG 流（一个 `RandomNumberGenerator` 实例）
   - 流之间完全隔离：一个流的随机调用不消耗其他流的随机序列
   - 流通过唯一 ID 标识，分两类：
     - **核心流**：枚举定义，游戏启动时自动创建
       ```gdscript
       enum CoreStream { COMBAT, LOOT, EVENT, AFFIX }
       ```
     - **扩展流**：字符串 ID，由下游系统或 Mod 运行时注册

4. **种子推导**：
   - 核心流：`derived_seed = hash(master_seed + core_stream_index)`
   - 扩展流：`derived_seed = hash(master_seed + stream_name_hash)`
   - 推导函数使用 FNV-1a 64-bit 哈希，确保不同流 ID 产生不同且不相关的种子
   - 相同主种子永远产生相同的推导种子序列

5. **核心流定义**：

   | 流 ID | 用途 | 消费系统 |
   |--------|------|---------|
   | `COMBAT` | 命中/暴击/闪避/技能触发判定 | 战斗计算器 |
   | `LOOT` | 掉落物品选择、数量、品质判定 | 掉落系统 |
   | `EVENT` | 奇遇触发、世界事件选择、NPC 事件 | 事件系统（未来） |
   | `AFFIX` | 装备词条生成、前后缀选择、数值范围随机 | 词条系统（未来） |

6. **扩展流注册**：
   - `RNGManager.register_stream(stream_name: String) -> void`
   - 注册时自动从当前主种子推导种子并创建 RNG 实例
   - 重复注册同一 stream_name：静默忽略（幂等）
   - Mod 和未来系统通过此接口创建自定义 RNG 流

7. **随机数 API**：
   - `RNGManager.rand_int(stream_id, min_val: int, max_val: int) -> int` — 均匀整数随机
   - `RNGManager.rand_float(stream_id, min_val: float = 0.0, max_val: float = 1.0) -> float` — 均匀浮点随机
   - `RNGManager.rand_bool(stream_id, probability: float = 0.5) -> bool` — 概率判定
   - `RNGManager.weighted_pick(stream_id, weights: Array[float]) -> int` — 加权随机选择，返回命中索引
   - `RNGManager.shuffle(stream_id, array: Array) -> Array` — Fisher-Yates 洗牌，返回新数组
   - `RNGManager.pick_random(stream_id, array: Array) -> Variant` — 从数组中随机选一个元素

8. **加权随机 (weighted_pick)**：
   - 输入：权重数组，如 `[10.0, 30.0, 5.0, 55.0]`
   - 算法：累积分布 + 二分查找（别名方法预留为性能优化路径）
   - 输出：被选中项的索引（0-based）
   - 所有权重为 0 时：返回 -1（无有效选择）
   - 权重数组为空时：返回 -1

9. **状态保存与恢复**：
   - `RNGManager.save_states() -> Dictionary` — 保存所有流的 `{seed, state}` 到字典
   - `RNGManager.load_states(data: Dictionary) -> void` — 从字典恢复所有流的状态
   - 序列化格式：`{ "master_seed": 12345, "streams": { "combat": {"seed": 67890, "state": 111213}, ... } }`
   - 存档系统负责调用这两个方法——RNGManager 不直接操作存档文件

10. **调试接口**：
    - `RNGManager.set_master_seed(seed: int) -> void` — 强制设置主种子（仅调试控制台使用）
    - `RNGManager.get_master_seed() -> int` — 读取当前主种子
    - `RNGManager.get_stream_info(stream_id) -> Dictionary` — 返回流的种子、状态、调用次数统计
    - 设置主种子后所有现有流重新推导种子并重置状态

11. **离线模拟支持**：
    - 离线模拟开始前：调用 `save_states()` 快照当前 RNG 状态
    - 离线模拟期间：在快照副本上运行随机调用，不影响在线 RNG 状态
    - 离线模拟完成后：丢弃模拟用的副本，在线 RNG 状态不受影响
    - 这保证了离线模拟的确定性（同种子同序列同结果），同时在线 RNG 不被离线模拟消耗

### States and Transitions

| 状态 | 描述 | 转换条件 |
|------|------|---------|
| **Uninitialized** | 主种子未设置，所有流不可用 | `set_master_seed()` 或新游戏初始化 → Seeded |
| **Seeded** | 主种子已设置，核心流已创建并就绪 | 正常运行状态 |
| **Simulating** | 离线模拟正在进行，使用状态副本 | 模拟完成 → Seeded（在线状态不受影响） |

特殊规则：
- **Uninitialized 状态下调用随机 API**：返回确定性默认值（`rand_int` 返回 `min_val`，`rand_float` 返回 `min_val`，`rand_bool` 返回 `false`，`weighted_pick` 返回 `0`），打印警告 `"RNG stream {id} not initialized, returning default"`
- **Simulating 状态下在线调用**：正常运行。Simulating 仅标记离线模拟路径使用独立副本，不影响在线路径

### Interactions with Other Systems

| 系统 | 方向 | 数据接口 | 说明 |
|------|------|---------|------|
| 公式引擎 | 下游消费 | `rand_float(COMBAT, ...)`, `rand_bool(COMBAT, ...)` | 公式中含随机方差或概率触发时调用 |
| 掉落系统 | 下游消费 | `weighted_pick(LOOT, weights)`, `rand_int(LOOT, ...)` | 掉落表加权选择、数量随机、品质判定 |
| 战斗计算器 | 下游消费 | `rand_float(COMBAT, ...)`, `rand_bool(COMBAT, ...)` | 命中/暴击/闪避概率判定 |
| 存档系统 | 双向 | `save_states()` / `load_states(data)` | 存档时保存 RNG 状态，加载时恢复 |
| 调试控制台 | 下游消费 | `set_master_seed()`, `get_stream_info()` | 开发阶段强制种子、查看流状态 |
| 词条系统（未来） | 下游消费 | `weighted_pick(AFFIX, ...)`, `rand_float(AFFIX, ...)` | 词条池选择、数值范围随机 |
| 事件系统（未来） | 下游消费 | `rand_bool(EVENT, ...)`, `weighted_pick(EVENT, ...)` | 奇遇触发概率、事件权重选择 |

## Formulas

### 1. 核心流种子推导

`derived_seed = fnv1a_64(master_seed, core_stream_index)`

**变量：**
| 变量 | 符号 | 类型 | 范围 | 说明 |
|------|------|------|------|------|
| master_seed | S | int | [0, 2^63 - 1] | 主种子 |
| core_stream_index | i | int | [0, 3] | CoreStream 枚举值 |

**输出范围：** [0, 2^63 - 1]（64-bit 非负整数）
**示例：** `fnv1a_64(9876543210, 0)` → 某确定性的 64-bit 整数（同输入永远产生同输出）

### 2. 扩展流种子推导

`derived_seed = fnv1a_64(master_seed, hash(stream_name))`

**变量：**
| 变量 | 符号 | 类型 | 范围 | 说明 |
|------|------|------|------|------|
| master_seed | S | int | [0, 2^63 - 1] | 主种子 |
| stream_name | N | String | 非空字符串 | 扩展流的唯一名称 |
| hash(N) | H(N) | int | [0, 2^63 - 1] | 字符串的 FNV-1a 哈希值 |

**输出范围：** [0, 2^63 - 1]
**示例：** `fnv1a_64(9876543210, fnv1a_64("custom_mod_stream"))` → 确定性 64-bit 整数

### 3. 加权随机选择 (weighted_pick)

`result = binary_search(cumulative_weights, rand × total_weight)`

**变量：**
| 变量 | 符号 | 类型 | 范围 | 说明 |
|------|------|------|------|------|
| weights | W | Array[float] | 长度 [1, 1024]，元素 [0.0, +∞) | 各项的权重值 |
| total_weight | T | float | (0.0, +∞) | `T = Σ(W[i])` |
| rand | R | float | [0.0, 1.0) | 来自指定流的均匀随机浮点数 |
| cumulative_weights | C | Array[float] | 长度 = len(W) | `C[i] = Σ(W[0..i])` — 预计算累积分布 |

**输出范围：** [0, len(W) - 1]（被选中项索引）或 -1（无效输入）
**计算过程：**
1. 若 `len(W) == 0` → 返回 -1
2. 计算 `T = Σ(W[i])`
3. 若 `T == 0.0` → 返回 -1
4. 生成 `R = rand_float(stream_id, 0.0, T)`
5. 在 `C` 数组中二分查找第一个 `C[i] >= R` 的索引
6. 返回该索引

**示例：** `weights = [10.0, 30.0, 5.0, 55.0]`，T = 100.0，R = 42.0 → C = [10, 40, 45, 100]，二分查找 42.0 ≥ 45 → 返回索引 2

### 4. 单次随机调用耗时

`call_time = method_overhead + stream_lookup`

**变量：**
| 变量 | 符号 | 类型 | 范围 | 说明 |
|------|------|------|------|------|
| method_overhead | t_method | float | [0.001, 0.01] ms | Godot RandomNumberGenerator 单次调用耗时 |
| stream_lookup | t_lookup | float | [0.001, 0.005] ms | 从流字典查找 RandomNumberGenerator 实例 |

**输出范围：** 0.002 ms（简单调用）到 0.015 ms（含流查找）
**示例：** `rand_bool(COMBAT, 0.3)` → 0.003 ms（简单概率判定）

### 5. weighted_pick 调用耗时

`wp_time = cumulative_build + rand_gen + binary_search`

**变量：**
| 变量 | 符号 | 类型 | 范围 | 说明 |
|------|------|------|------|------|
| cumulative_build | t_cum | float | O(n) | 累积分布数组构建耗时 |
| rand_gen | t_rand | float | [0.001, 0.01] ms | 单次均匀随机数生成 |
| binary_search | t_bs | float | O(log n) | 二分查找耗时 |
| n | n | int | [1, 1024] | 权重数组长度 |

**输出范围：** 0.01 ms（4 项）到 0.1 ms（1024 项）
**示例：** 10 项掉落表 → t_cum ≈ 0.005 ms + t_rand ≈ 0.003 ms + t_bs ≈ 0.002 ms = 0.01 ms

### 6. 状态序列化大小

`save_size ≈ fixed_overhead + stream_count × per_stream_size`

**变量：**
| 变量 | 符号 | 类型 | 范围 | 说明 |
|------|------|------|------|------|
| stream_count | N | int | [4, 64] | 已注册的 RNG 流数量 |
| per_stream_size | S_s | int | ~80 bytes | 每个流的序列化大小（stream_name + seed + state 的 JSON 编码） |
| fixed_overhead | S_f | int | ~30 bytes | master_seed 字段的 JSON 编码 |

**输出范围：** ~350 bytes（4 核心流）到 ~5.1 KB（64 流）
**示例：** 4 核心流 + 2 扩展流 = 6 × 80 + 30 = 510 bytes

## Edge Cases

- **If 权重数组为空**：`weighted_pick` 返回 -1。调用方应检查此返回值，表示"无有效选择"。
- **If 所有权重均为 0**：`weighted_pick` 返回 -1。等效于无有效选项，total_weight 为 0 时无法生成有意义的随机值。
- **If 权重数组包含负数**：钳位到 0.0 并打印警告 `"Negative weight at index {i} in stream {stream_id}, clamped to 0.0"`。负权重无游戏语义，不应让调用方处理负数。
- **If 权重数组只有一项**：返回索引 0（唯一选项必然命中）。不生成随机数——确定性返回。
- **If `rand_bool` 的 probability < 0**：钳位到 0.0，始终返回 false。
- **If `rand_bool` 的 probability > 1**：钳位到 1.0，始终返回 true。
- **If `rand_bool` 的 probability == 0**：始终返回 false（确定性）。不消耗随机数。
- **If `rand_bool` 的 probability == 1**：始终返回 true（确定性）。不消耗随机数。
- **If `rand_int` 的 min_val > max_val**：交换两者并打印警告 `"min_val > max_val in stream {stream_id}, values swapped"`。返回有效范围内的随机整数。
- **If `rand_int` 的 min_val == max_val**：返回该值（确定性）。不消耗随机数。
- **If `rand_float` 的 min_val > max_val**：同 rand_int 交换逻辑。
- **If 访问未注册的流 ID**：创建一个新的临时 RNG 实例（以当前主种子推导），打印警告 `"RNG stream '{id}' not registered, auto-created with derived seed"`。不阻断游戏运行，但表明调用方遗漏了注册步骤。
- **If Uninitialized 状态下调用随机 API**：返回确定性默认值（rand_int → min_val, rand_float → min_val, rand_bool → false, weighted_pick → 0），打印警告。游戏不应在 RNG 未初始化时正常运行——此为防御性降级。
- **If `save_states()` 在 Simulating 状态下调用**：保存在线状态的快照（不受离线模拟影响），正常工作。离线模拟使用独立副本。
- **If `load_states()` 传入不完整或损坏的 Dictionary**：逐字段验证，缺失字段用推导种子默认值填充。打印警告 `"RNG state incomplete: missing {field}, using derived default"`。不崩溃。
- **If `load_states()` 传入未知流名称**：创建该流并恢复其状态。允许旧存档中有已被删除的流——静默恢复但标记为不活跃。
- **If `register_stream()` 使用空字符串**：拒绝注册，打印错误 `"Stream name cannot be empty"`。返回不创建任何流。
- **If `register_stream()` 在 Simulating 状态下注册**：在在线流集合中注册，不影响当前离线模拟副本。下次离线模拟将包含新注册的流。
- **If 主种子为 0**：允许。FNV-1a 对输入 0 仍然产生有效哈希值。0 种子不等于"无种子"。
- **If FNV-1a 哈希碰撞**（两个不同流 ID 推导出相同种子）：理论上概率极低（2^-64）。接受此风险——碰撞仅导致两个流使用相同的初始种子序列，不影响隔离性，且每次调用后状态立即分化。
- **If weighted_pick 的权重值差异极大**（如 [0.0001, 1000000.0]）：float 精度可能导致低权重项几乎不可能命中。这是浮点数本质限制。若设计需要极端差异，调用方应使用整数权重。
- **If `shuffle()` 传入空数组**：返回空数组。无操作。
- **If `pick_random()` 传入空数组**：返回 null。打印警告 `"pick_random called on empty array in stream {stream_id}"`。
- **If 离线模拟中两个流并发访问**（多线程场景）：GDScript 单线程执行，不发生。若未来引入 GDExtension 多线程，每个线程必须使用自己的 RNG 副本。
- **If `set_master_seed()` 调用后未重新加载存档状态**：所有流重置到推导种子的初始状态。此后随机序列与存档保存时不同——这是调试用接口的正常行为，生产环境不应调用。

## Dependencies

| 系统 | 方向 | 依赖性质 | 数据接口 |
|------|------|---------|---------|
| **（无上游依赖）** | — | — | RNGManager 是 Foundation 层零依赖基础设施 |
| 公式引擎 | 下游依赖 RNGManager | 硬依赖 | 调用 `rand_float()`, `rand_bool()` 用于概率公式和方差计算 |
| 掉落系统 | 下游依赖 RNGManager | 硬依赖 | 调用 `weighted_pick()`, `rand_int()` 用于掉落表选择和数量判定 |
| 战斗计算器 | 下游依赖 RNGManager | 硬依赖 | 调用 `rand_bool()`, `rand_float()` 用于命中/暴击/闪避概率判定 |
| 存档系统 | 下游依赖 RNGManager | 硬依赖 | 调用 `save_states()` / `load_states()` 持久化 RNG 状态 |
| 调试控制台 | 下游依赖 RNGManager | 软依赖 | 调用 `set_master_seed()`, `get_stream_info()` 用于调试；可移除不影响游戏功能 |
| 词条系统（未来） | 下游依赖 RNGManager | 硬依赖 | 调用 `weighted_pick()`, `rand_float()` 用于词条池选择和数值随机 |
| 事件系统（未来） | 下游依赖 RNGManager | 硬依赖 | 调用 `rand_bool()`, `weighted_pick()` 用于奇遇触发和事件权重 |

**双向一致性**：上述系统的 GDD 应在各自 Dependencies 节中列出"上游依赖 RNGManager"。本 GDD 完成后，后续 GDD 的依赖声明需与此表保持一致。

## Tuning Knobs

| 参数 | 当前值 | 安全范围 | 增大影响 | 减小影响 |
|------|--------|---------|---------|---------|
| `MAX_STREAMS` | 64 | [8, 256] | 允许更多 Mod 和扩展系统注册流；状态序列化体积增大 | 限制系统扩展能力；核心 4 流 + 少量扩展应足够 |
| `MAX_WEIGHTS_LENGTH` | 1024 | [32, 8192] | 支持更大的掉落表和词条池；单次 weighted_pick 耗时增加 | 限制掉落表复杂度；超长权重数组应拆分 |
| `PROBABILITY_CLAMP_ENABLED` | true | [true, false] | probability 超出 [0,1] 时自动钳位，行为可预测 | 关闭后允许 >1 或 <0 的概率产生未定义行为（仅调试用） |
| `AUTO_CREATE_UNREGISTERED_STREAM` | true | [true, false] | 访问未注册流时自动创建，不中断游戏 | 关闭后未注册流访问触发错误，有助于发现遗漏注册的 bug |
| `WARN_ON_DEFAULT_RETURN` | true | [true, false] | 未初始化时打印警告，辅助调试 | 关闭后静默返回默认值，减少日志噪音（生产构建可用） |
| `OFFLINE_SIM_COPY_ENABLED` | true | [true, false] | 离线模拟使用独立副本，在线 RNG 不受影响 | 关闭后离线模拟直接消耗在线 RNG 状态（仅限测试） |

**说明**：上述参数为开发者/工程参数，不属于游戏设计师调参范围。运行时不应动态修改（调试模式除外）——它们是实现时的编译期常量或项目配置。

## Visual/Audio Requirements

不适用——纯基础设施系统，无视觉/音频需求。

## UI Requirements

不适用——纯基础设施系统，玩家不直接交互。调试接口通过调试控制台暴露。

## Acceptance Criteria

- [ ] **GIVEN** RNGManager 作为 Autoload 加载，**WHEN** 任意系统访问 `RNGManager`，**THEN** 获得同一个全局单例实例
- [ ] **GIVEN** 新游戏开始，**WHEN** RNGManager 初始化，**THEN** 自动生成 64 位主种子，并创建 COMBAT、LOOT、EVENT、AFFIX 四个核心流
- [ ] **GIVEN** 相同的主种子值 12345，**WHEN** 连续两次调用 `set_master_seed(12345)`，**THEN** 所有核心流产生完全相同的随机序列
- [ ] **GIVEN** COMBAT 流和 LOOT 流已初始化，**WHEN** 从 COMBAT 流连续调用 100 次 `rand_bool`，**THEN** LOOT 流的下一个 `rand_float` 结果与从未调用 COMBAT 流时完全一致
- [ ] **GIVEN** 权重数组 `[10.0, 30.0, 5.0, 55.0]`，**WHEN** 以固定种子执行 `weighted_pick` 10000 次，**THEN** 各索引命中频率比例近似 10:30:5:55（误差 < 5%）
- [ ] **GIVEN** 权重数组 `[100.0]`（仅一项），**WHEN** 执行 `weighted_pick`，**THEN** 返回 0，且不消耗随机数
- [ ] **GIVEN** 空权重数组 `[]`，**WHEN** 执行 `weighted_pick`，**THEN** 返回 -1
- [ ] **GIVEN** 所有权重为零 `[0.0, 0.0, 0.0]`，**WHEN** 执行 `weighted_pick`，**THEN** 返回 -1
- [ ] **GIVEN** 权重数组包含负数 `[10.0, -5.0, 20.0]`，**WHEN** 执行 `weighted_pick`，**THEN** 负数钳位到 0.0，打印警告，实际权重为 `[10.0, 0.0, 20.0]`
- [ ] **GIVEN** `rand_bool(COMBAT, 0.3)` 以固定种子执行 10000 次，**THEN** true 的频率约 30%（误差 < 3%）
- [ ] **GIVEN** `rand_bool` 的 probability 为 0，**WHEN** 执行，**THEN** 返回 false，不消耗随机数
- [ ] **GIVEN** `rand_bool` 的 probability 为 1，**WHEN** 执行，**THEN** 返回 true，不消耗随机数
- [ ] **GIVEN** `rand_bool` 的 probability 为 -0.5，**WHEN** 执行，**THEN** 钳位到 0，返回 false
- [ ] **GIVEN** `rand_bool` 的 probability 为 1.5，**WHEN** 执行，**THEN** 钳位到 1，返回 true
- [ ] **GIVEN** `rand_int(COMBAT, 10, 5)`（min > max），**WHEN** 执行，**THEN** 交换后返回 [5, 10] 范围内的随机整数，打印警告
- [ ] **GIVEN** `rand_int(COMBAT, 7, 7)`（min == max），**WHEN** 执行，**THEN** 返回 7，不消耗随机数
- [ ] **GIVEN** 流名称 `"custom_mod"`，**WHEN** 调用 `register_stream("custom_mod")`，**THEN** 创建新 RNG 流并从主种子推导种子；再次调用返回同一实例
- [ ] **GIVEN** 空字符串，**WHEN** 调用 `register_stream("")`，**THEN** 拒绝注册，打印错误，不创建任何流
- [ ] **GIVEN** RNGManager 处于 Seeded 状态，**WHEN** 调用 `save_states()` 后再 `load_states(saved_data)`，**THEN** 所有流的种子和状态恢复到保存时的值，后续随机序列与保存时完全一致
- [ ] **GIVEN** `load_states()` 传入缺失 `"master_seed"` 字段的 Dictionary，**WHEN** 执行，**THEN** 缺失字段用默认值填充，打印警告，不崩溃
- [ ] **GIVEN** RNGManager Uninitialized 状态，**WHEN** 调用 `rand_bool(COMBAT, 0.5)`，**THEN** 返回 false，打印警告
- [ ] **GIVEN** 在线 RNG 状态为 S1，**WHEN** 启动离线模拟（使用状态副本），**THEN** 模拟期间在线 RNG 仍为 S1，不受模拟调用影响
- [ ] **GIVEN** 数组 `[1, 2, 3, 4, 5]`，**WHEN** 以固定种子执行 `shuffle(COMBAT, array)`，**THEN** 返回一个排列，且以相同种子再次 shuffle 得到相同排列
- [ ] **GIVEN** 空数组，**WHEN** 执行 `shuffle(COMBAT, [])`，**THEN** 返回空数组
- [ ] **GIVEN** 空数组，**WHEN** 执行 `pick_random(COMBAT, [])`，**THEN** 返回 null，打印警告
- [ ] **GIVEN** 主种子为 0，**WHEN** 初始化 RNGManager，**THEN** 所有核心流正常创建，随机序列有效（不退化为全零或全同值）
- [ ] **GIVEN** 存档系统调用 `save_states()`，**WHEN** 序列化 6 个流（4 核心 + 2 扩展），**THEN** 结果 Dictionary 大小 < 1 KB
- [ ] **GIVEN** 单流每帧调用 100 次 `rand_bool`，**WHEN** 在 60fps 下运行 1 小时，**THEN** 总 RNG 调用耗时占帧预算 < 1%
- [ ] **GIVEN** 权重数组长度 1024，**WHEN** 执行 `weighted_pick`，**THEN** 单次调用耗时 < 0.1 ms
- [ ] **GIVEN** 存档中包含旧版本已删除的流名称，**WHEN** `load_states()` 执行，**THEN** 静默恢复该流状态，不报错

## Open Questions

| Question | Owner | Deadline | Resolution |
|----------|-------|----------|-----------|
| Godot 4.6 的 `RandomNumberGenerator` 内部实现是否有变更？`seed`/`state` 属性的行为是否与 4.3 一致？ | 开发者 | 实现阶段前 | — |
| GDScript 多实例 `RandomNumberGenerator`（10-20 个）在离线模拟批量调用（数千次/秒）下的性能是否满足 16.6ms 帧预算？ | 开发者 | 架构阶段前 | — |
| `weighted_pick` 是否需要支持别名方法（Alias Method）以优化高频场景的 O(1) 采样？累积分布 + 二分查找的 O(n) 构建是否足够？ | 开发者 | 掉落系统 GDD 时决定 | — |
| 扩展流的 `stream_name` 是否需要命名空间前缀（如 `"mod_xxx:stream_yyy"`）以防止 Mod 之间冲突？ | 技术总监 | Mod 规范系统 GDD 时决定 | — |
