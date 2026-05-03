# 等级系统 (Level System)

> **Status**: Designed
> **Author**: binlee1990 + agents
> **Last Updated**: 2026-05-04
> **Implements Pillar**: 4.1 数字增长就是快乐 · 4.2 放置 = 低频高价值决策 · 4.5 多层重置（弱预留）
> **Creative Director Review (CD-GDD-ALIGN)**: REVISED 2026-05-04（3 项 CONCERNS 已应用：C1 4.2 契约钩子加入 §Player Fantasy；C2 MAX_LEVELS_PER_GAIN 设计意图加入 §Tuning Knobs；C3 化神/合体境内部级间体感问题加入 §Open Questions）

## Overview

等级系统是玩家成长曲线的核心驱动器。玩家通过自动战斗、挂机探索等途径累积 `exp`（战斗经验），本系统在 exp 跨过阈值时把等级 +1，同时把 6 项 MVP 属性（`hp_max / atk / def / spd / crit_rate / crit_dmg`）的基础值按成长公式提升一档。等级越高 → 属性越强 → 玩家可挑战更难的区域 → 区域 exp 产出更高 → 等级再提升——这构成 game-concept §10.2 "第一条可玩闭环"中"等级提升 → 强化角色 → 推进区域"的关键三连环节。在 HUD 上，玩家看到的不是"系统在跑什么"，而是"我又升了一级、攻击 +5、距离突破下一境界还差 7 级"——这种"今天比昨天更强、且可量化"的体验是等级系统直接服务的玩家幻想。

在依赖图中，等级系统是 Feature 层的**整合中介**：它消费 ResourceSystem 的 `exp` 资源、调用 FormulaEngine 计算"升级所需经验"和"属性成长系数"、通过 `AttributeSystem.set_base` 写入新属性基础值、向 ModifierEngine 的 `realm` 池注册境界带来的乘法倍率、并通过 EventBus 发布 `level.changed` 事件供 HUD、区域解锁、修炼等下游订阅。它本身不创造 exp（来源是自动战斗/掉落）、不存储属性（AttributeSystem 才是账本）、不算公式（FormulaEngine 才是求值器）——它只回答四个问题：**经验够升级了吗？升到几级？6 项属性应该写成多少？境界倍率应挂在哪个 modifier？**

等级系统承担两个跨 GDD 关键职责：① 它是 MVP 范围内**唯一合法的 `exp` 消费者**——直接回应 cross-GDD review (2026-05-03) 标记的"MVP 5 项资源消费端为零"阻塞项，把 ResourceSystem 已具备但无人调用的 `spend("exp", amount)` 接通；② 它是**属性基础值的主要长期写入方**——承接 attribute-system.md §Player Fantasy 与 §Tuning Knobs 边界声明中明确委托给等级系统的"属性如何随时间增长"职责。本 GDD 完成后，#22 半自动战斗系统、#24 地图推进系统、#20 修炼系统的设计依赖才能解锁。

MVP 范围：单角色（`player` entity）从等级 1 起的成长曲线 + 与等级绑定的境界字段（凡人 → 炼气 → ……，具体绑定方式与境界倍率注册时机在 §Detailed Design 中确定）+ 属性增长经过 FormulaEngine 软上限以避免数值爆炸。**不在 MVP**：境界突破事件本身（消耗额外资源 / 天劫风险 / 玩家手动确认）、飞升 / 轮回 / 合道、多角色（弟子）独立等级、灵根 / 资质 / 命格等修仙身份扩展——本系统为这些 Post-MVP 扩展预留接口，但 MVP 不实现。Pillar 对应：**4.1 数字增长就是快乐**（主）——等级是玩家最直观、最频繁感知的成长指标；**4.2 放置 = 低频高价值决策**（强）——升级触发"换区域 / 加天赋 / 换装"等核心决策；**4.5 多层重置**（弱预留）——等级与境界在 `reset_scope=breakthrough` 范围内可被未来突破系统重置，本系统不主动触发但提供干净的重置接口。

## Player Fantasy

等级系统是修仙者命格上的"成道刻度"——平段时几乎察觉不到，只是属性条上每一格 exp 慢慢被填满；但每隔一段就有一格"台阶"，跨过去的瞬间整个修为体感都换一层。线性是表象，跃迁才是本质。它本身无形，但玩家所有"今天又强了一截"的感觉、所有"我能不能挑战这张图了"的盘算、所有"再挂一会就突破"的等待——都从这把成道刻度上流出。

**主锚定时刻**：玩家在 Lv.29 卡关一小时——东海挂机区还能稳定通关，但属性条只涨了一点点，看着距离突破还差 1.4 万 exp，他索性把队伍挂着自己去做饭。45 分钟后回来，HUD 上方的等级条爬到 Lv.30 临界点又跨了一步——浮窗弹出"修为入炼气境"，紧接着属性面板里 atk 从 312 跳到 386、hp_max 从 8,420 涨到 12,160，HUD 的 realm 倍率小标从 ×1.00 变成 ×1.20（来自 ModifierEngine 的 `realm` 池注入），原本要打 90 秒的精英怪现在 52 秒清完，掉宝刻度多亮起一格。玩家立刻把挂机点位推到下一张地图——Lv.30 才能进的"乾元谷"——开始下一段平段累积。**这就是台阶的力量**：平段持续投入持续涨数字（小快乐），台阶处一次性兑现成战斗体感的跃迁（大快乐）。两种快乐叠加，没有谁挤掉谁。

**次锚定时刻**：玩家把队伍挂在乾元谷，没事点开角色面板看了一眼"道行长卷"——长卷上 30 颗刻度珠已亮起，下一颗在 Lv.40 即筑基境前置。他算了一下：当前 exp 速率推进到 Lv.40 大约需要 6 小时挂机，刚好够覆盖一个工作日。他把今天上午装备出的 +15% 攻击速度法器换上、给队伍喂一颗 +20% exp 的小灵丹（来自缓存的 buff 池），收益条立刻刷新——原本 6 小时的预估变成 4.5 小时，"今天下班回来正好能看到下一阶突破"——他把游戏丢进后台、出门去公司。**这就是台阶的另一面**：每一颗未亮的刻度珠都是一个长期目标，玩家围绕它做"该挂哪 / 该用什么 buff / 该什么时候冲刺"的低频高价值决策。

等级系统作为玩家成长的核心驱动器，**它的承诺不是"持续给你数字"，而是"给你可信的台阶"**。在一个跨越突破/飞升/轮回多个阶段、长达数百小时的放置游戏里，玩家对"我距离下一格台阶有多远 / 跨过去会换来什么"的可计算性，是所有挂机点位选择、装备替换、buff 使用的前提。如果台阶的位置含糊不清、跨过台阶后属性增长却没什么变化、或者反过来 buff 一叠加战力直接膨胀到几个台阶都不需要打——玩家很快就会失去"今天攻克哪一阶"的目标感、回到无脑挂机。等级系统通过"平段 exp 持续累积 + 台阶处属性成长经过 FormulaEngine 软上限 + 境界阈值通过 ModifierEngine `realm` 池一次性注入 + `level.changed` 事件统一通告下游"的机制，把"成道刻度的可信节奏"作为修仙世界的核心节拍——一种克制的可期待，托住了 30 天后玩家面对屏幕上"修为：金丹境（Lv.7X）"时仍然觉得"下一格台阶清楚地立在那里，我看得见、够得着"。

（注：本节中 Lv.30 / Lv.40 / Lv.7X 等等级阈值与具体属性数字均为 Player Fantasy 示意，正式境界阈值表与属性成长曲线由 §Formulas 定义。）

**支柱对应**：
- **4.1 数字增长就是快乐**（主）：等级系统是 4.1 在中期成长曲线上**最直接的兑现者**——平段持续涨属性给"持续小快乐"，台阶处境界倍率注入给"跃迁大快乐"，两种快乐叠加，且都是可观测、可对账、可解释的；玩家从不需要对增长是否真实产生怀疑。
- **4.2 放置不是无操作，而是低频高价值决策**（强）：每一颗未亮的台阶刻度都是一个**目标**——玩家围绕"这一阶要挂哪 / 该用什么 buff / 该什么时候推图"做出真正有意义的决策。等级系统不强迫玩家逐秒操作，但它**为低频高价值决策提供清晰的目标坐标**。
- **4.5 多层重置制造长期目标**（弱预留）：境界阈值是第一层重置/跃迁的原型——MVP 内不实现突破事件本身，但本系统的"台阶"结构与未来突破/飞升/轮回的"更高阶段台阶"同构。每一次 Post-MVP 重置都可以复用本系统已建立的"平段 + 台阶"节拍，不需要重新教育玩家什么是"下一阶"。

**重要边界声明**：等级系统是上述支柱兑现的**必要基础设施**，而非支柱的直接载体——HUD 系统才是"等级条 / 属性面板 / 突破弹窗 / 道行长卷"等可视化呈现的承担者，AttributeSystem 才是属性数值的最终账本，ModifierEngine 才是境界倍率叠加规则的执行者，区域系统 / 地图推进系统才是"Lv.30 才能进乾元谷"门槛的判定者，FormulaEngine 才是属性成长公式与 exp 阈值公式的求值器。本系统**只为它们提供成道刻度的位置、跨越的时机、跨越后该写入的属性值与该挂载的境界倍率**。本节描述的"玩家锚定时刻"是等级系统作为基础设施被多个上层系统协同消费后所达成的整体体验，不应被理解为等级系统应主动包含 HUD 弹窗、突破特效、区域门槛判定等上层逻辑（参见 TD-SYSTEM-BOUNDARY 评审约束）。

**Pillar 4.2 契约钩子（CD-GDD-ALIGN C1 修订）**：`level.changed` 与 `realm.advanced` 两个事件**不是纯数据通告**——它们是 pillar 4.2 兑现的契约触发点。HUD 系统、区域系统 / 地图推进系统、（Post-MVP）装备建议系统、修炼系统等下游订阅者必须把这两个事件视为**"玩家低频高价值决策窗口已打开"的语义信号**，而非数字账本变更通知：`level.changed{levels_gained > 0}` 应触发"是否换更难的挂机区域 / 是否调整队伍 buff 配置"等决策提示；`realm.advanced` 应触发"新区域解锁 / 推荐换装 / 推荐冲刺下一境界"等显著呈现。如果下游漏接此契约，等级系统从玩家视角看就只剩"数字自动涨"，pillar 4.2 在体验层面将退化为 4.1 的副作用——这是必须由本系统在 GDD 层面显式声明、由跨 GDD 评审持续追踪的下游契约，而不是依赖 HUD 团队在未来某个时点自行领会。

## Detailed Design

### Core Rules

