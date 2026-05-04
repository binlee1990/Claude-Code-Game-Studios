# Sprint 1 -- 2026-05-04 to 2026-05-17

## Sprint Goal
Foundation 起步：交付 BigNumber API contract（含 60fps 帧预算性能 spike 与饱和/零边界）+ RandomSeedSystem 全局单例与多流独立性。Sprint 出口意味着 GdUnit4 + CI 首次绿灯，且所有数值原语 + 多流 RNG 可被后续 sprint 调用。

## Layer / Milestone
- Layer: Foundation
- Milestone: 无（Foundation 完成节点在 Sprint 2 出口）

## AI Context Budget
- Stories: 20 total（≤ 20 — context window hard constraint）
- Parallelizable: 2 stories（无跨依赖，可 parallel subagent 执行）
- Verification Density: ≥ 1 automated or manual evidence item per story

## Tasks

### Must Have（Critical Path — 依赖顺序）
| ID | Story | Epic | Type | Depends On |
|----|-------|------|------|------------|
| S1-001-big-number-system | [Testing harness and BigNumber API contract](../epics/big-number-system/story-001-testing-harness-and-bignumber-api-contract.md) | 大数值系统 | Integration | None |
| S1-002-big-number-system | [`mantissa ∈ \[1.0, 10.0)` 且 `exponent` 使得 `mantissa × 10^exponent` 等于原始](../epics/big-number-system/story-002-mantissa-1-0-10-0-exponent-mantissa-10-exponent.md) | 大数值系统 | Logic | Story 001 must be ready or done for shared test fixtures and baseline APIs |
| S1-003-big-number-system | [结果为 `{6.0, 8}`](../epics/big-number-system/story-003-6-0-8.md) | 大数值系统 | Logic | Story 001 must be ready or done for shared test fixtures and baseline APIs |
| S1-004-big-number-system | [结果约为 5.5（float，误差 < 0.01）](../epics/big-number-system/story-004-5-5-float-0-01.md) | 大数值系统 | Logic | Story 001 must be ready or done for shared test fixtures and baseline APIs |
| S1-005-big-number-system | [结果为 `BigNumber.ZERO`](../epics/big-number-system/story-005-bignumber-zero.md) | 大数值系统 | Logic | Story 001 must be ready or done for shared test fixtures and baseline APIs |
| S1-006-big-number-system | [结果为 `BigNumber.ZERO`](../epics/big-number-system/story-006-bignumber-zero.md) | 大数值系统 | Logic | Story 001 must be ready or done for shared test fixtures and baseline APIs |
| S1-007-big-number-system | [结果为 `BigNumber.MAX`（饱和）](../epics/big-number-system/story-007-bignumber-max.md) | 大数值系统 | Logic | Story 001 must be ready or done for shared test fixtures and baseline APIs |
| S1-008-big-number-system | [总耗时 < 16.6ms（60fps 帧预算内，纯 GDScript MVP 目标；若不达标，升级至 GDExtension C++）](../epics/big-number-system/story-008-16-6ms-60fps-gdscript-mvp-gdextension-c.md) | 大数值系统 | Logic | Story 001 must be ready or done for shared test fixtures and baseline APIs |
| S1-009-big-number-system | [`mantissa == 4.2`，`exponent == 1`](../epics/big-number-system/story-009-mantissa-4-2-exponent-1.md) | 大数值系统 | Logic | Story 001 must be ready or done for shared test fixtures and baseline APIs |
| S1-010-big-number-system | [返回 `100`](../epics/big-number-system/story-010-100.md) | 大数值系统 | Logic | Story 001 must be ready or done for shared test fixtures and baseline APIs |
| S1-011-big-number-system | [返回格式为 `"1.23e150"` 的字符串](../epics/big-number-system/story-011-1-23e150.md) | 大数值系统 | Logic | Story 001 must be ready or done for shared test fixtures and baseline APIs |
| S1-012-big-number-system | [均返回 `true`](../epics/big-number-system/story-012-true.md) | 大数值系统 | Logic | Story 001 must be ready or done for shared test fixtures and baseline APIs |

