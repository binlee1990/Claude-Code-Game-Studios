# 事件总线 (Event Bus)

> **Status**: Approved
> **Author**: binlee1990 + agents
> **Last Updated**: 2026-05-04
> **Implements Pillar**: 4.6 渐进叙事展开 · 4.10 数据驱动与可扩展

## Overview

事件总线是整个游戏的跨系统通信基础设施层。它提供集中式的事件发布/订阅机制，使游戏系统之间无需直接持有对方引用即可交换信息——资源系统发出"灵气增加"事件，UI 系统订阅并更新显示，两者互不知道对方的存在。

游戏包含 30 个 MVP 系统，横跨资源产出、战斗、掉落、存档、UI 等领域。如果每个系统都硬编码调用其他系统，依赖关系将退化为网状耦合，导致无法独立开发、测试或替换任何模块。事件总线通过统一的发布-订阅协议切断这些直接依赖，使每个系统只需关心"我发出什么事件"和"我监听什么事件"，而不需要知道事件的消费者或生产者是谁。

本系统管理的事件类型包括但不限于：资源变化、等级提升、装备掉落、区域解锁、境界突破、成就达成、系统启用/禁用、UI 页面切换通知。下游消费者涵盖 UI 框架（响应数据变化刷新显示）、HUD 系统（更新资源面板）、调试控制台（监听全量事件用于日志）以及未来的通知系统和教程系统。

玩家不直接与事件总线交互。他们感受到的是它带来的效果：灵气数字实时跳动、突破成功的通知弹窗、新系统在恰当的时机出现——这些流畅的反馈都建立在事件总线的解耦通信之上。

## Player Fantasy

事件总线是隐形的经脉——玩家永远看不到它，但能感受到修仙世界的"气"在流畅运转。

**锚定时刻**：玩家离开游戏数小时后返回。屏幕亮起，一连串反馈同时涌来——灵气数字跳动、离线收益弹出、某个装备掉落通知、修炼突破可用的提示。这些信息不是同时"刷"出来的，而是按照因果顺序依次呈现，像世界在向玩家讲述它在你离开时发生了什么。这种"世界在我离开时仍在运转，且回来时一切有序"的感觉，正是事件总线在背后编排的。

作为基础设施，事件总线不创造任何玩家幻想，但它是所有幻想的传导网络。没有它，数字增长无法即时显示、突破提示无法及时弹出、新系统无法在恰当的解锁条件满足时出现——玩家的修仙世界会变得迟钝、断裂、缺乏因果感。有了它，修仙世界表现为一个对玩家行动即时响应的、有内在因果逻辑的活世界。

支柱对应：
- **4.1 数字增长就是快乐**：事件总线确保灵气、修为、战力的每一次变化都能被 UI 即时捕获和显示，让数字增长的快感不被延迟或丢失。
- **4.6 渐进叙事展开**：事件总线驱动"条件满足 → 解锁通知 → UI 页面出现"的渐进链路，使新系统在恰当时机自然浮现。

## Detailed Design

### Core Rules

1. **架构形态**：`EventBus` 作为 Autoload 单例（`/root/EventBus`），全局唯一。所有系统通过 `EventBus` 的统一接口发布和订阅事件，不直接持有其他系统的引用。

2. **事件标识**：每个事件类型用字符串常量唯一标识，集中在 `EventName` 静态类中定义。禁止使用魔法字符串——所有事件名必须通过常量引用。

3. **事件负载**：每个事件携带一个 `Dictionary` 负载（payload）。Dictionary 的 key 由事件定义方在 GDD 中声明，订阅方按约定读取。不使用强类型对象——避免为每个事件创建类，保持扩展灵活性。

4. **发布**：`EventBus.emit(event_name: String, payload: Dictionary = {}) -> void`
   - 调用后，所有当前订阅者立即同步收到事件
   - 发布是即时的（在调用帧内完成），不排队
   - 发布者不知道也不关心有多少订阅者（包括零订阅者）

5. **订阅**：`EventBus.subscribe(event_name: String, callable: Callable) -> void`
   - 同一 callable 对同一 event_name 重复订阅只生效一次
   - 订阅立即生效，可接收下一次 emit

