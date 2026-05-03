# 跨 GDD 审查报告

**日期**：2026-05-03
**GDD 已审查**：16 个（13 系统 GDD + game-concept + systems-index + debug-console）
**系统覆盖**：BigNumber, RandomSeed, EventBus, TimeManager, NumberFormatting, DataConfig, FormulaEngine, ModifierEngine, SaveSystem, ResourceSystem, AttributeSystem, ItemMaterialSystem, OutputMultiplierSystem, DebugConsole
**审查模式**：full（一致性 + 设计理论 + 场景走查）

---

## Consistency Issues

### Blocking（必须在架构阶段前解决）

#### 🔴 BigNumber 无法存储亚单位值 — OMS 三个核心资源的被动产出永久为零

**涉及 GDD**：`big-number-system.md`、`output-multiplier-system.md`

**证据**：

BigNumber GDD 明确声明：
> "本系统仅表示 ≥ 1 的绝对量值；比值（0~1 范围）和百分比乘数由公式引擎使用 float 处理。" (Overview)
> "若归一化后 exponent < 0：钳位到零" (§Detailed Design 规则 3)
> "If 除法结果 < 1（如 5 ÷ 7）：返回 BigNumber.ZERO" (§Edge Cases)

OMS `production_config.json` 的 `base_rate_per_second` 值存储为 BigNumber（§Detailed Design 规则 3）：
- `xiuwei`: `"0.1"` → `BigNumber.from_string("0.1")` → mantissa=1.0, exponent=-1 → 归一化 exponent<0 → **钳位为 ZERO**
- `lingshi`: `"0.1"` → **同上，钳位为 ZERO**
- `herb`: `"0.02"` → **同上，钳位为 ZERO**

**后果**：
1. xiuwei、lingshi、herb 三个资源在 MVP 中永远不会通过被动产出增长
2. `get_tick_amount("xiuwei", delta)` 返回 ZERO → `ResourceSystem.add("xiuwei", ZERO)` → delta=0 抑制事件 → HUD 静默不显示
3. OMS AC-01 期望 `get_production_rate("xiuwei") == BigNumber.from_float(0.1)` — 永远无法通过
4. lingqi 的 `base_rate=1.0` 不受影响（≥1），但 `multiply_float(delta)` 在 delta<1 秒时也可能坍缩

**修复方案**：OMS 改用 `float` 存储 `base_rate_per_second`，仅在 `get_production_rate()` 最后一步转为 BigNumber：
```
P_rate_float = base_rate_float * final_mult_float
return BigNumber.from_float(max(P_rate_float, 1.0))  # 或引入 MIN_POSITIVE
```
或 BigNumber 引入 `MIN_POSITIVE` 表示（如 `{mantissa: 1.0, exponent: -1}` 合法化，仅表示精度而非钳位）。

#### 🔴 EventBus 缺少 `subscribe_pattern` API — debug-console 核心功能阻塞

**涉及 GDD**：`event-bus.md`、`debug-console.md`

**证据**：

debug-console.md §Dependencies 依赖：
> `EventBus.subscribe_pattern(prefix, callable)` + `unsubscribe_pattern(prefix, callable)` — 用于 `event watch`；无此 API 则该命令降级为 no-op

EventBus GDD 当前仅提供 `subscribe(event_name: String, callable)` 精准匹配（§Detailed Design 规则 5），无通配符/前缀订阅。Open Questions 中将通配符列为"未决定"（line 220）。

**后果**：debug-console 的 `event watch` 命令完全无法实现。`event watch` 是调试控制台 10 个命令中最有价值的一个（实时追踪事件流），缺少它将严重削弱开发诊断能力。

**修复方案**：
1. 在 EventBus GDD 中追加 `subscribe_pattern(prefix: String, callable: Callable) -> void` 和 `unsubscribe_pattern(prefix: String, callable: Callable) -> void` API
2. 或将 debug-console 改为"订阅所有已知事件名"方案（不使用通配符，逐事件名订阅）

#### 🔴 EventBus 命名空间约定缺失多个系统的事件

**涉及 GDD**：`event-bus.md`、`save-system.md`、`output-multiplier-system.md`、`time-manager.md`

**证据**：EventBus §Core Rules 11 列出的事件命名空间**不包含**：

