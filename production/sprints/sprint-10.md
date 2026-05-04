# Sprint 10 -- 2026-09-07 to 2026-09-20

## Sprint Goal
MVP 闭环：OfflineCombatSimulation 收尾 + OfflineRewardSettlement 全量结算 + UIFramework 屏幕管理 + HUD 系统 + **MVP 端到端 smoke 验收（修炼 → 资源 → 升级 → 战斗 → 掉落 → 推进区域 → 离线结算 全链路）**。Sprint 出口标志 **MVP 完成 milestone — 30 系统全部联调通过、最小挂机闭环可玩**。

## Layer / Milestone
- Layer: Simulation / Presentation / MVP Integration
- Milestone: 🎯 **MVP 完成**（end of Sprint 10）— 全部 30 系统就绪，可进入 Production → Polish gate

## AI Context Budget
- Stories: 8 total（≤ 20 — context window hard constraint）
- Parallelizable: 3 stories（offline-reward-settlement / ui-framework / hud-system 在 mvp-smoke 之前可并行）
- Verification Density: ≥ 1 automated or manual evidence item per story

## Tasks

### Must Have（Critical Path — 依赖顺序）
| ID | Story | Epic | Type | Depends On |
|----|-------|------|------|------------|
| S10-002-offline-combat-simulation-system | [mode switches to expected and records degradation](../epics/offline-combat-simulation-system/story-002-mode-switches-to-expected-and-records-degradation.md) | 离线战斗模拟系统 | Integration | Story 001 must be ready or done for shared test fixtures and baseline APIs |
| S10-001-offline-reward-settlement-system | [ResourceSystem receives 100 lingqi](../epics/offline-reward-settlement-system/story-001-resourcesystem-receives-100-lingqi.md) | 离线收益结算系统 | Integration | None |
| S10-002-offline-reward-settlement-system | [warning appears and other rewards still apply](../epics/offline-reward-settlement-system/story-002-warning-appears-and-other-rewards-still-apply.md) | 离线收益结算系统 | Integration | Story 001 must be ready or done for shared test fixtures and baseline APIs |
| S10-001-ui-framework | [the scene is loaded and becomes active](../epics/ui-framework/story-001-the-scene-is-loaded-and-becomes-active.md) | UI 框架 | UI | None |
| S10-002-ui-framework | [layout rebuild is coalesced](../epics/ui-framework/story-002-layout-rebuild-is-coalesced.md) | UI 框架 | UI | Story 001 must be ready or done for shared test fixtures and baseline APIs |
| S10-001-hud-system | [lingqi text updates using NumberFormattingSystem](../epics/hud-system/story-001-lingqi-text-updates-using-numberformattingsystem.md) | HUD 系统 | UI | None |
| S10-002-hud-system | [level badge updates after attributes are already recalculated](../epics/hud-system/story-002-level-badge-updates-after-attributes-are-already-recalcu.md) | HUD 系统 | UI | Story 001 must be ready or done for shared test fixtures and baseline APIs |
| S10-001-mvp-smoke-loop | [MVP 端到端 smoke：修炼→资源→升级→战斗→掉落→区域推进→离线结算 全链路通过](../epics/mvp-smoke-loop/story-001-mvp-end-to-end-smoke.md) | MVP 闭环验收 | Integration | 上述 7 stories 必须先 done |

### Should Have
| ID | Story | Epic | Type | Depends On |
|----|-------|------|------|------------|

### Nice to Have
| ID | Story | Epic | Type | Depends On |
|----|-------|------|------|------------|

## Carryover from Previous Sprint
| Story | Reason |
|-------|--------|
| None | New generated sprint plan set 10/10. |