6. **取消订阅**：`EventBus.unsubscribe(event_name: String, callable: Callable) -> void`
   - 取消订阅后不再收到该事件
   - 对未订阅的 callable 取消订阅是安全操作（静默忽略）

7. **一次性订阅**：`EventBus.subscribe_once(event_name: String, callable: Callable) -> void`
   - 收到一次事件后自动取消订阅
   - 适用于"等待某条件达成后执行一次"的场景（如等待突破完成）

8. **错误隔离（GDScript 可实现边界）**：GDScript 4.x 没有 `try/catch`，EventBus **不承诺捕获订阅者回调内部的运行时错误**。可实现的隔离边界是：投递前检查 `Callable.is_valid()` 与 Node 实例有效性；无效 callable 会被移除并打印 warning，后续订阅者继续投递。订阅者自身逻辑错误由 Godot 错误日志暴露，订阅者必须保持回调短小、无跨系统写入副作用。

9. **订阅者生命周期**：当订阅者是 Node 且被释放（`tree_exited`）时，EventBus 自动移除该 Node 的所有订阅。防止已销毁节点收到回调导致崩溃。

10. **调试模式**：`EventBus.set_debug_enabled(true)` 开启后，每次 emit 都打印事件名和订阅者数量到控制台。不影响事件投递行为。

11. **通配符订阅（前缀匹配）**：
    - `EventBus.subscribe_pattern(prefix: String, callable: Callable) -> void`
      - 订阅所有事件名以 `prefix` 开头的事件（`String.begins_with(prefix)` 匹配）。
      - 回调签名：`callable(event_name: String, payload: Dictionary) -> void`——**与 `subscribe()` 不同**，pattern 回调接收事件名作为第一个参数，便于消费方区分多个匹配事件（如 `event watch resource` 同时收到 `resource.lingqi.changed` 和 `resource.xiuwei.changed`）。
      - prefix 不可为空字符串（订阅所有事件无意义且会拖垮订阅者）；空 prefix 拒绝注册并打印警告 `"subscribe_pattern: prefix must not be empty"`。
      - 同一 (prefix, callable) 重复订阅只生效一次（与 `subscribe()` 一致的去重语义）。
      - pattern 订阅与精确订阅独立——同一事件触发时，`subscribe()` 和 `subscribe_pattern()` 的回调都会收到，按内部投递顺序执行（精确订阅先于 pattern）。
    - `EventBus.unsubscribe_pattern(prefix: String, callable: Callable) -> void`
      - 注销 (prefix, callable) 对应的 pattern 订阅；对未订阅的 (prefix, callable) 是静默 no-op。
      - **必须与 `subscribe_pattern` 对称**——不能用 `unsubscribe()` 注销 `subscribe_pattern()` 的订阅，反之亦然（两者维护独立的订阅集合）。
    - **性能模型**：每次 `emit()` 在精确投递完成后，遍历所有 pattern 订阅，对每个 prefix 做 `event_name.begins_with(prefix)` 检查；命中则执行回调。复杂度 O(P × k)，P 为 pattern 订阅数，k 为平均 prefix 长度。Pattern 订阅数应远小于精确订阅数（设计预期 ≤ 4 个，开发者调试用）；高频事件场景下若 pattern 订阅累计开销超过帧预算 0.5 ms/frame 应警告。
    - **典型用例**：调试控制台 `event watch resource` 命令——开发者实时观察 `resource.*` 事件流；不应作为生产代码的解耦机制（生产代码用精确订阅）。
    - **错误隔离**：pattern 回调使用与精确订阅相同的有效性检查（规则 8）；不提供 GDScript 不支持的异常捕获语义。

