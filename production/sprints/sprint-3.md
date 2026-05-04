# Sprint 3 -- 2026-06-01 to 2026-06-14

## Sprint Goal
Deliver the planning and implementation slice from 时间管理器 through 公式引擎 while preserving upstream dependency order.

## AI Context Budget
- Stories: 20 total（≤ 20 — context window hard constraint）
- Parallelizable: 3 stories（无跨依赖，可 parallel subagent 执行）
- Verification Density: ≥ 1 automated or manual evidence item per story

## Tasks

### Must Have（Critical Path — 依赖顺序）
| ID | Story | Epic | Type | Depends On |
|----|-------|------|------|------------|
| S3-007-time-manager | [静默忽略，无错误](../epics/time-manager/story-007-007-logic.md) | 时间管理器 | Logic | Story 001 must be ready or done for shared test fixtures and baseline APIs |
| S3-001-number-formatting-system | [返回 `"0"`](../epics/number-formatting-system/story-001-0.md) | 数值格式化系统 | Logic | None |
| S3-002-number-formatting-system | [返回 `"9,999"`](../epics/number-formatting-system/story-002-9-999.md) | 数值格式化系统 | Logic | Story 001 must be ready or done for shared test fixtures and baseline APIs |
| S3-003-number-formatting-system | [返回 `"567万"`](../epics/number-formatting-system/story-003-567.md) | 数值格式化系统 | Logic | Story 001 must be ready or done for shared test fixtures and baseline APIs |
| S3-004-number-formatting-system | [返回 `"1234极"`](../epics/number-formatting-system/story-004-1234.md) | 数值格式化系统 | Logic | Story 001 must be ready or done for shared test fixtures and baseline APIs |
| S3-005-number-formatting-system | [返回 `"MAX"`](../epics/number-formatting-system/story-005-max.md) | 数值格式化系统 | Logic | Story 001 must be ready or done for shared test fixtures and baseline APIs |
| S3-006-number-formatting-system | [返回 `"1.00亿"`（舍入跨单位）](../epics/number-formatting-system/story-006-1-00.md) | 数值格式化系统 | Logic | Story 001 must be ready or done for shared test fixtures and baseline APIs |
| S3-007-number-formatting-system | [返回 `"万"`](../epics/number-formatting-system/story-007-007-ui.md) | 数值格式化系统 | UI | Story 001 must be ready or done for shared test fixtures and baseline APIs |
| S3-008-number-formatting-system | [总耗时 < 1ms](../epics/number-formatting-system/story-008-1ms.md) | 数值格式化系统 | Logic | Story 001 must be ready or done for shared test fixtures and baseline APIs |
| S3-001-data-config-system | [返回 `{"name": "史莱姆", "hp": "100"}`](../epics/data-config-system/story-001-name-hp-100.md) | 数据配置系统 | Config/Data | None |
| S3-002-data-config-system | [返回含 3 个键的 Dictionary](../epics/data-config-system/story-002-3-dictionary.md) | 数据配置系统 | Config/Data | Story 001 must be ready or done for shared test fixtures and baseline APIs |
| S3-003-data-config-system | [该表为空，其他表正常加载，打印错误含文件路径](../epics/data-config-system/story-003-003-config-data.md) | 数据配置系统 | Config/Data | Story 001 must be ready or done for shared test fixtures and baseline APIs |

### Should Have
| ID | Story | Epic | Type | Depends On |
|----|-------|------|------|------------|
| S3-004-data-config-system | [后者覆盖前者，打印警告](../epics/data-config-system/story-004-004-config-data.md) | 数据配置系统 | Config/Data | Story 001 must be ready or done for shared test fixtures and baseline APIs |
| S3-005-data-config-system | [无操作](../epics/data-config-system/story-005-005-config-data.md) | 数据配置系统 | Config/Data | Story 001 must be ready or done for shared test fixtures and baseline APIs |
| S3-006-data-config-system | [`tags` 为 `\["beast", "slime"\]`（Array 类型）](../epics/data-config-system/story-006-tags-beast-slime-array.md) | 数据配置系统 | Config/Data | Story 001 must be ready or done for shared test fixtures and baseline APIs |
| S3-001-formula-engine | [结果为 `15.0`](../epics/formula-engine/story-001-15-0.md) | 公式引擎 | Config/Data | None |
| S3-002-formula-engine | [多余变量被忽略，结果正确](../epics/formula-engine/story-002-002-config-data.md) | 公式引擎 | Config/Data | Story 001 must be ready or done for shared test fixtures and baseline APIs |
| S3-003-formula-engine | [返回 `0.0`，打印警告；再次调用返回 `0.0` 不重复解析](../epics/formula-engine/story-003-0-0-0-0.md) | 公式引擎 | Config/Data | Story 001 must be ready or done for shared test fixtures and baseline APIs |

### Nice to Have
| ID | Story | Epic | Type | Depends On |
|----|-------|------|------|------------|
| S3-004-formula-engine | [结果为 `1.0`（布尔 true → float）](../epics/formula-engine/story-004-1-0-true-float.md) | 公式引擎 | Config/Data | Story 001 must be ready or done for shared test fixtures and baseline APIs |
| S3-005-formula-engine | [结果为 `120.0`](../epics/formula-engine/story-005-120-0.md) | 公式引擎 | Logic | Story 001 must be ready or done for shared test fixtures and baseline APIs |

## Carryover from Previous Sprint
| Story | Reason |
|-------|--------|
| None | New generated sprint plan set 3/10. |

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
- [ ] QA plan exists (`production/qa/qa-plan-sprint-3.md`)
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
