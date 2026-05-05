# Sprint 12 — MVP Experience Glue（FTUE + 内容 + 节奏）

> **Created**: 2026-05-05
> **Status**: Complete — audited and repaired on 2026-05-05
> **Predecessor**: Sprint 11（UI Scene Layer — First Playable 达成）
> **Goal Type**: 体验层落地 — 将 6 份设计文档转化为可实现的 story

## Sprint Goal

将 30 系统 MVP 从"能跑的零件集合"升级为"有连贯体验的可玩游戏"。落实 6 份体验层设计文档（设计总计 ~3,200 行）中 Sprint 12 可实现的 MVP 内容：FTUE 引导、渐进 UI 解锁、敌人/掉落数据配置、境界突破仪式、离线结算体验。

**出口标志**: 新玩家从标题画面 → 首次修炼 → 战斗解锁 → 首次突破 → 首次离线回归 的完整 6 阶段引导流畅运行；3 区域 15 敌人配置完整；境界突破有视觉反馈。

## Layer / Milestone

- Layer: Experience Layer（新 — 连接系统与玩家）
- Milestone: 🎯 **Sprint 12 Experience Complete** — 玩家能通过 FTUE 引导跑通完整 MVP 循环

## MVP 边界（Codex 收紧后）

| 维度 | MVP 包含 | Phase 2+ 排除 |
|------|---------|--------------|
| 等级 | Lv.1–30 | Lv.31+ |
| 境界 | 凡人→炼气→筑基 | 金丹/元婴 |
| 掉落 | exp / lingshi / herb | 装备/碎片/稀有材料 |
| 战力 | base × realm_pool | equipment pool |
| 区域 | 青丘山林/幽墟灵谷/荒殒战场 | 更多区域 |
| 引导 | 6 阶段渐进发现（无弹窗教程） | 教程弹窗/箭头/强制路径 |
| 战法 | 无（纯普攻自动） | 战法配置 UI |

## AI Context Budget

- Stories: ≤ 20（~18 预估）
- Parallelizable: ~6 stories（数据配置类彼此独立；FTUE 各阶段可部分并行）
- Verification Density: 每个 Logic 类 story ≥ 5 tests；UI 类 story ≥ 1 screenshot + 1 walkthrough

## Epics

### Epic 1: Content Data Configuration（数据配置 — Must Have）

将 mvp-content-progression.md 的数值配置转化为 Godot 可加载的数据文件。

| ID | Story | Type | Depends On |
|----|-------|------|------------|
| S12-001 | Zone 1（青丘山林）敌人数据配置 — 5 敌人完整属性 + 掉落表 JSON | Logic/Config | none |
| S12-002 | Zone 2（幽墟灵谷）敌人数据配置 — 5 敌人完整属性 + 掉落表 JSON | Logic/Config | none |
| S12-003 | Zone 3（荒殒战场）敌人数据配置 — 5 敌人（含 1 精英）属性 + 掉落表 JSON | Logic/Config | none |
| S12-004 | 经验曲线数据配置 — Lv.1–30 逐级经验表 JSON | Logic/Config | none |
| S12-005 | 区域解锁条件数据配置 — zone_starter/zone_forest/zone_mine 的 unlock + graduate 条件 | Logic/Config | S12-001..003 |
| S12-006 | 离线倍率配置 + 经济平衡参数 — 4h 100%→24h 50% 衰减曲线 | Logic/Config | none |

### Epic 2: FTUE Onboarding（新手引导 — Must Have）

将 onboarding-flow.md 的 6 阶段引导落地为代码。

| ID | Story | Type | Depends On |
|----|-------|------|------------|
| S12-007 | FTUE 状态机 — 6 阶段定义 + 阶段转换条件 + 状态持久化 | Logic | none |
| S12-008 | Stage 0–1: 标题→首次修炼→战斗解锁 — 冷启动 UI 初始状态 + 灵气阈值 100 解锁战斗 | UI | S12-007 |
| S12-009 | Stage 2–3: 首次战斗循环→区域理解 — 前 10 条战斗日志展示策略 + Zone 2 锁定状态可见 | UI | S12-008 |
| S12-010 | Stage 4: 首次突破引导 — Lv.10 炼气突破的视觉/数值/叙事反馈 | UI | S12-009 |
| S12-011 | Stage 5: 首次离线回归 — 离线结算屏首次展示策略 + 回归牵引 | UI | S12-010 |
| S12-012 | HUD 渐进解锁 — 4→12 字段逐阶段淡入（对标 screen-flow.md §3） | UI | S12-007 |

