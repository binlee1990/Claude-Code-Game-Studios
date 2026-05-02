# Sprint-010 — 治理收口 + 里程碑审查

> **Status**: COMPLETE
> **Start**: 2026-05-17
> **End**: 2026-05-21
> **Goal**: 关闭 9 个 sprint 累积的 governance/QA/process 债务，为 Alpha 阶段提供干净的启动基线
> **Capacity**: AI-native（无人类时间估算）
> **Generated**: 2026-05-02

## Context

Sprint-009 完成 Vertical Slice 层 4 系统（fog/bond-combo/difficulty/boss），post-audit hardening 后 1037/1037 PASS。
19 个 epic 全部 Complete。项目实质上已达到 Production→Polish 过渡条件。

但 governance 层滞后于代码层：
- 9 个 sprint 无一做过 retrospective
- 无 formal changelog
- 无 launch checklist
- gate-check（2026-05-01）标记 CONCERNS，6 个 FAIL 项未解决
- milestone review 未更新（仍是 Sprint-008 基线）
- regression suite、test helpers、performance tests 目录不存在

**Sprint-010 不写任何新功能代码。** 本 sprint 只产出文档、流程、测试基础设施。

**排除范围**: Alpha epic 实现代码、Ch.4 内容、新 ADR、NG+ 选择器。

## Story Map

### Must Have（7 stories）

| ID | Story | Type | Deps | Verification |
|----|-------|------|------|-------------|
| RETRO-001 | Sprint-001~009 retrospective batch（1 份综合 retrospective doc，覆盖 9 sprint 的 velocity/blocker/pattern/actionable insights） | Governance | — | `production/reviews/retrospective-sprint-001-009.md` 存在，含 per-sprint 摘要 + 跨 sprint 趋势分析 |
| GATE-001 | Production→Polish gate re-check（重新评估 2026-05-01 gate-check 的 6 FAIL → 修复后状态） | Review | Sprint-009 verified | `production/reviews/gate-check-production-to-polish-2026-05-17.md` verdict PASS 或列出剩余精确 blockers |
| MILESTONE-001 | Milestone review 更新（VS Complete, 19 epics, 1037 tests, Post-Sprint-009 state） | Review | RETRO-001 | `production/reviews/milestone-review-vs-complete-2026-05-17.md` 存在 |
| CHANGELOG-001 | Internal + player-facing changelog（从 9 sprint 的 git log + sprint plans 生成） | Documentation | — | `production/changelog-internal.md` + `production/changelog-player.md` 存在 |
| REGRESSION-001 | Regression suite 创建 + 全量回归跑（GDD critical path → test 映射，覆盖固定 bug 的回测） | QA | 1037 PASS baseline | `tests/regression-suite.md` 存在，全量 GUT 仍然 ≥1037 PASS |
| TEST-HELPERS-001 | Test helpers scaffold（assertion utilities, factory functions, mock objects per 项目系统） | QA | — | `tests/helpers/` 目录存在，≥3 个 helper 文件，现有测试可 import 不报错 |
| ARCH-SYNC-001 | Post-Sprint-009 architecture review sync（ADR-010~013 实现后对照，traceability matrix 更新） | Governance | Sprint-009 | `production/reviews/architecture-review-2026-05-17.md` 存在 |

### Should Have（3 stories）

| ID | Story | Type | Deps | Verification |
|----|-------|------|------|-------------|
| LAUNCH-001 | Launch checklist scaffold（code/content/store/marketing/community/infrastructure/legal 全部门 readiness） | Documentation | — | `production/launch-checklist.md` 存在，7 个部门 checklist 骨架完整 |
| PERF-SCAFFOLD-001 | Performance test scaffold + baseline（tests/performance/ 目录 + 首个 frame-time baseline test） | QA | — | `tests/performance/` 目录存在，≥1 个 perf test，可 GUT 执行 |
| DESIGN-REVIEW-BATCH-001 | Design review batch for untracked systems（对准 2026-05-01 gate-check FAIL 项：per-system 独立 design review） | Governance | — | `production/reviews/design-review-batch-2026-05-17.md` 存在，覆盖 ≥5 个系统 |

### Nice to Have（2 stories）

| ID | Story | Type | Deps | Verification |
|----|-------|------|------|-------------|
| TEST-GAP-001 | BOSS-002 standalone test（BossActionPattern 独立单测，关闭 Sprint-009 遗留的部分覆盖） | Logic | BOSS-002 | `tests/unit/boss/boss_action_pattern_test.gd` ≥10 tests, GUT PASS |
| PROCESS-001 | Retrospective process codification（retro 模板 + sprint-plan / sprint-status 自动 retro 触发规则） | Governance | RETRO-001 | `production/templates/retrospective-template.md` 存在，sprint-plan skill 含 retro trigger |

## Verification Gates

| Gate | Threshold |
|------|-----------|
| GUT runner | ≥1037 PASS（不降基线） |
| godot --check-only | 退出码 0 |
| Windows export | 退出码 0 |
| Gate re-check verdict | PASS 或 ≤2 CONCERNS（从当前 6 FAIL 收敛） |
| Regression suite completeness | 覆盖 ≥60% GDD critical paths |
| Changelog completeness | 覆盖 ≥80% 已完成 story IDs |

## Risk Assessment

| Risk | Severity | Mitigation |
|------|----------|------------|
| Retrospective batch 质量取决于 git log/sprint plan 完整性 | LOW | 9 sprint 的 sprint-*.md 和 sprint-status.yaml 记录完整，可机械化生成 |
| Gate re-check 可能仍然 CONCERNS（人工签收/UX review 需真人） | LOW | 区分 AI-blocking vs human-only FAIL，前者全部修复，后者明确标注为 release waiver |
| Test helpers 可能被后续 sprint 的代码变更破坏 | LOW | 放在 tests/helpers/ 独立目录，不耦合业务代码 |
| Launch checklist 7 部门中有 5 个不适用于 solo indie dev | LOW | 标注 "indie scope exempt"，仅填写适用的 code/community/infrastructure |

## Out of Scope

- Alpha epic 创建或实现（event/new-game-plus/hp/chapter-04）
- Ch.4 内容规划
- ADR-014+ 新架构决策
- NG+ 难度倍率选择器
- MAN-* 人工队列（仍在 sprint-人工.md 管理）
- Visual polish / BGM / 截图签收
- 新增 gameplay feature
