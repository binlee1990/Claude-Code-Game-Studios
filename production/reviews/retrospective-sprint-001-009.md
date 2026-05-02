# Sprint-001~009 综合 Retrospective

> **Date**: 2026-05-02
> **Scope**: 9 sprints, 19 epics Complete, 1021 Sprint-009 tests; current post-audit baseline 1037 tests
> **Phase**: Production — Vertical Slice 完整交付
> **Source**: sprint-001.md ~ sprint-009.md + sprint-status.yaml + active.md

---

## Per-Sprint 摘要

### Sprint-001 — Vertical Slice 核心循环

| 维度 | 数据 |
|------|------|
| **Goal** | 完成 SRPG 核心战斗循环的 Vertical Slice：战斗开始→结算→奖励的完整闭环 |
| **Stories** | 13 条新交付（2 turn-based + 5 battle-settlement + 3 camera-map + 3 UI）；前置 31 条已完成 stories 来自 5 个 epic |
| **Must/Should/Nice** | 全部 Must（未分层） |
| **Test 基线** | 805 条 `test_` 方法（静态 grep） |
| **Status** | COMPLETE WITH PRODUCT-SCOPE NOTES |
| **Key Risks/Issues** | **等距摄像机延期**：计划为斜45度，实际交付 2D top-down 回退方案；story-001-isometric-camera 标记 Deferred |
| **Notable** | 打包版 smoke 退出时 Godot 报告资源仍在使用 warning；4 个核心 epic 完成（回合/结算/视角/UI）；奠定后续 sprint 的内容消费框架 |

---

### Sprint-002 — 治理闭合 + Presentation P0 + Chapter 2 Foundation

| 维度 | 数据 |
|------|------|
| **Goal** | 闭合三类债务：治理债（ADR 提升 + TR 回填）、观感债（字体/BGM P0 修复）、内容断点债（Ch.2 GDD 全量） |
| **Stories** | 18 条（Lane A 治理 6 + Lane B 观感 8 + Lane C 内容 4） |
| **Must/Should/Nice** | 未分层（三 lane 平行，各有 Gate） |
| **Test 基线** | 686/686 GUT PASS；静态 805 条 |
| **Status** | COMPLETE |
| **Key Risks/Issues** | **BGM 资产 URL 死链 3/4**：audio-director 重做后仍不可达，orchestrator 通过 archive.org 解决；**中文字体覆盖**：用 Noto Serif SC 子集缓解生僻字风险；**License 合规**：OFL + CC-BY 3.0 署名义务记录但未在游戏内展示 |
| **Notable** | 首次三 lane 并行 Sprint；Control Manifest 升级至 v2（覆盖 ADR-001~006）；ADR-004/005/006 从 Proposed 提升至 Accepted；Chapter 2 GDD 531 行全量交付 |

---

### Sprint-003 — Chapter 2 实战实装

| 维度 | 数据 |
|------|------|
| **Goal** | Ch.2 GDD/JSON skeleton → 玩家可玩的三战完整内容（信念值首次分叉 + 王秀 AI + Boss 三阶段 + 果子二选三） |
| **Stories** | 9 条（Must 6 + Should 3） |
| **Must/Should/Nice** | 6 / 3 / 0 |
| **Test 基线** | 静态 805 条（实际新增 ~79 条 Logic 测试，使用旧 grep 方法未反映） |
| **Status** | COMPLETE WITH AUTOMATION NOTES |
| **Key Risks/Issues** | **Story 文件不存在**（CH2-c-000 硬前置）：chapter-02 epic 仅 placeholder，Day 1 首先生成 6 个 story 文件；**Boss GDD 缺失**：boss-system GDD 在 Sprint 内补写（BOSS-GDD-001）；**AI 调参偏乐观**：王秀 A* 护航 AI 估 1 天，实际风险较高但 mitigated by 优先做独立 story |
| **Notable** | 全 Logic 密集型 Sprint；信念值 B2-GATE 第一次上线；Boss 三阶段复用 pattern 建立；ADR-007 信念分支系统 Accepted |

---

### Sprint-004 — 管理界面 Beta + 基地系统 MVP

