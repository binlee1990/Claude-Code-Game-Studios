# 产出乘数系统 (Output Multiplier System)

> **Status**: Designed
> **Author**: binlee1990 + agents
> **Last Updated**: 2026-05-03
> **Implements Pillar**: 4.1 数字增长就是快乐 · 4.10 数据驱动与可扩展
> **Creative Director Review (CD-GDD-ALIGN)**: APPROVED 2026-05-03

## Overview

产出乘数系统是资源产出速率与修正器/倍率引擎之间的翻译层。游戏中的每个资源（灵气、修为、灵石、药材、战斗经验）背后都有一个"产出倍率"——来自装备加成、技能天赋、境界突破、灵丹 Buff、区域效果等多个来源——这些来源各自属于不同的叠加池（池内先加总再乘、池间独立相乘）。产出乘数系统的核心职责是：**为每种资源定义具体的产出乘数来源集合、每个来源归属的叠加池、以及池间叠乘顺序**，然后将这些注册到修正器/倍率引擎，最终计算出该资源的"每 tick 产出量 = 基础产出 × 总倍率"，供自动产出系统和修炼系统直接使用。

从玩家视角看，产出乘数系统是 HUD 上数字跳动速度的油门。玩家给角色换了一件 +15% 装备产出率的戒指、激活了攻击阵法（×1.5 灵气产出）、突破了炼气境（×2.0 修为产出）——这些选择在底层都被翻译为修正器注册操作，产出乘数系统确保装备的 +15% 和阵法的 ×1.5 不在同一个池里互相吞掉、确保境界的 ×2.0 对所有资源独立生效。玩家不需要理解叠加池的数学，但他们会观察到：**每一个"增加产出"的配置选择都忠实、可预期地反映在产出速度上**。没有这个系统，产出加成可能"差不多生效了"，也可能"意外放大了三倍"——可信任的成长感就会崩塌。

## Player Fantasy

产出乘数系统是修仙世界的"灵脉图谱"——它不计算、不存储、不展示，它只做一件事：定义每条灵脉（产出来源）流向哪里、各脉之间如何交汇。

**锚定时刻 1 —— 笃定感**：玩家换上一枚 +15% 灵气产出的戒指，HUD 上的"灵气/秒"数字在下一次 tick 时从 1,200 跳到了 1,380。玩家心算：1200 × 1.15 = 1380，完全吻合。不需要点开面板验证、不需要怀疑"是不是真的生效了"。这种"换装即见效、数字可心算"的确定性，是产出乘数系统提供的最核心情感。在一个充满随机掉落、概率突破的修仙世界中，产出乘数系统是玩家唯一可以**绝对信任**的东西——装备池 +15% 就是 ×1.15，境界池 ×2.0 就是 ×2.0，不同池的加成各自独立、永不互吞。天道酬勤，不偏不倚。

**锚定时刻 2 —— 策略发现**：玩家卡在瓶颈，灵气产出不够突破下一个境界。试过换更好的装备（+10%），效果一般。然后激活了闲置的"聚灵阵"——阵法池 +50%，与装备池独立相乘。产出从 1,200 跳到了 1,200 × 1.10 × 1.50 = 1,980，涨了 65% 而非 60%。她意识到：**不是所有加成平等，跨域组合才是王道**。从此开始有意识地平衡装备、境界、阵法、丹药四个方向的投入。这种"从可预测中悟出策略"的进阶体验，把产出乘数系统从"公正度量衡"升级为**隐秘的策略导师**——池结构本身就是在无声地教导玩家：同源叠加是庸才之道（加算池），跨源共振是天才之道（乘算池）。

这两个锚定时刻共同兑现 pillar 4.1"数字增长就是快乐"的深层含义：增长不止是"数字变大"，更是**增长可以被理解、被预测、被策略性地放大**。同时命中 pillar 4.2"放置不是无操作，而是低频高价值决策"——装备配装、阵法选择、境界突破这些低频决策之所以有价值，正是因为产出乘数系统在底层忠实兑现了每一个决策的数学后果。

**重要边界声明**：产出乘数系统是上述体验的**必要基础设施**，而非体验的直接载体。玩家看到的"灵气/秒 1,380"是 HUD 系统渲染的，装备切换是 UI 框架提供的，阵法激活是战斗系统/宗门系统触发的。本系统只承担"来源归类 → 池分配 → 注册修正器 → 输出最终倍率"这一条管线，确保经过这条管线的每一个乘数都是正确、可追溯、可审计的。

**支柱对应**：
- **4.1 数字增长就是快乐**：产出乘数系统确保增长是可理解、可预期的。玩家看到的不是"灵气大概在涨"，而是"我的每一个产出加成选择都精确地转化为产出速度"。
- **4.10 数据驱动与可扩展**：新增一个产出来源（如 Alpha 阶段的"宗门聚灵阵 +30% 灵气产出"）只需在配置表中追加一条定义——来源名、归属池、倍率值——不需要改动任何产出系统的代码。

## Detailed Design

### Core Rules

1. **架构形态**：`OutputMultiplierSystem` 为 `RefCounted` 服务类，由 Autoload 单例 `/root/OutputMultiplierSystem` 持有。独立于 ModifierEngine——通过**组合**持有 `ModifierEngine` 引用并调用其 API，不继承、不包装。与 ResourceSystem/AttributeSystem/ModifierEngine 同型架构。

2. **职责边界**：OutputMultiplierSystem 是产出域的**翻译层**。三件事它做：
   - 定义每种资源的产出乘数来源集合和池归属映射
   - 接收来源系统（装备/境界/区域/Buff）的激活/注销请求，翻译为 ModifierEngine 注册操作
   - 为消费者（自动产出、修炼）提供最终产出速率查询
   
   三件事它**不做**：
   - 不计算叠加（ModifierEngine 的职责）
   - 不存储资源值（ResourceSystem 的职责）
   - 不决定 tick 频率（TimeManager / AutoProduction 的职责）

3. **配置驱动**：启动时通过 `DataConfig.get("production_config")` 加载 `production_config.json`，缓存在内部 `base_rates: Dictionary[String, float]`、`fractional_carry: Dictionary[String, float]` 和 `resource_configs: Dictionary[String, Dictionary]` 中。配置格式：
   ```json
   {
     "lingqi": {
       "base_rate_per_second": "1.0",
       "allows_passive": true,
       "passive_sources": ["realm", "equipment", "zone", "buff"]
     },
     "xiuwei": {
       "base_rate_per_second": "0.1",
       "allows_passive": true,
       "passive_sources": ["realm", "equipment", "zone", "buff"]
     },
     "lingshi": {
       "base_rate_per_second": "0.1",
       "allows_passive": true,
       "passive_sources": ["realm", "equipment", "zone", "buff"]
     },
     "herb": {
       "base_rate_per_second": "0.02",
       "allows_passive": true,
       "passive_sources": ["realm", "equipment", "zone", "buff"]
     },
     "exp": {
       "base_rate_per_second": "0",
       "allows_passive": false,
       "passive_sources": []
     }
   }
   ```
   - `allows_passive = false` 时，该资源的所有被动产出查询返回 `BigNumber.ZERO`（exp 仅来自战斗管线）
   - `passive_sources` 白名单控制哪些来源类型对该资源生效
   - `base_rate_per_second` 的字符串格式由 `String.to_float()` / 等价安全解析读取（支持 `"1.0"`, `"0.1"`, `"1e3"` 等）
   - 基础速率允许 `< 1.0`；这些亚单位速率不得先转换为 BigNumber，否则会被 BigNumber 的 `exponent < 0` 规则钳位为 ZERO

4. **产出来源分类（MVP）**：4 类产出来源，直接映射到 ModifierEngine 同名乘法池：

   | 来源 ID | 中文 | 性质 | 对应池 | 生命周期 | 跨资源 |
   |---------|------|------|--------|---------|--------|
   | `realm` | 境界加成 | 永久 | `realm` | 境界突破时激活，永不过期 | 是（同一境界倍率对全部 4 资源生效） |
   | `equipment` | 装备加成 | 装备绑定 | `equipment` | 装备时激活，卸下时注销 | 否（每件装备指定加成哪些资源） |
   | `zone` | 区域加成 | 区域绑定 | `zone` | 进入区域时激活，离开时注销 | 是（每区域定义各自对 4 资源的倍率） |
   | `buff` | 丹药/阵法 | 临时 | `buff` | 使用/激活时开始，duration 到期或手动取消 | 是 |

   **MVP 排除**：`skill`（技能树 Alpha 阶段）、`milestone`（成就系统 Post-MVP）。exp 不在此系统管辖——战斗产出走战斗掉落管线。

   **池隔离机制**：ModifierEngine 的池按 `(target, pool)` 二元组隔离。`"lingqi_production"` target 下的 `"equipment"` 池与 `"player.atk"` target 下的 `"equipment"` 池互不干扰——**无需为产出创建独立池前缀**，直接复用既有池名。

