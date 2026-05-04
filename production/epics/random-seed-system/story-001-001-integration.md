# Story 001: 获得同一个全局单例实例

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

- [ ] GIVEN: RNGManager 作为 Autoload 加载，**WHEN** 任意系统访问 `RNGManager`，**THEN** 获得同一个全局单例实例
- [ ] GIVEN: 新游戏开始，**WHEN** RNGManager 初始化，**THEN** 自动生成 64 位主种子，并创建 COMBAT、LOOT、EVENT、AFFIX 四个核心流
- [ ] GIVEN: 相同的主种子值 12345，**WHEN** 连续两次调用 `set_master_seed(12345)`，**THEN** 所有核心流产生完全相同的随机序列

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

- **AC**: GIVEN: RNGManager 作为 Autoload 加载，**WHEN** 任意系统访问 `RNGManager`，**THEN** 获得同一个全局单例实例
  - Given: RNGManager 作为 Autoload 加载
  - When: 任意系统访问 `RNGManager`
  - Then: 获得同一个全局单例实例
  - Edge cases: boundary, invalid, missing-data, and repeat-run variants from the GDD edge-case section

- **AC**: GIVEN: 新游戏开始，**WHEN** RNGManager 初始化，**THEN** 自动生成 64 位主种子，并创建 COMBAT、LOOT、EVENT、AFFIX 四个核心流
  - Given: 新游戏开始
  - When: RNGManager 初始化
  - Then: 自动生成 64 位主种子，并创建 COMBAT、LOOT、EVENT、AFFIX 四个核心流
  - Edge cases: boundary, invalid, missing-data, and repeat-run variants from the GDD edge-case section

- **AC**: GIVEN: 相同的主种子值 12345，**WHEN** 连续两次调用 `set_master_seed(12345)`，**THEN** 所有核心流产生完全相同的随机序列
  - Given: 相同的主种子值 12345
  - When: 连续两次调用 `set_master_seed(12345)`
  - Then: 所有核心流产生完全相同的随机序列
  - Edge cases: boundary, invalid, missing-data, and repeat-run variants from the GDD edge-case section

---

## Test Evidence

**Story Type**: Integration
**Required evidence**:
- `tests/integration/random_seed/001-integration_test.gd` — must exist and pass

**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: None
- Unlocks: Story 002
