# 调试控制台 (Debug Console)

> **Status**: In Design
> **Author**: binlee1990 + agents
> **Last Updated**: 2026-05-03
> **Implements Pillar**: 4.10 数据驱动与可扩展

## Overview

调试控制台是 MVP 开发阶段的统一诊断入口——开发者在游戏运行时按 `~` 键呼出一个覆盖层，输入文本命令（或从命令面板选择），即时查看任意系统的内部状态：资源当前值、事件流日志、配置表内容、已注册的 modifier 列表、实体属性快照、产出速率分解。它不替代 Godot 内置的 `@tool` 脚本编辑器或 `print()` 调试——而是把"运行时看一眼就知道系统在做什么"的体验集中到一个入口，避免开发者在多个 Godot dock 面板之间反复切换。

从使用者（开发者+QA）视角看，调试控制台是"游戏体内的一台 X 光机"。开发资源系统时，敲 `res list` 看 5 项资源的 current/cap；调事件总线时，敲 `event watch resource` 实时打印每一条 `resource.*.changed` 的 payload；验证掉落系统时，敲 `config show enemies` 看敌人数据库全表。不需要临时写 `print()` 语句然后重启、不需要在 Godot 编辑器的 Remote Scene Tree 里手动展开节点——一条命令，实时反馈。这个系统的全部价值就是：**让开发者和 QA 在运行时拥有一双穿透所有系统的眼睛**，缩短"怀疑 → 验证 → 定位"的迭代循环。

> **Note**：调试控制台是 MVP 的**开发辅助工具**——不面向玩家，不影响游戏平衡，不在正式构建中编译。它与 Godot 内置控制台（`@tool` / `OS.debug`）的关系是补充而非替代：Godot 内置控制台提供脚本错误、`print()` 输出和表达式求值；本系统提供领域特定的快速查询命令（`res`、`event`、`config`、`modifier`、`attr`、`prod`）。

## Player Fantasy

调试控制台是开发者的**神识**——修仙者以神识内视丹田经脉、洞察灵气流转；开发者以控制台内视游戏运行时状态，洞察每一个系统的数据流动。

**锚定时刻**：你正在实现修正器/倍率引擎的叠加顺序。灵气的最终产出速率不对——应该是 ×3.30，实际却是 ×2.85。你会怎么做？以往你需要：在 ModifierEngine 的 `apply()` 里加 `print()` → 重新编译 → 触发一次产出查询 → 在 Godot 输出面板翻几十行日志 → 发现 realm 池倍率是 1.5 而不是 2.0 → 回到境界系统的注册代码检查 → 再来一轮。有了调试控制台，你敲 `prod breakdown lingqi`，屏幕直接打印完整池分解，3 秒定位 bug——realm 的 value 注册为 0.5 而不是 1.0。不需要 `print()`、不需要重启、不需要翻日志。

这就是调试控制台的核心承诺：**让开发者在运行时拥有一双穿透所有系统的眼睛**，把"怀疑 → 验证 → 定位"的循环从分钟级压缩到秒级。`res list` 是扫视资源经脉、`event watch` 是追踪灵气波动、`config show` 是翻阅天书玉简、`modifier list` 是查看阵法叠加——每条命令都是一道神识探入对应系统的底层。

**支柱对应**：
- **4.10 数据驱动与可扩展**：调试控制台直接服务于数据驱动架构的开发效率——当所有内容都在 JSON 配置表中时，开发者需要一个即时查看配置加载结果的工具，而不是去翻原始 JSON 文件。

## Detailed Design

### Core Rules

1. **架构形态**：`DebugConsole` 作为 Autoload 单例（`/root/DebugConsole`），项目设置中无条件注册。Autoload 节点通过 `add_child(preload("res://src/tools/debug_console/debug_console.tscn").instantiate())` 在 `_ready()` 中挂载 UI 子树。理由：`.tscn` 允许在编辑器中直观检视布局，调试工具自身出 bug 时排查更容易。

2. **发布构建排除**：`_ready()` 第一行执行 `if not OS.is_debug_build(): queue_free(); return;`——发布构建（Release Export）中 Autoload 节点被立即销毁，零内存驻留、零 `_process` 调用、零 UI 残留、零事件监听。`~` 键输入因节点已不存在而自动失效。Debug Export 中保留功能（开发者/QA 使用）。

3. **暂停期间存活**：Autoload 节点设置 `process_mode = Node.PROCESS_MODE_ALWAYS`，保证调用 `get_tree().paused = true` 后控制台仍能响应输入和渲染。

