# Sprint 2 — Feature Layer MVP

**Start**: 2026-05-01
**End**: 2026-05-02

## Sprint Goal

实现全部 4 个 Feature 层系统：Movement BFS 可达范围+路径、Attack 伤害公式+射程检查、Victory 全灭+回合上限判定、AI @abstract 接口+NullAI。所有 Logic Story 带通过的 GdUnit4 测试。

## Capacity

- 单人（solo developer）
- 估计 ~5 工作会话
- 缓冲 20%（预留调试和集成时间）

## Tasks

### Must Have（关键路径 — 依赖顺序）

| ID | Story | Epic | Type | Est. | Depends On |
|----|-------|------|------|------|------------|
| 4-1 | BFS 可达范围 + Manhattan 距离 | movement | Logic | 2h | 1-3, 1-4 |
| 4-2 | MovementResult + 路径重建 | movement | Logic | 2h | 4-1 |
| 4-3 | 移动执行 + Map 集成 | movement | Integration | 2h | 4-2 |
| 5-1 | 伤害公式 + AttackResult | attack | Logic | 1.5h | 2-1 |
| 5-2 | 射程检查 + AttackRangeResolver | attack | Logic | 1.5h | 5-1, 4-1 |
| 5-3 | AttackResolver 执行 + 无反击 + 集成 | attack | Integration | 2h | 5-2, 2-4 |
| 6-1 | VictoryChecker — 全灭判定 | victory | Logic | 1.5h | — |
| 6-2 | 回合上限 + 存活数判定 | victory | Logic | 1.5h | 6-1 |
| 7-1 | @abstract AIController + NullAI | ai | Logic | 1.5h | 2-3 |
| 7-2 | WorldState + ActionPlan 数据结构 | ai | Logic | 1.5h | 7-1 |

### Should Have

| ID | Story | Epic | Type | Est. |
|----|-------|------|------|------|
| 4-4 | 移动范围 UI 高亮 | movement | UI | 1h |

### Nice to Have

- BasicAI Tier 2（MVP 仅 NullAI——玩家手动操控敌方回合的热座模式）
- 攻击高亮 + 伤害预览 UI
- Sprint 1 的 Stacked 测试注入到回合系统

## Risks

| Risk | Probability | Impact | Mitigation |
|------|------------|--------|------------|
| BFS 性能在大型地图上超出帧预算 | 低 | 中 | BFS 跑在纯数组上，非逐帧；Sprint 3 如需可换 A* |
| Movement + Attack 同时引入导致集成复杂度攀高 | 中 | 中 | 严格按依赖顺序实施（Movement→Attack→Victory→AI）；每个 Epic 完成后做集成冒烟测试 |
| AI 接口与 Turn System 的契约不明确 → 信号连接不匹配 | 低 | 中 | ADR-0008 已定义 take_turn(units, world_state)→ActionList 契约 |
| Sprint 2 QA Plan 执行不完整 | 中 | 中 | 已解决：runner clean，Sprint 2 sign-off 已生成 |

## Dependencies on External Factors

- 无外部依赖（单人项目，Godot 4.6.2 本地已安装）

## Definition of Done

- [x] 所有 Must Have 任务完成
- [x] 全部 Logic Story 有干净通过测试（`tests/unit/movement/`, `tests/unit/attack/`, `tests/unit/victory/`, `tests/unit/ai/`）
- [x] 集成 Story（4-3, 5-3）有干净通过的集成测试或文档化 playtest
- [x] 代码审查通过（current QA risk-resolution diff reviewed against sprint scope）
- [x] Design documents 更新以反映任何偏离
- [x] Sprint 1 QA Plan 签核报告完成

> ✅ **QA Plan Execution (refreshed 2026-05-02)**: `production/qa/qa-plan-sprint-2-2026-05-02.md` 已执行，Sprint 2 QA sign-off 已生成：`production/qa/qa-signoff-sprint-2-2026-05-02.md`。当前 headless runner 复核为 clean：`Total Passed: 251`，`SCRIPT ERROR` / `Assertion failed` / `ERROR:` / `WARNING:` 均为 0。Sprint 2 当前状态为 **complete / QA signed off**。详情见 `production/qa/qa-execution-audit-2026-05-02.md`。
