# Sprint 9 -- 2026-08-24 to 2026-09-06

## Sprint Goal
Feature/Integration 完成 + Simulation 起步：完整在线战斗循环（Enemy → Loot → Combat → SemiAutoCombat → Zone → MapProgression → Cultivation）+ 离线模拟内核基线（OfflineSimulationCore + IdleExploration + OfflineCombatSimulation 起点）。Sprint 出口标志 **Feature 层 + Feature Integration 层完成**，且 Simulation 层 4 系统中 3 个就绪。

## Layer / Milestone
- Layer: Feature / Feature Integration / Simulation
- Milestone: ✅ **Feature + Feature Integration Layer 完成**（end of Sprint 9）；Simulation 层 75% 就绪

## AI Context Budget
- Stories: 20 total（≤ 20 — context window hard constraint）
- Parallelizable: 多 epic 并行（auto-production / enemy-database / combat-calculator / offline-sim-core 起点无 sprint 内依赖）
- Verification Density: ≥ 1 automated or manual evidence item per story

## Tasks

### Must Have（Critical Path — 在线战斗 + 修炼循环，按依赖严格排序）
| ID | Story | Epic | Type | Depends On |
|----|-------|------|------|------------|
| S9-002-auto-production-system | [exp is never requested from OMS](../epics/auto-production-system/story-002-exp-is-never-requested-from-oms.md) | 自动产出系统 | Integration | Story 001 must be ready or done for shared test fixtures and baseline APIs |
| S9-001-enemy-database | [`get_count() == 3`](../epics/enemy-database/story-001-get-count-3.md) | 敌人数据库 | Config/Data | None |
| S9-002-enemy-database | [only enemies tagged starter are returned](../epics/enemy-database/story-002-only-enemies-tagged-starter-are-returned.md) | 敌人数据库 | Integration | Story 001 must be ready or done for shared test fixtures and baseline APIs |
| S9-001-loot-system | [bundle includes exp](../epics/loot-system/story-001-bundle-includes-exp.md) | 掉落系统 | Integration | Sprint 内 enemy-database S9-001/002 |
| S9-002-loot-system | [output is capped deterministically to 5 entries](../epics/loot-system/story-002-output-is-capped-deterministically-to-5-entries.md) | 掉落系统 | Logic | Sprint 内 enemy-database S9-001/002 |
| S9-001-combat-calculator | [CombatResult is identical](../epics/combat-calculator/story-001-combatresult-is-identical.md) | 战斗计算器 | Integration | None |
| S9-002-combat-calculator | [all attacks use crit_dmg multiplier](../epics/combat-calculator/story-002-all-attacks-use-crit-dmg-multiplier.md) | 战斗计算器 | Logic | Story 001 must be ready or done for shared test fixtures and baseline APIs |
| S9-001-zone-system | [all are queryable by id and sorted by order](../epics/zone-system/story-001-all-are-queryable-by-id-and-sorted-by-order.md) | 区域系统 | Integration | Sprint 内 enemy-database S9-001 |
| S9-002-zone-system | [current zone does not change and lock reason is returned](../epics/zone-system/story-002-current-zone-does-not-change-and-lock-reason-is-returned.md) | 区域系统 | Logic | Story 001 must be ready or done for shared test fixtures and baseline APIs |
| S9-001-cultivation-system | [lingqi increases by `manual_lingqi_gain`](../epics/cultivation-system/story-001-lingqi-increases-by-manual-lingqi-gain.md) | 修炼系统 | Integration | Sprint 内 auto-production S9-002 |
| S9-002-cultivation-system | [no resource changes occur](../epics/cultivation-system/story-002-no-resource-changes-occur.md) | 修炼系统 | Integration | Story 001 must be ready or done for shared test fixtures and baseline APIs |
| S9-001-semi-auto-combat-system | [loot is rolled and combat finished event includes victory](../epics/semi-auto-combat-system/story-001-loot-is-rolled-and-combat-finished-event-includes-victor.md) | 半自动战斗系统 | Integration | Sprint 内 combat-calculator + enemy-database + loot-system 全部就绪 |
| S9-002-semi-auto-combat-system | [no crash and HUD can show a zone data error](../epics/semi-auto-combat-system/story-002-no-crash-and-hud-can-show-a-zone-data-error.md) | 半自动战斗系统 | Integration | Story 001 must be ready or done for shared test fixtures and baseline APIs |
| S9-001-map-progression-system | [next zone becomes unlocked](../epics/map-progression-system/story-001-next-zone-becomes-unlocked.md) | 地图推进系统 | Integration | Sprint 内 zone-system S9-001/002 |

