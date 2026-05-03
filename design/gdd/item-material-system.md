# 物品/材料系统 (Item/Material System)

> **Status**: Approved
> **Author**: binlee1990 + agents
> **Last Updated**: 2026-05-03
> **Implements Pillar**: MVP: 4.1 数字增长就是快乐（主） · 4.10 数据驱动与可扩展（基底）；Alpha: 4.6 渐进叙事展开（主，待装备/词条/法宝/稀有材料上线后兑现）
> **Creative Director Review (CD-GDD-ALIGN)**: CONCERNS (accepted) 2026-05-03 — 3 项非阻塞修订已应用：(1) Player Fantasy 显性区分 MVP 兑现度；(2) Open Questions 追加"Alpha 重写 Player Fantasy"承诺；(3) 澄清"千年血参"为 Alpha 示意
> **Independent /design-review**: NEEDS REVISION → REVISED 2026-05-03 — 5 specialist + creative-director 综合裁定 7 项 BLOCKING + 15 项 IMPORTANT 已修订（详见 review-log）
> **/design-review Re-review (R2)**: NEEDS REVISION → REVISED 2026-05-03 — 5 specialist + creative-director 再审查 4 项 BLOCKING + 18 项 IMPORTANT 已修订：(1) peek_field CoW 描述修正（GDScript 4.x 引用类型，非 3.x CoW）+ 容器字段内部 `.duplicate(false)` 浅拷贝阻断写穿透；(2) `is_loaded()` + EventBus 订阅改为先订阅后检查（TOCTOU 竞态修复）；(3) AC-F6 重写为契约 AC（GDScript 无运行时栈自省）；(4) AC-E1 拆为 E1a（CI 可测 2 组合）+ E1b（手动验证 release build）；(5) 公式 3a/3b 变量名统一 t_str_eq + T→T_items；(6) 公式 4 新增 t_json_io 变量 + t_event_dispatch 范围修正；(7) query_by_tag contains 语义澄清为精确等值比较；(8) `set_data_config(dc: Object)` 类型标注；(9) AC 测试类型路由修正（D/I→Logic）；(10) AC 计数修正 + AC-E3/E4 新增；(11) reload Unloaded 状态边界定义；(12) EventBus GDD `categories→item_classes` 跨文档同步修复；(13) Autoload/class_name 命名冲突追加 Open Questions；(14) OS.is_debug_build 关闭决议

## Summary

物品/材料系统是修真世界所有物品的元数据注册和查询服务（"沉默的命名者"）。它从 `items.json` 加载所有物品的 `name/item_class/rarity/icon_path/tags` 等显示信息，对 HUD / 掉落系统 / 物品图鉴等下游系统提供 typed accessor API。MVP 仅承载 5 种 `resource_material` 元数据，**不持有玩家库存数量**——玩家持有的同质化材料数量由 ResourceSystem 管理，本系统只做"翻译服务"，让数字旁边都有可读的中文名字。

> **Quick reference** — Layer: `Core Gameplay` · Priority: `MVP` · Key deps: `数据配置系统`

## Overview

物品/材料系统是游戏中所有物品（material、equipment、consumable、quest_item……）元数据的统一注册和查询服务。它在游戏启动时通过数据配置系统加载 `items.json`，把所有物品定义（中文名、图标路径、稀有度、分类标签、本地化 key 等）存入内存索引，并对外提供 `ItemRegistry.get(item_id)`、`query_by_item_class(cat)`、`query_by_tag(tag)` 等类型化查询 API。任何系统拿到一个 `item_id` 字符串后，**通过本系统把它翻译成"这是什么、怎么显示、属于哪类"**——这是物品体系跨系统通信的语义桥梁。

**关键边界声明**：本系统**只持有元数据**，**不持有玩家库存**。玩家实际拥有的同质化材料数量（如 herb 的当前数量、lingshi 的余额）由资源系统（ResourceSystem）管理，本系统不参与读写。掉落系统拾取 herb 时的执行链是：`ItemRegistry.get("herb") → 拿到 metadata → 显示稀有度边框/图标 → ResourceSystem.add("herb", qty)`——本系统提供"翻译服务"，资源系统负责"账本"。这种分工让两个系统都保持单一职责，避免 God Object（TD-SYSTEM-BOUNDARY 评审约束）。

**MVP 范围**：MVP 阶段 `items.json` 仅承载 5 种 `item_class="resource_material"` 物品的元数据（对应资源系统已注册的 lingqi/xiuwei/lingshi/herb/exp）。装备、词条、消耗品、任务道具、法宝、宠物蛋等离散物品体系延后到 Alpha 阶段；本系统的 schema 已为这些扩展预留分类与字段（如 `rarity`、`tags`、`icon_path`），未来追加 JSON 记录即生效，不修改本系统代码。这与 game-concept §11 MVP "战斗只产经验/材料、不要复杂装备词条海" 的边界一致。

**为什么需要它**：没有这一层，HUD 顶栏显示 `"herb"` 时不知道该写"药材"还是"草药"；掉落系统拿到 `item_id` 时无法判断稀有度边框的颜色；后期装备系统接入时需要重新发明物品 metadata 层。有了它，HUD/掉落/百科/未来装备系统都使用同一份"物品身份证"，物品的显示一致性、分类一致性、本地化一致性都集中维护。

虽然玩家不直接调用本系统的 API，但他们看到的每一个物品名称、每一个图标、每一个稀有度边框都是它驱动的。当玩家在拾取面板看到"千年血参（绿色稀有边框）+1"时，"千年血参"和"绿色边框"都是 ItemRegistry 翻译出来的；当玩家未来翻看物品图鉴时，"已收集 12/30"的图鉴框架也建立在这一层之上。

作为 Core Gameplay 层基础服务，本系统是 MVP 最小挂机闭环中"掉落 → HUD 显示 → 拾取入账"链路的关键中介。本 GDD 完成后，掉落系统、HUD 系统、未来的物品图鉴系统的设计依赖才能解锁。

## Player Fantasy

物品/材料系统是修真世界的"沉默命名者"——它从不发声、玩家从不察觉它的存在，但所有可见的物品都因为它才有了名字、形状、稀有度的颜色。它的工作不是创造惊喜，而是让所有惊喜可被言说。

**主锚定时刻**：玩家挂机十分钟后切回游戏，离线结算面板缓缓铺开——

> "灵气 +2.4 亿、修为 +1800 万、灵石 +47、药材：**灵草 ×12**、战斗经验 +5300。"

每个数字旁边都有一个有质感的中文名字，每个名字都是一颗可以被记住、被讨论、被搜索的具体存在。不是"resource_b +47"，不是"item_03 ×12"——是"灵石 +47、灵草 ×12"。这种"翻译"在屏幕上不到一行，玩家甚至不会觉得它特殊；但如果它消失，整个修真世界会立刻坍塌成一组面目模糊的占位符 ID。

**次级锚定时刻**（Alpha 示意，**非 MVP 实际数据**）：玩家在挂机区某次循环里掉到一株稍特殊的药材，HUD 角落弹出"获得：**千年血参 ×1**"。即使 MVP 阶段所有材料都是同等稀有度的常规项，"千年血参"四个字本身就是一个微型小说——它告诉玩家这个世界有"千年"、有"血参"、有植物分阶、有时间感。这种"被命名"的瞬间是 4.6 渐进叙事展开 的最小单元：世界不是通过一段长剧情展开的，而是通过每一次新物品的命名、每一次新分类的出现、每一次新稀有度颜色的诞生，像点水墨画一样一笔一笔晕染开来。

> **MVP 现实声明**：MVP 数据集仅 5 条 `lingqi/xiuwei/lingshi/herb/exp`，**不含"千年血参"**——本节次级锚定时刻是为 Alpha 阶段装备/词条/法宝/稀有材料上线后的"渐进叙事"占位。MVP 阶段实际兑现的是支柱 4.1（数字增长就是快乐）的具象化层（"灵气 +2.4 亿"→"灵气 +2.4 亿、灵草 ×12"），而非支柱 4.6 的"渐进"维度。4.6 的真正兑现条件是 Alpha 内容广度上线——届时本节应回头修订（见 Open Questions）。

**调性目标**：让玩家信任这个世界的"语言层"。当 ResourceSystem 用"账本般的确定性"承诺数量可信、AttributeSystem 用"成长可视化"承诺自身越来越强，**ItemRegistry 承诺的是"看到的每一个物品名字都是经过设计的、不会乱"**。三者形成自然分工——数量、属性、命名——共同构筑修真世界的可信底色。

**反证（独立价值论证）**：要看清 ItemRegistry 对玩家体验的独立贡献，最直接的方法是想象它**不存在**或**降级**时玩家看到什么：

- **若 name 字段缺失或 ItemRegistry 永久零返回**：HUD 顶栏会显示 `unknown_item × 47`、`item_03 × 12`，离线结算面板写满未知 ID。玩家无法在 0.3 秒内辨认刚拾取的物品到底是什么——4.1 数字增长的反馈环路被切断（数字仍在涨，但失去"我知道我在涨什么"的语义）。
- **若 rarity / item_class 缺失**：HUD 失去稀有度边框颜色与分类筛选的依据；玩家无法形成"我已收集 12/30 种药材"的进度感知；Alpha 阶段"稀有掉落红框闪一下"这种最微小的叙事单元也无法成立——4.6 渐进叙事支柱不可能浮现。

ItemRegistry 自身**不产生**任何玩家情绪，但它让其他系统**有可能产生**这些情绪。本系统的玩家锚定时刻不是"我看到 ItemRegistry 在工作"，而是"我每次看见的物品都被认真命名过"——这种"语言基质"是修仙叙事所有展开的最小可识别单元。

**支柱对应**：
- **4.6 渐进叙事展开**（主）：物品命名是世界展开的最小笔触。MVP 5 种材料先建立"每一个物品都有完整身份"的元承诺；Alpha 阶段装备/词条/法宝上线后，这个容器立即接得住成百上千的新物品，每一个都有同等待遇。
- **4.1 数字增长就是快乐**（辅）：数字旁边的名字让增长从抽象变具体。"+47"是数字，"灵石 +47"是收获——后者比前者快乐一个量级。
- **4.10 数据驱动与可扩展**（基底）：物品命名集中在 items.json，新增物品只需追加 JSON 记录，符合本游戏所有内容长期可扩展的承诺。

