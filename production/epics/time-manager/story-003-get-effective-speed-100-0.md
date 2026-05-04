# Story 003: `get_effective_speed()` 返回 100.0（截断）

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

- [x] GIVEN: speed = 10.0x，**WHEN** 注册新来源使乘积超过 MAX_SPEED(100)，**THEN** `get_effective_speed()` 返回 100.0（截断）
- [x] GIVEN: 注册倍率为 0 或 -1 的来源，**WHEN** 执行 `add_speed_source()`，**THEN** 该来源倍率钳位到 1.0，打印警告
- [x] GIVEN: Running 状态，**WHEN** 调用 `freeze()`，**THEN** `get_game_time()` 停止增长，发布 `time.frozen` 事件

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
- Story 004 covers the next acceptance group in this epic.

---

## QA Test Cases

*Written at story creation. The developer implements against these cases.*

- **AC**: GIVEN: speed = 10.0x，**WHEN** 注册新来源使乘积超过 MAX_SPEED(100)，**THEN** `get_effective_speed()` 返回 100.0（截断）
  - Given: speed = 10.0x
  - When: 注册新来源使乘积超过 MAX_SPEED(100)
  - Then: `get_effective_speed()` 返回 100.0（截断）
  - Edge cases: boundary, invalid, missing-data, and repeat-run variants from the GDD edge-case section

- **AC**: GIVEN: 注册倍率为 0 或 -1 的来源，**WHEN** 执行 `add_speed_source()`，**THEN** 该来源倍率钳位到 1.0，打印警告
  - Given: 注册倍率为 0 或 -1 的来源
  - When: 执行 `add_speed_source()`
  - Then: 该来源倍率钳位到 1.0，打印警告
  - Edge cases: boundary, invalid, missing-data, and repeat-run variants from the GDD edge-case section

- **AC**: GIVEN: Running 状态，**WHEN** 调用 `freeze()`，**THEN** `get_game_time()` 停止增长，发布 `time.frozen` 事件
  - Given: Running 状态
  - When: 调用 `freeze()`
  - Then: `get_game_time()` 停止增长，发布 `time.frozen` 事件
  - Edge cases: boundary, invalid, missing-data, and repeat-run variants from the GDD edge-case section

---

## Test Evidence

**Story Type**: Integration
**Required evidence**:
- `tests/integration/time_manager/get-effective-speed-100-0_test.gd` — must exist and pass

**Status**: [x] Executed 2026-05-04

---

## Dependencies

- Depends on: Story 001 must be ready or done for shared test fixtures and baseline APIs
- Unlocks: Story 004

## 2026-05-04 Sprint Execution Evidence

- Sprint execution order: Sprint 2, story 17/20
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
