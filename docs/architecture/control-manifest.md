# Control Manifest

> Manifest Version: 2026-04-27-v3
> Generated From: ADR-001 (Event Architecture), ADR-002 (Scene Management), ADR-003 (Save System), ADR-004 (Combat System), ADR-005 (AI Behavior), ADR-006 (Attribute Data Model), ADR-008 (Resource Economy Upgrade), ADR-009 (Equipment Upgrade Scope)
> Status: Active
> Coverage: Foundation Layer (3/3 ADRs) + Gameplay Layer (3/3 ADRs)

---

本文件从已接受的 ADR 中提取程序员必须遵守的硬规则。每条规则可追溯到源 ADR。

---

## Foundation Layer

### Event Architecture (ADR-001)

#### Required

| ID | Rule | Source |
|----|------|--------|
| EV-R01 | 所有跨系统通信通过 `GameEvents.gd` (Autoload) 信号实现 | ADR-001 Decision |
| EV-R02 | 信号命名: `snake_case` + 过去式 (`health_changed`, `unit_died`) | ADR-001 Decision |
| EV-R03 | 信号参数必须包含充分上下文，监听者无需额外查询即可决策 | ADR-001 Decision |
| EV-R04 | 每个系统只发出自己领域的信号，不代理其他系统的信号 | ADR-001 Decision |
| EV-R05 | 所有信号定义集中在 `GameEvents.gd`，附带 docstring | ADR-001 Validation |

#### Forbidden

| ID | Rule | Source |
|----|------|--------|
| EV-F01 | 信号处理器中禁止发出同一总线的其他信号（防嵌套/循环） | ADR-001 Decision |
| EV-F02 | 禁止系统间直接方法调用（除明确的数据依赖） | ADR-001 Validation |
| EV-F03 | 禁止创建 `GameEvents` 之外的第二事件总线 | ADR-001 Alternative 1 |

#### Guardrails

| ID | Rule | Budget | Source |
|----|------|--------|--------|
| EV-G01 | 信号发送性能 < 0.1ms/signal | 帧预算内 | ADR-001 Performance |
| EV-G02 | 信号类型内存 < 1KB/类型 | — | ADR-001 Performance |
| EV-G03 | 参数变更时需同步所有监听者签名 | — | ADR-001 Consequences |

---

### Scene Management (ADR-002)

#### Required

| ID | Rule | Source |
|----|------|--------|
| SC-R01 | 所有场景切换通过 `SceneManager.gd` (Autoload) | ADR-002 Decision |
| SC-R02 | 场景切换期间必须显示 loading 画面 | ADR-002 Decision |
| SC-R03 | UI 层 (Layer 3) 与游戏逻辑层 (Layer 0-2) 节点无交叉引用 | ADR-002 Validation |
| SC-R04 | 场景层次遵循: Layer 0 (Camera/Env) → Layer 1 (World) → Layer 2 (Units) → Layer 3 (UI) → Layer 4 (Effects) | ADR-002 Decision |
| SC-R05 | 像素角色使用 Nearest texture filter | ADR-002 HD-2D Settings |

#### Forbidden

| ID | Rule | Source |
|----|------|--------|
| SC-F01 | 禁止 UI 节点直接引用 Game World 节点（通过信号通信） | ADR-002 Validation |
| SC-F02 | 禁止 Game World 节点直接引用 UI 节点 | ADR-002 Validation |
| SC-F03 | 禁止单一大场景模式（所有内容放一个场景） | ADR-002 Alternative 1 |

#### Guardrails

| ID | Rule | Budget | Source |
|----|------|--------|--------|
| SC-G01 | 场景切换总时间 < 2s（含 loading 画面） | <2s | ADR-002 Performance |
| SC-G02 | 战斗场景内存 < 512MB | <512MB | ADR-002 Performance |
| SC-G03 | 场景路径注册在 `SCENES` 字典中，不散落硬编码 | — | ADR-002 Consequences |

---

### Save System (ADR-003)

#### Required

| ID | Rule | Source |
|----|------|--------|
| SV-R01 | 存档数据使用 `Resource` 类封装（`SaveData.gd`） | ADR-003 Decision |
| SV-R02 | 支持 8 个存档槽位 (`user://saves/save_N.tres`) | ADR-003 Decision |
| SV-R03 | 每份存档包含 `version` 字段，加载时检查并执行版本迁移 | ADR-003 Decision |
| SV-R04 | 存档/读档通过 `SaveManager.gd` (Autoload) | ADR-003 Decision |
| SV-R05 | 自动存档在关键节点触发（章节完成、重大选择、基地升级） | ADR-003 Decision |
| SV-R06 | 存档/读档后发出 `GameEvents.game_saved` / `game_loaded` 信号 | ADR-003 Decision |