**重要边界声明**：本系统是上述支柱兑现的**必要中介**，而非支柱的直接载体——HUD 系统才是把"灵草 ×12"画到屏幕上的视觉呈现者；掉落系统才是产生"获得：千年血参"瞬间的触发者；本地化系统（Post-MVP）才是支撑多语言名字的翻译层。本系统**只为它们提供物品身份证的统一注册和查询**。本节的"玩家锚定时刻"是物品系统作为基础设施被多个上层系统协同消费后所达成的整体体验，不应被理解为本系统应主动包含 UI 渲染、本地化文本、掉落触发等上层逻辑（参见 TD-SYSTEM-BOUNDARY 评审约束）。

物品/材料系统不是修仙幻想的舞台，也不是惊喜的创造者——它是这个世界**所有物品都能被叫出名字**的基础设施。在长达数百小时的修仙旅程中，玩家或许永远不会感谢 ItemRegistry，但他们会感谢一个"我看到的每一个物品都被认真对待"的世界。

## Detailed Design

### Core Rules

1. **架构形态**：`ItemRegistry` 作为 `RefCounted` 服务类，由 Autoload 节点 `/root/ItemRegistry`（轻量 Node 包装器）在 `_ready()` 中创建唯一实例。Autoload 顺序：**DataConfig 排在 ItemRegistry 之前**（`project.godot` 中显式设置）。对外暴露纯查询接口；不含任何运行时写入路径（除 `reload()` 调试方法）、不持有玩家状态、不发布运行时变更事件。

2. **ItemDefinition 数据模型**（每条以 `id` 为 key 存入内部 Dictionary `_items`）：

   | 字段 | 类型 | MVP 必填 | 默认值 | MVP 用途 | Alpha+ 用途 |
   |------|------|---------|--------|---------|------------|
   | `id` | String | ✓ | — | 全局唯一标识（与 ResourceSystem.resource_id 共享命名空间） | — |
   | `name` | String | ✓ | — | 中文显示名（如 "灵草", "千年血参"） | 本地化前的 fallback |
   | `item_class` | String | ✓ | — | 锁定枚举 `resource_material / consumable / equipment / quest`（MVP 仅用第一个）。**字段名为 `item_class` 而非 `category`** —— 避免与 `ResourceSystem.category`（按数量行为分：currency/material/progress/regenerative）在共享 id 命名空间下产生语义分叉 | 驱动分类筛选 |
   | `tags` | Array[String] | ✓ | `[]` | 开放标签集（如 `["herb", "low_tier"]`），掉落表/合成食谱过滤用 | 词条池过滤、配方匹配 |
   | `rarity` | String | ✓ | `"fanpin"` | 修仙品质 8 级枚举：`fanpin / jingliang / xiyou / shishi / chuanshuo / shenhua / xiantian / hundun`（与 game-concept §9 #108 一致）；MVP 全部 `fanpin`；HUD 据此映射边框颜色 | 装备品质门槛、掉落概率分层 |
   | `icon_path` | String | ✓ | `""` | Godot 资源路径（如 `"res://assets/icons/herb.png"`）；空字符串表示用占位图 | — |
   | `stackable` | bool | ✗ | `true` | 可叠加性；MVP material 全部 true。**约束：`stackable=false` 时 `stack_limit` 字段被忽略（离散装备实例无叠加语义）** | 离散装备实例为 false |
   | `stack_limit` | int | ✗ | `-1` | **`-1=无限`（默认）**；`>=0` 为具体上限。背包槽叠加上限。语义遵循 Godot/Unix 惯例（`-1=无界`，`0=零个=禁用`，`>0=有限上限`）。`stackable=false` 时本字段被忽略 | 库存 UI 槽位容量 |
   | `localization_key` | String | ✗ | `""` | i18n key（Post-MVP） | 本地化管线对接 |
   | `description` | String | ✗ | `""` | flavor text 或用途说明 | 物品详情面板 |
   | `equip_slot` | String | ✗ | `""` | Alpha 装备槽位标识 | 装备系统 slot 约束 |
   | `affix_pool_id` | String | ✗ | `""` | Alpha 词条池引用 | 词条/affix 生成系统 |
   | `discrete_instance` | bool | ✗ | `false` | 是否每件实例独立（带词条/耐久） | Alpha 装备实例系统 |
   | `meta` | Dictionary | ✗ | `{}` | ItemRegistry 不读取的扩展字段 | 任意后期扩展 |

3. **API 表面**（同步、无协程）：

   | 方法 | 返回 | 错误处理 | 用途 |
   |------|------|---------|------|
   | `get(id: String) → Dictionary` | ItemDefinition 的**深拷贝**副本；id 不存在返回 `{}` | 警告 | 单条查询，主链路 |
   | `has_item(id: String) → bool` | `true` / `false` | — | 防卫、调试 |
   | `peek_field(id: String, field: String) → Variant` | 单字段值；id 或字段不存在返回 `null`。**注意：标量字段（String/int/float/bool）by-value 安全；容器字段（Array/Dictionary）按 GDScript CoW 语义返回引用，调用方对返回容器执行 `.append()`/`.erase()` 等原地修改会污染 registry 内部状态——必须先 `.duplicate()` 或改用 `get(id).field`** | 不打印警告 | 高频单字段查询 **[UNSAFE for containers — see §Edge Cases E]** |
   | `get_all_ids() → Array[String]` | 所有 id 数组（拷贝） | — | 调试、工具、迭代 |
   | `get_count() → int` | 已加载条目数 | — | 加载断言、调试 |
   | `query_by_item_class(cat: String) → Array[Dictionary]` | 匹配条目**深拷贝**数组；无匹配 `[]` | 非锁定 cat 打印警告 | 掉落系统/HUD 分类筛选 |
   | `query_by_tag(tag: String) → Array[Dictionary]` | 匹配条目**深拷贝**数组；无匹配 `[]` | — | 掉落过滤、合成食谱匹配 |
   | `reload() → void` | — | 仅 debug 生效；否则 no-op | 热重载（开发期） |
   | `set_data_config(dc: Object) → void` | — | — | 测试时注入替代 DataConfig（Object 或兼容 mock）；传入 `null` 模拟 Autoload 缺失场景 |
   | `is_loaded() → bool` | `_ready()` 完成且 `_items` 至少尝试过加载（成功或降级为空均算）后返回 `true` | — | **Autoload 时序解药**：场景内节点（如 HUD）的 `_ready()` 在 Autoload 之后执行，订阅 `item_registry.loaded` 事件时该事件可能已发布过。下游节点在 `_ready()` 中应**先订阅后检查**（防止 TOCTOU 竞态——先 `subscribe` 保证不丢事件，后 `is_loaded()` 处理已就绪情况）：`EventBus.subscribe("item_registry.loaded", _on_item_registry_loaded); if ItemRegistry.is_loaded(): _on_item_registry_loaded(ItemRegistry._last_loaded_payload)`，避免错过信号 |

   所有返回 Dict / Array of Dict 的接口均执行 `.duplicate(true)` 深拷贝，确保调用方意外修改不污染 registry 内部状态。

4. **加载流程**（启动时一次性）：
   - (a) Autoload 顺序保证 DataConfig 已就绪
   - (b) `_ready()` 调 `DataConfig.get_all("items")` 取 raw Dict
   - (c) 逐条校验：
     - `id` 非空且唯一（重复跳过+警告）
     - `item_class` 在 4 元锁定枚举内（不在则跳过+警告，避免 typo）
     - `name` 非空（缺失跳过+警告——违反 fantasy 承诺）
     - `rarity` 在 8 元锁定枚举内（不在则降级为 `"fanpin"`+警告）
     - 缺失可选字段填默认值，多余字段保留
   - (d) 加载完成后打印摘要：总条目数、各 item_class 计数
   - (e) 可选发布 `item_registry.loaded` 事件，payload schema 严格定义为：`{count: int, item_classes: Dictionary[String, int]}`，其中 `count == _items.size()`，`item_classes` 的 key 为 4 元锁定枚举字符串、value 为该 item_class 已加载条目数（例：`{count: 5, item_classes: {"resource_material": 5}}`）。**payload 中的 `item_classes` 是加载完成时的浅拷贝临时统计 Dict（非 `_items` 内部引用）；订阅者读取后不应持有引用，重载时该 Dict 会被新实例替换。**

5. **查询语义与不变量**：
   - **只读承诺**：所有公共接口不修改 `_items`；调用方拿到深拷贝副本
   - **零值返回**：id 不存在/item_class 非法/tag 无匹配时返回 `{}` / `[]` / `false` / `null`，从不抛异常（与 ResourceSystem/DataConfig 一致）
   - **MVP 即时扫描**：`query_by_item_class` / `query_by_tag` 用 O(N) 扫描；预构建倒排索引推迟到 Alpha（代码注释建议标记为 `# Alpha: build inverted index when item count > 50`，避免把已知后续优化误判为未完成占位）
   - **id 命名空间共享**：本系统 `id` 与 ResourceSystem `resource_id` 共享命名空间——同一 `"herb"` 在 items.json 和 resource_config.json 中各自有字段（前者管 metadata，后者管账本）；**本系统不校验** id 是否在 ResourceSystem 中存在（解耦）

6. **数据校验与错误处理**（启动时静默降级，不崩溃）：
   - `id` 缺失/空：跳过 + 警告
   - `id` 重复（items.json 内）：后者覆盖前者 + 警告（DataConfig 也会先警告一次）
   - `item_class` 非法：跳过 + 警告（不容忍 typo）
   - `name` 缺失：跳过 + 警告（违反 fantasy 承诺）
   - `rarity` 非法：降级为 `"fanpin"` + 警告（容忍降级）
   - JSON 解析失败/items.json 不存在：DataConfig 已处理；本系统 `_items` 为空，所有查询返回零值

7. **运行时不可变性**：不支持 register/unregister/set_ 等运行时写入接口（与 ResourceSystem 不同——后者持有玩家可变状态）。运行时若需新增物品类型：(a) 修改 items.json (b) 重启游戏 / 调 `reload()`。这与游戏概念 §4.10"数据驱动与可扩展"一致：扩展通过配置而非代码。

