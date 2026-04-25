# SRPG 当前整体执行方案

**Last Updated**: 2026-04-25
**Stage**: Production / Post-Vertical-Slice Build
**Owner Mode**: Solo execute with evidence-first verification

## Progress Update

- `P0` 已完成：Godot 全量测试已恢复为 `0` 编译失败、`0` 断言失败
- `P1` 已完成：battle 主路径、Camera/Map、UI、SaveManager 产品化整合已落地并通过自动化回归
- `P2` 已完成：3 份结构化验证 session 已落地，人工视觉可读性 PASS WITH NOTES，2026-04-25 fun validation rerun PASS
- `P3` 已完成当前推荐链：`skill-system`、`equipment-system`、`character-management` 已完成并通过自动化回归
- 当前未完成重点已转入 Production：
  - UI/UX polish
  - 最小战斗表现层
  - 第一关真实内容切片

## 目标

在不扩散范围的前提下，先把项目拉到一个可验证、可演示、可继续扩展的稳定基线：

1. 自动化测试基线恢复到可信状态
2. Vertical Slice 从 prototype 升级为正式产品路径
3. Sprint 001 的 Camera / UI / Save 集成闭环完成
4. 完成至少 3 次 playtest，并据此决定后续大 epic 启动顺序

## 当前已确认事实

### 已完成

- Core 逻辑层已完成并有较多测试覆盖：
  - `attribute-system`
  - `class-system`
  - `resource-economy`
  - `tactical-mechanism`
  - `ai-system`
- `turn-based-mode` 与 `battle-settlement` 已完成主要逻辑实现
- `prototypes/vertical-slice/` 下存在可玩的战斗原型

### 当前缺口

- 自动化实现层已经闭环；人工视觉可读性已通过但有 UI polish notes，玩法验证 rerun 已 PASS
- 正式 battle scene 已根据用户反馈回退为 2D 俯视图；原 `CM-001` 等角视角目标已延后
- 结构化 validation session 已完成，纯人工自由试玩 rerun 已形成 PASS WITH PRODUCT-SCOPE NOTES
- `core loop fun validated` 已通过；玩家继续游玩意愿依赖后续内容与 polish
- `production/sprints/sprint-001.md` 与 `production/session-state/active.md` 存在状态漂移

## 总体策略

原则：**先修基线，再接主路径，再补展示层，再做产品级存档，再跑 playtest，最后再开后续大系统。**

这样做的原因：

- 现在继续堆功能，会把已有失败继续埋深
- prototype 已证明核心循环可玩，但还没进入正式场景路径
- Camera / UI / Save 是当前 Vertical Slice 的真正阻塞项
- 当前自动化 backlog、人工 gate 证据、Windows exe smoke、packaged-build 完整试玩已落地，下一步是 UI/UX polish、内容和战斗表现

## 执行优先级

### P0：修复自动化基线

目标：让测试恢复为可信工程信号。

重点处理：

1. 属性系统信号签名不一致
   - `src/core/attributes/attribute_component.gd`
   - `src/core/attributes/unit_attributes.gd`
2. class-system 失败项
   - class exp
   - class bonus
   - save/load round-trip
3. resource 相关编译失败
   - `tests/unit/resource/*`
   - `tests/integration/resource/*`
4. 测试脚本自身错误
   - `tests/integration/test_turn_order_integration.gd`
   - `tests/unit/test_attribute_formulas.gd`

退出条件：

- `godot --headless res://tests/test_runner.tscn` 无编译失败
- 现有断言失败全部修复，或剩余项被明确降级并单独记录

### P1：把 Vertical Slice 接到正式主路径

目标：从主菜单进入的不是空场景，而是真正可玩的战斗切片。

重点处理：

1. 将 `prototypes/vertical-slice/` 中已验证的核心战斗流程迁入或接入 `src/ui/combat/`
2. 明确主战斗场景的正式入口结构
3. 避免长期维持“prototype 能玩、产品入口不能玩”的双轨状态

退出条件：

