# 修正器/倍率引擎 (Modifier/Multiplier Engine)

> **Status**: Designed
> **Author**: binlee1990 + agents
> **Last Updated**: 2026-05-03
> **Implements Pillar**: 4.1 数字增长就是快乐 · 4.10 数据驱动与可扩展

## Overview

修正器/倍率引擎是游戏中所有数值修正的统一管理、叠加和查询服务。游戏中任何"基础值 + 多个修正 → 最终值"的场景——装备加成、技能增幅、Buff/Debuff、境界加成、账号天赋、里程碑奖励、区域效果——都通过本引擎处理叠加逻辑，而不是在各系统中硬编码。

核心职责三件事：**注册**（各系统声明修正值、来源和类型）、**叠加**（按预定义数学顺序合并为最终系数）、**查询**（任意时刻获取某目标的最终修正结果）。本引擎不决定"这个 Buff 持续多久"或"装备加多少攻击"——这些由源系统负责。本引擎只管"把所有修正按规则算在一起"。

**叠加模型**采用三阶段管线：

1. **加法阶段**：所有 flat 加法修正（+100 攻击）先汇总
2. **乘法加算池**：百分比修正按池分组，同池内的修正先加总再乘（如三个 +10% 加成 → +30% → ×1.3）
3. **乘法乘算池**：独立乘区，每个修正单独相乘（×1.1 × 1.2 × 1.05）

加算池防止同类来源无限膨胀；乘算池让不同来源的乘区各自独立、奖励 Build 多样性。修正值统一为 `float`，最终结果通过 BigNumber 的 `multiply_float()` / `add()` 应用到基础值。公式引擎计算单个修正系数，本引擎管理多个修正的叠加顺序。

## Player Fantasy

修正器/倍率引擎是玩家看不见的丹田气海——所有加成在这里汇聚、叠加、共振，最终转化为屏幕上跳动的数字。

**锚定时刻**：玩家花了十分钟调整 Build——给剑修配了一套暴击装备（+30% 暴击率）、激活了攻击阵法（×1.5 伤害加成）、喂了队伍灵丹（+20% 全属性）、突破了炼气境（×2.0 灵气产出）。然后开始挂机——伤害数字从 500 跳到了 2100，灵气产出从每秒 1000 飙到了 4500。玩家打开属性面板逐项核对：装备的暴击率叠对了、阵法的加成独立乘算了、灵丹和境界的加成各在各的池子里没有互相吞掉。这种"每一份加成都被忠实计算、不同来源各司其职"的感觉，就是修正器引擎在背后保障的。

如果没有它，加成可能"差不多生效了"也可能"好像没生效"；同类加成可能意外加算导致收益递减，也可能意外乘算导致数值爆炸。有了它，玩家可以信任一个核心承诺：**描述写 ×1.5，实际就是 ×1.5；描述写 +10%，同类来源先加总再乘，不同来源独立乘——规则透明、可预测、可计划。**

这也意味着 Build 策略有深度：堆同一乘区（如全靠装备百分比）会遇到加算递减；跨多个乘区（装备 + 技能 + Buff + 境界）能获得乘算放大。玩家在配置界面的每一个选择都有数学意义。

支柱对应：
- **4.1 数字增长就是快乐**：修正器引擎确保增长是可理解的。玩家知道"我的 ×1.5 是从哪里来的"，而不是面对一个黑箱倍率。可理解的叠加比不可理解的叠加更有快感。
- **4.10 数据驱动与可扩展**：新修正来源（新装备类型、新 Buff、新境界加成）只需注册为新的 modifier，不需要改叠加代码。游戏长期扩展的数学基础。

## Detailed Design

### Core Rules

1. **架构形态**：`ModifierEngine` 为 RefCounted 服务类，持有所有已注册修正器。由 Autoload 持有单实例，通过 `register()` / `get_multiplier()` / `apply()` 等 API 使用。