12. **事件名空间约定**：
    - `resource.{resource_id}.changed` — 资源数量变化（payload: `{resource_id, old_value, new_value, delta}`）
    - `resource.{resource_id}.cap_changed` — 资源上限变化（由资源系统 `set_max` 触发）
    - `resource.{resource_id}.overflow` — 资源溢出（add 超过上限或 set_max 截断 current 时触发；payload 含 `attempted, actual_added, lost`）
    - `attribute.{entity_id}.{attr_id}.base_changed` — 角色属性基础值变化（payload: `{entity_id, attr_id, old_value, new_value, delta}`，由属性系统 `set_base` 触发；最终值变化不广播——订阅者按需在收到 base_changed 后重算 final）
    - `attribute.{entity_id}.unregistered` — 实体注销聚合事件（payload: `{entity_id}`，由属性系统 `unregister_entity` 触发；HUD 据此清理面板，无需逐属性订阅删除事件）
    - `combat.encounter_started` — 单场在线战斗开始（payload: `{zone_id, enemy_id, encounter_id}`）
    - `combat.encounter_finished` — 单场在线战斗结束（payload: `{zone_id, enemy_id, encounter_id, result, duration, rewards_summary}`）
    - `ui.{screen_name}.opened/closed` — UI 页面切换
    - `system.{system_name}.unlocked` — 系统解锁
    - `level.changed` — 等级变化（payload: `{entity_id, old_level, new_level, levels_gained}`）
    - `realm.advanced` — 境界变化（payload: `{entity_id, old_realm, new_realm}`）
    - `achievement.unlocked` — 成就达成
    - `offline.settled` — 离线收益结算完成
    - `offline.simulation_completed` — 离线模拟草案生成完成（payload: `{draft_id, offline_seconds, simulator_count, warning_count}`）
    - `cultivation.stance_changed` — 修炼姿态变化（payload: `{old_stance, new_stance}`）
    - `exploration.target_changed` — 挂机探索目标变化（payload: `{old_zone_id, new_zone_id, strategy}`）
    - `zone.changed` — 当前区域变化（payload: `{old_zone_id, new_zone_id}`）
    - `zone.first_cleared` — 区域首次通关（payload: `{zone_id, clear_time, combat_result}`）
    - `time.frozen` / `time.unfrozen` / `time.speed_changed` / `time.offline_delta` — 时间状态与离线 delta 通知
    - `save.loaded` / `save.saved` / `save.corrupted` — 存档加载、保存、损坏恢复通知
    - `production_multiplier_changed` — 产出来源激活/注销导致某资源最终产出倍率变化
    - `modifier_expired` — 限时修正器过期，由 ModifierEngine 发布
    - `loot.dropped` — 掉落系统结算出物品/材料时发布
    - `item_registry.loaded` — 物品注册表启动加载完成（payload: `{count: int, item_classes: Dictionary[String, int]}`，由物品/材料系统 `_ready()` 完成时触发；HUD/掉落系统据此确认 metadata 就绪）
    - `item_registry.reloaded` — 物品注册表热重载完成（payload: `{count: int, item_classes: Dictionary[String, int]}`，由 `ItemRegistry.reload()` 在 debug 模式触发；订阅方应刷新缓存的 metadata）

13. **高频事件治理**：默认 `emit()` 保持即时同步，不做透明节流或合并，避免破坏资源/存档/战斗等事务事件的因果语义。对显示型高频事件，EventBus 提供可选 `emit_coalesced(event_name: String, payload: Dictionary, coalesce_key: String = "") -> void`：
    - 同一帧内相同 `(event_name, coalesce_key)` 仅保留最后一个 payload，在帧末按一次普通 `emit()` 投递。
    - 只允许用于"最新状态覆盖旧状态"的 UI/调试事件；不得用于需要累计 delta、逐条审计或触发业务连锁的事件。
    - 资源、属性、存档等拥有业务语义的系统应优先在自身领域内批处理（如 ResourceSystem.batch_add），而不是要求 EventBus 猜测如何合并 payload。
    - 调试模式下仍统计每帧 emit 次数，超过 `HIGH_EMIT_FREQUENCY_THRESHOLD` 打印 warning，提示发布方改用批处理或 coalesced 显示事件。

### States and Transitions

EventBus 自身不持有业务状态，但管理订阅关系的内部状态：

| 状态 | 描述 | 转换条件 |
|------|------|---------|
| **Empty** | 无订阅者 | `subscribe()` → Active |
| **Active** | 有活跃订阅 | `unsubscribe()` 且无剩余订阅者 → Empty |
| **Emitting** | 正在向订阅者投递事件 | 投递完成 → 回到 Active/Empty |

