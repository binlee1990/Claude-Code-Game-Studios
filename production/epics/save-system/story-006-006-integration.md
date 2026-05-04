# Story 006: 在关闭前完成一次保存

> **Epic**: 存档系统
> **Status**: Ready
> **Layer**: Core Data
> **Type**: Integration
> **Manifest Version**: 2026-05-04

## Context

**GDD**: `design/gdd/save-system.md`
**Requirement**: `TR-save-system-001` — SaveManager persists namespaced provider data to a versioned JSON autosave with temp-write, backup recovery, and migrations.

**ADR Governing Implementation**: ADR-0008: Autoload 初始化顺序
**ADR Decision Summary**: Use explicit Autoload order in `project.godot`:

**Engine**: Godot 4.6.2 | **Risk**: MEDIUM
**Engine Notes**: ADR-0008 status is Accepted; verify any Godot 4.6.2 behavior named by the ADR before closing the story.

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

*From GDD `design/gdd/save-system.md`, scoped to this story:*

- [ ] GIVEN: SaveManager 收到 `NOTIFICATION_WM_CLOSE_REQUEST`，**WHEN** 退出流程触发，**THEN** 在关闭前完成一次保存
- [ ] GIVEN: 自动保存间隔设为 60 秒，**WHEN** 游戏运行 180 秒，**THEN** 至少触发 2 次自动保存（不含退出保存）
- [ ] GIVEN: `meta.data_version` 与当前游戏数据版本不一致，**WHEN** 加载，**THEN** 打印版本不匹配警告，继续加载不中止

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
- Story 007 covers the next acceptance group in this epic.

---

## QA Test Cases

*Written at story creation. The developer implements against these cases.*

- **AC**: GIVEN: SaveManager 收到 `NOTIFICATION_WM_CLOSE_REQUEST`，**WHEN** 退出流程触发，**THEN** 在关闭前完成一次保存
  - Given: SaveManager 收到 `NOTIFICATION_WM_CLOSE_REQUEST`
  - When: 退出流程触发
  - Then: 在关闭前完成一次保存
  - Edge cases: boundary, invalid, missing-data, and repeat-run variants from the GDD edge-case section

- **AC**: GIVEN: 自动保存间隔设为 60 秒，**WHEN** 游戏运行 180 秒，**THEN** 至少触发 2 次自动保存（不含退出保存）
  - Given: 自动保存间隔设为 60 秒
  - When: 游戏运行 180 秒
  - Then: 至少触发 2 次自动保存（不含退出保存）
  - Edge cases: boundary, invalid, missing-data, and repeat-run variants from the GDD edge-case section

- **AC**: GIVEN: `meta.data_version` 与当前游戏数据版本不一致，**WHEN** 加载，**THEN** 打印版本不匹配警告，继续加载不中止
  - Given: `meta.data_version` 与当前游戏数据版本不一致
  - When: 加载
  - Then: 打印版本不匹配警告，继续加载不中止
  - Edge cases: boundary, invalid, missing-data, and repeat-run variants from the GDD edge-case section

---

## Test Evidence

**Story Type**: Integration
**Required evidence**:
- `tests/integration/save/006-integration_test.gd` — must exist and pass

**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: Story 001 must be ready or done for shared test fixtures and baseline APIs
- Unlocks: Story 007
