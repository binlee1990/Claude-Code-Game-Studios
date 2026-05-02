# Sprint 人工操作集中队列

> Version: v2.0 | Date: 2026-05-02 | Status: **OPEN**
> Source: 从 `sprint-001.md` ~ `sprint-010.md` 抽离的人工执行、人工验收、截图归档、试玩、听感确认与 sign-off 工作。

## 目标

把各 sprint 中散落的人工操作项集中成一个可执行队列，避免它们继续混在自动化开发 sprint 的 Definition of Done、遗留问题和时间线里。

本文件只管理需要真人参与的工作；代码实现、自动化测试、Godot export、packaged smoke、ADR 草稿和普通技术 backlog 仍由对应 sprint / epic / docs 文件管理。

## 排序规则

| 优先级 | 含义 |
|---|---|
| P0 | 发布、公开构建、视觉可读性或关键证据闭环前必须完成 |
| P1 | 会影响下一阶段设计判断或玩家体验判断，但不阻塞当前自动化交付 |
| P2 | 体验 polish 或补充性确认，可在 P0/P1 后执行 |

执行顺序按“先补基础证据 → 再验证新增管理/基地体验 → 再跑 Ch.2 完整体验 → 最后做发布签收”排序；同优先级内优先处理会解除后续任务阻塞的项。

## 集中执行队列

| 顺序 | 优先级 | ID | 来源 | 人工任务 | 前置条件 | 输出物 / 退场条件 | 状态 |
|---:|---|---|---|---|---|---|---|
| 1 | P0 | MAN-001 | Sprint-002 `Lane B Gate`；Sprint-003 `QA-EVID-001` / Carryover；Sprint-002 Revalidation | Presentation P0 截图与证据清理：主菜单焦点/存档摘要、战斗 HUD Auto/Speed、回合顺序 HP 条、全局 hint bar 四屏截图；同步清理 `production/qa/evidence/sprint-002-presentation-p0.md` 中的 pending/TODO 口径 | 最新 Windows build 可启动；自动化 parse/test/export/smoke 已 PASS | evidence 文件更新，4 屏截图路径可追溯；不再保留“待人工截图验收”旧口径 | OPEN |
| 2 | P0 | MAN-002 | Sprint-004 `MGMT-006`；Sprint-004 / Sprint-005 Revalidation | 管理界面 + 基地 MVP 视觉证据与人工 smoke：主菜单进入基地，训练场查看，市集买卖，战斗结算进入管理界面，角色/装备切换，保存/读档后状态保持 | Sprint-004 / Sprint-005 自动化 UI 与 save 测试 PASS；可用 Windows build | `production/qa/evidence/sprint-004-management-base-evidence.md` 更新为完成；截图清单、路径、结果和问题记录完整 | OPEN |
| 3 | P0 | MAN-003 | Sprint-001 Timeline / Revalidation | Vertical Slice 最终视觉 walkthrough：确认 2D top-down fallback、UI/resource/battle HUD 可读性、Chapter 1 正式路径视觉表现是否满足 release candidate 口径 | MAN-001 完成；当前 build 可完整跑 Chapter 1 | 新增或更新 `production/playtests/` / `production/qa/evidence/` 中的 release visual sign-off；若仍 PASS WITH NOTES，明确哪些 notes 不阻塞发布 | PARTIAL：已有 2026-04-24 visual sign-off 与 2026-04-25 fun rerun，最终 release 视觉签收未闭合 |
| 4 | P1 | MAN-004 | Sprint-003 `CH2-PT-001`；Sprint-003 DoD / Revalidation | Ch.2 三战完整 playtest + 信念值数据采集：3 名玩家完整通关 Ch.2，记录路线、失败点、信念值差值，验证 AC-CH2-009 是否达到 >= 15 | Chapter 2 三战实现与自动化测试 PASS；QA plan 文件名已与实际测试文件对齐或在报告中说明偏差 | `production/playtests/` 下新增 Ch.2 playtest 报告；差值统计脚本/表格输出可追溯；截图或录屏路径归档 | OPEN |
| 5 | P1 | MAN-005 | Sprint-004 `BASE-004`；Sprint-005 Remaining Issues / Revalidation | Ch.2 培养闭环回流分析：验证 Sprint-004 的管理界面 + 基地训练/市集是否缓解 Ch.2 卡关 | MAN-002 完成；MAN-004 至少有一轮 baseline 结果 | playtest 报告更新，明确“基地/管理是否缓解卡关”、仍需哪些数值或 UX 调整 | BLOCKED by MAN-002 / MAN-004 |
| 6 | P2 | MAN-006 | Sprint-002 Risk Resolution Log | BGM loop 听感确认：主菜单 BGM 与战斗 BGM 是否有明显接缝、音量突变或疲劳感 | 最新音频资源已随 build 打包；可进入主菜单与战斗 | playtest/evidence 记录听感结论；若失败，生成 audio backlog，不直接改代码 | OPEN |
| 7 | P0 Final Gate | MAN-007 | Sprint-002 out-of-scope release gate；Sprint-005 out-of-scope public release gate | Public release 人工签收包：确认 Credits 法务署名可见、P0/P1 人工证据闭环、公开构建无未接受的人工阻塞项 | MAN-001 ~ MAN-006 完成或有明确 release-waiver；Credits 自动化门禁 PASS | 发布签收记录，列出 accepted notes / deferred notes / release blockers | BLOCKED until release candidate |

