# Sprint 4 -- 2026-06-15 to 2026-06-28

## Sprint Goal
Deliver the planning and implementation slice from 公式引擎 through 存档系统 while preserving upstream dependency order.

## AI Context Budget
- Stories: 20 total（≤ 20 — context window hard constraint）
- Parallelizable: 2 stories（无跨依赖，可 parallel subagent 执行）
- Verification Density: ≥ 1 automated or manual evidence item per story

## Tasks

### Must Have（Critical Path — 依赖顺序）
| ID | Story | Epic | Type | Depends On |
|----|-------|------|------|------------|
| S4-006-formula-engine | [结果为 `50.0`](../epics/formula-engine/story-006-50-0.md) | 公式引擎 | Logic | Story 001 must be ready or done for shared test fixtures and baseline APIs |
| S4-007-formula-engine | [结果为 `30.0`](../epics/formula-engine/story-007-30-0.md) | 公式引擎 | Logic | Story 001 must be ready or done for shared test fixtures and baseline APIs |
| S4-008-formula-engine | [缓存清空，后续调用触发重新解析](../epics/formula-engine/story-008-008-config-data.md) | 公式引擎 | Config/Data | Story 001 must be ready or done for shared test fixtures and baseline APIs |
| S4-009-formula-engine | [结果为 `-7.0`（负数允许）](../epics/formula-engine/story-009-7-0.md) | 公式引擎 | Config/Data | Story 001 must be ready or done for shared test fixtures and baseline APIs |
| S4-010-formula-engine | [threshold 钳位到 `1.0`，打印警告](../epics/formula-engine/story-010-threshold-1-0.md) | 公式引擎 | Logic | Story 001 must be ready or done for shared test fixtures and baseline APIs |
| S4-001-modifier-engine | [返回 `250.0`](../epics/modifier-engine/story-001-250-0.md) | 修正器/倍率引擎 | UI | None |
| S4-002-modifier-engine | [结果为 BigNumber 表示 2500](../epics/modifier-engine/story-002-bignumber-2500.md) | 修正器/倍率引擎 | Config/Data | Story 001 must be ready or done for shared test fixtures and baseline APIs |
| S4-003-modifier-engine | [返回 `true`；再次调用 `unregister("abc")` 返回 `false`](../epics/modifier-engine/story-003-true-unregister-abc-false.md) | 修正器/倍率引擎 | Logic | Story 001 must be ready or done for shared test fixtures and baseline APIs |
| S4-004-modifier-engine | [返回空字符串 `""`，打印警告](../epics/modifier-engine/story-004-004-logic.md) | 修正器/倍率引擎 | Logic | Story 001 must be ready or done for shared test fixtures and baseline APIs |
| S4-005-modifier-engine | [成功返回 ID，`get_add_sum` 包含 `0.0` 贡献](../epics/modifier-engine/story-005-id-get-add-sum-0-0.md) | 修正器/倍率引擎 | Logic | Story 001 must be ready or done for shared test fixtures and baseline APIs |
| S4-006-modifier-engine | [第二次直接返回缓存值](../epics/modifier-engine/story-006-006-ui.md) | 修正器/倍率引擎 | UI | Story 001 must be ready or done for shared test fixtures and baseline APIs |
| S4-007-modifier-engine | [返回的数组长度为 2 且包含 `"player.atk"` 和 `"lingqi_production"`（去重，顺序不保证）；空注册表时返](../epics/modifier-engine/story-007-2-player-atk-lingqi-production.md) | 修正器/倍率引擎 | Config/Data | Story 001 must be ready or done for shared test fixtures and baseline APIs |

### Should Have
| ID | Story | Epic | Type | Depends On |
|----|-------|------|------|------------|
| S4-001-save-system | [`user://save/save.json` 包含 `meta` 和 `systems`，且 `systems.time_manager`](../epics/save-system/story-001-user-save-save-json-meta-systems-systems-time-manager.md) | 存档系统 | Config/Data | None |
| S4-002-save-system | [尝试加载 `save.json.bak`，若 backup 有效则从 backup 恢复，发布 `save.corrupted` 事件](../epics/save-system/story-002-save-json-bak-backup-backup-save-corrupted.md) | 存档系统 | Config/Data | Story 001 must be ready or done for shared test fixtures and baseline APIs |
| S4-003-save-system | [系统 A 的 namespace 数据为 `null`，系统 B 的数据正常保存，打印警告](../epics/save-system/story-003-a-namespace-null-b.md) | 存档系统 | Integration | Story 001 must be ready or done for shared test fixtures and baseline APIs |
| S4-004-save-system | [该 provider 的 `restore_fn()` 收到空 Dictionary `{}`](../epics/save-system/story-004-provider-restore-fn-dictionary.md) | 存档系统 | Integration | Story 001 must be ready or done for shared test fixtures and baseline APIs |
| S4-005-save-system | [迁移中止，不覆盖原文件，回退到 backup 或新游戏](../epics/save-system/story-005-backup.md) | 存档系统 | Config/Data | Story 001 must be ready or done for shared test fixtures and baseline APIs |
| S4-006-save-system | [在关闭前完成一次保存](../epics/save-system/story-006-006-integration.md) | 存档系统 | Integration | Story 001 must be ready or done for shared test fixtures and baseline APIs |

### Nice to Have
| ID | Story | Epic | Type | Depends On |
|----|-------|------|------|------------|
| S4-007-save-system | [文件写入 `user://test_save/save.json`](../epics/save-system/story-007-user-test-save-save-json.md) | 存档系统 | Config/Data | Story 001 must be ready or done for shared test fixtures and baseline APIs |
| S4-008-save-system | [存在 `save.json` 和 `save.json.bak`，不存在 `save.json.tmp`（临时文件已清理）](../epics/save-system/story-008-save-json-save-json-bak-save-json-tmp.md) | 存档系统 | Config/Data | Story 001 must be ready or done for shared test fixtures and baseline APIs |

## Carryover from Previous Sprint
| Story | Reason |
|-------|--------|
| None | New generated sprint plan set 4/10. |

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
- [ ] QA plan exists (`production/qa/qa-plan-sprint-4.md`)
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