| 维度 | 数据 |
|------|------|
| **Goal** | 解决玩家直接反馈：无培养机制 + 无法设置己方人员属性；通过管理界面和基地 MVP 提供养成闭环 |
| **Stories** | 8 条（Must 5 + Should 3） |
| **Must/Should/Nice** | 5 / 3 / 0 |
| **Test 基线** | 静态 805 条 |
| **Status** | COMPLETE WITH AUTOMATION NOTES |
| **Key Risks/Issues** | **用户反馈驱动 sprint**：直接响应玩家"没有培养机制"反馈；**ux-spec 缺失**：MGMT-001/002 无 ux-spec，Day 1 同步产出 |
| **Notable** | UI 重（5/8 为 UI 类型）；character-management/equipment-system epic 逻辑层已全 Complete，UI 接入低风险；基地系统仅 MVP，完整版（酒馆/情报室/升级）推入后续 sprint |

---

### Sprint-005 — 本地化 + Credits 合规 + Ch.3 准备

| 维度 | 数据 |
|------|------|
| **Goal** | 关闭公开构建风险缺口：全量 UI 本地化、语言切换与持久化、游戏内 Credits、规划漂移修复 |
| **Stories** | 14 条（Must 5 + Should 4 + Nice 5） |
| **Must/Should/Nice** | 5 / 4 / 5 |
| **Test 基线** | 817 条（+12 vs Sprint-004） |
| **Status** | COMPLETE WITH SPRINT-006+ SCOPE NOTES |
| **Key Risks/Issues** | **LOC-001 覆盖面过大**：硬编码字符串迁移可能吞噬整个 Sprint；**打包版 smoke 资源泄漏**：ObjectDB/resources still in use warning，Sprint 内 triage 并修复；**发布后修复**：中文语言下仍有英文残留，Post-completion Fix 补齐 |
| **Notable** | 首次使用 reframe-and-execute review模式；ADR-008/009 Draft→Accepted（独立工作流）；`zh_CN`/`en_US` key parity 100% 达标；Ch.3/Bond/Base/Fog readiness 文档全量交付；Sprint-005 发包 smoke 不再报告资源泄漏 |

---

### Sprint-006 — 养成深度：Bond MVP + Equipment Enhancement + Base Phase 1

| 维度 | 数据 |
|------|------|
| **Goal** | 将 Sprint-005 readiness 转化为可玩养成闭环：Bond 数据层 + affinity 钩子、装备强化 MVP（+1~+5）、基地行动点 + 情报室 MVP |
| **Stories** | 12 条（Must 5 + Should 4 + Nice 3） |
| **Must/Should/Nice** | 5 / 4 / 3 |
| **Test 基线** | ~835 条（Codex 执行轮次，无独立复验精确计数） |
| **Status** | COMPLETE WITH SPRINT-007+ SCOPE NOTES |
| **Key Risks/Issues** | **Bond 数据模型命名冲突**：`SaveData.story_progress.bond_levels` 可能与新 pair-keyed 格式冲突；**装备强化 UI 层级过深**：在角色管理 Tab 内嵌套强化面板，用 modal overlay 解决；**ADR-008 数据表格式未定**：优先约定 schema 再落地 |
| **Notable** | 首次大量使用 Codex 执行轮次做验证 gate；4 个自动化 gate 均为 Codex 报告值，无独立复验；packaged smoke 首次包含 `bond_growth_present:true` + `base_enhanced_level:5` |

---

### Sprint-007 — Ch.3 战斗 1 + Bond 酒馆 + Base 升级 + Equipment +6 + Architecture Review Full

| 维度 | 数据 |
|------|------|
| **Goal** | 将养成深度切到可推进的内容深度：Ch.3 战斗 1 可玩、Bond 酒馆对话主动 affinity 增长、Base 酒馆 + 升级 UI、装备 +6 风险区闭合、Architecture Review full mode |
| **Stories** | 12 条（Must 7 + Should 3 + Nice 2） |
| **Must/Should/Nice** | 7 / 3 / 2 |
| **Test 基线** | 855 条（+20 vs Sprint-006 估计值；初版 849 条，偏差修复后 855 条） |
| **Status** | COMPLETE |
| **Key Risks/Issues** | **2 项偏差**：Ch.3 战斗数据路径缺失（plan 预期 `assets/data/chapters/chapter_03_battle_1.json`，实际仅有 `battle_definitions/chapter_03_act_a.json`）；装备风险区测试嵌入 enhancement_test 而非独立文件 — 均在复核中修复 |
| **Notable** | Architecture Review full mode 首次 PASS，3 个 Sprint-005 follow-up（F-1/F-2/F-3）全闭合；GUT check-only 与 Windows export 均已独立复验；packaged smoke 含 `chapter3_battle` + `tavern_affinity` + `risk_enhanced_level` 新指标 |