2. **修正器数据模型**（`ModifierData` Dictionary）：
   - `id`: String — 引擎自动生成的唯一标识
   - `target`: String — 修正目标。**target 字符串语义由消费方约定，ModifierEngine 自身对 target 字符串无解析**：属性系统使用 `{entity_id}.{attr_id}` 格式（如 `"player.atk"`、`"enemy_yougui_a.def"`）；产出乘数系统使用 `{resource_id}_production` 格式（如 `"lingqi_production"`）。各消费方通过自身 GDD 定义 target 命名约定。
   - `type`: int — `0 = ADD`（flat 加法），`1 = MULT`（百分比乘法）
   - `value`: float — ADD 为 flat 值（100.0）；MULT 为比例（0.3 表示 +30%）
   - `pool`: String — MULT 修正的叠加池标识（ADD 类型忽略此字段）
   - `source`: String — 来源标识（用于批量注销和调试，如 `"equip_sword_001"`, `"buff_power_pill"`）
   - `duration`: float — 持续时间（秒，0 = 永久）
   - `remaining`: float — 剩余时间（内部字段，注册时 = duration）

3. **叠加管线**：给定 target，最终结果：
   ```
   add_sum = Σ(所有 ADD modifier.value)
   for each unique pool among MULT modifiers:
     pool_mult[pool] = 1.0 + Σ(该 pool 中所有 MULT modifier.value)
   final_mult = Π(all pool_mult values)
   result = (base + add_sum) × final_mult
   ```

4. **预定义乘法池（MVP）**：
   | 池名 | 来源类型 | 说明 |
   |------|---------|------|
   | `"equipment"` | 装备百分比 | 装备提供的攻击%、防御%等 |
   | `"skill"` | 技能/天赋 | 技能树和天赋提供的百分比加成 |
   | `"buff"` | Buff/Debuff | 临时增益和减益效果 |
   | `"realm"` | 境界突破 | 境界带来的永久百分比加成 |
   | `"milestone"` | 里程碑/成就 | 达成目标后的永久加成 |
   | `"zone"` | 区域效果 | 特定区域的加成/惩罚 |

   新池通过配置表扩展，不需要改代码。

5. **注册 API**：
   - `register(data: Dictionary) → String` — 接受修正器数据字典，返回自动生成的 ID。`id` 和 `remaining` 由引擎填充，调用方无需提供。
   - 同一 source 可注册多个修正器（如一件装备同时加攻击和暴击）。

6. **注销 API**：
   - `unregister(id: String) → bool` — 按 ID 注销单个修正器
   - `unregister_by_source(source: String) → int` — 注销该来源所有修正器，返回数量
   - 注销时自动标记相关 target 缓存为脏

7. **查询 API**：
   - `get_add_sum(target: String) → float` — 加法修正总和
   - `get_multiplier(target: String) → float` — 最终乘法倍率（所有池累乘）
   - `get_pool_multiplier(target: String, pool: String) → float` — 指定池的倍率
   - `apply(target: String, base: BigNumber) → BigNumber` — 一步完成 base → 最终值
   - `get_breakdown(target: String) → Dictionary` — 详细分解（每个池的贡献值）
   - `get_all_targets() → Array[String]` — 返回当前所有已注册修正器的不重复 target 列表（**调试用**）。无修正器时返回空数组。结果不保证排序顺序；调用方按需排序。该方法供调试控制台 `modifier list` 命令枚举所有 target；游戏运行逻辑不应依赖此方法（性能 O(N)，N 为修正器总数）。

8. **缓存机制**：
   - 每个 target 缓存最终乘法倍率（dirty-flag 模式）
   - 注册/注销/过期触发脏标记，下次查询时重算
   - 修正器变化频率远低于查询频率，缓存有效

9. **限时修正器**：
   - `duration > 0` 的修正器为限时修正器
   - `update(delta: float)` 由调用方每 tick 调用，递减 `remaining`
   - `remaining ≤ 0` 时自动注销，触发事件总线 `"modifier_expired"` 事件
   - 永久修正器（`duration = 0`）不受 update 影响

