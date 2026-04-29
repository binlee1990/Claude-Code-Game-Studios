# Sprint 1 — Foundation + Core MVP

**Start**: 2026-04-30
**End**: TBD（按故事完成签核）

## Sprint Goal

实现可运行的最小 SRPG 内核：棋盘从 CSV 加载并渲染、单位携带数据驱动属性放置于网格上、阵营轮转状态机驱动回合循环。全部 Logic Story 带通过的 GdUnit4 测试。

## Capacity

- 单人（solo developer）
- 估计 ~5 工作会话
- 缓冲 20%（预留调试和集成时间）

## Tasks

### Must Have（关键路径 — 依赖顺序）

| ID | Story | Epic | Type | Est. | Depends On |
|----|-------|------|------|------|------------|
| 1-1 | GridSpace — 坐标转换边界 | map | Logic | 2h | — |
| 1-2 | CSV 地图加载 + TileMapLayer | map | Logic | 3h | 1-1 |
| 1-3 | 网格拓扑 — 邻接 + 边界 | map | Logic | 2h | 1-2 |
| 1-4 | 占用追踪 — place/remove/move | map | Logic | 2h | 1-3 |
| 2-1 | UnitStats — 数据驱动 + .tres 校验 | unit | Logic | 2h | 1-1 |
| 2-3 | 公共接口 + action_state 状态机 | unit | Logic | 3h | 2-1, 1-4 |
| 2-4 | HP 系统 — 伤害/治疗/死亡链 | unit | Logic | 2h | 2-3 |
| 3-1 | TurnManager 初始化 + TurnConfig | turn | Logic | 2h | 2-3 |
| 3-2 | 状态机核心 — 4 状态 + 5 转换 | turn | Logic | 4h | 3-1 |
| 3-3 | Match End + VictoryChecker 集成 | turn | Logic | 3h | 3-2 |

### Should Have

| ID | Story | Epic | Type | Est. |
|----|-------|------|------|------|
| 2-2 | Unit Scene — 场景结构 + 视觉 | unit | Visual/Feel | 2h |
| 3-4 | Turn 信号发射 + AIController 接口 | turn | Logic | 2h |

### Nice to Have

- Feature 层 Stories（Movement/Attack/Victory/AI）— Sprint 2

## Risks

| Risk | Probability | Impact | Mitigation |
|------|------------|--------|------------|
| TileMapLayer API 与 Godot 4.6 版本不匹配 | 低 | 中 | engine-reference/godot/ 已缓存 4.6 文档 |
| BFS 被 Movement 依赖但 Movement 不在本次 Sprint | 无 | — | Map 拓扑层独立于 Movement BFS——仅需 get_neighbors/is_walkable |
| control-manifest.md 缺失导致实施无规则参考 | 低 | 低 | ADR 中的 Required/Forbidden 行替代 |

## Dependencies on External Factors

- 无外部依赖（单人项目，Godot 4.6.2 本地已安装）

## Definition of Done

- [ ] 所有 Must Have 任务完成
- [ ] 全部 Logic Story 有通过测试（`tests/unit/*/`）
- [ ] Story 2-2 有视觉证据（`production/qa/evidence/`）
- [ ] 代码审查通过
- [ ] Design documents 更新以反映任何偏离

> ⚠️ **No QA Plan**: 本 Sprint 在无 QA Plan 的情况下启动。在最后一个 Story 实施前运行 `/qa-plan sprint`。Production → Polish 门禁要求 QA 签核报告，该报告依赖 QA Plan。