#### Forbidden

| ID | Rule | Source |
|----|------|--------|
| SV-F01 | 禁止使用 SQLite 存档（过度工程化） | ADR-003 Alternative 2 |
| SV-F02 | 禁止使用裸 JSON 文件存档（缺乏类型安全） | ADR-003 Alternative 1 |
| SV-F03 | 禁止存档中包含逻辑代码引用（仅数据） | ADR-003 Decision |

#### Guardrails

| ID | Rule | Budget | Source |
|----|------|--------|--------|
| SV-G01 | 存档写入 < 500ms | <1s | ADR-003 Performance |
| SV-G02 | 存档读取 < 200ms | <500ms | ADR-003 Performance |
| SV-G03 | 单槽位大小 < 1MB | <2MB | ADR-003 Performance |
| SV-G04 | XOR 加密仅防普通用户，非安全加密 | — | ADR-003 Consequences |

---

## Gameplay Layer

### Combat System (ADR-004)

#### Required

| ID | Rule | Source |
|----|------|--------|
| CB-R01 | 伤害计算必须在单帧内完成，禁止任何异步操作 | ADR-004 Constraints |
| CB-R02 | 战斗流程必须通过 CombatStateMachine 管理，不得绕过状态机直接跳转 | ADR-004 Decision |
| CB-R03 | 行动顺序必须按 AGI 降序排列，AGI 相同时随机决定先后 | ADR-004 Requirements |
| CB-R04 | 伤害计算管线必须按顺序叠加：base → 克制修正 → 元素修正 → 高低差修正 | ADR-004 Decision |
| CB-R05 | 战斗信号（battle_started / battle_ended 等）必须通过 GameEvents 发出 | ADR-004 + ADR-001 |
| CB-R06 | 战术子系统（TacticalResolver）必须作为独立模块注入，不得内嵌于 DamageCalculator | ADR-004 Decision |
| CB-R07 | 自动战斗模式必须复用 AIDecisionEngine，不得独立实现决策逻辑 | ADR-004 + ADR-005 |
| CB-R08 | 战斗结算必须在 CombatStateMachine 进入 BATTLE_ENDED 状态后触发 | ADR-004 Decision |

#### Forbidden

| ID | Rule | Source |
|----|------|--------|
| CB-F01 | 战斗进行中（PLAYER_TURN / ENEMY_TURN / EXECUTING 状态）禁止执行存档操作 | ADR-004 Constraints + ADR-003 |
| CB-F02 | 禁止在伤害计算中使用 await / 协程 / 信号等待 | ADR-004 Constraints |
| CB-F03 | 禁止 UI 层节点直接调用 CombatSystem 方法（须通过信号） | ADR-004 + ADR-002 |
| CB-F04 | 禁止在 _process() 中连接战斗信号 | ADR-001 Validation |

#### Guardrails

| ID | Rule | Budget | Source |
|----|------|--------|--------|
| CB-G01 | 单次行动结算耗时 < 1ms | <1ms | ADR-004 Performance |
| CB-G02 | 单次伤害计算耗时 < 0.1ms | <0.1ms | ADR-004 Performance |
| CB-G03 | 克制/元素叠加最终倍率不得超过 2.25x（需边界值测试覆盖） | — | ADR-004 Risks |

---

### AI Behavior (ADR-005)

#### Required

| ID | Rule | Source |
|----|------|--------|
| AI-R01 | 每个 AI 类型必须有独立配置文件（JSON/Resource），禁止硬编码行为权重 | ADR-005 Decision |
| AI-R02 | AI 决策必须通过三层架构（TacticalLayer → StrategyLayer → ExecutionLayer）执行 | ADR-005 Decision |
| AI-R03 | 威胁值计算必须使用标准公式：damage_potential×1.0 + proximity×0.5 + hp_threat×0.3 + role_affinity×0.2 | ADR-005 Decision |
| AI-R04 | Boss AI 阶段切换必须在 HP 阈值（70% / 50%）触发，且在一帧内完成 | ADR-005 Decision |
| AI-R05 | AI 配置文件通过 AIConfigLoader 加载，禁止直接 load() 散落在决策代码中 | ADR-005 Decision |

#### Forbidden

| ID | Rule | Source |
|----|------|--------|
| AI-F01 | 禁止硬编码 AI 行为权重或目标优先级数值 | ADR-005 Alternative 2 |
| AI-F02 | 禁止 AI 决策使用 await / 多帧分散计算 | ADR-005 Constraints |