10. **条件修正**：修正器引擎**不评估条件**。源系统负责在条件满足时注册、条件不满足时注销。理由：条件逻辑千差万别且源系统已拥有上下文；MVP 阶段不需要统一条件评估框架。

### States and Transitions

ModifierEngine 整体无状态机。单个修正器的生命周期：

```
[Registered] → [Active] ──expire──→ [Removed]
                  │
                  └──unregister──→ [Removed]
```

- **Registered = Active**：注册即生效，无延迟激活
- **Removed**：过期或注销后从内部列表移除，不再参与计算

### Interactions with Other Systems

| 系统 | 方向 | 数据接口 | 说明 |
|------|------|---------|------|
| 大数值系统 | 下游消费 | `BigNumber.add(BigNumber.from_float(add_sum))`, `BigNumber.multiply_float(final_mult)` | `apply()` 方法内部调用 BigNumber 运算 |
| 公式引擎 | 上游协作 | 源系统用公式引擎计算单个修正值后注册到修正器引擎 | 公式引擎计算"这个装备加多少暴击率"，修正器引擎管理"所有暴击率修正怎么叠" |
| 事件总线 | 双向 | 发送 `"modifier_expired"` 事件；接收游戏状态变更（Post-MVP） | 限时修正器过期时通知 UI 和其他系统 |
| 产出乘数系统 | 下游消费 | 调用 `get_multiplier("lingqi_production")` / `get_pool_multiplier()` 获取最终倍率和池分解 | 灵气/修为产出倍率。OMS 自行用 float base_rate 计算速率并处理亚单位 carry；资源系统不直接调用 ModifierEngine |
| 属性系统 | 下游消费 | 调用 `apply("player.atk", base_atk)` 计算最终攻击力（target 命名约定：`{entity_id}.{attr_id}`，由属性系统的 `make_target()` 生成） | 装备、技能、Buff 对属性的加成。详见 attribute-system.md §Detailed Design 规则 5 |
| 等级系统 | 下游消费 | 等级变化时注册/注销境界/等级修正 | 等级提升带来的属性加成 |
| 产出乘数系统 | 下游消费 | 产出乘数系统定义具体产出来源和池分配，使用修正器引擎叠加 | 修正器引擎提供通用基础设施 |
| 战斗计算器 | 下游消费 | 查询伤害倍率、防御倍率、暴击倍率 | 战斗中的实时修正查询 |
| 半自动战斗系统 | 下游消费 | 战斗开始/结束时注册/注销战斗 Buff | 限时战斗增益 |
| 区域系统 | 下游消费 | 进入/离开区域时注册/注销区域修正 | 区域效果加成 |
| 调试控制台 | 下游 → 只读查询 | `get_all_targets()` / `get_breakdown(target)` | `modifier list` 与 `modifier breakdown` 命令；不注册或注销修正器 |

## Formulas

### 1. 加法修正总和 (Additive Sum)

`add_sum(target) = Σ m.value`，对 target 下所有 type = ADD 的修正器求和

**变量：**
| 变量 | 符号 | 类型 | 范围 | 说明 |
|------|------|------|------|------|
| modifier.value | v_i | float | (-∞, +∞) | 单个加法修正值 |

**输出范围：** (-∞, +∞)，负值表示减益（如区域惩罚、Debuff）

**示例：** 两个 ADD 修正 `v₁ = 200.0, v₂ = 50.0` → `add_sum = 250.0`

### 2. 池内倍率 (Pool Multiplier)

`pool_mult(target, pool) = 1.0 + Σ m.value`，对 target + pool 下所有 type = MULT 的修正器求和后加 1

**变量：**
| 变量 | 符号 | 类型 | 范围 | 说明 |
|------|------|------|------|------|
| modifier.value | v_j | float | (-∞, +∞) | 单个乘法修正比例（0.3 = +30%） |

