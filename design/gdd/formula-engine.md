# 公式引擎 (Formula Engine)

> **Status**: Designed
> **Author**: binlee1990 + agents
> **Last Updated**: 2026-05-03
> **Implements Pillar**: 4.1 数字增长就是快乐 · 4.10 数据驱动与可扩展

## Overview

公式引擎是整个游戏的统一数学表达式求值服务层。所有涉及数值计算的机制——修炼产出、资源消耗、伤害公式、成长曲线、软上限、掉落权重——都通过公式引擎计算，而不是在各自系统中硬编码公式逻辑。这一集中化设计确保公式定义可配置、可热更新、可单测，且所有系统共享同一套数学规则。

核心形态是一个轻量级表达式求值器（expression evaluator），支持变量代入、基础四则运算、幂运算、常用数学函数（min, max, clamp, log, floor, ceil）、软上限函数、条件表达式和随机方差注入。公式以字符串形式存储在配置表中，运行时解析求值——设计师调整数值只需改配置，不需要改代码。

类型系统遵循已建立的大数值系统约定：公式输入和输出的绝对量（灵气、修为、伤害）使用 `BigNumber`，比值和百分比乘数使用 `float`。公式引擎不持有游戏状态——所有变量由调用方在求值时通过上下文字典注入。公式引擎本身是纯确定性的——随机方差由调用方在公式结果上叠加，确保公式的可测试性和可复现性。

公式引擎不追求图灵完备——它不是脚本语言，不支持循环、赋值或函数定义。复杂的业务逻辑（如多阶段战斗结算、多轮掉落循环）由各自的系统代码实现，公式引擎只负责"给定变量，返回结果"的单次求值。

## Player Fantasy

公式引擎是无形的天道法则——玩家永远看不到它，但修仙世界的每一丝规律都由它编织。

**锚定时刻**：玩家在配置界面花了两分钟调整队伍——换了一件暴击率更高的装备、升级了一个攻击天赋、把修炼加成的阵法换了位置。然后挂机刷怪，五分钟后回来一看：伤害数字从每跳 1.2 万变成了 3.8 万，灵气产出从每秒 500 跳到了 2100。玩家打开详细战报，发现伤害公式里暴击真的生效了、攻击力的成长系数真的兑现了、那件装备的词条加成真的被算进了总倍率。这种"我改了配置，世界如实回应"的感觉，正是公式引擎在背后保障的。

作为基础设施，公式引擎不创造成长本身，但它是成长的公正度量衡。没有它，每次装备升级后的伤害提升可能是"大概差不多"，暴击率可能是"看着好像有用"，成长曲线可能是"策划感觉这个数值差不多"。有了它，修仙世界的所有数值关系是精确、一致、可追溯的——玩家可以信赖"攻击力提高 10%，伤害真的会提高约 10%"，而不是面对一个黑箱。

支柱对应：
- **4.1 数字增长就是快乐**：公式引擎确保每一次增长都是可理解、可预期的。玩家看到的不是随机数字跳动，而是"我的选择 → 公式计算 → 确切结果"的因果链。可理解的成长比不可理解的成长更有快感。
- **4.10 数据驱动与可扩展**：所有公式配置化意味着新区域、新职业、新机制的数值体系不需要改代码——定义新公式、配好变量、调好参数，系统自动生效。这是游戏长期可扩展的数学基础。

## Detailed Design

### Core Rules

1. **架构形态**：`FormulaEngine` 作为工具类（非 Autoload），无状态。通过 `FormulaEngine.evaluate(formula_id, context)` 或 `FormulaEngine.evaluate_raw(expression, context)` 静态方法调用。公式引擎不持有任何游戏状态或单例引用。

2. **底层实现**：基于 Godot 内置 `Expression` 类。`Expression` 支持基础数学运算、变量代入、比较运算和三元条件表达式，满足 MVP 公式需求。FormulaEngine 在其上封装缓存、类型安全、错误处理和常用游戏数学函数。

