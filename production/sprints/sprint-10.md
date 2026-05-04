# Sprint 10 -- 2026-09-07 to 2026-09-20

## Sprint Goal
MVP 闭环：OfflineCombatSimulation 收尾 + OfflineRewardSettlement 全量结算 + UIFramework 屏幕管理 + HUD 系统 + **MVP 端到端 smoke 验收（修炼 → 资源 → 升级 → 战斗 → 掉落 → 推进区域 → 离线结算 全链路）**。Sprint 出口标志 **MVP 完成 milestone — 30 系统全部联调通过、最小挂机闭环可玩**。

## Layer / Milestone
- Layer: Simulation / Presentation / MVP Integration
- Milestone: 🎯 **MVP 完成**（end of Sprint 10）— 全部 30 系统就绪，可进入 Production → Polish gate

## AI Context Budget
- Stories: 8 total（≤ 20 — context window hard constraint）
- Parallelizable: 3 stories（offline-reward-settlement / ui-framework / hud-system 在 mvp-smoke 之前可并行）
- Verification Density: ≥ 1 automated or manual evidence item per story

## Tasks

### Must Have（Critical Path — 依赖顺序）
| ID | Story | Epic | Type | Depends On |
|----|-------|------|------|------------|
| S10-002-offline-combat-simulation-system | [mode switches to expected and records degradation](../epics/offline-combat-simulation-system/story-002-mode-switches-to-expected-and-records-degradation.md) | 离线战斗模拟系统 | Integration | Story 001 must be ready or done for shared test fixtures and baseline APIs |
| S10-001-offline-reward-settlement-system | [ResourceSystem receives 100 lingqi](../epics/offline-reward-settlement-system/story-001-resourcesystem-receives-100-lingqi.md) | 离线收益结算系统 | Integration | None |
| S10-002-offline-reward-settlement-system | [warning appears and other rewards still apply](../epics/offline-reward-settlement-system/story-002-warning-appears-and-other-rewards-still-apply.md) | 离线收益结算系统 | Integration | Story 001 must be ready or done for shared test fixtures and baseline APIs |
| S10-001-ui-framework | [the scene is loaded and becomes active](../epics/ui-framework/story-001-the-scene-is-loaded-and-becomes-active.md) | UI 框架 | UI | None |
| S10-002-ui-framework | [layout rebuild is coalesced](../epics/ui-framework/story-002-layout-rebuild-is-coalesced.md) | UI 框架 | UI | Story 001 must be ready or done for shared test fixtures and baseline APIs |
| S10-001-hud-system | [lingqi text updates using NumberFormattingSystem](../epics/hud-system/story-001-lingqi-text-updates-using-numberformattingsystem.md) | HUD 系统 | UI | None |
| S10-002-hud-system | [level badge updates after attributes are already recalculated](../epics/hud-system/story-002-level-badge-updates-after-attributes-are-already-recalcu.md) | HUD 系统 | UI | Story 001 must be ready or done for shared test fixtures and baseline APIs |
| S10-001-mvp-smoke-loop | [MVP 端到端 smoke：修炼→资源→升级→战斗→掉落→区域推进→离线结算 全链路通过](../epics/mvp-smoke-loop/story-001-mvp-end-to-end-smoke.md) | MVP 闭环验收 | Integration | 上述 7 stories 必须先 done |

### Should Have
| ID | Story | Epic | Type | Depends On |
|----|-------|------|------|------------|

### Nice to Have
| ID | Story | Epic | Type | Depends On |
|----|-------|------|------|------------|

## Carryover from Previous Sprint
| Story | Reason |
|-------|--------|
| None | New generated sprint plan set 10/10. |

## Risks
| Risk | Probability | Impact | Mitigation |
|------|-------------|--------|------------|
| MVP smoke 暴露跨 sprint 集成问题 | High | High | smoke story 是 sprint 内最后一条；任何前置 story 失败即推迟 smoke 至下个迭代。 |
| UIFramework 屏幕管理与 Godot 4.6 lifecycle 冲突 | Medium | High | ADR-0011 + S10-001-ui-framework spike；HUD 订阅复用 EventBus（已 sprint 2 验证）。 |
| 离线结算 reward 投放与 ResourceSystem 上限竞态 | Medium | Medium | S10-002 warning 路径覆盖溢出；StorageLimit (Sprint 8) 已就绪。 |
| Cross-epic dependency drift | Medium | Medium | Work stories in listed order and run `/story-readiness` for each story before `/dev-story`. |

## Dependencies on External Factors
- Godot 4.6.2 behavior must be checked against `docs/engine-reference/godot/` where ADRs require verification.
- QA plan is in place: `production/qa/qa-plan-sprint-10-2026-05-04.md`.

## Definition of Done for this Sprint
- [ ] All Must Have tasks completed
- [ ] All tasks pass acceptance criteria
- [ ] QA plan exists (`production/qa/qa-plan-sprint-10-2026-05-04.md`) ✅
- [ ] All Logic/Integration stories have passing unit/integration tests
- [ ] Smoke check passed (`/smoke-check sprint`)
- [ ] QA sign-off report: APPROVED or APPROVED WITH CONDITIONS (`/team-qa sprint`)
- [ ] No S1 or S2 bugs in delivered features
- [ ] Design documents updated for any deviations
- [ ] Code reviewed and merged
- [ ] **Traceability**: 所有 sprint stories 映射回 `offline-combat-simulation-system.md` / `offline-reward-settlement-system.md` / `ui-framework.md` / `hud-system.md` 的 GDD acceptance criteria（覆盖率 100%）
- [ ] **MVP 完成 milestone 检查清单**:
  - [ ] 30 / 30 MVP 系统全部 done
  - [ ] MVP smoke story (S10-001-mvp-smoke-loop) PASS
  - [ ] systems-index.md 标注 "MVP First Playable Achieved" 时间戳
  - [ ] 进入 Production → Polish gate 准备就绪

## Next Steps
- `/story-readiness [story-file]` for the first Must Have story
- `/dev-story [story-file]` after readiness passes
- `/sprint-status` during active execution
- `/scope-check [epic]` before implementing work outside the listed stories
- 出口后：`/gate-check production-to-polish`
