# Story 008: Batch / Snapshot / Restore 1

> **Epic**: 属性系统
> **Status**: Ready
> **Layer**: Core Gameplay
> **Type**: Config/Data
> **Manifest Version**: 2026-05-04

## Context

**GDD**: `design/gdd/attribute-system.md`
**Requirement**: `TR-attribute-system-001` — AttributeSystem owns entity attribute base values, final-value queries through ModifierEngine, events, snapshot, and restore.

**ADR Governing Implementation**: ADR-0007: 修正器叠加顺序
**ADR Decision Summary**: Use one `ModifierEngine` service with a three-stage pipeline: `base + add_sum`, then same-pool additive percentage multipliers, then cross-pool multiplication. MVP pools are `equipment`, `realm`, `zone`, and `buff`. Targets are strings such as `player.atk` and `lingqi_production`.

**Engine**: Godot 4.6.2 | **Risk**: LOW
**Engine Notes**: ADR-0007 status is Accepted; verify any Godot 4.6.2 behavior named by the ADR before closing the story.

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

- [ ] GIVEN: `"player"` 注册，**WHEN** `set_base_batch("player", {atk:BN(500), def:BN(200), spd:BN(80)})`，**THEN** 三个属性 base 全部更新，发布 3 条 `base_changed` 事件
- [ ] GIVEN: 主角和 5 弟子已注册，含若干 base 值，**WHEN** `snapshot()`，**THEN** 返回 `{version:1, entities:{...}}` 含全部 6 实体；BigNumber 字典可被 `from_dict` 还原
- [ ] GIVEN: snapshot 数据中含 `"deprecated_disciple"` 但配置无此 schema，**WHEN** `restore(data)`，**THEN** 跳过该 entity 并打印警告，其他 entity 正常恢复

---

## Implementation Notes

*Derived from ADR-0007 Implementation Guidelines:*

- Must apply modifiers in the order ADD, same-pool additive MULT, cross-pool multiplicative MULT.
- Must use `"{entity_id}.{attr_id}"` for attribute targets.
- Must use `"{resource_id}_production"` for production targets.
- Must cache clean target multiplier results and invalidate on register/unregister/expiry.
- Must emit `modifier_expired` when duration-based modifiers expire.
- Must not evaluate business-specific conditions in ModifierEngine.

---

## Out of Scope

- Story 001 covers the baseline contract for this epic; do not duplicate its setup work here.
- Story 009 covers the next acceptance group in this epic.

---

## QA Test Cases

*Written at story creation. The developer implements against these cases.*

- **AC**: GIVEN: `"player"` 注册，**WHEN** `set_base_batch("player", {atk:BN(500), def:BN(200), spd:BN(80)})`，**THEN** 三个属性 base 全部更新，发布 3 条 `base_changed` 事件
  - Given: `"player"` 注册
  - When: `set_base_batch("player", {atk:BN(500), def:BN(200), spd:BN(80)})`
  - Then: 三个属性 base 全部更新，发布 3 条 `base_changed` 事件
  - Edge cases: boundary, invalid, missing-data, and repeat-run variants from the GDD edge-case section

- **AC**: GIVEN: 主角和 5 弟子已注册，含若干 base 值，**WHEN** `snapshot()`，**THEN** 返回 `{version:1, entities:{...}}` 含全部 6 实体；BigNumber 字典可被 `from_dict` 还原
  - Given: 主角和 5 弟子已注册，含若干 base 值
  - When: `snapshot()`
  - Then: 返回 `{version:1, entities:{...}}` 含全部 6 实体；BigNumber 字典可被 `from_dict` 还原
  - Edge cases: boundary, invalid, missing-data, and repeat-run variants from the GDD edge-case section

- **AC**: GIVEN: snapshot 数据中含 `"deprecated_disciple"` 但配置无此 schema，**WHEN** `restore(data)`，**THEN** 跳过该 entity 并打印警告，其他 entity 正常恢复
  - Given: snapshot 数据中含 `"deprecated_disciple"` 但配置无此 schema
  - When: `restore(data)`
  - Then: 跳过该 entity 并打印警告，其他 entity 正常恢复
  - Edge cases: boundary, invalid, missing-data, and repeat-run variants from the GDD edge-case section

---

## Test Evidence

**Story Type**: Config/Data
**Required evidence**:
- `production/qa/smoke-attribute-system.md` — smoke check evidence

**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: Story 001 must be ready or done for shared test fixtures and baseline APIs
- Unlocks: Story 009