4. **UI 渲染层级**：UI 子树根节点为 `CanvasLayer`，`layer = 128`，确保渲染于游戏 HUD（layer 1–10）之上。Godot 内置 Debugger Overlay 不经普通 CanvasLayer，无层级竞争。`CanvasLayer.visible` 初始为 `false`。

5. **激活与停用**：`_input(event)` 捕获按键，**使用 `event.physical_keycode == KEY_QUOTELEFT`**（物理键位，跨键盘布局稳定，4.x 标准做法）。按下时切换 `CanvasLayer.visible` 与 `get_tree().paused`，并调用 `get_viewport().set_input_as_handled()` 阻止 `~` 字符写入 LineEdit 或泄漏到游戏。

6. **打开流程**：（1）`_previous_focus = get_viewport().gui_get_focus_owner()` 缓存前焦点；（2）`get_tree().paused = true`；（3）`CanvasLayer.visible = true`；（4）控制台根 Control 设 `mouse_filter = MOUSE_FILTER_STOP` 阻断鼠标穿透；（5）`LineEdit.grab_focus()` 抓取键盘焦点（Godot 4.6 双焦点：仅键盘焦点，鼠标可在输出区自由选中文本）。

7. **关闭流程**：（1）注销所有活跃的 `event watch` 订阅（见规则 9 与 States and Transitions）；（2）`CanvasLayer.visible = false`；（3）`get_tree().paused = false`；（4）若 `is_instance_valid(_previous_focus)` 则调用其 `grab_focus()`，否则 `LineEdit.release_focus()`。

8. **命令解析模型**：输入字符串按空白符分词（`String.split(" ", false)`），第一个 token 为**命令名**，后续 token 为**有序参数列表**。支持双引号包裹含空格的参数（如 `attr "enemy yougui a"`）：扫描 token 序列，遇 `"` 开头则合并到下一个以 `"` 结尾的 token，去引号后作为单一参数。不支持反斜杠转义。无嵌套子命令（`res list` 中 `res` 是命令名、`list` 是第一个参数）。

9. **命令注册（静态硬编码）**：注册表在 `DebugConsole._ready()` 中以字典形式构建，不对外暴露动态注册接口。结构：

   ```gdscript
   _commands: Dictionary = {
       "res":      { "handler": Callable(self, "_cmd_res"),      "help": "res list" },
       "event":    { "handler": Callable(self, "_cmd_event"),    "help": "event watch <prefix> | event unwatch <prefix>" },
       "config":   { "handler": Callable(self, "_cmd_config"),   "help": "config list | config show <table> | config get <table> <id> | config reload [<table>]" },
       "modifier": { "handler": Callable(self, "_cmd_modifier"), "help": "modifier list | modifier breakdown <target>" },
       "attr":     { "handler": Callable(self, "_cmd_attr"),     "help": "attr [<entity_id>]" },
       "prod":     { "handler": Callable(self, "_cmd_prod"),     "help": "prod breakdown <resource_id>" },
       "time":     { "handler": Callable(self, "_cmd_time"),     "help": "time status | time freeze | time unfreeze | time speed <N> | time speed reset" },
       "save":     { "handler": Callable(self, "_cmd_save"),     "help": "save now | save dump [<namespace>]" },
       "help":     { "handler": Callable(self, "_cmd_help"),     "help": "help [<command>]" },
       "clear":    { "handler": Callable(self, "_cmd_clear"),    "help": "clear" },
   }
   ```

   理由：所有命令针对内置系统编写，控制台是唯一消费方；动态注册引入生命周期复杂度而无收益。

10. **处理器签名**：每个命令处理器返回输出行数组。签名 `func _cmd_xxx(args: Array[String]) -> Array[String]`。处理器**不直接写 UI**——调度层统一将返回数组追加到输出缓冲区。处理器抛出异常时由调度层捕获（见规则 13）。

11. **输出渲染**：
    - 输出区：`RichTextLabel`，`bbcode_enabled = true`、`scroll_following = true`、`selection_enabled = true`。
    - 等宽字体：`SystemFont` 资源 + `font_names = ["Courier New", "Courier", "monospace"]`，系统级 fallback，零外部资产依赖。
    - 时间戳前缀：每行追加 `[HH:MM:SS] `（`Time.get_time_string_from_system()`）。
    - BBCode 颜色约定：命令回显 `[color=gray]`、正常输出 `[color=white]`、警告 `[color=yellow]`、错误 `[color=red]`、`event watch` 实时行 `[color=cyan]`。
    - **缓冲实现**：业务层维护 `_output_buffer: Array[String]`（`SCROLLBACK_LIMIT = 500`），追加行时若超限则 `pop_front()` 然后 `clear()` + 全量 `append_text()` 重建（`RichTextLabel` 无原生删行 API；500 行级别重建 < 1 ms 可接受）。