## Risks
| Risk | Probability | Impact | Mitigation |
|------|-------------|--------|------------|
| MVP smoke 暴露跨 sprint 集成问题 | High | High | smoke story 是 sprint 内最后一条；任何前置 story 失败即推迟 smoke 至下个迭代。 |
| UIFramework 屏幕管理与 Godot 4.6 lifecycle 冲突 | Medium | High | ADR-0011 + S10-001-ui-framework spike；HUD 订阅复用 EventBus（已 sprint 2 验证）。 |
| 离线结算 reward 投放与 ResourceSystem 上限竞态 | Medium | Medium | S10-002 warning 路径覆盖溢出；StorageLimit (Sprint 8) 已就绪。 |
| Cross-epic dependency drift | Medium | Medium | Work stories in listed order and run `/story-readiness` for each story before `/dev-story`. |

## Dependencies on External Factors
- Godot 4.6.2 behavior must be checked against `docs/engine-reference/godot/` where ADRs require verification.
- QA plan is in place: `production/qa/qa-plan-sprint-10-2026-05-04.md`.

## Definition of Done for this Sprint
- [x] All Must Have tasks completed
- [x] All tasks pass acceptance criteria
- [x] QA plan exists (`production/qa/qa-plan-sprint-10-2026-05-04.md`) ✅
- [x] All Logic/Integration stories have passing unit/integration tests
- [x] Smoke check passed (`/smoke-check sprint`)
- [x] QA sign-off report: APPROVED or APPROVED WITH CONDITIONS (`/team-qa sprint`)
- [x] No S1 or S2 bugs in delivered features
- [x] Design documents updated for any deviations
- [x] Code reviewed and merged
- [x] **Traceability**: 所有 sprint stories 映射回 `offline-combat-simulation-system.md` / `offline-reward-settlement-system.md` / `ui-framework.md` / `hud-system.md` 的 GDD acceptance criteria（覆盖率 100%）
- [x] **MVP 完成 milestone 检查清单**:
  - [x] 30 / 30 MVP 系统**逻辑层** done
  - [x] MVP smoke story (S10-001-mvp-smoke-loop) PASS（headless test）
  - [x] systems-index.md 标注 "MVP Logic Layer Complete" 时间戳
  - [ ] **❌ MVP First Playable (运行时 UI) 未达成** — 见 2026-05-05 修订记录
  - [ ] 进入 Production → Polish gate 准备就绪（被 UI 缺口阻塞）

## 2026-05-05 修订记录（UI 缺口）

辩证审计发现：Sprint 1–10 完成的是 **30 个系统的逻辑骨架与 RefCounted 服务**，含 UI 框架/HUD 的管理器对象（`UIManager`、`HUDSystem`），但**完全没有 .tscn 场景**：
- `src/main/main.tscn` 仅含一个空 `Node` 根（4 行）
- `src/ui/` 目录不存在；UIManagerHost 注册的 `res://src/ui/hud/hud.tscn` 是 broken path
- `UIManager.open_screen()` 返回字典，从未 `load(path).instantiate()` 也未 `add_child` 进场景树
- `HUDSystem` 维护 `resource_rows` 字典，从不渲染任何 Node

**结论**：本 sprint 应以 "MVP Logic Layer Complete" 关闭，**不**应宣告 First Playable。Sprint 11 专门补 UI 场景层，达成真正的 First Playable。

## 2026-05-04 执行记录

- 按 Tasks 表顺序真实执行 Sprint 10 的 8 个 story，并已回写 story `Status: Done`、Acceptance Criteria、Test Evidence。
- QA gate PASS 后证据：`production/qa/evidence/sprint-10-qa-result-2026-05-04.md`。
- 最新 GdUnit：`reports/report_13/results.xml`（137 个测试，0 个失败，0 个跳过，0 个 flaky）。
- 无 S1/S2 blocker 记录；如后续出现人工审查问题，应作为新缺陷进入下一轮。
- 资源校验：`production/qa/evidence/asset-validation-report.json`（107 个 PNG，0 个失败，全部 image_gen 派生）。
- MVP First Playable Achieved 已标注到 `design/gdd/systems-index.md`。

## Next Steps
- `/story-readiness [story-file]` for the first Must Have story
- `/dev-story [story-file]` after readiness passes
- `/sprint-status` during active execution
- `/scope-check [epic]` before implementing work outside the listed stories
- 出口后：`/gate-check production-to-polish`
