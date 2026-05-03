# Architecture Traceability Index

Last Updated: 2026-05-04
Engine: Godot 4.6.2
Mode: Technical Setup architecture coverage

## Coverage Summary

- Total MVP systems traced: 30
- Covered by ADRs: 30 (100%)
- Partial: 0
- Gaps: 0
- Foundation layer gaps: 0
- Core layer gaps: 0

This index maps each approved MVP GDD system to the ADRs that govern its implementation. It is intentionally system-level for Technical Setup. Story/test linkage should be expanded later with `/architecture-review rtm` once epics, stories, and test files exist.

## Full Matrix

| Requirement ID | GDD | System | Layer | ADR Coverage | Status |
|----------------|-----|--------|-------|--------------|--------|
| TR-big-number-001 | `design/gdd/big-number-system.md` | 大数值系统 | Foundation | ADR-0001 | Covered |
| TR-rng-001 | `design/gdd/random-seed-system.md` | 随机数与种子系统 | Foundation | ADR-0004 | Covered |
| TR-event-bus-001 | `design/gdd/event-bus.md` | 事件总线 | Foundation | ADR-0002, ADR-0008 | Covered |
| TR-time-manager-001 | `design/gdd/time-manager.md` | 时间管理器 | Foundation | ADR-0002, ADR-0003, ADR-0006, ADR-0015 | Covered |
| TR-number-formatting-001 | `design/gdd/number-formatting-system.md` | 数值格式化系统 | Core Data / Presentation support | ADR-0001, ADR-0014 | Covered |
| TR-data-config-001 | `design/gdd/data-config-system.md` | 数据配置系统 | Core Data | ADR-0005, ADR-0008 | Covered |
| TR-formula-engine-001 | `design/gdd/formula-engine.md` | 公式引擎 | Core Data | ADR-0001, ADR-0005, ADR-0013 | Covered |
| TR-modifier-engine-001 | `design/gdd/modifier-engine.md` | 修正器/倍率引擎 | Core Data | ADR-0001, ADR-0002, ADR-0007 | Covered |
| TR-save-system-001 | `design/gdd/save-system.md` | 存档系统 | Core Data | ADR-0002, ADR-0003, ADR-0006, ADR-0008 | Covered |
| TR-resource-system-001 | `design/gdd/resource-system.md` | 资源系统 | Core Gameplay | ADR-0001, ADR-0002, ADR-0005, ADR-0006, ADR-0010 | Covered |
| TR-attribute-system-001 | `design/gdd/attribute-system.md` | 属性系统 | Core Gameplay | ADR-0001, ADR-0002, ADR-0007 | Covered |
| TR-item-material-001 | `design/gdd/item-material-system.md` | 物品/材料系统 | Core Gameplay | ADR-0005, ADR-0008 | Covered |
| TR-output-multiplier-001 | `design/gdd/output-multiplier-system.md` | 产出乘数系统 | Core Gameplay | ADR-0001, ADR-0002, ADR-0005, ADR-0007 | Covered |
| TR-debug-console-001 | `design/gdd/debug-console.md` | 调试控制台 | Presentation / DevTools | ADR-0002, ADR-0003, ADR-0005, ADR-0006, ADR-0007, ADR-0010, ADR-0011, ADR-0012, ADR-0014 | Covered |
| TR-level-system-001 | `design/gdd/level-system.md` | 等级系统 | Feature | ADR-0001, ADR-0002, ADR-0005, ADR-0007, ADR-0013 | Covered |
| TR-storage-limit-001 | `design/gdd/storage-limit-system.md` | 存储上限系统 | Feature | ADR-0001, ADR-0010 | Covered |
| TR-auto-production-001 | `design/gdd/auto-production-system.md` | 自动产出系统 | Feature | ADR-0003, ADR-0007, ADR-0010 | Covered |
| TR-enemy-database-001 | `design/gdd/enemy-database.md` | 敌人数据库 | Feature | ADR-0005, ADR-0013 | Covered |
| TR-loot-system-001 | `design/gdd/loot-system.md` | 掉落系统 | Feature | ADR-0004, ADR-0005, ADR-0009 | Covered |
| TR-cultivation-system-001 | `design/gdd/cultivation-system.md` | 修炼系统 | Feature Integration | ADR-0003, ADR-0007, ADR-0010 | Covered |
| TR-combat-calculator-001 | `design/gdd/combat-calculator.md` | 战斗计算器 | Feature Integration | ADR-0001, ADR-0004, ADR-0007, ADR-0009, ADR-0013 | Covered |
| TR-semi-auto-combat-001 | `design/gdd/semi-auto-combat-system.md` | 半自动战斗系统 | Feature Integration | ADR-0002, ADR-0004, ADR-0009 | Covered |
| TR-zone-system-001 | `design/gdd/zone-system.md` | 区域系统 | Feature Integration | ADR-0005, ADR-0009 | Covered |
| TR-map-progression-001 | `design/gdd/map-progression-system.md` | 地图推进系统 | Feature Integration | ADR-0002, ADR-0005, ADR-0009 | Covered |
| TR-offline-sim-core-001 | `design/gdd/offline-simulation-core.md` | 离线模拟内核 | Simulation | ADR-0003, ADR-0004, ADR-0015 | Covered |
| TR-idle-exploration-001 | `design/gdd/idle-exploration-system.md` | 挂机探索系统 | Simulation | ADR-0002, ADR-0009, ADR-0015 | Covered |
| TR-offline-combat-001 | `design/gdd/offline-combat-simulation-system.md` | 离线战斗模拟系统 | Simulation | ADR-0004, ADR-0009, ADR-0015 | Covered |
| TR-offline-settlement-001 | `design/gdd/offline-reward-settlement-system.md` | 离线收益结算系统 | Simulation | ADR-0002, ADR-0010, ADR-0015 | Covered |
| TR-ui-framework-001 | `design/gdd/ui-framework.md` | UI 框架 | Presentation | ADR-0002, ADR-0011, ADR-0014 | Covered |
| TR-hud-system-001 | `design/gdd/hud-system.md` | HUD 系统 | Presentation | ADR-0002, ADR-0011, ADR-0014 | Covered |

## Known Gaps

No Foundation or Core architecture gaps remain after ADR-0001 through ADR-0015.

Remaining work is implementation evidence rather than architecture coverage:

- BigNumber and RNG performance thresholds require prototype profiling.
- Godot 4.6 UI dual-focus behavior requires UI prototype/manual evidence.
- SaveManager restore ordering and FileAccess write return handling require tests.
- Offline simulation equivalence requires deterministic replay tests.

## Superseded Requirements

None.

