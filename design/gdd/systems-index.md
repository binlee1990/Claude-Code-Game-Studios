# Systems Index: 修仙放置挂机刷宝 RPG

> **Status**: Draft
> **Created**: 2026-05-03
> **Last Updated**: 2026-05-03
> **Source Concept**: design/gdd/game-concept.md
> **TD-SYSTEM-BOUNDARY Review**: CONCERNS (accepted) 2026-05-03
> **PR-SCOPE Review**: REALISTIC 2026-05-03

---

## Overview

一款修仙题材的半放置刷宝队伍 RPG，MVP（最小挂机闭环）需要 29 个系统实现核心循环：修炼产出资源 → 自动战斗刷怪掉落 → 等级提升推进区域 → 离线结算收益。系统按 7 层依赖组织，从 Foundation（大数值、事件、时间、随机）到 Presentation（UI 框架、HUD），自底向上设计。

核心循环（§10.2）：修炼 → 资源增长 → 等级提升 → 简单自动战斗 → 掉落材料 → 强化角色 → 推进区域 → 离线结算

---

## Systems Enumeration

| # | System Name | Category | Priority | Status | Design Doc | Depends On |
|---|-------------|----------|----------|--------|------------|------------|
| 1 | 大数值系统 | Foundation | MVP | Designed | design/gdd/big-number-system.md | — |
| 2 | 随机数与种子系统 | Foundation | MVP | Designed | design/gdd/random-seed-system.md | — |
| 3 | 事件总线 | Foundation | MVP | Designed | design/gdd/event-bus.md | — |
| 4 | 时间管理器 | Foundation | MVP | Designed | design/gdd/time-manager.md | 事件总线 |
| 5 | 数值格式化系统 | Core Data | MVP | Not Started | — | 大数值系统 |
| 6 | 数据配置系统 | Core Data | MVP | Not Started | — | 大数值系统 |
| 7 | 公式引擎 | Core Data | MVP | Not Started | — | 大数值系统, 随机数与种子系统 |
| 8 | 修正器/倍率引擎 | Core Data | MVP | Not Started | — | 公式引擎, 大数值系统 |
| 9 | 存档系统 | Core Data | MVP | Not Started | — | 数据配置系统, 时间管理器 |
| 10 | 资源系统 | Core Gameplay | MVP | Not Started | — | 大数值系统, 事件总线, 公式引擎, 修正器/倍率引擎 |
| 11 | 属性系统 | Core Gameplay | MVP | Not Started | — | 大数值系统, 公式引擎, 修正器/倍率引擎 |
| 12 | 物品/材料系统 | Core Gameplay | MVP | Not Started | — | 数据配置系统, 大数值系统 |
| 13 | 产出乘数系统 | Core Gameplay | MVP | Not Started | — | 修正器/倍率引擎 |
| 14 | 调试控制台 | Core Gameplay | MVP | Not Started | — | 事件总线, 数据配置系统 |
| 15 | 等级系统 | Feature | MVP | Not Started | — | 属性系统, 公式引擎 |
| 16 | 存储上限系统 | Feature | MVP | Not Started | — | 物品/材料系统, 资源系统 |
| 17 | 自动产出系统 | Feature | MVP | Not Started | — | 资源系统, 时间管理器, 产出乘数系统 |
| 18 | 敌人数据库 | Feature | MVP | Not Started | — | 数据配置系统, 属性系统 |
| 19 | 掉落系统 (inferred) | Feature | MVP | Not Started | — | 敌人数据库, 物品/材料系统, 随机数与种子系统 |
| 20 | 修炼系统 | Feature Integration | MVP | Not Started | — | 资源系统, 自动产出系统, 时间管理器 |
| 21 | 战斗计算器 | Feature Integration | MVP | Not Started | — | 属性系统, 公式引擎, 随机数与种子系统, 修正器/倍率引擎 |
| 22 | 半自动战斗系统 | Feature Integration | MVP | Not Started | — | 战斗计算器, 敌人数据库, 掉落系统, 等级系统 |
| 23 | 区域系统 | Feature Integration | MVP | Not Started | — | 敌人数据库, 数据配置系统 |
| 24 | 地图推进系统 | Feature Integration | MVP | Not Started | — | 区域系统, 等级系统 |
| 25 | 离线模拟内核 | Simulation | MVP | Not Started | — | 时间管理器 |
| 26 | 挂机探索系统 | Simulation | MVP | Not Started | — | 半自动战斗系统, 区域系统 |
| 27 | 离线战斗模拟系统 | Simulation | MVP | Not Started | — | 离线模拟内核, 半自动战斗系统 |
| 28 | 离线收益结算系统 | Simulation | MVP | Not Started | — | 离线战斗模拟系统, 离线模拟内核 |
| 29 | UI 框架 | Presentation | MVP | Not Started | — | 事件总线 |
| 30 | HUD 系统 | Presentation | MVP | Not Started | — | UI 框架, 数值格式化系统, 资源系统, 区域系统 |

