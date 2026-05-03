# Targeted Design Review: 2026-05-04

> **Skill**: `.claude/skills/design-review`
> **Mode**: targeted lean pass
> **Scope**: systems that still had deferred or stale review state after the all-GDD cleanup
> **Verdict**: APPROVED for this pass

## Newly Completed GDDs

The 15 batch-authored GDDs below were reviewed individually for required section completeness, dependency references, acceptance criteria, stale placeholders, and cross-GDD contract conflicts. No blocking design issues remained after the consistency fixes.

| System | File | Verdict |
|--------|------|---------|
| 自动产出系统 | `auto-production-system.md` | APPROVED |
| 战斗计算器 | `combat-calculator.md` | APPROVED |
| 修炼系统 | `cultivation-system.md` | APPROVED |
| 敌人数据库 | `enemy-database.md` | APPROVED |
| HUD 系统 | `hud-system.md` | APPROVED |
| 挂机探索系统 | `idle-exploration-system.md` | APPROVED |
| 掉落系统 | `loot-system.md` | APPROVED |
| 地图推进系统 | `map-progression-system.md` | APPROVED |
| 离线战斗模拟系统 | `offline-combat-simulation-system.md` | APPROVED |
| 离线收益结算系统 | `offline-reward-settlement-system.md` | APPROVED |
| 离线模拟内核 | `offline-simulation-core.md` | APPROVED |
| 半自动战斗系统 | `semi-auto-combat-system.md` | APPROVED |
| 存储上限系统 | `storage-limit-system.md` | APPROVED |
| UI 框架 | `ui-framework.md` | APPROVED |
| 区域系统 | `zone-system.md` | APPROVED |

## Additional Focused Repairs

| File | Reason | Result |
|------|--------|--------|
| `enemy-database.md` | Enemy runtime HP ownership was ambiguous. | Clarified that MVP enemy current HP remains combat-local and is not registered into AttributeSystem. |
| `event-bus.md` | HUD subscription wording conflicted with prefix subscription semantics. | Production HUD now uses precise resource event names; prefix watch is debug-oriented. |
| `formula-engine.md` | Dependency note still described a future systems-index update. | Reframed as current hard/soft dependency boundary. |
| `level-system.md` | Historical HUD/UI review text was stale. | Removed obsolete "not designed" references and kept only real tuning risk. |
| `number-formatting-system.md` | Used `## Detailed Rules` instead of project GDD standard. | Normalized to `## Detailed Design`. |
| `save-system.md` | Quick reference omitted EventBus. | Added EventBus dependency. |
| `time-manager.md` | Stale note said systems-index still needed an update. | Replaced with current bidirectional consistency note. |

## Evidence

- 30 / 30 system GDDs have all required sections.
- 0 remaining `Deferred` review markers in system GDDs.
- 0 duplicate `referenced_by` lists in `design/registry/entities.yaml`.
- 0 active item categories outside ResourceSystem's enum.
- `systems-index.md` reviewed count refreshed to 30.

## Remaining Non-Blocking Risks

The pass leaves performance and tuning questions in place where implementation evidence is still required. Those items should be resolved during prototype or implementation, not by speculative GDD wording.
