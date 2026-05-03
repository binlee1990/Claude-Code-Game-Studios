# 属性系统 (Attribute System)

> **Status**: Designed
> **Author**: binlee1990 + agents
> **Last Updated**: 2026-05-03
> **Implements Pillar**: 4.1 数字增长就是快乐 · 4.10 数据驱动与可扩展
> **Creative Director Review (CD-GDD-ALIGN)**: APPROVED 2026-05-03

> **Quick reference** — Layer: `Core Gameplay` · Priority: `MVP` · Key deps: `BigNumber, FormulaEngine, ModifierEngine, EventBus, DataConfig`

## Overview

属性系统是游戏中所有实体（主角、弟子、敌人、Boss）数值面板的统一存储、整合与变更通知服务。游戏世界的每一个会"打人"或"被打"的对象——它的生命、攻击、防御、速度、暴击率/暴击伤害、命中、闪避、韧性、神识、气运、因果——都以"实体 ID × 属性 ID → BigNumber 数值"的二维映射形式存放在这里。它不计算属性成长公式（由公式引擎负责）、不管理装备/技能/Buff 的叠加顺序（由修正器/倍率引擎负责）、不决定"升级时该加多少攻击"（由等级系统决定）；它只回答四个问题：**这个实体的某个属性基础值是多少？最终值（含所有修正）是多少？我帮你改完了基础值，谁需要被通知？哪些属性是这个实体需要展示的？**

每条属性条目除基础值外，还可声明"是否派生"——派生属性的最终值由修正器引擎在查询时实时整合（不缓存，避免脏数据）。**最终值查询**是属性系统的核心 API——调用方传入实体 ID 和属性 ID，本系统拉取基础值、向修正器引擎请求叠加该实体的相关修正、返回最终 BigNumber。基础值变化时通过事件总线发布 `attribute.{entity_id}.{attr_id}.base_changed`，下游 HUD 面板、战斗计算器缓存、UI 评分系统订阅这些事件刷新显示。属性 ID 是字符串常量（如 `hp/atk/def/spd/crit_rate/crit_dmg/...`），属性集通过数据配置系统按"实体类别 → 属性集合"声明（主角/弟子/敌人 可拥有不同的属性子集，如敌人不需要"神识"或"因果"）。

属性系统**不是**业务系统——它不知道"剑修攻击成长比体修高"（那是职业系统 + 公式引擎），也不知道"穿了破军剑 +200 攻击"（那是装备系统注册到修正器引擎的修正器）。它是一个被动的数据库 + 整合查询器 + 事件源。这种边界划分延续 ResourceSystem 设定的 TD-SYSTEM-BOUNDARY 先例：当你想给属性系统加"自动按等级长属性"或"装备穿戴时改属性"时，停下——那是上层业务系统的责任，本系统只负责"它叫我改基础值，我就改；它叫我查最终值，我就调修正器引擎拼出来"。这一原则保证 11 项修仙属性的语义被严格隔离：本系统提供"一个干净的属性账本"，所有奇思妙想（神识对禁制的穿透、因果对掉落的影响、气运对暴击的隐形权重）都由各业务系统通过"改基础值 + 注册修正器"来兑现，不污染属性系统本身。

虽然玩家不直接调用属性系统的 API，但他们看到的每一份属性面板、每一次"装备升级后伤害真的提升了"、每一个 Build 评分的变化，都来自这一系统的整合查询。pillar **4.1 数字增长就是快乐**在这里得到落实——属性数字的可信、可对账、可解释，是后期"我堆暴击有用吗""神识值对禁制是否真起作用"等长期 Build 决策的基础。pillar **4.10 数据驱动与可扩展**也在此处兑现——新属性（如赛季新增的"道纹"或"业障"）只需在配置表追加，整合 + 事件发布机制自动生效，不改代码。作为 Core Gameplay 层基础服务，本 GDD 完成后，#15 等级系统、#18 敌人数据库、#20 战斗计算器、HUD 系统四个直接下游系统的设计依赖才能解锁。

## Player Fantasy

属性系统是修仙世界的天命册——每一项属性都是命数的一笔铭刻，每一次变化都被工整地记下、可被翻阅、可被追问"为何如此"。它本身无形，但角色的每一根筋骨、每一缕神识、每一分气运因果，都在这本天命册里以数字的形式被固定下来。玩家不直接翻阅这本册子（那是 HUD 系统的工作），但他们能感受到一份底层的承诺：**屏幕上跳出的每一个属性数字，都不是凭空冒出来的，都能被追问、被对账、被证明。**

**主锚定时刻**：玩家午休回来，把刚掉的一件六品神识法器拖到丹修弟子身上替换原装备。属性面板上"神识"瞬间从 2,840 跳到 4,120。玩家半信半疑——这是真涨了，还是显示作秀？长按属性条，弹出"溯源"小窗：`基础 800（金丹三转）+ 法器·凝神珠 +1,200 + 阵法·聚神 ×1.5 + 因果加成 ×1.05 = 4,120`。每一笔来源、每一次乘算、每一道修正都摊开。玩家点头："这件法器值得换。"——下一秒就把旧装备扔进了分解箱。决策不再是"看着差不多变强了"，而是"我看见了它强在哪里、为什么"。（注：本例中"神识""因果加成"均为 Post-MVP 示意属性，描述目标体验形态；MVP 6 属性版本下溯源链为 `基础 800 + 法器 +1,200 × 阵法 1.5 = 3,000`，机制完全成立。）

**次锚定时刻**：玩家把队伍调进东海秘境，长按一个"幽鬼护法"敌方单位，浮窗披露："韧性 8,500 / 闪避 12% / 神识 3,200 / 弱点：火"。玩家瞄一眼自己面板的"命中 18% / 火属性穿透 +50%"，心里默算："命中差点——但火穿透够了，三回合稳过。"敌人的属性与自己的属性都被同一本天命册记录，披露的瞬间就是数字承诺：你看到的，就是战斗时真实生效的。这种"我之命数与彼之命数都是公平账本"的信赖感，让低频高价值决策（§4.2）有了铁打的对账依据——玩家不需要"试一试看运气"，而可以"算一算定结果"。

属性系统作为基础设施服务的核心是**信任 fantasy**：在一个跨越突破/飞升/轮回多个阶段、长达数百小时的放置游戏里，玩家对面板每一个数字的信赖是所有 Build 决策、装备替换、配队选择、突破规划的前提。如果属性数字会无故跳变、若有若无、来源不明，所有"我堆暴击有用吗""神识值真能穿禁制吗""气运真能拉暴击吗"等问题都会被噪声淹没，玩家很快会停止思考、回到无脑挂机。属性系统通过"基础值与最终值分离 + 任何修正都可追溯 + 任何变化都发事件"的机制，把"天命册般的确定性"作为修仙世界的底色——一种克制的可信，托住了 30 天后玩家面对屏幕上"神识 1.23e15"时仍然觉得"这一切是真的、是我经营出来的"。

**支柱对应**：
- **4.1 数字增长就是快乐**：属性数字的可信、可对账、可解释，让"装备升级 → 属性提升"的成长不被怀疑、不被噪声稀释；玩家相信增长是真的，于是继续投入。
- **4.2 放置不是无操作，而是低频高价值决策**：属性面板的溯源能力 + 敌人属性披露能力，把"配置队伍/设置战法/筛选装备"三类核心决策从"凭感觉"提升为"凭对账"——这是放置玩法深度的根。
- **4.10 数据驱动与可扩展**（次要）：属性 ID 通过配置表声明，新属性（如赛季新增的"道纹"或"业障"）只需追加配置自动接入溯源与事件链路，不污染现有逻辑。

**重要边界声明**：属性系统是上述支柱兑现的**必要基础设施**，而非支柱的直接载体——HUD 系统才是属性面板与"溯源"小窗的视觉呈现者，敌人数据库才是"披露敌方属性"的数据源，等级系统/装备系统/职业系统才是"基础值如何随时间增长"的剧本作者，修正器引擎才是"装备 +1200 / 阵法 ×1.5"叠加规则的实际执行者。本系统**只为它们提供可信赖的属性账本与最终值整合 API**。本节描述的"玩家锚定时刻"是属性系统作为基础设施被多个上层系统协同消费后所达成的整体体验，不应被理解为属性系统应主动包含面板渲染、敌人属性披露 UI 或装备穿戴动画等上层逻辑（参见 TD-SYSTEM-BOUNDARY 评审约束）。