12. **命令历史**：
    - 内存维护 `_history: Array[String]`，`HISTORY_LIMIT = 50`，超限 `pop_front()`。仅非空字符串实际执行后写入。
    - `LineEdit.gui_input` 信号回调中拦截 `KEY_UP` / `KEY_DOWN`，调用 `accept_event()` 阻止默认光标移动，滚动历史并设置 `_line_edit.text = _history[i]`、`_line_edit.caret_column = _history[i].length()`。
    - **不跨会话持久化**——MVP 决策。需要时未来扩展到 `user://debug_console_history.json`。

13. **错误处理**：
    - **未知命令**：输出 `[color=red][ERROR] Unknown command: '{name}'. Type 'help' for a list.[/color]`。
    - **参数错误**：处理器自行校验，返回含 `[color=red][ERROR] Usage: {usage}[/color]` 行的数组。
    - **处理器异常**：调度层用 `push_error` + 异常隔离包裹，输出 `[color=red][EXCEPTION] {command}: {error}[/color]`，控制台继续运行。
    - **目标系统 Autoload 缺失**：处理器先检查 `has_node("/root/SystemName")`，缺失时返回 `[color=yellow][WARN] System not available: {name}[/color]`。

14. **帮助系统**：
    - `help`（无参）：列出所有已注册命令名 + 各自 `help` 字段一行简介。
    - `help <command>`：输出该命令的 `help` 字段全文（语法 + 示例）。
    - `help` 命令本身在注册表中。

### States and Transitions

#### 状态定义

| 状态 | `CanvasLayer.visible` | `get_tree().paused` | `LineEdit` 焦点 | EventBus 订阅 |
|------|----------------------|--------------------|----------------|--------------|
| **Hidden** | false | false（控制台不影响） | 无 | 无 |
| **Visible_Idle** | true | true | LineEdit 持有 | 无 |
| **Visible_Watching** | true | true | LineEdit 持有 | ≥1 个 `subscribe_pattern` 活跃 |

> `Visible_Idle` 与 `Visible_Watching` 共享所有 UI 行为，唯一差异是是否有活跃的事件订阅。

#### 转换表

| 源状态 | 触发 | 目标 | 动作 |
|--------|------|------|------|
| Hidden | `~` 键按下 | Visible_Idle | 缓存前焦点 → 暂停游戏 → 显示面板 → grab_focus(LineEdit) |
| Visible_Idle | `~` 键按下 | Hidden | 隐藏面板 → 恢复游戏 → 恢复前焦点 |
| Visible_Idle | 执行 `event watch <prefix>` | Visible_Watching | `EventBus.subscribe_pattern(prefix, _on_event)`，记入 `_watching_prefixes` |
| Visible_Watching | 执行 `event unwatch <prefix>`（且仅剩此项） | Visible_Idle | `EventBus.unsubscribe_pattern(prefix, _on_event)` |
| Visible_Watching | 执行 `event unwatch <prefix>`（仍有其余订阅） | Visible_Watching | 注销该 prefix，保留其余 |
| Visible_Watching | `~` 键按下 | Hidden | **遍历 `_watching_prefixes` 全部 unsubscribe_pattern** → 同 Visible_Idle → Hidden |
| Visible_*  | `time freeze` / `time speed` 命令 | 状态不变 | TimeManager 状态变化与控制台 UI 状态正交 |

#### 守卫条件

- 任何状态进入仅在 `OS.is_debug_build() == true` 时可达——发布构建中节点不存在，整套状态机不生效。
- `event watch` 在 prefix 为空字符串时拒绝并报错（防止订阅所有事件导致 UI 刷爆）。

### Interactions with Other Systems

#### EventBus

| 项 | 内容 |
|----|------|
| 流入（控制台调用） | `EventBus.subscribe_pattern(prefix: String, callable: Callable)` — `event watch` 时调用；`EventBus.unsubscribe_pattern(prefix: String, callable: Callable)` — `event unwatch` 或控制台关闭时调用 |
| 流出 | 无——控制台不发布任何事件 |
| 接口归属 | EventBus 拥有；控制台是纯消费方 |
| 回调格式 | `_on_watched_event(event_name: String, payload: Dictionary)`：追加 `[WATCH] {event_name} → {payload}` 到输出缓冲（青色） |
| 多 watch 支持 | `_watching_prefixes: Dictionary[String, Callable]` 追踪每 prefix → callable，支持同时观察多前缀 |
| **EventBus GDD 必须补充的接口** | `subscribe_pattern(prefix, callable) -> void` 与 **对称的** `unsubscribe_pattern(prefix, callable) -> void`。本 GDD 完成后需在 EventBus GDD 追加修订条目（Phase 5 处理）。 |