3. **求值模型**：
   - 输入：公式字符串 + 变量上下文（Dictionary）
   - 输出：`float`（倍率、系数、比值、百分比）
   - 所有变量值在注入前由调用方转换为 `float`
   - BigNumber 的 `magnitude()`（exponent）和 `log10()` 可作为变量传入公式
   - 公式不处理 BigNumber 运算——BigNumber 乘法/加法在公式求值后由调用方执行

4. **公式标识与存储**：
   - 每条公式有唯一 `formula_id`（字符串，如 `"damage_multiplier"`, `"cultivation_rate"`）
   - 公式存储在数据配置系统中，格式：
     ```json
     {
       "id": "damage_multiplier",
       "expression": "1.0 + atk_bonus * 0.01 + crit_rate * crit_damage",
       "variables": ["atk_bonus", "crit_rate", "crit_damage"],
       "category": "combat",
       "description": "伤害倍率计算"
     }
     ```
   - `expression` 是符合 Godot Expression 语法的字符串
   - `variables` 声明该公式需要的变量名列表，用于解析时验证

5. **缓存机制**：
   - `Expression.parse()` 结果缓存在内存中（以 `formula_id` 为 key）
   - 同一公式多次求值只解析一次，后续调用直接 execute
   - 热更新时清除指定缓存：`FormulaEngine.invalidate(formula_id)`
   - 清除全部缓存：`FormulaEngine.invalidate_all()`

6. **支持的运算符**（Godot Expression 原生）：
   - 算术：`+`, `-`, `*`, `/`, `%`
   - 幂运算：`pow(a, b)` 函数
   - 比较：`==`, `!=`, `<`, `>`, `<=`, `>=`
   - 逻辑：`and`, `or`, `not`
   - 三元：`value_if_true if condition else value_if_false`

7. **内置函数**（通过辅助对象注入）：
   - 数学：`min(a, b)`, `max(a, b)`, `clamp(val, lo, hi)`, `abs(x)`
   - 取整：`floor(x)`, `ceil(x)`, `round(x)`
   - 对数/幂：`sqrt(x)`, `pow(base, exp)`, `log(x)`（自然对数）, `log10(x)`, `exp(x)`
   - 软上限：
     - `softcap(value, threshold, power)` — 若 `value > threshold`，返回 `threshold + (value - threshold) ^ power`；否则返回 `value`
     - `log_softcap(value, threshold)` — 若 `value > threshold`，返回 `threshold * log10(value / threshold + 1)`；否则返回 `value`
   - 工具：`stepify(value, step)`（按步长对齐）, `lerp(a, b, t)`, `sign(x)`

8. **辅助对象注入方式**：
   - 创建 `FormulaHelper`（RefCounted）类，包含上述所有内置函数
   - `Expression.execute()` 时将 FormulaHelper 实例作为 `base_instance` 传入
   - 公式中的函数调用（如 `softcap(x, 100, 0.5)`）解析为 FormulaHelper 的方法调用

9. **变量注入**：
   - 调用方构造上下文字典：`{"atk_bonus": 15.0, "crit_rate": 0.3, "crit_damage": 2.0}`
   - FormulaEngine 按 `variables` 声明列表的顺序提取值，传入 `Expression.execute(inputs)`
   - 上下文中缺失的变量默认为 `0.0`，打印警告
   - 上下文中多余的变量被忽略

10. **类型规则**：
    - 所有输入变量强制为 `float`，非 float 类型（int, String）自动转换为 float
    - 输出强制为 `float`
    - 若公式求值结果不是 numeric 类型（如表达式返回 bool），转换规则：`true → 1.0`, `false → 0.0`

11. **错误处理**：
    - 解析失败：`Expression.parse()` 返回错误 → 缓存该错误，后续调用直接返回 `0.0` 并打印警告（不重复解析）
    - 执行失败：`Expression.execute()` 返回错误 → 返回 `0.0` 并打印警告，含公式 ID、表达式和变量值
    - 除零：Godot Expression 内部处理（返回 `inf` 或 `nan`）→ FormulaEngine 检测到 `nan`/`inf` 时返回 `0.0`
    - 公式 ID 不存在：返回 `0.0`，打印警告 `"Formula not found: {formula_id}"`