## Detailed Design

### Core Rules

1. **架构形态**：`AttributeSystem` 为 `RefCounted` 服务类，由 Autoload 单例 `/root/AttributeSystem` 持有。对外暴露纯 CRUD + 整合查询 + 事件接口；不计算属性成长公式（由公式引擎负责）、不管理修正叠加（由修正器引擎负责）、不决定基础值如何随时间变化（由等级系统/装备系统/职业系统负责）。所有属性基础值存储为 `BigNumber`。

2. **存储索引模型**：中央托管，二维嵌套 Dictionary：
   ```
   _attributes: Dictionary[entity_id: String] → Dictionary[attr_id: String] → BigNumber (base value)
   ```
   - 外层 key：实体唯一 ID（如 `"player"`、`"disciple_001"`、`"enemy_yougui_a"`）
   - 内层 key：属性 ID 字符串常量（见规则 6）
   - 内层 value：基础值 BigNumber 实例
   - 同一 entity 不要求拥有所有属性——通过"实体类别 → 属性集合"配置决定（如敌人可能不持有 `crit_dmg` 也无大碍）

3. **属性条目数据模型**（每条 entity_id 关联一个 entity_meta 字典，与属性数据分离）：
   ```
   _meta: Dictionary[entity_id: String] → {
     "category": String,              # "player" | "disciple" | "enemy" | "boss"
     "attribute_set": String,         # 引用 attribute_set_config.json 中的 schema 名
     "registered_at": float           # 注册时间戳，调试用
   }
   ```
   `_meta` 与 `_attributes` 分离：`_meta` 通过 `register_entity()` 写入并锁定，`_attributes` 通过 `set_base()` 频繁更新。

4. **API 表面**（全部同步调用，无协程）：
   ```
   # 实体生命周期
   register_entity(entity_id: String, definition: Dictionary) → bool
   unregister_entity(entity_id: String) → int       # 返回被清理的属性条目数
   has_entity(entity_id: String) → bool
   get_all_entity_ids() → Array[String]

   # 单属性 CRUD
   set_base(entity_id, attr_id, value: BigNumber) → void
   get_base(entity_id, attr_id) → BigNumber          # 不存在返回 ZERO
   get_final(entity_id, attr_id) → BigNumber          # 调 ModifierEngine.apply 整合
   has_attribute(entity_id, attr_id) → bool

   # 批量
   set_base_batch(entity_id, changes: Dictionary) → void   # {attr_id: BigNumber}
   get_attribute_set(entity_id) → Dictionary               # {attr_id: base_value} 只读副本
   get_final_set(entity_id) → Dictionary                   # {attr_id: final_value} 只读副本

   # 集成辅助
   make_target(entity_id, attr_id) → StringName            # 返回预缓存的 ModifierEngine target

   # 存档
   snapshot() → Dictionary
   restore(data: Dictionary) → void
   ```
   所有 `entity_id` 不存在时：getter 返回 ZERO/false/[]/{}；setter 打印警告并 no-op；遵循 ResourceSystem 设立的"安全降级，不崩溃"先例。

5. **ModifierEngine 集成约定（跨系统命名约定）**：所有调用 `ModifierEngine.register/get_multiplier/apply` 的系统在涉及属性时，**必须**以 `"{entity_id}.{attr_id}"` 作为 ModifierEngine 的 `target` 字段。例如：
   - 装备系统注册：`ModifierEngine.register({target: "player.atk", type: ADD, value: 200, source: "equip_sword_001", ...})`
   - 属性系统查询：`ModifierEngine.apply("player.atk", base_atk)`
   - 装备卸下：`ModifierEngine.unregister_by_source("equip_sword_001")`

   属性系统提供 `make_target(entity_id, attr_id) → StringName` 作为约定的**唯一格式化入口**——所有上层系统应通过此方法生成 target，避免魔法字符串拼接。`StringName` 是驻留字符串（指针比较），适合作为 ModifierEngine 内部字典键的高频查询场景。

6. **MVP 属性集（6 项，由 `attribute_set_config.json` 注册）**：

   | attr_id | 中文 | 类别 | MVP 默认 base 范围 | 说明 |
   |---------|------|------|------------------|------|
   | `hp_max` | 生命上限 | offensive_passive | [10, 1e6] | 战斗存活判定；最大生命值 |
   | `atk` | 攻击 | offensive | [1, 1e6] | 伤害输出基础值 |
   | `def` | 防御 | defensive | [0, 1e6] | 伤害减免基础值 |
   | `spd` | 速度 | utility | [1, 1000] | 行动顺序/攻速 |
   | `crit_rate` | 暴击率 | offensive | [0.0, 1.0] | 概率值；本系统仍存为 BigNumber 以保持 schema 一致 |
   | `crit_dmg` | 暴击伤害 | offensive | [1.0, 100.0] | 暴击倍率 |

   砍掉的属性：`hit / dodge / tenacity / shenshi / qiyun / yinguo`——MVP 闭环不需要；新增属性仅需追加配置，不改代码。**不进 MVP 属性系统的字段**：`hp_current`（实时血量，建议由战斗计算器内部"战斗状态层"管理，与本系统的"基础值账本"语义不同——见 Open Questions）。

7. **事件发布规则**：基础值实际变化时发布 `attribute.{entity_id}.{attr_id}.base_changed`，payload：
   ```
   { "entity_id": String, "attr_id": String, "old_value": BigNumber, "new_value": BigNumber, "delta": BigNumber }
   ```
   - `delta = new_value - old_value`（可正可负）
   - delta=ZERO 时不发布（防 HUD 无效刷新）
   - `register_entity` 时初始化基础值**不发布**事件（视为初始化静态步骤）
   - `unregister_entity` 时**发布一条聚合事件** `attribute.{entity_id}.unregistered`（payload `{entity_id}`），HUD 可据此清理面板而不需要订阅每条属性的删除事件
   - **本系统不广播最终值变化事件**——最终值由 ModifierEngine 修正变化驱动，本系统不感知；订阅者若需感知最终值变化应同时订阅 `attribute.*.base_changed` 和（Post-MVP）ModifierEngine 修正变更事件后自行重算

8. **整合查询语义（get_final）**：
   ```
   get_final(entity_id, attr_id):
     base = get_base(entity_id, attr_id)         # 若不存在返回 ZERO
     target = make_target(entity_id, attr_id)
     return ModifierEngine.apply(target, base)   # 透传，不缓存
   ```
   属性系统**不缓存**最终值——ModifierEngine 自身已对每个 target 做 dirty-flag 缓存。如果属性系统再加一层缓存，需要订阅 ModifierEngine 修正变更事件才能正确失效，但 ModifierEngine GDD 当前只发 `modifier_expired` 不发普通增减事件——属性系统加缓存会有脏数据风险。透传策略让 ModifierEngine 单点负责缓存正确性。

9. **实体注册流程**（启动 + 运行时）：
   - **启动批量注册**（敌人数据库等模板）：通过数据配置系统读取 `attribute_set_config.json` 和 `entity_template.json`，调用 `register_entity(template_id, definition)`。**分帧执行**：每帧最多注册 50 实体（控制初始化开销，参见 §Formulas），剩余通过 `call_deferred` 推迟到下一帧
   - **运行时动态注册**（战斗中实例化的敌人）：调用方传入 `entity_id`（含战斗会话 UUID 后缀，如 `"enemy_yougui_a_session1234"`）和 `definition`，单次调用同步完成
   - 重复注册同一 ID：返回 `false`，已有条目不变（与 ResourceSystem 的 `register` 一致）