---

### Sprint-008 — Ch.3 内容完成 + 装备养成收口

| 维度 | 数据 |
|------|------|
| **Goal** | Ch.3 从前半截推进到完整三战可玩：Battle 2 压力量表 + B3-GATE 信念分叉激活 + Finale Boss；装备分解/reroll UI 收口 |
| **Stories** | 10 条（Must 6 + Should 2 + Nice 2） |
| **Must/Should/Nice** | 6 / 2 / 2 |
| **Test 基线** | 879 条（+24 vs Sprint-007） |
| **Status** | COMPLETE |
| **Key Risks/Issues** | **B3-GATE 与既有 belief_system 耦合**：Day 1 先读代码再隔离实现；**3 个战斗在同一 Sprint 超估**：CH3-c-004 Finale 放入 Should Have 可浮动；**零偏差**：所有交付物路径与预期一致 |
| **Notable** | architecture.md §8 ADR 列表扩展至 001~009；BondSystem 接口清理（移除超前 `trigger_combo_skill`）；Fog/Bond GDD 详化为 Sprint-009 实现 ready；packaged smoke 含 `b3_gate_route=ren` + `chapter3_complete=true` + `reroll_preserved_level=7` |

---

### Sprint-009 — Vertical Slice 系统收尾

| 维度 | 数据 |
|------|------|
| **Goal** | 完成 Vertical Slice 层全部 4 个系统（fog-of-war / bond-combo / difficulty / boss），不含章节剧情内容 |
| **Stories** | 12 条（Must 7 + Should 3 + Nice 2） |
| **Must/Should/Nice** | 7 / 3 / 2 |
| **Test 基线** | **1021 条**（+142 vs Sprint-008，历史最大单 Sprint 增量） |
| **Status** | COMPLETE（1021/1021 PASS at sprint close; 1037/1037 after post-audit hardening） |
| **Key Risks/Issues** | **Fog 渲染性能**（15x15~25x25 tile overlays）：MVP 不做 LOS 裁剪，关闭 fog 的关卡零开销；**Difficulty 集成触及三系统**：按 combat→settlement→AI 顺序集成缓解耦合；**Boss telegraph 视觉效果**：MVP 用纯色矩形/闪烁占位，不依赖正式资产 |
| **Notable** | 首次在一个 Sprint 内落地 4 个新系统；+117 tests from Sprint-009 alone；新增源文件 12 个（~500 行代码）；新增测试文件 9 个；BOND-COMBO-002 与 BOSS-002 在 Sprint-010 仍有遗留 standalone test 需求 |

---

## 跨 Sprint 趋势

### Velocity（Stories per Sprint）

```
S001: ████████████████ 13 (4 epic 交付，31 条已前置)
S002: ██████████████████████ 18 (doc-heavy，三 lane 并行)
S003: ███████████ 9 (全 Logic 密集型)
S004: ██████████ 8 (UI 重，用户反馈驱动)
S005: █████████████████ 14 (UI+Integration+Doc+QA 混合)
S006: ██████████████ 12 (Logic+Integration 重)
S007: ██████████████ 12 (Content+Logic+UI+Governance 混合)
S008: ████████████ 10 (Content 重)
S009: ██████████████ 12 (Logic+Integration 重，4 新系统)
───────────────────────────────────
Average: 12.0 stories/sprint
Range: 8–18
```

**分析**：Story count 作为 velocity 指标有显著偏差 —— S002 的 18 stories 包含大量轻量 doc 任务（ADR 状态修改、TR 回填），而 S003 的 9 stories 均为高强度 Logic 代码。真实 velocity 在功能性交付层面保持稳定，Story 类型混合（Logic/Integration/UI/Doc/Governance）是 count 变化的主因。

