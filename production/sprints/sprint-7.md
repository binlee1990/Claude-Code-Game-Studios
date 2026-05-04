# Sprint 7 -- 2026-07-27 to 2026-08-09

## Sprint Goal
Deliver the planning and implementation slice from 物品/材料系统 through 调试控制台 while preserving upstream dependency order.

## AI Context Budget
- Stories: 20 total（≤ 20 — context window hard constraint）
- Parallelizable: 2 stories（无跨依赖，可 parallel subagent 执行）
- Verification Density: ≥ 1 automated or manual evidence item per story

## Tasks

### Must Have（Critical Path — 依赖顺序）
| ID | Story | Epic | Type | Depends On |
|----|-------|------|------|------------|
| S7-016-item-material-system | [H. 跨系统边界（1 条）](../epics/item-material-system/story-016-h-1.md) | 物品/材料系统 | Integration | Story 001 must be ready or done for shared test fixtures and baseline APIs |
| S7-017-item-material-system | [I. 内部一致性（1 条）](../epics/item-material-system/story-017-i-1.md) | 物品/材料系统 | Logic | Story 001 must be ready or done for shared test fixtures and baseline APIs |
| S7-001-output-multiplier-system | [Configuration and Initialization](../epics/output-multiplier-system/story-001-configuration-and-initialization.md) | 产出乘数系统 | UI | None |
| S7-002-output-multiplier-system | [Activation and Source Registration 1](../epics/output-multiplier-system/story-002-activation-and-source-registration-1.md) | 产出乘数系统 | UI | Story 001 must be ready or done for shared test fixtures and baseline APIs |
| S7-003-output-multiplier-system | [Activation and Source Registration 2](../epics/output-multiplier-system/story-003-activation-and-source-registration-2.md) | 产出乘数系统 | UI | Story 001 must be ready or done for shared test fixtures and baseline APIs |
| S7-004-output-multiplier-system | [Query and Formula Verification 1](../epics/output-multiplier-system/story-004-query-and-formula-verification-1.md) | 产出乘数系统 | UI | Story 001 must be ready or done for shared test fixtures and baseline APIs |
| S7-005-output-multiplier-system | [Query and Formula Verification 2](../epics/output-multiplier-system/story-005-query-and-formula-verification-2.md) | 产出乘数系统 | UI | Story 001 must be ready or done for shared test fixtures and baseline APIs |
| S7-006-output-multiplier-system | [Within-Pool Additivity and Cross-Pool Multiplicativity](../epics/output-multiplier-system/story-006-within-pool-additivity-and-cross-pool-multiplicativity.md) | 产出乘数系统 | UI | Story 001 must be ready or done for shared test fixtures and baseline APIs |
| S7-007-output-multiplier-system | [Deactivation and Lifecycle](../epics/output-multiplier-system/story-007-deactivation-and-lifecycle.md) | 产出乘数系统 | UI | Story 001 must be ready or done for shared test fixtures and baseline APIs |
| S7-008-output-multiplier-system | [Event Emission](../epics/output-multiplier-system/story-008-event-emission.md) | 产出乘数系统 | UI | Story 001 must be ready or done for shared test fixtures and baseline APIs |
| S7-009-output-multiplier-system | [Error Handling](../epics/output-multiplier-system/story-009-error-handling.md) | 产出乘数系统 | Logic | Story 001 must be ready or done for shared test fixtures and baseline APIs |
| S7-001-debug-console | [the node calls `queue_free()` and returns immediately, leaving zero re](../epics/debug-console/story-001-the-node-calls-queue-free-and-returns-immediately-leavin.md) | 调试控制台 | UI | None |

### Should Have
| ID | Story | Epic | Type | Depends On |
|----|-------|------|------|------------|
| S7-002-debug-console | [`CanvasLayer.visible` becomes `true`, `get_tree().paused` becomes `tru](../epics/debug-console/story-002-canvaslayer-visible-becomes-true-get-tree-paused-becomes.md) | 调试控制台 | UI | Story 001 must be ready or done for shared test fixtures and baseline APIs |
| S7-003-debug-console | [`LineEdit.release_focus()` is called instead of restoring the freed no](../epics/debug-console/story-003-lineedit-release-focus-is-called-instead-of-restoring-th.md) | 调试控制台 | UI | Story 001 must be ready or done for shared test fixtures and baseline APIs |
| S7-004-debug-console | [`EventBus.subscribe_pattern("resource", <callable>)` is called exactly](../epics/debug-console/story-004-eventbus-subscribe-pattern-resource-callable-is-called-e.md) | 调试控制台 | Integration | Story 001 must be ready or done for shared test fixtures and baseline APIs |
| S7-005-debug-console | [the second invocation outputs `\[WARN\] Already watching 'resource'. No-](../epics/debug-console/story-005-the-second-invocation-outputs-warn-already-watching-reso.md) | 调试控制台 | UI | Story 001 must be ready or done for shared test fixtures and baseline APIs |
| S7-006-debug-console | [each record in the `enemies` table is output as a single-line compact](../epics/debug-console/story-006-each-record-in-the-enemies-table-is-output-as-a-single-l.md) | 调试控制台 | Config/Data | Story 001 must be ready or done for shared test fixtures and baseline APIs |
| S7-007-debug-console | [the output lists all entity IDs registered in `AttributeSystem`](../epics/debug-console/story-007-the-output-lists-all-entity-ids-registered-in-attributes.md) | 调试控制台 | Logic | Story 001 must be ready or done for shared test fixtures and baseline APIs |

### Nice to Have
| ID | Story | Epic | Type | Depends On |
|----|-------|------|------|------------|
| S7-008-debug-console | [the output displays `real_time`, `game_time`, `effective_speed`, and `](../epics/debug-console/story-008-the-output-displays-real-time-game-time-effective-speed.md) | 调试控制台 | UI | Story 001 must be ready or done for shared test fixtures and baseline APIs |
| S7-009-debug-console | [`SaveManager.save_game()` is called and the output confirms the save w](../epics/debug-console/story-009-savemanager-save-game-is-called-and-the-output-confirms.md) | 调试控制台 | Config/Data | Story 001 must be ready or done for shared test fixtures and baseline APIs |

## Carryover from Previous Sprint
| Story | Reason |
|-------|--------|
| None | New generated sprint plan set 7/10. |

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
- [ ] QA plan exists (`production/qa/qa-plan-sprint-7.md`)
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