8. **热重载约束**：
   - `reload()` 仅在 `OS.is_debug_build() == true` 时执行
   - 流程：清空 `_items` → `DataConfig.reload_table("items")` → 重新执行加载流程
   - 若 DataConfig `HOT_RELOAD_ENABLED == false`：静默 no-op + 提示
   - 重载完成后可选发布 `item_registry.reloaded` 事件
   - **已知风险**：若热重载移除了某 id 而 ResourceSystem 已持有该 id 的非零 current → ResourceSystem 不受影响（账本独立），但 HUD 显示 metadata 时会拿到 `{}`，可能显示为空名称。开发期可接受，生产构建禁用 reload 即可规避。

9. **职责非依赖**（明确不做的事）：
   - 不调 ModifierEngine（无任何加成需要叠加）
   - 不调 FormulaEngine（无任何公式需要计算）
   - 不调 EventBus.emit（无玩家状态变化需要广播；可选 loaded/reloaded 是 lifecycle 事件不算业务事件）
   - 不持有玩家库存数量
   - 不参与 SaveSystem.register_provider（无玩家状态需要存档）
   - 不做引用完整性校验（如 `equip_slot` 是否对应有效槽位定义；属于 Alpha 装备系统职责）

10. **物品 ID 命名约定**：`snake_case`，全局唯一。MVP 沿用 ResourceSystem 已用的 `lingqi/xiuwei/lingshi/herb/exp`（无前缀）；**Alpha 新增 id 建议加分类前缀**（`eq_/con_/qst_`）以避免与 resource id 视觉冲突。本系统不强制此约定，由 items.json 维护方自律。

### States and Transitions

ItemRegistry 整体无状态机——纯只读注册服务。内部存在两种运行时状态（与 DataConfig 同模式）：

| 状态 | 判定 | 含义 |
|------|------|------|
| Unloaded | `_items.is_empty()` 且 `_ready()` 未完成 | 刚创建，索引为空，所有查询返回零值 |
| Loaded | `_ready()` 已完成 | 索引已构建，查询服务可用 |

热重载（`reload()`）期间短暂回到 Unloaded（清空索引）然后回到 Loaded，对外不暴露此瞬态——查询在 reload() 调用线程内完成，无并发问题（GDScript 主线程模型）。

### Interactions with Other Systems

| 系统 | 方向 | 数据接口 | 说明 |
|------|------|---------|------|
| 数据配置系统 | 上游硬依赖 | `DataConfig.get_all("items") → Dictionary` 取 raw 物品记录 | 启动加载、热重载入口 |
| 资源系统 | **边界协作** | 共享物品 id 命名空间；ResourceSystem 管账本（数量），ItemRegistry 管命名（metadata）。两者互不调用对方 | 同一 `"herb"` id 在 resource_config.json 和 items.json 中各自有字段；本系统**不校验** id 是否在 ResourceSystem 中存在（解耦） |
| 大数值系统 | 无直接关联 | — | 本系统不存储任何 BigNumber 字段（Alpha 阶段若加 `value_lingshi` 价格字段时再接入；MVP 不需要） |
| 事件总线 | 上游可选发布 | 可选发布 `item_registry.loaded` / `item_registry.reloaded`（lifecycle 事件） | 不发布业务事件（无玩家状态变化） |
| 修正器/倍率引擎 | 无关联 | — | 不调 apply()，无加成叠加需求 |
| 公式引擎 | 无关联 | — | 不调 evaluate()，无公式计算需求 |
| 存档系统 | 无关联 | — | 不注册 provider，无玩家状态需持久化 |
| 掉落系统 | 下游 → 主动调用 | `ItemRegistry.query_by_tag(tag)` / `get(id)` 获取掉落物 metadata | 掉落系统用 metadata 决定 UI 提示稀有度颜色，然后 `ResourceSystem.add(id, qty)` 入账 |
| HUD 系统 | 下游 → 主动调用 | `ItemRegistry.get(id)` 获取 name/icon_path/rarity 等显示信息 | 资源栏物品图标、拾取提示、未来背包面板 |
| 物品图鉴系统（Post-MVP） | 下游 → 主动调用 | `query_by_item_class()` / `get_all_ids()` 列出已发现物品 | 图鉴框架 |
| 半自动战斗系统 | 下游 → 间接 | 通过掉落系统间接消费 | 不直接调 ItemRegistry |
| 调试控制台 | 下游 → 主动调用 | `get_all_ids()` / `get(id)` 列举/查询所有物品 | 调试工具 |

## Formulas

> 本系统是纯只读查询服务，无游戏机制公式。下列 5 条为性能模型公式，用于估算 MVP/Alpha 规模下的耗时和内存占用，指导是否需要在 Alpha 加倒排索引。

### 1. 单次 get(id) 耗时 (Single Get Cost)

**命中路径**：`get_time_hit(id) = t_dict_lookup + t_duplicate`
**Miss 路径**（id 不存在）：`get_time_miss(id) = t_dict_lookup`（不执行深拷贝，直接返回 `{}`）

**变量：**
| 变量 | 符号 | 类型 | 范围 (ms) | 影响因素 |
|------|------|------|-----------|---------|
| Dictionary 主索引查找 | t_dict_lookup | float | [0.001, 0.005] | Godot 4 Dictionary 哈希查找 O(1) |
| 深拷贝 14 字段 ItemDefinition | t_duplicate | float | [0.005, 0.030] | 上限取决于 `tags` 数组长度和 `meta` 嵌套深度（Godot 4 `duplicate(true)` 对扁平 Dict ~0.003–0.010 ms；含嵌套时升至 0.030 ms）。**未建模上限**：tags 长度 > 50 或 meta 嵌套 > 5 层时实测可能超过 0.030 ms 上界，Alpha 阶段需补 benchmark |

**输出范围：** 命中 [0.006, 0.035] ms；miss [0.001, 0.005] ms。

**示例（命中）：** id=`"herb"`, tags=2 项, meta={} → `0.002 + 0.008 = 0.010 ms`
**示例（miss）：** id=`"nonexistent"` → `0.002 ms`

### 2. 单次 peek_field(id, field) 耗时 (Field Get Cost)

`field_time = t_dict_lookup × 2`

**变量：**
| 变量 | 符号 | 类型 | 范围 (ms) | 说明 |
|------|------|------|-----------|------|
| Dictionary 嵌套查找 | t_dict_lookup | float | [0.001, 0.005] | 外层 `_items[id]`，内层 `record[field]` |

**输出范围：** [0.002, 0.010] ms。

**关键语义**：返回值为 Variant 原始引用（String / Array 等共享底层），**无深拷贝**——比 `get(id)` 快 3–10 倍。**调用方约定不得修改返回值**（与 Section C Rule 5 "只读承诺" 一致）。高频单字段查询（如 HUD 每帧拉取 `name`）应优先用此 API。

### 3a. query_by_item_class 耗时（O(N) 即时扫描，O(1) 比较）

`class_query_time = N × (t_dict_access + t_str_eq) + M × t_duplicate`

**变量：**
| 变量 | 符号 | 类型 | 范围 |
|------|------|------|------|
| 已加载物品数 | N | int | [5, 1000] |
| 单次访问 | t_dict_access | float | [0.001, 0.002] ms |
| 字符串等值比较 | t_str_eq | float | [0.0005, 0.001] ms（O(1) — Godot StringName 哈希比较） |
| 匹配条数 | M | int | [0, N] |
| 深拷贝单条 | t_duplicate | float | [0.005, 0.030] ms |

**输出范围：**
- **MVP** (N=5, M=5)：`5 × 0.0025 + 5 × 0.015 = 0.0875 ms`
- **Alpha 典型** (N=500, M=50)：`500 × 0.0025 + 50 × 0.015 = 2.0 ms`
- **Alpha 最坏** (N=500, M=500)：`500 × 0.0025 + 500 × 0.015 = 8.75 ms`（半帧）—— **必须在 Alpha 实施倒排索引前控制 N，否则单次调用接近半帧预算**

### 3b. query_by_tag 耗时（O(N × T) — 比较是数组 contains 而非等值）

`tag_query_time = N × (t_dict_access + T_items × t_str_eq) + M × t_duplicate`

**变量：**
| 变量 | 符号 | 类型 | 范围 |
|------|------|------|------|
| 已加载物品数 | N | int | [5, 1000] |
| 单次访问 | t_dict_access | float | [0.001, 0.002] ms |
| 单条 item 的 tags 数组平均元素数（非搜索 tag 的字符串长度） | T_items | int | [0, 50] |
| 单次字符串比较 | t_str_eq | float | [0.0005, 0.001] ms |
| 匹配条数 | M | int | [0, N] |
| 深拷贝单条 | t_duplicate | float | [0.005, 0.030] ms |

**输出范围：**
- **MVP** (N=5, T=2, M=5)：`5 × (0.002 + 2 × 0.001) + 5 × 0.015 = 0.095 ms`
- **Alpha 典型** (N=500, T=5, M=50)：`500 × (0.002 + 5 × 0.001) + 50 × 0.015 = 4.25 ms` —— **超过帧预算 10% 阈值（16.67 × 10% = 1.667 ms）2.5 倍**
- **Alpha 最坏** (N=500, T=10, M=500)：`500 × (0.002 + 10 × 0.001) + 500 × 0.015 = 13.5 ms` —— **接近 1 帧**

**性能合同**：MVP 阶段（N=5）所有 query 在帧预算内可忽略；Alpha 阶段（N>50）必须实现倒排索引（`tags → Array[id]` 反向映射）将 tag_query_time 降为 O(M)，否则 HUD/掉落系统单帧多次调用会丢帧。**`INVERTED_INDEX_THRESHOLD` 已升级为运行时软门槛**（Tuning Knobs 详细说明）：加载完成后 `if get_count() > THRESHOLD and not _has_inverted_index: push_warning(...)`。

**附注 — `get_all_ids()` 临时分配开销**：`get_all_ids()` 调用 `_items.keys()` 返回 N 元素 StringName Array 拷贝，N=500 时临时分配 ~30 KB。**严禁在 `_process` / `_physics_process` 内调用**（60 fps × 30 KB = 1.8 MB/秒分配，触发 GC 周期性 2-5 ms 卡顿）；图鉴系统应在 `item_registry.loaded` 事件回调中缓存结果。`get_count()` 是 Dict.size() O(1)，无分配。

### 4. 启动加载耗时 (Load Time)

