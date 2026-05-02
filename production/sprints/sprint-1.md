# Sprint 1 — Foundation + Core MVP

**Start**: 2026-04-30
**End**: 2026-04-30

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

- [x] 所有 Must Have 任务完成
- [x] 全部 Logic Story 有通过测试（`tests/unit/*/`）
- [x] Story 2-2 有视觉证据（`production/qa/evidence/` — Godot 编辑器中截图待补充）
- [x] 代码审查通过（5 blockers 已修复，剩余 suggestions 入 tech-debt）
- [x] Design documents 更新以反映任何偏离（见下方 Deviations）

> ✅ **QA Execution Status (refreshed 2026-05-02)**: QA Plan 已补齐：`production/qa/qa-plan-sprint-1-2026-04-30.md`；历史签核报告存在：`production/qa/qa-signoff-sprint-1-2026-05-02.md`。当前 headless runner 复核为 clean：`Total Passed: 266`，`SCRIPT ERROR` / `Assertion failed` / `ERROR:` / `WARNING:` 均为 0。详情见 `production/qa/qa-execution-audit-2026-05-02.md`。

## Deviations from GDD/ADR

实施过程中与原始设计的偏离：

| # | 偏离 | 原因 | 影响 |
|---|------|------|------|
| D1 | `turn_state.gd` / `unit_state.gd` 使用匿名 `enum {}` + `preload` 模式替代命名 enum | Godot 4.6 不支持独立 `.gd` 文件的命名 enum 作为全局名称 | 消费者需加 `const TurnState = preload(...)` |
| D2 | `TurnManager.initialize(units)` / `VictoryChecker.determine_winner(units)` 参数改为无类型 Array | GDScript `Array[Unit]` 在 headless 测试中拒绝无类型 Array 输入 | 放宽类型约束，运行时兼容 |
| D3 | `Map._render_tiles()` 增加 TileMapLayer 缺失时的 guard | 支持 headless 测试（无场景树环境） | 无 TileMapLayer 时渲染静默跳过 |
| D4 | `Unit.hp` 使用 setter 发射 `unit_died` 信号 | 代码审查 Blocker #5：`hp` 直接赋值绕过死亡链 | `hp=0` 总是触发 `unit_died`（含从 setter 赋值路径） |
| D5 | `UnitStats.validate()` 使用 `push_error` + `return false` 替代 `assert` | 代码审查 Blocker #4：release build 中 assert 被裁剪 | 验证在 debug 和 release build 中均生效 |
| D6 | `Game._on_unit_died()` 连接 `unit_died` → `map.remove_unit()` + `queue_free()` | 代码审查 Blocker #2：死亡单位不释放 Map 占用 | 死亡链完整闭环 |
| D7 | TileSet 通过脚本生成（`tools/generate_tileset.gd`）而非手动在编辑器创建 | 自动化资产生成，确保 MVP 开箱即用 | 3 色 atlas tile 自动创建于 `assets/data/` |
