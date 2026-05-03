# 大数值系统 (Big Number System)

> **Status**: In Design
> **Author**: binlee1990 + agents
> **Last Updated**: 2026-05-03
> **Implements Pillar**: 4.1 数字增长就是快乐

## Summary

大数值系统提供统一的 `BigNumber` 抽象，支持从个位数到 1e300+ 的精确数值运算。它是所有资源、战斗、成长和离线模拟的底层依赖——没有它，修仙放置游戏的后期数值体系无法表达。

> **Quick reference** — Layer: `Foundation` · Priority: `MVP` · Key deps: `None`

## Overview

大数值系统是整个游戏的数据类型基础设施层。它为所有游戏系统提供统一的 `BigNumber` 抽象，支持从个位数到 `1e300+` 范围内的精确数值运算，包括加减乘除、幂运算、对数比较、科学计数法存储和存档序列化。

GDScript 原生的 `int`（64-bit，上限约 9.2e18）和 `float`（double，整数精度在 2^53 后丢失）无法满足修仙放置游戏中灵气、修为、战力、掉落倍率等数值在后期的指数级膨胀需求——本系统填补这一空白，确保数值在任意阶段不丢失精度。

玩家不直接与此系统交互。它是所有资源显示、战斗计算、成长公式和离线模拟的底层依赖——7 个系统直接依赖它，间接依赖贯穿全部 30 个 MVP 系统。没有它，游戏的中后期数值体系将无法表达。

## Player Fantasy

玩家不会"看到"大数值系统，但他们会感受到一个没有天花板的成长世界。当修为从百位跳到万亿、从万亿跳到科学计数法（那个"1.23e15 首次出现在屏幕上"的时刻）、从科学计数法跳到指数塔——每一次数位跃升都是修仙世界观中"破境飞升"的量化映射。数字的无限膨胀让"凡人成长为诸天至尊"不再只是一句文案，而是玩家亲身经历的数值体验。系统永远不会告诉你"你已经到顶了"。

## Detailed Design

### Core Rules

1. **内部表示**：每个 BigNumber 实例存储两个值：
   - `mantissa: float` — 有效数字部分，归一化到 `[1.0, 10.0)` 范围
   - `exponent: int` — 10 的幂次，范围 `[0, 308]`
   - 数学含义：`value = mantissa × 10^exponent`

2. **零值表示**：`mantissa = 0.0, exponent = 0`。BigNumber 不支持负数——任何会产生负数的运算结果钳位到零。

3. **归一化规则**：每次运算后，结果必须归一化：
   - 若 `mantissa == 0.0`：设 `exponent = 0`
   - 若 `mantissa >= 10.0`：`mantissa /= 10.0`，`exponent += 1`，循环直到 `mantissa < 10.0`
   - 若 `mantissa < 1.0` 且 `mantissa > 0.0`：`mantissa *= 10.0`，`exponent -= 1`，循环直到 `mantissa >= 1.0`
   - 若归一化后 `exponent > 308`：钳位到 `{mantissa: 9.999..., exponent: 308}`（float max 上限）
   - 若归一化后 `exponent < 0`：钳位到零

4. **运算规则**：

   **加法 `a + b`**：
   - 若 `|a.exponent - b.exponent| > 15`：较小值可忽略，返回较大值
   - 否则：将较小数的 mantissa 右移指数差后相加，归一化

   **减法 `a - b`**：
   - 若 `a < b`：返回零（非负约束）
   - 否则：同加法的对齐逻辑，mantissa 相减，归一化

   **乘法 `a × b`**：
   - `mantissa = a.mantissa × b.mantissa`
   - `exponent = a.exponent + b.exponent`
   - 归一化

   **除法 `a ÷ b`**：
   - 若 `b == 0`：返回 max value `{9.999..., 308}`（除零保护）
   - `mantissa = a.mantissa / b.mantissa`
   - `exponent = a.exponent - b.exponent`
   - 归一化

   **幂运算 `a ^ n`**（n 为 float）：
   - `mantissa = a.mantissa ^ n`
   - `exponent = round(a.exponent × n)`
   - 归一化

   **对数 `log10(a)`**：返回普通 float
   - `result = log10(a.mantissa) + a.exponent`

   **比较**：先比较 exponent，相同则比较 mantissa

