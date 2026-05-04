# Story 010: 总 RNG 调用耗时占帧预算 < 1%

> **Epic**: 随机数与种子系统
> **Status**: Ready
> **Layer**: Foundation
> **Type**: Integration
> **Manifest Version**: 2026-05-04

## Context

**GDD**: `design/gdd/random-seed-system.md`
**Requirement**: `TR-rng-001` — RNGManager provides deterministic master-seed and multi-stream random services for combat, loot, events, affixes, saves, and offline simulation.

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

*From GDD `design/gdd/random-seed-system.md`, scoped to this story:*

- [ ] GIVEN: 单流每帧调用 100 次 `rand_bool`，**WHEN** 在 60fps 下运行 1 小时，**THEN** 总 RNG 调用耗时占帧预算 < 1%
- [ ] GIVEN: 权重数组长度 1024，**WHEN** 执行 `weighted_pick`，**THEN** 单次调用耗时 < 0.1 ms
- [ ] GIVEN: 存档中包含旧版本已删除的流名称，**WHEN** `load_states()` 执行，**THEN** 静默恢复该流状态，不报错

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

---

## QA Test Cases

*Written at story creation. The developer implements against these cases.*

- **AC**: GIVEN: 单流每帧调用 100 次 `rand_bool`，**WHEN** 在 60fps 下运行 1 小时，**THEN** 总 RNG 调用耗时占帧预算 < 1%
  - Given: 单流每帧调用 100 次 `rand_bool`
  - When: 在 60fps 下运行 1 小时
  - Then: 总 RNG 调用耗时占帧预算 < 1%
  - Edge cases: boundary, invalid, missing-data, and repeat-run variants from the GDD edge-case section

- **AC**: GIVEN: 权重数组长度 1024，**WHEN** 执行 `weighted_pick`，**THEN** 单次调用耗时 < 0.1 ms
  - Given: 权重数组长度 1024
  - When: 执行 `weighted_pick`
  - Then: 单次调用耗时 < 0.1 ms
  - Edge cases: boundary, invalid, missing-data, and repeat-run variants from the GDD edge-case section

- **AC**: GIVEN: 存档中包含旧版本已删除的流名称，**WHEN** `load_states()` 执行，**THEN** 静默恢复该流状态，不报错
  - Given: 存档中包含旧版本已删除的流名称
  - When: `load_states()` 执行
  - Then: 静默恢复该流状态，不报错
  - Edge cases: boundary, invalid, missing-data, and repeat-run variants from the GDD edge-case section

---

## Test Evidence

**Story Type**: Integration
**Required evidence**:
- `tests/integration/random_seed/rng-1_test.gd` — must exist and pass

**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: Story 001 must be ready or done for shared test fixtures and baseline APIs
- Unlocks: None