| 缺失事件 | 声明方 GDD | 用途 |
|---------|-----------|------|
| `save.loaded`, `save.saved`, `save.corrupted` | save-system.md §Interactions | 存档状态变更通知 |
| `production_multiplier_changed` | output-multiplier-system.md §Interactions | 产出乘数变化通知 |
| `time.frozen`, `time.unfrozen`, `time.speed_changed`, `time.offline_delta` | time-manager.md §Interactions | 时间状态变更通知 |

**后果**：已有 `item_registry.loaded/reloaded` 通过 `/consistency-check` 补充的先例，但遗漏了 save/time/production 系列。新系统开发者可能使用冲突事件名。save-system.md 和 output-multiplier-system.md 的 GDD 内已自行标注此缺口。

**修复方案**：在 event-bus.md §Core Rules 11 追加 `save.*`、`time.*`、`production_multiplier_changed` 命名空间条目。同时将 Open Questions 中通配符订阅决议从"未决定"改为"实现"。

---

### Warnings（建议解决，不阻塞架构）

#### ⚠️ debug-console 引用 5 个不存在的上游 API

**涉及 GDD**：`debug-console.md`、`modifier-engine.md`、`data-config-system.md`、`save-system.md`、`output-multiplier-system.md`

**证据**：debug-console.md §Dependencies (lines 408-416) 列出需新增的接口：

| 引用 API | 上游 GDD | 实际状态 |
|----------|---------|---------|
| `ModifierEngine.get_all_targets()` | modifier-engine.md | **不存在** |
| `DataConfig.is_loaded()` | data-config-system.md | **不存在** |
| `SaveManager.collect_save_data()` | save-system.md | **不存在** |
| `SaveManager.is_saving()` | save-system.md | **不存在** |
| `OMS.get_final_rate()` | output-multiplier-system.md | 实际 API 名为 `get_production_rate()`，命名不一致 |

debug-console 自身标注了这些为"缺口"，但 5 个缺口的累积意味着核心命令集 ~50% 被阻塞。

**修复方案**：
1. 在 modifier-engine.md 补充 `get_all_targets() -> Array[String]`
2. 在 data-config-system.md 补充 `is_loaded() -> bool`
3. 在 save-system.md 补充 `collect_save_data() -> Dictionary` 和 `is_saving() -> bool`
4. debug-console.md 中 `OMS.get_final_rate()` → `OMS.get_production_rate()`

#### ⚠️ 5 个上游 GDD 的 Interactions 表缺少调试控制台的下游引用

**涉及 GDD**：`modifier-engine.md`、`resource-system.md`、`time-manager.md`、`save-system.md`、`attribute-system.md`

**证据**：debug-console.md 声明了 10 个上游软依赖，但逆向检查发现上述 5 个 GDD 的 Interactions 表中未列出调试控制台为消费者。对比 EventBus 和 DataConfig 已正确列出。

**修复方案**：在 5 个 GDD 的 Interactions 表中各追加一行 `调试控制台 — 下游消费 — 只读查询`。

#### ⚠️ 存档/读档时 Modifier 状态不持久化 — 永久 modifier 重建责任未分配

**涉及 GDD**：`save-system.md`、`modifier-engine.md`、`output-multiplier-system.md`

