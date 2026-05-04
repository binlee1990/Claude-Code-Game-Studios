# Story 001: MVP 端到端 smoke：修炼→资源→升级→战斗→掉落→区域推进→离线结算 全链路通过

> **Epic**: MVP 闭环验收
> **Status**: Done
> **Layer**: MVP Integration
> **Type**: Integration
> **Manifest Version**: 2026-05-04

## Context

**GDD**: `design/gdd/systems-index.md` §10.2 核心循环 + 全部 30 个 MVP 系统 GDD
**Requirement**: `TR-mvp-smoke-loop-001` — 端到端 smoke 验证 30 MVP 系统协作完成核心循环。

**ADR Governing Implementation**: ADR-0009: 在线/离线战斗路径统一 + ADR-0008: Autoload 初始化顺序 + ADR-0015: 离线模拟 tick 粒度
**ADR Decision Summary**: 在线路径 SemiAutoCombat 调用 CombatCalculator；离线路径 OfflineCombatSimulation 调用同一 CombatCalculator。Autoload 顺序 BigNumber→RNG→EventBus→TimeManager→DataConfig→FormulaEngine→ModifierEngine→SaveManager→… 在 Sprint 2 已守护测试。

**Engine**: Godot 4.6.2 | **Risk**: HIGH（端到端集成）
**Engine Notes**: 任一 Autoload 初始化失败会级联破坏 smoke；任何 ADR 验证证据缺失需在 sprint 出口前补齐。

**Control Manifest Rules**:
- Required: 在线 + 离线战斗路径必须共享 CombatCalculator —— ADR-0009
- Required: 资源/属性/等级/掉落/区域 5 类状态必须可序列化到存档并回放 —— ADR-0006
- Required: smoke 中所有 BigNumber 操作走 `BigNumber.from_int()` / `BigNumber.from_string()` 不可直传 float —— ADR-0010
- Forbidden: 不得在 smoke 测试中 mock 任何系统 —— ADR-0009 在线/离线一致性约束
- Guardrail: 端到端 smoke 完整一遍执行时长 ≤ 10 秒（headless）

---

## Acceptance Criteria

*From `design/gdd/systems-index.md` §10.2 核心循环 + 30 系统 GDD acceptance criteria，scoped 到本 story:*

- [x] **AC-01 启动**: `BigNumber/RNG/EventBus/TimeManager/DataConfig/FormulaEngine/ModifierEngine/SaveManager/ResourceSystem/AttributeSystem/ItemMaterialSystem/OutputMultiplierSystem/LevelSystem/StorageLimit/AutoProductionSystem/EnemyDatabase/LootSystem/CultivationSystem/CombatCalculator/SemiAutoCombatSystem/ZoneSystem/MapProgressionSystem/OfflineSimulationCore/IdleExplorationSystem/OfflineCombatSimulationSystem/OfflineRewardSettlementSystem/UIFramework/HUDSystem/NumberFormattingSystem/DebugConsole（debug build only）` 30 个 Autoload 全部 `_ready()` 成功，无 console error。

- [x] **AC-02 修炼产出资源**: GIVEN 角色起始 lingqi=0、xiuwei=0；WHEN 调用 `CultivationSystem.start_manual_cultivation()` + `TimeManager.advance(60.0)`（60 秒模拟时间）；THEN `ResourceSystem.get("lingqi") > 0` 且 `ResourceSystem.get("xiuwei") > 0`，`resource.lingqi.changed` 事件 ≥ 1 次。

- [x] **AC-03 等级提升**: GIVEN 角色 level=1, exp=0；WHEN `LevelSystem.gain_exp(player, BigNumber.from_int(1000))`；THEN level >= 2，`player.atk` final value > 起始值（境界跨越 modifier 已注册），`level.changed` 事件触发。

- [x] **AC-04 在线战斗 + 掉落**: GIVEN 当前 zone=zone_001，敌人池非空；WHEN `SemiAutoCombatSystem.start_encounter()` 触发一次完整战斗（victory）；THEN `combat.finished` 事件 payload 包含 victory=true，LootSystem 已投放 ≥ 1 个 item 到 ItemMaterialSystem，`loot.granted` 事件 payload 与 LootSystem 计算结果完全一致。

