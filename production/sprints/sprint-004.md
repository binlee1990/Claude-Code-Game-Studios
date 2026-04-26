# Sprint 4: 管理界面 Beta + 基地系统 MVP

> Version: v1.0 | Date: 2026-04-26 | Status: **COMPLETE**
> Completed: 2026-04-26
> Previous: sprint-003 v1.0 COMPLETE（Ch.2 三战全实装 + 信念值分叉 + Boss 三阶段）
> Control Manifest: 2026-04-26-v2（覆盖 ADR-001~007）
> Review Mode: solo

## Sprint Goal

解决玩家直接反馈的卡关问题：「没有培养机制」+「没有设置己方人员属性功能」。
通过管理界面 Beta（角色 + 装备）和基地系统 MVP（训练场 + 市集），
让玩家在战斗间隙有养成闭环，不再靠裸属性硬磕 Boss。

## 用户反馈根因

| 反馈 | 根因 | 解决方案 |
|------|------|----------|
| 没有培养机制 | 基地系统（训练场/市集）未实装 | 基地系统 MVP |
| 没有设置己方人员属性功能 | 角色管理 + 装备管理 UI 缺失 | 管理界面 Beta |

## Capacity

- Total days: 5（2026-04-26 → 2026-05-01）
- Buffer (20%): 1 day
- Available: 4 days
- Sprint-003 velocity: 9 stories / 1 day（全是 Logic，测试密集型）
- Sprint-004 混合 UI + Logic，预计 4-5 stories 上限

## 入场前提

| 项 | 状态 |
|---|---|
| sprint-003 | COMPLETE |
| stage.txt | Production |
| character-management epic | COMPLETE（逻辑层 3/3 Done，UI 缺失） |
| equipment-system epic | COMPLETE（逻辑层 7/7 Done，UI 缺失） |
| base-system GDD | 存在（design/gdd/base-system.md） |
| management UI ux-spec | 不存在（需新建） |

---

## Tasks

### Must Have — 管理界面 Beta 核心

| ID | Task | Agent/Owner | Est. Days | Dependencies | Acceptance Criteria |
|----|------|-------------|-----------|-------------|-------------------|
| MGMT-001 | 角色管理 UI（编队 + 角色详情） | ui-programmer | 0.5 | character-management epic 逻辑已完成 / ux-spec | AC.MGMT-001 角色列表 / 编队调整 / 角色详情查看 |
| MGMT-002 | 装备管理 UI（装备查看 + 更换） | ui-programmer | 0.5 | equipment-system epic 逻辑已完成 / ux-spec | AC.MGMT-002 装备列表 / 穿戴状态 / 更换操作 |
| MGMT-003 | 角色 + 装备 UI 整合入口（管理界面 Tab 切换） | ui-programmer | 0.25 | MGMT-001 + MGMT-002 | AC.MGMT-003 Tab 切换流畅，数据联动正确 |
| MGMT-004 | 管理界面存档集成（编队 + 装备状态持久化） | gameplay-programmer | 0.25 | character-management save / equipment save | AC.MGMT-004 退出管理界面后重新进入，状态保持 |
| MGMT-005 | 基地入口 UI（主菜单 + 战斗结算后 → 基地按钮） | ui-programmer | 0.25 | main_menu 已有点击区域 | AC.MGMT-005 主菜单和结算屏都有基地入口按钮 |

### Should Have — 基地系统 MVP

| ID | Task | Agent/Owner | Est. Days | Dependencies | Acceptance Criteria |
|----|------|-------------|-----------|-------------|-------------------|
| BASE-001 | 基地主界面框架（功能区 Tab 切换：训练场/市集） | ui-programmer | 0.25 | MGMT-005 基地入口 | BASE-AC-001 功能区 Tab 切换正常 |
| BASE-002 | 训练场 MVP（查看角色技能熟练度） | gameplay-programmer | 0.25 | skill-system epic 完成 | BASE-AC-002 玩家可查看各角色技能熟练度 |
| BASE-003 | 市集 MVP（买卖道具界面） | gameplay-programmer | 0.25 | resource-economy epic 完成 | BASE-AC-003 玩家可买入/卖出道具 |

### Nice to Have

| ID | Task | Agent/Owner | Est. Days | Dependencies | Acceptance Criteria |
|----|------|-------------|-----------|-------------|-------------------|
| MGMT-006 | 管理界面 + 基地 截图归档 + smoke | qa-lead + human | 0.25 | MGMT-001~005 + BASE-001~003 | evidence 文件落地 |
| BASE-004 | Ch.2 playtest 回流分析（验证培养闭环是否解决卡关） | qa-lead + human | 0.5 | Ch.2 三战可完整游玩 | playtest 报告更新 |

---

## Dependencies on External Factors

- character-management epic 逻辑已完成 → UI 接入无阻塞
- equipment-system epic 逻辑已完成 → UI 接入无阻塞
- skill-system epic 已完成 → 训练场可接入
- resource-economy epic 已完成 → 市集可接入
- main_menu.tscn 已有 → 基地入口按钮可叠加

---

## 不在本 Sprint 范围（明确排除）

- 基地系统完整版（含行动点、酒馆、情报室）→ Sprint-005+
- 羁绊系统 → Sprint-005+
- ADR-008（资源经济升级）/ ADR-009（装备升级）→ Sprint-005+
- 角色立绘 / 正式美术资产 → Beta 阶段
- Ch.3 GDD 设计 → Sprint-005+
- 管理界面完整版（装备强化/附魔/分解 UI）→ Beta 专项

---

## 执行顺序建议（5 天节拍）

