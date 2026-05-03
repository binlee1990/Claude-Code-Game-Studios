# 资源系统 (Resource System)

> **Status**: Designed
> **Author**: binlee1990 + agents
> **Last Updated**: 2026-05-03
> **Implements Pillar**: 4.1 数字增长就是快乐 · 4.4 城镇宗门是后勤系统
> **Creative Director Review (CD-GDD-ALIGN)**: REVISED 2026-05-03

## Overview

资源系统是游戏中所有"数字资产"的统一存储、读写与变更通知服务。游戏世界的状态——你修了多久、你有多少灵石、矿石、药材、丹药——全部以"资源 ID → BigNumber 数值"的映射形式存放在这里。它不创造资源（产出由自动产出系统负责）、不计算资源倍率（由产出乘数系统/修正器引擎负责）、不消费资源（由战斗、修炼、合成等业务系统通过本系统的 API 触发）；它只回答四个问题：**你有多少？你的上限是多少？你能/不能扣这个数？我帮你加/扣完了，谁需要被通知？**

资源 ID 是字符串常量（如 `lingqi`、`xiuwei`、`lingshi`），数值统一存储为 `BigNumber` 以支持后期指数级膨胀。每个资源除当前值外还有上限值（由存储上限系统注入）：任何加法运算超过上限会被钳位并发布"溢出"事件，任何减法运算导致负值会被拒绝并返回失败标志位。每一次资源变化——加、扣、设、上限调整——都通过事件总线发布 `resource.{id}.changed` 事件，下游的 HUD、UI 框架、调试控制台、离线收益结算面板订阅这些事件刷新显示和触发后续逻辑。

资源系统**不是**游戏机制系统——它不知道修炼会产灵气，也不知道战斗会消耗法力。它是一个被动的数据库 + 事件源。机制系统在合适的时机调用 `add(id, qty)` 或 `spend(id, qty)`，资源系统忠实记录、检查、广播。这种边界划分是 TD-SYSTEM-BOUNDARY 评审的核心约束（避免 God Object）：当你想给资源系统加"产出方法"时，停下——那是自动产出系统的责任。

虽然玩家不直接调用资源系统的 API，但他们看到的每一个跳动的数字都是由这个系统驱动的。HUD 顶栏的"灵气：1.23 万"在屏幕上每秒变化一次，背后是修炼系统调用 `add("lingqi", per_second_amount)`，资源系统钳位、写入、发布事件，HUD 订阅事件刷新文本。这种"我离开五分钟回来，灵气从 1.2 万变成了 16.5 万"的可见成长——pillar 4.1"数字增长就是快乐"的最直接体现——发生在资源系统这一层。没有它，所有玩家可见的数字都是浮空的，互不一致，无法存档，无法触发瓶颈/上限提示。

作为 Core Gameplay 层的基础服务，资源系统是 **MVP 最小挂机闭环**的中枢之一：修炼产灵气、战斗消耗法力、掉落给材料、升级扣经验、离线结算补发——所有这些机制都通过资源系统这一层落地。本 GDD 完成后，存储上限系统、自动产出系统、修炼系统、HUD 系统四个直接下游系统的设计依赖才能解锁。

## Player Fantasy

资源系统是修仙世界的丹田经脉——灵气在这里盈溢、修为在这里沉淀、灵石在这里堆积、药材丹药矿石在这里出入。它本身无相，但所有可见的成长都从它流出。

**主锚定时刻**：玩家午休回来，HUD 顶部的"灵气"数字从 2.4 亿跳到 8.7 亿，旁边的进度条已经泛红——"灵气 8.7亿 / 10亿（已满 87%）"。点开离线结算面板：73 分钟内，挂机区掉了 412 颗低阶灵石、2 株千年血参，修为推进 0.3% 至筑基七层；但溢出的灵气有 1700 万白白流逝。玩家的手立刻指向宗门面板——把"聚灵阵"再升一阶，扩 50% 容量，下次离开就不会再让这种"丹田已盈，恐有走火"的浪费发生。

这就是资源系统直接服务的体验：**数字在屏幕上跳动是世界仍在运转的最直接证据，而上限和瓶颈则把"数字增长"翻译成低频高价值决策**。pillar 4.1 在这里得到落实——增长不是单调线性，而是带阶段、带瓶颈的：你看着数字膨胀很爽，撞到上限的瞬间又自然产出下一个目标（升仓库、升宗门、突破境界）。pillar 4.4 也在此处兑现——宗门"聚灵阵/聚宝楼/储药轩"等建筑给资源加上限的设计，让宗门从装饰变成"我必须升级它否则吃亏"的后勤命脉。

**次级锚定时刻**：玩家点开"灵石"图标，弹出"近一小时变动明细"——东海挂机 +287、宗门税收 +50、突破筑基消耗 −1000、拍卖行成交 +2400。每一项都有来处，每一笔都可追溯。玩家不需要疑惑"数字怎么少了一千"，也不会怀疑"系统是不是漏算了"，于是放心地去推下一张图。

这一层是资源系统作为基础设施服务的**信任 fantasy**：在一个跨越突破/飞升/轮回多个阶段、长达数百小时的放置游戏里，玩家对数字的信任是所有其他成长体验的前提。如果数字会无故跳变、若有若无、来源不明，所有累积感都会崩塌。资源系统通过"任何变化都要发事件 + 任何来源都可追溯 + 任何溢出都有提示"的机制，把"账本般的确定性"作为修仙世界的底色——一种克制的可信，托住了 11 天后玩家面对屏幕上"灵气 1.23e15"时仍然觉得"这一切是真的、是我的"。

**支柱对应**：
- **4.1 数字增长就是快乐**：HUD 的数字跳动 + 上限/瓶颈/溢出三件套，让增长是有节奏的体验而非单调爬升。
- **4.4 城镇宗门是后勤系统**：上限管理把"升级宗门储物建筑"从可选优化变成必做决策，宗门生产侧因此真正反哺战斗与修炼。
- **4.2 放置不是无操作**（次要）：上限即将爆满 → 升级仓储 / 突破解锁更高上限——这是放置玩法核心的"低频高价值决策"之一。

资源系统不是创造修仙幻想的舞台，但它是这个幻想能被玩家信任、能被玩家看见、能被玩家用来做决定的底层经脉。

**重要边界声明**：资源系统是上述支柱兑现的**必要基础设施**，而非支柱的直接载体——HUD 系统才是数字跳动的视觉呈现者，宗门建筑系统/存储上限系统才是"升聚灵阵"决策的产生者，自动产出系统才是产出节奏的塑造者。本系统**只为它们提供可信赖的数据底座和事件源**。本节描述的"玩家锚定时刻"是资源系统作为基础设施被多个上层系统协同消费后所达成的整体体验，不应被理解为资源系统应主动包含产出/瓶颈提示/决策推荐等上层逻辑（参见 TD-SYSTEM-BOUNDARY 评审约束）。