特殊规则：
- **Emitting 状态下禁止订阅/取消订阅**：在事件投递过程中，订阅/取消操作缓存到队列，投递完成后批量执行。防止在回调中修改订阅列表导致迭代器失效。
- **Emitting 状态下禁止同事件 emit**：防止递归 emit（如回调中再次 emit 同一事件）。违反时打印警告并忽略递归 emit。

### Interactions with Other Systems

| 系统 | 方向 | 数据接口 | 说明 |
|------|------|---------|------|
| 资源系统 | 上游发布 | `resource.{id}.changed`，payload: `{resource_id, old_value, new_value, delta}` | 资源增减时发布，UI/HUD 订阅更新显示 |
| 属性系统 | 上游发布 | `attribute.{entity_id}.{attr_id}.base_changed` 和 `attribute.{entity_id}.unregistered` | 实体属性基础值变化与实体注销时发布，HUD 精准订阅主角/上阵弟子的属性事件 |
| 等级系统 | 上游发布 | `level.changed`，payload: `{entity_id, old_level, new_level, levels_gained}`；`realm.advanced`，payload: `{entity_id, old_realm, new_realm}` | 升级/境界变化时发布，HUD、地图推进、修炼提示订阅 |
| 掉落系统 | 上游发布 | `loot.dropped`，payload: `{item_id, quantity, source}` | 物品掉落时发布，背包和日志订阅 |
| 修炼系统 | 上游发布 | `cultivation.stance_changed` | 姿态切换时发布，HUD 刷新修炼状态 |
| 半自动战斗系统 | 上游发布 | `combat.encounter_started` / `combat.encounter_finished` | 战斗日志、地图推进和 HUD 消费 |
| 区域系统 | 上游发布 | `zone.changed` | 当前挂机区域切换通知 |
| 地图推进系统 | 上游发布 | `zone.first_cleared` | 首通和解锁反馈 |
| 挂机探索系统 | 上游发布 | `exploration.target_changed` | 当前挂机目标切换通知 |
| 离线模拟内核 | 上游发布 | `offline.simulation_completed` | 离线草案完成通知，供结算/调试消费 |
| 离线收益结算系统 | 上游发布 | `offline.settled` | 离线收益实际入账后通知 HUD/UI |
| UI 框架 | 下游订阅 | 订阅各类显示更新事件 | 响应数据变化刷新界面 |
| HUD 系统 | 下游订阅 | 精确订阅 MVP 资源的 `resource.{id}.changed`、`level.changed`、`realm.advanced`、`combat.*`、`zone.changed`、`offline.settled` | 更新资源栏、等级/境界、战斗状态、区域和离线摘要；生产 UI 不依赖 prefix 订阅 |
| 调试控制台 | 下游订阅 | 通过 `subscribe_pattern(prefix, callable)` 订阅指定事件前缀 | 开发阶段监控资源、时间、存档等事件流；空 prefix 不允许 |
| 时间管理器 | 上游发布 | `time.frozen`, `time.unfrozen`, `time.speed_changed`, `time.offline_delta` | 时间状态变更通知，离线收益结算触发 |
| 通知系统（未来） | 下游订阅 | 订阅突破、稀有掉落、成就等关键事件 | 触发弹窗通知 |
| 教程系统（未来） | 下游订阅 | 订阅 `system.*.unlocked` 等事件 | 触发新手引导 |

## Formulas

### 1. 单次事件投递耗时

`delivery_time = subscriber_count × callback_overhead + lookup_overhead`

**变量：**
| 变量 | 符号 | 类型 | 范围 | 描述 |
|------|------|------|------|------|
| subscriber_count | N | int | [0, 128] | 该事件的当前订阅者数量 |
| callback_overhead | t_cb | float | [0.001, 0.05] ms | 单个订阅者回调的平均执行耗时 |
| lookup_overhead | t_lookup | float | [0.001, 0.005] ms | 从订阅字典中查找订阅者列表的耗时 |

**输出范围：** 0 ms（无订阅者）到 ~6.4 ms（128 × 0.05 ms，极端情况）
**正常范围：** < 0.5 ms（典型场景：5–20 个订阅者，回调耗时 < 0.01 ms）
**示例：** `resource.lingqi.changed` 有 3 个订阅者，每个回调耗时 0.008 ms → delivery_time = 3 × 0.008 + 0.002 = 0.026 ms