12. **热更新支持**：
    - 开发模式下：数据配置系统重载时自动调用 `invalidate_all()`
    - 生产模式下：公式不可热更新（加载时解析，运行时不变）
    - 调试接口：`FormulaEngine.reload_formula(formula_id)` 强制重新解析指定公式

### States and Transitions

FormulaEngine 是无状态工具类，不适用状态机。每次 `evaluate()` 调用是独立的纯函数——输入相同则输出相同，不持有任何跨调用状态。缓存是性能优化而非业务状态。

### Interactions with Other Systems

| 系统 | 方向 | 数据接口 | 说明 |
|------|------|---------|------|
| 大数值系统 | 上游依赖 | 调用方使用 `BigNumber.log10()`, `magnitude()`, `to_float()` 提取 float 值注入公式 | 公式引擎不直接操作 BigNumber，调用方负责转换 |
| 随机数与种子系统 | 外部协作 | 调用方在公式结果上叠加随机方差：`result = formula_result * RNGManager.rand_float(COMBAT, 0.8, 1.2)` | 公式引擎本身是确定性的，随机性由调用方叠加 |
| 数据配置系统 | 上游依赖 | 公式定义从配置表加载，格式为 JSON/Resource | 数据配置系统负责存储和加载公式定义 |
| 修正器/倍率引擎 | 下游消费 | 修正器使用公式引擎计算修正系数，或将公式计算结果作为修正值输入 | 公式引擎提供基础计算，修正器管理叠加顺序 |
| 产出乘数系统 / 存储上限系统 | 下游消费 | 调用公式引擎计算产出倍率/消耗系数与上限增长公式，结果用于 BigNumber 乘法 | 如 `production_rate = FormulaEngine.evaluate("lingqi_production", ctx)`。**注意**：资源系统不直接调用 FormulaEngine，由这两个中介系统使用——见 resource-system.md §Dependencies "关键非依赖" |
| 等级系统/突破系统 | 下游消费 | 调用公式引擎计算属性成长系数后通过 AttributeSystem.set_base 写入 | 如 `growth_rate = FormulaEngine.evaluate("atk_growth", ctx)`。**注意**：属性系统**不直接**调用 FormulaEngine，由等级系统/突破系统作为中介——见 attribute-system.md §Dependencies "关键非依赖" |
| 等级系统 | 下游消费 | 调用公式引擎计算升级经验需求 | 如 `exp_needed = FormulaEngine.evaluate("level_exp", ctx)` |
| 战斗计算器 | 下游消费 | 调用公式引擎计算伤害倍率、命中概率等 | 如 `dmg_mult = FormulaEngine.evaluate("damage_mult", ctx)` |
| 调试控制台 | 下游消费 | 支持运行时公式求值测试 | 如输入公式和变量，查看求值结果 |

## Formulas

### 1. 幂软上限 (Power Softcap)

`softcap(value, threshold, power) → result`

**变量：**
| 变量 | 符号 | 类型 | 范围 | 说明 |
|------|------|------|------|------|
| value | v | float | [0.0, +∞) | 输入值 |
| threshold | t | float | [1.0, +∞) | 软上限阈值 |
| power | p | float | (0.0, 1.0] | 衰减指数（< 1 时生效） |

**输出范围：** `v`（v ≤ t 时）或 `t + (v - t)^p`（v > t 时）

**示例：** `softcap(500, 100, 0.5)` → `100 + (500 - 100)^0.5 = 100 + 20 = 120`

### 2. 对数软上限 (Logarithmic Softcap)

`log_softcap(value, threshold) → result`

**变量：**
| 变量 | 符号 | 类型 | 范围 | 说明 |
|------|------|------|------|------|
| value | v | float | [0.0, +∞) | 输入值 |
| threshold | t | float | [1.0, +∞) | 软上限阈值 |

**输出范围：** `v`（v ≤ t 时）或 `t × log10(v / t + 1)`（v > t 时）

**示例：** `log_softcap(1000, 100)` → `100 × log10(1000/100 + 1) = 100 × log10(11) ≈ 104.1`