#### DataConfig

| 项 | 内容 |
|----|------|
| 流入 | `get_table_names()`（`config list`）；`get_all(table)`（`config show <table>`）；`get(table, id)`（`config get <table> <id>`）；`reload_table(table)` / `reload_all()`（`config reload`，DataConfig 内部已有 debug-build 门控） |
| 流出 | 无 |
| 接口归属 | DataConfig 拥有 |
| 输出格式 | `config show <table>` 将每条记录序列化为单行 JSON（`JSON.stringify(record, "", 0)`，无缩进）以保持滚动缓冲行计数一致 |

#### ResourceSystem

| 项 | 内容 |
|----|------|
| 流入 | `get_all_ids()`、`get_value(id) -> BigNumber`、`get_max(id) -> BigNumber`、`get_definition(id) -> Dictionary` |
| 流出 | 无 |
| 接口归属 | ResourceSystem 拥有 |
| 命令 | `res list` — 遍历所有 ID，每行 `{id}  {current} / {cap}  [{category}]`；BigNumber 优先调用 NumberFormattingSystem，缺失时 fallback `BigNumber.to_string()` |
| 写操作 | **不提供** — 控制台对资源只读。需要注入测试值时由开发者用 Godot Remote Inspector 直接修改字段。 |

#### AttributeSystem

| 项 | 内容 |
|----|------|
| 流入 | `has_entity(id)`、`get_all_entity_ids()`、`get_attribute_set(id) -> Dictionary`（base）、`get_final_set(id) -> Dictionary`（final，内部经 ModifierEngine 计算） |
| 流出 | 无 |
| 接口归属 | AttributeSystem 拥有 |
| 命令 | `attr`（无参）— 列出所有已注册 entity_id；`attr <id>` — 并列输出每属性 `{attr_id}  base={base}  final={final}`，`final != base` 时追加 `(+{pct}%)` 差值 |

#### ModifierEngine

| 项 | 内容 |
|----|------|
| 流入 | `get_breakdown(target) -> Dictionary`；**需新增** `get_all_targets() -> Array[String]`（`modifier list` 命令需要） |
| 流出 | 无 |
| 接口归属 | ModifierEngine 拥有 |
| 命令 | `modifier list` — 列出所有已注册 target；`modifier breakdown <target>` — 输出每池贡献：`add_sum: {v}` / `pool[{name}]: ×{mult}` / `final_mult: {f}` |
| **下游 GDD 缺口** | `ModifierEngine.get_all_targets()` 当前未声明。需在 ModifierEngine GDD 补充，或实现阶段从内部 `_modifiers` 字典 target 字段集合派生。Phase 5 会标记此缺口供后续处理。 |

#### OutputMultiplierSystem

| 项 | 内容 |
|----|------|
| 流入 | 优先 `OutputMultiplierSystem.get_final_rate(resource_id) -> BigNumber` 与配套 breakdown 方法；fallback 路径：经 ModifierEngine 查询 target=`{resource_id}_production` |
| 流出 | 无 |
| 接口归属 | OutputMultiplierSystem 拥有 |
| 命令 | `prod breakdown <resource_id>` — Section A+B 承诺的核心命令；输出 base_rate、各源类型池倍率、final_mult、effective_rate（与 ResourceSystem 实际产出速率应一致） |
| **下游 GDD 缺口** | OMS 的高层 breakdown API 当前未声明。fallback 路径在语义上可行，但会绕过 OMS 的 `allows_passive` 白名单，dump 结果可能与实际产出路径不一致。需在 OMS GDD 实现阶段明确。 |

#### TimeManager

| 项 | 内容 |
|----|------|
| 流入 | `get_real_time()`、`get_game_time()`、`get_effective_speed()`、`freeze()` / `unfreeze()`、`add_speed_source(id, mult)` / `remove_speed_source(id)` |
| 流出 | 无 |
| 接口归属 | TimeManager 拥有 |
| 命令集 | `time status` — 输出 real/game/effective_speed/frozen；`time freeze`、`time unfreeze`；`time speed <N>` — 以 source_id `"debug_console"` 注册倍率，N ∈ [0.1, 100.0]，超出拒绝；`time speed reset` — 移除 `"debug_console"` 来源 |
| 与 `get_tree().paused` 关系 | 控制台用 `paused = true` 暂停场景树（影响动画/物理/`_process`）；`time freeze` 影响 TimeManager 的逻辑时间累计。两者正交：开控制台 = 场景暂停；`time freeze` = 业务时间冻结。开发者可组合使用。 |

#### SaveSystem