`load_time = t_dataconfig_get + N × (t_validate + t_index)`
`reload_time = t_clear(N) + load_time + t_json_io + t_event_dispatch`（含清空旧索引 + 重加载 + JSON I/O + 事件投递）

**变量：**
| 变量 | 符号 | 类型 | 范围 (ms) | 说明 |
|------|------|------|-----------|------|
| 从 DataConfig 取已加载 Dict | t_dataconfig_get | float | [0.001, 0.010] | DataConfig.get_all() 是 Dictionary 引用传递（O(1)）；主耗时不在此处 |
| 单条 schema 校验 | t_validate | float | [0.005, 0.020] | id/item_class/name/rarity 校验 + 默认值填充 |
| 单条索引写入 | t_index | float | [0.001, 0.005] | 写入 `_items[id]` |
| 清空旧索引 | t_clear(N) | float | N × [0.0005, 0.002] ms | reload 时 `_items.clear()`，O(N) 释放 |
| JSON 文件 I/O + 解析（`DataConfig.reload_table`） | t_json_io | float | [2, 13] ms | DataConfig 域，非本系统可控；首次加载受 OS 页缓存影响，热缓存显著更快；含 `FileAccess.get_file_as_string()` + `JSON.parse()`；500 条物品 JSON 约 50-100 KB |
| 事件投递（`item_registry.reloaded`） | t_event_dispatch | float | [0, 10] | 取决于下游订阅者数量与回调耗时；HUD 500 条缓存重建（每条 3 次 `peek_field` + UI 结构创建）预估 ~8 ms |

**输出范围：**
- **MVP load** (N=5)：`0.005 + 5 × 0.013 + 5 × 0.003 ≈ 0.09 ms`
- **MVP reload** (N=5)：`5 × 0.001 + 0.09 + 0.05 ≈ 0.15 ms`
- **Alpha load** (N=500)：`0.005 + 500 × 0.013 + 500 × 0.003 ≈ 8.0 ms`，单帧内可完成
- **Alpha reload** (N=500)：`500 × 0.001 + 8.0 + 8（t_json_io 中位）+ 8（t_event_dispatch 中位）≈ 24.5 ms`（上限：`0.5 + 8.0 + 13 + 10 = 31.5 ms`）—— **约 1.5-2 帧预算**，调试期会感知到明显卡顿；**强烈建议**通过 `call_deferred("reload")` 调度避免在帧内叠加其他处理开销，或在 Alpha 阶段实现分帧加载（每帧处理 N/8 条）。

### 5. 内存占用 (Memory Footprint)

`memory = base_overhead + N × per_item_size`

**变量：**
| 变量 | 符号 | 类型 | 范围 (bytes) | 说明 |
|------|------|------|-------------|------|
| ItemRegistry 服务对象基础开销 | base_overhead | int | ~200 | RefCounted + 主索引 Dict 头 |
| 单条 ItemDefinition 大小 | per_item_size | int | ~500（MVP 空 meta）→ ~1200（Alpha 满 meta） | 14 字段 + Dict 结构开销 + 可变字段 |

**输出范围：**
- **MVP** (N=5)：`200 + 5 × 500 ≈ 2.7 KB`
- **Alpha 一般** (N=500, 平均 meta)：`200 + 500 × 700 ≈ 350 KB`
- **Alpha 满 meta** (N=500, 满 meta)：`200 + 500 × 1200 ≈ 600 KB`

均远低于 512 MB 内存预算（`< 0.12%`）。本系统的内存占用可视为可忽略量级。

## Edge Cases

> 本系统的 edge cases 主要围绕**配置校验**、**查询零值**、**启动时序**、**热重载副作用**、**深拷贝陷阱**和**跨系统边界**展开。运行时无玩家状态变化，故无业务事件类边界。

### A. 加载与配置校验

- **If items.json 不存在 / 为空 / JSON 解析失败**：DataConfig 层已处理（打印错误）；本系统 `_items` 为空，所有查询正常返回零值。游戏不崩溃。
- **If items.json 内某条 `id` 字段缺失或为空字符串**：跳过该条 + 警告。
- **If items.json 内 `id` 重复（同一 items.json 中）**：后者覆盖前者 + 警告。注意 DataConfig 也会先警告一次（双重警告，便于追溯）。
- **If `item_class` 不在 4 元锁定枚举内**（typo 如 `"resource_materail"`）：跳过该条 + 警告。**不容忍降级**——typo 会导致 query 永远查不到，必须显性失败。
- **If `name` 缺失或为空字符串**：跳过该条 + 警告。**违反 Player Fantasy 承诺**（每个物品都有名字），必须拒绝注册。
- **If `rarity` 不在 8 元锁定枚举内**：降级为 `"fanpin"` + 警告。**容忍降级**——稀有度的拼错不影响查询路径，HUD 仍能显示。
- **If `tags` 字段不是 Array（如填了 String 或 null）**：视为 `[]` + 警告。
- **If `icon_path` 指向不存在的资源**：本系统**不校验**——交给 HUD 的占位图机制（HUD 加载失败时显示通用 placeholder.png）。
- **【关键】If Autoload 顺序失败（DataConfig 排在 ItemRegistry 之后 / DataConfig 被禁用）**：`ItemRegistry._ready()` 调用 `DataConfig.get_all("items")` 时 DataConfig 实例不存在 → GDScript 对空引用调方法**会崩溃**。**规则**：`_ready()` 入口必须先做防御性检查 —— `if not DataConfig: push_error("ItemRegistry: DataConfig autoload missing or unavailable; falling back to empty registry"); _items = {}; return`。**不使用 `assert`**：assert 在 release build 会被剥离、在 debug 会触发中止执行，二者都无法满足"降级运行不崩溃"的语义；只有显式条件分支 + `push_error` + `return` 才能在所有 build 配置下提供一致的降级行为。

### B. 查询零值返回

- **If `get(id)` 中 id 不存在**：返回 `{}` + 警告。
- **If `has_item("")` 空字符串 id**：返回 `false`，不警告（正常路径，调用方可能在做防御性检查）。
- **If `query_by_item_class("")` 或 cat 不在锁定枚举内**：返回 `[]` + 警告（违反枚举约束）。
- **If `query_by_item_class(cat)` 合法 cat 无匹配**（如 MVP 阶段查 `"equipment"`）：返回 `[]`，不警告（合法但当前数据集为空）。
- **If `query_by_tag(any)` 无匹配**：返回 `[]`，不警告（tags 是开放集，无效 tag 即为正常的空查询）。
- **`query_by_tag` 语义为数组元素精确等值匹配**：若 `record.tags = ["herb","low_tier"]`，`query_by_tag("herb")` 会匹配（`record.tags.has("herb")`，精确字符串 `==` 比较，**非子串 `.contains()` 匹配**——`"herb"` 不会匹配 `tags=["superherb"]`）。GDD 不提供"精确匹配整个 tags 数组"的接口；如需精确匹配，调用方自行 `query_by_tag` 后过滤。
- **If `peek_field(id, field)` 中 id 或 field 任一不存在**：返回 `null`，不打印警告（字段缺失可能是正常业务逻辑）。

### C. 启动时序

- **If `_ready()` 完成前外部代码调用 query**：`_items` 为 `{}`，所有查询返回零值。不崩溃，但调用方拿到的结果与"id 真不存在"无法区分。
- **【关键】If 存档恢复期间 ItemRegistry 尚未就绪**：SaveSystem 恢复 ResourceSystem 时，HUD 可能被触发显示资源条 → 调用 ItemRegistry.get(id) 显示 metadata。若 ItemRegistry._ready() 尚未完成，HUD 拿到 `{}` 后**显示空名**且永远不重试。**规则**：ItemRegistry 在 `_ready()` 完成后发布 `item_registry.loaded` 事件（payload `{count, item_classes}`）；依赖 metadata 显示的下游系统在首次收到此事件前应缓存待显示队列、避免直接渲染。

### D. 热重载

- **If `reload()` 在 `_ready()` 完成前（Unloaded 状态）被调用**：no-op + 警告 `"reload called before initial load complete"`。`_items` 不变（仍为空）。debug 模式下可手动触发，但初始加载未完成时重载无意义。
- **If `reload()` 在生产构建（`OS.is_debug_build() == false`）调用**：no-op + 提示 `"reload disabled in release build"`。
- **If `reload()` 时 `DataConfig.HOT_RELOAD_ENABLED == false`**：no-op + 提示。
- **If reload 后某 id 消失而 ResourceSystem 仍持有该 id 的非零 current**：ResourceSystem 不受影响（账本独立）；HUD 显示 metadata 时拿到 `{}`，显示空名。**reload 完成后必须 push_warning 列出差分**：`var disappeared = old_ids - new_ids; if not disappeared.is_empty(): push_warning("ItemRegistry.reload: ids disappeared from registry: %s — downstream HUD/loot may show empty names" % str(disappeared))`。**开发期可接受**——生产构建禁用 reload 即规避；但差分提示让开发者立即定位 items.json 删改导致的 HUD 空名。
- **If reload 后某 id 的 item_class 改变**：下次 `query_by_item_class` 反映新分类，无缓存陷阱（MVP 不预构建索引）。

### E. 拷贝陷阱（关键 API 契约）

- **If 调用方修改 `get(id)` 返回的 Dict**：registry `_items` 不受影响（深拷贝 `.duplicate(true)` 防护）。
- **【关键】If 调用方对 `peek_field()` 返回的容器字段（Array/Dictionary）执行写操作（如 `tags.append()` / `meta["k"] = v`）**：**会直接污染 `_items[id]` 的底层数据**。原因：GDScript 4.x 的 Array/Dictionary 是**引用类型**（非 Godot 3.x CoW），`peek_field` 返回容器字段时直接返回内部数据的引用，无任何拷贝。调用方对返回值执行的任何原地修改（`.append()` / `.erase()` / `[k]=v`）都会直接污染 `_items` 内部状态。
  - **调用方约定**：标量字段（String/int/float/bool）— 写入安全；**容器字段（`tags`/`meta`）— 必须先 `.duplicate()` 再修改**。
  - **实现层安全措施**：`peek_field` 对容器字段（检测 `typeof(result) == TYPE_ARRAY or typeof(result) == TYPE_DICTIONARY`）在返回前执行 `.duplicate(false)` 浅拷贝（阻断写穿透，开销可忽略）；标量字段直接返回原值。调用方如需嵌套容器的完全隔离仍应使用 `get(id).field`（深拷贝路径）。