### 3. 单次公式求值耗时

`eval_time = h × t_l + (1 - h) × (t_l + t_p) + t_e`

**变量：**
| 变量 | 符号 | 类型 | 范围 | 说明 |
|------|------|------|------|------|
| cache_hit | h | int | {0, 1} | 是否命中缓存 |
| lookup_time | t_l | float | [0.001, 0.005] ms | 缓存字典查找耗时 |
| parse_time | t_p | float | [0.05, 0.5] ms | Expression.parse() 首次解析耗时 |
| execute_time | t_e | float | [0.001, 0.05] ms | Expression.execute() 求值耗时 |

**输出范围：** 0.002 ms（缓存命中 + 简单公式）到 0.555 ms（缓存未命中 + 复杂公式）
**正常范围：** < 0.02 ms（缓存命中，典型公式）

**示例：** 缓存命中时：`eval_time = 1 × 0.003 + 0 + 0.01 = 0.013 ms`

### 4. 帧内公式引擎总预算

`formula_budget = frame_time × budget_ratio`

**变量：**
| 变量 | 符号 | 类型 | 范围 | 说明 |
|------|------|------|------|------|
| frame_time | t_f | float | 16.67 ms | 单帧时间（60 fps） |
| budget_ratio | r | float | [0.02, 0.05] | 公式引擎允许占用的帧时间比例 |

**输出范围：** 0.333 ms（保守，2%）到 0.833 ms（宽松，5%）
**推荐值：** r = 0.03 → budget = 0.5 ms/frame

### 5. 缓存内存占用

`cache_memory = formula_count × per_entry_size`

**变量：**
| 变量 | 符号 | 类型 | 范围 | 说明 |
|------|------|------|------|------|
| formula_count | n | int | [10, 500] | 已缓存的公式数量 |
| per_entry_size | s | int | ~200 bytes | 每个 Expression 实例 + 元数据的内存占用 |

**输出范围：** ~2 KB（10 个公式）到 ~100 KB（500 个公式）
**示例：** MVP 约 50 个公式 → 50 × 200 = 10 KB

## Edge Cases

- **If 公式表达式为空字符串**：返回 `0.0`，打印警告 `"Empty expression for formula: {formula_id}"`。空表达式无意义但不应崩溃。
- **If 公式 ID 不存在于配置中**：返回 `0.0`，打印警告 `"Formula not found: {formula_id}"`。调用方应检查公式是否已注册。
- **If 上下文中缺少声明的变量**：缺失变量默认为 `0.0`，打印警告 `"Missing variable '{var_name}' in context for formula '{formula_id}', defaulting to 0.0"`。公式仍正常求值——防御性降级。
- **If 上下文中包含未声明的变量**：忽略多余变量，不打印警告。调用方传入丰富上下文是正常行为。
- **If 公式中发生除零**：Godot Expression 返回 `inf` 或 `nan` → FormulaEngine 检测后返回 `0.0`，打印警告 `"Division by zero in formula '{formula_id}'"`。游戏公式中除零通常是配置错误。
- **If 公式求值结果为 NaN 或 Inf**：返回 `0.0`，打印警告 `"Non-finite result from formula '{formula_id}': {result}"`。NaN/Inf 不应传播到游戏逻辑。
- **If 公式求值结果为负数**：允许返回。公式引擎不钳位负数——负数有合法用途（如防御减免系数为负表示增伤）。钳位由调用方按业务规则处理。
- **If 公式返回布尔值**（如 `x > 5`）：转换为 float：`true → 1.0`, `false → 0.0`。布尔表达式在条件公式中有合法用途。
- **If softcap 的 value 为负数**：钳位 value 到 0.0，返回 0.0。软上限无负数语义。
- **If softcap 的 threshold ≤ 0**：钳位到 1.0，打印警告。阈值必须为正数。
- **If softcap 的 power ≤ 0 或 > 1**：power ≤ 0 钳位到 0.01，power > 1 钳位到 1.0（等效于无软上限）。打印警告。
- **If log_softcap 的 value 为 0**：返回 0.0（不执行 log 运算）。
- **If log_softcap 的 value 为负数**：钳位到 0.0，返回 0.0。
- **If 公式语法错误**：首次解析失败时缓存错误状态，后续调用直接返回 `0.0` 并打印警告（不重复解析）。`invalidate(formula_id)` 后重试解析。
- **If 变量名与内置函数名冲突**（如变量名为 `min`, `max`, `clamp`）：变量优先级低于函数名。Godot Expression 的函数调用优先于变量——变量名为 `min` 时在表达式中引用 `min` 将调用函数而非使用变量值。建议在变量命名约定中避免使用内置函数名。
- **If 同一公式 ID 注册了两个不同表达式**：后者覆盖前者，旧缓存被清除。打印信息 `"Formula '{formula_id}' expression updated"`。
- **If `evaluate_raw()` 传入超长表达式**（> 4096 字符）：截断到 4096 字符并打印警告。超长表达式可能是配置错误。
- **If 缓存被大量 invalidate 导致同一帧内重复 parse**：性能短暂下降但可接受。缓存重建是渐进的（按需解析），不批量重建。