### 2. 帧内事件总线总耗时预算

`event_bus_frame_budget = frame_time × budget_ratio`

**变量：**
| 变量 | 符号 | 类型 | 范围 | 描述 |
|------|------|------|------|------|
| frame_time | t_frame | float | 16.67 ms | 单帧时间（60 fps） |
| budget_ratio | r | float | [0.01, 0.05] | 事件总线允许占用的帧时间比例 |

**输出范围：** 0.167 ms（保守，1%）到 0.833 ms（宽松，5%）
**推荐值：** r = 0.03 → budget = 0.5 ms/frame
**示例：** 60 fps 下，事件总线每帧最多占用 0.5 ms，剩余 16.17 ms 留给游戏逻辑和渲染

### 3. 订阅容量上限

`max_subscribers_per_event = min(event_bus_frame_budget / avg_callback_time, hard_cap)`

**变量：**
| 变量 | 符号 | 类型 | 范围 | 描述 |
|------|------|------|------|------|
| event_bus_frame_budget | B | float | 0.5 ms | 事件总线帧预算 |
| avg_callback_time | t_avg | float | [0.001, 0.05] ms | 单次回调平均耗时 |
| hard_cap | C | int | 128 | 硬性上限，防止配置错误 |

**输出范围：** 10（回调耗时 0.05 ms 时）到 128（硬性上限）
**示例：** B = 0.5 ms，t_avg = 0.01 ms → min(50, 128) = 50 个订阅者

## Edge Cases

- **If 对没有订阅者的事件调用 emit**：静默忽略，无开销（仅字典查找一次）。这是正常行为——某些事件在特定阶段没有消费者。
- **If 在回调中再次对同一事件调用 emit**：检测到递归投递，打印警告 `"Recursive emit detected: {event_name}"`，忽略递归调用。防止无限循环。
- **If 在回调中对其他事件调用 emit**：允许。嵌套 emit 作为正常的同步调用处理，但深度超过 8 层时打印警告并截断。防止意外深度嵌套。
- **If 在回调中执行 subscribe/unsubscribe**：操作缓存到待处理队列，当前 emit 投递完成后批量执行。防止迭代器失效。
- **If 回调内部发生 GDScript 运行时错误**：EventBus 不捕获（GDScript 无 `try/catch`）。Godot 记录错误；EventBus 的设计约束是回调必须短小、无跨系统写入副作用。需要错误返回的订阅者应自行用 Result/状态码处理，而不是依赖异常。
- **If callable 在投递前已无效**：EventBus 跳过该 callable，移除订阅记录，打印 warning `Invalid callable removed during {event_name}`，继续向后续订阅者投递。
- **If 订阅者 Node 在 emit 前被释放**：EventBus 监听了 `tree_exited` 信号并已自动移除订阅，不会发生调用已释放节点的情况。
- **If 同一个 callable 对同一事件订阅多次**：只生效一次。重复订阅静默忽略。使用 `Callable` 的 `==` 比较判断重复。
- **If 对未订阅的 callable 调用 unsubscribe**：静默忽略，无副作用。
- **If subscribe_once 的 callable 无效**：一次性订阅在投递前即移除；无效 callable 不会被调用，后续 emit 不再触发。
- **If emit 频率极高（同一帧内数百次）**：普通 `emit()` 不透明节流；调试模式下打印警告 `"High emit frequency: {event_name} emitted {N} times this frame"`。发布方若事件只表达最新显示状态，可改用 `emit_coalesced()`；若事件包含累计业务 delta，必须在发布方领域内批处理。
- **If 事件名拼写错误或使用了未定义的常量**：不校验事件名合法性——EventBus 不持有"已注册事件"列表。这是设计决策：松耦合意味着发布者不声明自己会发什么事件。调试模式下会打印所有 emit 的事件名供人工检查。
- **If 在 _ready 之前访问 EventBus**：Autoload 单例在所有场景树的 `_ready` 之前初始化，不应出现此情况。若出现，返回空操作（GDScript Autoload 保证初始化顺序）。
- **If 单事件订阅者数超过 hard_cap (128)**：超出限制的 subscribe 调用被拒绝，打印警告 `"Subscriber cap reached for {event_name}"`。设计上应拆分事件粒度或优化订阅者。
- **If `subscribe_pattern` 的 prefix 为空字符串**：拒绝注册，打印警告 `"subscribe_pattern: prefix must not be empty"`，回调不会被触发。
- **If 同一 (prefix, callable) 重复 `subscribe_pattern`**：仅生效一次（与 `subscribe()` 一致的去重语义），不重复触发回调。
- **If 用 `unsubscribe()` 注销 `subscribe_pattern()` 的订阅**：静默 no-op（两者维护独立的订阅集合）；pattern 订阅仍然有效。反之亦然。
- **If 同一事件同时匹配多个 pattern 订阅**：每个匹配的 pattern 回调都被触发一次（独立投递）；pattern 之间的执行顺序由内部存储顺序决定，不保证特定顺序。
- **If pattern callable 无效**：与精确订阅一致——跳过、移除、打印 warning，继续向其余订阅者（含其他 pattern）投递。
- **If 一个事件同时匹配精确订阅和 pattern 订阅**：先投递精确订阅，再遍历 pattern 订阅。两者均收到事件。
- **If 同一帧内多次调用 `emit_coalesced("ui.hud.refresh", payload, "resources")`**：只保留最后一个 payload；帧末执行一次普通 `emit("ui.hud.refresh", latest_payload)`。
- **If 对需要逐条审计的事件调用 `emit_coalesced()`**（如 `save.saved` 或 `loot.dropped`）：这是发布方错误。EventBus 不理解业务语义，代码审查应禁止此用法。

