# Sprint 7 -- 2026-07-27 to 2026-08-09

## Sprint Goal
Core Gameplay 完成：物品/材料 跨系统边界 + 内部一致性收尾；OutputMultiplierSystem 完整产出率/激活注册/池叠加/事件/错误处理；DebugConsole 主路径（释放构建排除/快捷键/事件订阅/打印命令）。Sprint 出口标志 Core Gameplay Layer milestone — 数值/属性/物品/产出/调试 5 大子系统全部就绪。

## Layer / Milestone
- Layer: Core Gameplay
- Milestone: ✅ **Core Gameplay Layer 完成**（end of Sprint 7）

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
| S7-001-output-multiplier-system | [Configuration and Initialization](../epics/output-multiplier-system/story-001-configuration-and-initialization.md) | 产出乘数系统 | Integration | None |
| S7-002-output-multiplier-system | [Activation and Source Registration 1](../epics/output-multiplier-system/story-002-activation-and-source-registration-1.md) | 产出乘数系统 | Integration | Story 001 must be ready or done for shared test fixtures and baseline APIs |
| S7-003-output-multiplier-system | [Activation and Source Registration 2](../epics/output-multiplier-system/story-003-activation-and-source-registration-2.md) | 产出乘数系统 | Integration | Story 001 must be ready or done for shared test fixtures and baseline APIs |
| S7-004-output-multiplier-system | [Query and Formula Verification 1](../epics/output-multiplier-system/story-004-query-and-formula-verification-1.md) | 产出乘数系统 | Logic | Story 001 must be ready or done for shared test fixtures and baseline APIs |
| S7-005-output-multiplier-system | [Query and Formula Verification 2](../epics/output-multiplier-system/story-005-query-and-formula-verification-2.md) | 产出乘数系统 | Logic | Story 001 must be ready or done for shared test fixtures and baseline APIs |
| S7-006-output-multiplier-system | [Within-Pool Additivity and Cross-Pool Multiplicativity](../epics/output-multiplier-system/story-006-within-pool-additivity-and-cross-pool-multiplicativity.md) | 产出乘数系统 | Logic | Story 001 must be ready or done for shared test fixtures and baseline APIs |
| S7-007-output-multiplier-system | [Deactivation and Lifecycle](../epics/output-multiplier-system/story-007-deactivation-and-lifecycle.md) | 产出乘数系统 | Integration | Story 001 must be ready or done for shared test fixtures and baseline APIs |
| S7-008-output-multiplier-system | [Event Emission](../epics/output-multiplier-system/story-008-event-emission.md) | 产出乘数系统 | Integration | Story 001 must be ready or done for shared test fixtures and baseline APIs |
| S7-009-output-multiplier-system | [Error Handling](../epics/output-multiplier-system/story-009-error-handling.md) | 产出乘数系统 | Logic | Story 001 must be ready or done for shared test fixtures and baseline APIs |
| S7-001-debug-console | [the node calls `queue_free()` and returns immediately, leaving zero re](../epics/debug-console/story-001-the-node-calls-queue-free-and-returns-immediately-leavin.md) | 调试控制台 | Integration | None |

### Should Have
| ID | Story | Epic | Type | Depends On |
|----|-------|------|------|------------|
| S7-002-debug-console | [`CanvasLayer.visible` becomes `true`, `get_tree().paused` becomes `tru](../epics/debug-console/story-002-canvaslayer-visible-becomes-true-get-tree-paused-becomes.md) | 调试控制台 | UI | Story 001 must be ready or done for shared test fixtures and baseline APIs |
| S7-003-debug-console | [`LineEdit.release_focus()` is called instead of restoring the freed no](../epics/debug-console/story-003-lineedit-release-focus-is-called-instead-of-restoring-th.md) | 调试控制台 | UI | Story 001 must be ready or done for shared test fixtures and baseline APIs |
| S7-004-debug-console | [`EventBus.subscribe_pattern("resource", <callable>)` is called exactly](../epics/debug-console/story-004-eventbus-subscribe-pattern-resource-callable-is-called-e.md) | 调试控制台 | Integration | Story 001 must be ready or done for shared test fixtures and baseline APIs |
| S7-005-debug-console | [the second invocation outputs `\[WARN\] Already watching 'resource'. No-](../epics/debug-console/story-005-the-second-invocation-outputs-warn-already-watching-reso.md) | 调试控制台 | Logic | Story 001 must be ready or done for shared test fixtures and baseline APIs |
| S7-006-debug-console | [each record in the `enemies` table is output as a single-line compact](../epics/debug-console/story-006-each-record-in-the-enemies-table-is-output-as-a-single-l.md) | 调试控制台 | Logic | Story 001 must be ready or done for shared test fixtures and baseline APIs |
| S7-007-debug-console | [the output lists all entity IDs registered in `AttributeSystem`](../epics/debug-console/story-007-the-output-lists-all-entity-ids-registered-in-attributes.md) | 调试控制台 | Integration | Story 001 must be ready or done for shared test fixtures and baseline APIs |