- `main_menu -> battle` 进入的是可交互战斗场景
- 至少覆盖：选人、移动、攻击、敌方回合、胜负判定、回合顺序显示

### P1：完成 Camera / Map 三个 story

顺序固定：

1. `CM-001` 等角摄像机
2. `CM-002` 网格地图渲染
3. `CM-003` Camera Save/Load Integration

原因：

- UI 和正式战斗展示都依赖可用视角与地图承载
- `CM-003` 是典型后置集成项，必须建立在前两项之上

当前状态：

- `CM-001` 已延后。vertical slice 正式场景改为 2D 俯视图以优先解决操作和可读性
- `CM-002` 当前以 2D 可读性优先的网格地图实现
- `CM-003` 当前只保留对现有 top-down grid/map prefs 的持久化

### P1：完成 UI 三个 story

顺序固定：

1. `UI-001` Battle HUD
2. `UI-002` Resource HUD + Menu System
3. `UI-003` UI Save/Load Integration

原因：

- 现在 `combat_hud.gd` 只是占位
- 正式 Vertical Slice 的可玩性验证需要 HUD，而不是仅靠 prototype 自制控件
- `UI-003` 必须建立在真实 UI 状态存在之后

退出条件：

- [x] 战斗 HUD 可显示并响应事件
- [x] 菜单与资源 HUD 可键盘操作
- [x] UI 偏好与状态可持久化

### P1：做真正的 SaveManager 级整合

目标：结束“各子系统能序列化，但产品不能真正存读档”的状态。

重点处理：

1. 扩展 `SaveData`
   - battle state
   - action state
   - auto-battle / speed state
   - settlement history
   - camera preferences
   - UI preferences
2. 让 `SaveManager.save_game()` 真正收集运行中状态
3. 让 `SaveManager.load_game()` 真正恢复状态
4. 把现有 integration test 从“类级 round-trip”推进到“产品级 round-trip”

退出条件：

- [x] 存档能恢复到可继续操作的战斗现场
- [x] camera / UI 偏好与战斗状态同时恢复
- [x] `main_menu` 的 Continue 路径具备实际意义

### P2：完成 Vertical Slice QA 闭环

目标：不只是“能运行”，而是“已验证值得继续做”。

执行内容：

1. 至少完成 3 次 playtest
2. 记录定性反馈与阻塞问题
3. 根据反馈做最小必要修正
4. 更新 Sprint / Session / Epic 状态文档

退出条件：

- [x] `production/playtests/` 下至少 3 份有效记录
- 明确 core loop 是否成立
- Sprint 001 验收项完成状态真实可查

### P3：启动 VS 之后的后续大 epic

推荐顺序：

1. `skill-system` `[x]`
2. `equipment-system` `[x]`
3. `character-management` `[x]`

原因：

- UI-001 已直接依赖 skill data
- equipment 与 final attribute calculation 依赖 class / attribute 的稳定基线
- character-management 更适合建立在 UI、装备、技能都已有可展示数据之后

## 分阶段出口标准

### Phase A：基线恢复完成

- 测试恢复可信
- 文档中的“已完成”与代码现状不再明显冲突

### Phase B：Vertical Slice 产品化完成

- 正式入口可玩
- Camera / Map / UI / Save 四条链路闭环

### Phase C：验证完成

- 3 次 playtest 已完成
- core loop fun validated 有明确结论

### Phase D：后续扩展启动

- skill / equipment / character 按顺序开工

## 当前不建议立即做的事

- 把 vertical-slice PASS 误读为 release readiness
- 在还没有可试玩构建和第一关内容前，把 Production 阶段误判为“只剩扩系统”
- 重新引入 prototype 与 product 的双轨实现

## 文档同步要求

每完成一个阶段，至少同步这些文件：

- `production/session-state/active.md`
- `production/sprints/sprint-001.md`
- 对应 `production/epics/*/story-*.md`
- 必要时补 `production/playtests/*.md`

## 建议的下一步

按 UI/UX polish → 最小战斗表现 → 第一关内容切片推进。