## Dependencies

| 系统 | 方向 | 依赖性质 | 数据接口 |
|------|------|---------|---------|
| **（无硬性上游依赖）** | — | — | FormulaEngine 是 Core Data 层基础设施，不直接导入 BigNumber 或 RNGManager 的代码 |
| 大数值系统 | 架构协作 | 软依赖 | 调用方负责将 BigNumber 转为 float 后注入公式变量（`to_float()`, `log10()`, `magnitude()`）。FormulaEngine 本身不操作 BigNumber |
| 随机数与种子系统 | 架构协作 | 软依赖 | 随机性由调用方在公式结果上叠加（如 `result * RNGManager.rand_float(stream, 0.8, 1.2)`）。FormulaEngine 本身是纯确定性的 |
| 数据配置系统 | 上游依赖 | 硬依赖（Post-MVP）/ 软依赖（MVP） | MVP 阶段：FormulaEngine 自带最小 JSON 加载能力。Post-MVP：公式定义从数据配置系统统一加载。公式存储格式由本 GDD 定义 |
| 修正器/倍率引擎 | 下游消费 | 硬依赖 | 使用公式引擎计算修正系数和叠乘公式 |
| 产出乘数系统 / 存储上限系统 | 下游消费 | 硬依赖 | 调用公式引擎计算产出倍率、消耗系数和上限增长公式。资源系统**不直接**依赖 FormulaEngine，由这两个中介系统使用 |
| 等级系统/突破系统 | 下游消费 | 硬依赖 | 调用公式引擎计算属性成长系数后通过 AttributeSystem.set_base 写入。属性系统**不直接**依赖 FormulaEngine，由等级系统/突破系统中介 |
| 等级系统 | 下游消费 | 硬依赖 | 调用公式引擎计算升级经验需求 |
| 战斗计算器 | 下游消费 | 硬依赖 | 调用公式引擎计算伤害倍率、命中概率 |
| 掉落系统 | 下游消费 | 硬依赖 | 调用公式引擎计算掉落权重、掉落倍率 |
| 调试控制台 | 下游消费 | 软依赖 | 支持运行时公式求值测试 |

**关于 systems-index 依赖声明**：systems-index 中公式引擎的 "Depends On" 列为"大数值系统, 随机数与种子系统"。实际设计中这两个是软依赖（架构协作关系），FormulaEngine 不直接导入它们的代码。硬性上游依赖是数据配置系统（Post-MVP）。建议更新 systems-index 的依赖声明以反映此区分。

**双向一致性**：大数值系统 GDD 的 Interactions 表已列出公式引擎为双向关系；随机数与种子系统 GDD 的 Interactions 表已列出公式引擎为下游消费。本 GDD 与这两份 GDD 的声明一致。下游系统的 GDD 完成后需各自列出"上游依赖 FormulaEngine"。

## Tuning Knobs