| 项 | 内容 |
|----|------|
| 流入 | `SaveManager.save_game()`（`save now`）；`SaveManager.collect_save_data() -> Dictionary`（`save dump`，**需新增**） |
| 流出 | 无 |
| 接口归属 | SaveManager 拥有 |
| 命令 | `save now` — 立即写存档；`save dump` — 收集所有 provider 数据（不写文件）输出 JSON；`save dump <namespace>` — 仅 dump 指定 namespace |
| **下游 GDD 缺口** | 当前 SaveManager 设计中 `save_game()` 是收集+写入一体；`save dump` 需要拆出 `collect_save_data()` 内部方法。需在 SaveSystem GDD 实现阶段评估是否拆分（其他场景如"存档预览"功能也可复用）。 |

## Formulas

> **说明**：本系统无游戏数学公式（无伤害/产出/成长等计算），以下三式为运行时性能预算，用于实现阶段验证不同操作的耗时是否在可接受范围。

### 1. 输出缓冲重建耗时 (Output Buffer Rebuild Cost)

`T_rebuild = T_clear + N × T_append`

**变量：**

| 变量 | 符号 | 类型 | 范围 | 描述 |
|------|------|------|------|------|
| 重建后保留行数 | N | int | 0–499 | `pop_front()` 后写回 RichTextLabel 的行数；正常情况为 499（SCROLLBACK_LIMIT - 1） |
| 单行追加耗时 | T_append | float | 0.05–0.20 ms | 每次 `append_text()` 的 BBCode 解析 + 字形布局耗时；约 80 字符/行（含时间戳前缀和 BBCode 色彩标签）；来源：Godot 4.x RichTextLabel BBCode 渲染路径实测估算 |
| `clear()` 耗时 | T_clear | float | 0.1–0.5 ms | `RichTextLabel.clear()` 释放内部 paragraph 链表并触发重绘；Godot 4.x 内部实现无逐行遍历，属常数级操作 |
| 总重建耗时 | T_rebuild | float | 0–无上界（实际有界） | 一次溢出触发的完整重建总耗时（ms）；控制台处于暂停模式，不与游戏帧竞争 |

**输出范围：** 最小约 0.6 ms（N=0，仅 `clear()`）；典型值 25.1–100.1 ms（N=499，T_append=0.05–0.20 ms 区间）；**最坏 100.1 ms**。

> **预算结论：** 典型 T_append=0.10 ms 时 T_rebuild ≈ 50 ms，**超过单帧 16.6 ms**。在暂停模式下不影响游戏帧率，但开发者会感知 UI 短暂卡顿。建议实现阶段测量真实 T_append——若超过 0.03 ms/行，改为懒加载（仅渲染可视区域行）而非全量重建。

**示例（T_append 取保守中值 0.10 ms）：**

```
T_clear   = 0.30 ms
N         = 499
T_append  = 0.10 ms
T_rebuild = 0.30 + 499 × 0.10 = 50.20 ms
```

### 2. `event watch` 单帧回调累计耗时 (Per-Frame Watch Callback Cost)

`T_watch = M × (T_match + T_format) + V × M × T_render`

**变量：**

| 变量 | 符号 | 类型 | 范围 | 描述 |
|------|------|------|------|------|
| 单帧匹配到的事件数 | M | int | 0–无上界（实际建议 ≤500） | 一帧内 EventBus 发射且 prefix 匹配成功的事件数；如 `event watch resource` 在离线结算回放时可达 50–500 次/帧 |
| 前缀匹配耗时 | T_match | float | 0.003–0.008 ms | `String.begins_with()` GDScript 原生字符串操作；O(k)，k 为 prefix 长度（约 8–16 字符） |
| 回调内格式化 + 缓冲追加耗时 | T_format | float | 0.02–0.10 ms | `"[WATCH] %s → %s" % [...]` 字符串拼接 + `_output_buffer.append()`；payload 序列化为主要开销 |
| 控制台可见标志 | V | int | 0 或 1 | Visible_Watching 状态时为 1，Hidden 时为 0（GDD 规则 7 中关闭即 unsubscribe，故正常为 0） |
| 单行 RichTextLabel 追加耗时 | T_render | float | 0.05–0.20 ms | 同 F1 中 T_append；仅在 V=1 时产生 |
| 单帧 watch 总耗时 | T_watch | float | 0–无上界 | 一帧内所有 watch 回调的累计耗时（ms） |

**输出范围：** V=0 时 M×0.023 ms 起；V=1、M=50 典型 6.65–15.0 ms；M=200 时 26.6–60.0 ms（超过 16.6 ms 触发警告）。

**预算阈值（实现阶段日志告警触发条件）：**