## Dependencies

| 系统 | 方向 | 依赖性质 | 数据接口 |
|------|------|---------|---------|
| **（无上游依赖）** | — | — | EventBus 是 Foundation 层零依赖基础设施，不依赖任何其他系统 |
| 资源系统 | 下游依赖 EventBus | 硬依赖 | 发布 `resource.{id}.changed` 事件，通知 UI/HUD 刷新 |
| 属性系统 | 下游依赖 EventBus | 硬依赖 | 发布 `attribute.{entity_id}.{attr_id}.base_changed` 与 `attribute.{entity_id}.unregistered` 事件，通知 HUD/Build 评分系统刷新 |
| 时间管理器 | 下游依赖 EventBus | 硬依赖 | 发布 `time.frozen` / `time.unfrozen` / `time.speed_changed` / `time.offline_delta` 事件 |
| 存档系统 | 下游依赖 EventBus | 硬依赖 | 发布 `save.loaded` / `save.saved` / `save.corrupted` 事件 |
| 修正器/倍率引擎 | 下游依赖 EventBus | 硬依赖 | 发布 `modifier_expired` 事件 |
| 产出乘数系统 | 下游依赖 EventBus | 硬依赖 | 发布 `production_multiplier_changed` 事件；订阅 `modifier_expired` 清理来源追踪 |
| 物品/材料系统 | 下游依赖 EventBus | 软依赖 | 发布 `item_registry.loaded` / `item_registry.reloaded` 事件 |
| 等级系统 | 下游依赖 EventBus | 硬依赖 | 发布 `level.changed` 和 `realm.advanced` 事件 |
| 掉落系统 | 下游依赖 EventBus | 硬依赖 | 发布 `loot.dropped` 事件 |
| 修炼系统 | 下游依赖 EventBus | 硬依赖 | 发布 `cultivation.stance_changed` 事件 |
| 半自动战斗系统 | 下游依赖 EventBus | 硬依赖 | 发布 `combat.encounter_started` / `combat.encounter_finished` 事件 |
| 区域系统 | 下游依赖 EventBus | 硬依赖 | 发布 `zone.changed` 事件 |
| 地图推进系统 | 下游依赖 EventBus | 硬依赖 | 发布 `zone.first_cleared` 事件 |
| 挂机探索系统 | 下游依赖 EventBus | 硬依赖 | 发布 `exploration.target_changed` 事件 |
| 离线模拟内核 | 下游依赖 EventBus | 硬依赖 | 发布 `offline.simulation_completed` 事件 |
| 离线收益结算系统 | 下游依赖 EventBus | 硬依赖 | 发布 `offline.settled` 事件 |
| 调试控制台 | 下游依赖 EventBus | 软依赖 | 通过 `subscribe_pattern(prefix)` 订阅指定前缀用于开发日志；可移除不影响游戏功能 |
| UI 框架 | 下游依赖 EventBus | 硬依赖 | 订阅数据变化事件驱动界面刷新 |
| HUD 系统 | 下游依赖 EventBus | 硬依赖 | 订阅资源/等级变化事件更新顶栏显示 |
| 通知系统（未来） | 下游依赖 EventBus | 硬依赖 | 订阅突破、稀有掉落、成就等关键事件 |
| 教程系统（未来） | 下游依赖 EventBus | 硬依赖 | 订阅系统解锁事件触发引导流程 |