### Should Have（Simulation 层基线）
| ID | Story | Epic | Type | Depends On |
|----|-------|------|------|------------|
| S9-002-map-progression-system | [selection fails with lock reason](../epics/map-progression-system/story-002-selection-fails-with-lock-reason.md) | 地图推进系统 | Integration | Story 001 must be ready or done for shared test fixtures and baseline APIs |
| S9-001-offline-simulation-core | [it contains 4 chunks](../epics/offline-simulation-core/story-001-it-contains-4-chunks.md) | 离线模拟内核 | Logic | None |
| S9-002-offline-simulation-core | [no settlement draft is emitted](../epics/offline-simulation-core/story-002-no-settlement-draft-is-emitted.md) | 离线模拟内核 | Integration | Story 001 must be ready or done for shared test fixtures and baseline APIs |
| S9-001-idle-exploration-system | [recommended target is available](../epics/idle-exploration-system/story-001-recommended-target-is-available.md) | 挂机探索系统 | Integration | Sprint 内 semi-auto-combat + zone-system 全部就绪 |

### Nice to Have
| ID | Story | Epic | Type | Depends On |
|----|-------|------|------|------------|
| S9-002-idle-exploration-system | [exploration stores session summary for HUD](../epics/idle-exploration-system/story-002-exploration-stores-session-summary-for-hud.md) | 挂机探索系统 | Integration | Story 001 must be ready or done for shared test fixtures and baseline APIs |
| S9-001-offline-combat-simulation-system | [encounter count is 360](../epics/offline-combat-simulation-system/story-001-encounter-count-is-360.md) | 离线战斗模拟系统 | Integration | Sprint 内 offline-simulation-core + semi-auto-combat 全部就绪 |

## Carryover from Previous Sprint
| Story | Reason |
|-------|--------|
| None | New generated sprint plan set 9/10. |

## Risks
| Risk | Probability | Impact | Mitigation |
|------|-------------|--------|------------|
| Sprint 9 11 个 epic 集成风险 | High | High | Must Have 严格按依赖顺序排列；任何 epic 失败立即触发 `/scope-check` 并把下游 stories 推到 Sprint 10。 |
| Combat 在线/离线路径分歧 | High | High | ADR-0009 强制 SemiAutoCombat 调用 CombatCalculator，离线 sim 也必须调用同一 calculator；S9-002 半自动 + S9-001 离线战斗模拟 共享 fixture。 |
| OfflineSimulationCore tick 粒度与实时不匹配 | Medium | High | ADR-0015 限定 tick 粒度；deterministic replay 测试覆盖 1h 实时 vs 1h 批次模拟。 |
| Cross-epic dependency drift | Medium | Medium | Work stories in listed order and run `/story-readiness` for each story before `/dev-story`. |

## Dependencies on External Factors
- Godot 4.6.2 behavior must be checked against `docs/engine-reference/godot/` where ADRs require verification.
- QA plan is in place: `production/qa/qa-plan-sprint-9-2026-05-04.md`.

## Definition of Done for this Sprint
- [ ] All Must Have tasks completed
- [ ] All tasks pass acceptance criteria
- [ ] QA plan exists (`production/qa/qa-plan-sprint-9-2026-05-04.md`) ✅
- [ ] All Logic/Integration stories have passing unit/integration tests
- [ ] Smoke check passed (`/smoke-check sprint`)
- [ ] QA sign-off report: APPROVED or APPROVED WITH CONDITIONS (`/team-qa sprint`)
- [ ] No S1 or S2 bugs in delivered features
- [ ] Design documents updated for any deviations
- [ ] Code reviewed and merged
- [ ] **Traceability**: 所有 sprint stories 映射回 `auto-production-system.md` / `enemy-database.md` / `loot-system.md` / `cultivation-system.md` / `combat-calculator.md` / `semi-auto-combat-system.md` / `zone-system.md` / `map-progression-system.md` / `offline-simulation-core.md` / `idle-exploration-system.md` / `offline-combat-simulation-system.md` 的 GDD acceptance criteria（覆盖率 100%）
- [ ] **Feature + Feature Integration Layer milestone**: ADR-0009 在线/离线战斗路径统一 evidence + ADR-0015 离线 tick 粒度 evidence 已记录到 `production/qa/evidence/`

## 2026-05-04 执行记录
- 本轮按 sprint 顺序执行到 Sprint 9 后，QA gate PASS。
- 证据：`production/qa/evidence/sprint-9-qa-result-2026-05-04.md`。
- 最新 GdUnit：`reports/report_8/results.xml`（137 个测试，0 个失败，0 个跳过，0 个 flaky）。

## Next Steps
- `/story-readiness [story-file]` for the first Must Have story
- `/dev-story [story-file]` after readiness passes
- `/sprint-status` during active execution — Sprint 9 风险高，每完成 3 stories 跑一次 `/sprint-status`
- `/scope-check [epic]` before implementing work outside the listed stories