## Detailed Design

### Core Rules

1. **架构形态**：`ResourceSystem` 为 `RefCounted` 服务类，由 Autoload 单例 `/root/ResourceSystem` 持有。对外暴露纯 CRUD + 事件接口；不含任何产出逻辑、乘数计算或业务判断。所有资源值存储为 `BigNumber`。

2. **资源条目数据模型**（每条以 `id` 为 key 存入内部 Dictionary）：
   - `id`: String — 全局唯一资源标识，如 `"lingqi"`, `"xiuwei"`, `"lingshi"`
   - `current`: BigNumber — 当前数量，范围 `[ZERO, cap]`（若 `has_cap=true`）或 `[ZERO, BigNumber.MAX]`（若 `has_cap=false`）
   - `cap`: BigNumber — 当前上限；`has_cap=false` 时此字段保留但不参与钳位
   - `has_cap`: bool — 是否启用上限
   - `category`: String — 资源类别枚举：`"currency" | "material" | "progress" | "regenerative"`（驱动 cap 默认行为，见 Tuning Knobs）
   - `reset_scope`: String — 重置范围枚举：`"none" | "breakthrough" | "ascension" | "rebirth"`，4 级有序包含
   - `metadata`: Dictionary — 扩展字段（UI 颜色、本地化 key 等），ResourceSystem 不读取

3. **API 表面**（全部同步调用，无协程）：
   ```
   register(definition: Dictionary) → bool                # 接收单条资源定义，重复 ID 拒绝
   add(id: String, amount: BigNumber) → BigNumber         # 返回实际加入量；溢出时 < amount
   spend(id: String, amount: BigNumber) → bool            # 余额不足返回 false 且不修改值
   set_value(id: String, value: BigNumber) → void         # 强制设置，内部钳位至 [ZERO, cap]
   get_value(id: String) → BigNumber                      # 不存在返回 ZERO
   get_max(id: String) → BigNumber                        # has_cap=false 时返回 BigNumber.MAX
   set_max(id: String, new_cap: BigNumber) → void         # 由存储上限系统调用；下钳触发双事件
   can_afford(id: String, amount: BigNumber) → bool
   has_resource(id: String) → bool
   get_all_ids() → Array[String]
   get_definition(id: String) → Dictionary                # 返回只读副本：{category, reset_scope, has_cap}
   batch_add(changes: Dictionary) → Dictionary            # { id: amount }，返回 { id: actual_added }
   reset_by_scope(scope: String) → int                    # 按有序包含关系重置；返回被重置的资源数
   snapshot() → Dictionary                                # 返回完整存档快照
   restore(data: Dictionary) → void                       # 从存档恢复
   ```

4. **上限执行语义**（add）：先计算 `new_value = current.add(amount)`；若 `has_cap=true` 则 `new_value = BigNumber.min(new_value, cap)`。**实际加入量** = `new_value - current`，由返回值传达；调用方据此判断是否发生溢出。实际加入量 = ZERO 时**不发布事件**（delta=0 抑制规则）。溢出时除发布常规 `resource.{id}.changed` 外，额外发布 `resource.{id}.overflow`，payload `{resource_id, attempted, actual_added, lost}`，用于"仓库已满"提示。

5. **余额不足语义**（spend）：若 `current.less_than(amount) == true`，**原子拒绝**——不修改任何值，返回 `false`，不发布事件。拒绝是正常返回路径，调用方必须检查返回值。

6. **事件发布规则**：值实际变化时发布 `resource.{id}.changed`，payload：
   ```
   { "resource_id": id, "old_value": old, "new_value": new, "delta": delta }
   ```
   - `old_value` / `new_value` / `delta` 均为 BigNumber
   - delta=ZERO 时不发布（防 HUD 无效刷新）
   - **`set_max` 下钳 current 时的事件顺序：先 `resource.{id}.cap_changed` 再 `resource.{id}.changed`**——HUD 先刷新上限再刷新当前值，避免瞬间显示"超出上限"

7. **类别 → cap 默认行为**（仅元数据，实际钳位仍按 `has_cap` 字段）：

   | category | has_cap 默认 | 溢出行为 |
   |----------|------------|---------|
   | regenerative | true | 截断 + overflow 事件 |
   | material | true | 截断 + overflow 事件 |
   | currency | false | 仅受 BigNumber.MAX 约束 |
   | progress | false | 仅受 BigNumber.MAX 约束（消费由突破/升级系统驱动） |

8. **MVP 初始资源集**（5 条，由 `resource_config.json` 注册）：

   | id | 中文 | category | has_cap | reset_scope |
   |----|------|----------|---------|-------------|
   | `lingqi` | 灵气 | regenerative | true | breakthrough |
   | `xiuwei` | 修为 | progress | false | breakthrough |
   | `lingshi` | 灵石 | currency | false | ascension |
   | `herb` | 药材 | material | true | ascension |
   | `exp` | 战斗经验 | progress | false | breakthrough |

   砍掉的资源：`mana / ore / pill / fortune / karma / sect_contribution`——MVP 闭环不需要；新增条目仅需追加配置，不改代码。

9. **初始化方式**：游戏启动时通过数据配置系统读取 `resource_config.json`，对每条定义调用 `register(definition)`。`current` 初始化为 ZERO（除非存档恢复），`cap` 由配置提供初始值，运行时通过存储上限系统的 `set_max()` 更新。**不支持运行时动态新增资源类型**——避免 God Object 风险，新资源类型在配置表添加后重启生效。

10. **序列化（存档快照）**：`snapshot()` 返回 Dictionary：
    ```
    { "version": 1, "resources": { id: { "current": BigNumber.to_dict(), "cap": BigNumber.to_dict() } } }
    ```
    仅持久化 `current` 和 `cap`；`category`、`reset_scope`、`has_cap` 来自配置（运行时变更视为重启失效）。`restore()` 对每条资源**严格按顺序**调用：**先 `set_max(id, saved_cap)`，再 `set_value(id, saved_current)`**——否则 `set_value` 的钳位会以旧 cap 为基准，导致 current 被错误截断。遇到配置中不存在的 ID 跳过并打印警告（兼容存档迁移）。

11. **重置语义（4 级有序包含）**：`reset_by_scope(scope)` 重置所有 `reset_scope` **位于 scope 包含范围内**的资源。包含关系：
    ```
    reset_by_scope("none")          → 不重置任何资源（恒等操作）
    reset_by_scope("breakthrough")  → 重置 reset_scope == "breakthrough" 的资源
    reset_by_scope("ascension")     → 重置 reset_scope ∈ {"breakthrough", "ascension"}
    reset_by_scope("rebirth")       → 重置 reset_scope ∈ {"breakthrough", "ascension", "rebirth"}
    ```
    `reset_scope == "none"` 的资源**永不被重置**（成就、轮回次数等）。每条归零操作触发对应的 `resource.{id}.changed` 事件。MVP 不实现突破/飞升/轮回逻辑，但字段已就绪供后续系统调用。

