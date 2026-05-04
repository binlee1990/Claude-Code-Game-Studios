# Sprint 8 -- 2026-08-10 to 2026-08-23

## Sprint Goal
Feature 起步：DebugConsole 命令收尾（help/error/Test Strategy）+ LevelSystem 完整经验/境界跨越/重建/性能/跨系统集成 + StorageLimit 双倍上限 + AutoProduction tick→ResourceSystem 投放。Sprint 出口意味着 Feature 层 5 系统中 LevelSystem/StorageLimit/AutoProduction 3 系统就绪，为 Sprint 9 战斗循环铺路。

## Layer / Milestone
- Layer: Feature
- Milestone: 无（Feature 层完成节点在 Sprint 9 出口）

## AI Context Budget
- Stories: 20 total（≤ 20 — context window hard constraint）
- Parallelizable: 3 stories（无跨依赖，可 parallel subagent 执行）
- Verification Density: ≥ 1 automated or manual evidence item per story

## Tasks

### Must Have（Critical Path — 依赖顺序）
| ID | Story | Epic | Type | Depends On |
|----|-------|------|------|------------|
| S8-010-debug-console | [the output displays exactly the `event` command's full help text: `eve](../epics/debug-console/story-010-the-output-displays-exactly-the-event-command-s-full-hel.md) | 调试控制台 | Logic | Story 001 must be ready or done for shared test fixtures and baseline APIs |
| S8-011-debug-console | [the output displays `\[ERROR\] Command handler unavailable: {command}` i](../epics/debug-console/story-011-the-output-displays-error-command-handler-unavailable-co.md) | 调试控制台 | Logic | Story 001 must be ready or done for shared test fixtures and baseline APIs |
| S8-012-debug-console | [the `LineEdit` content does not change and no error or exception is pr](../epics/debug-console/story-012-the-lineedit-content-does-not-change-and-no-error-or-exc.md) | 调试控制台 | UI | Story 001 must be ready or done for shared test fixtures and baseline APIs |
| S8-013-debug-console | [Test Strategy Notes 1](../epics/debug-console/story-013-test-strategy-notes-1.md) | 调试控制台 | Logic | Story 001 must be ready or done for shared test fixtures and baseline APIs |
| S8-014-debug-console | [Test Strategy Notes 2](../epics/debug-console/story-014-test-strategy-notes-2.md) | 调试控制台 | Integration | Story 001 must be ready or done for shared test fixtures and baseline APIs |
| S8-001-level-system | [实体生命周期](../epics/level-system/story-001-001-config-data.md) | 等级系统 | Integration | None |
| S8-002-level-system | [gain_exp 主路径 1](../epics/level-system/story-002-gain-exp-1.md) | 等级系统 | Integration | Story 001 must be ready or done for shared test fixtures and baseline APIs |
| S8-003-level-system | [gain_exp 主路径 2](../epics/level-system/story-003-gain-exp-2.md) | 等级系统 | Integration | Story 001 must be ready or done for shared test fixtures and baseline APIs |
| S8-004-level-system | [境界跨越 + modifier](../epics/level-system/story-004-modifier.md) | 等级系统 | Logic | Story 001 must be ready or done for shared test fixtures and baseline APIs |
| S8-005-level-system | [save.loaded 重建 1](../epics/level-system/story-005-save-loaded-1.md) | 等级系统 | Integration | Story 001 must be ready or done for shared test fixtures and baseline APIs |
| S8-006-level-system | [save.loaded 重建 2](../epics/level-system/story-006-save-loaded-2.md) | 等级系统 | Integration | Story 001 must be ready or done for shared test fixtures and baseline APIs |
| S8-007-level-system | [reset 接口](../epics/level-system/story-007-reset.md) | 等级系统 | Integration | Story 001 must be ready or done for shared test fixtures and baseline APIs |
| S8-001-storage-limit-system | [`ResourceSystem.get_max("lingqi") == 1000`](../epics/storage-limit-system/story-001-resourcesystem-get-max-lingqi-1000.md) | 存储上限系统 | Integration | None |
| S8-002-storage-limit-system | [capped resources receive doubled cap through ResourceSystem](../epics/storage-limit-system/story-002-capped-resources-receive-doubled-cap-through-resourcesys.md) | 存储上限系统 | Integration | Story 001 must be ready or done for shared test fixtures and baseline APIs |
| S8-001-auto-production-system | [ResourceSystem receives lingqi +1](../epics/auto-production-system/story-001-resourcesystem-receives-lingqi-1.md) | 自动产出系统 | Integration | None |

### Should Have
| ID | Story | Epic | Type | Depends On |
|----|-------|------|------|------------|
| S8-008-level-system | [公式求值 1](../epics/level-system/story-008-1.md) | 等级系统 | Logic | Story 001 must be ready or done for shared test fixtures and baseline APIs |
| S8-009-level-system | [公式求值 2](../epics/level-system/story-009-2.md) | 等级系统 | Logic | Story 001 must be ready or done for shared test fixtures and baseline APIs |
| S8-010-level-system | [公式异常 / 边界](../epics/level-system/story-010-010-integration.md) | 等级系统 | Integration | Story 001 must be ready or done for shared test fixtures and baseline APIs |
| S8-011-level-system | [跨系统集成](../epics/level-system/story-011-011-logic.md) | 等级系统 | Integration | Story 001 must be ready or done for shared test fixtures and baseline APIs |

### Nice to Have
| ID | Story | Epic | Type | Depends On |
|----|-------|------|------|------------|
| S8-012-level-system | [性能 / 内存](../epics/level-system/story-012-012-logic.md) | 等级系统 | Logic | Story 001 must be ready or done for shared test fixtures and baseline APIs |

## Carryover from Previous Sprint
| Story | Reason |
|-------|--------|
| None | New generated sprint plan set 8/10. |

## Risks
| Risk | Probability | Impact | Mitigation |
|------|-------------|--------|------------|
| AutoProduction tick 与 TimeManager 速度倍率耦合错误 | Medium | High | S8-001-auto-production 测试 ResourceSystem +1 投放路径；同时覆盖时间冻结/解冻情况。 |
| LevelSystem 境界跨越 modifier 注册顺序错误 | Medium | High | S8-004 测试境界跨越 + modifier 注册原子性。 |
| Cross-epic dependency drift | Medium | Medium | Work stories in listed order and run `/story-readiness` for each story before `/dev-story`. |

## Dependencies on External Factors
- Godot 4.6.2 behavior must be checked against `docs/engine-reference/godot/` where ADRs require verification.
- QA plan is in place: `production/qa/qa-plan-sprint-8-2026-05-04.md`.

## Definition of Done for this Sprint
- [ ] All Must Have tasks completed
- [ ] All tasks pass acceptance criteria
- [ ] QA plan exists (`production/qa/qa-plan-sprint-8-2026-05-04.md`) ✅
- [ ] All Logic/Integration stories have passing unit/integration tests
- [ ] Smoke check passed (`/smoke-check sprint`)
- [ ] QA sign-off report: APPROVED or APPROVED WITH CONDITIONS (`/team-qa sprint`)
- [ ] No S1 or S2 bugs in delivered features
- [ ] Design documents updated for any deviations
- [ ] Code reviewed and merged
- [ ] **Traceability**: 所有 sprint stories 映射回 `debug-console.md` / `level-system.md` / `storage-limit-system.md` / `auto-production-system.md` 的 GDD acceptance criteria（覆盖率 100%）

## 2026-05-04 执行记录
- 本轮按 sprint 顺序执行到 Sprint 8 后，QA gate PASS。
- 证据：`production/qa/evidence/sprint-8-qa-result-2026-05-04.md`。
- 最新 GdUnit：`reports/report_8/results.xml`（137 个测试，0 个失败，0 个跳过，0 个 flaky）。

## Next Steps
- `/story-readiness [story-file]` for the first Must Have story
- `/dev-story [story-file]` after readiness passes
- `/sprint-status` during active execution
- `/scope-check [epic]` before implementing work outside the listed stories