### Test Growth（Per-Sprint Delta）

```
S001–S004: 805 ─────────────── Plateau (4 sprints 无增长)
S005:      817 (+12)          ██ localization + credits
S006:      ~835 (+18)         ███ Bond + Equipment + Base
S007:      855 (+20)          ███ Ch.3 Battle 1 + Equipment risk + Base upgrade
S008:      879 (+24)          ████ Ch.3 B2/B3 + B3-GATE + decomp/reroll
S009:     1021 (+142)         ████████████████████████████ fog + bond-combo + difficulty + boss
─────────────────────────────────────────────────────────────
Total growth: +216 (26.8% over baseline)
Average delta (S005–S009): +43.2 tests/sprint
```

**分析**：
- **S001–S004 测试计数假象**：早期 sprint 使用 `grep test_` 静态计数，未能反映实际新增测试。S003 实际新增 ~79 条 Logic 测试但 grep 仍报告 805。方法论切换至 GUT runner 输出后（S005+）才反映真实增长。
- **S009 爆发**：4 个新系统同时落地，测试密度极高（+142），验证了"Logic 型 story 天然携带高测试密度"的规律。
- **无回归**：全部 9 个 Sprint 0 test regression，GUT runner 始终 `0 fail`。

### Risk 模式

| 风险类型 | 出现 Sprint | 频率 | 最终处理 |
|----------|-------------|------|----------|
| **Story 文件不存在** | S003, S006, S007 | 3/9 | Day 1 首先生成，硬前置解决 |
| **Implementation scope 超估** | S003, S006, S007, S008 | 4/9 | Should/Nice 浮动到下一 Sprint |
| **GDD 缺失或未就绪** | S003 (boss), S004 (ux-spec), S005 (credits-screen) | 3/9 | Sprint 内补写 |
| **打包版 smoke 资源泄漏** | S001, S002, S003, S004 | 4/9 | S005 TECH-001 修复 |
| **外部验证队列积压** | S001–S009 | 9/9 | 集中至 sprint-人工.md，从未阻塞自动化 DoD |
| **Codex 验证独立性** | S006, S007, S008, S009 | 4/9 | 部分 gate 仅 Codex 报告值，独立复验未全覆盖 |
| **资产获取困难** | S002 (BGM) | 1/9 | archive.org 介入解决 |

**核心发现**：
- "Story 文件不存在"是最高频的 Day 1 blocker，反映出 epic/story 创建与 sprint 启动之间的 gap
- "Implementation scope 超估"是预期内的 AI-native sprint 特征 —— Should/Nice 浮动机制有效吸收了不确定性
- 外部验证（sprint-人工.md）作为 Release 债务持续累积，当前 0 阻塞但 Beta 阶段前必须消化

### Bottleneck 分析

| 瓶颈 | 严重度 | 影响范围 |
|------|--------|----------|
| **gameplay-programmer** | HIGH | 跨所有 Sprint 的最重 loaded agent，Logic + Integration 双负载 |
| **GDD → Implementation 串行依赖** | MEDIUM | Content sprint (S003, S007, S008) 必须先有 GDD 再实现 |
| **ADR 接受滞后** | MEDIUM | ADR-004~006 在 S002 才从 Proposed 提升（S001 已完成实现）；ADR-008/009 至 S005 才 Draft→Accepted |
| **Epic/Story 文件创建** | LOW（已缓解） | S003 后建立 Day 1 首先生成 story 文件的惯例 |
| **Codex 验证可信度** | LOW（需关注） | S006+ 部分 gate 仅 Codex 报告值，无独立复验链 |

---

## Actionable Insights

### 1. Sprint-Start 自动化：预创建 Story 文件

**问题**："Story 文件不存在"在 3/9 sprints 中成为 Day 1 硬 blocker。

**建议**：在 sprint-plan 生成阶段自动创建所有 epic/story skeleton 文件，而非等到 sprint 启动 Day 1。将 "story files exist" 加入 sprint Start Gate checklist。

**预期收益**：消除高频 Day 1 blocker，Sprint 可直接从 /dev-story 开始。

### 2. 外部验证 Pipeline：将 sprint-人工.md 拆分为 CI 可达项

