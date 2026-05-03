# GDD Cross Review: 2026-05-04

> **Skill**: `.claude/skills/review-all-gdds`
> **Scope**: all 30 MVP system GDDs under `design/gdd/`
> **Verdict**: APPROVED WITH WATCHLIST

## Review Summary

本轮复审覆盖 30 个系统 GDD、`systems-index.md`、`design/registry/entities.yaml` 与 `production/session-state/active.md`。目标是清理低价值 Open Questions、修复跨系统事实冲突，并刷新设计审查状态。

| Check | Result |
|-------|--------|
| System GDD count | 30 |
| Required core sections | PASS — all 30 contain Overview, Player Fantasy, Detailed Design, Formulas, Edge Cases, Dependencies, Tuning Knobs, Acceptance Criteria |
| Deferred review markers | PASS — 0 remaining |
| Registry duplicate `referenced_by` | PASS — 0 remaining |
| Registry item category enum | PASS — active item categories match ResourceSystem enum |
| Systems index reviewed count | PASS — 30 / 30 |

## Findings Fixed

| ID | Severity | Area | Resolution |
|----|----------|------|------------|
| CR-01 | BLOCKING | Registry resource/material categories | Replaced stale `regenerative_resource`, `progress_resource`, `crafting_material` values with `regenerative`, `progress`, `material` to match ResourceSystem. |
| CR-02 | IMPORTANT | EventBus and HUD subscription contract | Reworded HUD integration to use exact `resource.{id}.changed` subscriptions for production UI; prefix subscriptions remain debug tooling behavior. |
| CR-03 | IMPORTANT | TimeManager and SaveSystem dependency freshness | Removed stale TimeManager note saying systems-index still needed update; added EventBus to SaveSystem quick reference deps. |
| CR-04 | IMPORTANT | FormulaEngine dependency note | Replaced stale "suggest updating systems-index" language with the current distinction between architectural prerequisites and Post-MVP DataConfig formula source. |
| CR-05 | IMPORTANT | Systems index dependency map | Synced LevelSystem dependency map entry with the main systems table. |
| CR-06 | MAINTENANCE | Low-value Open Questions | Removed resolved/noisy Open Questions sections from 16 GDDs and reduced the remaining sections to real implementation, tuning, or Post-MVP risks. |

## Scenario Walkthroughs

| Scenario | Result |
|----------|--------|
| Offline return and settlement | PASS — TimeManager, OfflineSimulationCore, OfflineCombatSimulation, OfflineRewardSettlement, ResourceSystem, EventBus, SaveSystem dependencies now align. |
| Online combat win and reward grant | PASS — SemiAutoCombat, CombatCalculator, EnemyDatabase, LootSystem, ItemMaterial, ResourceSystem, LevelSystem boundaries remain coherent. |
| Level-up and map progression | PASS — LevelSystem dependency map and MapProgression requirements now agree; remaining Lv150-200 growth feel is retained as tuning watchlist. |
| Debug `event watch resource` | PASS — DebugConsole can use prefix watch for diagnostics without implying HUD production prefix subscriptions. |
| Save load and UI refresh | PASS — SaveSystem and LevelSystem describe `save.loaded` restore semantics without unnecessary `level.changed` / `realm.advanced` spam. |

## Watchlist

These are intentionally retained because they are real implementation or tuning risks, not meaningless questions:

- BigNumber and RNG performance thresholds still need profiling once GDScript implementations exist.
- DebugConsole RichTextLabel history and lazy BigNumber payload formatting need runtime measurement.
- LevelSystem Lv150-200 growth feel needs tuning sign-off before content lock.
- ItemMaterial Alpha expansion questions remain because MVP data intentionally contains only the five resource/material IDs.
- SaveSystem anti-cheat/checksum and provider restore ordering remain implementation decisions.

## Status Refresh

- `systems-index.md` now reports `Design docs reviewed | 30`.
- The 15 previously deferred batch GDDs now carry a 2026-05-04 lean design-review approval marker.
- Historical deleted review logs were not restored; this report records the fresh 2026-05-04 pass instead.