5. **Target 命名约定**：`"{resource_id}_production"`（如 `"lingqi_production"`），与 ModifierEngine GDD 中约定的产出域 target 格式一致。调用 `ModifierEngine.apply("lingqi_production", base_bn)` 查询灵气最终产出。

6. **叠加模型**：完全委托给 ModifierEngine 的三阶段管线：
   ```
   final_rate_float = base_rate_float × Π pool_mult(pool)  for pool ∈ {realm, equipment, zone, buff}
   ```
   这意味着：
   - 同一池内多个来源先加总再乘（如两件装备 +15% 和 +10% → 池倍率 = 1.0 + 0.15 + 0.10 = 1.25，非 1.15 × 1.10）
   - 不同池之间独立相乘（境界 ×2.0 + 装备 ×1.25 + 区域 ×1.10 + Buff ×1.20 → 总倍率 = 2.0 × 1.25 × 1.10 × 1.20 = 3.30）
   - OMS 不注册 ADD 类型产出修正；平坦的每秒产出改动应通过配置层调整 `base_rate_per_second`，乘数来源一律使用 MULT

7. **来源注册 API**（供装备/境界/区域/Buff 系统调用）：
   ```
   activate_source(source_def: Dictionary) → String
   # source_def = {
   #   "resource_id": String,      # 目标资源（必需）
   #   "source_type": String,      # "realm"|"equipment"|"zone"|"buff"（必需）
   #   "value": float,             # 修正值，0.15 表示 +15%（必需）
   #   "source_id": String,        # 唯一来源标识，如 "equip_ring_001", "realm_liandan"（必需）
   #   "duration": float           # 秒，0=永久（可选，默认 0）
   # }
   # 内部流程：
   #   1. 校验 resource_id 在配置中存在且 allows_passive=true
   #   2. 校验 source_type 在 passive_sources 白名单中
   #   3. 构造 ModifierEngine 注册：{target: "{resource_id}_production", type: MULT, value, pool: source_type, source: source_id, duration}
   #   4. 调用 ModifierEngine.register()
   #   5. 记录返回的 modifier_id 到内部 active_sources[source_id]
   #   6. 发布 EventBus "production_multiplier_changed" 事件
   #   7. 返回 modifier_id（空字符串表示注册失败）
   
   deactivate_source(source_id: String) → int
   # 调用 ModifierEngine.unregister_by_source(source_id)
   # 返回被注销的 modifier 数量
   # 发布 EventBus "production_multiplier_changed" 事件
   ```

8. **消费者查询 API**（供 AutoProduction / Cultivation / HUD 调用）：
   ```
   get_production_rate(resource_id: String) → float
   # 返回该资源每秒最终产出速率（base_rate_float × total_multiplier）
   # allows_passive=false → 返回 0.0
   # 不存在 resource_id → 返回 0.0 + warning
   # 注意：速率是 float，因为 xiuwei/lingshi/herb 的 MVP 基础速率 < 1.0，不能用 BigNumber 表示

   get_tick_amount(resource_id: String, delta_seconds: float) → BigNumber
   # 主结算方法：get_production_rate(resource_id) × delta_seconds + fractional_carry[resource_id]
   # 若累计值 < 1.0：写回 fractional_carry，返回 BigNumber.ZERO
   # 若累计值 ≥ 1.0：清空该资源 carry，返回 BigNumber.from_float(accumulated)
   # AutoProduction 的主调用口

   get_multiplier(resource_id: String) → float
   # 返回当前总倍率（供 HUD 显示"灵气产出倍率: ×3.42"）
   # 委托给 ModifierEngine.get_multiplier("{resource_id}_production")

   get_breakdown(resource_id: String) → Dictionary
   # 返回详细分解（供调试面板/工具提示）
   # {
   #   "base_rate": float,               # 基础每秒产出（可 < 1.0）
   #   "add_sum": 0.0,                   # OMS 不使用 ADD 产出修正
   #   "pools": {                        # 每池倍率
   #     "realm": 2.0,
   #     "equipment": 1.25,
   #     "zone": 1.10,
   #     "buff": 1.20
   #   },
   #   "final_multiplier": float,        # 最终总倍率
   #   "rate_per_second": float,         # get_production_rate() 的值
   #   "fractional_carry": float         # 当前亚单位余数，供调试显示
   # }
   ```

9. **初始化与生命周期**：
   - `_ready()`: assert `DataConfig != null` 且 `ModifierEngine != null`，调用 `load_config()` 加载 `production_config.json` 并缓存
   - 启动时**不预先注册任何 modifier**——所有来源在上层系统激活时才注册。这意味着如果没有装备/境界/区域/Buff 系统注册任何修正器，`get_multiplier()` 返回 `1.0`，`get_production_rate()` 返回纯 base_rate float
   - 初始化配置时为每个资源建立 `fractional_carry[id] = 0.0`；热重载保留仍存在资源的 carry，移除已删除资源的 carry
   - 支持运行时 `reload_config()` 用于开发调试（重新从 DataConfig 加载，不重置已注册的 modifier）

10. **MVP 初始倍率约定**（临时硬编码，Alpha 转为配置驱动）：
    - 凡人境界：无加成（倍率 1.0）
    - 炼气境：所有资源产出 ×2.0（`realm` 池，permanent）
    - 东海区域：lingqi ×1.0, xiuwei ×1.0, lingshi ×1.0, herb ×1.5（`zone` 池）
    - 装备词条：+15% 或 +10% 某资源产出（`equipment` 池，MULT value=0.15/0.10）
    - 灵丹：+20% 全资源产出，持续 300s（`buff` 池，duration=300）

11. **事件发布**：来源激活或注销时，发布 `production_multiplier_changed` 事件：
    ```
    EventBus.emit("production_multiplier_changed", {
      "resource_id": "lingqi",
      "source_id": "equip_ring_001",
      "action": "activated" | "deactivated",
      "new_multiplier": 3.42
    })
    ```
    HUD 和调试面板订阅此事件以刷新产出速率显示。**注意**：此事件只在 modifier 注册/注销时发布，不在每 tick 查询时发布——高频率查询走 ModifierEngine 缓存（dirty-flag 模式），不产生事件。

12. **输入校验**（安全降级，不崩溃）：
    - `resource_id` 不在配置中：`get_production_rate()` 返回 ZERO，`activate_source()` 返回 `""`，打印 warning
    - `allows_passive = false`：所有查询返回 ZERO（非错误），`activate_source()` 拒绝并打印 warning
    - `source_type` 不在 `passive_sources` 白名单中：`activate_source()` 拒绝，打印 warning
    - `activate_source()` 缺少必填字段：拒绝，返回 `""`，打印 warning 列出缺失字段
    - `value = 0` 或 `NaN`/`Inf`：拒绝，打印 warning（零值修正无意义）
    - `deactivate_source()` 对不存在的 source_id：返回 0（幂等，与 ModifierEngine 行为一致）
    - `get_tick_amount()` 的 `delta_seconds ≤ 0`：返回 ZERO，打印 warning

13. **性能预算**：
    - 单次 `get_production_rate()` 耗时：~0.005 ms（base_rate Dict lookup + ModifierEngine cache hit + float multiply）
    - 单次 `get_tick_amount()` 额外执行一次 carry 字典读写和一次 BigNumber.from_float（仅累计值 ≥1 时）
    - 每 tick（≥0.5s）对 4 个被动资源各查询一次，典型 < 0.03 ms，远低于帧预算
    - 自身无缓存层——完全依赖 ModifierEngine 的 target-level dirty-flag 缓存

### States and Transitions

OutputMultiplierSystem 整体**无状态机**——纯翻译层 + 配置缓存。单个产出来源的生命周期：

```
[Source Inactive] ──activate_source()──→ [Source Active]
       ↑                                        │
       └────deactivate_source()─────────────────┘
                                              │
                                    [duration 到期（ModifierEngine 自动注销）]
                                              │
       ┌──────────────────────────────────────┘
       ↓
[Source Inactive] + "production_multiplier_changed" 事件
```