## 已完成的历史人工验证

| ID | 来源 | 结果 | 证据 |
|---|---|---|---|
| MAN-DONE-001 | Sprint-001 visual / fun validation | PASS WITH NOTES / PASS WITH PRODUCT-SCOPE NOTES | `production/playtests/playtest-2026-04-24-visual-signoff.md`、`production/playtests/playtest-2026-04-25-fun-validation-rerun.md` |
| MAN-DONE-002 | Sprint-002 ADR governance sign-off | DONE | ADR-004/005/006 已 Accepted；`docs/architecture/control-manifest.md` 覆盖 ADR-001~006 |

## Sprint-007 截图候选补充

以下为 Sprint-007 自动化已 PASS 后的人工证据候选，不新增 release-blocking 项：

| 目标人工项 | 候选截图 / 录屏路径 | 说明 |
|---|---|---|
| MAN-002 | Base Tavern unlocked/locked state、Base Upgrade Lv1→Lv2、Tavern conversation completed/AP -1、Management equipment +6 risk-zone prompt/+7 result | 覆盖 Sprint-007 Base/Bond/Equipment 新 UI 面 |
| MAN-004 | Ch.3 battle 1 first turn、Ch.3 victory settlement、Ch.3 post-victory base handoff | 作为 Ch.2→Ch.3 过渡参考，不替代 Ch.2 三战 playtest |

## 执行约束

- 每个人工任务开始前先确认对应自动化 gate 已通过，避免用人工时间排查可自动发现的问题。
- 每个报告必须写清：build/hash 或日期、执行人、执行路径、截图/录屏路径、结果、阻塞项、可接受 notes。
- 如果人工结果只产生体验建议，不阻塞当前自动化交付，应标为 `PASS WITH NOTES` 并把后续改动转入对应 epic / backlog。
- 不在原 sprint 文档中新增新的人工 gate；新的人工项继续追加到本文件。

---

## Sprint-009+ 追加人工验证 (2026-05-02)

### VS 系统视觉验证