#### Guardrails

| ID | Rule | Budget | Source |
|----|------|--------|--------|
| AI-G01 | 单单位 AI 决策（含三层评估）耗时 < 5ms | <5ms | ADR-005 Performance |
| AI-G02 | Boss 阶段切换检查耗时 < 0.1ms | <0.1ms | ADR-005 Performance |
| AI-G03 | 配置文件命名遵循 `ai_[type]_config.json` 规范，CI 校验格式合法性 | — | ADR-005 Risks |

---

### Attribute Data Model (ADR-006)

#### Required

| ID | Rule | Source |
|----|------|--------|
| AT-R01 | 属性值（V）范围严格限定为整数 [0, 999]；潜质（P）枚举限定为 [E=1, D=2, C=3, B=4, A=5, S=6] | ADR-006 Constraints |
| AT-R02 | 属性数据必须封装为 AttributeData（Resource 子类），禁止以裸 Dictionary 传递 | ADR-006 Decision |
| AT-R03 | 成长公式固定为 V_new = V_old + P_current，禁止在第一周目引入 RNG | ADR-006 Constraints |
| AT-R04 | 果子使用、壁障突破、门槛奖励必须通过属性系统接口触发，并发出对应 GameEvents 信号 | ADR-006 Decision |
| AT-R05 | 属性数据必须通过 ADR-003 存档层（UnitSaveData）持久化，不得自行写入文件 | ADR-006 + ADR-003 |
| AT-R06 | 属性碾压检查（crush_check）必须在 DamageCalculator 调用前完成，结果作为倍率传入 | ADR-006 Decision |

#### Forbidden

| ID | Rule | Source |
|----|------|--------|
| AT-F01 | 下游系统（战斗、装备、技能、AI）禁止直接修改 AttributeData.values / potentials，必须通过属性系统提供的接口 | ADR-006 Constraints |
| AT-F02 | 禁止在 AttributeData 中存储任何逻辑代码引用或回调函数 | ADR-006 + ADR-003 |

#### Guardrails

| ID | Rule | Budget | Source |
|----|------|--------|--------|
| AT-G01 | 属性查询耗时 < 0.01ms（Dictionary lookup） | <0.01ms | ADR-006 Performance |
| AT-G02 | 升级成长计算（9 维）耗时 < 0.1ms | <0.1ms | ADR-006 Performance |

---

## Cross-Layer Rules

以下规则涉及多个 ADR 的交互:

| ID | Rule | Sources |
|----|------|---------|
| XL-R01 | 场景切换时通过 `GameEvents.scene_switch_started` 信号通知，非直接调用 | ADR-001 + ADR-002 |
| XL-R02 | 存档触发通过 `GameEvents` 信号，非 SaveManager 直接调用 SceneManager | ADR-001 + ADR-003 |
| XL-R03 | UI 存档面板仅与 `SaveManager` 交互，不直接访问文件系统 | ADR-002 + ADR-003 |

---

## Audit Checklist

代码审查时逐项检查:

- [ ] 跨系统调用: grep `GameEvents.` 确认所有通信走信号
- [ ] 信号嵌套: 检查信号 handler 中无 `GameEvents.xxx.emit()`
- [ ] 场景切换: grep `switch_scene` 确认无 `get_tree().change_scene` 直接调用
- [ ] UI 引用: 检查 Layer 3 节点无 `get_node()` 引用 Layer 0-2
- [ ] 存档访问: grep `user://saves` 确认仅 `SaveManager` 操作存档目录
- [ ] 纹理 filter: 检查 Sprite2D 节点使用 Nearest filter

---

## Version History

| Version | Date | Changes |
|---------|------|---------|
| 2026-04-23-v1 | 2026-04-23 | Initial manifest from ADR-001/002/003 |
| 2026-04-26-v2 | 2026-04-26 | Added Gameplay Layer: Combat System (ADR-004), AI Behavior (ADR-005), Attribute Data Model (ADR-006) |
| 2026-04-27-v3 | 2026-04-27 | Registered ADR-001 `equipment_enhanced(item_id, level, success)` follow-up and acknowledged ADR-008/009 as active Sprint-007 scope constraints |

---

## Related

- `docs/architecture/ADR-001-event-architecture.md`
- `docs/architecture/ADR-002-scene-management.md`
- `docs/architecture/ADR-003-save-system.md`
- `docs/architecture/ADR-004-combat-system.md`
- `docs/architecture/ADR-005-ai-behavior.md`
- `docs/architecture/ADR-006-attribute-data-model.md`
- `docs/architecture/architecture-traceability.md`
