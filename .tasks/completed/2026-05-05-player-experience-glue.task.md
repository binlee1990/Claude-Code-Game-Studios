# Task: MVP Player Experience Glue — 从系统集合到可玩游戏

**Task ID**: 2026-05-05-player-experience-glue
**Created**: 2026-05-05
**Type**: Strategy/Design — Multi-document authoring
**Complexity**: L3 (6 design docs, 3 priority tiers, cross-referencing + implementation-boundary validation required)

Role:

Game Design Director — 将 30 个已实现的 MVP 系统粘合成一个有连贯体验的可玩游戏，同时为 225 系统终局蓝图保持架构正确性。

Context:

- 30 个系统全部实现完毕（Sprint 1–11），系统间逻辑接口通过 ADR 和 EventBus 定义清晰
- 6 个 UX Spec 已起草（HUD + 5 屏），视觉设计规范已完成
- 核心循环在 game-concept.md §7 有高层描述，但未展开为具体时刻-by-时刻体验
- game-concept.md §12 定义了 9 阶段路线图，当前处于阶段 1（最小挂机闭环）
- **核心问题**: 系统能跑，但玩家"从打开游戏到沉迷"的路径不存在——缺连贯性、节奏和渐进展开

Objective:

创建 6 份设计文档，填充"系统集合"与"可玩游戏"之间的空白，确保 MVP 具备完整的玩家体验闭环。

Success criteria:

- [x] 每份文档至少经过一轮 self-review（内部一致性检查）
- [x] 所有文档交叉引用现有 GDD 和 UX Spec（不重复已有内容）
- [x] Player Journey Map 覆盖 0min–首次回归 完整路径
- [x] Screen Flow 覆盖所有 6 屏的导航关系和解锁条件
- [x] Content Progression Sheet 包含 3 个 MVP 区域的完整数值配置
- [x] 所有文档为中文，可直接交给 story 拆解

Decomposition:

### Phase A — 独立并行（无相互依赖）

| # | Document | Path | Agent | Description |
|---|----------|------|-------|-------------|
| A1 | Narrative/World Skeleton | `design/narrative/world-skeleton.md` | narrative-director | 修仙世界观最简框架：境界命名体系、3区域主题、开局文本、核心术语表 |
| A2 | Content Progression Sheet | `design/balance/mvp-content-progression.md` | systems-designer | 3个MVP区域的数值曲线、敌人属性、掉落表、战力门槛、解锁条件 |

### Phase B — 依赖 Phase A 完成（需 A 的上下文但可并行彼此）

| # | Document | Path | Agent | Description |
|---|----------|------|-------|-------------|
| B1 | Player Journey Map | `design/experience/player-journey-map.md` | game-designer | 0min→30min→1h→首日→首周 的完整体验路径，含情感曲线 |
| B2 | Screen Flow & Unlock Sequence | `design/experience/screen-flow.md` | ux-designer | 6屏导航拓扑、解锁触发条件、渐进UI节奏、返回逻辑 |

### Phase C — 依赖 Phase B 完成

| # | Document | Path | Agent | Description |
|---|----------|------|-------|-------------|
| C1 | Onboarding Flow Spec | `design/experience/onboarding-flow.md` | ux-designer | 首次进入游戏的教学节奏、信息密度控制、系统解锁顺序 |
| C2 | Session Loop Design | `design/experience/session-loop.md` | game-designer | 典型 play session 的决策闭环：回来看到什么→做什么→得到什么 |

Methodology:

- **SCQA**: 定义每个文档需要回答的核心问题
- **MECE**: 6 份文档互不重叠、协同覆盖完整体验层
- **Cross-reference**: 每份文档显式引用现有 GDD TR-ID 和 ADR 编号

Output:

6 份 Markdown 设计文档，写入 `design/` 对应子目录，格式遵循 GDD 8-section 标准（适用部分）。

Constraints:

- 不修改现有 30 个 GDD
- 不修改现有 ADR
- 不修改任何 src/ 代码
- 所有数值必须可在现有公式引擎中表达
- MVP 范围：3 区域、单角色、无宗门/宠物/秘境
- 为 225 系统终局蓝图保留扩展点（标注"Phase 2+"）

Non-assumptions:

- 不假设玩家有放置游戏经验——P0 体验必须对新手友好
- 不假设 UI 动画已实现——描述行为而非视觉效果
- 不假设中文以外语言——术语全用中文

Verification:

- 每份文档 self-review：检查内部逻辑一致性
- 交叉验证：所有 6 份文档之间的引用一致性
- GDD 对齐：抽样检查是否与至少 3 个相关 GDD 一致
- 用户审阅：最终由用户确认所有文档

## Dialectical Challenge Synthesis

### Thesis

按最初方案直接补完 6 份体验层设计文档：世界观、数值、玩家旅程、屏幕流、新手引导、会话循环。

### Antithesis

直接补完会把体验愿景写得过满，掩盖 MVP 实现边界：

- `LevelSystem` 当前阈值为 `fanren@1 / lianqi@10 / zhuji@30 / jindan@60 / yuanying@100`，所以 Lv.1-30 的 Sprint 12 内容只实际覆盖凡人、炼气、筑基；金丹/元婴只能作为近端命名预留。
- `LootSystem` 与 `ItemRegistry` 的 MVP 入口只稳定承诺 `exp / lingshi / herb` 等资源材料，不应把装备实例、稀有装备、碎片合成写成 MVP 必达。
- `SemiAutoCombatSystem` MVP 只承诺普攻自动与区域选择，不应在体验文档中展示战法配置空占位。
- 世界观区域名与数值区域名必须单一事实源，否则 screen-flow/onboarding/player-journey 会互相打架。

### Synthesis

修订 6 份文档时采用以下执行准则：

1. 区域展示名统一为 `青丘山林 / 幽墟灵谷 / 荒殒战场`，保留 `zone_starter / zone_forest / zone_mine` 作为系统 id。
2. Lv.1-30 MVP 内容以 `凡人 -> 炼气 -> 筑基` 为可实现闭环；`金丹 / 元婴` 保留为世界观命名和 Phase 2+ 牵引。
3. 掉落与经济文案只把 `exp / lingshi / herb` 写成 MVP 必达；装备、稀有材料、合成、图鉴作为 Phase 2+ 或 long-tail 预告，不进入 MVP 验收。
4. 新手引导与会话循环不展示空战法 UI；战法作为未来系统在扩展表中保留。

---

## Execution Log

| Phase | Status | Started | Completed |
|-------|--------|---------|-----------|
| Phase A | reviewed | 2026-05-05 | 2026-05-05 |
| Phase B | reviewed | 2026-05-05 | 2026-05-05 |
| Phase C | reviewed | 2026-05-05 | 2026-05-05 |
| Consistency Pass | completed | 2026-05-05 | 2026-05-05 |

## Execution Gate

**Verdict**: PROCEED
**Basis**: 目标文件、环境、可接受副作用、验证信号均明确；仅修改 6 份新设计文档与本任务文件，不修改 GDD、ADR 或 src。

## Completion Verdict

**Verdict**: COMPLETE
**Evidence**: 6 份文档完成边界收紧；旧区域名、待定项、Sprint 12 外装备/碎片/战法 UI、金丹/元婴误写为 MVP 终点等关键矛盾已通过一致性检索清除。