1. **架构形态**：`LevelSystem` 为 `RefCounted` 服务类，由 Autoload 单例 `/root/LevelSystem` 持有，与 `/root/AttributeSystem`、`/root/ResourceSystem`、`/root/ModifierEngine`、`/root/EventBus` 同级。对外暴露纯查询 + 升级触发 + 事件接口；不持有公式（FormulaEngine 计算）、不存储属性数值（AttributeSystem 持有）、不持有产出乘数（ModifierEngine 持有）、不创造 exp（自动战斗 / 掉落系统才是来源）。

2. **数据模型（per-entity）**：

   ```
   _entries: Dictionary[entity_id: String] → {
     "level": int,              # 主索引；MVP 起始 1，上限由 level_realm_config.json 决定
     "realm": String,           # 由 level 经阈值表自动派生（如 "lianqi"）
     "current_realm_id": int    # 阈值表中的索引；缓存避免重复 lookup，每次升级后重新派生
   }
   ```

   MVP 仅注册 `"player"` 一条；接口预留 `entity_id` 参数。**敌人 level 由敌人数据库直接持有，不经本系统注册**——避免 God Object，本系统只管玩家成长曲线，不管敌人静态等级。

3. **realm 阈值表（数据驱动）**：从 `level_realm_config.json` 读取。MVP 草拟 7 境界（具体数值经经济设计师 sign-off 后固化在 §Tuning Knobs）：

   | 境界序号 | realm | 中文 | 起始 level | 建议 realm modifier MULT 增量 |
   |---|---|---|---|---|
   | 0 | `fanren` | 凡人境 | 1 | 0.00 |
   | 1 | `lianqi` | 炼气境 | 10 | +0.20 |
   | 2 | `zhuji` | 筑基境 | 30 | +0.30 |
   | 3 | `jindan` | 金丹境 | 60 | +0.50 |
   | 4 | `yuanying` | 元婴境 | 100 | +0.80 |
   | 5 | `huashen` | 化神境 | 150 | +1.20 |
   | 6 | `heti` | 合体境 | 200 | +2.00 |

   境界 modifier 采用同一 `realm` 池内的加算值（同池内各境界 MULT 累加后乘 base，详见 §Formulas）；不为每个境界单独开池——避免乘算爆炸。

4. **API 表面**（全部同步调用，无协程）：

   ```
   # 实体生命周期
   register_entity(entity_id: String) → bool
   unregister_entity(entity_id: String) → int       # 返回被注销的 modifier 数
   has_entity(entity_id: String) → bool
   get_all_entity_ids() → Array[String]

   # 主驱动
   gain_exp(entity_id: String, amount: BigNumber) → int  # 返回本次连跳级数
   try_level_up(entity_id: String) → bool                # 仅 DEBUG_BUILD：跳过 spend 强制升 1 级

   # 查询
   get_level(entity_id: String) → int                    # 不存在返回 0
   get_realm(entity_id: String) → String                 # 不存在返回 ""
   get_realm_id(entity_id: String) → int                 # 不存在返回 -1
   get_exp_to_next(entity_id: String) → BigNumber        # 不存在返回 ZERO
   get_progress_ratio(entity_id: String) → float         # [0.0, 1.0]
   get_realm_progress(entity_id: String) → Dictionary    # {current_realm, level_in_realm, next_realm_level, level_to_next_realm}

   # 重置（接口预留，MVP 不调用）
   reset(entity_id: String, scope: String) → void        # 与 ResourceSystem.reset_by_scope 4 级有序包含一致

   # 存档
   snapshot() → Dictionary
   restore(data: Dictionary) → void
   ```

   所有 `entity_id` 不存在时遵循 ResourceSystem / AttributeSystem 既定的"安全降级，不崩溃"规约。

5. **升级原子流程（gain_exp）**：

   ```
   gain_exp(entity_id, amount):
     if not has_entity(entity_id): warn + 返回 0
     if amount.is_zero(): 返回 0

     # 第一步：原子消费 exp（spend 失败原子拒绝；can_afford 已前置但保留防御）
     if not ResourceSystem.spend("exp", amount): 返回 0

     # 第二步：连跳循环（仅累加 level，不写属性、不发事件）
     entry = _entries[entity_id]
     old_level = entry.level
     amount_remaining = amount
     levels_gained = 0
     while levels_gained < MAX_LEVELS_PER_GAIN:
       threshold_float = FormulaEngine.evaluate("level_exp", {"level": entry.level})
       threshold_bn = BigNumber.from_float(threshold_float)
       if amount_remaining.less_than(threshold_bn): break
       amount_remaining = amount_remaining.subtract(threshold_bn)
       entry.level += 1
       levels_gained += 1

     # 第三步：MAX_LEVELS_PER_GAIN 截断保护——剩余 exp 退回，不 silent drop
     if amount_remaining.greater_than(ZERO):
       ResourceSystem.add("exp", amount_remaining)
       if levels_gained == MAX_LEVELS_PER_GAIN:
         warn("MAX_LEVELS_PER_GAIN 截断 entity={entity_id}; 退回 {amount_remaining} exp")

     if levels_gained == 0: 返回 0

     # 第四步：境界判定 + modifier 切换
     old_realm = entry.realm
     new_realm = _derive_realm(entry.level)
     if new_realm != old_realm:
       _swap_realm_modifiers(entity_id, old_realm, new_realm)
       entry.realm = new_realm
       entry.current_realm_id = _realm_table.find(new_realm)

     # 第五步：属性全量重算（一次 6 次 set_base）
     _recalculate_attributes(entity_id, entry.level, entry.current_realm_id)

     # 第六步：事件发布（聚合，按顺序）
     EventBus.emit("level.changed", {
       entity_id, old_level, new_level: entry.level, levels_gained
     })
     if new_realm != old_realm:
       EventBus.emit("realm.advanced", {entity_id, old_realm, new_realm})

     return levels_gained
   ```

   设计要点：
   - **`amount_remaining` 退回 exp 资源**：防御异常 exp 注入时不 silent drop——超限部分回到 ResourceSystem.exp 余额，下个 tick 调用 gain_exp 自然分摊到多 tick
   - **属性重算在 modifier 切换之后**：set_base 写入时 ModifierEngine 缓存已被新 realm modifier 标脏，下次 get_final 自动反映新倍率
   - **`level.changed` 在属性写入完成后发布**：HUD 订阅时调 AttributeSystem.get_final 立即拿到最新值，无脏读窗口
   - **`realm.advanced` 在 `level.changed` 之后发布**：HUD 处理顺序为"等级条刷新 → 境界跃迁特效"，符合视觉因果

6. **属性全量重算（_recalculate_attributes）**：对 MVP 6 项属性逐项调 `FormulaEngine.evaluate("{attr_id}_growth", {"level": new_level, "realm_id": current_realm_id})` 算出 float，转 BigNumber（钳位 ≥1 的 BigNumber 边界由 BigNumber 层归一化，本系统无需额外校验）后调 `AttributeSystem.set_base(entity_id, attr_id, new_base)`。**全量重算（不增量）**——理由：① FormulaEngine 已内置 dirty-flag 缓存；② AttributeSystem.set_base 在 delta=ZERO 时不发事件（idempotent，性能无损）；③ 增量重算需维护"上一级的 base"额外状态，引入对账复杂度；④ 6 次 set_base 在帧预算内（attribute-system.md §Formulas 5: ~0.155 ms 总耗时）。

7. **境界跨越 modifier 切换（_swap_realm_modifiers）**：

   ```
   _swap_realm_modifiers(entity_id, old_realm, new_realm):
     # 1. 注销旧境界 source 下的全部 modifier（若 old_realm 非空）
     if old_realm != "":
       ModifierEngine.unregister_by_source(_realm_source(entity_id, old_realm))

     # 2. 跨多个境界时只挂终态——中间境界 modifier 永远不存在于系统中
     if new_realm == "fanren": return  # 凡人境无加成

     new_value = _realm_table[new_realm].mult_value
     for target in REALM_MODIFIER_TARGETS:
       ModifierEngine.register({
         target: target, type: MULT, value: new_value, pool: "realm",
         source: _realm_source(entity_id, new_realm), duration: 0
       })

   # source 命名约定
   _realm_source(entity_id, realm) → "level_system.realm." + entity_id + "." + realm
   ```

   `REALM_MODIFIER_TARGETS` 列表（MVP，10 个 target）：
   - 4 项 OMS production target：`["lingqi_production", "xiuwei_production", "lingshi_production", "herb_production"]`
   - 6 项 attribute target：`["player.hp_max", "player.atk", "player.def", "player.spd", "player.crit_rate", "player.crit_dmg"]`

   *跨多个境界（凡人 → 筑基跳过炼气）：unregister_by_source 一次注销旧境界全部 modifier；register 仅挂终态境界 10 条；中间境界 modifier 不存在。*

   *Post-MVP 弟子或多角色：source 含 entity_id 已支持隔离；不同 entity 的 realm modifier 互不影响。*

8. **存档/读档时 modifier 重建**：本系统订阅 `EventBus` 的 `save.loaded` 事件（save-system.md §Detailed Design 行 89 确认）。重建流程：

   ```
   restore(data):
     # 仅恢复内部 _entries 数据，不调 ModifierEngine
     for entity_id in data.entities:
       _entries[entity_id] = data.entities[entity_id]

   _on_save_loaded(payload):
     # 此时 ResourceSystem.restore 与 AttributeSystem.restore 已完成，事件抑制已解除
     for entity_id in _entries:
       entry = _entries[entity_id]
       # 防御：清理可能残留的旧 modifier（崩溃恢复 / 热重载场景）
       _swap_realm_modifiers(entity_id, "", entry.realm)
     # 不发 level.changed / realm.advanced——HUD 已订阅 save.loaded 自行整体重绘
   ```

   设计要点：
   - **不依赖 `_ready()`**：Autoload 初始化顺序由场景树决定，跨 Autoload 同步无保证
   - **save.loaded 由存档系统在所有 restore 完成后统一发布**，是唯一可信的"账本就绪"时刻
   - **save.loaded 后不发 level.changed / realm.advanced**：避免 HUD 在恢复完成后被无意义事件刷新；HUD 订阅 save.loaded 自行整体重绘
   - 注：attribute-system.md §Edge Cases 中的旧存档恢复事件名已在 2026-05-04 同步修订为 `save.loaded` 订阅语义。

9. **事件发布**：
   - **`level.changed`**：payload `{entity_id: String, old_level: int, new_level: int, levels_gained: int}`——单次 gain_exp 内**只发 1 条**（聚合），无论连升 1 级还是 100 级。EventBus GDD 已在 2026-05-04 同步为该 payload。
   - **`realm.advanced`** (新增事件)：payload `{entity_id: String, old_realm: String, new_realm: String}`——跨境界时发布（连跳跨多境界仍只发 1 条，old_realm 为起始境界、new_realm 为终态境界）。EventBus GDD 已在 2026-05-04 追加该命名空间与 Interactions/Dependencies 表项。
   - **HUD 等下游可只订阅 `realm.advanced`** 处理境界跃迁特效，不需要在每条 `level.changed` 中检查 `old_realm != new_realm`。

