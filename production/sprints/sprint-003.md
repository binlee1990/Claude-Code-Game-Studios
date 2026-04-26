# Sprint 3: Chapter 2 实战实装

> Version: v1.0 | Date: 2026-04-26 | Status: **PLANNING** — 接受 Plan，QA plan 待生成
> Previous: sprint-002 v1.0 COMPLETE（治理 + 观感 P0 + Ch.2 内容基线）
> Control Manifest: 2026-04-26-v2（覆盖 ADR-001~006）
> Review Mode: solo（PR-SPRINT 跳过；每 story 仍要求 /code-review）

## Sprint Goal

把 Chapter 2 从「GDD/JSON skeleton」推进到「玩家可玩的三战完整内容」：实装信念值首次分叉路由（B2-GATE）、护送战核心新机制（王秀 A* AI + 护卫姿态分摊）、Boss·陈朗三阶段战斗（含检查点 + 援军刷新）、果子二选三结算屏。

## Capacity

- Total days: 5（2026-04-26 → 2026-05-01）
- Buffer (20%): 1 day（应对 boss-system 占位 GDD 补写、AI 调参、checkpoint 边界 bug）
- Available: 4 days
- Sprint-002 历史 velocity 参照：18 stories / 5 天（其中 6 文档 + 8 UI/资产 + 4 内容设计）；Sprint-003 全 Logic，单价更高，6 stories 是合理上限

## 入场前提

| 项 | 状态 |
|---|---|
| sprint-002 | COMPLETE |
| stage.txt | Production |
| 12 epic + chapter-02 epic 入口 | 是（chapter-02 stories 仍是 placeholder） |
| Ch.2 GDD 8 节全量 | 是（design/gdd/chapter-02.md 531 行） |
| 信念值分支文档 | 是（design/narrative/belief-branching.md，B2-GATE 阈值=5 已锁定） |
| Ch.2 三战 JSON skeleton | 是（chapter_02_act_a/act_b/finale.json） |

## Sprint-003 输入文档

| 文档 | 路径 | 角色 |
|---|---|---|
| Ch.2 GDD | `design/gdd/chapter-02.md` | 权威源 — Detailed Rules / Formulas / AC |
| 信念值分支文档 | `design/narrative/belief-branching.md` | B2-GATE 公式与节点矩阵 |
| Chapter-02 epic 入口 | `production/epics/chapter-02/index.md` | 6 story 列表与 TR-IDs（placeholder） |
| Ch.2 三战 JSON | `src/ui/combat/battle_definitions/chapter_02_*.json` | 战斗定义；与代码对接 source of truth |
| 总纲 | `design/gdd/SRPG 核心模块设计总纲.md` | Boss 七原则、信念值上位规则 |

---

## Tasks

### Must Have（Critical Path）— Ch.2 实战核心

| ID | Task | Agent/Owner | Est. Days | Dependencies | Acceptance Criteria |
|----|------|-------------|-----------|-------------|-------------------|
| CH2-c-001 | 章节路由 + 信念值首次分叉（B2-GATE 实装） | gameplay-programmer | 0.5 | belief-branching §4.1 / chapter-02 §3.8 | AC-CH2-001 三场景全部 PASS（义领先→suppression / 仁领先→mercy / 三平→mercy_default）+ AC-CH2-007 边界 |
| CH2-c-002 | 王秀护送 AI（A* + 畏缩 + 安全区到达 + 退场剧情） | ai-programmer | 1.0 | ai-system 已有 pathfinding | AC-CH2-002 + AC-CH2-004（5 回合移动 + 阻塞畏缩 + 退场标志写入存档） |
| CH2-c-003 | 护卫姿态伤害分摊系统 | gameplay-programmer | 0.5 | combat_system / damage 计算管线 | AC-CH2-003（20 伤害 → 王秀 14/护卫 6）；guard_transfer_ratio 数据驱动；多护卫取速度序列首位 |
| CH2-c-004 | 镇压战部分失败结算（流民逃离计数 + 击杀计数对比） | gameplay-programmer | 0.5 | battle-settlement / 信念值节点 B2-N2B | edge case 5.9（≤4 逃离正常胜利，>4 触发部分失败义-5）+ B2-N2B 比较结算 |
| CH2-c-005 | Boss·陈朗三阶段 + 检查点 + 援军刷新 | ai-programmer | 1.0 | BOSS-GDD-001（本 sprint 内补） / turn-based 援军刷新接口 | AC-CH2-005 + AC-CH2-006（三阶段切换 / 第 12 回合或阶段三提前 / 检查点 HP 保留 15%） |
| CH2-c-006 | 果子二选三结算屏（强制弹窗 + 资源经济写入） | gameplay-programmer + ui-programmer | 0.5 | resource-economy / battle-settlement | AC-CH2-008（三选二 / 第三种弃 / 中断重载再次弹出） |

