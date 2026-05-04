# Sprint 5 -- 2026-06-29 to 2026-07-12

## Sprint Goal
Deliver the planning and implementation slice from 资源系统 through 属性系统 while preserving upstream dependency order.

## AI Context Budget
- Stories: 20 total（≤ 20 — context window hard constraint）
- Parallelizable: 2 stories（无跨依赖，可 parallel subagent 执行）
- Verification Density: ≥ 1 automated or manual evidence item per story

## Tasks

### Must Have（Critical Path — 依赖顺序）
| ID | Story | Epic | Type | Depends On |
|----|-------|------|------|------------|
| S5-001-resource-system | [Core CRUD 1](../epics/resource-system/story-001-core-crud-1.md) | 资源系统 | Config/Data | None |
| S5-002-resource-system | [Core CRUD 2](../epics/resource-system/story-002-core-crud-2.md) | 资源系统 | Logic | Story 001 must be ready or done for shared test fixtures and baseline APIs |
| S5-003-resource-system | [Core CRUD 3](../epics/resource-system/story-003-core-crud-3.md) | 资源系统 | Integration | Story 001 must be ready or done for shared test fixtures and baseline APIs |
| S5-004-resource-system | [Core CRUD 4](../epics/resource-system/story-004-core-crud-4.md) | 资源系统 | Integration | Story 001 must be ready or done for shared test fixtures and baseline APIs |
| S5-005-resource-system | [Events 1](../epics/resource-system/story-005-events-1.md) | 资源系统 | Integration | Story 001 must be ready or done for shared test fixtures and baseline APIs |
| S5-006-resource-system | [Events 2](../epics/resource-system/story-006-events-2.md) | 资源系统 | Integration | Story 001 must be ready or done for shared test fixtures and baseline APIs |
| S5-007-resource-system | [set_max 1](../epics/resource-system/story-007-set-max-1.md) | 资源系统 | Integration | Story 001 must be ready or done for shared test fixtures and baseline APIs |
| S5-008-resource-system | [set_max 2](../epics/resource-system/story-008-set-max-2.md) | 资源系统 | Logic | Story 001 must be ready or done for shared test fixtures and baseline APIs |
| S5-009-resource-system | [Reset 1](../epics/resource-system/story-009-reset-1.md) | 资源系统 | Integration | Story 001 must be ready or done for shared test fixtures and baseline APIs |
| S5-010-resource-system | [Reset 2](../epics/resource-system/story-010-reset-2.md) | 资源系统 | Logic | Story 001 must be ready or done for shared test fixtures and baseline APIs |
| S5-011-resource-system | [Snapshot / Restore](../epics/resource-system/story-011-snapshot-restore.md) | 资源系统 | Config/Data | Story 001 must be ready or done for shared test fixtures and baseline APIs |
| S5-012-resource-system | [Edge Cases](../epics/resource-system/story-012-edge-cases.md) | 资源系统 | Logic | Story 001 must be ready or done for shared test fixtures and baseline APIs |

### Should Have
| ID | Story | Epic | Type | Depends On |
|----|-------|------|------|------------|
| S5-013-resource-system | [Performance / Memory](../epics/resource-system/story-013-performance-memory.md) | 资源系统 | Integration | Story 001 must be ready or done for shared test fixtures and baseline APIs |
| S5-001-attribute-system | [实体生命周期 1](../epics/attribute-system/story-001-1.md) | 属性系统 | Config/Data | None |
| S5-002-attribute-system | [实体生命周期 2](../epics/attribute-system/story-002-2.md) | 属性系统 | Integration | Story 001 must be ready or done for shared test fixtures and baseline APIs |
| S5-003-attribute-system | [Single CRUD 1](../epics/attribute-system/story-003-single-crud-1.md) | 属性系统 | Config/Data | Story 001 must be ready or done for shared test fixtures and baseline APIs |
| S5-004-attribute-system | [Single CRUD 2](../epics/attribute-system/story-004-single-crud-2.md) | 属性系统 | Logic | Story 001 must be ready or done for shared test fixtures and baseline APIs |
| S5-005-attribute-system | [Final Value Integration 1](../epics/attribute-system/story-005-final-value-integration-1.md) | 属性系统 | UI | Story 001 must be ready or done for shared test fixtures and baseline APIs |

### Nice to Have
| ID | Story | Epic | Type | Depends On |
|----|-------|------|------|------------|
| S5-006-attribute-system | [Final Value Integration 2](../epics/attribute-system/story-006-final-value-integration-2.md) | 属性系统 | Integration | Story 001 must be ready or done for shared test fixtures and baseline APIs |
| S5-007-attribute-system | [Events](../epics/attribute-system/story-007-events.md) | 属性系统 | UI | Story 001 must be ready or done for shared test fixtures and baseline APIs |

## Carryover from Previous Sprint
| Story | Reason |
|-------|--------|
| None | New generated sprint plan set 5/10. |

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
- [ ] QA plan exists (`production/qa/qa-plan-sprint-5.md`)
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