**输出范围：** (0.0, +∞)，< 1.0 表示净减益

**示例：** 池 "equipment" 有三个修正 `0.10, 0.15, 0.05` → `1.0 + 0.30 = 1.30`

### 3. 最终乘法倍率 (Final Multiplier)

`final_mult(target) = Π pool_mult(target, pool)`，所有池的倍率相乘

**变量：**
| 变量 | 符号 | 类型 | 范围 | 说明 |
|------|------|------|------|------|
| pool 倍率 | p_k | float | (0.0, +∞) | 单个池的叠加倍率 |
| pool 数量 | n | int | [1, 10] | 参与累乘的池数量 |

**输出范围：** (0.0, +∞)

**示例：** 四个池 `1.30, 1.10, 1.20, 1.50` → `1.30 × 1.10 × 1.20 × 1.50 = 2.574`

### 4. 最终结果应用 (Apply to Base)

`result = (base + add_sum) × final_mult`

在 BigNumber 中的执行步骤：
```
adjusted = base.add(BigNumber.from_float(add_sum))
result = adjusted.multiply_float(final_mult)
```

**变量：**
| 变量 | 符号 | 类型 | 范围 | 说明 |
|------|------|------|------|------|
| base | b | BigNumber | [0, MAX] | 基础值 |
| add_sum | a | float | (-∞, +∞) | 加法修正总和 |
| final_mult | f | float | (0.0, +∞) | 最终乘法倍率 |

**完整示例：**

| 修正器 | type | value | pool | 说明 |
|--------|------|-------|------|------|
| 装备·剑 | ADD | 200.0 | — | flat 加攻击 |
| 装备·戒指 | ADD | 50.0 | — | flat 加攻击 |
| 装备·护甲 | MULT | 0.15 | equipment | +15% 攻击 |
| 技能·被动 | MULT | 0.10 | skill | +10% 攻击 |
| Buff·灵丹 | MULT | 0.20 | buff | +20% 攻击 |
| 境界·炼气 | MULT | 0.50 | realm | +50% 攻击 |
| 区域·荒漠 | MULT | -0.10 | zone | -10% 攻击（减益）|

```
add_sum = 200 + 50 = 250
pool_mult(equipment) = 1.0 + 0.15 = 1.15
pool_mult(skill)     = 1.0 + 0.10 = 1.10
pool_mult(buff)      = 1.0 + 0.20 = 1.20
pool_mult(realm)     = 1.0 + 0.50 = 1.50
pool_mult(zone)      = 1.0 + (-0.10) = 0.90
final_mult = 1.15 × 1.10 × 1.20 × 1.50 × 0.90 = 2.0538
result = (1000 + 250) × 2.0538 = 1250 × 2.0538 = 2567.25
```

### 5. 缓存重算耗时 (Cache Recalculation Cost)

`recalc_time = n_add × t_a + n_pool × (n_mult × t_a + t_m)`

**变量：**
| 变量 | 符号 | 类型 | 范围 | 说明 |
|------|------|------|------|------|
| ADD 修正数 | n_add | int | [0, 100] | 该 target 的加法修正数量 |
| 池数量 | n_pool | int | [0, 6] | 该 target 的乘法池数量 |
| MULT 修正数 | n_mult | int | [0, 100] | 单个池内的乘法修正数量 |
| 加法耗时 | t_a | float | ~0.001 ms | 单次 float 加法 |
| 乘法耗时 | t_m | float | ~0.001 ms | 单次 float 乘法 |

**典型值：** 20 ADD + 5 池 × 平均 4 MULT → `20 × 0.001 + 5 × (4 × 0.001 + 0.001) = 0.04 ms`

### 6. 修正器内存占用 (Memory per Modifier)

`memory = count × per_modifier_size`

