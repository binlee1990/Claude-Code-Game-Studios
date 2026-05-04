# Story 001: 返回当前 Unix 时间戳（精度 ±1 秒）

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

- [x] GIVEN: TimeManager 作为 Autoload 加载，**WHEN** 调用 `get_real_time()`，**THEN** 返回当前 Unix 时间戳（精度 ±1 秒）
- [x] GIVEN: speed = 2.0，**WHEN** 真实时间经过 60 秒，**THEN** `get_game_delta_since(last_game_time)` 返回约 120.0 秒
- [x] GIVEN: speed = 1.0（无加速），**WHEN** 真实时间经过 60 秒，**THEN** `get_game_delta_since(last_game_time)` 返回约 60.0 秒

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

- Story 002 covers the next acceptance group in this epic.

---

## QA Test Cases

*Written at story creation. The developer implements against these cases.*

- **AC**: GIVEN: TimeManager 作为 Autoload 加载，**WHEN** 调用 `get_real_time()`，**THEN** 返回当前 Unix 时间戳（精度 ±1 秒）
  - Given: TimeManager 作为 Autoload 加载
  - When: 调用 `get_real_time()`
  - Then: 返回当前 Unix 时间戳（精度 ±1 秒）
  - Edge cases: boundary, invalid, missing-data, and repeat-run variants from the GDD edge-case section

- **AC**: GIVEN: speed = 2.0，**WHEN** 真实时间经过 60 秒，**THEN** `get_game_delta_since(last_game_time)` 返回约 120.0 秒
  - Given: speed = 2.0
  - When: 真实时间经过 60 秒
  - Then: `get_game_delta_since(last_game_time)` 返回约 120.0 秒
  - Edge cases: boundary, invalid, missing-data, and repeat-run variants from the GDD edge-case section

- **AC**: GIVEN: speed = 1.0（无加速），**WHEN** 真实时间经过 60 秒，**THEN** `get_game_delta_since(last_game_time)` 返回约 60.0 秒
  - Given: speed = 1.0（无加速）
  - When: 真实时间经过 60 秒
  - Then: `get_game_delta_since(last_game_time)` 返回约 60.0 秒
  - Edge cases: boundary, invalid, missing-data, and repeat-run variants from the GDD edge-case section

---

## Test Evidence

**Story Type**: Integration
**Required evidence**:
- `tests/integration/time_manager/unix-1_test.gd` — must exist and pass

**Status**: [x] Executed 2026-05-04

---

## Dependencies

- Depends on: None
- Unlocks: Story 002

## 2026-05-04 Sprint Execution Evidence

- Sprint execution order: Sprint 2, story 15/20
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
