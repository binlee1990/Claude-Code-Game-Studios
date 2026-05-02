# Retrospective Template

> **Version**: v1.0
> **Purpose**: 每个 sprint 结束后自动触发的 retrospective 模板
> **Trigger**: `/sprint-done` 或 sprint status 变更时自动生成

---

## Quick Start

```bash
# 自动生成 retrospective（从 sprint plan + git log + status yaml）
cp production/templates/retrospective-template.md production/reviews/retrospective-sprint-NNN.md
# 然后填入实际数据
```

---

## Template

```markdown
# Sprint-NNN Retrospective

> **Sprint**: [NNN]
> **Date**: [YYYY-MM-DD]
> **Goal**: [sprint goal from sprint-NNN.md]
> **Outcome**: [COMPLETE / PARTIAL / FAILED]

---

## Story Completion

| Priority | Planned | Done | Rate |
|----------|---------|------|------|
| Must Have | [N] | [N] | [%] |
| Should Have | [N] | [N] | [%] |
| Nice to Have | [N] | [N] | [%] |
| **Total** | **[N]** | **[N]** | **[%]** |

---

## Velocity

| Metric | Value |
|--------|-------|
| Stories completed | [N] |
| New source lines | [N] |
| New test lines | [N] |
| Test delta | [baseline] → [new baseline] (+N) |
| godot --check-only | [exit 0 / N errors] |

---

## What Went Well

1. [item]
2. [item]

---

## What Didn't Go Well

1. [item]
2. [item]

---

## Blockers Encountered

| Blocker | Severity | Resolution | Time Cost |
|---------|----------|------------|-----------|
| [desc] | [LOW/MED/HIGH] | [how resolved] | [impact] |

---

## Risks That Materialized

| Risk (from sprint plan) | Impact | Mitigation Effective? |
|--------------------------|--------|-----------------------|
| [desc] | [actual impact] | [YES / PARTIAL / NO] |

---

## Deviations from Plan

| Deviation | Reason | Approved? |
|-----------|--------|-----------|
| [desc] | [why] | [YES / NO] |

---

## Lessons Learned

1. [actionable lesson]
2. [actionable lesson]

---

## Action Items for Next Sprint

| # | Action | Owner | Sprint |
|---|--------|-------|--------|
| 1 | [action] | [owner] | Sprint-NNN+1 |
| 2 | [action] | [owner] | Sprint-NNN+1 |

---

## Test Coverage Review

| System | Tests Added | Coverage Change | Gaps? |
|--------|-------------|-----------------|-------|
| [system] | +N | [baseline] → [new] | [YES/NO] |

---

## Architecture Review

| ADR | Created? | Updated? | Notes |
|-----|----------|----------|-------|
| [ADR-NNN] | YES/NO | YES/NO | [notes] |
```

---

## Auto-Generation Rules

以下字段可从 sprint plan + status yaml 自动填充：

| Field | Source |
|-------|--------|
| Sprint number, goal, date | `sprint-NNN.md` frontmatter |
| Story completion table | `sprint-status.yaml` story statuses |
| Test delta | `sprint-status.yaml` baseline → new baseline |
| godot --check-only | CI output or `active.md` |
| Velocity (stories, lines, tests) | git diff --stat + test manifest count |

以下字段需人工/Agent 填充：
- What Went Well / Didn't Go Well
- Blockers encountered
- Lessons learned
- Action items

---

## Integration with Sprint Workflow

1. **Sprint start**: N/A (retro 在 sprint 结束时触发)
2. **Sprint end**: `/sprint-done` 触发本模板自动生成
3. **Continuous**: 每个 story done 时记录 blocker/time 到 sprint-status.yaml metadata
4. **Storage**: 写入 `production/reviews/retrospective-sprint-NNN.md`

---

## Process Codification

本模板是 Sprint-010 PROCESS-001 的交付物。后续 sprint 的 `/sprint-plan` 和 `/sprint-done` skill 应：

1. `/sprint-plan`: 创建 sprint plan 时自动写入 retro 占位骨架
2. `/sprint-done`: sprint 完成时自动填充已知字段，标记为 DRAFT，等待人工/Agent 补充主观部分
3. 跨 sprint 趋势数据写入 `production/sprint-status.yaml` 的 `trends` 字段