```
Day 1  : MGMT-001（角色管理 UI）+ MGMT-002（装备管理 UI）+ ux-spec 同步
Day 2  : MGMT-003（Tab 整合）+ MGMT-004（存档集成）+ MGMT-005（基地入口）
Day 3  : BASE-001（基地框架）+ BASE-002（训练场 MVP）+ BASE-003（市集 MVP）
Day 4  : 串联 smoke（主菜单→基地→管理→编队→装备→保存→读档）+ bug fix
Day 5  : Nice to Have 截图归档 + playtest 回流分析 + Sprint-004 收尾
```

---

## Definition of Done for this Sprint

- [ ] 4 个 Must Have（MGMT-001~005）全部 /story-done COMPLETE
- [ ] 3 个 Should Have（BASE-001~003）全部 /story-done COMPLETE
- [ ] godot --check-only --quit：0 parse error
- [ ] GUT 测试套件：≥764 + 新增（无 regression）
- [ ] 管理界面 Beta 可用：角色/装备查看 + 编队/更换 + 存档持久化
- [ ] 基地系统 MVP 可用：训练场查看熟练度 + 市集买卖
- [ ] active.md 同步至 Sprint-004 COMPLETE

---

## 参考文档

| 文档 | 路径 | 说明 |
|------|------|------|
| 角色管理 GDD | `design/gdd/character-management.md` | 编队规则 / 退场召回 / AC 清单 |
| 装备系统 GDD | `design/gdd/equipment-system.md` | 装备数据模型 / 强化分解 / 套装 |
| 基地系统 GDD | `design/gdd/base-system.md` | 功能区 / 升级 / 行动点 |
| Character Epic | `production/epics/character-management/EPIC.md` | 3 stories 全 Complete |
| Equipment Epic | `production/epics/equipment-system/EPIC.md` | 7 stories 全 Complete |
| UI GDD | `design/gdd/ui-system.md` | UI 系统规范 |
| 现有 UI 场景 | `src/ui/menu/main_menu.tscn` / `src/ui/combat/battle_arena.tscn` | 现有菜单和战斗场景 |

---

## 关键架构约束

1. **UI 不碰逻辑**：UI 层只负责展示和交互，逻辑全部调用已有 epic 的类
2. **存档是粘合剂**：管理界面和基地的状态变化必须通过已有的 SaveManager / ProgressData
3. **Tab 切换不丢失状态**：进入管理界面 → 切换 Tab → 返回，数据不变
4. **数据驱动**：训练场熟练度、市集价格 均从 GDD 定义的常量读取，不硬编码

---

## Revalidation — 2026-04-27

### 完成进展

复核结论：Sprint-004 的 Must Have 与 Should Have 已执行完成，状态为 **COMPLETE WITH HUMAN-PLAYTEST NOTES**。

| 复核项 | 结果 | 证据 |
|---|---|---|
| MGMT-001 角色管理 UI | 完成 | `src/ui/management/character_management.gd`、`character_management_screen.tscn`；`tests/integration/ui/character_management_test.gd` |
| MGMT-002 装备管理 UI | 完成 | `src/ui/management/equipment_management.gd`、`equipment_management_screen.tscn`；装备切换测试在 `character_management_test.gd` 覆盖 |
| MGMT-003 Tab 整合 | 完成 | `src/ui/management/character_tab_bar.gd`，`battle_arena.gd` 管理 overlay 支持 rewards/camp/party/equipment/character |
| MGMT-004 存档集成 | 完成 | `battle_arena.gd` 管理界面变更触发自动保存；`tests/integration/save/battle_save_manager_integration_test.gd` 覆盖 management screen state |
| MGMT-005 基地入口 | 完成 | `main_menu.gd` / `main_menu.tscn` 有 Base 按钮；`battle_arena.gd` 结算 overlay 有 Base 按钮并切到 `SceneManager.switch_scene("base")` |
| BASE-001 基地主界面 | 完成 | `src/ui/base/base_hub.gd`、`base_hub.tscn`；`tests/integration/ui/base_hub_test.gd` |
| BASE-002 训练场 MVP | 完成 | `src/ui/base/training_ground.gd`；`base_hub_test.gd` 覆盖训练场布局与训练交互 |
| BASE-003 市集 MVP | 完成 | `base_hub.gd` 覆盖 market tab、buy/sell 价格与购买流 |
| Sprint status | 完成 8/9 | `production/sprint-status.yaml` 中 MGMT-001~006 与 BASE-001~003 为 done，BASE-004 为 backlog |
| 自动化解析 | PASS | 2026-04-27 运行 `godot --headless --check-only project.godot`，退出码 0 |
| 自动化测试入口 | PASS | 2026-04-27 运行 `godot --headless res://tests/test_runner.tscn`，退出码 0；当前仓库静态统计 805 个 `test_` 方法 |
| 打包版冒烟 | PASS | 2026-04-27 运行 `builds/windows/SRPG.exe --headless --srpg-playthrough-smoke`，输出 `PACKAGED_PLAYTHROUGH_SMOKE PASS` |

### 遗留问题

- `BASE-004` 仍为 backlog，需要人工 Ch.2 playtest 回流，验证培养闭环是否真正缓解卡关。
- `production/qa/evidence/sprint-004-management-base-evidence.md` 仍标记 `PENDING`，截图清单和 sign-off 未完成；功能测试覆盖存在，但人工视觉证据未闭合。
- 当前打包版 smoke 主要覆盖 Chapter 1 + management equipment 路径，不等同于完整基地路径人工 smoke；基地入口、训练场、市集依赖集成测试覆盖。
- 打包版 smoke 退出时 Godot 报告资源仍在使用的 warning/error；当前不阻塞 smoke PASS，但应在后续稳定性清理中处理。
