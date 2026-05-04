# Sprint 2 -- 2026-05-18 to 2026-05-31

## Sprint Goal
Foundation 完成：RNG snapshot/恢复 + EventBus 完整生命周期（含 lifecycle spike、反递归、callable 失效清理） + TimeManager 时间源就绪（含离线 delta cap）。Sprint 出口标志 Foundation Layer milestone — Foundation 4 系统全部可作 Autoload 投入后续 sprint。

## Layer / Milestone
- Layer: Foundation
- Milestone: ✅ **Foundation Layer 完成**（end of Sprint 2）

## AI Context Budget
- Stories: 20 total（≤ 20 — context window hard constraint）
- Parallelizable: 2 stories（无跨依赖，可 parallel subagent 执行）
- Verification Density: ≥ 1 automated or manual evidence item per story

## Tasks

### Must Have（Critical Path — 依赖顺序）
| ID | Story | Epic | Type | Depends On |
|----|-------|------|------|------------|
| S2-007-random-seed-system | [所有流的种子和状态恢复到保存时的值，后续随机序列与保存时完全一致](../epics/random-seed-system/story-007-007-integration.md) | 随机数与种子系统 | Integration | Story 001 must be ready or done for shared test fixtures and baseline APIs |
| S2-008-random-seed-system | [模拟期间在线 RNG 仍为 S1，不受模拟调用影响](../epics/random-seed-system/story-008-rng-s1.md) | 随机数与种子系统 | Integration | Story 001 must be ready or done for shared test fixtures and baseline APIs |
| S2-009-random-seed-system | [返回 null，打印警告](../epics/random-seed-system/story-009-null.md) | 随机数与种子系统 | Integration | Story 001 must be ready or done for shared test fixtures and baseline APIs |
| S2-010-random-seed-system | [总 RNG 调用耗时占帧预算 < 1%](../epics/random-seed-system/story-010-rng-1.md) | 随机数与种子系统 | Integration | Story 001 must be ready or done for shared test fixtures and baseline APIs |
| S2-001-event-bus | [Godot 4.6 Callable lifecycle spike](../epics/event-bus/story-001-godot-4-6-callable-lifecycle-spike.md) | 事件总线 | Integration | None |
| S2-002-event-bus | [获得同一个全局单例实例](../epics/event-bus/story-002-002-integration.md) | 事件总线 | Integration | Story 001 must be ready or done for shared test fixtures and baseline APIs |
| S2-003-event-bus | [后续 emit 不再触发该 callable](../epics/event-bus/story-003-emit-callable.md) | 事件总线 | Integration | Story 001 must be ready or done for shared test fixtures and baseline APIs |
| S2-004-event-bus | [第 1 和第 3 个订阅者正常收到事件，第 2 个订阅记录被移除，控制台打印无效 callable 警告](../epics/event-bus/story-004-1-3-2-callable.md) | 事件总线 | Integration | Story 001 must be ready or done for shared test fixtures and baseline APIs |
| S2-005-event-bus | [递归 emit 被忽略，控制台打印警告](../epics/event-bus/story-005-emit.md) | 事件总线 | Integration | Story 001 must be ready or done for shared test fixtures and baseline APIs |
| S2-006-event-bus | [无错误、无副作用](../epics/event-bus/story-006-006-integration.md) | 事件总线 | Integration | Story 001 must be ready or done for shared test fixtures and baseline APIs |
| S2-007-event-bus | [该订阅被移除，后续 emit 不再触发该 callable](../epics/event-bus/story-007-emit-callable.md) | 事件总线 | Integration | Story 001 must be ready or done for shared test fixtures and baseline APIs |
| S2-008-event-bus | [callable 被触发一次，第一个参数等于 `"resource.lingqi.changed"`，第二个参数等于 emit 的 payl](../epics/event-bus/story-008-callable-resource-lingqi-changed-emit-payl.md) | 事件总线 | Integration | Story 001 must be ready or done for shared test fixtures and baseline APIs |