### Should Have — 阻塞解除 + 治理收尾

| ID | Task | Agent/Owner | Est. Days | Dependencies | Acceptance Criteria |
|----|------|-------------|-----------|-------------|-------------------|
| CH2-c-000 | 创建 6 个 story 文件（chapter-02 epic 当前是 placeholder） | producer | 0.25 | epic index 已有列表 | 6 个 story-001~006.md 落地；每个 /story-readiness PASS |
| BOSS-GDD-001 | boss-system 占位 GDD（解锁 CH2-c-005 依赖） | game-designer | 0.5 | 总纲 Boss 七原则 + chapter-02 §3.6 | 8 段 GDD skeleton 至少含 Detailed Rules / Edge Cases / AC，足够 CH2-c-005 引用 |
| GOV-ADR-007 | ADR-007 信念值与分支系统 | technical-director | 0.25 | belief-branching.md / B2-GATE 实装结果 | status=Accepted；覆盖 belief_values 持久化 + 分叉判定 + soft/hard lock 路径 |

### Nice to Have — 收尾债务 / 体验性验收

| ID | Task | Agent/Owner | Est. Days | Dependencies | Acceptance Criteria |
|----|------|-------------|-----------|-------------|-------------------|
| QA-EVID-001 | Sprint-002 截图归档 + Windows packaged smoke 重跑 | human + qa-tester | 0.25 | builds/windows/SRPG.exe | production/qa/evidence/sprint-002-presentation-p0.md 4 屏截图 + smoke PASS |
| CH2-PT-001 | Ch.2 三战 playtest + 信念值数据采集（验证 AC-CH2-009 ≥15 差值） | qa-lead + human | 0.5 | 6 stories 全 DONE | 3 名玩家完整通关 Ch.2，差值统计脚本输出 ≥15 |

---

## Carryover from Previous Sprint

| Task | Reason | New Estimate |
|------|--------|-------------|
| Windows packaged smoke 重跑 | Sprint-002 outstanding；属人工动作 | 0.1 day（QA-EVID-001 内合并） |
| 截图归档 production/qa/evidence/sprint-002-presentation-p0.md | 同上 | 0.15 day（QA-EVID-001 内合并） |

---

## Risks

| Risk | Probability | Impact | Mitigation |
|------|------------|--------|------------|
| 王秀 A* + 畏缩 AI 调参周期长（CH2-c-002 估 1d 偏乐观） | HIGH | HIGH — 整 Sprint 推迟 | 第 1 天先做 CH2-c-001 + CH2-c-003 + CH2-c-006（独立 stories）；CH2-c-002 + CH2-c-005 第 2-4 天集中处理；超期立即转 Sprint-004 |
| boss-system GDD 缺失（CH2-c-005 阻塞） | MED | MED | BOSS-GDD-001 在 Should Have 但视为 CH2-c-005 硬前置；GDD 不需 8 节全量，只需 §3 Detailed Rules 足够指导实装 |
| 检查点 HP 保留逻辑（AC-CH2-006）实装难度高 | MED | MED | 第 1 天对照 chapter_01_finale 已有的多阶段 Boss 实现做差异分析；保留 15% 公式简单（HP × 0.15），主要在状态机切换 |
| 信念值分叉测试覆盖不足 | LOW | MED | CH2-c-001 强制覆盖 AC-CH2-001 全部三场景 + AC-CH2-007（边界截断） |
| Ch.2 三战 JSON 与代码字段对接发散 | MED | LOW | Sprint-002 已交付的 JSON 作为对接 source of truth；冲突时以 GDD §3 为准修 JSON |
| stories 文件不存在（chapter-02 epic 仅 placeholder） | HIGH（已知） | HIGH（无法 /story-readiness） | CH2-c-000 第 1 天首先完成；阻塞所有 CH2-c-* |

