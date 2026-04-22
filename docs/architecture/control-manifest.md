# Control Manifest

> Manifest Version: 2026-04-23-v1
> Generated From: ADR-001 (Event Architecture), ADR-002 (Scene Management), ADR-003 (Save System)
> Status: Active
> Coverage: Foundation Layer (3/3 ADRs)

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

---

## Related

- `docs/architecture/ADR-001-event-architecture.md`
- `docs/architecture/ADR-002-scene-management.md`
- `docs/architecture/ADR-003-save-system.md`
- `docs/architecture/architecture-traceability.md`
