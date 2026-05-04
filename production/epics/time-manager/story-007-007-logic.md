# Story 007: 静默忽略，无错误

> **Epic**: 时间管理器
> **Status**: Done
> **Layer**: Foundation
> **Type**: Logic
> **Manifest Version**: 2026-05-04

## Context

**GDD**: `design/gdd/time-manager.md`
**Requirement**: `TR-time-manager-001` — TimeManager owns real/game time, speed sources, freeze/unfreeze, save timestamp snapshots, and capped offline delta calculation.

**ADR Governing Implementation**: ADR-0003: 时间源与双时间体系
**ADR Decision Summary**: Implement `TimeManager` as an Autoload that owns a dual-time snapshot: real Unix time and derived game time. All gameplay timing uses `TimeManager`, never direct `_process(delta)` as authority. Online ticks use `get_game_delta_since`; offline settlement uses `min(real_now - exit_timestamp, MAX_OFFLINE_SECONDS)` with speed multiplier ignored.

**Engine**: Godot 4.6.2 | **Risk**: LOW
**Engine Notes**: ADR-0003 status is Accepted; verify any Godot 4.6.2 behavior named by the ADR before closing the story.

**Control Manifest Rules (this layer)**:
- Required: **Use `BigNumber` for all game absolute quantities** — source: ADR-0001
- Required: **Keep BigNumber arithmetic immutable; every operation returns a new instance** — source: ADR-0001
- Required: **Serialize BigNumber as `{"m": mantissa, "e": exponent}`** — source: ADR-0001
- Required: **Route cross-system notifications through EventBus exact subscriptions in production** — source: ADR-0002
- Forbidden: **Never store resources, attributes, damage, experience, or rewards as raw `int` / `float` absolute values** — source: ADR-0001
- Forbidden: **Never introduce GDExtension BigNumber before the GDScript performance gate fails with measured evidence** — source: ADR-0001
- Forbidden: **Never use EventBus prefix subscriptions for production UI/gameplay behavior** — source: ADR-0002
- Guardrail: **BigNumber**: 1000 instances × 50 operations must fit within a 16.6 ms frame before GDExtension is deferred long term — source: ADR-0001
- Guardrail: **EventBus**: typical frame cost target is <= 0.5 ms/frame — source: ADR-0002
- Guardrail: **TimeManager**: 1000 `get_game_time()` calls target <= 0.1 ms — source: ADR-0003

---

## Acceptance Criteria

*From GDD `design/gdd/time-manager.md`, scoped to this story:*

- [x] GIVEN: 移除从未注册的 source_id，**WHEN** 执行 `remove_speed_source("nonexistent")`，**THEN** 静默忽略，无错误

---

## Implementation Notes

*Derived from ADR-0003 Implementation Guidelines:*

- Must use `Time.get_unix_time_from_system()` as the authoritative real-time source.
- Must not use `_process(delta)` as the source of truth for idle progress or offline rewards.
- Must multiply online game time by registered speed sources.
- Must ignore speed multipliers for MVP offline reward time.
- Must clamp offline duration to `MAX_OFFLINE_SECONDS = 28800`.
- Must publish `time.frozen`, `time.unfrozen`, `time.speed_changed`, and `time.offline_delta` through EventBus.

---

## Out of Scope

- Story 001 covers the baseline contract for this epic; do not duplicate its setup work here.

---

## QA Test Cases

*Written at story creation. The developer implements against these cases.*

- **AC**: GIVEN: 移除从未注册的 source_id，**WHEN** 执行 `remove_speed_source("nonexistent")`，**THEN** 静默忽略，无错误
  - Given: 移除从未注册的 source_id
  - When: 执行 `remove_speed_source("nonexistent")`
  - Then: 静默忽略，无错误
  - Edge cases: boundary, invalid, missing-data, and repeat-run variants from the GDD edge-case section

---

## Test Evidence

**Story Type**: Logic
**Required evidence**:
- `tests/unit/time_manager/007-logic_test.gd` — must exist and pass

**Status**: [x] Executed 2026-05-04

---

## Dependencies

- Depends on: Story 001 must be ready or done for shared test fixtures and baseline APIs
- Unlocks: None

## 2026-05-04 Sprint Execution Evidence

- Sprint execution order: Sprint 3, story 1/20
- Sprint source: `production/sprints/sprint-3.md`
- QA plan: `production/qa/qa-plan-sprint-3-2026-05-04.md`
- Automated evidence: `reports/report_13/results.xml` (137 tests, 0 failures, 0 skipped, 0 flaky)
- QA gate evidence: `production/qa/evidence/sprint-3-qa-result-2026-05-04.md`
- Verdict: Done; acceptance criteria reviewed against implementation, runtime tests, and sprint QA plan evidence.
- QA-plan automated tests:
  - `tests/unit/time_manager/time_manager_logic_test.gd`
  - `tests/unit/number_formatting/number_formatter_test.gd`
  - `tests/performance/number_formatter_performance_test.gd`
  - `tests/unit/data_config/data_config_test.gd`
  - `tests/unit/formula_engine/formula_engine_test.gd`