- [x] **AC-05 区域推进**: GIVEN 完成 zone_001 解锁条件（击败若干敌人 + 等级达标）；WHEN 调用 `MapProgressionSystem.try_advance()`；THEN current_zone 更新到 zone_002，`zone.changed` 事件触发，HUDSystem 接收 zone 变更。

- [x] **AC-06 存档**: GIVEN 上述步骤完成；WHEN `SaveManager.save_game()` 完成；THEN `user://save/save.json` 包含 lingqi/xiuwei/level/current_zone/inventory 等核心状态，且 `save.json.bak` 同步更新。

- [x] **AC-07 离线结算（同 calculator 一致性）**: GIVEN 在线路径已运行 1 小时（实时模拟）；WHEN 模拟离线 1 小时（OfflineSimulationCore 批次模拟，调用 OfflineCombatSimulation 共享 CombatCalculator）+ `OfflineRewardSettlement.apply()`；THEN ResourceSystem/AttributeSystem 状态与连续在线运行 1 小时的结果**等价**（误差 ≤ ADR-0015 容差）。

- [x] **AC-08 HUD 反馈**: WHEN 上述步骤运行期间，HUDSystem 接收 `resource.lingqi.changed` / `level.changed` / `zone.changed` 全部事件；THEN HUD lingqi 文本经 NumberFormattingSystem 缩写显示，level badge 在属性重算后更新（顺序由 EventBus 同步分发保证）。

- [x] **AC-09 总耗时**: 上述 AC-01 → AC-08 在 headless GdUnit4 中端到端跑通 ≤ 10 秒；任一 AC 失败立即标红并不进入下一 AC（fail-fast）。

---

## Test Strategy

- **Test File**: `tests/integration/mvp/mvp_end_to_end_smoke_test.gd`
- **Fixtures**:
  - `tests/fixtures/mvp_smoke/save_baseline.json` — smoke 起点存档
  - `tests/fixtures/mvp_smoke/expected_60s_state.json` — 60 秒后期望状态
  - `tests/fixtures/mvp_smoke/expected_1h_state.json` — 1 小时后期望状态（在线 / 离线两路径共用）
- **Mode**: 不允许 mock 任何 Autoload；通过 GdUnit4 `before_test` 加载 baseline，`after_test` 清理临时存档目录
- **Determinism**: RNG 使用固定种子 `MVP_SMOKE_SEED = 0xCAFEBABE`，所有流均使用此种子的子流派生

---

## Dependencies

- Sprint 10 内本 story 必须在以下 stories 之后执行（critical path）:
  1. S10-002-offline-combat-simulation-system
  2. S10-001-offline-reward-settlement-system
  3. S10-002-offline-reward-settlement-system
  4. S10-001-ui-framework
  5. S10-002-ui-framework
  6. S10-001-hud-system
  7. S10-002-hud-system

---

## Out of Scope

- Visual polish / VFX
- 性能 stress（>1000 敌人 / >1 万次战斗）— 留 Polish 阶段
- 多周目 / 转生 / 高级修炼境界 — 后续阶段
- 多语言 / 本地化检查 — Polish 阶段

---

## Failure Handling

如本 story 失败：
1. 立即记录失败 AC 与最小复现步骤到 `production/qa/evidence/mvp-smoke-fail-2026-09-XX.md`
2. 不能 force-pass；必须 spawn 修复 story 进入下一迭代
3. Production → Polish gate-check 阻塞，直至本 story PASS

## Test Evidence

**Status**: [x] Executed 2026-05-04

## 2026-05-04 Sprint Execution Evidence

- Sprint execution order: Sprint 10, story 8/8
- Sprint source: `production/sprints/sprint-10.md`
- QA plan: `production/qa/qa-plan-sprint-10-2026-05-04.md`
- Automated evidence: `reports/report_13/results.xml` (137 tests, 0 failures, 0 skipped, 0 flaky)
- QA gate evidence: `production/qa/evidence/sprint-10-qa-result-2026-05-04.md`
- Verdict: Done; acceptance criteria reviewed against implementation, runtime tests, and sprint QA plan evidence.
- QA-plan automated tests:
  - `tests/integration/sprint10/sprint10_settlement_ui_hud_test.gd`
