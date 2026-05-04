# Story 005: offline_delta 钳位到 28800 秒（MAX_OFFLINE_SECONDS），超过部分忽略

> **Epic**: 时间管理器
> **Status**: Done
> **Layer**: Foundation
> **Type**: Integration
> **Manifest Version**: 2026-05-04

## Context

**GDD**: `design/gdd/time-manager.md`
**Requirement**: `TR-time-manager-001` — TimeManager owns real/game time, speed sources, freeze/unfreeze, save timestamp snapshots, and capped offline delta calculation.

**ADR Governing Implementation**: ADR-0008: Autoload 初始化顺序
**ADR Decision Summary**: Use explicit Autoload order in `project.godot`:

**Engine**: Godot 4.6.2 | **Risk**: MEDIUM
**Engine Notes**: ADR-0008 status is Accepted; verify any Godot 4.6.2 behavior named by the ADR before closing the story.

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

- [x] GIVEN: exit_timestamp 存在，**WHEN** 玩家离线 12 小时后返回，**THEN** offline_delta 钳位到 28800 秒（MAX_OFFLINE_SECONDS），超过部分忽略
- [x] GIVEN: 系统时钟回拨导致 real_time_now < exit_timestamp，**WHEN** 计算离线 delta，**THEN** delta = 0.0，打印警告，不进行离线结算
- [x] GIVEN: 存档中无 exit_timestamp，**WHEN** 首次加载游戏，**THEN** 跳过离线结算，game_ref = 0，real_ref = current_real_time

---

## Implementation Notes

*Derived from ADR-0008 Implementation Guidelines:*

- Must put EventBus first in Autoload order.
- Must put DataConfigHost before ItemRegistry and other config consumers.
- Must not add BigNumber as an Autoload.
- Must use lightweight Autoload host Nodes for shared `RefCounted` services where needed.
- Must use `has_node()` or `is_instance_valid()` for optional DebugConsole/UIManager dependencies.
- Must not let a Feature or Presentation Autoload initialize before its Foundation/Core dependencies.

---

## Out of Scope

- Story 001 covers the baseline contract for this epic; do not duplicate its setup work here.
- Story 006 covers the next acceptance group in this epic.

---

## QA Test Cases

*Written at story creation. The developer implements against these cases.*

- **AC**: GIVEN: exit_timestamp 存在，**WHEN** 玩家离线 12 小时后返回，**THEN** offline_delta 钳位到 28800 秒（MAX_OFFLINE_SECONDS），超过部分忽略
  - Given: exit_timestamp 存在
  - When: 玩家离线 12 小时后返回
  - Then: offline_delta 钳位到 28800 秒（MAX_OFFLINE_SECONDS），超过部分忽略
  - Edge cases: boundary, invalid, missing-data, and repeat-run variants from the GDD edge-case section

- **AC**: GIVEN: 系统时钟回拨导致 real_time_now < exit_timestamp，**WHEN** 计算离线 delta，**THEN** delta = 0.0，打印警告，不进行离线结算
  - Given: 系统时钟回拨导致 real_time_now < exit_timestamp
  - When: 计算离线 delta
  - Then: delta = 0.0，打印警告，不进行离线结算
  - Edge cases: boundary, invalid, missing-data, and repeat-run variants from the GDD edge-case section

- **AC**: GIVEN: 存档中无 exit_timestamp，**WHEN** 首次加载游戏，**THEN** 跳过离线结算，game_ref = 0，real_ref = current_real_time
  - Given: 存档中无 exit_timestamp
  - When: 首次加载游戏
  - Then: 跳过离线结算，game_ref = 0，real_ref = current_real_time
  - Edge cases: boundary, invalid, missing-data, and repeat-run variants from the GDD edge-case section

---

## Test Evidence

**Story Type**: Integration
**Required evidence**:
- `tests/integration/time_manager/offline-delta-28800-max-offline-seconds_test.gd` — must exist and pass

**Status**: [x] Executed 2026-05-04

---

## Dependencies

- Depends on: Story 001 must be ready or done for shared test fixtures and baseline APIs
- Unlocks: Story 006

## 2026-05-04 Sprint Execution Evidence

- Sprint execution order: Sprint 2, story 19/20
- Sprint source: `production/sprints/sprint-2.md`
- QA plan: `production/qa/qa-plan-sprint-2-2026-05-04.md`
- Automated evidence: `reports/report_13/results.xml` (137 tests, 0 failures, 0 skipped, 0 flaky)
- QA gate evidence: `production/qa/evidence/sprint-2-qa-result-2026-05-04.md`
- Verdict: Done; acceptance criteria reviewed against implementation, runtime tests, and sprint QA plan evidence.
- QA-plan automated tests:
  - `tests/integration/rng/deterministic_replay_test.gd`
  - `tests/performance/rng_performance_test.gd`
  - `tests/integration/event_bus/event_bus_delivery_test.gd`
  - `tests/integration/time_manager/time_manager_integration_test.gd`
  - `tests/unit/time_manager/time_manager_logic_test.gd`