10. **序列化（存档快照）**：`snapshot()` 返回：
    ```
    {
      "version": 1,
      "entities": {
        entity_id: {
          "meta": { category, attribute_set },
          "attributes": { attr_id: BigNumber.to_dict() }
        }
      }
    }
    ```
    `restore(data)` 对每个 entity 顺序：① `register_entity(entity_id, meta)` ② 逐条 `set_base(entity_id, attr_id, value)`（不发事件——见规则 7）③ 完成后**不**对该 entity 发任何事件（HUD 应在 restore 完成后整体重绘）。restore 期间静默处理是为了避免 N 个实体 × M 个属性的事件风暴。**临时实体**（战斗中实例化的敌人，entity_id 含 session UUID）**不进存档**——存档系统应只调用 `snapshot()` 持久化主角/弟子等持久实体，过滤逻辑由调用方负责（`category in ["player", "disciple"]`）。

11. **输入校验（安全降级，不崩溃）**：
    - `entity_id` 不存在：getter 返回 ZERO/false/{}；setter 打印警告并 no-op
    - `attr_id` 不在该实体的 schema 内：setter 打印警告并 no-op；getter 返回 ZERO 不警告（防御性读）
    - `value` 是含 NaN/Inf 的 BigNumber：BigNumber 层归一化时已钳位为 ZERO，正常路径
    - `register_entity` 中 `definition.attribute_set` 引用未知 schema：拒绝注册，返回 false，打印警告
    - 重复注册同一 entity_id：返回 false，不覆盖
    - `make_target(entity_id, attr_id)` 任一为空字符串：返回空 StringName 并打印警告

12. **`set_base_batch` 非原子语义**：对每对 `{attr_id: value}` **顺序执行** `set_base()`，不回滚。某条 attr 校验失败不影响其他条目。理由：与 ResourceSystem.batch_add 的非原子先例一致；MVP 不需要原子性。

### States and Transitions

`AttributeSystem` 整体**无状态机**——纯 CRUD 服务。**实体条目**有显式生命周期：

```
[Unregistered] ──register_entity──→ [Active] ──unregister_entity──→ [Removed]
                                       ↑                                 ↓
                                       └────── re-register fails ────────┘
```

| 状态 | 判定 | 说明 |
|------|------|------|
| Unregistered | `has_entity(id) == false` | 所有 setter no-op；getter 返回 ZERO/false/{} |
| Active | `has_entity(id) == true` | 正常 CRUD；`set_base` 触发 `base_changed` 事件 |
| Removed | `has_entity(id) == false`（曾经 Active） | `unregister_entity` 已发 `attribute.{id}.unregistered` 事件；后续操作同 Unregistered |

单条**属性条目**无独立状态机——属性的存在性由 schema 决定，注册时一次性创建，运行时不动态增删（添加新属性只能改 schema 配置后重启）。

### Interactions with Other Systems

| 系统 | 方向 | 数据接口 | 说明 |
|------|------|---------|------|
| 大数值系统 | 上游依赖 | 所有 base 值存储为 `BigNumber`；调用 `to_dict/from_dict/equals/is_zero` | 无法脱离 BigNumber 独立工作 |
| 修正器/倍率引擎 | 上游依赖（仅 `get_final`） | `get_final` 内部调 `ModifierEngine.apply(target, base)` | 跨系统命名约定 `target = "{entity_id}.{attr_id}"`；ModifierEngine 不感知 entity 概念 |
| 事件总线 | 上游依赖 | `EventBus.emit("attribute.{entity_id}.{attr_id}.base_changed", payload)` 和 `attribute.{entity_id}.unregistered` | 只发布不订阅 |
| 数据配置系统 | 上游依赖 | 启动时读取 `attribute_set_config.json`（schema 定义）和 `entity_template.json`（敌人/弟子模板） | 配置驱动 |
| 公式引擎 | 无直接关联 | — | 属性系统**不**调 FormulaEngine。属性成长公式由调用方（等级系统、突破系统）使用 |
| 等级系统 | 下游 → 主动调用 | `set_base("player", "atk", new_atk)` 当玩家升级时 | 升级带来的 base 增长由等级系统计算 |
| 装备系统（Post-MVP） | 下游 → 间接 | 不调用本系统；通过 `ModifierEngine.register({target: "player.atk", ...})` 影响 `get_final` 结果 | 属性系统通过透传机制自动反映装备加成 |
| 敌人数据库 | 下游 → 主动调用 | 启动批量 `register_entity` 静态模板；战斗实例化时 `register_entity` 动态副本 | 模板 entity_id 与战斗实例 entity_id 不同（实例 ID 含会话 UUID） |
| 战斗计算器 | 下游 → 主动调用 | 高频 `get_final(entity_id, attr_id)` 读双方最终属性 | spd/atk/def/crit_rate/crit_dmg 等用于伤害和顺序判定 |
| 半自动战斗系统 | 下游 → 主动调用 | 战斗结束清理临时实体：`unregister_entity("enemy_*_session{N}")` 批量 | 防止战斗会话累积 |
| HUD 系统 | 下游 → 订阅 | 订阅 `attribute.player.{attr_id}.base_changed` 等精准事件 | 不轮询；不订阅敌人属性变更（性能控制） |
| 调试控制台 | 下游 → 只读查询 | `has_entity(id)` / `get_all_entity_ids()` / `get_attribute_set(id)` / `get_final_set(id)` | `attr` 命令查看实体 base/final 属性；不修改属性 |
| 存档系统 | 下游 → 主动调用 | `snapshot()`/`restore(data)`；调用方负责过滤临时实体 | 本系统提供数据快照，存档系统负责文件 I/O |
| 物品/材料系统 | 无直接关联 | — | 物品/材料是数值资产，不是属性 |
| 资源系统 | 无直接关联 | — | 资源系统管"全局玩家资产"，属性系统管"角色个体属性"；语义正交 |

## Formulas

### 1. 最终值整合 (Final Value Integration)

`final(entity_id, attr_id) = ModifierEngine.apply(make_target(entity_id, attr_id), base(entity_id, attr_id))`

**变量：**
| 变量 | 符号 | 类型 | 范围 | 说明 |
|------|------|------|------|------|
| entity_id | e | String | 全局唯一 | 实体 ID（如 `"player"`、`"disciple_001"`） |
| attr_id | a | String | schema 内 | 属性 ID（如 `"atk"`、`"hp_max"`） |
| base | b | BigNumber | [ZERO, MAX] | get_base 返回的基础值（不存在为 ZERO） |
| target | t | StringName | `"{e}.{a}"` | make_target 返回的 ModifierEngine 索引 |
| final | f | BigNumber | [ZERO, MAX] | 整合后的最终值 |

**输出范围：** `[ZERO, BigNumber.MAX]`。本系统**透传**给 ModifierEngine，其内部公式为 `(base + add_sum) × Π pool_mult`（详见 modifier-engine.md §Formulas 4）。属性系统不缓存结果。

**示例：** `entity="player", attr="atk", base=BigNumber(1000)`；ModifierEngine 已注册：装备 +200（pool=equipment）、阵法 ×0.5（pool=skill）→ `final = (1000+200) × 1.0 × 1.5 = 1800`

### 2. 单次 set_base 操作耗时 (Single set_base Cost)

`set_base_time = t_lookup_outer + t_lookup_inner + t_validate + t_compare + t_write + t_event`

**变量：**
| 变量 | 符号 | 类型 | 范围（ms） | 说明 |
|------|------|------|-----------|------|
| 外层字典查找 | t_lookup_outer | float | ~0.001 | `_attributes[entity_id]` |
| 内层字典查找/写入 | t_lookup_inner | float | ~0.001 | `_attributes[entity_id][attr_id]` |
| schema 校验 | t_validate | float | ~0.001 | 检查 attr_id 是否在该实体 schema 内 |
| 旧值比较 | t_compare | float | ~0.001 | `BigNumber.equals` 用于 delta 抑制 |
| 引用写入 | t_write | float | ~0.001 | Dictionary 赋值 |
| 事件发布 | t_event | float | [0, 0.026] | EventBus emit（delta=ZERO 时为 0；5 订阅者基准 ~0.026） |

**输出范围：** `[0.005, 0.031]` ms。最快路径：delta=ZERO 抑制事件 → 0.005 ms；典型路径：5 订阅者 → 0.031 ms。

**示例：** 主角升级触发 `set_base("player", "atk", new_atk)`，3 订阅者 → `0.001×5 + 0.026×3/5 ≈ 0.021 ms`

### 3. 单次 get_final 操作耗时 (Single get_final Cost)

`get_final_time = t_lookup_outer + t_lookup_inner + t_make_target + t_modifier_apply`