5. **API 表面**：
   - 运算符重载：`+`, `-`, `*`, `/`, `==`, `<`, `>`, `<=`, `>=`
   - 命名方法：`add()`, `subtract()`, `multiply()`, `divide()`, `power()`, `log10()`
   - 工厂方法：`BigNumber.from_int()`, `BigNumber.from_float()`, `BigNumber.from_string()`, `BigNumber.zero()`
   - 转换方法：`to_int()`, `to_float()`, `to_string()`, `to_dict()`
   - 查询方法：`is_zero()`, `is_max()`, `magnitude()`（返回 exponent）
   - 静态常量：`BigNumber.ZERO`, `BigNumber.ONE`, `BigNumber.MAX`

6. **序列化格式**：`{"m": 1.234, "e": 150}` — JSON 兼容的 Dictionary

### States and Transitions

BigNumber 是无状态的值类型（value type），不适用状态机。每个实例是不可变的数学值——运算返回新实例，不修改原值。

### Interactions with Other Systems

| 系统 | 方向 | 数据接口 | 说明 |
|------|------|---------|------|
| 数值格式化系统 | 下游消费 | `BigNumber.to_string()` + `magnitude()` | 格式化系统读取 mantissa 和 exponent 生成中文/科学计数法显示 |
| 数据配置系统 | 下游消费 | `BigNumber.from_string()` / `from_float()` | 配置表中的数值字段反序列化为 BigNumber |
| 公式引擎 | 双向 | BigNumber 作为公式输入/输出的唯一数值类型 | 公式引擎的变量、计算和结果全部使用 BigNumber |
| 修正器/倍率引擎 | 双向 | BigNumber 作为 modifier 叠加的载体 | 加法 modifier 用 `add()`，乘法 modifier 用 `multiply()`，指数 modifier 用 `power()` |
| 资源系统 | 下游消费 | 所有资源值存储为 BigNumber | 资源的增减、上限检查、溢出检测 |
| 属性系统 | 下游消费 | 所有角色属性存储为 BigNumber | 攻击、防御、生命等属性的存储与计算 |
| 物品/材料系统 | 下游消费 | 物品价值、堆叠数量用 BigNumber | 物品的出售价格、材料数量 |

## Formulas

### 归一化 (Normalization)

`normalize(mantissa, exponent) → {mantissa, exponent}`

**变量：**
| 变量 | 符号 | 类型 | 范围 | 说明 |
|------|------|------|------|------|
| mantissa | m | float | 任意正 float | 运算后的原始有效数字 |
| exponent | e | int | 任意 int | 运算后的原始幂次 |

**输出范围：** `m ∈ [0.0] ∪ [1.0, 10.0)`，`e ∈ [0, 308]`

**规则：**
- 若 `m == 0.0` → 返回 `{0.0, 0}`
- 若 `m >= 10.0` → `m /= 10.0`，`e += 1`，循环
- 若 `m < 1.0` → `m *= 10.0`，`e -= 1`，循环
- 若 `e > 308` → 钳位到 `{9.999999999999999, 308}`
- 若 `e < 0` → 返回 `{0.0, 0}`

**示例：** `normalize(123.456, 5)` → `{1.23456, 7}`（即 1.23456 × 10^7）

### 加法 (Addition)

`add(a, b) → result`

**变量：**
| 变量 | 符号 | 类型 | 范围 | 说明 |
|------|------|------|------|------|
| a.mantissa | mₐ | float | [1.0, 10.0) | 第一个操作数有效数字 |
| a.exponent | eₐ | int | [0, 308] | 第一个操作数幂次 |
| b.mantissa | m_b | float | [1.0, 10.0) | 第二个操作数有效数字 |
| b.exponent | e_b | int | [0, 308] | 第二个操作数幂次 |

**输出范围：** `BigNumber(0)` 到 `BigNumber(9.999, 308)`

**计算过程：**
1. 若 `|eₐ - e_b| > 15`：返回较大的操作数（较小值可忽略）
2. 设 `e_diff = eₐ - e_b`
3. 若 `e_diff >= 0`：`result_m = mₐ + m_b × 10^(-e_diff)`，`result_e = eₐ`
4. 若 `e_diff < 0`：`result_m = m_b + mₐ × 10^(e_diff)`，`result_e = e_b`
5. 返回 `normalize(result_m, result_e)`

**示例：** `add({2.5, 3}, {3.0, 2})` → e_diff=1, result_m = 2.5 + 3.0×10^(-1) = 2.8, result_e = 3 → `{2.8, 3}` = 2800

### 减法 (Subtraction)