**问题**：外部验证队列（截图/人工 playtest/听感确认）持续 9 个 Sprint 未闭合，当前 0 阻塞但 Beta/Polish 阶段会成为硬阻塞。

**建议**：
- 将截图验证移至 headless CI（`godot --headless --screenshot` + golden image diff）
- 将 BGM 循环听感、字体视觉效果等不可自动化项标定 Beta milestone 日期
- Sprint-010 或 Beta 启动时做一次 sprint-人工.md 全量 triage

**预期收益**：减少 Release 阶段集中爆发风险。

### 3. gameplay-programmer 负载再平衡

**问题**：gameplay-programmer 是 9 个 Sprint 中最高频的 agent，Logic+Integration 双负载。S003 和 S008 的 scope 超估风险均与该角色相关。

**建议**：
- 将 Integration 型 story 更多地分配给 ui-programmer（有 UI 元素的集成）和 ai-programmer（AI 类集成）
- 在 Sprint 中显式标注每个 agent 的 estimated load，避免单个 agent 负担超过 40%
- 考虑增加 gameplay-programmer 的并行 instance（Logic 与 Integration 通常可独立）

**预期收益**：降低单 sprint 超估概率，提高 Should Have 完成率。

### 4. 测试计数方法论统一

**问题**：S001–S004 使用 `grep test_` 静态计数，未能反映实际测试增长；S005+ 才切换到 GUT runner 输出。历史数据在 S001–S004 区间不可比。

**建议**：
- 每个 Sprint 的 DoD gate 统一使用 GUT runner 输出（`total / pass / fail`）
- 将 test count 作为 Sprint 健康指标写入 sprint-status.yaml
- 弃用静态 grep 方法，或仅作为 sanity check

**预期收益**：可比的 test growth metric，更早发现测试覆盖停滞。

### 5. Codex 验证独立复验轮换

**问题**：S006+ 的 4 个自动化 gate 中，check-only 与 GUT 在部分 sprint 已独立复验，但 Windows export 与 packaged smoke 完全依赖 Codex 报告值。

**建议**：
- 每 3 个 Sprint 做一次全量独立复验（本地运行 check-only / GUT / export / smoke）
- 将 Codex 验证视为"开发期快速反馈"而非"权威 gate"
- 在 Sprint-010 的 gate-check 中纳入所有 4 gate 的独立复验

**预期收益**：消除 Codex 单点验证风险，确保 gate 可信。

---

## 关键里程碑时间线

```
2026-04-23  Sprint-001 Start  —  Vertical Slice 核心
2026-04-26  Sprint-002 Start  —  治理 + 观感 P0
2026-04-26  Sprint-003 Start  —  Ch.2 实战
2026-04-26  Sprint-004 Start  —  管理界面 + 基地 MVP
2026-04-27  Sprint-005 Start  —  本地化 + 合规
2026-04-27  Sprint-006 Start  —  养成深度
2026-04-27  Sprint-007 Start  —  Ch.3 Battle 1 + Bond + Base
2026-04-27  Sprint-008 Start  —  Ch.3 内容完成
2026-05-02  Sprint-009 Complete —  Vertical Slice 全系统 COMPLETE
2026-05-02  Sprint-010 Start  —  治理收口 + 里程碑审查
```

> **注**：Sprint 002–008 的实际执行均密集压缩在 2026-04-26 ~ 2026-04-28 区间（AI-native 并行执行），plan 窗口（各 5 天）与实际交付时间有显著差异。这反映了 AI agent 执行速度远超传统时间预算，但 plan 中的 day-by-day 节拍主要用于依赖关系排序而非实际 wall-clock 时间。

---

## 数据溯源

| 数据点 | 来源 |
|--------|------|
| Sprint Goal / Story 计数 | `production/sprints/sprint-00*.md` |
| Test 基线 | GUT runner 输出 + 静态 grep（S001–S004）/ GUT 输出（S005+） |
| Story 状态 | `production/sprint-status.yaml`（Sprint 008/009 archive） |
| 风险记录 | 各 Sprint 文件的 Risk Assessment 表 |
| 交付物证据 | 各 Sprint 的 Revalidation / Completion Evidence 段落 |
| Sprint-009 详细数据 | `production/session-state/active.md`（2026-05-02） |