| M 每帧 | V=0（仅后台格式化） | V=1（前台渲染） | 行动 |
|--------|-------|-------|------|
| ≤ 50 | ≤ 5 ms | ≤ 15 ms | 正常 |
| 51–200 | ≤ 20 ms | ≤ 60 ms | 输出黄色警告：`[WARN] event watch: {M} events/frame — consider narrowing prefix` |
| > 200 | > 20 ms | > 60 ms | 自动降频：每 10 帧合并输出一次（batch），输出红色警告 |

**示例（`event watch resource`，离线结算回放，V=1）：**

```
M        = 50
T_match  = 0.005 ms
T_format = 0.06 ms
T_render = 0.10 ms
T_watch  = 50 × (0.005 + 0.06) + 1 × 50 × 0.10
         = 3.25 + 5.0 = 8.25 ms ✓（< 16.6 ms 帧预算）
```

### 3. 命令分发端到端延迟 (Command Dispatch Latency)

`T_dispatch = T_parse + T_lookup + T_handler + L × T_append`

**变量：**

| 变量 | 符号 | 类型 | 范围 | 描述 |
|------|------|------|------|------|
| 输入解析耗时 | T_parse | float | 0.01–0.10 ms | `String.split()` + 引号合并扫描；token ≤ 20（GDD 规则 8） |
| 命令查找耗时 | T_lookup | float | 0.003–0.008 ms | `_commands[name]` Dictionary 访问；O(1)；当前 10 条命令 |
| 处理器执行耗时 | T_handler | float | 0.01–5.0 ms | 命令处理器本体耗时；范围因命令而异（见下方分级表） |
| 处理器输出行数 | L | int | 0–500 | 处理器返回 `Array[String]` 长度；`clear` 返回 0，`config show enemies` 可达 500 |
| 单行追加耗时 | T_append | float | 0.05–0.20 ms | 同 F1 中 T_append |
| 端到端总延迟 | T_dispatch | float | > 0 | 从 Enter 按下到首行输出可见的总耗时（ms） |

**处理器分级参考（T_handler 估算）：**

| 命令 | 典型 T_handler | 说明 |
|------|------------|------|
| `clear` | ~0.01 ms | 清空缓冲区引用 |
| `help` | ~0.05 ms | 遍历 10 条注册项 |
| `res list` | ~0.10 ms | 遍历 5 资源 + BigNumber 格式化 |
| `time status` | ~0.05 ms | 4 次 TimeManager 字段读取 |
| `prod breakdown lingqi` | ~1.0 ms | ModifierEngine 池遍历 + OMS 计算 |
| `attr 主角` | ~0.5 ms | AttributeSystem 属性集 + 差值 |
| `modifier list` | ~0.2 ms | 遍历所有已注册 target |
| `config show enemies` | ~1.0–5.0 ms | DataConfig 全表 dump（500 条时） |
| `save dump` | ~2.0–5.0 ms | 所有 provider collect + 序列化 |
| `event watch resource` | ~0.01 ms | 仅一次 subscribe_pattern |

**输出范围：** 最小约 0.12 ms（`clear`，L=0）；P50 约 2–10 ms；**P95 目标 < 50 ms**；可接受上界 < 200 ms（`config show enemies` 500 条 + 渲染：~101 ms）。

**示例 A — `prod breakdown lingqi`（典型调试命令）：**

```
T_parse    = 0.05 ms
T_lookup   = 0.005 ms
T_handler  = 1.0 ms
L          = 8
T_append   = 0.10 ms
T_dispatch = 0.05 + 0.005 + 1.0 + 8 × 0.10 = 1.86 ms ✓（远低于 50 ms P95）
```

**示例 B — `config show enemies`（最坏情况，500 条记录）：**

```
T_parse    = 0.05 ms
T_lookup   = 0.005 ms
T_handler  = 5.0 ms
L          = 500
T_append   = 0.15 ms
T_dispatch = 0.05 + 0.005 + 5.0 + 500 × 0.15 = 80.06 ms ✓（< 200 ms 可接受上界）
```

## Edge Cases

### Build & Lifecycle

- **If 在发布构建（Release Export）中运行**：`_ready()` 第一行 `queue_free(); return` 立即销毁节点，`~` 键不响应，零内存。
- **If Autoload 初始化时依赖系统（ResourceSystem / EventBus 等）尚未完成 `_ready()`**：命令处理器在执行时按需 `has_node("/root/SystemName")` 检查，缺失时返回 `[color=yellow][WARN] System not available: {name}[/color]`；不在 `_ready()` 阶段预检（Godot Autoload 初始化顺序由项目设置决定，运行期惰性检查比启动顺序约束更健壮）。
- **If 场景切换发生时控制台处于 Visible_Watching 状态**：Autoload 跨场景存活，订阅仍有效；若场景切换同时触发 EventBus 重置，`_watching_prefixes` Callable 失效，下次 `unsubscribe_pattern` 是 no-op，并清空字典，输出 `[color=yellow][WARN] Watch for '{prefix}' was invalidated by scene reload.[/color]`。
- **If `queue_free()` 与控制台其他逻辑同帧竞争**：Godot `queue_free` 在帧末执行，当帧 `_input` 与 `_cmd_xxx` 仍可安全完成。