`subtract(a, b) → result`

**变量：** 同加法

**输出范围：** `BigNumber(0)` 到 `BigNumber(9.999, 308)`

**计算过程：**
1. 若 `a < b`：返回 `BigNumber.ZERO`（非负约束）
2. 对齐逻辑同加法，mantissa 相减
3. 返回 `normalize(result_m, result_e)`

**示例：** `subtract({5.0, 3}, {2.0, 3})` → result_m = 5.0 - 2.0 = 3.0, result_e = 3 → `{3.0, 3}` = 3000

### 乘法 (Multiplication)

`multiply(a, b) → result`

**变量：** 同加法

**输出范围：** `BigNumber(0)` 到 `BigNumber(9.999, 308)`

**计算过程：**
1. `result_m = mₐ × m_b`
2. `result_e = eₐ + e_b`
3. 返回 `normalize(result_m, result_e)`

**示例：** `multiply({2.0, 5}, {3.0, 3})` → result_m = 6.0, result_e = 8 → `{6.0, 8}` = 600000000

### 除法 (Division)

`divide(a, b) → result`

**变量：** 同加法

**输出范围：** `BigNumber(0)` 到 `BigNumber(9.999, 308)`

**计算过程：**
1. 若 `b == 0`：返回 `BigNumber.MAX`（除零保护）
2. `result_m = mₐ / m_b`
3. `result_e = eₐ - e_b`
4. 返回 `normalize(result_m, result_e)`

**示例：** `divide({6.0, 8}, {2.0, 5})` → result_m = 3.0, result_e = 3 → `{3.0, 3}` = 3000

### 幂运算 (Power)

`power(a, n) → result`

**变量：**
| 变量 | 符号 | 类型 | 范围 | 说明 |
|------|------|------|------|------|
| a.mantissa | mₐ | float | [1.0, 10.0) | 底数有效数字 |
| a.exponent | eₐ | int | [0, 308] | 底数幂次 |
| n | n | float | [0.0, 100.0] | 指数（普通 float） |

**输出范围：** `BigNumber(0)` 到 `BigNumber(9.999, 308)`

**计算过程：**
1. 若 `n == 0`：返回 `BigNumber.ONE`
2. 若 `n == 1`：返回 a
3. `total_log = log10(mₐ) + eₐ`
4. `result_e = floor(total_log × n)`
5. `result_m = 10^(total_log × n - result_e)`
6. 返回 `normalize(result_m, result_e)`

**示例：** `power({2.0, 10}, 2.0)` → total_log = 0.301 + 10 = 10.301, result_e = 20, result_m = 10^(0.602) ≈ 4.0 → `{4.0, 20}` = 4e20

### 对数 (Log10)

`log10(a) → float`

**变量：**
| 变量 | 符号 | 类型 | 范围 | 说明 |
|------|------|------|------|------|
| a.mantissa | mₐ | float | [1.0, 10.0) | 有效数字 |
| a.exponent | eₐ | int | [0, 308] | 幂次 |

**输出范围：** `0.0` 到 `308.999...`（返回普通 float）

**计算过程：**
1. 若 `a == 0`：返回 `0.0`
2. `result = log10(mₐ) + eₐ`

**示例：** `log10({3.16, 5})` → log10(3.16) + 5 ≈ 0.5 + 5 = 5.5

## Edge Cases