**变量：**
| 变量 | 符号 | 类型 | 范围 | 说明 |
|------|------|------|------|------|
| 修正器总数 | count | int | [10, 2000] | 已注册修正器数量 |
| 单条大小 | size | int | ~120 bytes | Dictionary + 元数据 |

**输出范围：** ~1.2 KB（10 条）到 ~240 KB（2000 条）
**MVP 预估：** ~200 条 → ~24 KB

## Edge Cases

- **If 某目标没有任何修正器**：`get_add_sum()` 返回 `0.0`，`get_multiplier()` 返回 `1.0`，`apply(target, base)` 返回原 base 值。无修正 = 恒等变换。
- **If 某池内所有 MULT 修正值之和 < -1.0**：池内倍率 `pool_mult` 变为负数 → 钳位到 `0.0`，打印警告 `"Pool '{pool}' for target '{target}' has negative multiplier, clamped to 0.0"`。负池倍率无游戏意义，通常由配置错误导致。
- **If 最终乘法倍率 final_mult ≤ 0**：钳位到 `0.0`，打印警告。结果为 0，无论 base 多大。
- **If 加法修正总和 add_sum 为负且绝对值大于 base**：`base + add_sum < 0` → BigNumber 的非负约束生效，`BigNumber.add()` 中负结果钳位为 `BigNumber.ZERO`。
- **If 注销不存在的修正器 ID**：`unregister()` 返回 `false`，不崩溃，不打印警告（幂等操作）。
- **If 按来源注销时该来源无修正器**：`unregister_by_source()` 返回 `0`，不崩溃。
- **If 注册时 modifier.value 为 NaN 或 Inf**：拒绝注册，返回空字符串 `""`，打印警告 `"Invalid modifier value: {value} for source '{source}'"`。NaN/Inf 不应进入叠加管线。
- **If 注册时缺少必填字段**（无 target、无 type、无 value）：拒绝注册，返回空字符串 `""`，打印警告列出缺失字段。
- **If MULT 类型修正器的 pool 为空字符串**：默认分配到 `"default"` 池，打印警告 `"Empty pool for MULT modifier from '{source}', defaulted to 'default'"`。池名不应为空。
- **If modifier.value 为 0**：允许注册。零值修正无实际效果但不会破坏计算——某来源可能暂时将加成设为 0（如装备被"封印"）。
- **If `update(delta)` 传入负 delta**：钳位 delta 到 `0.0`，不回拨剩余时间。时间不应倒流。
- **If 同一帧内多个限时修正器同时过期**：全部在本帧 `update()` 中依次注销，每个触发独立的 `"modifier_expired"` 事件。批量过期不影响正确性。
- **If 同一来源注册了大量修正器**（如某系统误注册 10000 条）：不设硬性上限，但缓存重算耗时与修正器数量线性相关。若单 target 修正器超过 `WARN_MODIFIER_THRESHOLD`（默认 200），打印性能警告。
- **If 调用 `apply()` 时 base 为 BigNumber.ZERO**：`0 + add_sum` 后乘以 final_mult，结果取决于 add_sum 和 final_mult 的值。若 add_sum ≤ 0 且 final_mult ≤ 0，结果仍为 ZERO。允许。
- **If 循环注册/注销同一来源**（如某系统每帧误操作）：不崩溃，但每次操作标记缓存脏。同一帧内反复注册/注销，脏标记只记录"是否脏"不计数。性能损失可接受。
- **If `get_breakdown()` 对无修正的目标调用**：返回 `{"add_sum": 0.0, "pools": {}, "final_mult": 1.0}`。

## Dependencies