### Epic 3: Progressive UI Unlock（渐进 UI — Must Have）

将 screen-flow.md 的 LEFT NAV 状态机和屏解锁序列落地。

| ID | Story | Type | Depends On |
|----|-------|------|------------|
| S12-013 | LEFT NAV 可见性状态机 — VISIBLE+ACTIVE / LOCKED / HIDDEN 三态 × 5 Tab | UI | none |
| S12-014 | 屏幕渐进解锁序列 — 修炼屏→战斗屏→资源屏→离线结算屏→存档屏的解锁触发 + 叙事文本 | UI | S12-013 |
| S12-015 | 屏间过渡与 RIGHT PANEL 上下文切换 — 5 屏的 RIGHT PANEL 内容映射 | UI | S12-014 |

### Epic 4: Realm Breakthrough Ceremony（境界突破 — Should Have）

| ID | Story | Type | Depends On |
|----|-------|------|------------|
| S12-016 | 凡人→炼气突破仪式 — 金色印章动画 + 属性跳变 + 新姿态解锁提示 | UI/Visual | S12-007 |
| S12-017 | 炼气→筑基突破仪式 — MVP 终局突破 + Phase 2+ 路线图预告 | UI/Visual | S12-016 |

### Epic 5: Session Rhythm（会话节奏 — Should Have）

| ID | Story | Type | Depends On |
|----|-------|------|------------|
| S12-018 | 离线结算三层递进 — Toast→Drawer→全屏摘要 + 收益数字展示策略 | UI | S12-011 |
| S12-019 | 会话退出"期待锚点" — 退出前展示"下次回来你会得到..."预估 | UI | S12-018 |

## Dependency Graph

```
Phase 1（并行 — 数据 + 状态机基础）:
  S12-001 Zone 1 数据    ─┐
  S12-002 Zone 2 数据    ─┤
  S12-003 Zone 3 数据    ─┼─→ S12-005 区域解锁条件
  S12-004 经验曲线数据    ─┘
  S12-006 离线倍率配置    ─── 独立
  S12-007 FTUE 状态机     ─┐
  S12-013 LEFT NAV 状态机 ─┘

Phase 2（并行 — UI 实现）:
  S12-008 Stage 0-1 UI   ─┐
  S12-009 Stage 2-3 UI   ─┤─ 依赖 S12-007
  S12-014 屏解锁序列      ─┤─ 依赖 S12-013
  
Phase 3（串行 — 体验闭环）:
  S12-010 Stage 4 UI     ──→ S12-011 Stage 5 UI ──→ S12-018 离线三层
  S12-016 炼气突破        ──→ S12-017 筑基突破
  S12-012 HUD 渐进解锁    ──→ S12-015 RIGHT PANEL 切换
  
Phase 4（收尾）:
  S12-019 退出锚点
```

## Verification Gates

| Gate | When | What |
|------|------|------|
| Content Smoke | After Phase 1 | PASS — 15 敌人、3 区域、15 掉落表、Lv.1-30 经验曲线一致性检查通过 |
| FTUE Smoke | After Phase 2 | PASS — `validate_sprint12_experience.gd` 覆盖 Stage 0→5 |
| Experience Smoke | After Phase 3 | PASS — 完整 FTUE 6 阶段 + 境界突破 + 离线回归验证通过 |
| Regression | After Phase 4 | PASS — `reports/report_36/results.xml` GdUnit unit+integration 132 tests, 0 failures；Godot import exit 0 |

## Completion Audit — 2026-05-05