| 参数 | 当前值 | 安全范围 | 增大影响 | 减小影响 |
|------|--------|---------|---------|---------|
| `MAX_EXPRESSION_LENGTH` | 4096 | [512, 8192] | 允许更复杂的公式表达式 | 限制公式复杂度，超长公式被截断 |
| `CACHE_ENABLED` | true | [true, false] | 缓存解析结果，避免重复 parse | 每次求值都重新解析，性能下降（仅调试用） |
| `WARN_ON_MISSING_VARIABLE` | true | [true, false] | 缺失变量时打印警告，辅助调试 | 静默使用默认值 0.0，减少日志噪音（生产构建可用） |
| `WARN_ON_FORMULA_ERROR` | true | [true, false] | 公式错误时打印警告 | 静默返回 0.0，减少日志噪音 |
| `DEFAULT_MISSING_VARIABLE_VALUE` | 0.0 | [0.0, 1.0] | 缺失变量使用更高的默认值 | 缺失变量使用 0.0（当前推荐） |
| `FORMULA_BUDGET_RATIO` | 0.03 | [0.01, 0.05] | 公式引擎获得更多帧时间预算 | 更严格的性能限制 |
| `HOT_RELOAD_ENABLED` | false | [true, false] | 开发模式下支持公式热重载 | 公式只在启动时加载（生产推荐） |
| `BUILTIN_FUNCTIONS_ENABLED` | true | [true, false] | 启用软上限等游戏数学函数 | 仅基础数学运算（仅调试用） |

**说明**：上述参数为开发者/工程参数。`MAX_EXPRESSION_LENGTH` 和 `FORMULA_BUDGET_RATIO` 是运行时常量，不应在游戏中动态修改。`HOT_RELOAD_ENABLED` 仅在开发构建中开启。游戏设计师通过修改配置表中的公式表达式和变量值来调参，而非修改这些引擎参数。

## Acceptance Criteria

