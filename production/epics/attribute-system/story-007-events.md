# Story 007: Events

> **Epic**: 属性系统
> **Status**: Done
> **Layer**: Core Gameplay
> **Type**: UI
> **Manifest Version**: 2026-05-04

## Context

**GDD**: `design/gdd/attribute-system.md`
**Requirement**: `TR-attribute-system-001` — AttributeSystem owns entity attribute base values, final-value queries through ModifierEngine, events, snapshot, and restore.

**ADR Governing Implementation**: ADR-0002: 事件总线架构
**ADR Decision Summary**: Use a global `EventBus` Autoload Node with string event names and `Dictionary` payloads. The bus dispatches events synchronously in the current frame. Exact subscriptions are the production path. Prefix pattern subscriptions exist only for debug tooling such as `event watch resource`. Coalesced events are allowed only for display refreshes where latest-state wins.

**Engine**: Godot 4.6.2 | **Risk**: HIGH
**Engine Notes**: ADR-0002 status is Accepted; verify any Godot 4.6.2 behavior named by the ADR before closing the story.

**Control Manifest Rules (this layer)**:
- Required: **Use JSON files under `res://assets/data/` as the MVP configuration source** — source: ADR-0005
- Required: **Keep DataConfig schema-agnostic; consumers parse BigNumber strings themselves** — source: ADR-0005
- Required: **Keep all MVP config tables resident in DataConfig memory after startup load** — source: ADR-0005
- Required: **Use SaveManager provider callbacks by namespace for persistence** — source: ADR-0006
- Forbidden: **Never use Godot Resource files as the MVP content format** — source: ADR-0005
- Forbidden: **Never write runtime player state through DataConfig** — source: ADR-0005
- Forbidden: **Never make SaveManager import or understand concrete system state types** — source: ADR-0006
- Guardrail: **DataConfig**: MVP load target <= 100 ms and cache <= 5 MB — source: ADR-0005
- Guardrail: **SaveManager**: MVP save/load target <= 20 ms and save object <= 50 KB — source: ADR-0006
- Guardrail: **ModifierEngine**: cached 1000 `get_multiplier()` calls target <= 1 ms — source: ADR-0007

---

## Acceptance Criteria

*From GDD `design/gdd/attribute-system.md`, scoped to this story:*

- [x] GIVEN: `"player"` 已注册，base_atk = 100，**WHEN** `set_base("player", "atk", BigNumber.from_int(150))`，**THEN** EventBus 发布一次 `attribute.player.atk.base_changed`，payload `{entity_id:"player", attr_id:"atk", old_value:100, new_value:150, delta:50}`
- [x] GIVEN: HUD 仅订阅 `attribute.player.atk.base_changed`，**WHEN** `set_base("enemy_001", "atk", ...)` 同时被调用，**THEN** HUD 不收到敌人 atk 事件
- [x] GIVEN: `register_entity("player", ...)` 时初始 base 写入，**WHEN** 注册流程，**THEN** **不**发布 `base_changed` 事件（视为静态初始化）
- [x] GIVEN: `"enemy_001"` 已注册，**WHEN** `unregister_entity("enemy_001")`，**THEN** 仅发布一条 `attribute.enemy_001.unregistered` 事件，不发逐属性删除事件

---

## Implementation Notes

*Derived from ADR-0002 Implementation Guidelines:*

- Must define event names as constants; production code must not use untracked magic strings.
- Must use exact subscriptions for production UI and gameplay consumers.
- Must restrict `subscribe_pattern` to DebugConsole and similar diagnostics.
- Must reject empty prefix pattern subscriptions.
- Must validate `Callable.is_valid()` before delivery and remove invalid callables.
- Must defer subscribe/unsubscribe mutations until after current dispatch completes.

---

## Out of Scope

- Story 001 covers the baseline contract for this epic; do not duplicate its setup work here.
- Story 008 covers the next acceptance group in this epic.

---

## QA Test Cases

*Written at story creation. The developer implements against these cases.*

- **Manual check**: GIVEN: `"player"` 已注册，base_atk = 100，**WHEN** `set_base("player", "atk", BigNumber.from_int(150))`，**THEN** EventBus 发布一次 `attribute.player.atk.base_changed`，payload `{entity_id:"player", attr_id:"atk", old_value:100, new_value:150, delta:50}`
  - Setup: `"player"` 已注册，base_atk = 100
  - Verify: `set_base("player", "atk", BigNumber.from_int(150))`
  - Pass condition: EventBus 发布一次 `attribute.player.atk.base_changed`，payload `{entity_id:"player", attr_id:"atk", old_value:100, new_value:150, delta:50}`

- **Manual check**: GIVEN: HUD 仅订阅 `attribute.player.atk.base_changed`，**WHEN** `set_base("enemy_001", "atk", ...)` 同时被调用，**THEN** HUD 不收到敌人 atk 事件
  - Setup: HUD 仅订阅 `attribute.player.atk.base_changed`
  - Verify: `set_base("enemy_001", "atk", ...)` 同时被调用
  - Pass condition: HUD 不收到敌人 atk 事件

- **Manual check**: GIVEN: `register_entity("player", ...)` 时初始 base 写入，**WHEN** 注册流程，**THEN** **不**发布 `base_changed` 事件（视为静态初始化）
  - Setup: `register_entity("player", ...)` 时初始 base 写入
  - Verify: 注册流程
  - Pass condition: 不发布 `base_changed` 事件（视为静态初始化）

- **Manual check**: GIVEN: `"enemy_001"` 已注册，**WHEN** `unregister_entity("enemy_001")`，**THEN** 仅发布一条 `attribute.enemy_001.unregistered` 事件，不发逐属性删除事件
  - Setup: `"enemy_001"` 已注册
  - Verify: `unregister_entity("enemy_001")`
  - Pass condition: 仅发布一条 `attribute.enemy_001.unregistered` 事件，不发逐属性删除事件

---

## Test Evidence

**Story Type**: UI
**Required evidence**:
- `production/qa/evidence/events-evidence.md` — manual/interaction evidence with sign-off

**Status**: [x] Executed 2026-05-04

---

## Dependencies

- Depends on: Story 001 must be ready or done for shared test fixtures and baseline APIs
- Unlocks: Story 008

## 2026-05-04 Sprint Execution Evidence

- Sprint execution order: Sprint 5, story 20/20
- Sprint source: `production/sprints/sprint-5.md`
- QA plan: `production/qa/qa-plan-sprint-5-2026-05-04.md`
- Automated evidence: `reports/report_13/results.xml` (137 tests, 0 failures, 0 skipped, 0 flaky)
- QA gate evidence: `production/qa/evidence/sprint-5-qa-result-2026-05-04.md`
- Verdict: Done; acceptance criteria reviewed against implementation, runtime tests, and sprint QA plan evidence.
- QA-plan automated tests:
  - `tests/unit/resource_system/resource_system_crud_test.gd`
  - `tests/integration/resource_system/resource_system_state_test.gd`
  - `tests/unit/attribute_system/attribute_system_crud_test.gd`
  - `tests/integration/attribute_system/attribute_system_final_test.gd`