- **If 调用方修改 `query_by_*` 返回的 Array 中的某条 Dict**：registry 不受影响（数组中每条都是深拷贝副本）。

### F. 跨系统边界

- **If items.json 与 resource_config.json 中的 id 集合不一致**（如 ItemRegistry 有 `"herb"` 而 ResourceSystem 没有，或反之）：各自独立运行，互不报错。HUD 试图显示 ItemRegistry 中无定义的 id 时拿到 `{}`，UI 用占位/空名 fallback。**这是设计中的解耦特性，不是缺陷**——允许两份配置在 Alpha 阶段错位演进（如先在 items.json 定义新装备 metadata、ResourceSystem 不需感知）。
- **【debug 启动期建议】id 命名空间一致性 warning**：MVP 阶段 5 条 resource_material id 与 ResourceSystem 5 条 resource_id 强一一对应，运行时无 id 错位的合理理由。建议在 debug build 启动期（两个系统 `loaded` 事件均到达后）由独立的"启动校验器"调用 `_check_id_consistency_with_resource_system()`：`var only_in_item = item_ids - res_ids; var only_in_res = res_ids - item_ids; if not only_in_item.is_empty() or not only_in_res.is_empty(): push_warning(...)`。**ItemRegistry 自身不实现该校验**（保持解耦），由调试控制台或独立的 startup-checker 系统负责；本 GDD 仅约定 Open Questions 中。Alpha 阶段允许真错位时，可关闭此 warning。
- **If `meta` 字段含循环引用**：理论上 `duplicate(true)` 会无限递归崩溃。**本系统假设上游 DataConfig 已拦截循环引用**——GDScript JSON 解析器本身不会产生循环引用（Object 引用不可序列化），唯一风险是 DataConfig 后处理引入。本 GDD 不再额外校验，依赖于 DataConfig 的清洁性承诺。

## Dependencies

### 上游依赖

| 系统 | 依赖性质 | 数据接口 |
|------|---------|---------|
| **数据配置系统** (DataConfig) | 硬依赖 | 启动时调 `DataConfig.get_all("items") → Dictionary` 取得 raw 物品记录；热重载调 `DataConfig.reload_table("items")`。Autoload 顺序保证 DataConfig 先于本系统 `_ready()` 完成 |
| **事件总线** (EventBus) | 软依赖（可选） | 发布 `item_registry.loaded` / `item_registry.reloaded` 两个 lifecycle 事件，供下游确认就绪。**不发布任何业务变更事件** |

### 下游消费者

| 系统 | 调用方向 | 数据接口 | 备注 |
|------|---------|---------|------|
| **HUD 系统** | 主动调用 | 高频：`peek_field(id, "name"/"icon_path"/"rarity")`；低频：`get(id)` 整条获取 | HUD 在 `_process` 中应优先用 `peek_field`（无深拷贝）。**最优模式（约定）**：若 HUD 显示内容固定（如资源栏 5 条），应在 `item_registry.loaded` 事件回调中**一次性读取并本地缓存**所需字段（name / icon_path / rarity），避免每帧重复 `peek_field` 同 id 同 field。Alpha 规模下重复 peek 累积约 0.075 ms/帧（可忽略但可消除）。首次渲染前应通过 `is_loaded()` 同步检查 + `loaded` 事件订阅二选一确保不错过信号。 |
| **掉落系统** | 主动调用 | `query_by_tag(tag)` 过滤掉落候选；`get(id)` 获取 metadata 用于 UI 提示稀有度颜色，然后调 `ResourceSystem.add(id, qty)` 入账 | 掉落物图标和名称显示链路的中介 |
| **半自动战斗系统** | 间接消费 | 通过掉落系统间接使用本系统 | 不直接调本系统 API |
| **物品图鉴系统**（Post-MVP） | 主动调用 | `query_by_item_class("resource_material" / "consumable" / ...)`、`get_all_ids()` | 图鉴框架；`get_all_ids()` 应缓存结果，不在 `_process` 内调用 |
| **调试控制台** | 主动调用 | `get_all_ids()` + `get(id)` 列举/查询所有物品；`reload()` 触发热重载（仅 debug 模式） | 调试期高频路径 |

### 边界协作（无调用关系）

| 系统 | 关系 | 说明 |
|------|------|------|
| **资源系统** (ResourceSystem) | id 命名空间共享但**互不调用** | ResourceSystem 管账本（数量、cap、reset_scope），ItemRegistry 管命名（name、icon_path、rarity）。同一 `"herb"` id 在 resource_config.json 和 items.json 中各自有字段。两份配置可独立演进——本系统**不校验** id 是否在 ResourceSystem 中存在 |

### 关键非依赖（容易误以为是依赖但不是）

| 系统 | 关系 | 说明 |
|------|------|------|
| **大数值系统** (BigNumber) | **无直接关联** | 本系统 MVP 不存储任何 BigNumber 字段。Alpha 阶段若引入 `value_lingshi`（物品出售价格）等字段时再接入。**与 BigNumber GDD §Interactions 现有"物品/材料系统：物品价值、堆叠数量用 BigNumber"陈述不一致——需在 /consistency-check 阶段澄清**（改为"Alpha 阶段引入"或加注 MVP 不需要） |
| **修正器/倍率引擎** (ModifierEngine) | **无关联** | 不调 `apply()` / `get_multiplier()`；本系统无任何加成叠加需求 |
| **公式引擎** (FormulaEngine) | **无关联** | 不调 `evaluate()`；本系统无公式计算需求 |
| **存档系统** (SaveSystem) | **无关联** | 不注册 `register_provider()`；本系统不持有玩家状态，无需持久化 |

### 双向一致性自检（与上游/下游 GDD 对齐）

- ✅ **DataConfig GDD** §Interactions 列出"物品/材料系统 — `DataConfig.get_all("items")` 获取物品定义"——一致
- ✅ **DataConfig GDD** §Dependencies 列出"物品/材料系统 — 硬依赖"——一致
- ✅ **ResourceSystem GDD** §Interactions 列出"物品/材料系统 — 边界协作：可叠加同质化材料走 ResourceSystem，离散有词条/品质实体走 item 系统"——本 GDD 进一步澄清：MVP 不引入"离散有词条"实体（推迟到 Alpha），ResourceSystem 继续承担同质化材料的账本职责
- ⚠ **BigNumber GDD** §Interactions 列出"物品/材料系统 — 物品价值、堆叠数量用 BigNumber"——**与本 GDD 不一致**。本 GDD 明确 MVP 不存 BigNumber 字段。需在 `/consistency-check` 阶段更新 BigNumber GDD：将该行改为"物品/材料系统（Alpha 引入）— Alpha 阶段引入物品价格/价值字段时使用 BigNumber"
- ✅ **EventBus GDD** §Core Rules 12 命名空间约定已列入 `item_registry.loaded` / `item_registry.reloaded` 两个 lifecycle 事件（与 resource-system / attribute-system 同模式）。

### 上游依赖关系总览

```text
DataConfig ─→ ItemRegistry ─→ HUD
                         ─→ 掉落系统 ─→ ResourceSystem
                         ─→ 物品图鉴（Post-MVP）
                         ─→ 调试控制台
EventBus（可选） ←─ ItemRegistry  发布 loaded/reloaded
```

本系统是 Core Gameplay 层中的"语义桥梁"——上承 DataConfig 的 raw 配置，下供所有需要"物品名字 + 图标 + 稀有度"的系统使用。

## Tuning Knobs

物品/材料系统的可调参数分两类：**配置驱动参数**（per-item，由数据配置系统加载）和**引擎/调试参数**（编译期常量或开发模式专用）。

### 配置驱动参数（物品级别，per-item）

详见 Section C "ItemDefinition 数据模型" 表。简要总结调参边界：

| 参数 | 类型 | 默认值 | 安全范围 | 调整影响 |
|------|------|--------|---------|---------|
| `item_class` | enum String | 必填 | `{resource_material, consumable, equipment, quest}` | 决定该物品在哪些 `query_by_item_class` 调用中被命中；非锁定枚举值会被加载流程拒绝 |
| `rarity` | enum String | `"fanpin"` | `{fanpin, jingliang, xiyou, shishi, chuanshuo, shenhua, xiantian, hundun}` | 8 级稀有度；HUD 据此映射边框颜色（颜色 mapping 由 HUD GDD 定义）；非锁定枚举值降级为 `fanpin` 容忍降级 |
| `tags` | Array[String] | `[]` | 任意字符串集（开放枚举） | 决定 `query_by_tag` 命中范围；建议 tag 命名 `snake_case`、避免拼写漂移；空数组无任何 tag 命中 |
| `stack_limit` | int | `-1` | `[-1, 9999]` | **`-1` = 无限堆叠（MVP material 默认）**；`>= 0` 为具体上限（`0` 等同"禁用堆叠"），由背包/UI 系统执行槽位上限。本系统仅存储不强制。`stackable=false` 时被忽略 |
| `stackable` | bool | `true` | `{true, false}` | true 时表示同 id 可累加（MVP material 全部 true）；false 预留给 Alpha 离散装备实例（此时 `stack_limit` 被忽略） |
| `description` | String | `""` | 任意字符串（建议 ≤ 200 字符） | flavor text；过长会增加内存占用（per_item_size 上限） |
| `icon_path` | String | `""` | Godot `res://` 路径或 `""` | 空字符串 → HUD 用 placeholder.png；本系统不校验路径有效性 |

### 引擎/调试参数（全局，开发期或编译期常量）