### Should Have
| ID | Story | Epic | Type | Depends On |
|----|-------|------|------|------------|
| S1-013-big-number-system | [结果为 `BigNumber.MAX`](../epics/big-number-system/story-013-bignumber-max.md) | 大数值系统 | Logic | Story 001 must be ready or done for shared test fixtures and baseline APIs |
| S1-014-big-number-system | [结果为 `BigNumber.MAX`（饱和）](../epics/big-number-system/story-014-bignumber-max.md) | 大数值系统 | Logic | Story 001 must be ready or done for shared test fixtures and baseline APIs |
| S1-001-random-seed-system | [获得同一个全局单例实例](../epics/random-seed-system/story-001-001-integration.md) | 随机数与种子系统 | Integration | None |
| S1-002-random-seed-system | [LOOT 流的下一个 `rand_float` 结果与从未调用 COMBAT 流时完全一致](../epics/random-seed-system/story-002-loot-rand-float-combat.md) | 随机数与种子系统 | Logic | Story 001 must be ready or done for shared test fixtures and baseline APIs |
| S1-003-random-seed-system | [返回 -1](../epics/random-seed-system/story-003-1.md) | 随机数与种子系统 | Logic | Story 001 must be ready or done for shared test fixtures and baseline APIs |
| S1-004-random-seed-system | [GIVEN: `rand_bool(COMBAT, 0](../epics/random-seed-system/story-004-given-rand-bool-combat-0.md) | 随机数与种子系统 | Logic | Story 001 must be ready or done for shared test fixtures and baseline APIs |

### Nice to Have
| ID | Story | Epic | Type | Depends On |
|----|-------|------|------|------------|
| S1-005-random-seed-system | [钳位到 0，返回 false](../epics/random-seed-system/story-005-0-false.md) | 随机数与种子系统 | Logic | Story 001 must be ready or done for shared test fixtures and baseline APIs |
| S1-006-random-seed-system | [返回 7，不消耗随机数](../epics/random-seed-system/story-006-7.md) | 随机数与种子系统 | Logic | Story 001 must be ready or done for shared test fixtures and baseline APIs |

## Carryover from Previous Sprint
| Story | Reason |
|-------|--------|
| None | New generated sprint plan set 1/10. |

## Risks
| Risk | Probability | Impact | Mitigation |
|------|-------------|--------|------------|
| GdUnit4 插件未在用户本地安装 | Medium | High | Sprint 出口前确保 `addons/gdUnit4/plugin.cfg` 存在；仍缺失则把 example test 留为 known blocker。 |
| Godot 4.6.2 post-cutoff API behavior | Medium | High | Verify against `docs/engine-reference/godot/` when a governing ADR marks HIGH or MEDIUM risk. |
| BigNumber 纯 GDScript 不达 60fps 帧预算 | Medium | High | S1-008 是 spike；不达标即按 ADR-0001 升级 GDExtension C++ 路径。 |
| Cross-epic dependency drift | Medium | Medium | Work stories in listed order and run `/story-readiness` for each story before `/dev-story`. |

## Dependencies on External Factors
- Godot 4.6.2 behavior must be checked against `docs/engine-reference/godot/` where ADRs require verification.
- QA plan is in place: `production/qa/qa-plan-sprint-1-2026-05-04.md`.

## Definition of Done for this Sprint
- [ ] All Must Have tasks completed
- [ ] All tasks pass acceptance criteria
- [ ] QA plan exists (`production/qa/qa-plan-sprint-1-2026-05-04.md`) ✅
- [ ] All Logic/Integration stories have passing unit/integration tests
- [ ] Smoke check passed (`/smoke-check sprint`)
- [ ] QA sign-off report: APPROVED or APPROVED WITH CONDITIONS (`/team-qa sprint`)
- [ ] No S1 or S2 bugs in delivered features
- [ ] Design documents updated for any deviations
- [ ] Code reviewed and merged
- [ ] **Traceability**: 所有 sprint stories 映射回 GDD `big-number-system.md` / `random-seed-system.md` 的 acceptance criteria 并在测试 docstring 中标注（覆盖率 100%）
- [ ] **ADR 验证证据**: BigNumber 60fps 性能 + RNG 多流独立性 evidence 已记录到 `production/qa/evidence/`

## 2026-05-04 执行记录
- 本轮按 sprint 顺序执行到 Sprint 1 后，QA gate PASS。
- 证据：`production/qa/evidence/sprint-1-qa-result-2026-05-04.md`。
- 最新 GdUnit：`reports/report_8/results.xml`（137 个测试，0 个失败，0 个跳过，0 个 flaky）。

## Next Steps
- `/story-readiness [story-file]` for the first Must Have story
- `/dev-story [story-file]` after readiness passes
- `/sprint-status` during active execution
- `/scope-check [epic]` before implementing work outside the listed stories
