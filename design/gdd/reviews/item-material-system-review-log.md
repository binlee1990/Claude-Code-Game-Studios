# Review Log — 物品/材料系统 (Item/Material System)

> Path: `design/gdd/item-material-system.md`
> 维护规则：每次评审追加在表底；不删除历史条目。

---

## Review — 2026-05-03 — Verdict: CONCERNS (accepted, internal CD-GDD-ALIGN)
Scope signal: M
Specialists: creative-director (CD-GDD-ALIGN, 内部对齐评审)
Blocking items: 0 | Recommended: 3
Summary: 内部 CD-GDD-ALIGN 评审通过。3 项非阻塞修订已应用：(1) Player Fantasy 显性区分 MVP 兑现度；(2) Open Questions 追加"Alpha 重写 Player Fantasy"承诺；(3) 澄清"千年血参"为 Alpha 示意。MVP 数据集仅 5 条 resource_material；本系统作为"沉默的命名者"定位清晰，不持有玩家库存（库存归 ResourceSystem）。
Prior verdict resolved: First review

---

## Review — 2026-05-03 — Verdict: NEEDS REVISION → REVISED (independent /design-review)
Scope signal: M (按 Alpha 接入难度计；MVP 实施本身是 S)
Specialists: game-designer · systems-designer · godot-gdscript-specialist · performance-analyst · qa-lead · creative-director (senior)
Blocking items: 7 | Recommended: 15 | Nice-to-have: 9
Summary: 独立 /design-review 在 5 specialist 对抗性评审 + creative-director 综合裁定下，发现 7 项 BLOCKING（公式 3 query 路径错建模 + Alpha 性能 AC 缺位 / AC-C2 把 footgun 验证为通过条件 / assert 与降级矛盾 / AC-D1 不可执行 / AC-G1 payload schema 未定义 / Alpha 性能门槛缺失 / rarity 8 元枚举完整性 AC 缺失）。修订工作量集中且明确：60-90 行 GDD 改动，含 4 项设计决策 — get_field → peek_field 重命名、categories payload 用 `Dictionary[String, int]` 轻量统计、category 字段 → item_class 重命名、stack_limit=-1=无限符合 Godot/Unix 惯例。同步修订 entities.yaml（item_category_enum → item_class_enum）。
Prior verdict resolved: Yes — CD-GDD-ALIGN CONCERNS 中"Player Fantasy MVP 兑现度"在本次 specialist 评审中被进一步强化为"Header 与正文矛盾"，已通过 Header 改为分阶段表述 + Player Fantasy 加反证段落彻底解决。

### BLOCKING 处理对照
| # | 问题 | 修订摘要 |
|---|------|---------|
| 1 | 公式 3 错建模 + Alpha AC 缺失 | 拆 3a/3b；新增 AC-F4/F5/F6 |
| 2 | AC-C2 footgun 反模式 | get_field → peek_field 全文重命名；AC-C2 重写为标量 by-value 验证；AC-C3 改为 DOC-CONTRACT |
| 3 | assert + 降级矛盾 | 改用显式 `if not DataConfig: push_error+return` |
| 4 | AC-D1 不可执行 | 改为 `set_data_config(null)` 注入 + playtest 截图补充 |
| 5 | AC-G1 schema 未定义 | 严格化为 `Dictionary[String, int]` |
| 6 | Alpha 性能门槛缺失 | 新增 AC-F4/F5/F6 |
| 7 | rarity 8 元完整性 | 新增 AC-A10 parametric |

### IMPORTANT 处理对照（15 项全部应用）
- Header 4.6 主支柱 → "MVP: 4.1 主 / Alpha: 4.6 主"
- `category` → `item_class` 字段 + API + enum 全文重命名（同步 entities.yaml）
- stack_limit=0 → -1（Godot/Unix 惯例）+ stackable 交互规则 + AC-A3 同步
- Player Fantasy 加反证段落（unknown_item × 47 / rarity 缺失反证）
- 公式 1 拆命中/miss、公式 4 加 t_clear(N)
- 新增 `is_loaded()` API 解 Autoload race
- HUD cache 模式约定写入 §Dependencies
- AC-A8 拆 a/b、§A 组顶部 fixture 策略说明、AC-E1 加 4 项可观测断言、AC-F3 平台限定
- INVERTED_INDEX_THRESHOLD 升级为 MVP 软门槛 push_warning
- §Edge Cases 加 reload id 差分契约 + id 一致性 debug 校验建议
- §Open Questions 追加 typed Dict / OS.is_debug_build / Autoload 防御 / 9 常量精简 / per_item_size 证明 / Alpha N=1000 上限 等 7 项