**变量：**
| 变量 | 符号 | 类型 | 范围（ms） | 说明 |
|------|------|------|-----------|------|
| 字典查找 ×2 | t_lookup_×2 | float | ~0.002 | 外层 + 内层 |
| make_target StringName | t_make_target | float | [0.0005, 0.002] | 缓存命中 ~0.0005；缓存未命中含拼接 ~0.002 |
| ModifierEngine.apply | t_modifier_apply | float | [0.005, 0.040] | 缓存命中 ~0.005（add_sum + final_mult + BigNumber 乘法）；缓存未命中重算 ~0.040 |

**输出范围：** `[0.0075, 0.044]` ms。**典型路径**（ModifierEngine 缓存命中 + StringName 缓存命中）：~0.008 ms。

**示例：** 战斗中查询 `get_final("enemy_yougui_a", "def")` → 0.008 ms

### 4. 批量初始化耗时与分帧策略 (Batch Init Cost & Frame Slicing)

`total_init_time = N_entity × M_attr × t_per_entry`

`frames_required = ceil(N_entity / batch_per_frame)`

`per_frame_cost = batch_per_frame × M_attr × t_per_entry`

**变量：**
| 变量 | 符号 | 类型 | 范围 | 说明 |
|------|------|------|------|------|
| 实体总数 | N_entity | int | [50, 500] | 静态模板 + 主角/弟子；MVP 上限 226 |
| 平均属性数 | M_attr | int | [4, 11] | MVP 平均 7（含 6 项 + meta） |
| 单条耗时 | t_per_entry | float | ~0.006 ms | BigNumber 实例化 + 嵌套 Dictionary 写入 |
| 分帧批次 | batch_per_frame | int | [20, 100] | 推荐 50 |

**输出范围：**
- 总耗时：`226 × 7 × 0.006 = 9.5 ms`（worst case 单帧执行会导致丢帧）
- 分帧策略：`50 实体/帧 × 7 属性 × 0.006 ms = 2.1 ms/帧`，5 帧完成
- 帧预算占比：每帧 ~12%，可接受

**示例：** 启动加载 200 敌人模板 + 26 主角弟子 → 5 帧完成（~83 ms 实时跨度），用户感知为"启动时一闪"

### 5. 战斗高频 get_final 帧内总开销 (Battle Frame get_final Total Cost)

`battle_frame_cost = N_query × get_final_time_avg`

**变量：**
| 变量 | 符号 | 类型 | 范围 | 说明 |
|------|------|------|------|------|
| 单帧查询次数 | N_query | int | [20, 200] | 1 主角 + N_enemy × M_attr 读取 |
| 单次耗时（典型） | get_final_time_avg | float | ~0.008 ms | 公式 3 缓存命中典型值 |

**输出范围：**
- MVP 典型战斗（1 主角 + 10 敌人 × 平均 5 属性 = 55 次/帧）：`55 × 0.008 = 0.44 ms`，占帧预算 ~2.6%
- 极端场景（200 次/帧）：`200 × 0.008 = 1.6 ms`，占帧预算 ~9.6%

**示例：** 战斗计算器同帧读取 5 个敌人的 spd/atk/def/crit_rate 共 20 次 → 0.16 ms

### 6. 单条属性条目内存占用 (Memory per Attribute Entry)

`per_attr_size = bn_instance + dict_entry_overhead`

**变量：**
| 变量 | 符号 | 类型 | 范围（bytes） | 说明 |
|------|------|------|-------------|------|
| BigNumber 实例 | bn_instance | int | ~40 | mantissa(float) + exponent(int) + 对象头 |
| Dictionary 条目开销 | dict_entry_overhead | int | ~24 | key(String) 引用 + 哈希桶元数据 |

**输出范围：** ~64 bytes/条（不随数值大小变化）

**示例：** MVP 6 属性 × 226 实体 = 1356 条 → 1356 × 64 = ~87 KB

### 7. 单实体内存占用 (Memory per Entity)

`per_entity_size = inner_dict_overhead + M_attr × per_attr_size + meta_dict_size + outer_entry_overhead`

**变量：**
| 变量 | 符号 | 类型 | 范围（bytes） | 说明 |
|------|------|------|-------------|------|
| 内层 Dict 对象头 | inner_dict_overhead | int | ~64 | GDScript Dictionary 对象基础开销 |
| 单属性条目 | per_attr_size | int | ~64 | 公式 6 |
| meta 字典 | meta_dict_size | int | ~80 | category + attribute_set + registered_at |
| 外层 Dict 条目开销 | outer_entry_overhead | int | ~24 | entity_id 字符串 key |

**输出范围：** MVP 6 属性实体 ~ `64 + 6×64 + 80 + 24 = ~552 bytes/实体`

**示例：** 单个主角实体 ~552 bytes；单个敌人模板 ~552 bytes（属性数相同）

### 8. 全局内存预算 (Global Memory Budget)

`global_memory = N_entity × per_entity_size + outer_dict_overhead + stringname_cache_size`

**变量：**
| 变量 | 符号 | 类型 | 范围（KB） | 说明 |
|------|------|------|-----------|------|
| 实体总数 | N_entity | int | [10, 500] | MVP 226 上限 |
| 单实体大小 | per_entity_size | int | ~0.55 KB | 公式 7 |
| 外层 Dict 对象头 | outer_dict_overhead | int | ~2 | GDScript Dictionary |
| StringName 缓存 | stringname_cache_size | int | [0, 40] | N_entity × M_attr × ~24 bytes |

**输出范围：**
- MVP 226 实体：`226 × 0.55 + 2 + 38 = ~165 KB`
- 扩展 500 实体：`500 × 0.55 + 2 + 84 = ~361 KB`

**边界：** 项目内存上限 512 MB；本系统 worst case 占比 ~0.07%。即使属性扩到 11 项，226 实体内存约 ~280 KB，远低于预算。

### 9. 属性系统帧预算分配 (Frame Budget Allocation)

`attribute_budget = t_frame × budget_ratio`

**变量：**
| 变量 | 符号 | 类型 | 范围 | 说明 |
|------|------|------|------|------|
| 单帧时间 | t_frame | float | 16.67 ms | 60 fps |
| 帧预算占比 | budget_ratio | float | [0.02, 0.06] | 属性系统帧时间占用比 |

**推荐值：** `budget_ratio = 0.04` → `attribute_budget = 0.667 ms/frame`

在此预算下的实际开销估算（典型战斗帧）：
- 50 次 get_final（公式 5 典型）：0.4 ms
- 5 次 set_base（受击/修炼/状态变化触发）：~0.155 ms
- 总计 ~0.56 ms，低于预算 0.667 ms

放置游戏中属性系统的实际调用频率约为：在线战斗 1 秒数十次 get_final + 数次 set_base；离线模拟批量按需查询；空闲时几乎为零。预算充裕。

## Edge Cases

### get_final 路径

- **If `entity_id` 不存在 (`has_entity == false`)**：返回 `BigNumber.ZERO`，**不**调 ModifierEngine.apply（避免对未注册 target 的无意义查询），**不**打印警告（防御性读，避免日志噪音）。
- **If `entity_id` 存在但 `attr_id` 不在该实体 schema 内**：返回 `BigNumber.ZERO`，不调 ModifierEngine.apply，不打印警告。理由同上——下游可能在不知道 attr 是否存在时探测性调用。
- **If `attr_id` 存在但 ModifierEngine 中无对应 target 注册的修正器**：透传 base 值，ModifierEngine.apply 返回 `(base + 0) × 1.0 = base`。这是正常路径，不应警告——大多数实体在游戏初期没有任何修正器。
- **If ModifierEngine.apply 整合后结果溢出 `BigNumber.MAX`**：BigNumber 饱和算术钳位为 MAX，正常返回。属性系统不额外检测——溢出语义由 BigNumber 层负责。
- **If `make_target(entity_id, attr_id)` 任一参数为空字符串**：返回 `BigNumber.ZERO` 并打印警告 `"get_final called with empty entity_id or attr_id"`。空 ID 必为调用方错误。

### set_base 路径

