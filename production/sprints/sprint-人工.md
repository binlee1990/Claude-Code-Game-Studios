# Sprint 人工操作集中队列

> Version: v1.0 | Date: 2026-04-27 | Status: **OPEN**
> Source: 从 `sprint-001.md` ~ `sprint-005.md` 抽离的人工执行、人工验收、截图归档、试玩、听感确认与 sign-off 工作。

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

## 执行约束

- 每个人工任务开始前先确认对应自动化 gate 已通过，避免用人工时间排查可自动发现的问题。
- 每个报告必须写清：build/hash 或日期、执行人、执行路径、截图/录屏路径、结果、阻塞项、可接受 notes。
- 如果人工结果只产生体验建议，不阻塞当前自动化交付，应标为 `PASS WITH NOTES` 并把后续改动转入对应 epic / backlog。
- 不在原 sprint 文档中新增新的人工 gate；新的人工项继续追加到本文件。
