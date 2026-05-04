# Sprint 10 -- 2026-09-07 to 2026-09-20

## Sprint Goal
Deliver the planning and implementation slice from 离线战斗模拟系统 through HUD 系统 while preserving upstream dependency order.

## AI Context Budget
- Stories: 7 total（≤ 20 — context window hard constraint）
- Parallelizable: 3 stories（无跨依赖，可 parallel subagent 执行）
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
| Missing sprint QA plan | Medium | High | Run `/qa-plan sprint` before implementing the final story in this sprint. |
| Godot 4.6.2 post-cutoff API behavior | Medium | High | Verify against `docs/engine-reference/godot/` when a governing ADR marks HIGH or MEDIUM risk. |
| Cross-epic dependency drift | Medium | Medium | Work stories in listed order and run `/story-readiness` for each story before `/dev-story`. |

## Dependencies on External Factors
- Godot 4.6.2 behavior must be checked against `docs/engine-reference/godot/` where ADRs require verification.
- QA plan is not present yet; sprint closure remains gated on `/qa-plan sprint`.

## Definition of Done for this Sprint
- [ ] All Must Have tasks completed
- [ ] All tasks pass acceptance criteria
- [ ] QA plan exists (`production/qa/qa-plan-sprint-10.md`)
- [ ] All Logic/Integration stories have passing unit/integration tests
- [ ] Smoke check passed (`/smoke-check sprint`)
- [ ] QA sign-off report: APPROVED or APPROVED WITH CONDITIONS (`/team-qa sprint`)
- [ ] No S1 or S2 bugs in delivered features
- [ ] Design documents updated for any deviations
- [ ] Code reviewed and merged

> WARNING: No QA Plan was found for this generated sprint. Run `/qa-plan sprint` before the last story is implemented. The Production -> Polish gate requires a QA sign-off report, which requires a QA plan.

## Next Steps
- `/story-readiness [story-file]` for the first Must Have story
- `/dev-story [story-file]` after readiness passes
- `/sprint-status` during active execution
- `/scope-check [epic]` before implementing work outside the listed stories