| 参数 | 默认值 | 安全范围 | 增大影响 | 减小影响 |
|------|--------|---------|---------|---------|
| `WARN_ON_MISSING_ID` | `true` | {true, false} | id 不存在时打印警告，辅助调试 | 静默返回 `{}`，减少日志噪音（生产构建可关闭） |
| `WARN_ON_INVALID_ITEM_CLASS` | `true` | {true, false} | 非锁定 item_class 触发警告 | 静默跳过条目，减少日志噪音 |
| `WARN_ON_INVALID_RARITY` | `true` | {true, false} | 非锁定 rarity 触发警告（即使已降级） | 静默降级，减少日志噪音 |
| `WARN_ON_DUPLICATE_ID` | `true` | {true, false} | items.json 内 id 重复触发警告 | 静默"后覆盖前"（DataConfig 层仍会警告） |
| `WARN_ON_MISSING_NAME` | `true` | {true, false} | name 缺失触发警告并跳过 | 不推荐关闭——违反 fantasy 承诺 |
| `LOAD_SUMMARY_LOG` | `true` | {true, false} | 启动加载完成后打印总条目数 + 各 item_class 计数摘要 | 静默加载，减少启动日志 |
| `EMIT_LIFECYCLE_EVENTS` | `true` | {true, false} | 启动后发布 `item_registry.loaded`；reload 后发布 `item_registry.reloaded` | 关闭后下游系统无法通过事件感知就绪状态——HUD 必须自行轮询 `get_count() > 0` |
| `INVERTED_INDEX_THRESHOLD` | `50` | `[10, 1000]` | **MVP 软门槛**：加载完成后若 `get_count() > THRESHOLD` 且 `_has_inverted_index == false`，发布 `push_warning("ItemRegistry: item count %d exceeds index threshold %d — Alpha must implement inverted index" % [get_count(), THRESHOLD])`。**MVP 不实现倒排索引本身**，但软门槛保证 Alpha 数据集触碰阈值时立即可见。Alpha 实施后该常量驱动实际索引切换 | 阈值越低越早切换索引/越早警告，但小规模下索引构建开销可能盖过收益 |
| `RELOAD_DEBUG_ONLY` | `true` | {true, false} | `reload()` 仅 `OS.is_debug_build() == true` 时执行 | 关闭后生产构建也允许 reload；**强烈不推荐**，开发漏洞可能导致玩家触发重载副作用（HUD 显示空名等） |

### 设计师 vs 开发者调参边界

- **配置驱动参数** 通过 `items.json` 修改，由**数值/内容设计师**调整。新增物品类型、调整稀有度、追加标签都不需要改代码——追加 JSON 记录即生效（重启或 `reload()`）
- **引擎/调试参数** 是项目级常量或开发模式开关，由**开发者**在实现阶段设定，运行时不应动态修改
- **物品名字（name）和 description** 虽属配置驱动，但其修真叙事调性由 `narrative-director` / `world-builder`（Post-MVP 接入）把关；MVP 阶段由系统作者直接命名 5 条材料

### 与依赖系统的调参分工

| 调参对象 | 负责系统 | 说明 |
|---------|---------|------|
| 物品 metadata（name/icon_path/item_class/rarity/tags） | 本系统（items.json） | 元数据集中维护 |
| 物品玩家持有数量（current/cap） | 资源系统（resource_config.json + 存储上限系统） | 本系统不持有数量参数 |
| 物品掉落概率/权重 | 掉落系统（loot_tables.json） | 本系统不持有掉落参数；只提供 `tags` 供掉落表过滤 |
| 物品稀有度颜色映射 | HUD 系统 | 本系统只存储 rarity 枚举字符串；颜色 mapping 是 HUD 渲染层职责 |
| 本地化文案 | 本地化系统（Post-MVP） | 本系统只存储 `localization_key`，实际翻译由本地化系统加载 |

## Visual/Audio Requirements

本系统作为**纯元数据查询服务**，不拥有任何视觉或音频资产。它通过 `icon_path` 字段引用图标资产、通过 `rarity` 枚举字符串供 HUD 映射颜色——**实际渲染、动画、音效全部由下游系统承担**。

### 本系统建立的资产约束

| 约束 | 内容 | 兑现方 |
|------|------|-------|
| 物品图标资产路径格式 | `res://assets/icons/items/<item_id>.png`（推荐惯例；本系统不强制） | items.json 维护方 + 美术 |
| 物品图标尺寸/格式 | 由 HUD GDD 定义（推荐 64×64 PNG），本 GDD 不约定 | HUD GDD |
| 稀有度颜色映射 | 8 元枚举 → RGB 颜色由 HUD GDD 定义；本系统只存储 `rarity` 字符串 | HUD GDD |
| 拾取/掉落动画与音效 | 不在本系统职责内；由掉落系统 GDD 定义触发条件，HUD GDD 定义视觉表现 | 掉落系统 GDD + HUD GDD |
| 物品图鉴/百科视觉框架 | Post-MVP 物品图鉴系统 GDD 承担 | 物品图鉴 GDD（Post-MVP） |

### 非职责声明

本系统不调用任何 `AudioStreamPlayer` / `AnimationPlayer` / `Tween`，不持有任何 `Texture` / `AudioStream` 资源引用。它只持有**字符串路径**（`icon_path`），由消费方按需 `load()`。这与 ResourceSystem / AttributeSystem 的"无视觉/音频职责"模式一致。

> **📌 Asset Spec 标记**：本节当前为边界声明而非具体资产清单。MVP 5 条物品的图标资产将在 `/asset-spec system:item-material-system` 阶段（art bible 通过后）批量生成。

## UI Requirements

本系统**无直接 UI 表面**——没有自己的菜单、面板、HUD 元素。它作为元数据查询服务被多个 UI 系统消费：

| UI 系统 | 消费方式 | UI 责任归属 |
|---------|---------|------------|
| HUD 系统（资源栏） | 调 `peek_field(id, "name"/"icon_path")` 渲染顶栏物品图标 | HUD GDD |
| 掉落提示气泡（"获得：灵草 ×12"） | 掉落系统调 `get(id)` → 拼接 name/rarity → 调 HUD 弹出气泡 | 掉落系统 GDD + HUD GDD |
| 资源详情 tooltip | HUD 调 `get(id)` → 显示 name/rarity/description | HUD GDD |
| 物品图鉴/百科（Post-MVP） | 调 `query_by_item_class()` / `get_all_ids()` → 渲染图鉴页 | 物品图鉴 GDD（Post-MVP） |
| 调试控制台 | 调 `get_all_ids()` + `get(id)` 列举/查看 | 调试控制台 GDD |

### 本系统对消费方的约束

- **加载就绪事件**：`item_registry.loaded` 在 `_ready()` 完成后发布，UI 应在收到此事件前缓存待显示队列、避免渲染空名（见 §Edge Cases C 项）。
- **占位资产 fallback**：当 `peek_field(id, "icon_path") == ""` 或资源加载失败时，HUD 应使用 `res://assets/icons/items/_placeholder.png` 占位（路径由 HUD GDD 约定）。
- **空名 fallback**：若 `get(id) == {}`（id 未注册），HUD 应显示 `<unknown:item_id>` 而非空字符串——便于调试期定位配置缺失。

### 非职责声明

本系统不创建 `Control` 节点、不发射输入事件、不参与场景树。所有 UI 交互、布局、皮肤主题由 UI 框架 GDD + 各消费 UI GDD 承担。

> **📌 UX Flag — 物品/材料系统**: 本系统无独立 UI 表面，**不需要单独的 UX spec**。所引用的 UI 元素（资源栏图标、掉落气泡、tooltip）应在 HUD GDD 完成后通过 `/ux-design hud` 统一设计。

## Acceptance Criteria

> **测试类型路由**：A/B/C/D/F/G/I 组为 **Logic**（GDUnit4 单元测试，BLOCKING）；E/H 组为 **Integration**（涉及 Autoload/EventBus，BLOCKING）。

### A. 加载与配置（11 条）

**Fixture 策略**：本组所有 AC 通过 `set_data_config(mock_dc)` 注入 mock DataConfig，**不依赖真实 items.json 文件 I/O**。建议在 `tests/helpers/registry_factory.gd` 提供 `build_mock_data_config(items: Dictionary) -> MockDataConfig` 工厂方法，由各测试用例传入预制 items dict 调用。

- [ ] **AC-A1** GIVEN items.json 含 5 条 MVP material（lingqi/xiuwei/lingshi/herb/exp），各含必填字段，WHEN 启动完成，THEN `get_count() == 5` 且 `get_all_ids()` 返回这 5 个 id 集合
- [ ] **AC-A2** GIVEN ItemRegistry 已加载，WHEN `get("herb")`，THEN 返回 Dictionary 含 `name == "药材"`、`item_class == "resource_material"`、`rarity == "fanpin"`、`tags` 至少含 `"herb"`
- [ ] **AC-A3** GIVEN items.json 含某条记录省略 `description`/`stack_limit`/`stackable`，WHEN 加载，THEN 三字段填默认值（`""`/`-1`/`true`）—— `stack_limit=-1` 表示无限堆叠（详见 §Detailed Design Core Rules #2）
- [ ] **AC-A4** GIVEN items.json 含 `item_class="unknown_cat"` 的非法记录，WHEN 加载，THEN 该条不在 `_items` 中 + 警告，其他记录正常加载
- [ ] **AC-A5** GIVEN items.json 含 `name=""` 的记录，WHEN 加载，THEN 该条被跳过 + 警告
- [ ] **AC-A6** GIVEN items.json 含 `rarity="unknown_rarity"` 的记录，WHEN 加载，THEN rarity 降级为 `"fanpin"` + 警告，条目仍被注册
- [ ] **AC-A7** GIVEN items.json 同一 id 出现两次，WHEN 加载，THEN 后者覆盖前者 + 警告（DataConfig 也会先警告一次）
- [ ] **AC-A8a** GIVEN mock `DataConfig.get_all("items")` 返回 `{}`（模拟 items.json 文件不存在的降级路径——DataConfig 已在自己 layer 处理），WHEN ItemRegistry `_ready()` 完成，THEN `_items=={}`、`get_count()==0`、所有查询返回零值，不崩溃
- [ ] **AC-A8b** GIVEN mock `DataConfig.get_all("items")` 返回 `null`（模拟 JSON 解析失败的降级路径），WHEN ItemRegistry `_ready()` 完成，THEN `_items=={}`、`get_count()==0`、所有查询返回零值，不崩溃，触发 `push_warning("ItemRegistry: DataConfig returned null for items table")`
- [ ] **AC-A9** GIVEN items.json 含某记录 `tags=null` 或 `tags="herb"`（非 Array），WHEN 加载，THEN tags 降级为 `[]` + 警告，条目仍被注册
- [ ] **AC-A10** 参数化测试 — GIVEN mock items 含 8 条记录，每条 `rarity` 分别为 `fanpin / jingliang / xiyou / shishi / chuanshuo / shenhua / xiantian / hundun`，其余字段（id/name/item_class）合法且各异，WHEN 加载，THEN `get_count() == 8` 且对每条记录 `peek_field(id, "rarity")` 返回 items.json 输入的原值（无降级）。**目的**：防止 8 元枚举校验列表的拼写漏洞（如把 `xiantian` 拼为 `xiātian` 或漏掉 `hundun`）静默失效

