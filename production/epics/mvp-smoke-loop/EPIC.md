# Epic: MVP 闭环验收（mvp-smoke-loop）

> **Status**: Ready
> **Layer**: MVP Integration（跨层 sprint-10 收尾验收）
> **Stage**: Pre-Production → Sprint 10
> **Owner**: lead-programmer + qa-lead 联合
> **Created**: 2026-05-04
> **Manifest Version**: 2026-05-04

---

## Why this epic exists

systems-index.md 定义了 MVP 30 系统与核心循环：**修炼 → 资源增长 → 等级提升 → 简单自动战斗 → 掉落材料 → 强化角色 → 推进区域 → 离线结算**。

Sprint 1–10 把每个系统单独验证完毕，但**没有任何 sprint 把 30 系统串成端到端循环**。本 epic 仅含 1 条 Integration story，作为 Sprint 10 出口的 MVP first-playable gate。

This epic does NOT add new systems — it only verifies the already-built systems function as a coherent loop.

---

## Scope

| In Scope | Out of Scope |
|----------|--------------|
| 端到端 smoke 测试覆盖核心循环 8 节点 | 任何新 GDD/ADR/系统设计 |
| 跨系统 fixture（CombatCalculator + LootSystem + ResourceSystem + LevelSystem + ZoneSystem + OfflineSimulationCore）| 性能 stress 测试（留 Polish 阶段） |
| 在线 + 离线两条路径同 fixture 验证（ADR-0009）| Visual polish / VFX |
| 1 条 Integration story | 多 story 拆分（后续若 smoke 不通过，再 spawn 修复 story） |

---

## Governing GDDs / ADRs

- 涉及 GDD: 全部 30 个 MVP 系统 GDD（验收点引用而非新增）
- 关键 ADR:
  - ADR-0008: Autoload 初始化顺序
  - ADR-0009: 在线/离线战斗路径统一
  - ADR-0010: ResourceSystem 不可变 BigNumber 策略
  - ADR-0015: 离线模拟 tick 粒度
- 关键 systems-index 条目: §10.2 核心循环

---

## Stories

| Story | Type | Sprint |
|-------|------|--------|
| [story-001-mvp-end-to-end-smoke](story-001-mvp-end-to-end-smoke.md) | Integration | Sprint 10 |

---

## Definition of Done

- [ ] story-001 PASS（端到端 smoke 8 节点全通）
- [ ] 在线路径 + 离线路径同 fixture 一致性证明记录到 `production/qa/evidence/`
- [ ] systems-index.md 标记 "MVP First Playable Achieved 2026-09-20"
- [ ] Production → Polish gate-check 解锁