### 输入

- **If 在 AZERTY/QWERTZ 键盘上按 `~` 等效物理键**：`physical_keycode == KEY_QUOTELEFT` 与键盘布局无关，正常触发。
- **If 用户激活 IME（中文/日文/韩文输入法）后按 `~` 物理键**：IME 可能先消费按键，`_input` 收不到事件——接受平台限制，开发者需先关闭 IME 再按 `~`。
- **If 用户在控制台已打开时快速双击 `~`（间隔 < 1 帧）**：第一次 Open，第二次 Close；控制台闪烁后关闭，状态正确，无损坏。
- **If `~` 键被玩家在 InputMap 重绑定为游戏动作**：控制台用 `physical_keycode` 原始硬件路径，不经 InputMap，不受影响。

### 控制台开关与状态

- **If 打开控制台时 `get_tree().paused` 已为 true（游戏内暂停菜单已激活）**：Open 流程开头 `_tree_was_paused_before = get_tree().paused`；Close 仅在 `_tree_was_paused_before == false` 时执行 `paused = false`，否则保持暂停。**这是 Section C 规则 6/7 的实现细化**，确保不会意外解除游戏内暂停菜单的暂停状态。
- **If 打开控制台时存在另一模态对话框**：`_previous_focus = get_viewport().gui_get_focus_owner()` 缓存其控件引用，Close 时 `is_instance_valid()` 为 true 则正常恢复焦点。
- **If 控制台 Hidden 但 `_watching_prefixes` 非空（理论上不可达）**：`CanvasLayer.visibility_changed` 信号回调中检测到 `visible == false` 且字典非空时补调清理逻辑，输出 `[color=yellow][WARN] Orphaned watches detected and cleaned up.[/color]`。
- **If `_previous_focus` 节点在控制台打开期间被销毁（UI 场景切换等）**：Close 时 `is_instance_valid()` 为 false，调用 `LineEdit.release_focus()` 代替，不崩溃，不恢复焦点。
- **If LineEdit 焦点被外部 UI 元素（如 tooltip）在控制台打开期间抢走**：控制台不强制重抢焦点；开发者可点击 LineEdit 区域恢复，或重开控制台。**理由**：自动焦点守卫会干扰输出区文本选中功能。

### 命令解析

- **If 提交空字符串或仅空白符（只按空格后回车）**：`tokens.is_empty()`，无操作，不写历史，不输出。
- **If quoted arg 内容仅含空白（如 `attr "   "`）**：处理器对参数 `.strip_edges()` 后视为空，返回 `[color=red][ERROR] Usage: attr [<entity_id>][/color]`。
- **If 命令名大小写混合（如 `RES list`、`Help`）**：调度层对第一个 token `.to_lower()` 后查表；命令名不区分大小写。子命令参数（`list`/`watch`/`show`）由各处理器决策（约定同样 `.to_lower()`）。
- **If 输入含未闭合引号（如 `attr "enemy yougui`）**：剩余所有 token 合并为一参数（去开头 `"`），不报错。**理由**：调试工具宽松解析优于严格拒绝；当前 10 个命令均最多 1 个 quoted arg，宽松合并不会造成歧义。
- **If 参数内含字面换行符（粘贴多行文本）**：`LineEdit` 不接受多行输入，换行符在粘贴时被 Godot 过滤为空格，解析层无需处理。
- **If 输入超过 1000 字符**：`KEY_ENTER` 处理时检查 `text.length() > 1000`，输出 `[color=red][ERROR] Input too long (max 1000 chars).[/color]`，不执行命令，不写历史，清空 LineEdit。

### 命令执行