### B. 查询 API（12 条）

- [ ] **AC-B1** GIVEN ItemRegistry 已加载，WHEN `has_item("herb")`，THEN `true`，无警告
- [ ] **AC-B2** GIVEN ItemRegistry 已加载，WHEN `has_item("nonexistent")`，THEN `false`，不打印警告
- [ ] **AC-B3** GIVEN ItemRegistry 已加载，WHEN `get("nonexistent")`，THEN `{}` + 打印警告
- [ ] **AC-B4** GIVEN ItemRegistry 已加载，WHEN `peek_field("herb", "name")`，THEN 字符串 `"药材"`，无警告
- [ ] **AC-B5** GIVEN ItemRegistry 已加载，WHEN `peek_field("nonexistent", "name")`，THEN `null`，不打印警告
- [ ] **AC-B6** GIVEN ItemRegistry 已加载，WHEN `peek_field("herb", "nonexistent_field")`，THEN `null`，不打印警告
- [ ] **AC-B7** GIVEN ItemRegistry 已加载 5 条 resource_material，WHEN `query_by_item_class("resource_material")`，THEN 返回 5 条 Dictionary 数组
- [ ] **AC-B8** GIVEN ItemRegistry 已加载，WHEN `query_by_item_class("equipment")`（合法但无匹配），THEN `[]`，不打印警告
- [ ] **AC-B9** GIVEN ItemRegistry 已加载，WHEN `query_by_item_class("unknown_cat")`（非锁定枚举），THEN `[]` + 打印警告
- [ ] **AC-B10** GIVEN herb.tags=`["herb","low_tier"]`，WHEN `query_by_tag("herb")`，THEN herb 在返回数组中（contains 语义，不是精确匹配）
- [ ] **AC-B11** GIVEN herb.tags=`["herb","low_tier"]`，WHEN `query_by_tag("nonexistent_tag")`，THEN `[]`，不打印警告
- [ ] **AC-B12** GIVEN ItemRegistry 已加载多条带 tags 的物品，WHEN `query_by_tag("")` 空字符串，THEN `[]`（无任何 record.tags 含空字符串），不打印警告

### C. 拷贝陷阱（4 条）

- [ ] **AC-C1** GIVEN `var d = get("herb")`，WHEN 调用方修改 `d["name"] = "fake"`，THEN 再次 `get("herb")` 返回 `name == "药材"`（registry 不受影响）
- [ ] **AC-C2** GIVEN `var n = peek_field("herb", "name")`（标量字段，String），WHEN 调用方对返回值执行 `n = "fake"` 等本地变量赋值，THEN 再次 `peek_field("herb", "name")` 返回原值 `"药材"`（标量 by-value 隔离正确）
- [ ] **AC-C3 (DOC-CONTRACT, no auto test)** 容器字段引用泄漏由 **API 命名 + doc-comment + code-review checklist** 三层防御，不写自动化测试验证"污染会发生"——把 footgun 验证为通过条件是 QA 反模式。已知契约：调用方拿到 peek_field 返回的容器字段后，**必须**先 `.duplicate()` 再做任何原地修改；如需安全可写，应改用 `get(id).field`（深拷贝路径）。code-review 阶段必须扫描所有 `peek_field(_, _)` 调用点，确认未对返回容器执行 `.append()`/`.erase()`/`[k] = v` 等原地写入。Alpha 阶段建议补 lint/静态分析规则自动化此检查。
- [ ] **AC-C4** GIVEN `var arr = query_by_item_class("resource_material")`，WHEN 修改 `arr[0]["name"] = "fake"`，THEN registry 不受影响（数组中每条都是深拷贝）

### D. 启动时序（2 条）

- [ ] **AC-D1** GIVEN ItemRegistry 实例已创建，通过 `set_data_config(null)` 注入空依赖（模拟 DataConfig Autoload 缺失/被禁用，**避免 mutate `project.godot`——CI 不支持**），WHEN 触发 `_initialize()` / `_ready()` 重入路径，THEN `push_error("ItemRegistry: DataConfig autoload missing or unavailable; falling back to empty registry")` 被触发 + `_items=={}` + `get_count()==0` + 所有查询返回零值，游戏不崩溃，控制台错误便于定位 Autoload 配置问题。**注**：Autoload 顺序的实际验证属于集成 playtest，应在 `production/qa/evidence/` 记录一次手动测试截图（修改 project.godot → 启动 → 观察控制台报错 → 恢复 project.godot），不要求 CI 自动覆盖
- [ ] **AC-D2** GIVEN ItemRegistry 尚未发布 `item_registry.loaded` 事件，WHEN 任意外部代码调 `get(id)`/`peek_field(id, ..)`，THEN 返回零值（`{}` / `null`），不崩溃。GDD 要求依赖 metadata 显示的下游应等待事件后再渲染（避免空名 UI 漏洞）

### E. 热重载（4 条）

- [ ] **AC-E1a** 参数化测试（CI 可覆盖） — GIVEN debug build（CI 默认），`DataConfig.HOT_RELOAD_ENABLED` 的 2 种取值 `{true, false}`，WHEN 调 `reload()`，THEN：仅 `true` 时实际执行 reload + 发布 `item_registry.reloaded` 事件；`false` 时 `_items` 快照不变、`get_count()` 不变、EventBus 未收到 `item_registry.reloaded`、控制台打印 `"hot reload disabled in DataConfig"` 提示
- [ ] **AC-E1b** 手动验证（CI 跳过） — GIVEN release build（`OS.is_debug_build() == false`）的 2 种取值 `{HOT_RELOAD_ENABLED=true, HOT_RELOAD_ENABLED=false}`，WHEN 调 `reload()`，THEN：两种均 no-op，`_items` 快照不变、EventBus 未收到 `item_registry.reloaded`、控制台打印 `"reload disabled in release build"`。**注**：`OS.is_debug_build()` 是引擎静态方法，无法在 GDUnit4 中被 mock；本 AC 需在 `production/qa/evidence/` 记录一次手动验证截图（导出 release build → 启动 → 控制台调 reload → 观察提示 → 确认 _items 不变）。
- [ ] **AC-E2** GIVEN `(debug=true, HOT_RELOAD_ENABLED=true)` 条件下（同 AC-E1a true 分支），修改 items.json 添加新 id `"test_new_item"`，调 `reload()` 后，WHEN `has_item("test_new_item")`，THEN `true`
- [ ] **AC-E3** GIVEN 初始加载含 id=`"old_item"`，reload 后 items.json 移除该 id，WHEN reload 完成，THEN：① `push_warning` 内容含 `"old_item"` 出现在差分列表中；② `has_item("old_item") == false`
- [ ] **AC-E4** GIVEN 初始加载 id=`"x"` 的 `item_class="resource_material"`，reload 后同一 id 的 `item_class` 改为 `"consumable"`，WHEN reload 完成，THEN：① `query_by_item_class("resource_material")` 返回数组不含 `"x"`；② `query_by_item_class("consumable")` 返回数组含 `"x"`

### F. 性能（6 条）

- [ ] **AC-F1** 性能矩阵 — MVP 5 条数据规模下，WHEN 单帧内执行各 100 次操作，THEN 总耗时满足：`get(id)` < 5 ms、`query_by_item_class` < 0.5 ms、`query_by_tag` < 0.5 ms、`peek_field` < 1 ms（公式 1/2/3a/3b 上限 × 100）
- [ ] **AC-F2** GIVEN mock items 含 5 条物品，WHEN 启动加载完成（含 DataConfig 调用），THEN 总加载耗时 < 5 ms
- [ ] **AC-F3** GIVEN MVP 5 条物品已加载，WHEN 用 `OS.get_static_memory_usage()` 差值采样，THEN ItemRegistry 净增内存 < 5 KB。**注**：跨平台/跨 GC 时机的绝对值波动较大，本 AC 仅作为 ADVISORY，限定运行环境为 Linux headless CI + 固定 GC 触发；非该环境下视为 informational
- [ ] **AC-F4** Alpha 规模性能门槛 — GIVEN mock items 含 N=500 条记录（其中 50 条 item_class="resource_material"），WHEN 单次执行 `query_by_item_class("resource_material")`，THEN 单次耗时 < 2.5 ms（公式 3a 典型值上界）。**MVP 实施时此 AC 可标 `@tag("alpha_perf")` 跳过，Alpha 数据集准备完毕后启用**
- [ ] **AC-F5** Alpha 倒排索引门槛 — GIVEN mock items 含 N=500 条记录（每条 tags 平均 5 项，匹配 50 条），WHEN 单次执行 `query_by_tag("low_tier")`，THEN 单次耗时 < 5 ms（暗示已实现倒排索引）。**MVP 实施时此 AC 可标 `@tag("alpha_perf")` 跳过；Alpha 数据集启用后若该 AC 失败则要求实现倒排索引（详见 §Tuning Knobs `INVERTED_INDEX_THRESHOLD`）**
- [ ] **AC-F6** `get_all_ids()` 调用约束（契约 AC，非运行时检测） — **注**：GDScript 无运行时调用栈自省 API（无 `get_stack()` 等），无法在 ItemRegistry 内部检测调用者是否在 `_process` 中。本 AC 验证的是代码约定而非运行时行为：① API doc-comment 中明确写有 "不得在 `_process` / `_physics_process` 内调用此方法，应在 `item_registry.loaded` 事件回调中缓存结果"；② code-review checklist（见 AC-C3 的 checklist）中包含 "所有 `get_all_ids()` 调用点是否出现在 `_process` / `_physics_process` 中" 检查项。**Alpha 扩展**（N > INVERTED_INDEX_THRESHOLD 时）：ItemRegistry 内部维护 `_get_all_ids_last_frame: int` 帧计数器，若同一帧内被重复调用且 N > THRESHOLD 则 `push_warning` 提示缓存（仅检测重复调用频率，不检测调用栈）

### G. Lifecycle 事件（2 条）