- **Source Active = modifier 已在 ModifierEngine 注册且在有效期内**
- **Source Inactive = modifier 已从 ModifierEngine 注销（主动或过期）**
- OMS 不追踪"活跃/过期"状态——过期由 ModifierEngine 的 `update(delta)` 和 `modifier_expired` 事件处理。OMS 订阅 `modifier_expired` → 清理 `active_sources` 中对应的 ID → 发布 `production_multiplier_changed`

### Interactions with Other Systems

| 系统 | 方向 | 依赖性质 | 数据接口 |
|------|------|---------|---------|
| **修正器/倍率引擎** | 上游依赖 | 硬依赖 | 调用 `register()` / `unregister_by_source()` / `apply()` / `get_multiplier()` / `get_breakdown()`。所有叠加数学委托给此系统。OMS 无法脱离 ModifierEngine 独立工作 |
| **大数值系统** | 上游依赖 | 硬依赖 | `get_tick_amount()` 在累计产出 ≥1.0 后返回 BigNumber，供 ResourceSystem 入账；速率本身使用 float，避免亚单位被 BigNumber 钳位 |
| **数据配置系统** | 上游依赖 | 硬依赖 | 启动时调用 `DataConfig.get("production_config")` 加载 `production_config.json`；`reload_config()` 时重新读取 |
| **事件总线** | 上游依赖 | 硬依赖 | 发布 `"production_multiplier_changed"` 事件；订阅 `"modifier_expired"` 事件（清理过期 modifier 的内部追踪） |
| **资源系统** | **无直接关联** | — | OMS 不调用 ResourceSystem。OMS 的输出（BigNumber）由 AutoProduction/Cultivation 等调用方传入 `ResourceSystem.add()` |
| **自动产出系统** | 下游消费 | 硬依赖 | 每 tick 调用 `OMS.get_tick_amount(id, delta)`；返回非 ZERO 时传入 `ResourceSystem.add(id, amount)`，亚单位余数由 OMS carry 保留 |
| **修炼系统** | 下游消费 | 硬依赖 | 调用 `OMS.get_tick_amount("lingqi", delta)` 和 `OMS.get_tick_amount("xiuwei", delta)` 获取修炼产出；灵气→修为的主动消费另由修炼系统 GDD 定义 |
| **装备系统** | 下游 → 主动调用 | 软依赖（Alpha） | 装备时调用 `OMS.activate_source({resource_id, "equipment", value, item_id})`；卸下时调用 `OMS.deactivate_source(item_id)` |
| **境界突破系统** | 下游 → 主动调用 | 软依赖（Post-MVP） | 突破时调用 `OMS.activate_source({resource_id, "realm", value, "realm_XXXX"})`。MVP 可通过硬编码初始化基础境界加成 |
| **区域系统** | 下游 → 主动调用 | 软依赖 | 进入/离开区域时调用 `activate_source` / `deactivate_source`，source_type="zone" |
| **Buff 系统** | 下游 → 主动调用 | 软依赖（Alpha） | Buff 激活/失效时调用 `activate_source` / `deactivate_source`，source_type="buff" |
| **HUD 系统** | 下游 → 订阅 | 软依赖 | 订阅 `"production_multiplier_changed"` 事件，或轮询 `get_multiplier()` / `get_breakdown()` 刷新"灵气/秒"显示 |
| **调试控制台** | 下游 → 查询 | 软依赖 | 调用 `get_breakdown()` 输出全资源产出倍率分解 |
| **离线收益结算系统** | 下游 → 查询 | 软依赖 | 离线结算时优先调用 `get_tick_amount(id, offline_delta)` 取得已处理亚单位 carry 的离线总量；`get_production_rate()` 仅用于显示/估算 |

**双向一致性自检：**
- ✅ ModifierEngine GDD §Interactions 列出"产出乘数系统 — 调用 `apply('lingqi_production', base)` 计算最终产出"——一致
- ✅ ModifierEngine GDD §Dependencies 列出"产出乘数系统 — 定义具体产出来源和池分配，使用修正器引擎叠加"——一致
- ⚠️ ResourceSystem GDD §Interactions 声明"修正器/倍率引擎 — 无直接关联"——需确认 ResourceSystem 的 Interactions 表中未列出调用 ModifierEngine 的路径。ResourceSystem GDD 已在此处正确声明：产出乘数由 AutoProduction/Cultivation 在传入 `add()` 前应用。一致性通过。
- ✅ EventBus GDD §Core Rules 12 命名空间约定已追加 `"production_multiplier_changed"` 事件。

## Formulas

### 所有权声明

| 公式 | 所有权 | 定义位置 |
|------|-------|---------|
| `R_rate` — 最终每秒生产速率 | **OMS 拥有** | 本 GDD Formula 1 |
| `A_tick` — Tick 产出量 | **OMS 拥有** | 本 GDD Formula 2 |
| `M_total` — 乘数组合 | **OMS 文档化，ModifierEngine 计算** | 本 GDD Formula 3（声明式）；计算逻辑见 modifier-engine.md §Formulas 1-4 |
| `T_query` — 单次查询耗时 | **OMS 拥有** | 本 GDD Formula 4 |

**委托声明**：以下公式的数学语义属于产出乘数域，但其计算完全在 ModifierEngine 内部执行。本 GDD 在此仅引用，不重新定义：

| 委托公式 | 定义位置 | OMS 使用方式 |
|---------|---------|------------|
| `add_sum(target) = Σ v_i` | modifier-engine.md §Formula 1 | OMS 不使用 ADD 产出修正；`get_breakdown()` 固定报告 `0.0` |
| `pool_mult(target, pool) = 1.0 + Σ v_j` | modifier-engine.md §Formula 2 | 仅在 `get_breakdown()` 中通过 `get_pool_multiplier()` 查询 |
| `final_mult(target) = Π pool_mult(target, pool)` | modifier-engine.md §Formula 3 | `get_multiplier()` 直接委托；`get_production_rate()` 用该 float 乘以 `base_rate_float` |
| 缓存重算耗时 | modifier-engine.md §Formula 5 | 影响本系统 `T_query` 的缓存未命中项 |

---

### Formula 1: 最终每秒生产速率 (Production Rate Per Second)

`R_rate` 是本系统核心公式——将 `production_config.json` 中可为亚单位的基础速率与 ModifierEngine 返回的最终乘数结合。速率使用 `float`，因为 BigNumber 已明确只表示 `>= 1` 的绝对量。

```
R_rate(resource_id) = base_rate_float(resource_id) × ModifierEngine.get_multiplier("{resource_id}_production")
```

MVP 阶段所有 OMS 来源均为 MULT 类型；`add_sum` 不参与产出速率计算。

**变量：**

| 变量 | 符号 | 类型 | 范围 | 说明 |
|------|------|------|------|------|
| resource_id | id | String | `{"lingqi", "xiuwei", "lingshi", "herb"}` | 资源标识符。exp 不在此系统管辖（`allows_passive=false`） |
| base_rate_float | b | float | `[0.0, config_max]` | 从 `production_config.json` 加载的基础每秒产出。lingqi=1.0, xiuwei=0.1, lingshi=0.1, herb=0.02 |
| target | — | String | `"{id}_production"` | ModifierEngine 查询键，例 `"lingqi_production"` |
| final_mult | f | float | `[0.0, +∞)` | 所有池倍率的连乘积。由 ModifierEngine 计算并缓存（dirty-flag 模式）。无修正时 = 1.0 |
| R_rate | R | float | `[0.0, +∞)` | 该资源每秒最终产出速率，可小于 1.0 |

**输出范围：** `[0.0, +∞)`；若乘数溢出为 `INF` / `NaN`，查询返回 `0.0` 并打印 warning，避免污染资源账本。

**工作示例（灵气，中等境界，4 池全激活）：**

输入：
- `resource_id = "lingqi"`, `base_rate_float = 1.0`
- 境界池 `realm` 倍率 = 2.0（炼气境 ×2.0, value=1.0, MULT）
- 装备池 `equipment` 倍率 = 1.25（戒指 +15% + 护腕 +10%, value 相加 = 0.25, MULT）
- 区域池 `zone` 倍率 = 1.10（东海 +10%, value=0.10, MULT）
- Buff池 `buff` 倍率 = 1.20（聚灵丹 +20%, value=0.20, MULT）