12. **输入校验**（安全降级，不崩溃）：
    - `id` 不存在：`get_value` 返回 ZERO；`add`/`spend`/`set_value`/`set_max` 打印警告并 no-op
    - `amount = ZERO` 用于 `add`/`spend`：直接返回（不操作，不发布事件）。**`set_value(id, ZERO)` 是合法操作**（强制清零），不命中此 no-op 规则——仍执行钳位、计算 delta 并发布事件
    - `new_cap = ZERO`：`set_max` 拒绝并打印警告（上限为 0 无游戏意义）
    - 重复 `register` 同一 ID：返回 `false`，不覆盖现有条目
    - 无效 `scope`（不在 4 级枚举内）：`reset_by_scope` 返回 0 并打印警告

13. **`batch_add` 非原子语义**：对每对 `{id: amount}` **顺序执行** `add()`，返回每条实际加入量。**显式声明非原子**——某条 ID 无效不影响其他条目，已执行的 add 不回滚。离线结算和 MVP 不需要原子性；如未来交易系统需要原子操作，应另行设计。**重复 id 处理**：`changes` Dictionary 中同一 id 只执行一次 add（GDScript Dictionary 键唯一性）；如需对同一资源多次累加，调用方应在传入前自行合并 amount。

### States and Transitions

ResourceSystem 整体**无状态机**——纯 CRUD 服务。单个资源条目存在三个隐式数值状态，由查询方自行判断（ResourceSystem 不主动跟踪、不广播状态转换）：

```
[Below Cap]  ←──add──→  [At Cap]
     ↑                      │
     └──────spend───────────┘
                 ↓
           [At Zero]  ←── reset_by_scope / spend to zero
```

| 状态 | 判定 | 含义 |
|------|------|------|
| At Zero | `current.is_zero() == true` | 无可用资源，`spend` 必然拒绝 |
| Below Cap | `current > ZERO` 且 (`current < cap` 或 `has_cap=false`) | 正常区间，`add`/`spend` 均可执行 |
| At Cap | `has_cap=true` 且 `current.equals(cap)` | 再次 `add` 实际加入量为 ZERO + 触发 overflow 事件 |

> 这三个状态对 HUD 系统和自动产出系统有实际意义（At Cap 时产出浪费），但 ResourceSystem 不主动广播状态转换——查询方通过 `resource.{id}.changed` 事件的 `new_value` 与 `get_max()` 比较自行推断，或订阅 `resource.{id}.overflow` 直接获知溢出。

### Interactions with Other Systems

| 系统 | 方向 | 数据接口 | 说明 |
|------|------|---------|------|
| 大数值系统 | 上游依赖 | 所有 `current`/`cap` 存储为 `BigNumber`；调用 `add/subtract/compare/min/is_zero/to_dict/from_dict` | ResourceSystem 无法脱离 BigNumber 独立工作 |
| 事件总线 | 上游依赖 | 调用 `EventBus.emit("resource.{id}.changed", payload)` 等 3 类事件 | Foundation 已完成；ResourceSystem 只发布不订阅 |
| 数据配置系统 | 上游依赖 | 启动时读取 `resource_config.json`，批量 `register()` | 配置表定义全部资源 ID、category、has_cap、reset_scope、初始 cap |
| 存储上限系统 | 下游 → 主动调用 | `ResourceSystem.set_max(id, new_cap)` | 上限计算由存储上限系统负责；ResourceSystem 只存储结果 |
| 自动产出系统 | 下游 → 主动调用 | 每 tick `add(id, tick_amount)` | 产出量由自动产出系统计算（含修正器结果）后传入 |
| 修炼系统 | 下游 → 主动调用 | `add("lingqi", amount)` / `add("xiuwei", amount)` | 修炼收益由修炼系统计算后写入 |
| 修正器/倍率引擎 | 无直接关联 | — | ResourceSystem 不调用 ModifierEngine；产出乘数在调用方传入 amount 前已应用 |
| 公式引擎 | 无直接关联 | — | ResourceSystem 不调用 FormulaEngine；公式由产出乘数系统/存储上限系统等中介使用 |
| 离线收益结算系统 | 下游 → 主动调用 | `batch_add({id: offline_total})` | 离线总量由结算系统用时间戳差值计算后一次性写入 |
| HUD 系统 | 下游 → 订阅 | 订阅 `resource.{id}.changed` / `cap_changed` / `overflow` | HUD 被动接收变更，不轮询 |
| 调试控制台 | 下游 → 只读查询 | `get_all_ids()` / `get_value(id)` / `get_max(id)` / `get_definition(id)` | `res list` 命令只读展示资源账本；不提供写命令 |
| 战斗计算器/半自动战斗 | 下游 → 主动调用 | `spend(id, cost)` 检查返回值；`add(id, drop)` | spend 返回 false 时调用方自行处理（如跳过技能） |
| 物品/材料系统 | 边界协作 | 可叠加同质化材料（如 herb）走 ResourceSystem；离散有词条/品质实体（装备、特殊丹药）走 item 系统 | 边界由物品/材料系统 GDD 进一步明确；本 GDD 只承诺 herb 类同质材料的能力 |
| 存档系统 | 下游 → 主动调用 | 存档调用 `snapshot()`；读档调用 `restore(data)` | ResourceSystem 提供纯数据快照，存档系统负责文件 I/O |
| 境界突破/飞升/轮回系统（Post-MVP） | 下游 → 主动调用 | `reset_by_scope(scope)` 传入对应 scope | ResourceSystem 仅按 scope 归零，不判断哪些资源该重置 |

## Formulas

### 1. 实际增加量（add 路径，有上限） (Actual Added Amount — Capped Path)

`actual_added(current, cap, amount) = clamp(amount, ZERO, cap - current)`

**变量：**
| 变量 | 符号 | 类型 | 范围 | 说明 |
|------|------|------|------|------|
| current | c | BigNumber | [ZERO, cap] | 操作前资源当前值 |
| cap | M | BigNumber | [ZERO, MAX] | 资源上限（`has_cap=true` 时有效） |
| amount | a | BigNumber | [ZERO, MAX] | 请求增加的量 |
| actual_added | r | BigNumber | [ZERO, cap-current] | 实际入账量 |

**输出范围：** `[ZERO, cap-current]`。`has_cap=false` 时退化为 `actual_added = amount`（仅受 `BigNumber.MAX` 钳位）。

**示例：** 灵气 current=800, cap=1000, amount=300 → `actual_added = clamp(300, 0, 200) = 200`

### 2. add 路径溢出量 (Add Path Overflow)

