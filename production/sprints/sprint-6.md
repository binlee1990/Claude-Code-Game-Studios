# Sprint 6 -- 2026-07-13 to 2026-07-26

## Sprint Goal
Core Gameplay 推进：AttributeSystem 完整批量/快照/边界/性能；物品/材料系统完整加载/查询/拷贝/启动时序/热重载/性能。Sprint 出口意味着 ItemMaterial 数据基础设施可被掉落系统消费。

## Layer / Milestone
- Layer: Core Gameplay
- Milestone: 无（Core Gameplay 完成节点在 Sprint 7 出口）

## AI Context Budget
- Stories: 20 total（≤ 20 — context window hard constraint）
- Parallelizable: 1 stories（无跨依赖，可 parallel subagent 执行）
- Verification Density: ≥ 1 automated or manual evidence item per story

## Tasks

### Must Have（Critical Path — 依赖顺序）
| ID | Story | Epic | Type | Depends On |
|----|-------|------|------|------------|
| S6-008-attribute-system | [Batch / Snapshot / Restore 1](../epics/attribute-system/story-008-batch-snapshot-restore-1.md) | 属性系统 | Integration | Story 001 must be ready or done for shared test fixtures and baseline APIs |
| S6-009-attribute-system | [Batch / Snapshot / Restore 2](../epics/attribute-system/story-009-batch-snapshot-restore-2.md) | 属性系统 | Integration | Story 001 must be ready or done for shared test fixtures and baseline APIs |
| S6-010-attribute-system | [Edge Cases](../epics/attribute-system/story-010-edge-cases.md) | 属性系统 | Integration | Story 001 must be ready or done for shared test fixtures and baseline APIs |
| S6-011-attribute-system | [Performance / Memory 1](../epics/attribute-system/story-011-performance-memory-1.md) | 属性系统 | Logic | Story 001 must be ready or done for shared test fixtures and baseline APIs |
| S6-012-attribute-system | [Performance / Memory 2](../epics/attribute-system/story-012-performance-memory-2.md) | 属性系统 | Logic | Story 001 must be ready or done for shared test fixtures and baseline APIs |
| S6-001-item-material-system | [A. 加载与配置（11 条） 1](../epics/item-material-system/story-001-a-11-1.md) | 物品/材料系统 | Config/Data | None |
| S6-002-item-material-system | [A. 加载与配置（11 条） 2](../epics/item-material-system/story-002-a-11-2.md) | 物品/材料系统 | Config/Data | Story 001 must be ready or done for shared test fixtures and baseline APIs |
| S6-003-item-material-system | [A. 加载与配置（11 条） 3](../epics/item-material-system/story-003-a-11-3.md) | 物品/材料系统 | Config/Data | Story 001 must be ready or done for shared test fixtures and baseline APIs |
| S6-004-item-material-system | [A. 加载与配置（11 条） 4](../epics/item-material-system/story-004-a-11-4.md) | 物品/材料系统 | Config/Data | Story 001 must be ready or done for shared test fixtures and baseline APIs |
| S6-005-item-material-system | [B. 查询 API（12 条） 1](../epics/item-material-system/story-005-b-api-12-1.md) | 物品/材料系统 | Logic | Story 001 must be ready or done for shared test fixtures and baseline APIs |
| S6-006-item-material-system | [B. 查询 API（12 条） 2](../epics/item-material-system/story-006-b-api-12-2.md) | 物品/材料系统 | Logic | Story 001 must be ready or done for shared test fixtures and baseline APIs |
| S6-007-item-material-system | [B. 查询 API（12 条） 3](../epics/item-material-system/story-007-b-api-12-3.md) | 物品/材料系统 | Logic | Story 001 must be ready or done for shared test fixtures and baseline APIs |