ModifierEngine 计算：
```
final_mult = 2.0 × 1.25 × 1.10 × 1.20 = 3.30
R_rate = 1.0 × 3.30 = 3.30
```

结果：灵气每秒产出速率 **3.30**。

**`allows_passive = false` 时的行为**：`get_production_rate("exp")` 无视 ModifierEngine 状态，直接返回 `0.0`——战斗经验走战斗掉落管线，不参与被动产出乘数。

---

### Formula 2: Tick 产出量与亚单位余数 (Tick Amount With Sub-Unit Carry)

将每秒速率转换为离散时间片的可入账产出量。AutoProduction 和 Cultivation 的主调用口。

```
raw_tick(resource_id, delta) = R_rate(resource_id) × delta + carry_old(resource_id)

if raw_tick < 1.0:
  carry_new = raw_tick
  A_tick = BigNumber.ZERO
else:
  carry_new = 0.0
  A_tick = BigNumber.from_float(raw_tick)
```

**前置条件**：`delta > 0`；否则返回 `BigNumber.ZERO` 且不修改 carry。

**变量：**

| 变量 | 符号 | 类型 | 范围 | 说明 |
|------|------|------|------|------|
| resource_id | id | String | `{"lingqi", "xiuwei", "lingshi", "herb"}` | 资源标识符 |
| delta | Δt | float | `(0, +∞)` | 自上次 tick 的实耗秒数。由 TimeManager 提供 |
| R_rate | R | float | `[0.0, +∞)` | 来自 Formula 1 的每秒速率 |
| carry_old | c_old | float | `[0.0, 1.0)` | 上次未达到 BigNumber 最小可表示单位的亚单位余数 |
| raw_tick | q | float | `[0.0, +∞)` | 本次累计待入账产出 |
| carry_new | c_new | float | `[0.0, 1.0)` | 本次结算后保留的亚单位余数 |
| A_tick | A | BigNumber | `[ZERO, MAX]` | 本 tick 应传递给 `ResourceSystem.add()` 的产出量 |

**输出范围：** `[ZERO, BigNumber.MAX]`。

**delta 边界处理：**
- `delta ≤ 0`：返回 ZERO，打印 warning，carry 不变。时间不应倒流或停滞。
- `raw_tick < 1.0`：返回 ZERO 但不丢失产出；累积进 `fractional_carry`，后续 tick 达到 1.0 后一次性入账。
- `delta 无上限`：离线结算系统可传入任意时长（如 8h = 28800s）；当 raw_tick 足够大时直接转 BigNumber。
- 浮点 delta 精度：≥ 10^7 秒时 float 精度开始丢失最低有效位，但对游戏数值无实际影响。

**工作示例（灵气，delta = 0.5s，续上例）：**

```
R_rate("lingqi") = 3.30
raw_tick = 3.30 × 0.5 + 0.0 = 1.65
A_tick = BigNumber.from_float(1.65)
carry_new = 0.0
```

结果：本 tick 产出 1.65 灵气 → `ResourceSystem.add("lingqi", BigNumber.from_float(1.65))`。

**工作示例（修为，亚单位 tick 累积）：**

```
R_rate("xiuwei") = 0.1
delta = 5.0
raw_tick #1 = 0.5 + 0.0 = 0.5 -> A_tick = ZERO, carry = 0.5
raw_tick #2 = 0.5 + 0.5 = 1.0 -> A_tick = BigNumber.from_float(1.0), carry = 0.0
```

结果：修为不会因 BigNumber 亚单位钳位而永久为零；10 秒累计 1 点修为。

**工作示例（离线 30 分钟，灵石）：**

```
R_rate("lingshi") = 0.1 × 3.30 = 0.33
delta = 1800.0  (30 min)
raw_tick = 0.33 × 1800.0 + 0.0 = 594.0
A_tick = BigNumber.from_float(594.0)
```

结果：离线 30 分钟累计 594 灵石。

---

### Formula 3: 乘数组合 (Multiplier Composition) — 委托文档化

本系统**不计算**此公式——它是 ModifierEngine 叠加管线的声明式文档。写在此处是为了让读者无需跳转到 modifier-engine.md 即可理解产出乘数的叠加规则。

```
M_total(resource_id) = Π ( 1.0 + Σ v_{target, pool} )
```

对 `target = "{resource_id}_production"`，在 MVP 4 池 `{realm, equipment, zone, buff}` 上连乘。

**变量：**

| 变量 | 符号 | 类型 | 范围 | 说明 |
|------|------|------|------|------|
| target | — | String | `"{id}_production"` | ModifierEngine 查询目标 |
| pool | — | String | `{"realm", "equipment", "zone", "buff"}` | MVP 4 个乘数池 |
| v_{target, pool} | v | float | `(-∞, +∞)` | 该 target + pool 下所有 MULT 修正值之和。0.15 = +15%。池内和 < -1.0 时 ModifierEngine 钳位到 -1.0 |
| 1.0 + Σ v | p_k | float | `[0.0, +∞)` | 该池的最终倍率。= 1.0 表示该池无效果 |
| M_total | M | float | `[0.0, +∞)` | 所有池倍率的连乘积。通过 `ModifierEngine.get_multiplier(target)` 获取 |

**输出范围：** `[0.0, +∞)`。钳位由 ModifierEngine 执行（池倍率 < 0 → 钳位到 0.0）。

**叠加语义：**
- **池内加总**：同一池内多个来源先加总再乘。两件装备 +15% 和 +10% → `1.0 + 0.15 + 0.10 = 1.25`（非 `1.15 × 1.10 = 1.265`）。这意味堆同一来源有递减感。
- **池间连乘**：不同池独立相乘。境界 ×2.0 × 装备 ×1.25 × 区域 ×1.10 × Buff ×1.20 = 3.30。这意味跨来源组合有放大感。
- **空池 = 1.0**：若某池无注册修正器，其倍率 = 1.0（恒等元），不影响 M_total。

**跨资源独立性：** 每个 `resource_id` 在 ModifierEngine 中有独立 target，因此 `"lingqi_production"` 的乘数与 `"xiuwei_production"` 的乘数互不干扰。

**工作示例（灵气，4 池全激活）：**

| 池 | 已注册修正 | Σ v | 池倍率 |
|----|----------|-----|--------|
| `realm` | 炼气境 value=1.0 | 1.0 | 2.0 |
| `equipment` | 戒指 0.15 + 护腕 0.10 | 0.25 | 1.25 |
| `zone` | 东海 0.10 | 0.10 | 1.10 |
| `buff` | 聚灵丹 0.20 | 0.20 | 1.20 |

```
M_total = 2.0 × 1.25 × 1.10 × 1.20 = 3.30
```

玩家卸下护腕后（注销 value=0.10）：
```
equipment 池倍率 → 1.0 + 0.15 = 1.15
M_total = 2.0 × 1.15 × 1.10 × 1.20 = 3.036
```

---

### Formula 4: 单次查询耗时 (Per-Query Cost)

`get_production_rate()` 的调用链路耗时分析。

```
T_query = T_lookup + T_ME_cache + T_float_mult
```

**变量：**

| 变量 | 符号 | 类型 | 范围 (ms) | 说明 |
|------|------|------|----------|------|
| 字典查找 | T_lookup | float | [0.001, 0.005] | base_rates Dictionary（≤10 键）中按 resource_id 查找 |
| ModifierEngine 缓存命中 | T_ME_cache | float | [0.001, 0.003] | `get_multiplier()` 缓存命中路径。缓存未命中时追加 ~0.04 ms 重算（罕见——仅在 modifier 注册/注销帧） |
| float 乘法 | T_float_mult | float | [0.001, 0.003] | `base_rate_float * final_mult` |
| **单次查询总耗时** | **T_query** | **float** | **[0.003, 0.011]** | 缓存命中典型值 ~0.005 ms |

**输出范围：** `[0.003, 0.011]` ms（缓存命中）。

**典型场景（每 tick 查询 4 个被动资源）：**

```
T_tick_4 = 4 × 0.005 = 0.020 ms
```

远低于资源系统帧预算 0.333 ms（resource-system.md §Formula 8）。

**最坏场景（4 资源全部缓存未命中 + 重算，仅在 modifier 注册/注销帧）：**

```
T_tick_4_worst = 4 × (0.003 + 0.04 + 0.005) = 0.192 ms
```

仍在帧预算内。