## Dependencies on External Factors

- `design/gdd/boss-system.md` 不存在（chapter-02 §6.1 注明）→ BOSS-GDD-001 解决
- `design/gdd/bond-system.md` 不存在 → 仅影响 CH2-c-001 的 R3 羁绊特殊对话 edge case，本 Sprint 该 edge case 标 deferred 到 Sprint-004
- `production/registries/tr-registry.yaml` 已有 TR-ch2-001~006 placeholder → /architecture-review 可在 Sprint-003 末跑一次刷新

---

## 不在本 Sprint 范围（明确排除）

- ADR-008（资源经济升级）/ ADR-009（装备升级）→ Sprint-004
- bond-system / fog-of-war / 基地 / 多周目 / 事件系统 / 正式音频 6 系统 epic 化 → Sprint-004 或 Sprint-005
- 管理屏 Beta（手动编队 / 装备切换 UI / 结算屏全量）→ Sprint-004（UX 提案 Beta 目标专项 sprint）
- Ch.3 GDD 设计 → 等 Ch.2 playtest 数据回流后再排（Sprint-005+）
- 角色立绘 / 3D 立牌正式美术资产 → Beta 阶段

---

## 执行顺序建议（5 天节拍）

```
Day 1  : CH2-c-000（story 文件落地）+ CH2-c-001（章节路由 / B2-GATE）+ BOSS-GDD-001 启动
Day 2  : CH2-c-002（王秀 AI 上半，A* + 畏缩）+ CH2-c-003（护卫姿态分摊，可并行）
Day 3  : CH2-c-002（王秀 AI 下半 / 调参 / 退场剧情）+ CH2-c-004（镇压战结算）
Day 4  : CH2-c-005（Boss 三阶段 + 检查点 + 援军，BOSS-GDD-001 必须前置 PASS）
Day 5  : CH2-c-006（果子二选三）+ Ch.2 三战 smoke 串通 + GOV-ADR-007 + QA-EVID-001
```

---

## Definition of Done for this Sprint

- [ ] 6 个 Must Have stories 全部 /story-done COMPLETE
- [ ] CH2-c-000（story 文件落地）+ BOSS-GDD-001（占位 GDD）+ GOV-ADR-007 DONE
- [ ] AC-CH2-001~008 全部自动化测试覆盖（AC-CH2-009 体验性放 Nice to Have playtest）
- [ ] godot --check-only --quit：0 parse error
- [ ] GUT 测试套件：≥686 + 新增（无 regression）
- [ ] Ch.2 三战可在主菜单完整连贯打通（手工 smoke）
- [ ] QA plan 存在（`production/qa/qa-plan-sprint-3.md`）
- [ ] 每 story 已 /code-review（solo 模式不强制 PHASE-GATE，但单 story review 必跑）
- [ ] active.md 同步至 Sprint-003 COMPLETE
- [ ] No S1/S2 bugs in delivered features
- [ ] 设计文档：sprint 期间若发现 GDD 与实现差异，先改 GDD 再改代码（GDD 为权威源）

> **Scope check:** 本 Sprint 仅落地 chapter-02 epic 已有的 6 stories + 治理收尾 + 风险占位 GDD，无超出 epic 原范围的新增。如后续要追加新 story，请运行 `/scope-check chapter-02`。
