# Sprint Plan Index

> **Generated**: 2026-05-04
> **Last Updated**: 2026-05-05（UI 缺口补丁 — 新增 Sprint 11 UI Scene Layer）
> **Planning Rule**: Each sprint has at most 20 stories for AI execution context safety.
> **Total MVP Stories**: 187 + 1 (mvp-smoke-loop) + 16 (sprint-11 UI scene layer) = 204
> **MVP First Playable Status**: ❌ 未达成（Sprint 10 完成的是 Logic Layer Complete；UI 场景层在 Sprint 11）

| Sprint | Story Count | Layer | Milestone | First Epic | Last Epic | File |
|--------|-------------|-------|-----------|------------|-----------|------|
| Sprint 1 | 20 | Foundation | — | 大数值系统 | 随机数与种子系统 | [sprint-1.md](sprint-1.md) |
| Sprint 2 | 20 | Foundation | ✅ **Foundation Layer 完成** | 随机数与种子系统 | 时间管理器 | [sprint-2.md](sprint-2.md) |
| Sprint 3 | 20 | Core Data | — | 时间管理器 | 公式引擎 | [sprint-3.md](sprint-3.md) |
| Sprint 4 | 20 | Core Data | ✅ **Core Data Layer 完成** | 公式引擎 | 存档系统 | [sprint-4.md](sprint-4.md) |
| Sprint 5 | 20 | Core Gameplay | — | 资源系统 | 属性系统 | [sprint-5.md](sprint-5.md) |
| Sprint 6 | 20 | Core Gameplay | — | 属性系统 | 物品/材料系统 | [sprint-6.md](sprint-6.md) |
| Sprint 7 | 20 | Core Gameplay | ✅ **Core Gameplay Layer 完成** | 物品/材料系统 | 调试控制台 | [sprint-7.md](sprint-7.md) |
| Sprint 8 | 20 | Feature | — | 调试控制台 | 自动产出系统 | [sprint-8.md](sprint-8.md) |
| Sprint 9 | 20 | Feature / Integration / Simulation | ✅ **Feature + Feature Integration 完成** | 自动产出系统 | 离线战斗模拟系统 | [sprint-9.md](sprint-9.md) |
| Sprint 10 | 8 | Simulation / Presentation / MVP Integration | ✅ **MVP Logic Layer Complete**（First Playable 实际未达成 — 见 sprint-10 2026-05-05 修订） | 离线战斗模拟系统 | MVP 闭环验收 | [sprint-10.md](sprint-10.md) |
| Sprint 11 | 16 | UI Scene Layer | 🎯 **MVP First Playable** | ui-scene-foundation | mvp-screens | [sprint-11.md](sprint-11.md) |

## Layer 进度对照

| Layer | 系统数 | 完成 sprint | 完成时间（计划） |
|-------|--------|-------------|------------------|
| Foundation | 4 | Sprint 2 | 2026-05-31 |
| Core Data | 5 | Sprint 4 | 2026-06-28 |
| Core Gameplay | 5 | Sprint 7 | 2026-08-09 |
| Feature | 5 | Sprint 8（部分）+ Sprint 9 | 2026-09-06 |
| Feature Integration | 5 | Sprint 9 | 2026-09-06 |
| Simulation | 4 | Sprint 9–10 | 2026-09-20 |
| Presentation | 2 | Sprint 10 | 2026-09-20 |

## Sprint 间依赖摘要

- Sprint 2 出口需 Foundation 4 Autoload 启动顺序守护测试通过
- Sprint 4 出口需 ADR-0006 atomic write + ADR-0007 叠加顺序 evidence 落档
- Sprint 7 出口需 ADR-0012 Release 排除 + OMS×ModifierEngine 职责切分 evidence 落档
- Sprint 9 出口需 ADR-0009 在线/离线统一 + ADR-0015 tick 粒度 evidence 落档
- **Sprint 10 出口需 mvp-smoke-loop story PASS**（30 系统端到端闭环 — 已 PASS 但仅 headless 验证，非 First Playable）
- **Sprint 11 出口需 mvp-first-playable-smoke story PASS**（玩家从启动 Godot 到完成 game-concept §10.2 8 步循环全程 UI 可达）

## QA Plan 状态

每个 sprint 对应一份 QA plan：`production/qa/qa-plan-sprint-N-2026-05-04.md`，10/10 已存在。

## 2026-05-04 执行记录

- Sprint 1 → Sprint 10 已按 Tasks 表顺序真实执行并关闭 188 个 sprint story，10/10 sprint QA gate PASS。
- 最新 GdUnit 证据：`reports/report_13/results.xml`（137 个测试，0 个失败，0 个跳过，0 个 flaky）。
- Story 执行总账：`production/qa/evidence/sprint-story-execution-2026-05-04.json`。
- 每个 sprint 的验收记录已写入：`production/qa/evidence/sprint-N-qa-result-2026-05-04.md`。
- 资源产出与校验记录：`production/qa/evidence/asset-production-2026-05-04.md`、`production/qa/evidence/asset-validation-report.json`。

## 审计记录

- **2026-05-04 dialectical audit**: 完成 11 项缺陷 D1–D11 修复 — 删过时 QA 警告、重写 sprint goal、修正 ~50 处 story type 误标、Sprint 9 critical path 重排、Sprint 10 加 MVP smoke story 与 mvp-smoke-loop epic、加 milestone 标记、加 traceability DoD。
- **2026-05-05 UI 缺口审计**: 用户 reframe-and-execute 流程暴露 "MVP First Playable Achieved" 是误判 — Sprint 1–10 完成的是 30 系统**逻辑层**（含 UIManager / HUDSystem 的 RefCounted 服务），但**没有任何 .tscn 场景**（main.tscn 空 Node 根 / src/ui 不存在 / open_screen 从未 instantiate）。修复：systems-index.md 与 sprint-10.md 措辞修正；新增临时 HUD 骨架（src/ui/hud/*）证明服务可驱动 UI；新立 Sprint 11 (16 stories, 6 新 epic) 专门补 UI 场景层达成真正 First Playable。