| 系统 | 方向 | 依赖性质 | 数据接口 |
|------|------|---------|---------|
| 大数值系统 | 上游依赖 | 硬依赖 | `apply()` 内部调用 `BigNumber.add()` 和 `BigNumber.multiply_float()`。修正器引擎无法脱离 BigNumber 独立工作 |
| 事件总线 | 上游依赖 | 硬依赖 | 限时修正器过期时发送 `"modifier_expired"` 事件。事件总线是 Foundation 层已完成的系统 |
| 公式引擎 | 架构协作 | 软依赖 | ModifierEngine 本身**不调用**公式引擎。调用方用公式引擎计算单个修正值后注册到 ModifierEngine。两者是架构邻居，不互相导入 |
| 产出乘数系统 | 下游消费 | 硬依赖 | 调用 `get_multiplier("lingqi_production")` / `get_pool_multiplier()` 获取产出倍率。OMS 自行用 float base_rate 计算速率并处理亚单位 carry；资源系统**不直接**依赖 ModifierEngine |
| 属性系统 | 下游消费 | 硬依赖 | 调用 `apply("{entity_id}.{attr_id}", base)` 计算最终属性值（target 命名约定见 attribute-system.md §Detailed Design 规则 5） |
| 等级系统 | 下游消费 | 硬依赖 | 等级/境界变化时注册/注销修正 |
| 产出乘数系统 | 下游消费 | 硬依赖 | 定义具体产出来源和池分配，使用修正器引擎叠加 |
| 战斗计算器 | 下游消费 | 硬依赖 | 查询伤害/防御/暴击等战斗修正 |
| 半自动战斗系统 | 下游消费 | 软依赖 | 战斗开始/结束时注册/注销战斗 Buff。MVP 可简化为无战斗 Buff |
| 区域系统 | 下游消费 | 软依赖 | 进入/离开区域时注册/注销区域修正 |

**双向一致性**：大数值系统 GDD 的 Interactions 表已列出修正器/倍率引擎为双向关系；公式引擎 GDD 的 Interactions 表已列出修正器引擎为下游消费。本 GDD 的声明与这两份 GDD 一致。下游系统（资源、属性、等级等）的 GDD 完成后需各自列出"上游依赖 ModifierEngine"。

## Tuning Knobs

| 参数 | 当前值 | 安全范围 | 增大影响 | 减小影响 |
|------|--------|---------|---------|---------|
| `CACHE_ENABLED` | true | [true, false] | 缓存查询结果，性能优化 | 每次查询重算（仅调试用） |
| `WARN_MODIFIER_THRESHOLD` | 200 | [50, 1000] | 允许更多修正器不触发性能警告 | 更早触发性能警告 |
| `WARN_ON_NEGATIVE_POOL` | true | [true, false] | 池倍率为负时打印警告 | 静默钳位（减少日志噪音，生产构建可用） |
| `WARN_ON_MISSING_FIELDS` | true | [true, false] | 注册缺少字段时打印警告 | 静默拒绝 |
| `WARN_ON_INVALID_VALUE` | true | [true, false] | NaN/Inf 值注册时打印警告 | 静默拒绝 |
| `DEFAULT_POOL` | "default" | — | MULT 修正无池名时使用的默认池 | — |

## Acceptance Criteria