| 顺序 | 优先级 | ID | 人工任务 | 前置条件 | 输出物 | 状态 |
|---:|---|------|------|------|------|---|
| 8 | P1 | MAN-008 | **迷雾视觉效果验证**: 启用 fog 关卡中观察迷雾三态颜色、移动后揭示、隐藏敌人不出现在 targeting、侦察兵视野加成正确 | 当前 Windows build; FogStateManager/FogRenderer/FogTargetFilter 已实现 | 截图 2-3 张（迷雾初始/揭示后/敌人出现），记录视觉问题 | OPEN |
| 9 | P1 | MAN-009 | **组合技 UI 验证**: 羁绊 A 级角色相邻时 combo 按钮状态、门槛不满足时 disabled+tooltip 文字、执行后冷却倒计时 | BondRegistry + ComboValidator + ComboSkillData 已实现 | 截图 2 张（按钮激活/禁用状态），记录 UI 交互问题 | OPEN |
| 10 | P1 | MAN-010 | **难度倍率感受验证**: 玩 Ch.1(0.7×) vs Ch.3(1.0×) vs Ch.6+(1.2×)，确认敌人强度差异可感知 | DifficultyManager + phase_curve.json 已实现；自动化倍率应用已 PASS | playtest 笔记，记录各阶段战斗难度主观感受 | OPEN — AI 数值验证完成，主观体感仍需真人 |
| 11 | P1 | MAN-011 | **Boss 数据模型验证**: 使用现有 Ch.2/Ch.3 Boss 战，确认 BossProfile/BossPhase/BossCheckpoint 数据加载正确 | BossProfile/Phase/Checkpoint/ActionPattern 已实现；Resource 与兼容 API 自动化已 PASS | 战斗中观察 Boss 名称/阶段/前兆是否正确显示 | OPEN — AI 数据验证完成，战斗内可见性仍需真人 |

### Sprint-009 完整验证

| 顺序 | 优先级 | ID | 人工任务 | 前置条件 | 输出物 | 状态 |
|---:|---|------|------|------|------|---|
| 12 | P0 | MAN-012 | **Sprint-009 packaged smoke**: 双击 `builds/windows/SRPG.exe` → 主菜单 → 战斗(迷雾关) → combo 触发 → 存档 → 读档 → 退出 | 自动化 gate 全 PASS (1037/1037, check-only 0, export OK, strict packaged smoke PASS) | smoke 报告 | OPEN — 自动 packaged smoke 已 PASS，人工双击 walkthrough 仍需真人 |
| 13 | P2 | MAN-013 | **装备 +11+ 风险体验**: 强化装备到 +11 以上，确认失败降级概率合理、保护符号消耗可见 | EQUIP-014 概率曲线与保护符号消耗已实现并测试 | 记录强化日志（等级/成功/失败/符号消耗） | OPEN — AI 规则/UI 验证完成，主观公平感仍需真人 |

### AI 自动完成记录 (2026-05-02)

| ID | 覆盖人工项 | 自动完成内容 | 证据 |
|---|---|---|---|
| MAN-AUTO-001 | MAN-010 | 难度曲线、combat/settlement/AI bridge、packaged smoke 启动错误修复 | `tests/unit/difficulty/*.gd`, `production/qa/evidence/sprint-009-ai-auto-evidence.md` |
| MAN-AUTO-002 | MAN-011 | BossProfile/BossPhase/BossCheckpoint/BossActionPattern 数据模型、兼容 API、序列化测试 | `tests/unit/boss/*.gd` |
| MAN-AUTO-003 | MAN-012 | Windows export、完整 GUT、strict packaged smoke、可启动性检查 | `tools/package_windows_release.ps1` |
| MAN-AUTO-004 | MAN-013 | +11+ 成功率、失败降级、保护符号 `x2+` 消耗、UI enable/disable 回归 | `tests/unit/equipment/extreme_risk_test.gd`, `tests/integration/ui/character_management_test.gd` |

### 已完成

| ID | 来源 | 结果 | 证据 |
|---|---|---|---|
| MAN-DONE-003 | Sprint-009 QA verification | 自动化全部 PASS | `production/qa/evidence/sprint-009-qa-evidence.md` — 1037/1037 PASS, export OK, strict packaged smoke PASS |