---

## Categories

| Category | Description | Systems |
|----------|-------------|---------|
| **Foundation** | Zero-dependency infrastructure used by everything | 大数值系统, 随机数与种子系统, 事件总线, 时间管理器 |
| **Core Data** | Data infrastructure — loading, formulas, formatting, persistence | 数值格式化系统, 数据配置系统, 公式引擎, 修正器/倍率引擎, 存档系统 |
| **Core Gameplay** | Primary gameplay systems — resources, attributes, items | 资源系统, 属性系统, 物品/材料系统, 产出乘数系统, 调试控制台 |
| **Feature** | Concrete features built on core gameplay | 等级系统, 存储上限系统, 自动产出系统, 敌人数据库, 掉落系统 |
| **Feature Integration** | Systems that orchestrate multiple features into player-facing loops | 修炼系统, 战斗计算器, 半自动战斗系统, 区域系统, 地图推进系统 |
| **Simulation** | Offline and batch simulation systems | 离线模拟内核, 挂机探索系统, 离线战斗模拟系统, 离线收益结算系统 |
| **Presentation** | UI and visual feedback | UI 框架, HUD 系统 |

---

## Priority Tiers

| Tier | Definition | Target Milestone | Design Urgency |
|------|------------|------------------|----------------|
| **MVP** | 最小挂机闭环 — 修炼、战斗、掉落、区域、离线、存档、大数值 | First playable | Design FIRST (all 30 systems) |

> Note: All 30 systems are MVP tier. Future tiers (Vertical Slice, Alpha, Full Vision) will be added after MVP is complete. See game-concept.md §12 for the full 9-phase roadmap.

---

## Dependency Map

### Foundation Layer (no dependencies)

1. **大数值系统** — All numeric operations across the game use this; without it no system can express values
2. **随机数与种子系统** — Reproducible randomness for combat, drops, and events
3. **事件总线** — Decoupled cross-system communication; prevents hard-coded dependencies
4. **时间管理器** — depends on: 事件总线 — Timestamp-based time tracking; foundation for offline income and auto-production

### Core Data Layer (depends on Foundation)

1. **数值格式化系统** — depends on: 大数值系统
2. **数据配置系统** — depends on: 大数值系统
3. **公式引擎** — depends on: 大数值系统, 随机数与种子系统
4. **修正器/倍率引擎** — depends on: 公式引擎, 大数值系统
5. **存档系统** — depends on: 数据配置系统, 时间管理器

### Core Gameplay Layer (depends on Foundation + Core Data)

1. **资源系统** — depends on: 大数值系统, 事件总线, 公式引擎, 修正器/倍率引擎
2. **属性系统** — depends on: 大数值系统, 公式引擎, 修正器/倍率引擎
3. **物品/材料系统** — depends on: 数据配置系统, 大数值系统
4. **产出乘数系统** — depends on: 修正器/倍率引擎
5. **调试控制台** — depends on: 事件总线, 数据配置系统