- **If 除法的除数为零**：返回 `BigNumber.MAX`（饱和算术，不抛异常）。放置游戏中除零通常由配置错误导致，不应崩溃。
- **If 减法结果为负**：返回 `BigNumber.ZERO`（非负约束）。修仙游戏的资源值、属性值、倍率值均无负数语义。
- **If 运算后 exponent 超过 308**：返回 `BigNumber.MAX {9.999, 308}`。1e308 已远超任何合理游戏数值，达到此值通常表示配置错误或无限循环。
- **If 运算后 exponent 小于 0**：返回 `BigNumber.ZERO`。结果小于 1 且不可表示时，按零处理。
- **If 加法中两个操作数的 exponent 差超过 15**：忽略较小值，返回较大值。float 精度约 15-16 位有效数字，超出此范围的加法对结果无贡献。
- **If 两个非常接近的大数相减**：mantissa 可能出现精度丢失（catastrophic cancellation）。接受此限制——放置游戏中精确到个位的差值无实际意义。
- **If 幂运算指数 n 为负数**：返回 `BigNumber.ZERO`。负指数产生小于 1 的值，超出非负范围。
- **If 幂运算指数 n 超过 100.0**：钳位到 100.0 后计算。超过此值的幂运算几乎必然溢出到 MAX，提前钳位避免无效计算。
- **If 幂运算底数为零**：若 `n == 0` 返回 `BigNumber.ONE`（0^0 = 1 的约定），否则返回 `BigNumber.ZERO`。
- **If log10 参数为零**：返回 `0.0`。数学上未定义，但游戏中 log10(0) 应视为"无量级"。
- **If mantissa 出现 NaN 或 Inf**（由 float 运算异常导致）：返回 `BigNumber.ZERO`。NaN/Inf 不应传播到游戏逻辑。
- **If MAX 值参与运算**（MAX + anything, MAX × anything）：结果仍为 MAX（饱和）。防止溢出循环。
- **If from_string 接收到非法输入**（负数、非数字字符串、空字符串）：返回 `BigNumber.ZERO`。反序列化不应崩溃。
- **If from_string 接收到超大值**（如 "1e9999"）：返回 `BigNumber.MAX`。超出表示范围的值钳位。
- **If from_float 接收到负 float**：返回 `BigNumber.ZERO`。abs 后若超出范围则归一化钳位。

## Dependencies

| 系统 | 方向 | 依赖性质 | 数据接口 |
|------|------|---------|---------|
| 数值格式化系统 | 下游依赖 BigNumber | 硬依赖 | 读取 `mantissa` + `exponent` 用于格式化显示 |
| 数据配置系统 | 下游依赖 BigNumber | 硬依赖 | 配置表数值字段反序列化为 BigNumber 实例 |
| 公式引擎 | 下游依赖 BigNumber | 硬依赖 | 公式变量、中间计算、最终结果全部使用 BigNumber |
| 修正器/倍率引擎 | 下游依赖 BigNumber | 硬依赖 | modifier 的叠加运算使用 BigNumber 的 `add()` / `multiply()` / `power()` |
| 资源系统 | 下游依赖 BigNumber | 硬依赖 | 所有资源值（灵气、修为、灵石等）存储为 BigNumber |
| 属性系统 | 下游依赖 BigNumber | 硬依赖 | 所有角色属性（攻击、防御、生命等）存储为 BigNumber |
| 物品/材料系统 | 下游依赖 BigNumber | 硬依赖 | 物品价值、材料数量使用 BigNumber |

**上游依赖**：无。BigNumber 是 Foundation 层零依赖基础设施。

**双向一致性**：上述 7 个系统的 GDD 应在 Dependencies 节中列出"上游依赖大数值系统"。本 GDD 设计完成后，后续 GDD 的依赖声明需与此表保持一致。

## Tuning Knobs

| 参数 | 当前值 | 安全范围 | 增大影响 | 减小影响 |
|------|--------|---------|---------|---------|
| `MAX_EXPONENT` | 308 | [100, 500] | 扩大可表示范围；超过 308 后归一化需特殊处理 float 精度边界 | 缩小数值天花板；可能限制后期飞升/轮回的数值膨胀空间 |
| `ADDITION_PRECISION_DIGITS` | 15 | [10, 18] | 加法精度更高，更多小数值参与计算，运算稍慢 | 忽略更多小数值，加法更快，但数值漂移可能累积 |
| `POWER_EXPONENT_CAP` | 100.0 | [10.0, 500.0] | 允许更大的幂运算，但几乎必然溢出到 MAX | 限制幂运算增长速度，防止数值爆炸过快 |
| `ENABLE_SATURATED_ARITHMETIC` | true | [true, false] | 溢出时钳位到 MAX，行为可预测 | 关闭后溢出行为未定义（仅用于调试，不建议生产关闭） |
| `DEFAULT_SERIALIZATION_FORMAT` | "dict" | ["dict", "string"] | 使用 `{"m":1.23,"e":5}` 格式，JSON 原生兼容 | 使用 `"1.23e5"` 字符串格式，更易读但需解析 |

**说明**：BigNumber 是基础设施系统，调参空间有限。上述 5 个参数在游戏运行时不应动态修改——它们是实现时的编译期常量或项目配置，由开发者调整而非设计师。

## Acceptance Criteria