**证据**：SaveManager.load_game() → ResourceSystem.restore() 和 AttributeSystem.restore() 恢复数值状态，但 ModifierEngine 中的 modifier 注册状态不持久化。OMS 的"永久" modifier（如 realm 境界倍率）需要来源系统在读档后重新注册。由于境界突破系统 (#191) Post-MVP，当前无任何系统承担此重建责任。

OMS §Edge Cases 已自问："If 存档时 modifier 处于 active 状态但读档时已过期" — 回答为"各来源系统在游戏会话中注册"。但 MVP 阶段没有会注册 modifier 的"来源系统"。

**修复方案**：在等级系统/修炼系统 GDD 中明确：`_ready()` 或 save restore 回调中重建永久 modifier（realm 倍率）。

#### ⚠️ systems-index 中 debug-console 依赖声明过于简化

**涉及 GDD**：`systems-index.md`

**证据**：systems-index line 37 列出调试控制台依赖 "事件总线, 数据配置系统"。但实际 debug-console 有 10 个软依赖（见其 §Dependencies）。仅列 2 个可能误导开发者在实现时低估依赖链。

**修复方案**：在 systems-index 中追加完整依赖列表，或至少标注为"软依赖（缺失时降级）"。

#### ⚠️ OMS base_rate 类型不一致 — Design 与数据矛盾

**涉及 GDD**：`output-multiplier-system.md`

**证据**：OMS §Detailed Design 规则 3 声明 `base_rates: Dictionary[String, BigNumber]`，但 MVP 的 base_rate 值中含有亚单位（0.1, 0.02）。声明类型与数据格式矛盾——BigNumber 无法表示这些值。与第一个 CRITICAL 同源。

---

## Game Design Issues

### Blocking

#### 🔴 MVP 5 项资源：全部只有来源声明，消费端设计为零

**涉及 GDD**：`resource-system.md`、`output-multiplier-system.md`、game-concept.md

**证据**：

| 资源 | 来源系统 | 消费端 | 消费系统状态 |
|------|---------|--------|------------|
| `lingqi` | OMS 被动产出 (1.0/s) | 修炼消耗 / 突破消耗 | **修炼系统 Not Started / 突破系统 Post-MVP** |
| `xiuwei` | OMS 被动产出 (0.1/s) | 境界突破消耗 | **突破系统 Post-MVP** |
| `lingshi` | OMS 被动产出 (0.1/s) | 商店购买 / 升级消耗 | **无此系统** |
| `herb` | OMS 被动产出 (0.02/s) | 炼丹消耗 | **无此系统** |
| `exp` | 战斗掉落 | 等级提升消耗 | **等级系统 Not Started** |

ResourceSystem 的 `spend()` API 已完整设计（含 `can_afford`、`batch_add`、原子拒绝语义），但在所有 13 个已设计 GDD 中**零次被调用**。

**设计后果**：经济循环不存在。所有资源只会单向增长（来源→积累→上限溢出），没有消费路径将其转化为有意义的游戏进展（修炼、突破、升级、购买）。这违背了 game-concept.md §10.2 "第一条可玩闭环"的最基本定义。

**修复方案**：在 MVP 中至少设计以下消费路径：
1. 等级系统 GDD 中定义 `exp` → 等级提升的消费公式
2. 修炼系统 GDD 中定义 `lingqi` → `xiuwei` 的转化消费（如手动修炼消耗灵气加速修为）
3. 或接受 MVP 简化为"纯积累 → 手动 reset/突破"无消费模型（资源系统已有 `reset_by_scope`）

#### 🔴 未建模的正反馈循环 — OMS 无上限乘算 + 无软上限约束

**涉及 GDD**：`output-multiplier-system.md`、`modifier-engine.md`、`formula-engine.md`

**证据**：

核心正反馈环（game-concept.md §10.2）：
```
修炼产出灵气 → 灵气积累 → 突破境界 → realm 倍率↑ → 产出加速 → 更快积累 → ...
```

但在已设计的 GDD 中：
- OMS Open Questions 明确回答："MVP 不设上限——上限属于平衡性问题而非技术问题"
- ModifierEngine 的 `final_mult = Π pool_mult` 无硬性上限（仅池倍率 < 0 时钳位到 0）
- FormulaEngine 提供了 `softcap()` 和 `log_softcap()` 函数，但**无任何 GDD 要求在产出/属性路径上使用它们**
- 境界倍率的步进大小未定义（炼气→筑基→金丹各境界差距未知）

**设计后果**：
1. 一旦境界系统接入，4 个乘算池叠加，总倍率可能从 1.0 在数小时内跳到 1e6+
2. 中文单位表（万→亿→兆→...→极）在几个单位区间内被击穿
3. 支柱 4.1 "增长要有阶段、瓶颈、突破和重置"的后半句（瓶颈/重置）无法兑现

**修复方案**：
1. 在等级系统/境界突破系统 GDD 中要求：每个产出池倍率增长必须经过 FormulaEngine 的 `softcap` 或 `log_softcap`
2. 或在 OMS GDD 中定义产出乘数建议上限（仅文档约束，非硬编码）

#### 🔴 17 个 MVP 系统未设计（57%）— 第一条可玩闭环 4/7 环节缺失

**涉及 GDD**：`systems-index.md`、game-concept.md

**证据**：

game-concept.md §10.2 "第一条可玩闭环"：
```
修炼 → 资源增长 → 等级提升 → 简单自动战斗 → 掉落材料 → 强化角色 → 推进区域 → 离线结算
```

| 环节 | 对应系统 | GDD 状态 |
|------|---------|---------|
| 资源增长 | ResourceSystem + OMS | ✅ Designed |
| 等级提升 | 等级系统 #15 | ❌ Not Started |
| 修炼 | 修炼系统 #20 | ❌ Not Started |
| 自动战斗 | 半自动战斗系统 #22 + 战斗计算器 #21 | ❌ Not Started |
| 掉落 | 掉落系统 #19 | ❌ Not Started |
| 区域推进 | 区域系统 #23 + 地图推进系统 #24 | ❌ Not Started |
| 离线结算 | 离线收益结算系统 #28 | ❌ Not Started |

**结论**：当前设计的 13 个系统全部是**被动基础设施**（CRUD、计算、存储、通信）。已设计系统之间的接口契约质量很高，但它们合在一起不构成可玩体验。这是"坚实的地基 + 完全空白的上层建筑"。

**是否可推进至 /create-architecture？** 可以，但架构决策将大量依赖"尚未设计的系统会如何行为"的假设。建议至少先完成 3 个最小桥梁系统的 GDD 草稿：
- #15 等级系统（定义 exp→等级→属性的成长链）
- #17 自动产出系统（定义 tick 循环和资源注入）
- #20 修炼系统（定义灵气→修为的转化和点击/自动行为）

---

### Warnings

#### ⚠️ 10 根设计支柱中 6 根零兑现

**支柱兑现矩阵**：

| 支柱 | 当前兑现 | 兑现方式 | 缺口 |
|------|---------|---------|------|
| 4.1 数字增长就是快乐 | ✅ 强 | BigNumber + NumberFormatting + OMS + ModifierEngine + ResourceSystem + AttributeSystem | 成长节奏未定义 |
| 4.2 放置 = 低频高价值决策 | ❌ 零 | — | 无任何决策系统被设计 |
| 4.3 刷宝提供惊喜 | ❌ 零 | RandomSeed 提供基础但掉落系统不存在 | 掉落/装备 Not Started |
| 4.4 宗门 = 后勤系统 | ❌ 零 | ResourceSystem 预留上限连接点 | Post-MVP |
| 4.5 多层重置 | ❌ 零 | ResourceSystem 预留 reset_scope | Post-MVP |
| 4.6 渐进叙事 | ⚠️ 弱 | EventBus + ItemMaterialSystem 预留 | 叙事系统不存在 |
| 4.7 子玩法服务主循环 | ❌ 零 | — | Post-MVP |
| 4.8 自动化 = 奖励 | ❌ 零 | — | Not Started |
| 4.9 单机经济 | ✅ 合规 | 无不一致 | 经济本体未设计 |
| 4.10 数据驱动 | ✅ 强 | DataConfig + FormulaEngine + BigNumber + RandomSeed + ItemMaterialSystem | — |

这种偏斜是 MVP 基础设施优先策略的自然结果，但意味着**下一批 GDD 必须以 4.2 和 4.3 为首要目标支柱**。

#### ⚠️ ModifierEngine 无乘法倍率上限 — 中期数值可能失控

**涉及 GDD**：`modifier-engine.md`、`output-multiplier-system.md`

4 个乘算池 × 无上限 × BigNumber 1e308 = 潜在的数值爆炸。OMS 明确拒绝在 MVP 设上限（"上限属于平衡性问题而非技术问题"）。建议至少设定文档级软约束（如"单个池倍率建议不超过 100×"）。

#### ⚠️ OMS 基础速率×倍率 — 增长节奏不可评估

**涉及 GDD**：`output-multiplier-system.md`、`number-formatting-system.md`

OMS 定义的初始速率 lingqi=1.0/s，在无任何乘数时：到达"万"需 2.8 小时，到达"亿"需 3.2 年。节奏在 MVP 合理。但若有 100× 以上倍率叠加，第一个单位跃迁（万）可在 1-2 分钟内完成——即中文单位表被穿透得极快。由于境界/装备倍率未定义，无法评估。

#### ⚠️ 玩家角色身份完全缺失

**涉及 GDD**：`attribute-system.md`、game-concept.md

AttributeSystem 中主角 `entity_id="player"` 的属性是 `hp_max/atk/def/spd/crit_rate/crit_dmg` — 通用 RPG 角色，不是"修仙者"。缺少灵气亲和度、修炼资质、神识强度等修仙角色标识。

建议在等级系统 GDD 中至少填入最小修仙角色身份（境界字段、灵根/资质基础属性）。

#### ⚠️ ItemMaterialSystem MVP 仅兑现支柱 4.1 的"具象化层"

**涉及 GDD**：`item-material-system.md`

ItemMaterialSystem Player Fantasy 节的支柱对应声明其 MVP 阶段只兑现 4.1（数字增长的具象化层——"灵草 ×12"而非"item_03 ×12"），4.6（渐进叙事）和 4.3（刷宝惊喜）仅为 Alpha 占位。GDD 内已有 Open Questions 承诺 Alpha 阶段重写 Player Fantasy。**不是缺陷**，但需在审查记录中标记为"已知延后"。

---

### Info

#### ℹ️ 13 个系统的修仙隐喻高度一致

所有 13 个已设计 GDD 的 Player Fantasy 节围绕一个共同承诺构建：**"可信的、可追溯的、有因果的成长"**。每个系统的隐喻映射（BigNumber="无天花板的成长世界"、EventBus="隐形的经脉"、TimeManager="时光长河"、ResourceSystem="丹田经脉的账本"）互不冲突，且都带有"重要边界声明"来澄清自身是基础设施而非体验载体。这种集体自限是设计纪律性的体现。

#### ℹ️ 策略空间设计正确（防优势策略）

OMS 的"池内加算、池间乘算"模型主动制造了投资分散化激励——跨池分散（4 池各 +20% = ×2.07）严格优于单池堆叠（4 件装备各 +20% = ×1.80）。这是有意的设计激励，符合支柱 4.2 的策略深度。

#### ℹ️ 已设计系统全部被动 — 零玩家交互

当前 13 个系统全部是被动基础设施，不需玩家主动决策。不是问题——MVP 基础设施优先策略的自然结果——但意味着 player-facing 系统的设计必须在下一阶段启动。

#### ℹ️ 无成长系统 GDD = 无法评估缩放一致性

BigNumber (1e308) > NumberFormatting (10^52) > OMS 初始产出 (1/s)。当前的数值跨度设计合理，但缺少等级/境界/敌人缩放曲线，无法评估中期/后期一致性。

#### ℹ️ 反支柱检查全部通过

无抽卡 ✅、无多人 ✅、无复杂装备词条 ✅、无实时交易经济 ✅。ItemMaterialSystem 明确声明 `rarity` 是修仙品质枚举非抽卡稀有度。

---

## Cross-System Scenario Issues

4 个关键多系统场景走查：

### 🔴 场景 1：离线返回结算 — 链路断裂

**涉及系统**：TimeManager, EventBus, OMS, ResourceSystem, 离线模拟内核 (#25), 自动产出系统 (#17)

**走查**：
```
TimeManager._ready() → 检测 exit_timestamp → 计算 offline_delta
  → EventBus.emit("time.offline_delta", {real_delta, game_delta})
  → ??? 离线模拟内核 (#25) — Not Started
  → ??? 自动产出系统 (#17) — Not Started
  → ResourceSystem.batch_add() ← API 已就绪
  → EventBus "resource.*.changed" → HUD 刷新
```

**失败模式**：BLOCKER — 离线结算的编排者不存在。OMS.get_tick_amount() 和 ResourceSystem.batch_add() 已就绪，但**无任何已设计系统负责"订阅 time.offline_delta → 遍历 4 个被动资源 → 调用 OMS → 调用 ResourceSystem"这个编排序列**。

### 🔴 场景 2：在线资源产出 Tick — 亚单位值坍缩

**涉及系统**：TimeManager, OMS, ModifierEngine, BigNumber, ResourceSystem

**走查**：
```
AutoProduction → OMS.get_tick_amount("xiuwei", 0.5)
  → base_rate = BigNumber.from_string("0.1") → ZERO（钳位）
  → final_mult = ModifierEngine.apply("xiuwei_production", ZERO) = (0 + 0) × 1.0 = ZERO
  → 返回 ZERO
  → ResourceSystem.add("xiuwei", ZERO) → delta=ZERO → 不发布事件
```

**失败模式**：BLOCKER — xiuwei/lingshi/herb 三个资源产出恒为零，且由于 delta=0 时的 EventBus 事件抑制规则，HUD 不会显示任何异常。**静默失败**——最危险的失败模式。

### ⚠️ 场景 3：装备替换 → 修正器重算

**涉及系统**：装备系统 (Post-MVP), OMS, ModifierEngine, ResourceSystem

**走查**：
```
装备替换 → OMS.deactivate_source(old) → OMS.activate_source(new)
  → ModifierEngine.unregister_by_source / register
  → 缓存标记为脏 → 下次 get_multiplier() 重算
  → OMS.get_production_rate() 自动反映新倍率
```

**问题**：WARNING — 装备系统不在 MVP 范围内。MVP 中产出乘数的唯一注册者应该是境界突破系统（也不在 MVP 范围）。**当前 MVP 设计中，所有 4 个产出乘数池都不会有任何 modifier 注册**，OMS.get_multiplier() 永远返回 1.0。产出 = 裸 base_rate——这可能是故意的 MVP 简化，但需在 GDD 中明确记录。

### ⚠️ 场景 4：存档/读档 — Modifier 状态丢失

**涉及系统**：SaveManager, ResourceSystem, AttributeSystem, ModifierEngine, OMS

**走查**：
```
SaveManager.load_game()
  → ResourceSystem.restore(data) → set_max → set_value → 数值恢复 ✓
  → AttributeSystem.restore(data) → register_entity → set_base → 属性恢复 ✓
  → ModifierEngine — 无 restore 机制 ✗
  → OMS.active_sources — 从空开始 ✗
  → 永久 modifier（realm 倍率）需来源系统重建 → 来源系统不存在 ✗
```

**问题**：WARNING — Modifier 注册状态不持久化。永久 modifier（如 realm 境界倍率）的重建责任未在 GDD 层分配给任何系统。在读档后的第一个 tick，所有资源的产出倍率 = 1.0，直到某个系统显式重建 modifier。

---

## GDDs Flagged for Revision

| GDD | Reason | Type | Priority |
|-----|--------|------|----------|
| output-multiplier-system.md | base_rate 存储方案与 BigNumber 不兼容 | Consistency | Blocking |
| big-number-system.md | 需引入 MIN_POSITIVE 或明确亚单位值替代通道 | Consistency | Blocking |
| event-bus.md | 缺失 subscribe_pattern API + save.*/time.*/production_multiplier_changed 命名空间 | Consistency | Blocking |
| debug-console.md | 5 个 API 引用指向不存在接口 + OMS API 名不一致 | Consistency | Warning |
| modifier-engine.md | 缺 get_all_targets()；Interactions 表缺调试控制台 | Consistency | Warning |
| data-config-system.md | 缺 is_loaded() | Consistency | Warning |
| save-system.md | 缺 collect_save_data() + is_saving()；Interactions 表缺调试控制台 | Consistency | Warning |
| resource-system.md | Interactions 表缺调试控制台 | Consistency | Warning |
| time-manager.md | Interactions 表缺调试控制台；陈旧注释需清理 | Consistency | Warning |
| attribute-system.md | Interactions 表缺调试控制台 | Consistency | Warning |
| systems-index.md | debug-console 依赖声明过于简化 | Consistency | Warning |

---

## Verdict: **FAIL**

**3 个 Blocking 一致性缺陷 + 3 个 Blocking 设计缺陷 = 必须在架构阶段前解决。**

### Required Actions Before Re-running

1. **修复 BigNumber-OMS 亚单位值问题**：OMS 改用 float 存储 base_rate，仅在最终输出时转换为 BigNumber。同步修正 OMS AC-01 和 Formula 1/2
2. **在 EventBus GDD 追加 `subscribe_pattern` / `unsubscribe_pattern` API + 缺失事件命名空间**：save.*, time.*, production_multiplier_changed
3. **在 4 个上游 GDD 补充 debug-console 需要的 API**：ModifierEngine.get_all_targets()、DataConfig.is_loaded()、SaveManager.collect_save_data() + is_saving()
4. **修正 OMS API 命名不一致**：debug-console.md 中 `get_final_rate()` → `get_production_rate()`
5. **在 5 个上游 GDD 的 Interactions 表追加调试控制台下游引用**
6. **设计至少 3 个游戏循环桥梁系统 GDD**：#15 等级系统、#17 自动产出系统、#20 修炼系统