### Feature Layer (depends on Core Gameplay)

1. **等级系统** — depends on: 属性系统, 公式引擎
2. **存储上限系统** — depends on: 物品/材料系统, 资源系统
3. **自动产出系统** — depends on: 资源系统, 时间管理器, 产出乘数系统
4. **敌人数据库** — depends on: 数据配置系统, 属性系统
5. **掉落系统** — depends on: 敌人数据库, 物品/材料系统, 随机数与种子系统

### Feature Integration Layer (depends on Feature)

1. **修炼系统** — depends on: 资源系统, 自动产出系统, 时间管理器
2. **战斗计算器** — depends on: 属性系统, 公式引擎, 随机数与种子系统, 修正器/倍率引擎
3. **半自动战斗系统** — depends on: 战斗计算器, 敌人数据库, 掉落系统, 等级系统
4. **区域系统** — depends on: 敌人数据库, 数据配置系统
5. **地图推进系统** — depends on: 区域系统, 等级系统

### Simulation Layer (depends on Feature Integration)

1. **离线模拟内核** — depends on: 时间管理器
2. **挂机探索系统** — depends on: 半自动战斗系统, 区域系统
3. **离线战斗模拟系统** — depends on: 离线模拟内核, 半自动战斗系统
4. **离线收益结算系统** — depends on: 离线战斗模拟系统, 离线模拟内核

### Presentation Layer (depends on everything above)

1. **UI 框架** — depends on: 事件总线
2. **HUD 系统** — depends on: UI 框架, 数值格式化系统, 资源系统, 区域系统

---

## Recommended Design Order

| Order | System | Priority | Layer | Agent(s) | Effort |
|-------|--------|----------|-------|----------|--------|
| 1 | 大数值系统 | MVP | Foundation | godot-gdscript-specialist | L |
| 2 | 事件总线 | MVP | Foundation | godot-gdscript-specialist | S |
| 3 | 时间管理器 | MVP | Foundation | godot-gdscript-specialist | S |
| 4 | 随机数与种子系统 | MVP | Foundation | godot-gdscript-specialist | S |
| 5 | 公式引擎 | MVP | Core Data | godot-gdscript-specialist | M |
| 6 | 修正器/倍率引擎 | MVP | Core Data | godot-gdscript-specialist | M |
| 7 | 数据配置系统 | MVP | Core Data | godot-gdscript-specialist | M |
| 8 | 存档系统 | MVP | Core Data | godot-gdscript-specialist | M |
| 9 | 数值格式化系统 | MVP | Core Data | godot-gdscript-specialist | S |
| 10 | 资源系统 | MVP | Core Gameplay | godot-gdscript-specialist | M |
| 11 | 属性系统 | MVP | Core Gameplay | godot-gdscript-specialist | M |
| 12 | 物品/材料系统 | MVP | Core Gameplay | godot-gdscript-specialist | S |
| 13 | 产出乘数系统 | MVP | Core Gameplay | godot-gdscript-specialist | S |
| 14 | 调试控制台 | MVP | Core Gameplay | godot-specialist | S |
| 15 | 等级系统 | MVP | Feature | godot-gdscript-specialist | M |
| 16 | 敌人数据库 | MVP | Feature | godot-gdscript-specialist | S |
| 17 | 掉落系统 | MVP | Feature | godot-gdscript-specialist | M |
| 18 | 自动产出系统 | MVP | Feature | godot-gdscript-specialist | S |
| 19 | 存储上限系统 | MVP | Feature | godot-gdscript-specialist | S |
| 20 | 战斗计算器 | MVP | Feature Integration | godot-gdscript-specialist | M |
| 21 | 区域系统 | MVP | Feature Integration | godot-gdscript-specialist | S |
| 22 | 半自动战斗系统 | MVP | Feature Integration | godot-gdscript-specialist | L |
| 23 | 修炼系统 | MVP | Feature Integration | godot-gdscript-specialist | S |
| 24 | 地图推进系统 | MVP | Feature Integration | godot-gdscript-specialist | S |
| 25 | 离线模拟内核 | MVP | Simulation | godot-gdscript-specialist | M |
| 26 | 挂机探索系统 | MVP | Simulation | godot-gdscript-specialist | S |
| 27 | 离线战斗模拟系统 | MVP | Simulation | godot-gdscript-specialist | M |
| 28 | 离线收益结算系统 | MVP | Simulation | godot-gdscript-specialist | M |
| 29 | UI 框架 | MVP | Presentation | godot-specialist | M |
| 30 | HUD 系统 | MVP | Presentation | godot-specialist | M |