### NICE-TO-HAVE（9 项）
保留为 Open Questions / 后续 follow-up；不阻塞实施。

### Specialist 分歧裁定
- AC-C2 严重性：3 specialist BLOCKING vs 1 NICE → 裁定 BLOCKING（已应用）
- 9 个 Debug 常量精简度：仅 game-designer 提出 → 裁定 NICE-TO-HAVE，进入 Open Questions
- Player Fantasy 是否重写：保留"沉默的命名者" framing + 加独立价值论证段落（已应用）

### 用户决策（4 项）
1. get_field → **peek_field**（保留引用语义 + 命名提示只读）
2. categories payload schema → **`Dictionary[String, int]`**（轻量统计）
3. category 字段重命名 → **`item_class`**（与 ResourceSystem 隔离）
4. stack_limit → **`-1=无限`**（Godot/Unix 惯例）

---

## Review — 2026-05-03 — Verdict: NEEDS REVISION → REVISED (re-review R2)
Scope signal: M
Specialists: game-designer · systems-designer · godot-gdscript-specialist · performance-analyst · qa-lead · creative-director (senior)
Blocking items: 4 | Recommended: 18 | Nice-to-have: 12
Summary: 第二轮独立 /design-review 在 5 specialist 对抗性评审 + creative-director 综合裁定下，发现 4 项 BLOCKING（peek_field CoW 描述在 GDScript 4.x 中错误、is_loaded() + EventBus TOCTOU 竞态、AC-F6 在 GDScript 不可实现、AC-E1 4 组合不可测）+ 18 项 IMPORTANT（公式变量统一、contains 语义澄清、t_json_io 缺失、AC 计数/路由修正等）。修订工作量 14 处 GDD 改动 + EventBus GDD 2 行交叉修复。核心设计骨架经历两轮 adversarial review 后已稳固，本轮 BLOCKING 密度相比 R1（7 项）显著下降。修订后达到 Approved 标准。
Prior verdict resolved: Yes — R1 7 BLOCKING + 15 IMPORTANT 已在 R1 修订中解决；R2 4 BLOCKING + 18 IMPORTANT 已在本轮修订。

### R2 BLOCKING 处理对照
| # | 问题 | 来源 | 修订摘要 |
|---|------|------|---------|
| 1 | peek_field CoW 描述错误 | godot-gdscript | CoW→引用类型 + 容器字段内部 `.duplicate(false)` 浅拷贝阻断写穿透 |
| 2 | is_loaded() TOCTOU 竞态 | godot-gdscript | 先订阅后检查（`subscribe` → `is_loaded()` → 执行回调）|
| 3 | AC-F6 不可实现 | performance | 重写为契约 AC（doc-comment + code-review + Alpha 帧重复调用检测）|
| 4 | AC-E1 4 组合不可测 | qa-lead | 拆为 E1a（CI 覆盖 2 组合）+ E1b（手动验证 release build 2 组合）|

### R2 IMPORTANT 处理对照（14 项已应用）
- 公式 3a/3b: t_eq_compare / t_string_compare → t_str_eq 统一；T → T_items（消除歧义）
- 公式 4: 新增 t_json_io 变量 + t_event_dispatch [0,0.5]→[0,10]ms + reload 估算 18-22→24.5-31.5ms
- query_by_tag "contains 语义" → 明确为"数组元素精确等值比较（`==`），非子串 `.contains()` 匹配"
- set_data_config(dc) → set_data_config(dc: Object) 类型标注
- AC 测试类型路由: D/I 组 Integration→Logic（均为纯 mock 可测）
- AC 计数修正: A 组 10→11 条
- 新增 AC-E3（reload 后 id 消失差分警告）+ AC-E4（reload 后 item_class 改变）
- reload 在 Unloaded 状态下行为: no-op + 警告
- AC-G1 增强: 新增断言⑤ — 被拒绝记录的 item_class 不出现
- EventBus GDD: categories→item_classes 跨文档同步修复（2 行）
- Open Questions: Autoload/class_name 命名冲突追加
- Open Questions: OS.is_debug_build() 关闭决议
- Header: 新增 R2 修订摘要行