**双向一致性说明**：上述系统的 GDD 应在各自 Dependencies 节中列出"上游依赖 EventBus"。本 GDD 完成后，后续 GDD 的依赖声明需与此表保持一致。

## Tuning Knobs

| 参数 | 当前值 | 安全范围 | 增大影响 | 减小影响 |
|------|--------|---------|---------|---------|
| `MAX_SUBSCRIBERS_PER_EVENT` | 128 | [32, 256] | 允许更多订阅者，但单次投递耗时增加 | 限制过严可能导致合法订阅被拒绝 |
| `BUDGET_RATIO` | 0.03 | [0.01, 0.05] | 事件总线获得更多帧时间，允许更高频率 | 过严可能导致事件积压 |
| `MAX_EMIT_DEPTH` | 8 | [4, 16] | 允许更深的事件嵌套链 | 过浅可能截断合理的嵌套场景 |
| `HIGH_EMIT_FREQUENCY_THRESHOLD` | 50 | [10, 200] | 更宽容，只有极高频才告警 | 更敏感，更容易触发调试告警 |
| `DEBUG_ENABLED` | false | [true, false] | 开启后每次 emit 打印日志，性能下降 | 关闭后零性能开销 |

**说明**：上述参数为开发者/性能调优参数，不属于游戏设计师调参范围。运行时不应动态修改（调试模式除外）——它们是实现时的编译期常量或项目配置。

## Acceptance Criteria