- **If 新值与旧值相等（delta = ZERO）**：写入仍执行（idempotent），但**不**发布 `attribute.{e}.{a}.base_changed` 事件（与 ResourceSystem.set_value delta 抑制规则一致，防 HUD 无效刷新）。
- **If `value` 是含 NaN/Inf 的 BigNumber**：BigNumber 层归一化时已钳位为 ZERO，命中"set_base 接收 ZERO"路径——若旧值非 ZERO，正常发布事件 delta=负值；若旧值已 ZERO，命中 delta=ZERO 抑制。
- **If `attr_id` 不在该实体 schema 内**：拒绝写入，打印警告 `"set_base: attr '{attr_id}' not in schema for entity '{entity_id}' (schema='{attribute_set}')"`。schema 违规必为业务逻辑错误。
- **If `entity_id` 不存在（实体未注册或已 unregister）**：拒绝写入，打印警告 `"set_base on unregistered entity '{entity_id}'"`。调用方应先 `register_entity` 或检查 `has_entity`。
- **If 在 `attribute.{e}.{a}.base_changed` 回调中调用 `set_base(e, a, ...)`（同名递归）**：同 ResourceSystem 的"递归 emit 阻断"规则——EventBus 阻断同名递归事件投递；本系统的写入**已执行**但事件不投递。**调用方应避免在属性变化回调中修改同一属性**。

### register_entity 路径

- **If `entity_id` 已注册（`has_entity == true`）**：返回 `false`，已有条目和 meta 完全不变，打印警告 `"register_entity: '{entity_id}' already registered"`。与 ResourceSystem.register 一致。
- **If `definition` 缺失必填字段（`category` / `attribute_set`）**：拒绝注册，返回 `false`，打印警告列出缺失字段。
- **If `definition.attribute_set` 引用未知 schema 名（`attribute_set_config.json` 中无此条目）**：拒绝注册，返回 `false`，打印警告 `"register_entity: unknown attribute_set '{name}'"`。
- **If `definition` 中初始 base 值有越界（如 `crit_rate = BigNumber(2.0)`，超出 [0.0, 1.0] 推荐范围）**：本系统**不**检测语义越界（attribute 范围属于业务校验，本系统是数据层），允许写入；越界检查应由数据配置系统在加载时校验，或由调用方在 `set_base` 前检查。
- **If 启动批量注册分帧执行期间被中断（如玩家在加载界面退出）**：已注册的实体保持 Active 状态，未注册的实体保持 Unregistered；下次启动时存档系统先 `restore()` 再补齐未恢复的模板（敌人模板每次启动都是从配置重建，不依赖存档；主角/弟子来自存档）。

### unregister_entity 路径

- **If `entity_id` 不存在**：返回 `0`，不崩溃，不打印警告（幂等操作）。
- **If `unregister_entity` 期间正在被 `get_final` 高频读取（如战斗中敌人死亡）**：本系统是同步的，调用 `unregister_entity` 时立即清空内存条目；后续 `get_final` 命中 `entity_id 不存在` 路径返回 ZERO（不崩溃）。**调用方应在战斗回合结束等安全点统一清理临时实体**，避免回合中清理。
- **If 同一帧内 `unregister_entity` 多个实体（战斗结束清理 20 个敌人）**：发布 20 条 `attribute.{entity_id}.unregistered` 事件，按调用顺序投递。订阅者（HUD）应能容忍批量清理事件。

### snapshot / restore 路径

- **If `snapshot()` 包含临时实体（含 session UUID 后缀）**：本系统**不**主动过滤——返回所有 Active 实体的快照。**调用方（存档系统）负责按 `category in ["player", "disciple"]` 过滤**，避免把战斗中的敌人会话写入存档。这一职责划分写入 §Dependencies 的"存档系统"行。
- **If `restore(data)` 中含配置文件不存在的 `entity_id`（如旧存档主角弟子 ID 在新版本被改名）**：跳过该 entity，打印警告 `"restore: skipping unknown entity '{entity_id}'"`。其他实体正常恢复，不崩溃。
- **If `restore(data)` 中某属性条目的 BigNumber 字典损坏（缺 `m` 或 `e` 字段）**：BigNumber.from_dict 返回 ZERO，restore 写入 ZERO 并打印警告。降级处理。
- **If `restore(data)` 中某 entity 的 `meta.attribute_set` 在新配置中已删除**：跳过该 entity，打印警告 `"restore: entity '{entity_id}' references deprecated schema '{name}'"`。需配合存档迁移系统处理。
- **If `restore(data)` 期间产生事件**：本系统**抑制** restore 期间的所有 `base_changed` 事件（与 ResourceSystem 不同——属性数量乘实体数量可能在百级以上，事件风暴会卡顿 HUD）。restore 完成后由调用方主动发起一次"全量 HUD 重绘"信号（如订阅存档系统已定义的 `save.loaded` 事件后整体刷新）。

### 跨系统协作路径

- **If 上层系统未通过 `make_target` 直接拼接 ModifierEngine target 字符串**（如手写 `"player_atk"` 而非 `"player.atk"`）：本系统无法检测——ModifierEngine 会把它当成另一个独立 target，导致修正器与 `get_final("player", "atk")` 不挂钩。**通过文档约束 + 代码规约（lint/PR review）保证**，本系统在 §Tuning Knobs 提供 `STRICT_TARGET_FORMAT_WARN` 选项可在调试模式下捕获不合规格式。
- **If 实体被 `unregister_entity` 后，ModifierEngine 中其修正器未被对应业务系统清理**：本系统**不**主动清理 ModifierEngine 中相关 target 的修正器——属性系统不持有这些修正器的 source 信息。**调用 unregister_entity 的业务系统（如战斗系统、装备系统）应在卸下装备/战斗结束时调用 `ModifierEngine.unregister_by_source(source)`**。残留修正器是内存泄漏风险但不影响正确性（再注册同名 entity_id 时旧修正器会意外生效——这一风险在 Open Questions 中记录）。

### 性能路径

- **If 单实体属性数超过 `WARN_ATTRIBUTE_COUNT_THRESHOLD`（默认 30）**：注册时打印性能警告 `"entity '{entity_id}' has {N} attributes, exceeds recommended limit"`。MVP 6 项远低于阈值；后期赛季新增多套体系后可能触发。
- **If 注册实体总数超过 `WARN_ENTITY_COUNT_THRESHOLD`（默认 1000）**：注册时打印性能警告。MVP 226 远低于阈值。

## Dependencies

### 上游依赖

| 系统 | 依赖性质 | 数据接口 |
|------|---------|---------|
| **大数值系统** (BigNumber) | 硬依赖 | 所有 `base` 值存储为 `BigNumber` 实例；调用 `to_dict/from_dict/equals/is_zero/subtract`（用于 delta 计算）。属性系统无法脱离 BigNumber 独立工作 |
| **修正器/倍率引擎** (ModifierEngine) | 硬依赖（仅 `get_final` 路径） | 调用 `ModifierEngine.apply(target, base)` 整合最终值。`target` 命名约定为 `"{entity_id}.{attr_id}"`（由 `make_target()` 生成 StringName）。属性系统**不**调用 ModifierEngine.register/unregister（修正器生命周期由业务系统管理） |
| **事件总线** (EventBus) | 硬依赖 | 调用 `EventBus.emit()` 发布两类事件：`attribute.{entity_id}.{attr_id}.base_changed` / `attribute.{entity_id}.unregistered`。属性系统**只发布不订阅** |
| **数据配置系统** | 硬依赖 | 启动时读取 `attribute_set_config.json`（schema 定义）和 `entity_template.json`（敌人/弟子模板），通过 `register_entity()` 批量注册。配置定义全部 attribute_set 名、attribute_set 包含的 attr_id 集合、各 attr_id 的初始 base 值 |

### 下游消费者