### Nice to Have
| ID | Story | Epic | Type | Depends On |
|----|-------|------|------|------------|
| S7-008-debug-console | [the output displays `real_time`, `game_time`, `effective_speed`, and `](../epics/debug-console/story-008-the-output-displays-real-time-game-time-effective-speed.md) | 调试控制台 | Integration | Story 001 must be ready or done for shared test fixtures and baseline APIs |
| S7-009-debug-console | [`SaveManager.save_game()` is called and the output confirms the save w](../epics/debug-console/story-009-savemanager-save-game-is-called-and-the-output-confirms.md) | 调试控制台 | Integration | Story 001 must be ready or done for shared test fixtures and baseline APIs |

## Carryover from Previous Sprint
| Story | Reason |
|-------|--------|
| None | New generated sprint plan set 7/10. |

## Risks
| Risk | Probability | Impact | Mitigation |
|------|-------------|--------|------------|
| OutputMultiplierSystem 与 ModifierEngine 职责重复 | Medium | High | TD-SYSTEM-BOUNDARY 已约束：ModifierEngine 提供基础设施，OMS 定义具体来源/池叠乘；S7-006 验证池间乘性。 |
| DebugConsole Release 构建未排除导致体积/泄漏 | Medium | High | ADR-0012 + S7-001 queue_free 测试 + 内存断言。 |
| Cross-epic dependency drift | Medium | Medium | Work stories in listed order and run `/story-readiness` for each story before `/dev-story`. |

## Dependencies on External Factors
- Godot 4.6.2 behavior must be checked against `docs/engine-reference/godot/` where ADRs require verification.
- QA plan is in place: `production/qa/qa-plan-sprint-7-2026-05-04.md`.

## Definition of Done for this Sprint
- [ ] All Must Have tasks completed
- [ ] All tasks pass acceptance criteria
- [ ] QA plan exists (`production/qa/qa-plan-sprint-7-2026-05-04.md`) ✅
- [ ] All Logic/Integration stories have passing unit/integration tests
- [ ] Smoke check passed (`/smoke-check sprint`)
- [ ] QA sign-off report: APPROVED or APPROVED WITH CONDITIONS (`/team-qa sprint`)
- [ ] No S1 or S2 bugs in delivered features
- [ ] Design documents updated for any deviations
- [ ] Code reviewed and merged
- [ ] **Traceability**: 所有 sprint stories 映射回 `item-material-system.md` / `output-multiplier-system.md` / `debug-console.md` 的 GDD acceptance criteria（覆盖率 100%）
- [ ] **Core Gameplay Layer milestone**: ADR-0012 Release 排除 evidence + ADR-0007 OMS×ModifierEngine 职责分割证明 已记录到 `production/qa/evidence/`

## 2026-05-04 执行记录
- 本轮按 sprint 顺序执行到 Sprint 7 后，QA gate PASS。
- 证据：`production/qa/evidence/sprint-7-qa-result-2026-05-04.md`。
- 最新 GdUnit：`reports/report_8/results.xml`（137 个测试，0 个失败，0 个跳过，0 个 flaky）。

## Next Steps
- `/story-readiness [story-file]` for the first Must Have story
- `/dev-story [story-file]` after readiness passes
- `/sprint-status` during active execution
- `/scope-check [epic]` before implementing work outside the listed stories