### Should Have
| ID | Story | Epic | Type | Depends On |
|----|-------|------|------|------------|
| S2-009-event-bus | [cb1 与 cb2 均被触发；cb1 收到一个参数（payload），cb2 收到两个参数（event_name + payload）](../epics/event-bus/story-009-cb1-cb2-cb1-payload-cb2-event-name-payload.md) | 事件总线 | Integration | Story 001 must be ready or done for shared test fixtures and baseline APIs |
| S2-010-event-bus | [订阅者只收到 1 次 `ui.hud.refresh`，payload 等于第 10 次调用的 payload](../epics/event-bus/story-010-1-ui-hud-refresh-payload-10-payload.md) | 事件总线 | Logic | Story 001 must be ready or done for shared test fixtures and baseline APIs |
| S2-001-time-manager | [返回当前 Unix 时间戳（精度 ±1 秒）](../epics/time-manager/story-001-unix-1.md) | 时间管理器 | Integration | None |
| S2-002-time-manager | [返回 3.0（乘法叠加）](../epics/time-manager/story-002-3-0.md) | 时间管理器 | Logic | Story 001 must be ready or done for shared test fixtures and baseline APIs |
| S2-003-time-manager | [`get_effective_speed()` 返回 100.0（截断）](../epics/time-manager/story-003-get-effective-speed-100-0.md) | 时间管理器 | Integration | Story 001 must be ready or done for shared test fixtures and baseline APIs |
| S2-004-time-manager | [返回 0.0](../epics/time-manager/story-004-0-0.md) | 时间管理器 | Integration | Story 001 must be ready or done for shared test fixtures and baseline APIs |

### Nice to Have
| ID | Story | Epic | Type | Depends On |
|----|-------|------|------|------------|
| S2-005-time-manager | [offline_delta 钳位到 28800 秒（MAX_OFFLINE_SECONDS），超过部分忽略](../epics/time-manager/story-005-offline-delta-28800-max-offline-seconds.md) | 时间管理器 | Integration | Story 001 must be ready or done for shared test fixtures and baseline APIs |
| S2-006-time-manager | [倍率立即更新，但 game_time 仍不推进，解冻后使用新倍率](../epics/time-manager/story-006-game-time.md) | 时间管理器 | Integration | Story 001 must be ready or done for shared test fixtures and baseline APIs |

## Carryover from Previous Sprint
| Story | Reason |
|-------|--------|
| None | New generated sprint plan set 2/10. |

## Risks
| Risk | Probability | Impact | Mitigation |
|------|-------------|--------|------------|
| Godot 4.6 Callable lifecycle 与 4.3 不兼容 | Medium | High | S2-001-event-bus 是 spike；不通过即把 ADR-0002 升级为 fast-fail issue 并触发 architecture review。 |
| Web 不活跃情境下 Time.get_unix_time_from_system 行为差异 | Medium | High | S2-005 钳位测试覆盖该路径；同时手测 Web 切后台 9 小时。 |
| Cross-epic dependency drift | Medium | Medium | Work stories in listed order and run `/story-readiness` for each story before `/dev-story`. |

## Dependencies on External Factors
- Godot 4.6.2 behavior must be checked against `docs/engine-reference/godot/` where ADRs require verification.
- QA plan is in place: `production/qa/qa-plan-sprint-2-2026-05-04.md`.

## Definition of Done for this Sprint
- [x] All Must Have tasks completed
- [x] All tasks pass acceptance criteria
- [x] QA plan exists (`production/qa/qa-plan-sprint-2-2026-05-04.md`) ✅
- [x] All Logic/Integration stories have passing unit/integration tests
- [x] Smoke check passed (`/smoke-check sprint`)
- [x] QA sign-off report: APPROVED or APPROVED WITH CONDITIONS (`/team-qa sprint`)
- [x] No S1 or S2 bugs in delivered features
- [x] Design documents updated for any deviations
- [x] Code reviewed and merged
- [x] **Traceability**: 所有 sprint stories 映射回 `random-seed-system.md` / `event-bus.md` / `time-manager.md` 的 GDD acceptance criteria（覆盖率 100%）
- [x] **Foundation Layer milestone**: Foundation 4 Autoload（BigNumber/RNG/EventBus/TimeManager）启动顺序通过 ADR-0008 守护测试

## 2026-05-04 执行记录

- 按 Tasks 表顺序真实执行 Sprint 2 的 20 个 story，并已回写 story `Status: Done`、Acceptance Criteria、Test Evidence。
- QA gate PASS 后证据：`production/qa/evidence/sprint-2-qa-result-2026-05-04.md`。
- 最新 GdUnit：`reports/report_13/results.xml`（137 个测试，0 个失败，0 个跳过，0 个 flaky）。
- 无 S1/S2 blocker 记录；如后续出现人工审查问题，应作为新缺陷进入下一轮。

## Next Steps
- `/story-readiness [story-file]` for the first Must Have story
- `/dev-story [story-file]` after readiness passes
- `/sprint-status` during active execution
- `/scope-check [epic]` before implementing work outside the listed stories