### Should Have
| ID | Story | Epic | Type | Depends On |
|----|-------|------|------|------------|
| S6-008-item-material-system | [B. 查询 API（12 条） 4](../epics/item-material-system/story-008-b-api-12-4.md) | 物品/材料系统 | Logic | Story 001 must be ready or done for shared test fixtures and baseline APIs |
| S6-009-item-material-system | [C. 拷贝陷阱（4 条）](../epics/item-material-system/story-009-c-4.md) | 物品/材料系统 | Logic | Story 001 must be ready or done for shared test fixtures and baseline APIs |
| S6-010-item-material-system | [D. 启动时序（2 条）](../epics/item-material-system/story-010-d-2.md) | 物品/材料系统 | Integration | Story 001 must be ready or done for shared test fixtures and baseline APIs |
| S6-011-item-material-system | [E. 热重载（4 条） 1](../epics/item-material-system/story-011-e-4-1.md) | 物品/材料系统 | Integration | Story 001 must be ready or done for shared test fixtures and baseline APIs |
| S6-012-item-material-system | [E. 热重载（4 条） 2](../epics/item-material-system/story-012-e-4-2.md) | 物品/材料系统 | Integration | Story 001 must be ready or done for shared test fixtures and baseline APIs |
| S6-013-item-material-system | [F. 性能（6 条） 1](../epics/item-material-system/story-013-f-6-1.md) | 物品/材料系统 | Logic | Story 001 must be ready or done for shared test fixtures and baseline APIs |

### Nice to Have
| ID | Story | Epic | Type | Depends On |
|----|-------|------|------|------------|
| S6-014-item-material-system | [F. 性能（6 条） 2](../epics/item-material-system/story-014-f-6-2.md) | 物品/材料系统 | Logic | Story 001 must be ready or done for shared test fixtures and baseline APIs |
| S6-015-item-material-system | [G. Lifecycle 事件（2 条）](../epics/item-material-system/story-015-g-lifecycle-2.md) | 物品/材料系统 | Integration | Story 001 must be ready or done for shared test fixtures and baseline APIs |

## Carryover from Previous Sprint
| Story | Reason |
|-------|--------|
| None | New generated sprint plan set 6/10. |

## Risks
| Risk | Probability | Impact | Mitigation |
|------|-------------|--------|------------|
| ItemMaterial 拷贝陷阱（dictionary 浅拷贝）泄漏到 inventory | High | High | S6-009 拷贝陷阱测试覆盖；ADR-0005 配置表只读契约。 |
| 热重载触发期间 inventory 引用悬挂 | Medium | Medium | S6-011/012 hot reload 测试 + S6-015 lifecycle 事件。 |
| Cross-epic dependency drift | Medium | Medium | Work stories in listed order and run `/story-readiness` for each story before `/dev-story`. |

## Dependencies on External Factors
- Godot 4.6.2 behavior must be checked against `docs/engine-reference/godot/` where ADRs require verification.
- QA plan is in place: `production/qa/qa-plan-sprint-6-2026-05-04.md`.

## Definition of Done for this Sprint
- [ ] All Must Have tasks completed
- [ ] All tasks pass acceptance criteria
- [ ] QA plan exists (`production/qa/qa-plan-sprint-6-2026-05-04.md`) ✅
- [ ] All Logic/Integration stories have passing unit/integration tests
- [ ] Smoke check passed (`/smoke-check sprint`)
- [ ] QA sign-off report: APPROVED or APPROVED WITH CONDITIONS (`/team-qa sprint`)
- [ ] No S1 or S2 bugs in delivered features
- [ ] Design documents updated for any deviations
- [ ] Code reviewed and merged
- [ ] **Traceability**: 所有 sprint stories 映射回 `attribute-system.md` / `item-material-system.md` 的 GDD acceptance criteria（覆盖率 100%）

## 2026-05-04 执行记录
- 本轮按 sprint 顺序执行到 Sprint 6 后，QA gate PASS。
- 证据：`production/qa/evidence/sprint-6-qa-result-2026-05-04.md`。
- 最新 GdUnit：`reports/report_8/results.xml`（137 个测试，0 个失败，0 个跳过，0 个 flaky）。

## Next Steps
- `/story-readiness [story-file]` for the first Must Have story
- `/dev-story [story-file]` after readiness passes
- `/sprint-status` during active execution
- `/scope-check [epic]` before implementing work outside the listed stories