`add_overflow(amount, actual_added) = amount - actual_added`

**变量：**
| 变量 | 符号 | 类型 | 范围 | 说明 |
|------|------|------|------|------|
| amount | a | BigNumber | [ZERO, MAX] | 请求增加的量 |
| actual_added | r | BigNumber | [ZERO, a] | 公式 1 的结果 |
| add_overflow | ov | BigNumber | [ZERO, a] | 被上限截断的损失量 |

**输出范围：** `[ZERO, amount]`。`add_overflow > ZERO` 时触发 `resource.{id}.overflow` 事件。`has_cap=false` 时永远为 ZERO。

**示例（续上例）：** `add_overflow = 300 - 200 = 100`

### 3. spend 准入判定 (Spend Eligibility)

`spend_allowed(current, amount) = current.greater_or_equal(amount)`

**变量：**
| 变量 | 符号 | 类型 | 范围 | 说明 |
|------|------|------|------|------|
| current | c | BigNumber | [ZERO, MAX] | 操作前资源当前值 |
| amount | a | BigNumber | [ZERO, MAX] | 请求扣减的量 |
| spend_allowed | — | bool | {true, false} | 是否允许执行 spend |

**输出范围：** 布尔值。**spend 是"全有或全无"**——与 `add` 的钳位语义不对称：返回 `true` 时 `current ← current - amount`，返回 `false` 时 `current` 不变、不发布事件。

**示例：** current=500, amount=300 → `true`，扣减后 current=200；amount=600 → `false`，current 保持 500。

### 4. set_max 截断 (Set-Max Truncation)

`new_current(old_current, new_cap) = BigNumber.min(old_current, new_cap)`

`set_max_overflow(old_current, new_cap) = max(ZERO, old_current - new_cap)`

