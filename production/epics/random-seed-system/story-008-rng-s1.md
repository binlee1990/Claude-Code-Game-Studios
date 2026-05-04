# Story 008: 模拟期间在线 RNG 仍为 S1，不受模拟调用影响

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

- [ ] GIVEN: 在线 RNG 状态为 S1，**WHEN** 启动离线模拟（使用状态副本），**THEN** 模拟期间在线 RNG 仍为 S1，不受模拟调用影响
- [ ] GIVEN: 数组 `[1, 2, 3, 4, 5]`，**WHEN** 以固定种子执行 `shuffle(COMBAT, array)`，**THEN** 返回一个排列，且以相同种子再次 shuffle 得到相同排列
- [ ] GIVEN: 空数组，**WHEN** 执行 `shuffle(COMBAT, [])`，**THEN** 返回空数组

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
- Story 009 covers the next acceptance group in this epic.

---

## QA Test Cases

*Written at story creation. The developer implements against these cases.*

- **AC**: GIVEN: 在线 RNG 状态为 S1，**WHEN** 启动离线模拟（使用状态副本），**THEN** 模拟期间在线 RNG 仍为 S1，不受模拟调用影响
  - Given: 在线 RNG 状态为 S1
  - When: 启动离线模拟（使用状态副本）
  - Then: 模拟期间在线 RNG 仍为 S1，不受模拟调用影响
  - Edge cases: boundary, invalid, missing-data, and repeat-run variants from the GDD edge-case section

- **AC**: GIVEN: 数组 `[1, 2, 3, 4, 5]`，**WHEN** 以固定种子执行 `shuffle(COMBAT, array)`，**THEN** 返回一个排列，且以相同种子再次 shuffle 得到相同排列
  - Given: 数组 `[1, 2, 3, 4, 5]`
  - When: 以固定种子执行 `shuffle(COMBAT, array)`
  - Then: 返回一个排列，且以相同种子再次 shuffle 得到相同排列
  - Edge cases: boundary, invalid, missing-data, and repeat-run variants from the GDD edge-case section

- **AC**: GIVEN: 空数组，**WHEN** 执行 `shuffle(COMBAT, [])`，**THEN** 返回空数组
  - Given: 空数组
  - When: 执行 `shuffle(COMBAT, [])`
  - Then: 返回空数组
  - Edge cases: boundary, invalid, missing-data, and repeat-run variants from the GDD edge-case section

---

## Test Evidence

**Story Type**: Integration
**Required evidence**:
- `tests/integration/random_seed/rng-s1_test.gd` — must exist and pass

**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: Story 001 must be ready or done for shared test fixtures and baseline APIs
- Unlocks: Story 009