- [ ] **GIVEN** EventBus 作为 Autoload 加载，**WHEN** 任意系统访问 `EventBus`，**THEN** 获得同一个全局单例实例
- [ ] **GIVEN** 系统A 订阅了 `test.event`，**WHEN** 系统B 调用 `EventBus.emit("test.event", {"key": "value"})`，**THEN** 系统A 的回调被调用，且 payload 等于 `{"key": "value"}`
- [ ] **GIVEN** 系统A 未订阅 `test.event`，**WHEN** `EventBus.emit("test.event")` 被调用，**THEN** 静默完成，无错误、无副作用
- [ ] **GIVEN** 系统A 订阅了 `test.event`，**WHEN** 系统A 调用 `EventBus.unsubscribe("test.event", callable)`，**THEN** 后续 emit 不再触发该 callable
- [ ] **GIVEN** 系统A 对 `test.event` 订阅了同一个 callable 两次，**WHEN** emit 被调用，**THEN** callable 只执行一次
- [ ] **GIVEN** 系统A 使用 `subscribe_once` 订阅 `test.event`，**WHEN** 事件被 emit 一次后再次 emit，**THEN** callable 只在第一次被调用
- [ ] **GIVEN** 3 个订阅者订阅同一事件，其中第 2 个 callable 在投递前已无效，**WHEN** `EventBus.emit()` 被调用，**THEN** 第 1 和第 3 个订阅者正常收到事件，第 2 个订阅记录被移除，控制台打印无效 callable 警告
- [ ] **GIVEN** 一个 Node 作为订阅者，**WHEN** 该 Node 被 `queue_free()` 释放，**THEN** EventBus 自动移除该 Node 的所有订阅，后续 emit 不触发该 Node 的回调
- [ ] **GIVEN** 回调执行中调用 `subscribe("other.event", callable)`，**WHEN** 当前 emit 完成，**THEN** 延迟的订阅生效，可接收后续 `other.event` 的 emit
- [ ] **GIVEN** 回调执行中再次对同一事件调用 `emit`，**WHEN** 检测到递归，**THEN** 递归 emit 被忽略，控制台打印警告
- [ ] **GIVEN** 嵌套 emit 深度达到 9 层，**WHEN** 第 9 层尝试 emit，**THEN** emit 被截断，控制台打印深度警告
- [ ] **GIVEN** 单事件订阅者数量达到 129，**WHEN** 第 129 次 subscribe 被调用，**THEN** 订阅被拒绝，控制台打印上限警告
- [ ] **GIVEN** 对从未订阅过的 callable 调用 `unsubscribe`，**WHEN** 执行完毕，**THEN** 无错误、无副作用
- [ ] **GIVEN** `DEBUG_ENABLED = true`，**WHEN** 任意 emit 被调用，**THEN** 控制台输出事件名和当前订阅者数量
- [ ] **GIVEN** 同一帧内对 `resource.lingqi.changed` emit 100 次，**WHEN** `HIGH_EMIT_FREQUENCY_THRESHOLD = 50` 且调试模式开启，**THEN** 帧结束时打印高频告警
- [ ] **GIVEN** `subscribe_once` 的 callable 在投递前已无效，**WHEN** emit 尝试投递，**THEN** 该订阅被移除，后续 emit 不再触发该 callable
- [ ] **GIVEN** 一个事件有 10 个订阅者，每个回调耗时 0.01 ms，**WHEN** 执行 emit，**THEN** 总投递耗时 < 0.2 ms（含查找开销）
- [ ] **GIVEN** EventBus 初始化完成，**WHEN** 在帧内执行 100 次不同事件的 emit（每次 5 个订阅者），**THEN** 总耗时 < 0.5 ms（帧预算内）
- [ ] **GIVEN** 系统A 调用 `subscribe_pattern("resource", callable)`，**WHEN** EventBus.emit("resource.lingqi.changed", {...}) 被调用，**THEN** callable 被触发一次，第一个参数等于 `"resource.lingqi.changed"`，第二个参数等于 emit 的 payload
- [ ] **GIVEN** 系统A 调用 `subscribe_pattern("resource", callable)`，**WHEN** EventBus.emit("attribute.player.atk.base_changed", {...}) 被调用（前缀不匹配），**THEN** callable 不被触发
- [ ] **GIVEN** 系统A 调用 `subscribe_pattern("", callable)`（空 prefix），**WHEN** 注册被处理，**THEN** 注册被拒绝，控制台打印警告，后续任何 emit 都不触发该 callable
- [ ] **GIVEN** 系统A 同时调用 `subscribe("test.event", cb1)` 与 `subscribe_pattern("test", cb2)`，**WHEN** EventBus.emit("test.event", {...}) 被调用，**THEN** cb1 与 cb2 均被触发；cb1 收到一个参数（payload），cb2 收到两个参数（event_name + payload）
- [ ] **GIVEN** 系统A `subscribe_pattern("resource", callable)`，**WHEN** 调用 `unsubscribe_pattern("resource", callable)` 后再 emit `resource.lingqi.changed`，**THEN** callable 不再被触发
- [ ] **GIVEN** 系统A `subscribe_pattern("resource", callable)`，**WHEN** 错误地调用 `unsubscribe("resource", callable)`，**THEN** 该 pattern 订阅仍然有效（unsubscribe 与 unsubscribe_pattern 互不影响）
- [ ] **GIVEN** 同一帧内连续 10 次调用 `emit_coalesced("ui.hud.refresh", payload_i, "resource_panel")`，**WHEN** 帧末 flush 执行，**THEN** 订阅者只收到 1 次 `ui.hud.refresh`，payload 等于第 10 次调用的 payload

## Open Questions

| Question | Owner | Deadline | Resolution |
|----------|-------|----------|------------|
| payload Dictionary 是否深拷贝给每个订阅者，还是按只读约定引用传递？ | 开发者 | 实现阶段前 | 保留：默认倾向引用传递 + 订阅者只读约定；如测试发现写穿透风险，再改为 debug 防御或浅拷贝。 |