10. **No-Op 安全降级**（与 ResourceSystem / AttributeSystem 一致）：
    - `entity_id` 未注册：getter 返回安全默认值；`gain_exp` 打印警告 + 返回 0
    - `gain_exp(entity_id, BigNumber.ZERO)`：直接返回 0，不调 spend、不发事件
    - `ResourceSystem.spend("exp", amount)` 返回 false：原子拒绝，level 不变（理论不达——can_afford 已前置；防御性退出）
    - level 已达配置最大值：level 不再增加；剩余 amount_remaining 全部退回 ResourceSystem.exp
    - `FormulaEngine.evaluate` 返回 0.0（公式缺失 / 语法错误）：threshold = 0，触发 MAX_LEVELS_PER_GAIN 截断保护退回 + 警告
    - 重复 `register_entity(entity_id)`：返回 false，不覆盖（与 AttributeSystem.register_entity 一致）

11. **重置接口预留（reset）**：本系统对外暴露 `reset(entity_id, scope: String)` 方法，按 scope 归零 level + realm（与 ResourceSystem.reset_by_scope 4 级有序包含一致：`none / breakthrough / ascension / rebirth`）。MVP 不主动触发——但接口已就绪供 Post-MVP 突破/飞升/轮回系统调用。reset 时同步：先 unregister_by_source 注销当前境界全部 modifier；level 归 1、realm 归 `"fanren"`、current_realm_id = 0；触发 `_recalculate_attributes` 重算属性 base 至 Lv.1 默认值；发布 `level.changed`（new_level=1，levels_gained = -(old_level - 1)）+ `realm.advanced`（new_realm="fanren"）。

12. **调试控制台只读查询**：暴露 `get_level / get_realm / get_realm_id / get_realm_progress / get_exp_to_next / get_all_entity_ids` 等只读接口（与 attribute-system.md / resource-system.md 调试接口风格一致）。`level info {entity_id}` 命令打印 level / realm / current_realm_id / exp_to_next / progress。`try_level_up` 写命令仅 DEBUG_BUILD 暴露——跳过 exp spend 强制升 1 级，触发完整重算流程，便于测试境界跨越。

### States and Transitions

`LevelSystem` 整体**无状态机**——纯查询 + 触发 + 事件源服务。**实体条目**有显式生命周期，与 attribute-system.md 风格一致：

```
[Unregistered] ──register_entity──→ [Active] ──unregister_entity──→ [Removed]
                                       ↑                                 ↓
                                       └────── re-register fails ────────┘
```

| 状态 | 判定 | 行为 |
|------|------|------|
| Unregistered | `has_entity(id) == false` | getter 返回 0 / "" / -1 / ZERO；gain_exp 打印警告 + 返回 0 |
| Active | `has_entity(id) == true` | 正常 gain_exp 触发升级流程；可被多次升级与境界跨越 |
| Removed | `has_entity(id) == false`（曾经 Active） | 同 Unregistered；unregister_entity 时按 source 注销该 entity 的全部 realm modifier |

**level 数值无独立状态机**——level 是单调递增整数（MVP 不支持降级）；realm 由 level + `level_realm_config.json` 阈值表自动派生，不持有独立状态。`current_realm_id` 缓存仅为性能优化，每次升级后通过 `_derive_realm` 重新派生确认。

### Interactions with Other Systems