**变量：**
| 变量 | 符号 | 类型 | 范围 | 说明 |
|------|------|------|------|------|
| old_current | c₀ | BigNumber | [ZERO, MAX] | set_max 调用前 current 值 |
| new_cap | M' | BigNumber | (ZERO, MAX] | 新上限（ZERO 时被拒绝，见 Edge Cases） |
| new_current | c₁ | BigNumber | [ZERO, M'] | set_max 后 current 值 |
| set_max_overflow | ov_c | BigNumber | [ZERO, c₀] | 由上限收缩导致的 current 损失量 |

**输出范围：** `new_current ∈ [ZERO, new_cap]`；`set_max_overflow ∈ [ZERO, old_current]`。**当 `set_max_overflow > ZERO` 时，事件按顺序发布：先 `resource.{id}.cap_changed`，再 `resource.{id}.changed`，最后 `resource.{id}.overflow`**——HUD 可在 cap 刷新后再展示溢出提示。

**示例：** old_current=800, new_cap=500 → new_current=500, set_max_overflow=300

### 5. 重置作用域包含判断 (Reset Scope Inclusion)

`should_reset(resource_scope, requested_scope) = (rank(resource_scope) ≥ 1) AND (rank(resource_scope) ≤ rank(requested_scope))`

**作用域秩映射：**

| 作用域 | 秩 |
|-------|----|
| `none` | 0 |
| `breakthrough` | 1 |
| `ascension` | 2 |
| `rebirth` | 3 |

**变量：**
| 变量 | 符号 | 类型 | 范围 | 说明 |
|------|------|------|------|------|
| resource_scope | s_r | int（枚举秩） | [0, 3] | 资源定义的重置作用域 |
| requested_scope | s_q | int（枚举秩） | [0, 3] | 当前触发的重置范围 |
| should_reset | — | bool | {true, false} | 该资源是否在本次重置中被清零 |

**输出范围：** 布尔值。`rank=0`（`none`）的资源永不被重置；`requested_scope=none`（秩 0）时无任何资源被重置（恒等操作）。

**示例：**
- 药材（`breakthrough`，秩 1），requested=`ascension`（秩 2）→ `1≥1 AND 1≤2` → `true`，被清零
- 灵石（`ascension`，秩 2），requested=`breakthrough`（秩 1）→ `2≤1` 为 false → `false`，保留
- 成就计数（`none`，秩 0），requested=`rebirth`（秩 3）→ `0≥1` 为 false → `false`，永不重置

### 6. 单次 add/spend 操作耗时 (Single Operation Cost)

`op_time = t_lookup + t_bn_op + t_cap_check + t_event`

**变量：**
| 变量 | 符号 | 类型 | 范围（ms） | 说明 |
|------|------|------|-----------|------|
| 字典查找耗时 | t_lookup | float | [0.001, 0.005] | Dictionary 按 id 查找条目 |
| BigNumber 运算耗时 | t_bn_op | float | [0.001, 0.010] | 单次 BigNumber add/subtract（含归一化） |
| 上限检查耗时 | t_cap_check | float | [0.001, 0.005] | compare()+clamp；`has_cap=false` 时 ≈ 0.001 |
| 事件发布耗时 | t_event | float | [0, 0.026] | EventBus emit（delta=ZERO 时为 0；5 订阅者基准 ≈ 0.026） |

**输出范围：** `[0.003, 0.046]` ms。最快路径：无上限 + delta=ZERO → ≈ 0.003 ms；最慢路径：有上限 + 5 订阅者 → ≈ 0.046 ms。

**示例（典型）：** has_cap=true, 3 订阅者：`op_time = 0.002 + 0.005 + 0.003 + 0.026 = 0.036 ms`

### 7. batch_add 批量操作耗时 (Batch Add Cost)

`batch_time(N) = N × t_op_avg + t_batch_overhead`

**变量：**
| 变量 | 符号 | 类型 | 范围 | 说明 |
|------|------|------|------|------|
| 条目数量 | N | int | [1, 30] | 本批次涉及的不同 id 数量（MVP=5，扩展预留 30） |
| 平均单操作耗时 | t_op_avg | float | [0.003, 0.046] ms | 公式 6，典型 0.020 ms |
| 批量控制开销 | t_batch_overhead | float | [0.001, 0.005] ms | 循环、日志、批次结束总结 |

**输出范围：** 与 N 线性正比。MVP 全量批更新（5 资源）：`5 × 0.020 + 0.002 = 0.102 ms`。

**示例（离线结算）：** 5 资源全部 +增量并触发事件：`5 × 0.025 + 0.003 = 0.128 ms`，远低于帧预算。

### 8. 资源系统帧预算分配 (Frame Budget Allocation)

`resource_budget = t_frame × budget_ratio`

**变量：**
| 变量 | 符号 | 类型 | 范围 | 说明 |
|------|------|------|------|------|
| 单帧时间 | t_frame | float | 16.67 ms | 60 fps |
| 帧预算占比 | budget_ratio | float | [0.01, 0.05] | 资源系统帧时间占用比 |

**推荐值：** `budget_ratio = 0.02` → `resource_budget = 0.333 ms/frame`

在此预算下，每帧最多可执行：`floor(0.333/0.036) ≈ 9` 次有上限+事件的 add；纯无事件路径可达 `floor(0.333/0.003) ≈ 111` 次。放置游戏中资源系统的实际调用频率约为每 tick（≥0.5s）一次，预算充裕。

### 9. 单条资源内存占用 (Memory per Entry)

`entry_size = dict_overhead + 2 × bn_size + metadata_size`

**变量：**
| 变量 | 符号 | 类型 | 范围（bytes） | 说明 |
|------|------|------|-------------|------|
| Dictionary 基础开销 | dict_overhead | int | ~64 | GDScript Dictionary 对象头 |
| BigNumber 实例大小 | bn_size | int | ~40 | 1 float + 1 int + 对象头 |
| 元数据大小 | metadata_size | int | ~56 | id（String）+ has_cap + reset_scope + category + 对齐 |

**输出范围：** ~200 bytes/条（不随数值大小变化）。

**MVP 预估（5 资源）：** `5 × 200 = 1 KB`。**扩展（100 资源）：** `100 × 200 = 20 KB`，远低于 512 MB 内存上限。

## Edge Cases

- **If `add(id, amount)` 的 `amount` 等于 `BigNumber.MAX` 且资源有上限**：`actual_added = clamp(MAX, ZERO, cap-current)`，最多填满至 cap，发布 `resource.{id}.overflow`。BigNumber 饱和算术保证 `cap-current` 不会下溢。
- **If `add(id, amount)` 的 `amount` 恰好等于 `cap-current`（精确填满）**：`actual_added = amount`，`add_overflow = ZERO`。发布 `resource.{id}.changed`，**不发布** `resource.{id}.overflow`。
- **If `amount` 是含 NaN/Inf 的 BigNumber**：BigNumber 层归一化时已钳位为 ZERO，命中"amount=ZERO 直接返回"规则，不操作、不发布事件。资源系统无需额外校验。
- **If 资源 `current` 已等于 `cap`（At Cap 状态）时调用 `add`**：`actual_added = ZERO`，**不发布** `resource.{id}.changed`（delta=ZERO 抑制）；但 `add_overflow = amount > ZERO`，**仍发布** `resource.{id}.overflow`，用于自动产出系统感知浪费。
- **If `spend` 将 `current` 精确扣减至 ZERO**：spend_allowed=true，正常发布 `resource.{id}.changed`，不发布 overflow。At Zero 是正常数值状态。
- **If `set_value(id, value)` 的 `value` 等于当前 `current`**：delta=ZERO，不发布 `resource.{id}.changed`。与 `add(ZERO)` 语义对称。
- **If `set_value(id, ZERO)`**：合法操作（强制清零），不命中"amount=ZERO no-op"规则。仍执行钳位、计算 delta、发布事件（如果 current ≠ ZERO）。
- **If `set_max(id, new_cap)` 的 `new_cap` 等于当前 `cap`**：不发布 `cap_changed`（cap 未实际变化）；整个调用静默 no-op。
- **If `set_max` 的 `new_cap` 大于 `old_current`（上限上调，无截断）**：`set_max_overflow = ZERO`。只发布 `cap_changed`，不发布 `changed` 和 `overflow`。
- **If `set_max` 的 `new_cap` 精确等于 `old_current`（恰好收缩至当前值）**：`set_max_overflow = ZERO`。只发布 `cap_changed`，不发布 `changed` 和 `overflow`。
- **If `set_max` 的 `new_cap` 小于 `old_current`（上限收缩触发截断）**：事件顺序严格为 ① `cap_changed` → ② `changed` → ③ `overflow`。HUD 必须先更新上限再更新当前值，避免"当前 > 上限"瞬态。
- **If `set_max` 的 `new_cap` 超过 `BigNumber.MAX`**：BigNumber 饱和钳位为 MAX。若 `MAX != old_cap`（之前未饱和），视为 cap 发生变化，发布 `resource.{id}.cap_changed`；若 `old_cap` 已为 MAX，则属于 `new_cap == old_cap` 的 no-op 路径，不发布事件。`has_cap=true` 时实质无界，流程正常。
- **If `batch_add` 输入 Dictionary 中同一 `id` 出现两次**：GDScript Dictionary 键唯一性导致后者覆盖前者，资源系统只执行一次 add。**调用方负责合并重复 id 的 amount**——本系统不做合并。
- **If 在 `resource.{id}.changed` 回调中调用 `spend(id, amount)`**：构成同名事件递归 emit，被 EventBus 阻断；spend 的数值修改**已执行**但事件不投递，订阅者将看到 current 已变更但未收到对应事件。**调用方应避免在资源事件回调中修改同一资源**。
- **If 在 `resource.{id}.changed` 回调中调用 `subscribe`**：EventBus 缓存到待处理队列，当前 emit 完成后批量生效。新订阅者从下一次 emit 起收到事件。
- **If `reset_by_scope("none")`**：rank("none")=0，无资源满足 `rank(s_r) ≥ 1 AND ≤ 0`，返回 0，不修改、不发事件。幂等空操作。
- **If `reset_by_scope` 命中的资源 `current` 已为 ZERO**：目标值 ZERO，delta=ZERO，不发布 `resource.{id}.changed`；但仍计入返回值的"被重置资源数"。
- **If `reset_by_scope("rebirth")` 命中 5 条 MVP 资源**：同帧顺序投递 5 次事件，总耗时约 0.13 ms（5 订阅者基准），远低于帧预算 0.333 ms。资源规模扩至 50+ 时应考虑引入 `emit_deferred` 降峰。
- **If `snapshot()` 在 `resource.{id}.changed` 回调内被调用**：snapshot 是纯只读操作，捕获事件已写入后的状态。存档系统在事件中触发快照所得结果与正常路径一致。
- **If `restore(data)` 中存在配置文件不含的 `id`**：跳过该条目并打印警告，继续处理。不中断恢复，不崩溃。被跳过的 id 维持初始 ZERO 值。
- **If `restore(data)` 中存档 BigNumber 字典缺少 `m` 或 `e` 字段（存档损坏）**：BigNumber.from_dict 返回 ZERO，restore 写入 ZERO 并打印警告。降级处理，不崩溃。
- **If `restore(data)` 中存档 `cap` 小于存档 `current`（数据异常）**：restore 严格按"先 set_max 再 set_value"顺序执行（见 Core Rules #10），确保 set_value 的钳位以存档 cap 为基准。
- **If `restore(data)` 执行期间产生事件**：restore 期间**不抑制**事件——每条资源的 `set_max + set_value` 各自按常规规则发布事件（cap 变更则 `cap_changed`，current 变更则 `changed`，截断则 `overflow`）。理由：HUD 应反映读档后的最终状态，事件抑制会导致 HUD 不刷新；读档少见，瞬态事件抖动可接受。如未来需要"读档静音模式"以避免 UI 抖动，由调用方（存档系统）在 restore 前后批量挂起 HUD 订阅。

## Dependencies

### 上游依赖

| 系统 | 依赖性质 | 数据接口 |
|------|---------|---------|
| **大数值系统** (BigNumber) | 硬依赖 | 所有 `current` 和 `cap` 存储为 `BigNumber` 实例；调用 `add/subtract/compare/min/is_zero/equals/less_than/greater_or_equal/to_dict/from_dict`。资源系统无法脱离 BigNumber 独立工作 |
| **事件总线** (EventBus) | 硬依赖 | 调用 `EventBus.emit()` 发布 3 类事件：`resource.{id}.changed` / `resource.{id}.cap_changed` / `resource.{id}.overflow`。资源系统**只发布不订阅** |
| **数据配置系统** | 硬依赖 | 启动时读取 `resource_config.json`，对每条定义调用 `register()`。配置定义全部资源 ID、category、has_cap、reset_scope、初始 cap |

### 下游消费者

| 系统 | 调用方向 | 数据接口 | 备注 |
|------|---------|---------|------|
| **存储上限系统** | 主动调用 | `ResourceSystem.set_max(id, new_cap)` | 上限计算由存储上限系统负责；本系统只存储结果 |
| **自动产出系统** | 主动调用 | 每 tick `add(id, tick_amount)` | 产出量由自动产出系统在调用前计算好（含修正器结果） |
| **修炼系统** | 主动调用 | `add("lingqi", amount)` / `add("xiuwei", amount)` | 修炼收益由修炼系统计算后写入 |
| **战斗计算器/半自动战斗** | 主动调用 | `spend(id, cost)` 检查返回值；`add(id, drop)` | spend 返回 false 时调用方自行处理（如跳过技能） |
| **离线收益结算系统** | 主动调用 | `batch_add({id: offline_total})` | 离线总量由结算系统用时间戳差值计算后一次性写入 |
| **HUD 系统** | 订阅 | 订阅 `resource.{id}.changed` / `cap_changed` / `overflow` | HUD 被动接收变更，不轮询 |
| **物品/材料系统** | 边界协作 | 同质化材料（如 `herb`）走 ResourceSystem；离散有词条/品质实体（装备、特殊丹药）走 item 系统 | 边界由物品/材料系统 GDD 进一步明确 |
| **存档系统** | 主动调用 | 存档 `snapshot()`；读档 `restore(data)` | 本系统提供纯数据快照，存档系统负责文件 I/O |
| **境界突破/飞升/轮回系统** (Post-MVP) | 主动调用 | `reset_by_scope(scope: String)` 传入 4 级枚举之一 | 本系统按 scope 归零，不判断哪些资源该重置 |

### 关键非依赖（容易误以为是依赖但不是）

| 系统 | 关系 | 说明 |
|------|------|------|
| **修正器/倍率引擎** (ModifierEngine) | **无直接关联** | 资源系统**不调用** ModifierEngine。产出乘数由调用方（自动产出系统/修炼系统/产出乘数系统）在传入 amount 前应用，本系统只存最终值 |
| **公式引擎** (FormulaEngine) | **无直接关联** | 资源系统**不调用** FormulaEngine。公式由产出乘数系统、存储上限系统等中介使用 |

### 双向一致性自检（与上游 GDD 对齐）

- ✅ **BigNumber GDD** §Interactions 列出"资源系统 — 所有资源值存储为 BigNumber"——一致
- ✅ **EventBus GDD** §Interactions 列出"资源系统 — 发布 `resource.{id}.changed`"——一致；本 GDD 额外引入的 `cap_changed` 和 `overflow` 两个事件也已在 EventBus GDD §12 命名空间约定中列出
- ⚠ **ModifierEngine GDD** §Interactions 列出"资源系统 — 调用 `apply("lingqi_production", base)` 计算最终产出"——**与本 GDD 不一致**。本 GDD 明确资源系统**不**调用 ModifierEngine（避免 God Object，由调用方/产出乘数系统中介）。需在 `/consistency-check` 阶段更新 ModifierEngine GDD 的 Interactions 表，将"资源系统"行改为"产出乘数系统"
- ⚠ **FormulaEngine GDD** §Interactions 列出"资源系统 — 调用公式引擎计算产出倍率/消耗系数"——**与本 GDD 不一致**。同上理由：资源系统不直接调用 FormulaEngine。需在 `/consistency-check` 阶段更新 FormulaEngine GDD 的 Interactions 表

## Tuning Knobs

资源系统的可调参数分为两类：**配置驱动参数**（per-resource，由数据配置系统加载）和**引擎/调试参数**（编译期或开发模式专用）。

### 配置驱动参数（资源条目级别，per-resource）

| 参数 | 类型 | 默认值 | 安全范围 | 调整影响 |
|------|------|--------|---------|---------|
| `has_cap` | bool | 由 category 决定（regenerative/material → true；currency/progress → false） | {true, false} | true 时资源会因上限钳位丢失溢出量；false 时仅受 BigNumber.MAX 约束（实质无界） |
| `cap`（初始值） | BigNumber | 由配置提供，建议起始值 1e3 ~ 1e6 | [BigNumber.from_int(100), BigNumber.MAX] | 影响 At Cap 触发频率；过低导致玩家频繁感到瓶颈，过高使储存上限系统失去意义 |
| `category` | enum | 必填 | {currency, material, progress, regenerative} | 决定 has_cap 默认行为和 HUD 默认呈现风格（细节由 HUD GDD 定义） |
| `reset_scope` | enum | 必填 | {none, breakthrough, ascension, rebirth} | 决定该资源在何种重置事件中被清零；4 级有序包含 |

### 引擎/调试参数（全局，开发期或编译期常量）

| 参数 | 默认值 | 安全范围 | 增大影响 | 减小影响 |
|------|--------|---------|---------|---------|
| `RESOURCE_BUDGET_RATIO` | 0.02 | [0.01, 0.05] | 资源系统获得更多帧时间预算，允许更高频调用 | 更严格的性能限制；过严可能导致离线结算批量更新触发卡顿 |
| `WARN_ON_MISSING_ID` | true | {true, false} | 调用未注册 id 时打印警告，辅助调试 | 静默 no-op，减少日志噪音（生产构建可关闭） |
| `WARN_ON_INVALID_INPUT` | true | {true, false} | new_cap=ZERO、duplicate register、无效 scope 等情况打印警告 | 静默拒绝，减少日志噪音 |
| `WARN_ON_RESTORE_MISMATCH` | true | {true, false} | restore 时遇到配置中不存在的 id、损坏的 BigNumber 字典等情况打印警告 | 静默跳过，便于版本迁移 |
| `OVERFLOW_EVENT_ENABLED` | true | {true, false} | true 时溢出触发独立 `resource.{id}.overflow` 事件 | false 时只有常规 `changed` 事件，HUD 无法专门处理"仓库已满"提示（仅调试用，生产推荐 true） |
| `MAX_BATCH_SIZE` | 30 | [10, 100] | 允许 batch_add 单次处理更多资源条目 | 限制批量大小，防止异常输入；超过此值时截断并打印警告 |

### 设计师 vs 开发者调参边界

- **配置驱动参数**通过 `resource_config.json` 修改，由**数值设计师**调整。新增资源类型只需追加一条配置（重启生效）
- **引擎/调试参数**是项目级常量或开发模式开关，由**开发者**在实现阶段设定，运行时不应动态修改
- **资源初始 cap 值**虽属配置驱动，但其增长曲线由存储上限系统的 GDD 定义；本 GDD 仅承诺"接受存储上限系统通过 `set_max()` 写入的值"

### 与依赖系统的调参分工

| 调参对象 | 负责系统 | 说明 |
|---------|---------|------|
| 资源初始 cap 值 | 资源系统（首次注册）→ 存储上限系统（运行时升级） | 资源系统提供初始默认；存储上限系统接管成长 |
| 资源产出速率 | 修炼系统/自动产出系统 | 本系统不持有产出参数 |
| 产出乘数（装备/技能/Buff 等） | 修正器/倍率引擎 + 产出乘数系统 | 本系统不持有乘数参数 |
| 重置触发条件（境界等级、飞升前置） | 突破/飞升/轮回系统（Post-MVP） | 本系统只接受 reset_by_scope 调用，不判断触发时机 |

## Acceptance Criteria

### Core CRUD

- [ ] **GIVEN** `ResourceSystem` 已加载，`resource_config.json` 包含 `lingqi/xiuwei/lingshi/herb/exp` 五条定义，**WHEN** 游戏启动完成，**THEN** `get_all_ids()` 返回恰好包含这 5 个 id 的 Array，且每条资源 `current == BigNumber.ZERO`
- [ ] **GIVEN** 调用 `register({id: "lingqi", category: "regenerative", has_cap: true, reset_scope: "breakthrough", cap: BigNumber.from_int(1000)})` 成功，**WHEN** 再次调用相同 id 的 register，**THEN** 返回 `false`，已有条目不变
- [ ] **GIVEN** `lingqi` current=`BigNumber.from_int(800)`，cap=`BigNumber.from_int(1000)`，**WHEN** `add("lingqi", BigNumber.from_int(150))`，**THEN** 返回 `BigNumber.from_int(150)`，`get_value("lingqi") == BigNumber.from_int(950)`
- [ ] **GIVEN** `lingqi` current=`BigNumber.from_int(800)`，cap=`BigNumber.from_int(1000)`，**WHEN** `add("lingqi", BigNumber.from_int(300))`，**THEN** 返回 `BigNumber.from_int(200)`（钳位），`get_value == BigNumber.from_int(1000)`
- [ ] **GIVEN** `lingshi` current=`BigNumber.from_int(500)`（has_cap=false），**WHEN** `add("lingshi", BigNumber.from_int(9999))`，**THEN** 返回 `BigNumber.from_int(9999)`，`get_value == BigNumber.from_int(10499)`
- [ ] **GIVEN** `herb` current=`BigNumber.from_int(300)`，**WHEN** `spend("herb", BigNumber.from_int(300))`，**THEN** 返回 `true`，`get_value == BigNumber.ZERO`
- [ ] **GIVEN** `herb` current=`BigNumber.from_int(300)`，**WHEN** `spend("herb", BigNumber.from_int(301))`，**THEN** 返回 `false`，`get_value` 仍为 `BigNumber.from_int(300)`，EventBus 未收到 `resource.herb.changed`
- [ ] **GIVEN** `lingqi` current=`BigNumber.from_int(600)`，cap=`BigNumber.from_int(1000)`，**WHEN** `set_value("lingqi", BigNumber.from_int(200))`，**THEN** `get_value == BigNumber.from_int(200)`
- [ ] **GIVEN** `get_value("nonexistent_id")`，**WHEN** 该 id 从未注册，**THEN** 返回 `BigNumber.ZERO`，不抛异常
- [ ] **GIVEN** 5 资源已注册，changes=`{lingqi: 100, herb: 50, exp: 200}`，**WHEN** `batch_add(changes)`，**THEN** 返回 Dictionary 含 3 键，每条 actual_added 与预期一致

### Events

- [ ] **GIVEN** `lingqi` current=`BigNumber.from_int(500)`，**WHEN** `add("lingqi", BigNumber.from_int(100))`，**THEN** EventBus 发布一次 `resource.lingqi.changed`，payload 中 old=500、new=600、delta=100
- [ ] **GIVEN** `lingqi` current=`BigNumber.from_int(900)`，cap=`BigNumber.from_int(1000)`，**WHEN** `add("lingqi", BigNumber.from_int(200))`，**THEN** 发布 `changed`（delta=100）+ `overflow`（attempted=200, actual=100, lost=100）
- [ ] **GIVEN** `lingqi` current==cap==`BigNumber.from_int(1000)`，**WHEN** `add("lingqi", BigNumber.from_int(50))`，**THEN** 返回 ZERO，**不**发布 `changed`，**仍**发布 `overflow`（lost=50）
- [ ] **GIVEN** `add` 或 `spend` 的 amount=`BigNumber.ZERO`，**WHEN** 调用，**THEN** `get_value` 不变，EventBus 不发布任何事件
- [ ] **GIVEN** `herb` current=`BigNumber.from_int(100)`，**WHEN** `spend("herb", BigNumber.from_int(100))`，**THEN** 返回 true，发布 `changed`（new=ZERO），**不**发布 overflow

### set_max

- [ ] **GIVEN** `lingqi` cap=1000, current=600，**WHEN** `set_max("lingqi", BigNumber.from_int(2000))`，**THEN** `get_max==2000`，`get_value` 不变，仅发布 `cap_changed`，不发布 `changed/overflow`
- [ ] **GIVEN** `lingqi` cap=1000, current=800，**WHEN** `set_max("lingqi", BigNumber.from_int(500))`，**THEN** `get_value==500`，事件顺序严格为 ① `cap_changed` → ② `changed` → ③ `overflow`（lost=300）
- [ ] **GIVEN** `lingqi` cap=1000，**WHEN** `set_max("lingqi", BigNumber.from_int(1000))`（与现 cap 相同），**THEN** EventBus 不发布任何事件，调用静默 no-op
- [ ] **GIVEN** `set_max("lingqi", BigNumber.ZERO)`，**WHEN** 执行，**THEN** 拒绝，`get_max` 不变，打印警告
- [ ] **GIVEN** `lingqi` cap=1000，**WHEN** `set_max("lingqi", new_cap)` 其中 new_cap 超过 BigNumber.MAX，**THEN** 实际存储 `cap == BigNumber.MAX`，发布 `cap_changed`（视为 cap 发生变化）

### Reset

- [ ] **GIVEN** MVP 5 资源均有非零 current，**WHEN** `reset_by_scope("breakthrough")`，**THEN** 返回 3（lingqi/xiuwei/exp 被重置；reset_scope=breakthrough 的全部 3 项），`lingshi/herb` 不变
- [ ] **GIVEN** MVP 5 资源均有非零 current，**WHEN** `reset_by_scope("rebirth")`，**THEN** 返回 5，所有资源 current==ZERO，同帧投递 5 次 `changed` 事件，总耗时 < 0.333 ms
- [ ] **GIVEN** 任意状态，**WHEN** `reset_by_scope("none")`，**THEN** 返回 0，所有 current 不变，不发布事件
- [ ] **GIVEN** 无效 scope `"transcend"`，**WHEN** `reset_by_scope("transcend")`，**THEN** 返回 0，所有 current 不变，打印警告
- [ ] **GIVEN** `xiuwei` current==ZERO 且 reset_scope=breakthrough，**WHEN** `reset_by_scope("breakthrough")`，**THEN** 该资源计入返回的重置数量，但**不**发布 `changed`（delta=ZERO 抑制）

### Snapshot / Restore

- [ ] **GIVEN** `lingqi` current=500/cap=1000；`lingshi` current=2000（has_cap=false），**WHEN** `snapshot()`，**THEN** 返回 `{version:1, resources: {lingqi:{current:{...},cap:{...}}, ...}}` 可被 `BigNumber.from_dict` 还原
- [ ] **GIVEN** snapshot 数据中 `lingqi.cap=1000, lingqi.current=800`，初始注册 cap=500，**WHEN** `restore(data)`，**THEN** `get_max==1000` 且 `get_value==800`（验证 set_max 在 set_value 之前执行——否则 current 会被旧 cap 500 截断）
- [ ] **GIVEN** `restore(data)` 含未在配置中的 id `"ancient_ore"`，**WHEN** 调用，**THEN** 跳过该条目并打印警告，其他 5 资源正常恢复，不崩溃
- [ ] **GIVEN** `restore(data)` 中 `herb.current` 缺少 `"e"` 字段（存档损坏），**WHEN** 调用，**THEN** `get_value("herb")==ZERO`，打印警告，不崩溃

### Edge Cases

- [ ] **GIVEN** `lingqi` current=400, cap=1000，**WHEN** `add("lingqi", BigNumber.from_int(600))`（精确填满），**THEN** 返回 600，`get_value==1000`，发布 `changed`，**不**发布 `overflow`
- [ ] **GIVEN** `lingqi` current=200，**WHEN** `set_value("lingqi", BigNumber.ZERO)`，**THEN** `get_value==ZERO`，发布 `changed`（delta=-200），不被 amount=ZERO no-op 拦截

### Performance / Memory

- [ ] **GIVEN** `lingqi` has_cap=true，5 个订阅者，**WHEN** 单帧 100 次 `add("lingqi", BigNumber.from_int(1))`，**THEN** 总耗时 < 0.333 ms（帧预算）
- [ ] **GIVEN** MVP 5 资源已注册，changes 含 5 条增量，**WHEN** `batch_add(changes)`，**THEN** 总耗时 < 0.15 ms
- [ ] **GIVEN** `get_all_ids().size()==5`，**WHEN** 内存采样，**THEN** ResourceSystem 总占用 < 2 KB

## Open Questions

| Question | Owner | Deadline | Resolution |
|----------|-------|----------|-----------|
| 物品/材料系统边界——本 GDD 假定可叠加同质化材料（如 herb）走 ResourceSystem、离散有词条/品质实体走 item 系统，但具体边界由"物品/材料系统"GDD 拍板。如发生归类争议，可能需要将 herb 从 ResourceSystem 迁出 | 设计师 | 物品/材料系统 GDD 时 | — |
| ModifierEngine GDD §Interactions 列出"资源系统调用 apply()"，与本 GDD 不一致——需在 `/consistency-check` 阶段把 ModifierEngine 的 Interactions 改为"产出乘数系统调用 apply()" | 设计师 | `/consistency-check` 阶段 | ✅ 已解决 2026-05-03 — modifier-engine.md §Interactions(line 122) 和 §Dependencies(line 266) 两处"资源系统"已改为"产出乘数系统" |
| FormulaEngine GDD §Interactions 列出"资源系统调用 evaluate"，与本 GDD 不一致——需在 `/consistency-check` 阶段把 FormulaEngine 的 Interactions 改为"产出乘数系统/存储上限系统调用 evaluate" | 设计师 | `/consistency-check` 阶段 | ✅ 已解决 2026-05-03 — formula-engine.md §Interactions(line 121) 和 §Dependencies(line 231) 两处"资源系统"已改为"产出乘数系统/存储上限系统" |
| EventBus GDD §12 命名空间约定中列出 `cap_changed` 和 `overflow` 两个资源事件 | 开发者 | 实现阶段前 | ✅ 已解决 2026-05-03 — event-bus.md 已追加 `resource.{id}.cap_changed` 和 `resource.{id}.overflow` 命名空间 |
| 5 条 MVP 资源的初始 cap 具体数值（lingqi 起始 1e3 还是 1e4？herb 起始多少？）由数值设计师拍板，依赖于存储上限系统的成长公式 | 数值设计师 | 存储上限系统 GDD 时 | — |
| `resource_config.json` 的具体文件位置（`assets/data/` 下何处？）和格式版本号约定，依赖于数据配置系统 GDD | 开发者 | 数据配置系统 GDD 时 | — |
| 是否需要 `resource.*.changed` 这种通配符订阅（订阅所有资源变化、无需逐 id 订阅）以减少订阅样板代码？取决于 EventBus 是否实现通配符订阅（其 Open Questions 中已列） | 设计师 | HUD 系统 GDD 时 | — |
| **reset_scope 4→5 级扩展**（追加 `heyi`/合道作为最高重置层，对应游戏概念 §4.5 的"合道"）+ Post-MVP 资源（气运 fortune、因果 karma、宗门贡献 sect_contribution）的 category 归属与 reset_scope 归类。`karma` 的语义是"跨 rebirth 保留、仅 heyi 重置"——直接驱动枚举从 4 级扩到 5 级。可能还需新增 `reputation` 或 `karma` category 类别。这两个问题强耦合：扩展 reset_scope 时必须同步设计 karma/fortune 归类，否则 4.5 多层重置链会断裂 | 设计师 | 合道系统 / 因果系统 GDD 时（最迟 Post-MVP 阶段 8 即长期重置） | — |