- [ ] **GIVEN** 任意正 float 值，**WHEN** 通过 `BigNumber.from_float()` 创建实例，**THEN** `mantissa ∈ [1.0, 10.0)` 且 `exponent` 使得 `mantissa × 10^exponent` 等于原始值
- [ ] **GIVEN** 两个 BigNumber `a = {2.5, 3}` 和 `b = {3.0, 2}`，**WHEN** 执行 `a.add(b)`，**THEN** 结果为 `{2.8, 3}`（即 2800）
- [ ] **GIVEN** `a = {2.0, 3}` 和 `b = {5.0, 3}`，**WHEN** 执行 `a.subtract(b)`，**THEN** 结果为 `BigNumber.ZERO`（非负约束）
- [ ] **GIVEN** `a = {2.0, 5}` 和 `b = {3.0, 3}`，**WHEN** 执行 `a.multiply(b)`，**THEN** 结果为 `{6.0, 8}`
- [ ] **GIVEN** `a = {6.0, 8}` 和 `b = {2.0, 5}`，**WHEN** 执行 `a.divide(b)`，**THEN** 结果为 `{3.0, 3}`
- [ ] **GIVEN** `a = {2.0, 10}`，**WHEN** 执行 `a.power(2.0)`，**THEN** 结果为 `{4.0, 20}`
- [ ] **GIVEN** `a = {3.16, 5}`，**WHEN** 执行 `a.log10()`，**THEN** 结果约为 5.5（float，误差 < 0.01）
- [ ] **GIVEN** `b = BigNumber.ZERO`，**WHEN** 执行 `a.divide(b)`，**THEN** 结果为 `BigNumber.MAX`
- [ ] **GIVEN** 运算结果使 exponent > 308，**WHEN** 归一化执行，**THEN** 结果钳位为 `{9.999, 308}`
- [ ] **GIVEN** 运算结果使 exponent < 0，**WHEN** 归一化执行，**THEN** 结果为 `BigNumber.ZERO`
- [ ] **GIVEN** mantissa 出现 NaN 或 Inf，**WHEN** 归一化执行，**THEN** 结果为 `BigNumber.ZERO`
- [ ] **GIVEN** 字符串 `"1.23e150"`，**WHEN** 执行 `BigNumber.from_string()`，**THEN** 结果为 `{1.23, 150}`
- [ ] **GIVEN** 字符串 `"abc"` 或 `""` 或 `"-5"`，**WHEN** 执行 `BigNumber.from_string()`，**THEN** 结果为 `BigNumber.ZERO`
- [ ] **GIVEN** 字符串 `"1e9999"`，**WHEN** 执行 `BigNumber.from_string()`，**THEN** 结果为 `BigNumber.MAX`
- [ ] **GIVEN** 任意 BigNumber 实例，**WHEN** 执行 `to_dict()` 后再 `BigNumber.from_dict(result)`，**THEN** 结果与原值相等
- [ ] **GIVEN** `a = BigNumber.MAX`，**WHEN** 执行 `a.add(BigNumber.ONE)`，**THEN** 结果为 `BigNumber.MAX`（饱和）
- [ ] **GIVEN** 两个操作数 exponent 差 > 15，**WHEN** 执行加法，**THEN** 结果等于较大操作数
- [ ] **GIVEN** 两个相等值的 BigNumber，**WHEN** 执行 `a == b`，**THEN** 结果为 `true`
- [ ] **GIVEN** 1000 个 BigNumber 实例执行各 100 次加减乘除，**WHEN** 在单帧内完成，**THEN** 总耗时 < 16.6ms（60fps 帧预算内）
- [ ] **GIVEN** `BigNumber.from_int(0)`，**WHEN** 创建零值实例，**THEN** `is_zero()` 返回 `true`，`mantissa == 0.0`，`exponent == 0`
- [ ] **GIVEN** `a = {2.0, 3}` 且 `n = 0`，**WHEN** 执行 `a.power(n)`，**THEN** 结果为 `BigNumber.ONE`

## Open Questions

| Question | Owner | Deadline | Resolution |
|----------|-------|----------|-----------|
| 纯 GDScript mantissa+exponent 的性能是否满足离线模拟批量运算需求？需原型验证 | 开发者 | 架构阶段前 | — |
| 是否需要在 MVP 后期迁移到 GDExtension C++ 以提升性能？ | 技术总监 | MVP 完成后评估 | — |
| `from_string()` 是否需要支持中文数字格式（如 "1.23万亿"）？还是由数值格式化系统单向处理？ | 设计师 | 数值格式化系统 GDD 时决定 | — |