- [ ] **AC-G1** GIVEN ItemRegistry 启动加载成功（`get_count() > 0`，含 5 条 resource_material + 1 条 `item_class="unknown_cat"` 被 AC-A4 跳过），WHEN `_ready()` 完成，THEN EventBus 收到一次 `item_registry.loaded` 事件，payload 严格符合 schema `{count: int, item_classes: Dictionary[String, int]}`：① `count == get_count() == 5`（不含被跳过的记录）；② `item_classes.keys()` 仅含 4 元锁定枚举内的值；③ `item_classes["resource_material"] == 5`；④ 所有未出现 item_class 的 key 不在 `item_classes` 中（即 keys.size() == 实际加载的 distinct item_class 数）；⑤ `item_classes` **不包含** `"unknown_cat"` key（被拒绝记录的 item_class 不出现）。事件**同步发布**（不使用 `call_deferred` / `await`，确保订阅者在第 1 帧结束前可处理）
- [ ] **AC-G2** GIVEN AC-E1 的 reload 实际执行路径，WHEN reload 完成，THEN EventBus 收到一次 `item_registry.reloaded` 事件

### H. 跨系统边界（1 条）

- [ ] **AC-H1** GIVEN ItemRegistry 注册集合 = `{a, b}`、ResourceSystem 注册集合 = `{b, c}`（部分重叠），WHEN 两者同时运行，THEN：① `ItemRegistry.has_item("c")==false`；② `ResourceSystem.has_resource("a")==false`；③ `ItemRegistry.get("c")=={}`；④ `ResourceSystem.get_value("a")==BigNumber.ZERO`；两者各自正常运行，互不报错

### I. 内部一致性（1 条）

- [ ] **AC-I1** GIVEN ItemRegistry 已加载 N 条物品，WHEN 同时调用 `get_all_ids()` 与 `get_count()`，THEN `get_all_ids().size() == get_count()`；且对所有锁定 item_class 调用 `query_by_item_class()` 后并集 size 等于 `get_count()`

## Open Questions

| Question | Owner | Deadline | Resolution |
|----------|-------|----------|-----------|
| **BigNumber GDD §Interactions** 列出"物品/材料系统：物品价值、堆叠数量用 BigNumber"——与本 GDD §Dependencies 不一致（MVP 无 BigNumber 字段）。需在 `/consistency-check` 阶段把该行改为"Alpha 阶段引入"或加注 MVP 不需要 | 设计师 | `/consistency-check` 阶段 | ✅ 已解决 2026-05-03 — big-number-system.md L100（§Interactions）+ L285（§Dependencies）两处已改为"物品/材料系统（Alpha 阶段引入）"，标注 MVP 不接入 |
| **EventBus GDD §Core Rules 12** 命名空间约定已列入 `item_registry.loaded` / `item_registry.reloaded` 两个 lifecycle 事件 | 开发者 | `/consistency-check` 阶段 | ✅ 已解决 2026-05-03 — event-bus.md 已追加两条 item_registry 命名空间，含 payload 说明 |
| **entities.yaml** 中 5 条物品（lingqi/xiuwei/lingshi/herb/exp）的 `referenced_by` 字段**未含 `design/gdd/item-material-system.md`**。需在 Phase 5b 时追加引用关系 | 开发者 | Phase 5b（本 GDD 完成后） | — |
| **rarity 8 元枚举的 HUD 颜色 mapping** 由 HUD GDD 定义。本 GDD 只锁定枚举字符串集合（`fanpin/jingliang/xiyou/shishi/chuanshuo/shenhua/xiantian/hundun`），具体 RGB 值待 HUD GDD 拍板 | 美术 + UI 设计师 | HUD GDD 时 | — |
| **物品图标资产规格**（尺寸如 64×64、格式 PNG/SVG/WebP、命名约定）由 HUD GDD 与 art-bible 共同决定。本 GDD 只约定 `icon_path` 是 `res://...` 字符串 | 美术总监 | art-bible / HUD GDD | — |
| **倒排索引切换阈值**：GDD 当前以 `INVERTED_INDEX_THRESHOLD=50` 作为代码注释中的参考值。Alpha 实施时是否真正按此切换、是否引入 `query_by_*` 调用频率监测来动态决策——待 Alpha 性能验证阶段拍板 | 开发者 | Alpha 性能验证阶段 | — |
| **tags 集合是否在 Alpha 锁定**：MVP 阶段 tags 是开放字符串集，避免拼写漂移依赖 items.json 维护方自律。Alpha 阶段如装备/词条体系大规模上线时，tag typo 可能让大量记录从掉落表中消失——是否引入 `valid_tags.json` 白名单或在加载时警告非白名单 tag？ | 设计师 | Alpha 装备系统 GDD 时 | — |
| **`localization_key` 命名约定**：建议形如 `"item.<id>.name"` / `"item.<id>.desc"`，但需与本地化系统 GDD（Post-MVP）的整体命名空间约定对齐。Post-MVP 本地化系统设计阶段拍板 | 设计师 + 开发者 | 本地化系统 GDD（Post-MVP） | — |
| **装备 instance 的实例 ID 设计**（`discrete_instance=true` 时如何生成 instance_id、如何持久化）由 Alpha 装备/词条系统 GDD 决定。本 GDD 在 schema 中预留 `discrete_instance` bool 但不规范实例化机制 | 设计师 | Alpha 装备系统 GDD | — |
| **`affix_pool_id` / `equip_slot` 引用完整性校验**：MVP 不校验这些 Alpha 字段引用的有效性。Alpha 装备/词条系统接入时，是否引入"启动时引用完整性校验"或"运行时按需校验"——待装备系统 GDD 决定 | 开发者 | Alpha 装备系统 GDD | — |
| **`items.json` 文件位置约定**（`assets/data/items.json` 是否合适）依赖于数据配置系统 GDD 已建立的 `assets/data/` 路径约定，本 GDD 沿用 | 开发者 | 实施阶段前 | ✅ 已解决 — DataConfig GDD §Core Rules 已约定 `assets/data/` 路径，本系统沿用 |
| **【设计承诺】Alpha 阶段重写 Player Fantasy 节**：MVP 阶段本 GDD 的 Player Fantasy 实质只兑现支柱 4.1（数字增长具象化层），支柱 4.6（渐进叙事）和支柱 4.3（刷宝惊喜）目前仅作占位。Alpha 装备/词条/法宝/稀有材料上线后，需回头追加 "拾取动画 + 稀有度颜色 + 词条 reveal 三件套" 锚定段，真正兑现 4.6 渐进叙事 + 4.3 刷宝惊喜 | 设计师 + creative-director | Alpha 装备系统 GDD / Alpha 内容广度 第一次扩张时 | — |
| **typed `Dictionary[K, V]` 采纳决策** — Godot 4.4+ 支持类型化字典；与项目静态类型偏好一致。但 ItemDefinition 14 字段含异构 Variant 值，typed dict 仅能标 `Dictionary[String, Variant]` 提供 key 类型保证而非 value。是否值得采纳？或考虑 custom Resource 子类（获得完整类型安全但需 DataConfig JSON 解析桥接层） | 开发者 | 实施阶段前 | — |
| **`OS.is_debug_build()` 在 Godot 4.6.2 行为复核** — 4.4-4.6 多处 OS API 变更（VERSION.md MEDIUM/HIGH 风险版本）；本 GDD 多处依赖此 API（reload 门控、debug 校验、warning 输出）。需查 `docs/engine-reference/godot/` 确认 4.6.2 行为；是否改用 `OS.has_feature("debug")` 备选 | 开发者 | 实施阶段前 | — |
| **Autoload 顺序运行时防御** — 当前依赖 project.godot 行序的隐式约定。是否在 `_ready()` 中通过 `Engine.has_singleton("DataConfig")` 或类似 API 做运行时顺序检测？ | 开发者 | 实施阶段前 | — |
| **id 命名空间一致性 debug 校验** — MVP 阶段建议在调试控制台 / 独立 startup-checker 系统中实现 `_check_id_consistency_with_resource_system()`，运行时不强制但 debug 启动时打印差分。本系统不实现以保持解耦——由调试控制台 GDD 接手 | 开发者 + 设计师 | 调试控制台 GDD 时 | — |
| **9 个 Debug 常量精简度** — game-designer 评审建议 MVP 仅保留 3 个核心常量（`WARN_ON_INVALID_ITEM_CLASS` / `WARN_ON_MISSING_NAME` / `EMIT_LIFECYCLE_EVENTS`），其余 6 个移至 Alpha 章节脚注（避免 MVP 阅读负担与"为什么没用"的认知摩擦）。creative-director 裁定为 NICE-TO-HAVE 部分接受。是否接受精简？ | 开发者 + 设计师 | 实施阶段前 | — |
| **per_item_size 字段分解证明** — 公式 5 给出 per_item_size 上限 1200 bytes 是估算值，缺各字段 Godot 内存占用分解。Alpha 阶段需补 benchmark 验证 tags=50 + meta=5 层嵌套的实际内存 | 开发者 | Alpha 性能验证阶段 | — |
| **Autoload `/root/ItemRegistry` 与 `class_name ItemRegistry`（RefCounted）命名冲突** — GDScript 全局命名空间中两者同名；`ItemRegistry` 标识符解析时 Autoload Node 优先于 `class_name`。实施前需决定：RefCounted 服务类命名为 `ItemRegistryService`（内部），Autoload 保持 `ItemRegistry`（对外 API）；或 Autoload 脚本改名为 `ItemRegistryAutoload` | 开发者 | 实施阶段前 | — |
| **OS.is_debug_build() 行为确认** — godot-gdscript-specialist 确认：Godot 4.6 中 `OS.is_debug_build()` 稳定可靠，无需切换到 `OS.has_feature("debug")`。此条可关闭 | 开发者 | 实施阶段前 | ✅ 已解决 — `OS.is_debug_build()` 使用正确，无需修改；`Engine.has_singleton()` 也不是 Autoload 顺序防御的必要手段 |
| **Alpha 实际物品数估算超 N=500 建模上限** — 装备 ~200 + 词条池 ~100 + 消耗品 ~50 + 任务道具 ~100 + 法宝 ~50 ≈ 550 条（已超本 GDD N=500 上限）。Alpha 阶段需将公式上限调至 N=1000 并重新验证性能门槛 | 开发者 | Alpha 内容广度第一次扩张时 | — |