- [ ] **GIVEN** 两个 ADD 修正 `target="atk"` value 分别为 200 和 50，**WHEN** 调用 `get_add_sum("atk")`，**THEN** 返回 `250.0`
- [ ] **GIVEN** 三个 MULT 修正同一池 `"equipment"` value 为 0.10, 0.15, 0.05，**WHEN** 调用 `get_pool_multiplier("atk", "equipment")`，**THEN** 返回 `1.30`
- [ ] **GIVEN** 四个池倍率 1.15, 1.10, 1.20, 1.50，**WHEN** 调用 `get_multiplier("atk")`，**THEN** 返回 `1.15 × 1.10 × 1.20 × 1.50 = 2.282`
- [ ] **GIVEN** base=BigNumber(1000) 且 add_sum=250, final_mult=2.0，**WHEN** 调用 `apply("atk", base)`，**THEN** 结果为 BigNumber 表示 2500
- [ ] **GIVEN** target 无任何修正器，**WHEN** 调用 `get_multiplier("atk")` 和 `get_add_sum("atk")`，**THEN** 分别返回 `1.0` 和 `0.0`
- [ ] **GIVEN** 一个限时修正器 duration=5.0，**WHEN** 调用 `update(3.0)` 后 `update(3.0)`，**THEN** 修正器已注销，触发 `"modifier_expired"` 事件
- [ ] **GIVEN** 注册修正器返回 id="abc"，**WHEN** 调用 `unregister("abc")`，**THEN** 返回 `true`；再次调用 `unregister("abc")` 返回 `false`
- [ ] **GIVEN** source="sword_001" 注册了 3 个修正器，**WHEN** 调用 `unregister_by_source("sword_001")`，**THEN** 返回 `3`，相关 target 修正器数量减少 3
- [ ] **GIVEN** 注册 value=NaN 的修正器，**WHEN** 调用 `register()`，**THEN** 返回空字符串 `""`，打印警告
- [ ] **GIVEN** 注册缺少 target 字段的修正器，**WHEN** 调用 `register()`，**THEN** 返回空字符串 `""`，打印警告
- [ ] **GIVEN** MULT 修正器 pool="" 空字符串，**WHEN** 注册，**THEN** 分配到 `"default"` 池，打印警告
- [ ] **GIVEN** 同一池内修正值之和 = -1.5，**WHEN** 调用 `get_pool_multiplier()`，**THEN** 钳位到 `0.0`，打印警告
- [ ] **GIVEN** 修正器 value=0，**WHEN** 注册，**THEN** 成功返回 ID，`get_add_sum` 包含 `0.0` 贡献
- [ ] **GIVEN** 同一 source 注册两个不同 target 的修正器，**WHEN** 调用 `unregister_by_source()`，**THEN** 两个 target 的修正器均被移除
- [ ] **GIVEN** target 有修正器，**WHEN** 调用 `get_breakdown("atk")`，**THEN** 返回包含 `add_sum`、`pools` 字典和 `final_mult` 的 Dictionary
- [ ] **GIVEN** target 缓存为脏，**WHEN** 首次调用 `get_multiplier()` 后再次调用，**THEN** 第二次直接返回缓存值
- [ ] **GIVEN** 一个修正器 value=0.15, pool="equipment", target="atk"，**WHEN** 注销后重新查询，**THEN** 该池倍率不再包含 0.15
- [ ] **GIVEN** 200 个修正器分散在 6 个池中，**WHEN** 单帧内调用 1000 次 `get_multiplier()`，**THEN** 总耗时 < 1.0 ms（缓存命中场景）
- [ ] **GIVEN** 已注册 3 个修正器，target 分别为 `"player.atk"`、`"player.atk"`、`"lingqi_production"`，**WHEN** 调用 `get_all_targets()`，**THEN** 返回的数组长度为 2 且包含 `"player.atk"` 和 `"lingqi_production"`（去重，顺序不保证）；空注册表时返回空数组 `[]`

## Open Questions

| Question | Owner | Deadline | Resolution |
|----------|-------|----------|-----------|
| 修正器是否需要支持序列化（存档/读档时持久化限时修正器的 remaining 时间）？ | 开发者 | 存档系统 GDD 时决定 | — |
| 产出乘数系统的职责是否与修正器引擎重叠太多？是否应合并？ | 技术总监 | 产出乘数系统 GDD 时决定 | — |
| 是否需要修正器变更事件（如 `"modifier_added"`, `"modifier_removed"`），还是仅过期事件？ | 设计师 | UI 框架 GDD 时决定 | — |
| 池名是否需要命名空间前缀（如 `"combat.equipment"` vs `"production.equipment"`）以避免冲突？ | 设计师 | 首批修正器配置时决定 | — |
| Post-MVP 是否需要条件表达式支持（如公式引擎的条件求值）？ | 技术总监 | MVP 完成后评估 | — |