**公式边界情况：**
- **`base_rate_float = 0.0`**（如 exp 配置为 `"0"`）：`R_rate = 0.0`，`A_tick = ZERO`。合法——`allows_passive=false` 的资源基础速率为 0。
- **`final_mult = 0.0`**（所有池被钳位到 0）：`R_rate = 0.0`。极不可能但数学可达到。
- **`delta` 极小（< 1e-6 秒）**：BigNumber 归一化可能钳位到 ZERO。返回 ZERO 合理——微小时间片不应产生可测量产出。
- **`raw_tick` 超过 BigNumber 可表示范围**：`BigNumber.from_float(raw_tick)` 饱和为 MAX。正常游玩不会触及；若触及通常表示倍率配置失控。

## Edge Cases

### 初始化与依赖不可用

- **If ModifierEngine 在 `get_production_rate()` 调用时尚未初始化**：返回 `0.0`，打印 warning `"ModifierEngine not available for production rate query: {resource_id}"`。`_ready()` 的 assert 覆盖正常启动路径，但消费者系统可能在 Autoload 初始化顺序异常时提前调用——安全降级优于崩溃。首几帧的产出查询不产生数值。
- **If DataConfig 在 `load_config()` 期间不可用**：`_ready()` 的 assert 捕获——游戏不应启动。若在 `reload_config()` 期间 DataConfig 变为 null（热重载边缘情况）：保留现有缓存配置不变，打印 error `"DataConfig unavailable during reload, keeping existing config"`。
- **If EventBus 在 `activate_source()` / `deactivate_source()` 期间不可用**：静默跳过事件发射，打印 warning `"EventBus unavailable, skipping production_multiplier_changed event"`。modifier 的注册/注销本身仍成功——核心职责（ModifierEngine 操作）独立于事件投递。HUD 将缺失本次更新，下一次 tick 查询或 EventBus 恢复后自然修复。
- **If `production_config.json` 缺失或 JSON 无效**：`DataConfig.get("production_config")` 返回空 Dictionary。OMS 以零资源、空 base_rates 初始化。所有 `get_production_rate()` 返回 ZERO，所有 `activate_source()` 因 resource_id 未找到被拒绝。OMS 降级运行，不崩溃。在配置修复前，被动产出实质禁用。
- **If `modifier_expired` 事件订阅在 `_ready()` 中失败**：`_ready()` 中的 EventBus assert 已覆盖。若仍失败：OMS 将永远无法自动清理 active_sources 中的过期条目。加载后重试一次；若两次均失败，打印 error，设置内部标志 `event_subscriptions_valid = false`。后续所有 activate/deactivate 打印一次性 warning `"Event subscriptions invalid — expired modifiers will not be auto-cleaned"`。

### 配置 Schema 异常

- **If `base_rate_per_second` 不是合法的非负 float 字符串**（如 `"abc"`, `""`, `"-1"`, `"nan"`）：OMS 将该资源的 `base_rate` 设为 `0.0`、`allows_passive` 强制设为 false，打印 error `"Invalid base_rate_per_second for '{id}': '{raw}' — resource disabled"`。
- **If `passive_sources` 字段缺失或类型错误**：默认设为空数组 `[]`。`activate_source()` 将因白名单为空拒绝所有来源注册。打印 warning `"Missing or invalid passive_sources for '{id}', defaulting to empty — no sources will be accepted"`。
- **If `allows_passive` 字段缺失或类型错误**：宽松解析——`"true"` / `"false"` 字符串 → 对应布尔值；其他无效值 → 默认 `false`（安全侧：宁可不产出也不错误地发放被动产出）。打印 warning。
- **If `production_config.json` 包含 ResourceSystem 中不存在的资源 ID**：OMS 正常缓存并使用。`get_production_rate()` 返回非零值 → AutoProduction 调用 `ResourceSystem.add()` → ResourceSystem 自行拒绝并打印 warning。OMS 不校验 ResourceSystem 的注册表（解耦），但打印 info 级日志标记潜在配置不一致。

### 来源激活与注销

- **If 同一 `source_id` 被重复激活且中间未 `deactivate_source()`**：拒绝第二次注册，打印 warning `"Source '{source_id}' already active, use deactivate_source() first"`，返回空字符串 `""`。调用方必须先注销再重新激活（如更换装备场景：先 deactivate 旧装备，再 activate 新装备）。
- **If 对从未激活过的 `source_id` 调用 `deactivate_source()`**：委托给 `ModifierEngine.unregister_by_source(source_id)`，返回 0（幂等）。打印 info 日志 `"Deactivate called for unknown source '{source_id}' — no-op"`，不打印 warning——调用方不一定知道 modifier 是否已过期被 ME 自动清理。
- **If 对已过期（被 ModifierEngine 自动注销）的 `source_id` 调用 `deactivate_source()`**：`active_sources` 中已无该条目（`modifier_expired` 处理器已清理）。委托给 `ModifierEngine.unregister_by_source()` 返回 0。`deactivate_source()` 返回 0，**不**发射 `production_multiplier_changed` 事件（因为 `active_sources.has(source_id) == false`——该 modifier 的过期事件已在之前发射过，无需重复通知）。
- **If `activate_source()` 传入 `resource_id` 不在配置中**：返回 `""`，打印 warning `"Unknown resource_id '{id}' for source '{source_id}'"`。
- **If `activate_source()` 传入 `source_type` 不在 `passive_sources` 白名单中**：返回 `""`，打印 warning `"Source type '{type}' not in passive_sources for '{resource_id}'"`。
- **If `activate_source()` 传入 `value = 0` 或 `NaN` / `Inf`**：返回 `""`，打印 warning 含具体无效值。零值修正无意义；NaN/Inf 不应进入 ModifierEngine 叠加管线。
- **If `activate_source()` 对 `allows_passive = false` 的资源调用**：返回 `""`，打印 warning `"Cannot activate passive production source for '{resource_id}' — allows_passive is false"`。
- **If 在同一帧内先 `activate_source()` 再 `deactivate_source()` 同一 source_id**：单线程 GDScript 按调用顺序执行。最终状态为 inactive。两个 `production_multiplier_changed` 事件均被发射（activated → deactivated）。下游经历一个瞬间的"乘数变化 → 恢复"抖动。由调用方负责避免无意义的 activate/deactivate 对——OMS 不检测此模式。

### 查询边界

- **If `get_tick_amount(resource_id, delta)` 的 `delta ≤ 0`**：返回 `BigNumber.ZERO`，打印 warning `"Invalid delta {delta}s for '{resource_id}' — must be positive"`。负数表示时间倒流（bug），零表示无时间流逝（无意义查询）。
- **If `delta` 极大（如 7 天离线 = 604800 秒）**：OMS 本身不钳位 delta。`raw_tick = rate_float × delta + carry` 使用 float；浮点 delta 在 ~10^7 秒级别开始丢失最低有效位，但对游戏数值无实际影响。若离线结算需要 > 10^7 秒的精度，应由离线结算系统自行分批处理。
- **If `get_production_rate()` 返回 `0.0` 但 `base_rate_float > 0.0`**（所有池被钳位到 0.0）：打印 warning `"All pools clamped to zero for '{resource_id}' — production halted. Check for excessive debuffs"`。极不可能发生（需所有 4 池的 Σ v < -1.0），但一旦发生则表示配置错误或极端减益叠加。
- **If `get_breakdown()` 对未配置的 resource_id 调用**：返回 `{"base_rate": 0.0, "add_sum": 0.0, "pools": {}, "final_multiplier": 1.0, "rate_per_second": 0.0, "fractional_carry": 0.0}`。与 `get_production_rate()` 降级行为一致。

### 运行时配置重载（`reload_config()`）

- **If `reload_config()` 在 modifier 仍激活时调用**：已注册 modifier 在 ModifierEngine 中保留（OMS 不重置）。新 base_rates 被加载，下一次查询使用新基础值 × 现有 modifier。若 reload 移除了一个之前存在的 resource_id：`get_production_rate(missing_id)` 返回 ZERO，但该资源的 modifier 在 ME 中仍为 active。**缓解**：`reload_config()` 后遍历 `active_sources`，清理其 resource_id 在新配置中缺失或 `allows_passive` 变为 false 的条目——对每个受影响的 source_id 依次调用 `deactivate_source()`。
- **If `reload_config()` 将某资源的 `allows_passive` 从 true 改为 false**：`active_sources` 中匹配 resource_id 的条目被清理（见上条）。后续 `get_production_rate()` 返回 ZERO。异常被隔离——不会残留无用 modifier。
- **If `reload_config()` 缩小了 `passive_sources` 白名单**：不重新验证已激活来源（热重载仅开发模式用，不为此复杂度买单）。被移除的来源类型下已激活的 modifier 继续生效直至手动注销或过期。记录为已知限制。
- **If 游戏版本更新后 `production_config.json` 格式变化但未迁移**：降级规则（见"配置 Schema 异常"）使 OMS 以空 base_rates 初始化。被动产出实质上禁用但游戏不崩溃——版本迁移由存档系统负责（参见 save-system.md）。