| 系统 | 调用方向 | 数据接口 | 备注 |
|------|---------|---------|------|
| **等级系统** | 主动调用 | 升级时 `set_base("player", "atk", new_atk)` 等 | 升级带来的 base 增长由等级系统通过公式引擎计算后写入 |
| **敌人数据库** | 主动调用 | 启动时 `register_entity(template_id, definition)` 批量注册静态模板；战斗实例化时 `register_entity(instance_id, definition_clone)` 创建动态副本 | 模板 entity_id 与战斗实例 entity_id 不同（实例 ID 含会话 UUID 后缀） |
| **战斗计算器** | 主动调用 | 高频 `get_final(entity_id, attr_id)` 读双方最终属性 | 用于伤害公式、行动顺序、命中判定 |
| **半自动战斗系统** | 主动调用 | 战斗结束时批量 `unregister_entity("enemy_*_session{N}")` 清理临时实体 | 防止战斗会话内存累积 |
| **HUD 系统** | 订阅 | 订阅精准事件名 `attribute.player.{attr_id}.base_changed` / `attribute.disciple_001.{attr_id}.base_changed` | HUD 不订阅敌人属性变更（性能控制）；不轮询 |
| **装备系统**（Post-MVP） | 间接 | 不直接调用本系统；通过 `ModifierEngine.register({target: make_target("player", "atk"), ...})` 注册装备修正器，本系统的 `get_final` 自动反映 | 卸下装备时调 `ModifierEngine.unregister_by_source("equip_xxx")` |
| **存档系统** | 主动调用 | 存档调 `snapshot()`；读档调 `restore(data)`；调用方负责按 `category in ["player", "disciple"]` 过滤临时实体 | 本系统提供纯数据快照，存档系统负责文件 I/O 与 entity 过滤 |
| **Build 评分系统**（Post-MVP） | 主动调用 | 高频 `get_final_set(entity_id)` 拉取实体全属性快照 | 评分系统读最终值评估，不修改 base |
| **境界突破/飞升/轮回系统**（Post-MVP） | 主动调用 | `set_base(entity_id, attr_id, new_value)` 批量写入新境界初始属性 | 重置触发时由业务系统控制具体写入逻辑，本系统不感知"突破" |

### 关键非依赖（容易误以为是依赖但不是）

| 系统 | 关系 | 说明 |
|------|------|------|
| **公式引擎** (FormulaEngine) | **无直接关联** | 属性系统**不**调用 FormulaEngine。属性成长公式（如 `atk = base + level × growth`）由调用方（等级系统、突破系统）使用 FormulaEngine 计算后通过 `set_base` 写入。本系统是数据层，不持有任何公式 |
| **资源系统** (ResourceSystem) | **无直接关联** | 资源系统管"全局玩家资产"（灵气、灵石），属性系统管"角色个体属性"（攻击、防御）。语义正交、命名空间隔离（资源 ID 与属性 ID 不重名）；两者都通过 EventBus 与 BigNumber 协同，互不知道对方存在 |
| **物品/材料系统** | **无直接关联** | 物品/材料是数值资产（灵石、药材、丹药），不是属性。装备物品对属性的加成通过 ModifierEngine 中介，不经过属性系统 |
| **状态机系统** | **无直接关联** | 属性系统是 CRUD 服务，无业务状态机。实体的"在线/死亡/封印"等业务状态由各自业务系统持有 |
| **随机数与种子系统** (RNGManager) | **无直接关联** | 属性系统是确定性的——所有写入都来自显式调用，无随机性。装备词条等含随机的属性变化由调用方在写入前用 RNG 决定值，本系统只忠实存储 |

### 双向一致性自检（与上游 GDD 对齐）

- ✅ **BigNumber GDD** §Interactions 列出"属性系统 — 所有角色属性存储为 BigNumber"——一致
- ✅ **ModifierEngine GDD** §Interactions / §Dependencies 列出"属性系统 — 调用 `apply("player.atk", base_atk)` / `apply("{entity_id}.{attr_id}", base)` 计算最终属性值"——一致（已通过 `/consistency-check` 2026-05-03 把示例从裸 `"atk"` 更新为 `{entity_id}.{attr_id}` 命名约定）
- ✅ **ModifierEngine GDD** §Detailed Design 第 2 条 target 字段已加注释："target 字符串语义由消费方约定（属性系统使用 `{entity_id}.{attr_id}` 格式；产出乘数系统使用 `{resource_id}_production` 格式）；ModifierEngine 本身对 target 字符串无解析"——已在 `/consistency-check` 2026-05-03 加入
- ✅ **FormulaEngine GDD** §Interactions / §Dependencies 已通过 `/consistency-check` 2026-05-03 把"属性系统调用公式引擎"行更新为"等级系统/突破系统调用公式引擎"，并加"属性系统不直接调用 FormulaEngine"的中介说明——一致
- ✅ **EventBus GDD** §Core Rules 第 11 条命名空间约定已通过 `/consistency-check` 2026-05-03 追加 `attribute.{entity_id}.{attr_id}.base_changed` 和 `attribute.{entity_id}.unregistered` 两个显式条目；§Interactions 表 + §Dependencies 表也已追加属性系统行——一致
- ✅ **数据配置系统 GDD**（已 Designed）——本 GDD 仅依赖其"按 JSON/Resource 加载配置"基础能力，无具体接口冲突

### 跨文档冲突清单（汇总）

3 项跨 GDD 修订已通过 `/consistency-check` 2026-05-03 全部解决：
1. ✅ **ModifierEngine GDD**：§Detailed Design 第 2 条已加 target 命名约定注释；§Interactions / §Dependencies 中"属性系统"行示例已更新为 `apply("player.atk", base_atk)` / `apply("{entity_id}.{attr_id}", base)`
2. ✅ **FormulaEngine GDD**：§Interactions 行 122 + §Dependencies 行 232 中"属性系统"已改为"等级系统/突破系统"，并加入"属性系统不直接调用 FormulaEngine"的中介说明
3. ✅ **EventBus GDD**：§Core Rules 11 已追加 `attribute.{entity_id}.{attr_id}.base_changed` 和 `attribute.{entity_id}.unregistered` 两条命名空间；§Interactions 表 + §Dependencies 表已追加属性系统行

## Tuning Knobs

属性系统的可调参数分为三类：**Schema 配置参数**（per-attribute_set，由数值设计师设定）、**引擎/调试参数**（全局，开发期或编译期常量）、以及**与依赖系统的调参分工**说明。

### Schema 配置参数（per-attribute_set 与 per-attr_id 级别）

| 参数 | 类型 | 默认值 / 必填 | 安全范围 | 调整影响 |
|------|------|------------|---------|---------|
| `attribute_set.name` | String | 必填，唯一 | 字母数字下划线 | 实体类别 → 属性集合的索引名（如 `"player_set"`、`"enemy_basic_set"`） |
| `attribute_set.attr_ids` | Array[String] | 必填，至少 1 个 | MVP 推荐 4-7 项 | 决定该实体可写入的属性范围；越多 schema 校验越严，但单实体内存增加 |
| `attr_id` | String | 必填 | 全局唯一 snake_case | 属性 ID 字符串常量；新增属性 ID 必须在所有 attribute_set 中明确归属 |
| `attr_id.initial_base` | BigNumber | 由 schema 提供 | 各 attr_id 推荐范围（见 §Detailed Design 规则 6） | 实体注册时的初始 base；注册后由业务系统通过 `set_base` 更新 |
| `attr_id.recommended_range` | [BigNumber, BigNumber] | 元数据 | 各 attr_id 业务安全范围 | 仅作文档元数据，本系统**不**强制校验（语义校验由数据配置系统加载时执行） |

### 引擎/调试参数（全局，开发期或编译期常量）