- [ ] **GIVEN** 公式 `"lingqi_rate"` 表达式为 `"base_rate * (1.0 + level * 0.1)"`，**WHEN** 执行 `FormulaEngine.evaluate("lingqi_rate", {"base_rate": 10.0, "level": 5.0})`，**THEN** 结果为 `15.0`
- [ ] **GIVEN** 表达式字符串 `"a + b * c"`，**WHEN** 执行 `FormulaEngine.evaluate_raw("a + b * c", {"a": 1.0, "b": 2.0, "c": 3.0})`，**THEN** 结果为 `7.0`（运算符优先级正确）
- [ ] **GIVEN** 公式声明变量 `["atk", "def"]`，**WHEN** 上下文只传入 `{"atk": 100.0}`，**THEN** 结果中 def 默认为 `0.0`，打印警告
- [ ] **GIVEN** 公式声明变量 `["atk"]`，**WHEN** 上下文传入 `{"atk": 100.0, "spd": 50.0, "luck": 3.0}`，**THEN** 多余变量被忽略，结果正确
- [ ] **GIVEN** 不存在的公式 ID `"nonexistent"`，**WHEN** 执行 `evaluate("nonexistent", {})`，**THEN** 返回 `0.0`，打印警告
- [ ] **GIVEN** 空表达式公式，**WHEN** 执行 `evaluate`，**THEN** 返回 `0.0`，打印警告
- [ ] **GIVEN** 语法错误的表达式 `"a + * b"`，**WHEN** 首次执行 `evaluate`，**THEN** 返回 `0.0`，打印警告；再次调用返回 `0.0` 不重复解析
- [ ] **GIVEN** 表达式 `"1.0 / 0.0"`，**WHEN** 执行求值，**THEN** 返回 `0.0`，打印警告（除零保护）
- [ ] **GIVEN** 产生 NaN 的运算，**WHEN** 求值，**THEN** 返回 `0.0`，打印警告
- [ ] **GIVEN** 表达式 `"x > 5"` 且 `x = 10.0`，**WHEN** 求值，**THEN** 结果为 `1.0`（布尔 true → float）
- [ ] **GIVEN** 表达式 `"x > 5"` 且 `x = 3.0`，**WHEN** 求值，**THEN** 结果为 `0.0`（布尔 false → float）
- [ ] **GIVEN** 三元表达式 `"base * 2.0 if active else base * 0.5"` 且 `base=100.0, active=1.0`，**WHEN** 求值，**THEN** 结果为 `200.0`
- [ ] **GIVEN** `softcap(500, 100, 0.5)`，**WHEN** 求值，**THEN** 结果为 `120.0`
- [ ] **GIVEN** `softcap(50, 100, 0.5)`（value < threshold），**WHEN** 求值，**THEN** 结果为 `50.0`
- [ ] **GIVEN** `log_softcap(1000, 100)`，**WHEN** 求值，**THEN** 结果约为 `104.1`
- [ ] **GIVEN** `log_softcap(50, 100)`（value < threshold），**WHEN** 求值，**THEN** 结果为 `50.0`
- [ ] **GIVEN** `clamp(15, 0, 10)`，**WHEN** 求值，**THEN** 结果为 `10.0`
- [ ] **GIVEN** `floor(3.7)`，**WHEN** 求值，**THEN** 结果为 `3.0`
- [ ] **GIVEN** `lerp(0, 100, 0.3)`，**WHEN** 求值，**THEN** 结果为 `30.0`
- [ ] **GIVEN** 公式首次求值后缓存，**WHEN** 连续 1000 次调用 `evaluate`，**THEN** 平均单次缓存命中耗时 < 0.02 ms
- [ ] **GIVEN** 50 个已缓存公式，**WHEN** 单帧内各求值 1 次，**THEN** 总耗时 < 0.5 ms
- [ ] **GIVEN** 缓存中有 50 个公式，**WHEN** 调用 `invalidate_all()`，**THEN** 缓存清空，后续调用触发重新解析
- [ ] **GIVEN** `HOT_RELOAD_ENABLED = true`，**WHEN** 配置文件中公式表达式被修改并重新加载，**THEN** 新表达式生效
- [ ] **GIVEN** 传入 int 值 `{"level": 5}`，**WHEN** 求值，**THEN** 自动转换为 float `5.0`，结果正确
- [ ] **GIVEN** 表达式 `"a - b"` 且 `a=3.0, b=10.0`，**WHEN** 求值，**THEN** 结果为 `-7.0`（负数允许）
- [ ] **GIVEN** 超长表达式（> 4096 字符），**WHEN** 执行 `evaluate_raw`，**THEN** 截断到 4096 字符，打印警告
- [ ] **GIVEN** `softcap(-10, 100, 0.5)`，**WHEN** 求值，**THEN** value 钳位到 0.0，返回 `0.0`
- [ ] **GIVEN** `softcap(200, -5, 0.5)`，**WHEN** 求值，**THEN** threshold 钳位到 `1.0`，打印警告
- [ ] **GIVEN** `softcap(200, 100, 2.0)`，**WHEN** 求值，**THEN** power 钳位到 `1.0`，结果为 `200.0`（等效无软上限）
- [ ] **GIVEN** 上下文为空字典 `{}`，**WHEN** 对无变量公式 `"42 * 2"` 求值，**THEN** 结果为 `84.0`

## Open Questions

| Question | Owner | Deadline | Resolution |
|----------|-------|----------|-----------|
| Godot 4.6 的 `Expression` 类是否支持 `base_instance` 方式注入自定义函数？需验证 API 行为 | 开发者 | 实现阶段前 | — |
| MVP 阶段公式加载的最小实现是什么？直接 JSON 文件读取，还是需要 Resource 格式？ | 开发者 | 数据配置系统 GDD 时决定 | — |
| 公式 ID 是否需要命名空间前缀（如 `"combat.damage_mult"`, `"cultivation.rate"`）以避免冲突？ | 设计师 | 首批公式配置时决定 | — |
| `evaluate_raw()` 是否需要在生产构建中禁用（仅调试/测试可用）？ | 技术总监 | 实现阶段前 | — |
| 软上限函数是否需要支持更多变体（如分段线性衰减、指数衰减）？还是当前两种（幂软上限 + 对数软上限）足够？ | 设计师 | 属性系统/等级系统 GDD 时决定 | — |
