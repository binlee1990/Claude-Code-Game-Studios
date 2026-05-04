# Sprint 5 -- 2026-06-29 to 2026-07-12

## Sprint Goal
Core Gameplay 起步：ResourceSystem 完整 CRUD + 变更事件 + max/快照/重置 + 性能；AttributeSystem 实体生命周期 + Single CRUD + Final Value 通过 ModifierEngine 集成。Sprint 出口意味着资源/属性两条核心数值链路接入修正器，可被后续 Feature 层调用。

## Layer / Milestone
- Layer: Core Gameplay
- Milestone: 无（Core Gameplay 完成节点在 Sprint 7 出口）

## AI Context Budget
- Stories: 20 total（≤ 20 — context window hard constraint）
- Parallelizable: 2 stories（无跨依赖，可 parallel subagent 执行）
- Verification Density: ≥ 1 automated or manual evidence item per story

## Tasks

### Must Have（Critical Path — 依赖顺序）
| ID | Story | Epic | Type | Depends On |
|----|-------|------|------|------------|
| S5-001-resource-system | [Core CRUD 1](../epics/resource-system/story-001-core-crud-1.md) | 资源系统 | Integration | None |
| S5-002-resource-system | [Core CRUD 2](../epics/resource-system/story-002-core-crud-2.md) | 资源系统 | Logic | Story 001 must be ready or done for shared test fixtures and baseline APIs |
| S5-003-resource-system | [Core CRUD 3](../epics/resource-system/story-003-core-crud-3.md) | 资源系统 | Integration | Story 001 must be ready or done for shared test fixtures and baseline APIs |
| S5-004-resource-system | [Core CRUD 4](../epics/resource-system/story-004-core-crud-4.md) | 资源系统 | Integration | Story 001 must be ready or done for shared test fixtures and baseline APIs |
| S5-005-resource-system | [Events 1](../epics/resource-system/story-005-events-1.md) | 资源系统 | Integration | Story 001 must be ready or done for shared test fixtures and baseline APIs |
| S5-006-resource-system | [Events 2](../epics/resource-system/story-006-events-2.md) | 资源系统 | Integration | Story 001 must be ready or done for shared test fixtures and baseline APIs |
| S5-007-resource-system | [set_max 1](../epics/resource-system/story-007-set-max-1.md) | 资源系统 | Integration | Story 001 must be ready or done for shared test fixtures and baseline APIs |
| S5-008-resource-system | [set_max 2](../epics/resource-system/story-008-set-max-2.md) | 资源系统 | Logic | Story 001 must be ready or done for shared test fixtures and baseline APIs |
| S5-009-resource-system | [Reset 1](../epics/resource-system/story-009-reset-1.md) | 资源系统 | Integration | Story 001 must be ready or done for shared test fixtures and baseline APIs |
| S5-010-resource-system | [Reset 2](../epics/resource-system/story-010-reset-2.md) | 资源系统 | Logic | Story 001 must be ready or done for shared test fixtures and baseline APIs |
| S5-011-resource-system | [Snapshot / Restore](../epics/resource-system/story-011-snapshot-restore.md) | 资源系统 | Integration | Story 001 must be ready or done for shared test fixtures and baseline APIs |
| S5-012-resource-system | [Edge Cases](../epics/resource-system/story-012-edge-cases.md) | 资源系统 | Logic | Story 001 must be ready or done for shared test fixtures and baseline APIs |

### Should Have
| ID | Story | Epic | Type | Depends On |
|----|-------|------|------|------------|
| S5-013-resource-system | [Performance / Memory](../epics/resource-system/story-013-performance-memory.md) | 资源系统 | Integration | Story 001 must be ready or done for shared test fixtures and baseline APIs |
| S5-001-attribute-system | [实体生命周期 1](../epics/attribute-system/story-001-1.md) | 属性系统 | Integration | None |
| S5-002-attribute-system | [实体生命周期 2](../epics/attribute-system/story-002-2.md) | 属性系统 | Integration | Story 001 must be ready or done for shared test fixtures and baseline APIs |
| S5-003-attribute-system | [Single CRUD 1](../epics/attribute-system/story-003-single-crud-1.md) | 属性系统 | Integration | Story 001 must be ready or done for shared test fixtures and baseline APIs |
| S5-004-attribute-system | [Single CRUD 2](../epics/attribute-system/story-004-single-crud-2.md) | 属性系统 | Logic | Story 001 must be ready or done for shared test fixtures and baseline APIs |
| S5-005-attribute-system | [Final Value Integration 1](../epics/attribute-system/story-005-final-value-integration-1.md) | 属性系统 | Integration | Story 001 must be ready or done for shared test fixtures and baseline APIs |

### Nice to Have
| ID | Story | Epic | Type | Depends On |
|----|-------|------|------|------------|
| S5-006-attribute-system | [Final Value Integration 2](../epics/attribute-system/story-006-final-value-integration-2.md) | 属性系统 | Integration | Story 001 must be ready or done for shared test fixtures and baseline APIs |
| S5-007-attribute-system | [Events](../epics/attribute-system/story-007-events.md) | 属性系统 | Integration | Story 001 must be ready or done for shared test fixtures and baseline APIs |

## Carryover from Previous Sprint
| Story | Reason |
|-------|--------|
| None | New generated sprint plan set 5/10. |

## Risks
| Risk | Probability | Impact | Mitigation |
|------|-------------|--------|------------|
| ResourceSystem 演变为 God Object | Medium | High | TD-SYSTEM-BOUNDARY 已约束：仅 ID→数值 CRUD+事件，不含产出/乘数。S5-013 性能测试覆盖大量资源场景。 |
| ModifierEngine 与 AttributeSystem 集成顺序 | Medium | Medium | S5-005 Final Value Integration 必须在 attribute Logic 主路径之后；ADR-0010 不可变 BigNumber 约束。 |
| Cross-epic dependency drift | Medium | Medium | Work stories in listed order and run `/story-readiness` for each story before `/dev-story`. |

## Dependencies on External Factors
- Godot 4.6.2 behavior must be checked against `docs/engine-reference/godot/` where ADRs require verification.
- QA plan is in place: `production/qa/qa-plan-sprint-5-2026-05-04.md`.

## Definition of Done for this Sprint
- [ ] All Must Have tasks completed
- [ ] All tasks pass acceptance criteria
- [ ] QA plan exists (`production/qa/qa-plan-sprint-5-2026-05-04.md`) ✅
- [ ] All Logic/Integration stories have passing unit/integration tests
- [ ] Smoke check passed (`/smoke-check sprint`)
- [ ] QA sign-off report: APPROVED or APPROVED WITH CONDITIONS (`/team-qa sprint`)
- [ ] No S1 or S2 bugs in delivered features
- [ ] Design documents updated for any deviations
- [ ] Code reviewed and merged
- [ ] **Traceability**: 所有 sprint stories 映射回 `resource-system.md` / `attribute-system.md` 的 GDD acceptance criteria（覆盖率 100%）

## 2026-05-04 执行记录
- 本轮按 sprint 顺序执行到 Sprint 5 后，QA gate PASS。
- 证据：`production/qa/evidence/sprint-5-qa-result-2026-05-04.md`。
- 最新 GdUnit：`reports/report_8/results.xml`（137 个测试，0 个失败，0 个跳过，0 个 flaky）。

## Next Steps
- `/story-readiness [story-file]` for the first Must Have story
- `/dev-story [story-file]` after readiness passes
- `/sprint-status` during active execution
- `/scope-check [epic]` before implementing work outside the listed stories