| 系统 | 方向 | 数据接口 | 说明 |
|------|------|---------|------|
| 大数值系统 (BigNumber) | 上游依赖 | exp 阈值与属性成长结果均为 `BigNumber`；调 `from_float / to_dict / from_dict / less_than / greater_than / subtract` | 硬依赖，无法脱离独立工作 |
| 事件总线 (EventBus) | 上游依赖（双向） | 发布 `level.changed`、`realm.advanced`；订阅 `save.loaded` 触发 modifier 重建 | 唯一既发布又订阅 EventBus 的等级系统接口 |
| 公式引擎 (FormulaEngine) | 上游依赖 | `evaluate("level_exp", {level})` 算升级阈值；`evaluate("{attr_id}_growth", {level, realm_id})` 算属性成长系数 | 公式表达式必须经过 `log_softcap`（防止指数爆炸）；本系统不直接调用其他公式 |
| 资源系统 (ResourceSystem) | 上游依赖（spend）+ 下游协作（add 退回） | `spend("exp", BigNumber)` 原子消费；MAX_LEVELS_PER_GAIN 截断时 `add("exp", remaining)` 退回 | 必须 spend 成功后才升级；spend 失败原子拒绝；exp 退回保证不 silent drop |
| 修正器/倍率引擎 (ModifierEngine) | 上游依赖 | `register({target, type:MULT, value, pool:"realm", source, duration:0})` × 10 + `unregister_by_source(source)` | 每跨一次境界 1 次 unregister + 10 次 register；source 命名 `"level_system.realm.{entity_id}.{realm}"` |
| 属性系统 (AttributeSystem) | 下游调用 | `set_base(entity_id, attr_id, BigNumber)` × 6（每次升级全量重算 6 项 attribute） | 不调 register_entity（敌人数据库职责）；本系统是 MVP 中 player 实体属性 base 的主要写入方 |
| 数据配置系统 | 上游依赖 | 启动时读取 `level_realm_config.json`（境界阈值表 + realm modifier MULT value）和 `attribute_growth_config.json`（每属性的成长公式 ID 注册到 FormulaEngine） | 配置驱动；公式 ID 必须事先在 FormulaEngine 注册 |
| 存档系统 | 下游协作 + 上游事件依赖 | `snapshot()` / `restore()`；订阅 `save.loaded` 重建 modifier | snapshot 仅持久化 `{level, realm}`（realm 字段虽派生但持久化便于版本迁移）；ModifierEngine 状态不持久化 |
| 调试控制台 | 下游 → 只读查询 | `get_level / get_realm / get_realm_progress`；DEBUG_BUILD 下 `try_level_up` 写命令 | 与 attribute-system.md / resource-system.md 调试接口风格一致 |
| 自动产出系统 (Post-MVP #17) | 间接关联 | 不直接调本系统；通过 `realm` 池 modifier 自动反映在 `lingqi_production / xiuwei_production / lingshi_production / herb_production` 中 | OMS 通过 ModifierEngine.get_multiplier 自动获取 realm 倍率，无需感知等级 |
| 战斗计算器 (Post-MVP #21) | 间接关联 | 不直接调本系统；通过 `AttributeSystem.get_final("player", attr_id)` 自动获取受 realm modifier 加成的属性 | 战斗计算器不感知等级 |
| HUD 系统 (Post-MVP #30) | 间接关联 | 不直接调本系统的 setter；订阅 `level.changed` / `realm.advanced` 事件 + 调用 `get_level / get_realm / get_realm_progress` 查询面板数据 | UI 呈现完全由 HUD 决定，本系统只发数据 |
| 自动战斗系统 (Post-MVP #22) | 上游 → 主动调用 | 战斗结束时调 `LevelSystem.gain_exp("player", drop_exp)` | exp 唯一合法来源；MVP 自动战斗设计前由其他驱动桥接 |
| 修炼系统 (Post-MVP #20) | 间接关联 | 不直接调本系统；可通过 buff modifier 影响 exp 产出速率 | 修炼系统持有 lingqi → xiuwei 转化逻辑，不直接干预 level |
| 区域系统 / 地图推进系统 (Post-MVP #23/24) | 下游 → 主动查询 | 调 `get_level("player")` 检查区域 level 门槛 | 不订阅事件；按需查询 |
| 物品/材料系统 | 无直接关联 | — | 物品是离散资产，与等级成长无直接接口 |

**关键非依赖（容易误以为是依赖但不是）**：

| 系统 | 关系 | 说明 |
|------|------|------|
| 状态机系统 | 无直接关联 | 本系统是 CRUD + 事件源，无业务状态机 |
| 随机数与种子系统 | 无直接关联 | 升级阈值与属性成长完全确定性；未来若加入"突破成功率"由突破系统持有 |
| ModifierEngine.modifier_expired 事件 | 无关联 | realm modifier 是永久（duration=0），不会过期；本系统不订阅 modifier_expired |

**双向一致性自检（与上游 / 下游 GDD 对齐）**：

- ✅ **EventBus GDD** §事件名空间 / §Interactions / §Dependencies 已在 2026-05-04 同步 `level.changed` payload `{entity_id, old_level, new_level, levels_gained}`。
- ✅ **EventBus GDD** 已在 2026-05-04 追加 `realm.advanced` 事件及等级系统发布关系。
- ✅ **AttributeSystem GDD** §Edge Cases 的旧存档恢复事件名已在 2026-05-04 修订为 `save.loaded` 订阅语义。
- ✅ **AttributeSystem GDD** §Tuning Knobs 关于"属性如何随时间增长"的委托声明与本 GDD 一致——本系统是 player 属性 base 的主要长期写入方
- ✅ **ResourceSystem GDD** §Detailed Design 中 exp 资源的 `reset_scope=breakthrough` 与本系统 `reset(entity_id, scope)` 接口预留一致
- ✅ **ModifierEngine GDD** §Interactions 行 125 已列出"等级系统 — 等级变化时注册/注销境界/等级修正"——一致
- ✅ **FormulaEngine GDD** §Interactions 行 122-123 已列出"等级系统/突破系统 — 调用公式引擎计算属性成长系数 / 升级经验需求"——一致

## Formulas

### 1. 升级经验阈值 (Level EXP Threshold)

`formula_id: "level_exp"`

`level_exp = EXP_BASE * pow(level, 2.0) * pow(EXP_GROWTH, softcap(level, EXP_SOFTCAP_LV, EXP_SOFTCAP_POW))`

**变量：**

| 变量 | 符号 | 类型 | 范围 | 说明 |
|------|------|------|------|------|
| 当前等级 | `level` | int | [1, 200] | 注入变量；升到下一级前的当前等级 |
| 基础经验 | `EXP_BASE` | float | (0, ∞) | 调参常量，默认 `10.0`；控制 Lv.1→2 起点 |
| 指数增长系数 | `EXP_GROWTH` | float | (1.0, 1.1) | 调参常量，默认 `1.038`；控制每级递增速率 |
| softcap 等级阈值 | `EXP_SOFTCAP_LV` | int | [60, 100] | 调参常量，默认 `80`；高于此级后增速受控 |
| softcap 幂次 | `EXP_SOFTCAP_POW` | float | (0.3, 0.8) | 调参常量，默认 `0.55`；控制 80 级后压制力度 |
| 输出 | `level_exp` | float | [10, ~3e6] | 升到下一级所需 exp 量 |

`softcap(v, t, p)` = `v`（当 v ≤ t）；= `t + (v - t)^p`（当 v > t）

**输出范围：** 单调递增但高端增速受控；≥ EXP_BASE。FormulaEngine 返回 float，调用方 `BigNumber.from_float()` 转换后与 `exp.current` 比较。

**示例（含拟合误差）：**

| 等级 | softcap 后有效等级 | 公式结果 | 节奏目标 | 误差 |
|------|-------------------|---------|---------|------|
| L1 | 1.0 | ~10 | 10 | 0% |
| L5 | 5.0 | ~302 | 300 | +0.7% |
| L10 | 10.0 | ~1453 | 1500 | -3.1% |
| L30 | 30.0 | ~27,400 | 36,000 | -24% |
| L50 | 50.0 | ~161,700 | 144,000 | +12% |
| L99 | 85.76 | ~2,391,000 | (实际节奏 ~6 小时) | n/a |

**节奏说明（用户决策 A）**：Lv.99→100 实际为 ~6 小时（2.4M exp / 100 exp/s = 24,000 s），而非早期提议的 ~3 天。MVP 多日体验由 Lv.100-200 多级累加提供，而非单级时长。L30 偏差 -24% 在调参安全范围内（EXP_BASE / EXP_GROWTH 微调可修正），最终值由数值设计师 sign-off 后固化在 §Tuning Knobs（用户决策 B）。

---

### 2. hp_max 成长公式 (HP Max Growth)

`formula_id: "hp_max_growth"`

`hp_max_growth = clamp(log_softcap(100.0 * pow(level, 1.8) * (1.0 + realm_id * 0.15), 80000.0), 100.0, 1000000.0)`

**变量：**

| 变量 | 符号 | 类型 | 范围 | 说明 |
|------|------|------|------|------|
| 当前等级 | `level` | int | [1, 200] | 注入变量 |
| 境界序号 | `realm_id` | int | [0, 6] | 注入变量；凡人=0，合体=6 |
| log_softcap 阈值 | `80000.0` | float | 常量 | 约 Lv.160 触发 |
| 输出 | `hp_max_growth` | float | [100, 1e6] | 写入 `AttributeSystem.set_base("player", "hp_max")` |

`log_softcap(v, t)` = `v`（v ≤ t）；= `t * log10(v/t + 1)`（v > t）

**输出范围：** clamp [100, 1e6]，与 attribute-system.md §Detailed Design 6 上限一致。

**示例：**
- L1, realm_id=0: 100 × 1 × 1.0 = 100 ≈ 100 ✓
- L200, realm_id=6: 100 × 200^1.8 × 1.9 = 3,596,320 → softcap → 132,960 ≈ 1.3e5（目标 1e5）

---

### 3. atk 成长公式 (Attack Growth)

`formula_id: "atk_growth"`

`atk_growth = clamp(log_softcap(10.0 * pow(level, 1.75) * (1.0 + realm_id * 0.12), 8000.0), 10.0, 1000000.0)`

**变量：**

| 变量 | 类型 | 范围 | 说明 |
|------|------|------|------|
| `level` | int | [1, 200] | 注入变量 |
| `realm_id` | int | [0, 6] | 注入变量 |
| softcap 阈值 | float | `8000.0` 常量 | 约 Lv.140 触发 |
| 输出 `atk_growth` | float | [10, 1e6] | 写入 `set_base("player", "atk")` |

**输出范围：** clamp [10, 1e6]。

**示例：**
- L1, realm_id=0: 10 × 1 × 1 = 10 ✓
- L200, realm_id=6: 10 × 200^1.75 × 1.72 = 196,613 → softcap → 11,264 ≈ 1.1e4（目标 1e4）

---

### 4. def 成长公式 (Defense Growth)

`formula_id: "def_growth"`

`def_growth = clamp(log_softcap(5.0 * pow(level, 1.7) * (1.0 + realm_id * 0.10), 4000.0), 5.0, 1000000.0)`

**变量：**

| 变量 | 类型 | 范围 | 说明 |
|------|------|------|------|
| `level` | int | [1, 200] | 注入变量 |
| `realm_id` | int | [0, 6] | 注入变量 |
| softcap 阈值 | float | `4000.0` 常量 | 约 Lv.145 触发 |
| 输出 `def_growth` | float | [5, 1e6] | 写入 `set_base("player", "def")` |

**输出范围：** clamp [5, 1e6]。

**示例：**
- L1, realm_id=0: 5 × 1 × 1 = 5 ✓
- L200, realm_id=6: 5 × 200^1.7 × 1.6 = 66,032 → softcap → 4,972 ≈ 5,000（目标 5,000）

**节奏意图（economy-designer 验证）**：def 早期成长慢于 atk，制造"玻璃炮"体感，驱动玩家主动换防御装备（Pillar 4.2）。softcap 拐点 Lv.145 后边际收益压缩，高防打法靠装备 + 阵法。

---

### 5. spd 成长公式 (Speed Growth)

`formula_id: "spd_growth"`

`spd_growth = clamp(log_softcap(10.0 * pow(level, 1.35) * (1.0 + realm_id * 0.06), 700.0), 10.0, 1000.0)`

**变量：**

| 变量 | 类型 | 范围 | 说明 |
|------|------|------|------|
| `level` | int | [1, 200] | 注入变量 |
| `realm_id` | int | [0, 6] | 注入变量 |
| softcap 阈值 | float | `700.0` 常量 | 约 Lv.120 触发；防止突破上限 1000 |
| 输出 `spd_growth` | float | [10, 1000] | 写入 `set_base("player", "spd")`；上限 1000 硬边界 |

**输出范围：** clamp [10, 1000]，严格不超过 attribute-system 上限 1000。

**示例：**
- L1, realm_id=0: 10 × 1 × 1 = 10 ✓
- L200, realm_id=6: 10 × 200^1.35 × 1.36 = 15,613 → softcap → 958 ≈ 800-1000 ✓

**敏感参数警告（economy-designer 验证）**：spd 上限 1000 硬边界；建议 economy-designer 重点关注 Lv.150+ 实际值是否触碰；softcap 阈值 700 为主要调参点。

---

### 6. crit_rate 成长公式 (Crit Rate Growth)

`formula_id: "crit_rate_growth"`

`crit_rate_growth = clamp(log_softcap(0.05 + 0.003 * pow(level, 1.1) * (1.0 + realm_id * 0.04), 0.6), 0.0, 1.0)`

**变量：**

| 变量 | 类型 | 范围 | 说明 |
|------|------|------|------|
| `level` | int | [1, 200] | 注入变量 |
| `realm_id` | int | [0, 6] | 注入变量 |
| 基础暴击率 | float | `0.05` 常量 | Lv.1 起点 5%（裸值无装备）|
| softcap 阈值 | float | `0.6` 常量 | 裸值 60% 以上转对数；装备另加 |
| 输出 `crit_rate_growth` | float | [0.0, 1.0] | 基础值，最终值通过 ModifierEngine 叠加装备/天赋后使用 |

**输出范围：** clamp [0.0, 1.0]；log_softcap 确保裸值不超过 ~0.7，**严格上界 1.0 由 clamp 保证**——任何 NaN/inf 由 BigNumber 层归一化，crit_rate 永不会进入战斗计算 NaN 状态。

**示例：**
- L1, realm_id=0: 0.05 + 0.003 × 1 × 1 = 0.053 ≈ 0.05 ✓
- L200, realm_id=6: 0.05 + 0.003 × 200^1.1 × 1.24 = 1.478 → softcap → 0.323 → +0.05 → 0.373 ≈ **37%**

**设计意图（用户决策 C）**：Lv.200 合体境裸值约 37%，剩余至 100% 由装备/天赋/buff 通过 ModifierEngine 叠加补满。这一设计为装备系统留出价值空间——若裸值已达 50%+，装备的暴击率词条将失去激励，违背 Pillar 4.2"装备替换是低频高价值决策"。

---

### 7. crit_dmg 成长公式 (Crit Damage Growth)

`formula_id: "crit_dmg_growth"`

`crit_dmg_growth = clamp(log_softcap(1.5 + 0.025 * pow(level, 1.15) * (1.0 + realm_id * 0.05), 6.0), 1.0, 100.0)`

**变量：**

| 变量 | 类型 | 范围 | 说明 |
|------|------|------|------|
| `level` | int | [1, 200] | 注入变量 |
| `realm_id` | int | [0, 6] | 注入变量 |
| 基础暴伤 | float | `1.5` 常量 | Lv.1 起点 150% 暴伤（×1.5 倍）|
| softcap 阈值 | float | `6.0` 常量 | ×6.0 以上转对数，约 Lv.130 触发 |
| 输出 `crit_dmg_growth` | float | [1.0, 100.0] | 写入 `set_base("player", "crit_dmg")` |

**输出范围：** clamp [1.0, 100.0]。

**示例：**
- L1, realm_id=0: 1.5 + 0.025 × 1 × 1 = 1.525 ≈ 1.5 ✓
- L200, realm_id=6: 1.5 + 0.025 × 200^1.15 × 1.3 = 16.68 → softcap → 3.46 → +1.5 → 4.96 ≈ 5.0 ✓

---

### 8. 境界倍率映射 (Realm Modifier Value)

`realm_modifier_value(realm_id)` 为查表函数（非 FormulaEngine 表达式），由 `level_realm_config.json` 数据驱动。

**注意**：本表给出三列——增量列（与 §Detailed Design 规则 3 表一致）、累计列（注册到 ModifierEngine `realm` 池的实际 MULT 值）、总倍率（accumulator pool 公式 `final_mult = 1.0 + pool_sum`）：

| realm_id | realm | 中文 | MULT 增量（per-step） | MULT 累计（注册值） | 总倍率（合并后） |
|----------|-------|------|--------------------|------------------|----------------|
| 0 | `fanren` | 凡人境 | 0.00 | 0.00 | ×1.00 |
| 1 | `lianqi` | 炼气境 | +0.20 | 0.20 | ×1.20 |
| 2 | `zhuji` | 筑基境 | +0.30 | 0.50 | ×1.50 |
| 3 | `jindan` | 金丹境 | +0.50 | 1.00 | ×2.00 |
| 4 | `yuanying` | 元婴境 | +0.80 | 1.80 | ×2.80 |
| 5 | `huashen` | 化神境 | +1.20 | 3.00 | ×4.00 |
| 6 | `heti` | 合体境 | +2.00 | 5.00 | ×6.00 |

**实际注册值为"累计列"**（用户决策 D）：`_swap_realm_modifiers` 在跨境界时只挂终态境界——按 ModifierEngine 加算池语义（`pool_mult = 1.0 + Σ pool MULT`），同一时刻 `realm` 池中只有 1 条 source 的 modifier 在线，其 value 即"累计列"值。例如玩家在筑基境时，注册到 `realm` 池的 modifier value = `0.50`（不是 `0.30` 增量），ModifierEngine 给出的 `pool_mult` = 1.0 + 0.50 = 1.50（即"总倍率列"）。

**跨境界涨幅（economy-designer 验证）**：每跨境界总倍率涨幅持续递增（+20% / +25% / +33% / +40% / +43% / +50%），符合"越往后跃升感越强"的修仙叙事；最大 ×6.0 不构成 OMS 数值爆炸。

---

### 9. 单次 gain_exp 调用耗时 (Single gain_exp Cost)

`gain_exp_time = t_spend + N_levels × t_eval_level_exp + t_realm_switch + 6 × t_eval_attr + 6 × t_set_base + t_emit`

**变量：**

| 变量 | 类型 | 范围（ms） | 说明 |
|------|------|-----------|------|
| spend 耗时 | float | ~0.036 | resource-system.md §Formulas 6 典型值（有上限+3 订阅者）|
| 连跳级数 N_levels | int | [1, 100] | 本次 gain_exp 触发的升级数；上限 MAX_LEVELS_PER_GAIN=100 |
| 单次 level_exp 求值 | float | ~0.01 | FormulaEngine 缓存命中典型值 |
| 境界切换开销 | float | 0 or ~1.0 | 不跨境界=0；跨境界 = 1×unregister_by_source + 10×register ≈ 1.0 ms |
| 单次属性公式求值 | float | ~0.01 | 同 t_eval_level_exp |
| 单次 set_base | float | ~0.026 | attribute-system.md §Formulas 5 典型值（含事件发布，3 订阅者）|
| 事件发布 | float | ~0.013 | EventBus emit × 1（聚合 level.changed 单条）|
| 输出 gain_exp_time | float | ms | 单次调用总耗时 |

**输出范围：** 随 N_levels 线性增长。

**典型值（升 1 级，不跨境界）：**

`0.036 + 1×0.01 + 0 + 6×0.01 + 6×0.026 + 0.013 = 0.275 ms`

**最坏值（连升 100 级，跨 1 境界）：**

`0.036 + 100×0.01 + 1.0 + 6×0.01 + 6×0.026 + 0.026 = 2.278 ms`

> 最坏值 2.278 ms 超出帧预算（§12 分配 0.333 ms），但连升 100 级为稀有事件（离线回归首次 tick），可接受单帧超支；后续 tick 无连跳则恢复正常。**帧预算为统计平均值，不是单帧硬上限**——遵循 attribute-system / resource-system 的同等约定。

---

### 10. 单实体内存占用 (Memory per Entity)

`memory_entity = dict_overhead + level_size + realm_size + realm_id_size`

**变量：**

| 变量 | 范围（bytes） | 说明 |
|------|--------------|------|
| Dictionary 开销 | ~64 | GDScript Dictionary 基础元数据 |
| level 字段 | ~8 | int64 |
| realm 字段 | ~40 | String（指针 + 字符数据，avg 8 字符）|
| current_realm_id 字段 | ~8 | int64 |
| 输出 memory_entity | ~120 | 单 player 实体 _entries 条目占用 |

**输出范围：** ~120 bytes/实体；MVP 1 实体 → 约 120 bytes，可忽略不计。

---

### 11. 境界 modifier 内存占用 (Realm Modifier Memory)

`memory_realm_modifiers = n_targets × modifier_size`

**变量：**

| 变量 | 范围 | 说明 |
|------|------|------|
| modifier 目标数 n_targets | 10 | 4 OMS production + 6 player attribute |
| 单条 modifier 大小 | ~120 bytes | modifier-engine.md §Formulas 6 |
| 输出 memory_realm_modifiers | ~1,200 bytes | 单境界注册的全部 modifier 内存 |

**输出范围：** 固定 ~1.2 KB/实体（任意时刻仅 1 个境界的 10 条 modifier 在线）。

**示例：** player 处于金丹境：10 × 120 = 1,200 bytes ≈ 1.2 KB ✓

---

### 12. 等级系统帧预算 (Level System Frame Budget)

`level_budget = t_frame × budget_ratio`

**变量：**

| 变量 | 范围 | 说明 |
|------|------|------|
| 帧时长 t_frame | 16.6 ms | 60 fps 目标 |
| 预算比例 budget_ratio | 0.02 | 等级系统分配 2% 帧预算（参考 resource-system §Formulas 8）|
| 预算 level_budget | ~0.333 ms | 单帧内等级系统允许消耗的最大 CPU 时间 |

**输出范围：** 固定值 0.333 ms/frame。

**预算验证：**
- 典型调用（升 1 级，不跨境界）：0.275 ms < 0.333 ms ✓ 预算内
- 最坏调用（升 100 级，跨境界）：2.278 ms > 0.333 ms 超支约 6.8×
- 超支场景为低频离线回归事件，同一游戏会话内最多发生 1 次/数分钟；放置游戏中可接受单帧超支，不影响 60 fps 稳定性（下一帧等级系统无操作，预算自然补偿）。

## Edge Cases

### 类别 A：gain_exp 路径

- **If `amount` is `BigNumber.NaN` or `BigNumber.Inf`（非有限值）**: `gain_exp` 打印 `[ERROR] gain_exp: invalid amount entity={entity_id}`，返回 0，不调用 `ResourceSystem.spend`。
- **If `amount.is_zero()` 或 `amount.less_than(ZERO)`**: 返回 0，不调用 spend，不发事件。负值由调用方传入时视同 ZERO——等级系统不反向消费 exp。
- **If `entity_id` 不在 `_entries` 中（未注册或已 unregister）**: 打印 warn，返回 0。ResourceSystem.exp 余额不变。
- **If `ResourceSystem.can_afford("exp", amount)` 刚返回 true 但 `spend("exp", amount)` 随即返回 false（并发窗口或 tick 间资源被其他路径消耗）**: `gain_exp` 原子拒绝，level 不变，返回 0，不发事件。ResourceSystem 账本不变，无需退回。
- **If `amount` 恰好等于本级升级阈值（`amount_remaining == threshold_bn` 时 `less_than` 返回 false）**: 本级升级成功，`amount_remaining` 归零，while 循环因下一级阈值不满足而退出。返回 `levels_gained = 1`，无余量退回。
- **If 前期巨额 exp 注入跨多个境界（如 Lv.1 注入 1e6 exp 连跳至合体境）**: 仅发 1 条 `level.changed`（`levels_gained = N`）+ 1 条 `realm.advanced`（`old_realm = "fanren"`，`new_realm = "heti"`）。中间境界 modifier 不挂载，只挂终态境界的 10 条 modifier。这是设计决策，不是遗漏——§Detailed Design 规则 7 明确"只挂终态"。
- **If `amount` 精度超出 BigNumber 序列化安全范围（如 30 天挂机累积约 2.59e8 exp）**: BigNumber 层负责归一化，本系统透明传递。若 BigNumber.from_float 精度损失导致阈值比较结果偏差一级，多出的差值退回 ResourceSystem.exp，由下次 gain_exp 自然消化。
- **If `MAX_LEVELS_PER_GAIN=100` 截断触发（`levels_gained == 100` 时 `amount_remaining > 0`）**: `amount_remaining` 通过 `ResourceSystem.add("exp", amount_remaining)` 退回，打印 warn。下一次 `gain_exp` 调用（下个 tick）从退回的余量继续分摊。**不 silent drop**。

### 类别 B：境界跨越路径

- **If `level_realm_config.json` 缺失或为空**: 系统在启动时记录 `[FATAL] realm config missing`，`_realm_table` 退化为仅含 `fanren`（起始 1，MULT 0）的单条兜底表；所有实体永远处于凡人境，无 realm modifier 注册。功能降级但不崩溃。
- **If `_realm_table` 的阈值序列未按 level 升序排列**: 系统在加载时对阈值表按 `min_level` 升序排序后使用；记录 warn 提示配置未排序。`_derive_realm` 始终在已排序表上二分查找。
- **If `levels_gained > 0` 但升级后 level 仍在同一境界阈值区间（未跨境界）**: `new_realm == old_realm`，`_swap_realm_modifiers` 不调用，`realm.advanced` 不发布。`level.changed` 正常发布（`levels_gained > 0`）。
- **If 跨 N 个中间境界一次跳跃（如 fanren → jindan）**: 执行 1 次 `unregister_by_source(old_realm_source)` + 1 次 register（注册 jindan 的 10 条 modifier，MULT 累计值 = 1.00）；炼气、筑基的 modifier 永不存在于 ModifierEngine 中。`realm.advanced` 的 `old_realm = "fanren"`，`new_realm = "jindan"`。
- **If 合体境（最高境界，realm_id=6）玩家继续升级至 level 超过 200（配置最大值）**: level 停在 200，`amount_remaining` 全量退回 ResourceSystem.exp，不发 `realm.advanced`（已在最高境界）。`level.changed` 不发布（`levels_gained == 0`）。
- **If `reset(entity_id, "breakthrough")` 将 level 归 1（降回凡人境）**: 执行 `unregister_by_source(当前境界 source)` → level = 1，realm = "fanren"，current_realm_id = 0 → `_recalculate_attributes` 写入 Lv.1 属性 base → 发 `level.changed(new_level=1, levels_gained=-(old_level-1))` + `realm.advanced(new_realm="fanren")`。凡人境无 modifier 需注册。

### 类别 C：modifier 重建（save.loaded）路径

- **If `save.loaded` 事件在 `ResourceSystem.restore` 或 `AttributeSystem.restore` 完成之前触发**: 本系统 `_on_save_loaded` 仅操作 ModifierEngine（注册 realm modifier），不读取 ResourceSystem 或 AttributeSystem 数据，因此无顺序竞争风险。AttributeSystem 的 base 值在 `restore()` 阶段独立写入，不依赖 `save.loaded` 时机。
- **If `save.loaded` 被意外发布多次（如热重载或 debug 工具重复触发）**: `_on_save_loaded` 对每个 entity 先调用 `_swap_realm_modifiers(entity_id, "", entry.realm)`，其内部先执行 `unregister_by_source` 清理旧 modifier 再重新 register。幂等——重复调用结果相同，不产生重复 modifier。
- **If 玩家在 `_on_save_loaded` 执行期间（理论上同步帧内）触发 `gain_exp`**: GDScript 单线程，`_on_save_loaded` 作为信号回调执行完毕后才处理下一条信号。`gain_exp` 不会插入 `_on_save_loaded` 执行中段，无竞态风险。

### 类别 D：公式异常路径

- **If `FormulaEngine.evaluate("level_exp", ...)` 因公式未注册或语法错误返回 `0.0`**: `threshold_bn = BigNumber.ZERO`，`amount_remaining.less_than(ZERO)` 始终 false，循环每次都视为"可升级"——立即触发 MAX_LEVELS_PER_GAIN=100 截断保护。`amount_remaining` 退回，打印 warn。level 最多连升 100 级。这是 §Detailed Design 规则 10 "No-Op 安全降级"明确列出的行为。
- **If `FormulaEngine.evaluate("{attr_id}_growth", ...)` 返回负数（公式配置错误）**: `BigNumber.from_float(负数)` 产生负值 BigNumber；`AttributeSystem.set_base` 接收负值。`set_base` 的下界保护（attribute-system.md §Edge Cases）将其钳位至属性允许的最小值（如 hp_max ≥ 1）。本系统不二次钳位——职责在 AttributeSystem。
- **If `FormulaEngine.evaluate` 返回 `float('nan')` 或 `float('inf')`**: `BigNumber.from_float(NaN/Inf)` 由 BigNumber 层归一化为 `BigNumber.ZERO` 或 `BigNumber.MAX`（依 BigNumber GDD 约定）。结果等同上一条（ZERO）或立即触发截断（MAX）。本系统不额外处理——职责委托 BigNumber 层。
- **If `crit_rate_growth` 公式在极端参数下输出超过 1.0（如配置数值意外放大）**: `clamp(..., 0.0, 1.0)` 在公式表达式内直接拦截，`set_base` 写入值始终 ≤ 1.0。ModifierEngine 叠加后 `get_final` 结果可能超过 1.0——该上界钳位由战斗计算器在使用时负责，不在本系统处理。

### 类别 E：存档/读档路径

- **If 存档 `snapshot` 中含有当前 `_entries` 未注册的 `entity_id`（旧存档数据冗余）**: `restore` 跳过未知 entity_id，记录 warn `[WARN] restore: unknown entity_id={id}, skipped`。不崩溃，不自动 register——调用方负责 register 后再 restore。
- **If 存档中某 entity 的 `realm` 字段值不在当前 `_realm_table` 中（旧存档 realm 已被重命名或删除）**: `_on_save_loaded` 中 `_swap_realm_modifiers(entity_id, "", entry.realm)` 因 `_realm_table[entry.realm]` 不存在而跳过 register，记录 warn。`entry.realm` 保留原值（待版本迁移工具修正）；实体以无 realm modifier 状态运行，不崩溃。
- **If 存档中 `level` 与 `realm` 字段不一致（如 level=5 但 realm="jindan"，来自旧版本阈值表错位）**: `restore` 原样写入 `_entries`。`_on_save_loaded` 调用 `_derive_realm(entry.level)` 重新派生正确 realm，覆盖存档中的错误 realm 字段，并以正确 realm 注册 modifier。实际运行状态以当前阈值表为准，不以存档 realm 字符串为准。
- **If 存档数据中 `current_realm_id` 字段缺失（旧版本存档无此字段）**: `restore` 在写入 `_entries` 时若字段不存在则默认 `current_realm_id = 0`；`_on_save_loaded` 执行 `_derive_realm` 重新派生并更新该字段。不依赖存档中的 realm_id 缓存值。
- **If BigNumber 序列化的 exp 余量在 30 天极端累积后（约 2.59e8）触及精度边界**: BigNumber 存档格式（`to_dict`）使用字符串或高精度分量存储，不依赖 float 精度。`from_dict` 恢复后精度损失 ≤ BigNumber GDD 声明的 ULP 误差。若恢复后 exp 余量偏差导致升级判定差一级，参照类别 A 第 7 条处理：多余量退回，下次 tick 消化。

### 类别 F：跨系统协作路径

- **If `AttributeSystem.set_base(entity_id, attr_id, value)` 因 entity 未在 AttributeSystem 注册而失败**: `set_base` 按 AttributeSystem §Edge Cases 约定打印 warn 并静默返回。本系统不重试——LevelSystem 与 AttributeSystem 的实体注册需调用方在 `register_entity` 时保证同步完成（参见 §Acceptance Criteria）。
- **If `entity_id` 已调用 `unregister_entity` 后，外部代码仍调用 `gain_exp(entity_id, amount)`**: `has_entity` 返回 false，打印 warn，返回 0。ResourceSystem.exp 不被 spend，不发事件。
- **If `EventBus` 的 `level.changed` 下游订阅者在回调中调用 `gain_exp`（递归注入）**: GDScript 信号同步回调——`gain_exp` 会被递归执行，但此时外层 `gain_exp` 的升级循环已退出（`levels_gained` 已写入），递归调用是独立的新次调用，不破坏外层状态。递归深度由 MAX_LEVELS_PER_GAIN 截断保护隐性限制。若产生无限 exp 注入循环，属调用方设计缺陷，应在 `level.changed` 订阅者中禁止再次调用 `gain_exp`——本系统不做递归守卫，但在调试文档中明确此约定。
- **If `reset(entity_id, scope)` 与并发（同帧信号回调中）`gain_exp` 同时触发**: GDScript 单线程——`reset` 与 `gain_exp` 不真正并发。若 `reset` 在信号回调中被触发，它在 `gain_exp` 完成后执行，结果是 reset 覆盖 gain_exp 的升级结果。若 `gain_exp` 在 `reset` 的 `level.changed` 回调中触发，属上一条递归情形。两种情形均不导致状态损坏。

### 类别 G：性能边界

- **If 同一帧内多次调用 `gain_exp`（如自动战斗批量结算 N 场战斗 exp）**: 每次调用独立执行完整升级流程；若第一次调用已触发 MAX_LEVELS_PER_GAIN 截断并退回余量，余量进入 ResourceSystem.exp，第二次调用从余量开始计算，不重复截断。调用方应合并 exp 后单次调用 `gain_exp` 以减少总耗时。
- **If `save.loaded` 时所有 entity 同时重建 modifier（Post-MVP 多弟子场景，N 实体）**: `_on_save_loaded` 对每个 entity 执行 1 次 `unregister_by_source` + 10 次 `register`。总耗时约 `N × 11 × modifier_op_time`。MVP 单 entity：~1.0 ms（§Formulas 9 境界切换项）。10 弟子：~10 ms，超出帧预算——Post-MVP 引入多弟子时应将 modifier 重建分散到多帧（每帧处理 1-2 个 entity），不在 MVP 范围内实现，此处仅标记风险。

## Dependencies

### 上游依赖

| 系统 | 依赖性质 | 数据接口 |
|------|---------|---------|
| **大数值系统** (BigNumber) | 硬依赖 | exp 阈值与属性成长结果均为 `BigNumber`；调 `from_float / to_dict / from_dict / less_than / greater_than / subtract` |
| **事件总线** (EventBus) | 硬依赖（双向） | 发布 `level.changed`、`realm.advanced`；订阅 `save.loaded` 触发 modifier 重建。唯一既发布又订阅 EventBus 的等级系统接口 |
| **公式引擎** (FormulaEngine) | 硬依赖 | `evaluate("level_exp", {level})` 算升级阈值；`evaluate("{attr_id}_growth", {level, realm_id})` × 6 算属性成长系数。公式必须经过 log_softcap |
| **资源系统** (ResourceSystem) | 硬依赖（spend）+ 软协作（add 退回） | `spend("exp", BigNumber)` 原子消费；MAX_LEVELS_PER_GAIN 截断时 `add("exp", remaining)` 退回 |
| **修正器/倍率引擎** (ModifierEngine) | 硬依赖 | `register({target, type:MULT, value, pool:"realm", source, duration:0})` × 10 + `unregister_by_source(source)`；source 命名 `"level_system.realm.{entity_id}.{realm}"` |
| **属性系统** (AttributeSystem) | 硬依赖 | `set_base(entity_id, attr_id, BigNumber)` × 6（每次升级全量重算）。本系统是 MVP 中 player 实体属性 base 的主要写入方 |
| **数据配置系统** | 硬依赖 | 启动时读取 `level_realm_config.json` + `attribute_growth_config.json`；公式 ID 必须事先在 FormulaEngine 注册 |

### 下游消费者

| 系统 | 调用方向 | 数据接口 | 备注 |
|------|---------|---------|------|
| **存档系统** | 主动调用 | 存档调 `snapshot()`；读档调 `restore()` + 完成后发布 `save.loaded` 事件 | snapshot 仅持久化 `{level, realm}`；ModifierEngine 状态由本系统在 save.loaded 后重建 |
| **调试控制台** | 只读查询 | `get_level / get_realm / get_realm_id / get_realm_progress / get_exp_to_next / get_all_entity_ids`；DEBUG_BUILD 下 `try_level_up` 写命令 | 与 attribute-system / resource-system 调试接口风格一致 |
| **自动战斗系统** (Post-MVP #22) | 主动调用 | `gain_exp("player", drop_exp)` 战斗结束时调用 | 唯一合法的 exp 来源 |
| **区域系统 / 地图推进系统** (Post-MVP #23 / #24) | 主动查询 | `get_level("player")` 检查区域门槛 | 不订阅事件；按需查询 |
| **HUD 系统** (Post-MVP #30) | 订阅 + 查询 | 订阅 `level.changed` / `realm.advanced`；调用 `get_level / get_realm / get_realm_progress` 查询面板数据 | UI 呈现完全由 HUD 决定 |
| **半自动战斗系统** (Post-MVP #22) | 间接关联 | 通过 `AttributeSystem.get_final("player", attr_id)` 获取受 realm modifier 加成的属性 | 不感知等级数值 |
| **自动产出系统** (Post-MVP #17) | 间接关联 | 通过 `realm` 池 modifier 自动反映在 `lingqi / xiuwei / lingshi / herb_production` 倍率中 | OMS 不感知等级 |
| **修炼系统** (Post-MVP #20) | 间接关联 | 不直接调本系统；可通过 buff 影响 exp 产出速率 | 修炼系统不直接干预 level |
| **境界突破系统** (Post-MVP #191) | 主动调用 | `reset(entity_id, scope)` 触发突破重置 | MVP 不主动触发；接口已就绪 |

### 关键非依赖（容易误以为是依赖但不是）

| 系统 | 关系 | 说明 |
|------|------|------|
| 状态机系统 | 无直接关联 | 本系统是 CRUD + 事件源，无业务状态机 |
| 随机数与种子系统 | 无直接关联 | 升级阈值与属性成长完全确定性；未来若加入"突破成功率"由突破系统持有 |
| ModifierEngine.modifier_expired 事件 | 无关联 | realm modifier 是永久（duration=0），不会过期；本系统不订阅 modifier_expired |
| 物品/材料系统 | 无关联 | 物品是离散资产，与等级成长无直接接口 |
| 战斗计算器 (#21) | 间接（仅通过 AttributeSystem） | 战斗计算器不感知 level 数值；只调 `get_final` 读已被 realm modifier 加成的属性 |

### 双向一致性自检

- ✅ **EventBus GDD** `level.changed` payload、`realm.advanced` 命名空间与等级系统发布关系已在 2026-05-04 同步。
- ✅ **AttributeSystem GDD** 旧存档恢复事件名已在 2026-05-04 修订为 `save.loaded` 订阅语义。
- ✅ **AttributeSystem GDD** §Tuning Knobs 关于"属性如何随时间增长"的委托声明与本 GDD 一致
- ✅ **ResourceSystem GDD** §Detailed Design 中 exp 资源 `reset_scope=breakthrough` 与本系统 `reset` 接口一致
- ✅ **ModifierEngine GDD** §Interactions 行 125 已列出"等级系统 — 等级变化时注册/注销境界/等级修正"
- ✅ **FormulaEngine GDD** §Interactions 行 122-123 已列出本系统的 `level_exp` + `{attr_id}_growth` 调用契约

## Tuning Knobs

### 配置驱动参数（per-realm，由数值设计师调整）

| 参数 | 类型 | 默认值 | 安全范围 | 调整影响 |
|------|------|--------|---------|---------|
| `realm.id` | int | 必填，唯一 | [0, 6] (MVP) | 境界序号；新增境界需追加配置 + 同步 attribute_growth 公式中的 realm_id 范围 |
| `realm.name` | String | 必填，唯一 | snake_case | 境界字符串标识（`fanren / lianqi / zhuji / jindan / yuanying / huashen / heti`）；HUD 通过此字段查境界中文名 |
| `realm.start_level` | int | 见 §Detailed Design 规则 3 | [1, 200] | 进入该境界的最低 level；表必须按升序排列 |
| `realm.mult_value` | float | 见 §Formulas 8 累计列 | [0.0, 10.0] | 注册到 `realm` 池的 MULT 累计值；越大跨境界跃升感越强但可能数值爆炸 |

### 配置驱动参数（per-attribute，由数值设计师调整）

| 参数 | 类型 | 默认值 | 安全范围 | 调整影响 |
|------|------|--------|---------|---------|
| `attr_growth.formula_id` | String | 必填 | FormulaEngine 已注册的公式 ID | 链接到 `level_exp / hp_max_growth / atk_growth / ...` 等 |
| `attr_growth.softcap_threshold` | float | 见 §Formulas 2-7 各属性 | per-attr 推荐范围 | log_softcap 阈值；过早触发 → 末期成长太平、过晚 → 中期数值过大 |
| `attr_growth.realm_factor` | float | 见 §Formulas 2-7 系数 | [0.0, 0.30] | 境界对该属性 base 的额外加成乘数（与 ModifierEngine `realm` 池叠加，不重复计数） |

### 引擎/调试参数（全局，开发期或编译期常量）

| 参数 | 默认值 | 安全范围 | 增大影响 | 减小影响 |
|------|--------|---------|---------|---------|
| `MAX_LEVELS_PER_GAIN` | 100 | [10, 500] | 单次 gain_exp 允许更多连跳，离线返回更顺滑；最坏帧耗时增加 | 更严格防御异常 exp 注入；离线大量 exp 退回次数增多 |
| `EXP_BASE` | 10.0 | [1.0, 100.0] | 全局升级 exp 阈值上调，节奏放缓 | 升级更频繁，前期体验更"爽" |
| `EXP_GROWTH` | 1.038 | [1.020, 1.080] | 后期升级阈值膨胀更快，长线挂机时间拉长 | 后期成长更快，可能加速触碰 200 级上限 |
| `EXP_SOFTCAP_LV` | 80 | [60, 120] | softcap 启动更晚，高等级 exp 需求继续暴涨 | softcap 启动更早，高级压制更强 |
| `EXP_SOFTCAP_POW` | 0.55 | [0.30, 0.80] | softcap 后增速更接近线性，高级体验更接近平段 | 高级压制更狠 |
| `LEVEL_BUDGET_RATIO` | 0.02 | [0.01, 0.05] | 等级系统获得更多帧预算 | 更严格性能限制 |
| `WARN_ON_MAX_LEVELS_TRUNCATE` | true | {true, false} | 截断时打印警告辅助调试 | 静默退回（生产构建可关闭） |
| `WARN_ON_FORMULA_FAILURE` | true | {true, false} | 公式求值失败时打印警告 | 静默使用 0.0 默认值 |
| `SUPPRESS_RESTORE_EVENTS` | true | {true, false} | restore 期间抑制 level.changed / realm.advanced 事件 | 关闭后 restore 期间事件正常发布（仅调试） |

### MAX_LEVELS_PER_GAIN 设计意图（CD-GDD-ALIGN C2 修订）

**MAX_LEVELS_PER_GAIN 在 MVP 设为 100 是性能保守值，不是体验上限。** §Formulas 9 已验证最坏路径（连升 100 级跨 1 境界）耗时 2.278 ms 超出帧预算约 6.8×，但作为"离线回归首帧"罕见事件可接受。

Post-MVP 应监测以下两类场景并相应上调：① economy-designer 调参后离线 30 天 exp 跨度 > 100 级常态化；② 玩家社区反馈"明明攒了 5 个境界的 exp 结果只跨了 100 级被截断"。原则是**性能阈值不应反过来惩罚 pillar 4.1 的"一次回归看见一次完整跃迁"承诺**——若上调上限会触发帧 spike，应改为"分帧批处理但视觉上仍呈现为一次性结算"（HUD 配合），而非保留低 100 上限切碎多帧。

### 设计师 vs 开发者调参边界

- **配置驱动参数**通过 `level_realm_config.json` + `attribute_growth_config.json` 修改，由**数值设计师**调整。新增境界 / 调整阈值表 / 重写成长公式只需追加配置（重启生效）
- **引擎/调试参数**是项目级常量或开发模式开关，由**开发者**在实现阶段设定，运行时不应动态修改
- **境界增量值与 attr_growth 公式系数**虽属配置驱动，但其经济节奏由 economy-designer + 数值设计师在 sign-off 后固化；本 GDD 仅承诺"接受配置注入的值"

### 与依赖系统的调参分工

| 调参对象 | 负责系统 | 说明 |
|---------|---------|------|
| 6 项 attribute 的 schema 范围 | 属性系统 | attribute-system.md 锁定上下限；本系统的 attr_growth 公式必须遵守 |
| 6 项 attribute 的成长曲线 | 等级系统 + FormulaEngine | 本系统持有公式 ID，FormulaEngine 持有公式表达式 |
| 装备 / 技能 / Buff 对属性的修正 | 装备系统 / 技能系统 / Buff 系统 + ModifierEngine | 本系统不持有这些 modifier；它们与 realm modifier 在 ModifierEngine 中独立累加 |
| exp 资源的来源速率 | 自动战斗系统 / 区域系统 (Post-MVP) | 本系统只消费 exp，不持有产出参数 |
| 境界突破触发条件 | 境界突破系统 (Post-MVP #191) | 本系统只接受 `reset(entity_id, scope)` 调用；不判断触发时机 |

## Visual/Audio Requirements

本系统**无视觉/音频需求**。等级系统是数据基础设施层（Feature 层中介），所有玩家可见的等级表现——等级条进度、升级浮空数字、属性面板跳动、境界跃迁特效（如"修为入炼气境"动画）、境界突破闪光、realm 倍率小标变化——均由 **HUD 系统**承载，本系统仅通过 `level.changed` 与 `realm.advanced` 事件向其推送变更通知。视觉与音频规格由 HUD 系统 GDD（#30，未设计）、UI 框架 GDD（#29，未设计）定义。

参见 §Player Fantasy 的"重要边界声明"段落。

## UI Requirements

本系统**无 UI 需求**。等级条、境界标签、属性面板"修为入境"提示、道行长卷（境界进度可视化）、突破弹窗等所有 UI 元素由 **HUD 系统**与 **UI 框架**承载，本系统仅提供 `get_level / get_realm / get_realm_id / get_realm_progress / get_exp_to_next / get_progress_ratio` 等数据查询 API 供其消费。UI 布局、交互流程、信息密度由 UI 框架 GDD（#29，未设计）和 HUD 系统 GDD（#30，未设计）定义。

参见 §Player Fantasy 的"重要边界声明"段落。

## Acceptance Criteria

> qa-lead 独立验证延后到 fresh session 中运行 `/design-review design/gdd/level-system.md`（per skill 推荐——验证 agent 必须在独立 session 才能客观审查）。

### 实体生命周期

- **GIVEN** `LevelSystem` 已加载，`level_realm_config.json` 含 7 境界，**WHEN** `register_entity("player")`，**THEN** 返回 `true`，`get_level == 1`，`get_realm == "fanren"`，`get_realm_id == 0`
- **GIVEN** `"player"` 已注册，**WHEN** 再次 `register_entity("player")`，**THEN** 返回 `false`，已有条目不变，打印警告
- **GIVEN** `"player"` Lv.30 (zhuji)，已注册 10 条 realm modifier，**WHEN** `unregister_entity("player")`，**THEN** 返回 10，`has_entity == false`，ModifierEngine 中 source `"level_system.realm.player.zhuji"` 全消失
- **GIVEN** `unregister_entity("never_registered")`，**WHEN** 调用，**THEN** 返回 0，不崩溃，不打印警告

### gain_exp 主路径

- **GIVEN** Lv.1，ResourceSystem.exp=100，**WHEN** `gain_exp(BN(100))`，**THEN** spend 成功消 100；while 升 3 级（10+21+33≈64 exp）后 amount_remaining=36 退回 ResourceSystem.exp；最终 level=4，exp=36，发 1 条 `level.changed{old=1, new=4, levels_gained=3}`，**不**发 realm.advanced
- **GIVEN** Lv.1，exp=5，**WHEN** `gain_exp(BN(100))`，**THEN** ResourceSystem.spend(100) 返回 false（余额不足），gain_exp 返回 0，level 不变，exp 仍 5，不发事件
- **GIVEN** Lv.1，**WHEN** `gain_exp(BN.ZERO)`，**THEN** 直接返回 0，不调 spend，不发事件
- **GIVEN** `"ghost"` 未注册，**WHEN** `gain_exp("ghost", ...)`，**THEN** 返回 0，警告，ResourceSystem.exp 不变
- **GIVEN** Lv.1，exp=1e18，**WHEN** `gain_exp(BN.from_string("1e18"))`，**THEN** 返回 100（MAX_LEVELS_PER_GAIN 截断），amount_remaining 全量退回，警告打印

### 境界跨越 + modifier

- **GIVEN** Lv.9 (fanren)，**WHEN** gain_exp 升至 Lv.10，**THEN** `get_realm == "lianqi"`，`get_realm_id == 1`，ModifierEngine 注册 10 条 source=`"level_system.realm.player.lianqi"` 的 modifier（4 OMS + 6 attribute），每条 value=0.20，发 `realm.advanced{old="fanren", new="lianqi"}`
- **GIVEN** Lv.9 (fanren)，**WHEN** gain_exp 一次性跨 fanren → lianqi → zhuji 升至 Lv.31，**THEN** ModifierEngine 中**只有 1 个 source**（`"level_system.realm.player.zhuji"`，value=0.50）的 10 条 modifier；fanren / lianqi 的 source 永不出现；`realm.advanced` 仅发 1 条 (old="fanren", new="zhuji")
- **GIVEN** Lv.30 (zhuji)，**WHEN** `ModifierEngine.get_multiplier("player.atk")`，**THEN** 返回 1.50（= 1.0 + 0.50 累计 MULT）

### save.loaded 重建

- **GIVEN** snapshot 数据 `{entities: {"player": {level:30, realm:"zhuji"}}}`，**WHEN** `restore(snapshot)`，**THEN** `_entries` 写入完成；ModifierEngine `realm` 池**无** modifier（重建延后到 save.loaded）
- **GIVEN** restore 完成且 `save.loaded` 事件发布，**WHEN** `_on_save_loaded` 触发，**THEN** ModifierEngine 注册 zhuji 的 10 条 modifier，**不**发布 `level.changed` 或 `realm.advanced`
- **GIVEN** `save.loaded` 事件被发布两次（异常情形），**WHEN** `_on_save_loaded` 第二次触发，**THEN** `_swap_realm_modifiers` 内部先 `unregister_by_source` 再 register；最终 ModifierEngine 中只有 1 套 zhuji 的 10 条 modifier（幂等）
- **GIVEN** snapshot 含 entity `"player"` 的 `realm = "unknown_realm"`（已被重命名或删除），**WHEN** `_on_save_loaded`，**THEN** 跳过 register，打印警告，entity 以无 realm modifier 状态运行
- **GIVEN** snapshot 含 `level=5, realm="jindan"`（不一致），**WHEN** `_on_save_loaded`，**THEN** 调 `_derive_realm(5)` 派生为 "fanren"，覆盖存档 realm 字段，按 fanren 处理（不注册 modifier）

### reset 接口

- **GIVEN** Lv.30 (zhuji)，**WHEN** `reset("player", "breakthrough")`，**THEN** level=1, realm="fanren", current_realm_id=0；10 条 zhuji modifier 全部 unregister；属性 base 重置至 Lv.1 默认；发 `level.changed{new_level=1, levels_gained=-29}` + `realm.advanced{new_realm="fanren"}`
- **GIVEN** 任意状态，**WHEN** `reset("player", "none")`，**THEN** 不发任何事件，level / realm 不变（与 ResourceSystem.reset_by_scope("none") 行为一致）

### 公式求值

- **GIVEN** FormulaEngine 已注册 `level_exp` 公式（默认参数），**WHEN** `evaluate("level_exp", {"level": 1})`，**THEN** 结果 ≈ 10.4（误差 ±5%）
- **GIVEN** FormulaEngine 已注册 `level_exp`，**WHEN** `evaluate("level_exp", {"level": 99})`，**THEN** 结果 ≈ 2.4M（误差 ±20%）
- **GIVEN** FormulaEngine 已注册 `hp_max_growth`，**WHEN** `evaluate({"level":1, "realm_id":0})`，**THEN** 结果 ≈ 100
- **GIVEN** FormulaEngine 已注册 `hp_max_growth`，**WHEN** `evaluate({"level":200, "realm_id":6})`，**THEN** 结果 ∈ [1e5, 1.5e5]（log_softcap 后）
- **GIVEN** FormulaEngine 已注册 `crit_rate_growth`，**WHEN** `evaluate({"level":200, "realm_id":6})`，**THEN** 结果 ∈ [0.30, 0.45]，**严格 ≤ 1.0**

### 公式异常 / 边界

- **GIVEN** FormulaEngine 中 `level_exp` 公式未注册（缺失），**WHEN** `gain_exp("player", BN(1000))`，**THEN** evaluate 返回 0.0 → 触发 MAX_LEVELS_PER_GAIN 截断保护，返回 100，`amount_remaining` 退回，打印警告
- **GIVEN** Lv.200（合体境上限），**WHEN** `gain_exp("player", BN(1e8))`，**THEN** 返回 0，level 仍 200，全部 amount 退回，不发事件

### 跨系统集成

- **GIVEN** Lv.1，AttributeSystem 已注册 player 实体，**WHEN** gain_exp 升至 Lv.10，**THEN** `AttributeSystem.get_base("player", "atk")` 返回 `BigNumber(atk_growth(10, 1))` 的值
- **GIVEN** Lv.30 (zhuji)，**WHEN** `AttributeSystem.get_final("player", "atk")` 调用，**THEN** 返回 `base × 1.5`（realm 池倍率自动叠加）
- **GIVEN** Lv.10 (lianqi)，**WHEN** `OMS.get_production_rate("lingqi")` 调用，**THEN** 返回值含 ModifierEngine `realm` 池的 ×1.20 倍率

### 性能 / 内存

- **GIVEN** Lv.10，**WHEN** 单次 `gain_exp` 升 1 级（不跨境界），**THEN** 总耗时 < 0.333 ms（帧预算）
- **GIVEN** Lv.1 连升 100 级跨 1 境界（最坏路径），**WHEN** 单次 `gain_exp`，**THEN** 总耗时 < 3.0 ms（接受单帧超支）
- **GIVEN** Lv.30 jindan，**WHEN** 内存采样，**THEN** `_entries["player"]` < 200 bytes；ModifierEngine 中 realm modifier 共 10 条 ≈ 1.2 KB
- **GIVEN** 1000 次连续 `get_level("player")` 查询，**WHEN** 完成，**THEN** 平均单次 < 0.005 ms

## Open Questions

| Question | Owner | Deadline | Resolution |
|----------|-------|----------|-----------|
| EventBus GDD 曾使用旧版 `level.changed` payload；本 GDD 需要 `{entity_id, old_level, new_level, levels_gained}` | 设计师 | `/consistency-check` 阶段 | ✅ 已解决 2026-05-04 — event-bus.md 已同步为 `{entity_id, old_level, new_level, levels_gained}` |
| EventBus GDD §Core Rules 11 命名空间约定中**未列出** `realm.advanced` 事件——需在 `/consistency-check` 阶段追加 `realm.advanced` 命名空间 + 在 §Interactions 表追加等级系统发布 `realm.advanced` 行 | 设计师 | `/consistency-check` 阶段 | ✅ 已解决 2026-05-04 — event-bus.md 已追加 `realm.advanced` 与等级系统发布关系 |
| AttributeSystem GDD §Edge Cases 曾使用旧存档恢复事件名；实际 save-system.md 使用 `save.loaded` | 设计师 | `/consistency-check` 阶段 | ✅ 已解决 2026-05-04 — attribute-system.md 已改为订阅 `save.loaded` 后整体刷新 |
| `level_exp` 公式参数（EXP_BASE / EXP_GROWTH / EXP_SOFTCAP_LV / EXP_SOFTCAP_POW）的最终值由 economy-designer + 数值设计师 sign-off 后固化在 §Tuning Knobs。当前公式在 L30 偏差 -24%，L99 实际节奏 ~6 小时（早期目标 ~3 天）——MVP 多日体验由 Lv.100-200 多级累加提供 | 数值设计师 | 实施阶段前 | — |
| 7 项 attribute 的 attr_growth 公式参数（base / pow / realm_factor / softcap_threshold）的最终值由 economy-designer + 数值设计师 sign-off 后固化。当前 crit_rate 在 Lv.200 合体境裸值约 37%，剩余至 100% 由装备/天赋/buff 通过 ModifierEngine 叠加补满 | 数值设计师 | 实施阶段前 | — |
| `level_realm_config.json` 与 `attribute_growth_config.json` 的具体文件位置（`assets/data/` 下何处？）和格式版本号约定，依赖于数据配置系统 GDD | 开发者 | 数据配置系统 GDD 完善时 | — |
| Post-MVP 多角色（弟子）独立等级时，`save.loaded` 触发 N 实体同时重建 modifier 的总耗时（10 弟子 ≈ 10 ms）超出帧预算——是否需要在本系统引入"分帧重建"机制（每帧处理 1-2 个 entity，剩余 `call_deferred`）？取决于 Post-MVP 多角色 GDD 时的实际并发规模 | 设计师 | Post-MVP 多角色系统 GDD 时 | — |
| MAX_LEVELS_PER_GAIN = 100 的最坏帧耗时 2.278 ms 超出帧预算 0.333 ms 约 6.8×。是否需要在 Post-MVP 引入"批量升级分帧"以避免离线长时间返回的首次 tick 单帧 spike？当前接受单帧超支（参考 attribute-system / resource-system 同等约定） | 技术总监 | Post-MVP 性能评估时 | — |
| ModifierEngine 缺 `modifier_added` / `modifier_removed` 事件——若 Post-MVP 在等级系统/属性系统加缓存层，需推动 ModifierEngine 补充增减事件支持正确缓存失效。Open Questions 已在 ModifierEngine GDD 中提出 | 技术总监 | Post-MVP 性能评估时 | — |
| `realm.advanced` 在境界**降级**（Post-MVP 突破失败 / 反向重置）时是否需反向触发？当前 `reset()` 接口已发布 `realm.advanced{old_realm=A, new_realm="fanren"}`——这是正确语义还是需要新增 `realm.regressed` 事件？取决于 HUD GDD 对降级动效的需求 | 设计师 | HUD 系统 GDD 时 | — |
| 单 realm modifier value 注册到 4 OMS production target 是否会与未来"区域产出乘数"（zone 池）产生设计冲突？例如新手村区域降低 lingqi 产出 -50%（zone 池），此时合体境 ×6.0（realm 池）与新手村 ×0.5（zone 池）累乘的结果是否符合"高境界玩家不应被低级区域显著拖累"的预期？取决于区域系统 GDD | 设计师 | 区域系统 (#23) GDD 时 | — |
| Post-MVP 突破系统 (#191) 引入"突破失败导致境界停留"机制时，需要本系统提供哪种新接口？例如 `force_set_realm(entity_id, realm)` 跳过 level 阈值映射？当前接口已通过 `reset` 支持降级，但不支持任意 realm 设置 | 设计师 | 境界突破系统 GDD 时 | — |
| qa-lead 对本 GDD §Acceptance Criteria 的独立验证（覆盖率审查、可测性审查、缺失场景检查）应在 fresh session 中通过 `/design-review design/gdd/level-system.md` 执行 | QA Lead | GDD 完成后立即 | 待 fresh session 执行 |
| **CD-GDD-ALIGN C3 修订**：化神/合体境内部级间属性增长在中后期（Lv.150-200）几乎为 0（attr_growth 全部经过 log_softcap 后压平）——这与 §Player Fantasy 主张的"平段持续涨"承诺存在张力。境界**之间**的跃迁感由境界 modifier 倍率（×1.20 → ×6.00）保证，但境界**内部**最长挂机段的"平段刻度填满"体感是否被削弱？需 economy-designer 在 sign-off 阶段实测 Lv.150-200 段每级 hp_max / atk 的可观测增量，决定是否调整 attr_growth 公式 softcap 阈值或在 HUD 后端化属性条 / 强化境界进度长卷 | economy-designer + UX | sign-off 阶段 | — |