### 跨系统边界

- **If 外部系统绕过 OMS，直接向 ModifierEngine 注册 target 以 `_production` 结尾的 modifier**：OMS 不知道此 modifier。`get_production_rate()` 和 `get_breakdown()` 会包含它（ModifierEngine 不区分注册来源），但 OMS 无法将其归因于已知产出来源。**代码审查约束**：任何使用 `_production` 后缀 target 的 modifier 注册必须通过 OMS。违反此约定的 PR 不应被合入。
- **If 一个 `source_id` 同时用于产出修饰器和非产出修饰器**（如装备系统用同一 `"equip_ring_001"` 分别注册属性 modifier 和产出 modifier）：**设计上允许且有价值**——`deactivate_source("equip_ring_001")` 会将同一装备的属性加成和产出加成一并注销，符合"卸下装备 = 移除全部效果"的直觉。ModifierEngine 的 `unregister_by_source()` 按 source 批量注销天然支持此模式。
- **If `modifier_expired` 事件为非 OMS 注册的 modifier 触发**（如战斗 buff 过期）：OMS 的 `_on_modifier_expired` 处理器检查 modifier 的 target 是否匹配 `*_production` 模式——不匹配则静默跳过，避免对每个非产出 modifier 过期都执行无用的 active_sources 查找。
- **If `active_sources` 大小超过 500**：每个 source_type 打印一次性 warning `"Large active source count ({N}) for type '{type}' — verify sources are being properly deactivated"`。不设硬性上限，但异常增长通常是调用方未正确注销的 bug 信号。

### 消费者异常调用

- **If 消费者系统每帧高频调用 `get_production_rate()` + `get_breakdown()`**（如 > 100 次/秒）：每帧检查计数器；超过阈值时打印一次性性能 warning `"Excessive production rate queries ({N}/sec) — consider polling less frequently"`。正常负载为每 0.5s tick 时 4-5 次查询。
- **If `get_tick_amount()` 的 delta 参数为浮点极值**（如 `INF` 或 `NAN`）：返回 ZERO，carry 不变，打印 warning。无效时间片不应污染亚单位余数。

### 存档/读档交互

- **If 存档时 modifier 处于 active 状态但读档时已过期**：OMS 自身不持久化 modifier 状态（modifier 是瞬态的——由各来源系统在游戏会话中注册）。读档后，只有永久来源（如境界系统在初始化时注册的 realm modifier）会重新激活。临时 modifier（装备、Buff）依赖各来源系统在存档恢复后自行重建。**参见存档系统 GDD 的 modifier 持久化约定。**
- **If `production_config.json` 在存档和读档之间发生变化**（游戏版本升级）：OMS 使用新版配置文件。若基础速率降低，玩家看到产出下降（可接受——版本平衡调整）。若某资源被移除，其 modifier 在 `reload_config()` 路径中被清理。

## Dependencies

### 上游依赖

| 系统 | 依赖性质 | 数据接口 |
|------|---------|---------|
| **修正器/倍率引擎** (ModifierEngine) | 硬依赖 | 调用 `register()` / `unregister_by_source()` / `apply()` / `get_multiplier()` / `get_breakdown()`。所有叠加数学委托给此系统。OMS 无法脱离 ModifierEngine 独立工作 |
| **大数值系统** (BigNumber) | 硬依赖 | `get_tick_amount()` 在累计产出 ≥1.0 时返回 BigNumber；速率和亚单位 carry 使用 float，避免 `<1` 被 BigNumber 钳位 |
| **数据配置系统** (DataConfig) | 硬依赖 | 启动时调用 `DataConfig.get("production_config")` 加载 `production_config.json`；`reload_config()` 时重新读取 |
| **事件总线** (EventBus) | 硬依赖 | 发布 `"production_multiplier_changed"` 事件；订阅 `"modifier_expired"` 事件（清理内部 active_sources 追踪） |

### 下游消费者

| 系统 | 调用方向 | 数据接口 | 备注 |
|------|---------|---------|------|
| **自动产出系统** | 主动调用 | 每 tick `get_tick_amount(id, delta)` → `ResourceSystem.add()` | OMS 的主消费者；产出乘数系统完成后自动产出系统才能设计 |
| **修炼系统** | 主动调用 | `get_tick_amount("lingqi", delta)` / `get_tick_amount("xiuwei", delta)` | 修炼收益经过 OMS 倍率计算后写入资源系统 |
| **离线收益结算系统** | 主动调用 | `get_production_rate(id)` 获取离线期间的产出速率，用于批量计算离线收益 | 离线 delta 可能非常大（数小时到数天） |
| **装备系统** | 下游 → 主动调用 | 装备时 `activate_source({resource_id, "equipment", value, item_id})`；卸下时 `deactivate_source(item_id)` | MVP Alpha 阶段接入 |
| **境界突破系统** | 下游 → 主动调用 | 突破时 `activate_source({resource_id, "realm", value, "realm_XXX"})` | Post-MVP；MVP 可通过硬编码初始化凡人/炼气境倍率 |
| **区域系统** | 下游 → 主动调用 | 进入/离开区域时 `activate_source` / `deactivate_source`，source_type="zone" | MVP 至少需要东海区域的倍率定义 |
| **Buff 系统** | 下游 → 主动调用 | Buff 激活/失效时 `activate_source` / `deactivate_source`，source_type="buff" | Alpha 阶段接入 |
| **HUD 系统** | 下游 → 订阅/轮询 | 订阅 `"production_multiplier_changed"` 事件，或轮询 `get_multiplier()` / `get_breakdown()` 刷新"灵气/秒"等显示 | |
| **调试控制台** | 下游 → 查询 | 调用 `get_breakdown()` 输出全资源产出倍率分解 | 开发调试和 QA 验证的核心入口 |

### 关键非依赖（容易误以为依赖但不是）

| 系统 | 关系 | 说明 |
|------|------|------|
| **资源系统** (ResourceSystem) | **无直接关联** | OMS 不调用 ResourceSystem。OMS 的输出（BigNumber）由 AutoProduction / Cultivation 作为中介传入 `ResourceSystem.add()`。这是 TD-SYSTEM-BOUNDARY 评审明确要求的 God Object 防范 |
| **公式引擎** (FormulaEngine) | **无直接关联** | OMS 不调用 FormulaEngine。所有乘数计算由 ModifierEngine 完成；基础产出速率来自配置文件而非公式表达式 |

### 双向一致性自检

- ✅ **ModifierEngine GDD** §Interactions + §Dependencies 两处列出"产出乘数系统 — 调用 `apply('lingqi_production', base)` 计算最终产出；定义具体产出来源和池分配"——一致
- ✅ **ResourceSystem GDD** §Interactions 声明"修正器/倍率引擎 — 无直接关联"，§Dependencies 明确"产出乘数由调用方在传入 amount 前应用"——与本 GDD 的非依赖声明一致
- ✅ **EventBus GDD** §Core Rules 12 命名空间约定已追加 `"production_multiplier_changed"` 事件。

## Tuning Knobs

产出乘数系统的可调参数分为三类：**配置驱动参数**（`production_config.json`，per-resource）、**引擎/调试参数**（编译期常量或开发模式开关）、**MVP 硬编码值**（Alpha 阶段转为配置驱动）。

### 配置驱动参数（production_config.json，per-resource）

| 参数 | 类型 | 默认值 | 安全范围 | 调整影响 |
|------|------|--------|---------|---------|
| `base_rate_per_second` | 非负 float 字符串 | 见下表 | `["0", "1e30"]` | 直接影响该资源的产出速度，允许 `"0.1"` / `"0.02"` 等亚单位速率。过高导致玩家过早撞上限（At Cap 频繁触发 overflow）；过低使该资源严重稀缺，阻塞依赖它的所有升级 |
| `allows_passive` | bool | per-resource | `{true, false}` | `false` 时所有被动产出查询返回 ZERO。对战斗独有资源（如 exp）必须设为 false |
| `passive_sources` | Array[String] | per-resource | `[]` ~ `["realm","equipment","zone","buff"]` | 白名单控制哪些来源类型可以注册该资源的产出 modifier。空数组 = 拒绝所有来源注册。缩小白名单会使已激活来源（在 reload 时）被清理 |