- **If 命令名未知**：输出 `[color=red][ERROR] Unknown command: '{name}'. Type 'help' for a list.[/color]`，不写入历史。
- **If 处理器抛出未捕获异常**：调度层捕获并输出 `[color=red][EXCEPTION] {command}: {error}[/color]`，控制台继续运行，异常命令不写入历史。
- **If 命令目标 Autoload（如 `ResourceSystem`）在运行时不存在**：处理器首行 `if not has_node("/root/ResourceSystem"): return ["[color=yellow][WARN] System not available: ResourceSystem[/color]"]`，不尝试调用空引用。
- **If DataConfig 在 `load_all()` 完成前调用 `config show <table>`**：处理器调用 `DataConfig.is_loaded()`（**需新增**）或捕获异常，输出 `[color=yellow][WARN] DataConfig not yet loaded.[/color]`。
- **If 单条命令返回行数恰好等于 SCROLLBACK_LIMIT (500)**：缓冲区 K + 500 行，K > 0 触发 `pop_front` + `clear` + 全量重建；K = 0 时不触发。重建在同帧内完成（控制台暂停模式下帧预算充裕）。
- **If 单条命令返回 > 500 行（如 `config show` 一张 600 条记录的表）**：处理器在返回前对输出数组截断至 500 行，追加 `[color=yellow][WARN] Output truncated to 500 lines.[/color]` 作为最后一行；调度层不做二次截断。

### event watch

- **If `event watch` 的 prefix 为空字符串**：守卫拒绝，输出 `[color=red][ERROR] Prefix must not be empty. Usage: event watch <prefix>[/color]`，不调用 `subscribe_pattern`。
- **If 对同一 prefix 重复执行 `event watch`**：调度层在调用前检查 `_watching_prefixes.has(prefix)`，若已存在则输出 `[color=yellow][WARN] Already watching '{prefix}'. No-op.[/color]`，不重复订阅（防止 EventBus 侧双重回调）。
- **If 执行 `event unwatch <prefix>` 但该 prefix 从未被 watch**：检查 `has(prefix)` 为 false，输出 `[color=yellow][WARN] Not watching '{prefix}'. No-op.[/color]`，不调用 `unsubscribe_pattern`。
- **If watch 回调（`_on_watched_event`）内部抛出异常（如 payload 序列化失败）**：回调内部 try-catch 捕获，输出 `[color=red][EXCEPTION] watch callback for '{prefix}': {error}[/color]`，不取消订阅，控制台继续运行。
- **If 控制台关闭（`~` 键）时 `_watching_prefixes` 仍有活跃订阅**：Close 流程第一步遍历字典，对每 prefix 调用 `EventBus.unsubscribe_pattern(prefix, callable)`，清空字典；保证无泄漏订阅。
- **If watch 事件 payload 为嵌套 BigNumber 对象**：`_on_watched_event` 在格式化前对 payload 每个 value 调 `str()` 浅层序列化，确保 BigNumber 输出为可读字符串；序列化失败则输出 `[WATCH] {event_name} → [payload serialize error]`。

### 输出缓冲与内存

- **If `_output_buffer` 已有 499 行追加 1 行**：500 行未超限（上限检查为 `> SCROLLBACK_LIMIT`），不触发重建。
- **If `_output_buffer` 已有 500 行追加 1 行**：超限，`pop_front()` 移除最旧行（保留 499 行），随后 `RichTextLabel.clear()` + 全量 `append_text()` 重建，含新行共 500 行。

### 命令历史

- **If 按 KEY_UP 时历史为空**：`_history.is_empty()` 为 true，无操作，LineEdit 内容不变，不报错。
- **If 连续按 KEY_DOWN 已到历史顶部（最新条目）再继续按**：索引钳位在 0，LineEdit 显示最新历史条目，不越界，不报错。
- **If 历史已满 50 条再执行新命令**：`push_back(cmd)` 后若 `size() > HISTORY_LIMIT` 则 `pop_front()`；最旧条目被移除，新条目在末尾，历史保持 50 条。

### time / save 命令特定

- **If `time speed 0` 或 `time speed -1`**：超出范围 `[0.1, 100.0]`，返回 `[color=red][ERROR] Speed must be in range [0.1, 100.0]. Got: {N}.[/color]`，不调用 `add_speed_source`。极慢速调试场景应使用 `time freeze` 而非小于 0.1 的 speed。
- **If `time speed 1000`**：超上界 100.0，返回相同错误格式，不执行。
- **If `save now` 在前一次保存仍执行中（异步 IO 未完成）时被调用**：处理器检查 `SaveManager.is_saving()`（**需新增**）；为 true 时输出 `[color=yellow][WARN] Save already in progress. Command ignored.[/color]`。
- **If `save dump` 调用时没有任何 provider 注册**：`collect_save_data()` 返回 `{}`；处理器输出 `{}` 并追加 `[color=yellow][WARN] No save providers registered.[/color]`，不视为错误。

## Dependencies

[To be designed]

## Tuning Knobs

[To be designed]

## Visual/Audio Requirements

[To be designed]

## UI Requirements

[To be designed]

## Acceptance Criteria

[To be designed]

## Open Questions

[To be designed]