| 参数 | 默认值 | 安全范围 | 增大影响 | 减小影响 |
|------|--------|---------|---------|---------|
| `ATTRIBUTE_BUDGET_RATIO` | 0.04 | [0.02, 0.08] | 属性系统获得更多帧时间预算，允许更高频战斗 get_final 调用 | 更严格的性能限制；过严可能导致大型团战 get_final 触发卡顿 |
| `BATCH_INIT_PER_FRAME` | 50 | [10, 100] | 启动加载更快但单帧开销变大 | 启动加载分更多帧但每帧更轻；推荐 50（5 帧加载 226 实体） |
| `STRINGNAME_CACHE_PRELOAD` | true | {true, false} | 注册实体时预生成所有 `(entity_id, attr_id)` 的 StringName，加速 `make_target`；轻微增加内存（~38 KB worst case） | 按需生成 StringName，每次 `make_target` 增加 ~0.0015 ms 拼接开销 |
| `WARN_ATTRIBUTE_COUNT_THRESHOLD` | 30 | [10, 100] | 单实体属性数告警阈值；增大允许更复杂实体 | 更早触发性能警告（推荐 30，MVP 6 项远低于） |
| `WARN_ENTITY_COUNT_THRESHOLD` | 1000 | [100, 10000] | 实体总数告警阈值；增大允许更大型敌人数据库 | 更早触发性能警告（MVP 226 远低于） |
| `STRICT_TARGET_FORMAT_WARN` | true | {true, false} | 调试模式下：捕获不通过 `make_target` 直接拼接 ModifierEngine target 的违规调用并打印警告（开发环境强烈推荐） | 静默允许任意 target 格式，可能导致修正器与属性查询不挂钩（仅生产构建可关闭） |
| `WARN_ON_MISSING_ENTITY` | true | {true, false} | `set_base` 调用未注册实体时打印警告 | 静默 no-op，减少日志噪音（生产构建可关闭） |
| `WARN_ON_INVALID_INPUT` | true | {true, false} | `register_entity` 缺字段、未知 schema、空字符串 ID 等情况打印警告 | 静默拒绝 |
| `WARN_ON_RESTORE_MISMATCH` | true | {true, false} | `restore` 时遇到配置中不存在的 entity_id、损坏的 BigNumber 等情况打印警告 | 静默跳过，便于版本迁移 |
| `SUPPRESS_RESTORE_EVENTS` | true | {true, false} | `restore` 期间抑制所有 `base_changed` 事件，避免 N 实体 × M 属性的事件风暴；调用方应在 restore 完成后发起一次"全量 HUD 重绘"信号 | 关闭后 restore 期间每次 `set_base` 正常发事件，HUD 反复刷新（仅调试用） |
| `MAX_BATCH_SET_SIZE` | 30 | [10, 100] | 允许 `set_base_batch` 单次处理更多 attr 条目 | 限制批量大小，防止异常输入；超过此值时截断并打印警告 |

### 设计师 vs 开发者调参边界

- **Schema 配置参数**通过 `attribute_set_config.json` 修改，由**数值设计师**调整。新增属性 ID 只需追加配置（重启生效）；新增 attribute_set 需同步在 `entity_template.json` 中分配
- **引擎/调试参数**是项目级常量或开发模式开关，由**开发者**在实现阶段设定，运行时不应动态修改
- **属性的初始 base 值**虽属配置驱动，但其成长曲线由等级系统/突破系统的 GDD 定义；本 GDD 仅承诺"接受调用方通过 `set_base` 写入的值"

### 与依赖系统的调参分工

| 调参对象 | 负责系统 | 说明 |
|---------|---------|------|
| 属性 schema 与初始值 | 属性系统（首次注册） → 等级系统/突破系统（运行时增长） | 属性系统提供初始默认；等级系统接管成长 |
| 属性成长公式系数（`atk_per_level` 等） | 等级系统 + FormulaEngine | 本系统不持有公式 |
| 装备/技能/Buff 对属性的修正值 | 装备系统 / 技能系统 / Buff 系统 + ModifierEngine | 本系统不持有修正器 |
| 属性面板呈现样式（颜色、分组、排序） | HUD 系统 | 本系统不关心呈现 |
| 敌人初始属性 | 敌人数据库 | 通过 `register_entity` 写入；后续战斗中由战斗计算器读最终值 |
| 重置时属性如何归零/重算 | 突破/飞升/轮回系统（Post-MVP） | 本系统只接受调用方的 `set_base` 写入，不感知"重置"语义 |

## Visual/Audio Requirements

本系统**无视觉/音频需求**。属性系统是数据基础设施层，所有玩家可见的属性表现——属性面板、属性数值跳动、属性条变色、突破时的属性跃升动画、装备替换的数字浮空特效、暴击数字闪烁、面板溯源小窗、敌方属性披露浮窗——均由 **HUD 系统**承载，本系统仅通过 `attribute.{entity_id}.{attr_id}.base_changed` 事件向其推送变更通知。视觉与音频规格由 HUD 系统 GDD（#30，未设计）定义。

参见 §Player Fantasy 的"重要边界声明"段落。

## UI Requirements

本系统**无 UI 需求**。属性面板、属性溯源弹窗、属性对比窗口、敌方属性披露浮窗、Build 评分面板等所有 UI 元素由 **HUD 系统**与 **UI 框架**承载，本系统仅提供 `get_base / get_final / get_attribute_set / get_final_set` 等数据查询 API 供其消费。UI 布局、交互流程、信息密度由 UI 框架 GDD（#29，未设计）和 HUD 系统 GDD（#30）定义。

参见 §Player Fantasy 的"重要边界声明"段落。

## Acceptance Criteria

### 实体生命周期

- [ ] **GIVEN** `AttributeSystem` 已加载，`attribute_set_config.json` 含 `"player_set"` schema (含 6 项 MVP 属性)，**WHEN** 调用 `register_entity("player", {category:"player", attribute_set:"player_set"})`，**THEN** 返回 `true`，`has_entity("player") == true`，`get_attribute_set("player")` 返回含 6 个 attr_id 的 Dictionary
- [ ] **GIVEN** `"player"` 已注册，**WHEN** 再次调用 `register_entity("player", ...)`，**THEN** 返回 `false`，已有条目不变，打印警告
- [ ] **GIVEN** `definition.attribute_set` 为未知 schema `"unknown_set"`，**WHEN** `register_entity("test", ...)`，**THEN** 返回 `false`，`has_entity("test") == false`，打印警告
- [ ] **GIVEN** `definition` 缺 `category` 字段，**WHEN** `register_entity`，**THEN** 返回 `false`，打印警告列出缺失字段
- [ ] **GIVEN** `"enemy_001"` 已注册含 6 属性，**WHEN** `unregister_entity("enemy_001")`，**THEN** 返回 `6`，`has_entity == false`，发布一条 `attribute.enemy_001.unregistered` 事件
- [ ] **GIVEN** `unregister_entity("never_registered")`，**WHEN** 调用，**THEN** 返回 `0`，不崩溃，不打印警告

### Single CRUD

- [ ] **GIVEN** `"player"` 已注册，base_atk 初始 100，**WHEN** `set_base("player", "atk", BigNumber.from_int(500))`，**THEN** `get_base("player", "atk") == BigNumber.from_int(500)`
- [ ] **GIVEN** `set_base("player", "atk", BigNumber.from_int(500))`，**WHEN** 同帧再次相同调用，**THEN** delta=ZERO，**不**发布 `base_changed` 事件
- [ ] **GIVEN** `"player"` 已注册但无 `"luck"` 属性 (schema 内不含)，**WHEN** `set_base("player", "luck", BigNumber.from_int(1))`，**THEN** 拒绝写入，`get_base("player", "luck") == ZERO`，打印警告
- [ ] **GIVEN** `entity_id="ghost"` 未注册，**WHEN** `set_base("ghost", "atk", ...)`，**THEN** 拒绝写入，打印警告
- [ ] **GIVEN** `get_base("nonexistent", "atk")`，**WHEN** 调用，**THEN** 返回 `BigNumber.ZERO`，不打印警告（防御性读）

### Final Value Integration

- [ ] **GIVEN** `"player"` base_atk = 1000，ModifierEngine 无注册修正器，**WHEN** `get_final("player", "atk")`，**THEN** 返回 `BigNumber.from_int(1000)`（透传）
- [ ] **GIVEN** `"player"` base_atk = 1000，ModifierEngine 已注册 `{target:"player.atk", type:ADD, value:200}`，**WHEN** `get_final("player", "atk")`，**THEN** 返回 `BigNumber.from_int(1200)`
- [ ] **GIVEN** `"player"` base_atk = 1000，ModifierEngine 已注册 ADD +200 + MULT 0.5（pool=equipment），**WHEN** `get_final`，**THEN** 返回 `BigNumber.from_int(1800)`（即 (1000+200) × 1.5）
- [ ] **GIVEN** `"ghost"` 未注册，**WHEN** `get_final("ghost", "atk")`，**THEN** 返回 `BigNumber.ZERO`，**不**调用 ModifierEngine.apply
- [ ] **GIVEN** `make_target("player", "atk")`，**WHEN** 首次调用与第二次调用，**THEN** 返回相同 StringName 实例（缓存命中）