**MVP 默认基础速率：**

| 资源 | base_rate/s | allows_passive | passive_sources |
|------|------------|----------------|-----------------|
| lingqi | `"1.0"` | true | `["realm", "equipment", "zone", "buff"]` |
| xiuwei | `"0.1"` | true | `["realm", "equipment", "zone", "buff"]` |
| lingshi | `"0.1"` | true | `["realm", "equipment", "zone", "buff"]` |
| herb | `"0.02"` | true | `["realm", "equipment", "zone", "buff"]` |
| exp | `"0"` | false | `[]` |

**调参原则：**
- lingqi 与 xiuwei 保持 10:1 比例（修仙叙事"十份灵气凝一份修为"的一致性约束）
- herb 与 lingqi 保持 1:50 比例（确保药材是稀缺材料，掉落时有价值感）
- lingshi 的 0.1/s 与"首件可购买物品定价 80-120 灵石"联动——改动灵石基础速率需同步调整商店定价

### 引擎/调试参数（全局，编译期或开发模式）

| 参数 | 默认值 | 安全范围 | 增大影响 | 减小影响 |
|------|--------|---------|---------|---------|
| `MAX_ACTIVE_SOURCES_WARN` | 500 | [100, 5000] | 允许更多 active source 不触发性能警告 | 更早触发警告，帮助发现未正确注销的来源 |
| `EXCESSIVE_QUERY_THRESHOLD` | 100 | [20, 1000] | 允许更高频查询不触发性能警告 | 更敏感地检测消费者异常轮询 |
| `EVENT_SUBSCRIPTIONS_RETRY` | 1 | [0, 3] | 更多次重试 EventBus 订阅（启动容错） | 更快放弃，降级运行（expired modifier 不自动清理） |

### MVP 硬编码倍率（临时值——Alpha 转为配置驱动）

| 参数 | 当前值 | 安全范围 | 说明 |
|------|--------|---------|------|
| 凡人境界倍率 | `1.0`（无修正注册） | — | 基线 |
| 炼气境 realm 倍率 | `2.0`（所有 4 资源） | [1.5, 3.0] | 首境界突破的全资源 ×2 加成。过高使凡→炼气一步跨度过大 |
| 东海 zone 倍率 | `1.0`（lingqi/xiuwei/lingshi）/ `1.5`（herb） | [0.5, 3.0] | herb 绿色区域差异化——药材在东海区更丰富 |
| 装备产出词条值 | `0.10` ~ `0.20`（+10% ~ +20%） | [0.01, 0.50] | 单件装备产出加成。过高使装备成为压倒性来源（同池加算仍有限制） |
| 灵丹 buff 值 | `0.20`（+20%，300s） | [0.05, 1.0] | 丹药临时加成。duration 和 value 需同步调整 |

### 与依赖系统的调参分工

| 调参对象 | 负责系统 | 说明 |
|---------|---------|------|
| 基础产出速率 | 产出乘数系统（`production_config.json`） | 本系统定义初始值；数值设计师通过配置文件调整 |
| 产出乘数倍率值 | 各来源系统（装备/境界/区域/Buff GDD） | 具体加成值（如 +15%）由来源系统定义；OMS 只负责注册和查询 |
| 叠加池定义与叠序 | 修正器/倍率引擎 | 池的创建和叠加规则由 ModifierEngine 管理 |
| Tick 频率 | 时间管理器 / 自动产出系统 | OMS 不控制 tick 间隔；只提供 `get_tick_amount(id, delta)` 响应任意 delta |
| 资源上限 | 存储上限系统 | 上限影响产出溢出的触发频率；但溢出的检测和处理在 ResourceSystem 层 |

## Visual/Audio Requirements

产出乘数系统是纯基础设施系统——无直接视觉或音频需求。产出速率变化通过 `"production_multiplier_changed"` 事件传递给 HUD 系统，由 HUD 负责渲染"灵气/秒"等数值显示。堆叠分解的视觉呈现（tooltip 中的池倍率明细）属于 HUD 系统的设计范围。

## UI Requirements

本系统无直接 UI。产出倍率的查询和展示由 HUD 系统通过 `get_multiplier()` 和 `get_breakdown()` API 驱动。调试面板（调试控制台）可调用 `get_breakdown()` 展示全资源产出分解——该 UI 由调试控制台系统负责。

> **📌 UX Flag — 产出乘数系统**：本系统虽无自有 UI，但其 API 是 HUD "灵气/秒"显示和调试面板"倍率分解"的数据源。HUD 系统 GDD 中应明确：产出速率显示格式、倍率 tooltip 中池分解的呈现方式（每个池一行、显示倍率和来源数）、以及"倍率变化"时的视觉反馈（数字跳动/变色）。在 Phase 4 (Pre-Production) 运行 `/ux-design` 时，HUD spec 应引用本系统的 `get_breakdown()` 输出结构。
>
> 注意：此 flag 应在 systems-index 更新时记录到 HUD 系统的行中。

## Acceptance Criteria

### Configuration and Initialization

- [ ] **AC-01** **GIVEN** `production_config.json` 包含 5 资源定义（lingqi base `"1.0"` allows_passive=true, xiuwei base `"0.1"` allows_passive=true, lingshi base `"0.1"` allows_passive=true, herb base `"0.02"` allows_passive=true, exp base `"0"` allows_passive=false），**WHEN** `OutputMultiplierSystem._ready()` 执行完毕，**THEN** `get_production_rate("lingqi") == 1.0`，`get_production_rate("xiuwei") == 0.1`，`get_production_rate("lingshi") == 0.1`，`get_production_rate("herb") == 0.02`，`get_production_rate("exp") == 0.0`，且各资源 `fractional_carry` 初始为 `0.0`

- [ ] **AC-02** **GIVEN** exp 的 `allows_passive = false`，且 target `"exp_production"` 下存在 realm modifier（value=1.0, MULT, pool="realm"），**WHEN** 调用 `get_production_rate("exp")`，**THEN** 返回 `0.0`（无视 modifier），且 `get_tick_amount("exp", 10.0)` 返回 `BigNumber.ZERO`，且 `activate_source({resource_id: "exp", source_type: "equipment", value: 0.15, source_id: "exp_src"})` 返回 `""` 并打印 warning

- [ ] **AC-03** **GIVEN** `DataConfig.get("production_config")` 返回空 Dictionary（配置缺失或不可解析），**WHEN** `load_config()` 执行，**THEN** 系统以零资源、空 base_rates / fractional_carry 初始化，`get_production_rate("lingqi")` 返回 `0.0`，`activate_source({...})` 对任何 resource_id 返回 `""`，不崩溃

### Activation and Source Registration

- [ ] **AC-04** **GIVEN** target `"lingqi_production"` 下无任何 modifier（`get_multiplier("lingqi")` 返回 `1.0`），**WHEN** 调用 `activate_source({resource_id: "lingqi", source_type: "equipment", value: 0.15, source_id: "equip_ring_001"})`，**THEN** 返回非空 modifier ID 字符串，且 `get_multiplier("lingqi")` 返回 `1.15`，且 `get_production_rate("lingqi")` 返回 `1.15`

- [ ] **AC-05** **GIVEN** target `"lingqi_production"` 下无 modifier，**WHEN** 调用 `activate_source({resource_id: "lingqi", source_type: "realm", value: 1.0, source_id: "realm_liandan"})`，然后 `get_breakdown("lingqi")`，**THEN** `pools["realm"]` 等于 `2.0`（1.0 + 1.0），且 modifier 在 ModifierEngine 中以 `pool = "realm"` 和 `target = "lingqi_production"` 注册

- [ ] **AC-06** **GIVEN** `activate_source({..., source_id: "equip_ring_001"})` 已成功执行，**WHEN** 再次以相同 `source_id` 调用 `activate_source`（中间未 deactivate），**THEN** 返回 `""`，打印 warning，`get_multiplier("lingqi")` 保持首次激活的值不变

- [ ] **AC-07** **GIVEN** 配置中 lingqi 的 `allows_passive = true`，**WHEN** `activate_source({resource_id: "lingqi", source_type: "equipment", value: 0.0, source_id: "equip_zero"})` 和 `activate_source({..., value: NaN, source_id: "equip_nan"})` 分别被调用，**THEN** 两者均返回 `""`，各自打印 warning，`get_multiplier("lingqi")` 保持 `1.0`