Claude 执行后，本文件曾声明 19/19 完成，但审计发现完成证据不足且存在运行时错误：旧 session state 仍标记 Phase 1-2 未完成，Epic 文档仍为未完成状态，`project.godot` 缺少 FTUE autoload，`left_nav.gd` 和 `toast_stack.gd` 会导致 Godot headless 校验失败，FTUE 状态机订阅了错误事件名，`exp_curve.json` 与设计数值不一致，旧 QA 脚本未适配 Sprint 12 渐进 UI 解锁。

本轮 Codex 修复后，Sprint 12 完成状态以 `production/qa/evidence/sprint-12-completion-audit-2026-05-05.md` 为准。该证据文件记录了修复清单、验证命令和剩余风险。

## Progress

| Metric | Count |
|--------|-------|
| Total stories | 19 |
| Must Have | 15 |
| Should Have | 4 |
| Done | 19 |
| Remaining | 0 |
| Completion | 100% |

### Done (19/19)

| # | Story | Type | Files Changed |
|---|-------|------|---------------|
| S12-001 | Zone 1 敌人+掉落 JSON | Config | `enemies.json` `loot_tables.json` |
| S12-002 | Zone 2 敌人+掉落 JSON | Config | `enemies.json` `loot_tables.json` |
| S12-003 | Zone 3 敌人+掉落 JSON | Config | `enemies.json` `loot_tables.json` |
| S12-004 | 经验曲线 JSON | Config | `exp_curve.json` |
| S12-005 | 区域解锁条件 JSON | Config | `zones.json` |
| S12-006 | 离线倍率 JSON | Config | `offline_params.json` |
| S12-007 | FTUE 状态机 | Logic | `ftue_state_machine.gd` `_host.gd` `project.godot` |
| S12-008 | Stage 0-1 修炼屏冷启动 | UI | `cultivation_screen.gd` |
| S12-009 | Stage 2-3: 战斗循环→区域理解 | UI | `toast_stack.gd` (ftue叙事toast) |
| S12-010 | Stage 4: 首次突破引导 | UI | `toast_stack.gd` (同上) |
| S12-011 | Stage 5: 首次离线回归 | UI | `toast_stack.gd` (同上) |
| S12-012 | HUD 渐进解锁 | Logic | `hud_system.gd` |
| S12-013 | LEFT NAV 状态机 | UI | `left_nav.gd` |
| S12-014 | 屏幕解锁序列 | Logic | `ui_manager_host.gd` |
| S12-015 | RIGHT PANEL 上下文切换 | UI | `right_panel.gd` |
| S12-016 | 凡人→炼气突破仪式 | Visual | `hud_system.gd` `cultivation_screen.gd` |
| S12-017 | 炼气→筑基突破仪式 | Visual | 同 S12-016（同一 ceremony 代码） |
| S12-018 | 离线结算三层递进 | UI | `toast_stack.gd` `offline_settlement_screen.gd` |
| S12-019 | 会话退出"期待锚点" | UI | `offline_settlement_screen.gd` |

### Files Changed (14 files)

| File | Stories |
|------|---------|
| `assets/data/enemies.json` | S12-001..003 |
| `assets/data/zones.json` | S12-005 |
| `assets/data/loot_tables.json` | S12-001..003 |
| `assets/data/exp_curve.json` | S12-004 |
| `assets/data/offline_params.json` | S12-006 |
| `src/systems/features/ftue_state_machine.gd` | S12-007 |
| `src/systems/features/ftue_state_machine_host.gd` | S12-007 |
| `project.godot` | S12-007 |
| `src/ui/screens/cultivation_screen.gd` | S12-008, S12-016 |
| `src/ui/toast/toast_stack.gd` | S12-009..011, S12-018 |
| `src/systems/presentation/hud_system.gd` | S12-012, S12-016 |
| `src/ui/shell/left_nav.gd` | S12-013 |
| `src/systems/presentation/ui_manager_host.gd` | S12-014 |
| `src/ui/shell/right_panel.gd` | S12-015 |
| `src/ui/screens/offline_settlement_screen.gd` | S12-018, S12-019 |