### Events

- [ ] **GIVEN** `"player"` 已注册，base_atk = 100，**WHEN** `set_base("player", "atk", BigNumber.from_int(150))`，**THEN** EventBus 发布一次 `attribute.player.atk.base_changed`，payload `{entity_id:"player", attr_id:"atk", old_value:100, new_value:150, delta:50}`
- [ ] **GIVEN** HUD 仅订阅 `attribute.player.atk.base_changed`，**WHEN** `set_base("enemy_001", "atk", ...)` 同时被调用，**THEN** HUD 不收到敌人 atk 事件
- [ ] **GIVEN** `register_entity("player", ...)` 时初始 base 写入，**WHEN** 注册流程，**THEN** **不**发布 `base_changed` 事件（视为静态初始化）
- [ ] **GIVEN** `"enemy_001"` 已注册，**WHEN** `unregister_entity("enemy_001")`，**THEN** 仅发布一条 `attribute.enemy_001.unregistered` 事件，不发逐属性删除事件

### Batch / Snapshot / Restore

- [ ] **GIVEN** `"player"` 注册，**WHEN** `set_base_batch("player", {atk:BN(500), def:BN(200), spd:BN(80)})`，**THEN** 三个属性 base 全部更新，发布 3 条 `base_changed` 事件
- [ ] **GIVEN** 主角和 5 弟子已注册，含若干 base 值，**WHEN** `snapshot()`，**THEN** 返回 `{version:1, entities:{...}}` 含全部 6 实体；BigNumber 字典可被 `from_dict` 还原
- [ ] **GIVEN** snapshot 数据中含 `"deprecated_disciple"` 但配置无此 schema，**WHEN** `restore(data)`，**THEN** 跳过该 entity 并打印警告，其他 entity 正常恢复
- [ ] **GIVEN** snapshot 数据中某 BigNumber 字典缺 `"e"` 字段（损坏），**WHEN** `restore`，**THEN** 该属性 base = ZERO，打印警告，不崩溃
- [ ] **GIVEN** `restore(data)` 写入 100 条属性，**WHEN** `SUPPRESS_RESTORE_EVENTS=true`，**THEN** 期间 EventBus 不发布任何 `base_changed` 事件
- [ ] **GIVEN** `"enemy_yougui_a_session1234"`（临时实体）已注册，**WHEN** `snapshot()`，**THEN** 返回 Dictionary 包含此 entity（**不主动过滤**）；调用方（存档系统）负责过滤

### Edge Cases

- [ ] **GIVEN** `BigNumber` 实例由 NaN 创建（已归一化为 ZERO），**WHEN** `set_base("player", "atk", that_bn)`，**THEN** 写入 ZERO，根据旧值是否非 ZERO 决定是否发事件
- [ ] **GIVEN** `make_target("", "atk")` 入参空，**WHEN** 调用，**THEN** 返回空 StringName，打印警告
- [ ] **GIVEN** `get_final("player", "atk")` 在 base_changed 回调内被同步调用，**WHEN** 触发，**THEN** 正常返回当前最终值，不死锁，不递归阻断
- [ ] **GIVEN** `set_base("player", "atk", ...)` 在 `attribute.player.atk.base_changed` 自身回调内被调用 (同名递归)，**WHEN** 调用，**THEN** 写入已执行，但事件不再投递（EventBus 阻断）

### Performance / Memory

- [ ] **GIVEN** 226 实体已注册，每实体 6 属性，5 订阅者监听，**WHEN** 单帧 50 次 `get_final`，**THEN** 总耗时 < 0.667 ms（帧预算）
- [ ] **GIVEN** 1 主角，3 订阅者监听，**WHEN** 单帧 5 次 `set_base`（不同 attr），**THEN** 总耗时 < 0.155 ms
- [ ] **GIVEN** 启动时分帧批量注册 226 实体 × 7 属性，**WHEN** 完成，**THEN** 任一帧耗时 < 2.5 ms（不超过帧预算的 15%）
- [ ] **GIVEN** 226 实体 × 7 属性已注册，**WHEN** 内存采样，**THEN** AttributeSystem 总占用 < 200 KB
- [ ] **GIVEN** ModifierEngine 已对 `"player.atk"` 缓存最终倍率，**WHEN** 连续 100 次 `get_final("player", "atk")`，**THEN** 平均单次耗时 < 0.015 ms

## Open Questions

| Question | Owner | Deadline | Resolution |
|----------|-------|----------|-----------|
| `hp_current`（实时血量）的归属系统：本 GDD 假定它由战斗计算器内部的"战斗状态层"管理，与本系统的"基础值账本"语义不同。但战斗计算器 GDD 未设计——如未来认为 `hp_current` 应由 ResourceSystem 或本系统统一持有，需重审本 GDD 的属性集定义 | 设计师 | 战斗计算器 GDD 时 | — |
| ModifierEngine GDD §Detailed Design 的 target 示例使用裸字符串（如 `"atk"`），未声明"target 格式由消费方约定"——需在 `/consistency-check` 阶段在 ModifierEngine GDD §Edge Cases 或 §Tuning Knobs 增加 target 命名约定澄清 | 设计师 | `/consistency-check` 阶段 | ✅ 已解决 2026-05-03 — modifier-engine.md §Detailed Design 第 2 条 target 字段已加注释；§Interactions 行 123 与 §Dependencies 行 267 示例改为 `apply("player.atk", base_atk)` 与 `apply("{entity_id}.{attr_id}", base)` |
| FormulaEngine GDD §Interactions 列出"属性系统调用 evaluate 计算属性成长系数"，与本 GDD 不一致——需在 `/consistency-check` 阶段把 FormulaEngine 的 Interactions 改为"等级系统/突破系统调用 evaluate" | 设计师 | `/consistency-check` 阶段 | ✅ 已解决 2026-05-03 — formula-engine.md §Interactions 行 122 与 §Dependencies 行 232 中 "属性系统" 改为 "等级系统/突破系统"，并加"属性系统不直接调用 FormulaEngine"的中介说明 |
| EventBus GDD §12 命名空间约定中列出 `attribute.{entity_id}.{attr_id}.base_changed` 和 `attribute.{entity_id}.unregistered` 两个属性事件 | 开发者 | 实现阶段前 | ✅ 已解决 2026-05-03 — event-bus.md 已追加两条命名空间；§Interactions 表 + §Dependencies 表已追加属性系统行 |
| ModifierEngine 缺 `modifier_registered` / `modifier_unregistered` 事件——本系统当前不缓存最终值（透传 ModifierEngine），如未来需要在属性系统加一层缓存以优化战斗高频查询，需推动 ModifierEngine 补充增减事件以支持正确的缓存失效。Open Questions 已在 ModifierEngine GDD 中提出 | 技术总监 | Post-MVP 性能评估时 | — |
| 实体被 `unregister_entity` 后，ModifierEngine 中其修正器未被对应业务系统清理时的残留问题——本 GDD 选择"业务系统责任"路径。是否需要属性系统提供 `cleanup_modifiers_for_entity(entity_id)` 工具方法（内部按 source 前缀清理 ModifierEngine）作为补救措施？取决于 ModifierEngine API 是否允许按 target 前缀批量注销 | 设计师 | 装备系统 GDD 时 | — |
| MVP 6 属性的具体初始 base 值（`hp_max` 起始 100 还是 1000？`spd` 起始 10 还是 50？）由数值设计师拍板，依赖战斗计算器伤害公式 + 等级系统成长曲线 | 数值设计师 | 战斗计算器/等级系统 GDD 时 | — |
| `attribute_set_config.json` 与 `entity_template.json` 的具体文件位置（`assets/data/` 下何处？）和格式版本号约定，依赖于数据配置系统 GDD | 开发者 | 数据配置系统 GDD 完善时 | — |
| 是否需要 `attribute.*.base_changed` 通配符订阅以减少 HUD 订阅样板代码？取决于 EventBus 是否实现通配符订阅（其 Open Questions 已列）。MVP 阶段 HUD 只订阅主角 6 属性 + 上阵弟子 6 属性 ≈ 36 条精准订阅，可接受 | 设计师 | HUD 系统 GDD 时 | — |