---

## Circular Dependencies

None detected. All dependency chains flow unidirectionally: Foundation → Core Data → Core Gameplay → Feature → Feature Integration → Simulation → Presentation.

---

## High-Risk Systems

| System | Risk Type | Risk Description | Mitigation |
|--------|-----------|-----------------|------------|
| 大数值系统 | Technical | 12+ dependents; must support 1e30+ in GDScript without precision loss. Wrong choice here cascades everywhere. | Prototype early with performance benchmarks. Consider GDScript class vs GDExtension (C++) for performance-critical paths. |
| 半自动战斗系统 | Integration | Depends on 4 systems; shared by online combat and offline simulation. Interface mismatch between online/offline paths is highest risk. | Define strict input/output contract in GDD: same CombatCalculator used by both paths. Offline sim calls combat calculator, not semi-auto system directly. |
| 离线模拟内核 | Technical | Timestamp-delta batch simulation must match real-time simulation exactly. Any drift means offline rewards are wrong. | Deterministic replay tests: run 1 hour real-time, compare to 1-hour delta simulation. Must produce identical results. |
| 公式引擎 | Design | All growth/damage/production formulas pass through here. Over-engineering creates unnecessary complexity; under-engineering blocks tuning. | Start with expression evaluator supporting variables and basic math. Add soft-cap functions as needed. Don't build a full DSL. |
| 修正器/倍率引擎 | Design | Additive/multiplicative/conditional stacking order determines game balance. Wrong order = broken economy. | GDD must define stacking order explicitly. Test with extreme modifier combinations early. |

---

## TD-SYSTEM-BOUNDARY Concerns (accepted 2026-05-03)

1. **资源系统 God Object 风险** — GDD 需明确只管"资源 ID → 数值"CRUD + 变更事件，不含产出逻辑和乘数计算
2. **离线模拟内核边界模糊** — GDD 需明确只提供"时间差 → 批次模拟"框架，具体业务由子系统钩子注入
3. **产出乘数系统与修正器/倍率引擎职责划分** — 修正器提供通用基础设施，产出乘数定义具体来源和叠乘顺序；如职责太薄可合并
4. **调试控制台 MVP 优先级** — 可降级为 Godot 内置方案，不自研
5. **半自动战斗系统关键集成点** — GDD 需严格定义输入/输出接口，确保离线/在线共享战斗逻辑

---

## Progress Tracker

| Metric | Count |
|--------|-------|
| Total systems identified | 30 |
| Design docs started | 4 |
| Design docs reviewed | 0 |
| Design docs approved | 0 |
| MVP systems designed | 4 / 30 |

---

## Next Steps

- [ ] Run CD-SYSTEMS review (review mode: full)
- [ ] Design MVP systems in order (use `/design-system [system-name]` or `/map-systems next`)
- [ ] Run `/design-review` on each completed GDD
- [ ] Run `/gate-check systems-design` when all MVP systems are designed
- [ ] Prototype highest-risk system early (`/prototype big-number-system`)