- [ ] **AC-08** **GIVEN** lingqi 的 `passive_sources` 为 `["realm", "equipment", "zone", "buff"]`（不含 `"skill"`），**WHEN** `activate_source({resource_id: "lingqi", source_type: "skill", value: 0.15, source_id: "skill_test"})` 被调用，**THEN** 返回 `""`，打印 warning 提示 source_type 不在白名单中

### Query and Formula Verification

- [ ] **AC-09** **GIVEN** target `"lingqi_production"` 下无任何 modifier，**WHEN** 调用 `get_production_rate("lingqi")`，**THEN** 返回 `1.0`（base_rate × 1.0）

- [ ] **AC-10** **GIVEN** lingqi 下 4 个来源均激活：realm value=1.0（池倍率 2.0）、equipment 两件 value=0.15+0.10（池倍率 1.25）、zone value=0.10（池倍率 1.10）、buff value=0.20（池倍率 1.20），总 final_mult = 2.0 × 1.25 × 1.10 × 1.20 = 3.30，**WHEN** 调用 `get_production_rate("lingqi")`，**THEN** 返回 `3.30`

- [ ] **AC-11** **GIVEN** `get_production_rate("lingshi")` 返回 `0.33`（base 0.1 × multiplier 3.30），**WHEN** 在 fresh carry 状态下调用 `get_tick_amount("lingshi", 0.5)`，**THEN** 返回 `BigNumber.ZERO` 且 `fractional_carry["lingshi"] == 0.165`；**WHEN** 在 fresh carry 状态下调用 `get_tick_amount("lingshi", 1800.0)`，**THEN** 返回 `BigNumber.from_float(594.0)` 且 carry 归零

- [ ] **AC-12** **GIVEN** AC-10 的 4 池配置对 lingqi 生效，**WHEN** 调用 `get_multiplier("lingqi")`，**THEN** 返回 `3.30`，匹配 `M_total = 2.0 × 1.25 × 1.10 × 1.20`（Formula 3 文档化期望值）

- [ ] **AC-13** **GIVEN** realm（value=1.0, source_id="realm_lianqi"）和 equipment（value=0.25, source_id="equip_ring"）对 lingqi 生效，base_rate = `1.0`，**WHEN** 调用 `get_breakdown("lingqi")`，**THEN** 返回 Dictionary 其中 `base_rate` = `1.0`，`add_sum` = `0.0`，`pools.realm` = `2.0`，`pools.equipment` = `1.25`，`pools.zone` = `1.0`（空池），`pools.buff` = `1.0`（空池），`final_multiplier` = `2.50`，`rate_per_second` = `2.50`，`fractional_carry` 为当前余数

### Within-Pool Additivity and Cross-Pool Multiplicativity

- [ ] **AC-14** **GIVEN** 两个 equipment modifier 对 lingqi 生效：source "equip_a" value=0.15 + source "equip_b" value=0.10，无其他 modifier，**WHEN** 调用 ModifierEngine 的 `get_pool_multiplier("lingqi_production", "equipment")` 和 OMS 的 `get_multiplier("lingqi")`，**THEN** equipment 池倍率为 `1.25`（1.0 + 0.15 + 0.10），**NOT** `1.265`（1.15 × 1.10），且 `get_multiplier("lingqi")` 返回 `1.25`

- [ ] **AC-15** **GIVEN** lingqi 下 realm modifier（value=1.0, 池倍率 2.0）和 zone modifier（value=0.10, 池倍率 1.10）生效，无其他 modifier，**WHEN** 调用 `get_multiplier("lingqi")`，**THEN** 返回 `2.20`（2.0 × 1.10），确认两池独立相乘而非值先加总

### Deactivation and Lifecycle

- [ ] **AC-16** **GIVEN** equipment modifier `source_id: "equip_ring_001"`（value=0.15）对 lingqi 生效，`get_multiplier("lingqi")` = `1.15`，**WHEN** 调用 `deactivate_source("equip_ring_001")`，**THEN** 返回 `1`（一个 modifier 被移除），且 `get_multiplier("lingqi")` 返回 `1.0`，且 `get_production_rate("lingqi")` 返回 `1.0`

- [ ] **AC-17** **GIVEN** buff modifier 对 lingqi 生效：`source_id: "buff_pill_001"`, `duration: 5.0`, `value: 0.20`，`get_multiplier("lingqi")` = `1.20`，**WHEN** `ModifierEngine.update(6.0)` 被调用（耗尽 duration 触发过期），`"modifier_expired"` 事件发射，**THEN** OMS 发射 `"production_multiplier_changed"` 事件 `action: "deactivated"`, `source_id: "buff_pill_001"`，且 `get_multiplier("lingqi")` 返回 `1.0`

### Event Emission

- [ ] **AC-18** **GIVEN** EventBus 上有订阅者监听 `"production_multiplier_changed"` 并记录收到的 payload，**WHEN** `activate_source({resource_id: "lingqi", source_type: "equipment", value: 0.15, source_id: "equip_ring_001"})` 被调用，**THEN** 订阅者收到恰好一条事件，`resource_id: "lingqi"`, `source_id: "equip_ring_001"`, `action: "activated"`, `new_multiplier: 1.15`

- [ ] **AC-19** **GIVEN** `source_id: "equip_ring_001"` 对 lingqi 生效，订阅者监听 `"production_multiplier_changed"`，**WHEN** `deactivate_source("equip_ring_001")` 被调用，**THEN** 订阅者收到恰好一条事件，`resource_id: "lingqi"`, `source_id: "equip_ring_001"`, `action: "deactivated"`

### Error Handling

- [ ] **AC-20** **GIVEN** `get_production_rate("lingqi")` 返回非零 float，**WHEN** `get_tick_amount("lingqi", 0.0)` 和 `get_tick_amount("lingqi", -1.0)` 分别被调用，**THEN** 两者均返回 `BigNumber.ZERO`，carry 不变，各打印一条 warning 提示 delta 无效

## Open Questions

| Question | Owner | Deadline | Resolution |
|----------|-------|----------|-----------|
| ModifierEngine GDD Open Question "产出乘数系统的职责是否与修正器引擎重叠太多？是否应合并？" | 设计师 | 本 GDD 完成时 | ✅ 已解决——产出乘数系统作为独立系统设计，职责边界明确：修正器引擎做通用叠加数学，产出乘数系统做产出域来源分类和池映射。两系统独立但组合使用 |
| EventBus GDD §Core Rules 12 命名空间约定中列出 `"production_multiplier_changed"` 事件 | 开发者 | `/consistency-check` 阶段 | ✅ 已解决 2026-05-03 — event-bus.md 已列出该事件 |
| MVP 硬编码倍率（炼气境 ×2.0、东海 herb ×1.5）何时迁移到配置驱动？ | 设计师 | Alpha 阶段（阶段 3：装备刷宝与 Build） | MVP 可接受硬编码——只有 1-2 个境界和 1-2 个区域。Alpha 阶段新增更多境界/区域时转为 `realm_config.json` 和 `zone_config.json` |
| 是否需要支持运行时修改 base_rate（如科技树升级改变基础产出而非叠加乘数）？ | 设计师 | 科技树系统 GDD 时 | MVP 不需要。若未来需要，可通过追加 `set_base_rate(id, new_rate)` API 实现——暂不设计以保持 MVP 简洁 |
| HUD 应显示"绝对产出速率"还是"基础 × 倍率"分解？ | UX 设计师 | HUD 系统 GDD 时 | `get_breakdown()` API 已就绪支持两种模式——由 HUD GDD 决定 |
| 是否需要产出乘数上限（如最终倍率不超过 1e6×）以防止数值爆炸？ | 设计师 | 平衡性测试阶段 | MVP 不设上限——ModifierEngine 的池倍率钳位（< 0 → 0.0）已提供底线保护。上限属于平衡性问题而非技术问题 |
| 战斗掉落是否也应该经过产出乘数系统（如"装备 +15% 药材掉落"）？还是只影响被动产出？ | 设计师 | 掉落系统 GDD 时 | 当前设计只有被动产出经过 OMS。掉落倍率可能复用同样的 source→pool 映射但走不同管线（战斗计算器而非 passive tick）。是否抽象共享的"倍率来源定义"层由掉落系统 GDD 决定 |
