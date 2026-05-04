# Epic: 存档系统

> **Layer**: Core Data
> **GDD**: design/gdd/save-system.md
> **Architecture Module**: `SaveManager` (Autoload) (全局单例)
> **Status**: Ready
> **Stories**: Created (8 stories)

## Overview

存档系统是游戏的持久化基础设施。它采用注册表模式：各游戏系统通过 `register_provider()` 注册序列化/反序列化回调，SaveManager 不感知任何具体数据结构——只负责收集、组装、写入和读取一个 JSON 文件。每个系统拥有独立的存档数据段（namespace），读写互不干扰。

Architecture ownership: `SaveManager (Autoload)` owns 注册表, 序列化, 版本迁移.

## Governing ADRs

| ADR | Decision Summary | Engine Risk |
|-----|------------------|-------------|
| ADR-0006: 存档格式与版本迁移 | Implement `SaveManager` as a global Autoload that owns a provider registry. Each persistent system registers `save_fn() -> Dictionary` and `restore_fn(data: Dictionary) -> void` under a namespace. SaveManager writes a JSON save to `user://save/save.json` through a temporary file and keeps `save.json.bak` for recovery. | MEDIUM |
| ADR-0008: Autoload 初始化顺序 | Use explicit Autoload order in `project.godot`: | MEDIUM |

## GDD Requirements

| TR-ID | Requirement | ADR Coverage |
|-------|-------------|--------------|
| TR-save-system-001 | SaveManager persists namespaced provider data to a versioned JSON autosave with temp-write, backup recovery, and migrations. | ADR-0006, ADR-0008 |

**Untraced requirements**: 0 known in `docs/architecture/tr-registry.yaml`; the registry currently exposes one stable system-level TR for this GDD.

## Engine Risk

**MEDIUM** — highest governing ADR knowledge risk. Engine baseline: Godot 4.6.2.

## Cross-Epic Dependencies

- Upstream: 数据配置系统, 时间管理器, 事件总线
- Downstream: 调试控制台, 等级系统

## Definition of Done

This epic is complete when:
- All stories are implemented, reviewed, and closed via `/story-done`.
- All acceptance criteria from `design/gdd/save-system.md` are verified.
- All Logic and Integration stories have passing test files under `tests/`.
- All Visual/Feel and UI stories have evidence docs with sign-off under `production/qa/evidence/`.
- Any Godot 4.6.2 behavior named by the governing ADRs is verified against `docs/engine-reference/godot/`.

## Stories

| # | Story | Type | Status | ADR |
|---|-------|------|--------|-----|
| 001 | [`user://save/save.json` 包含 `meta` 和 `systems`，且 `systems.time_manager`](story-001-user-save-save-json-meta-systems-systems-time-manager.md) | Config/Data | Ready | ADR-0006 |
| 002 | [尝试加载 `save.json.bak`，若 backup 有效则从 backup 恢复，发布 `save.corrupted` 事件](story-002-save-json-bak-backup-backup-save-corrupted.md) | Config/Data | Ready | ADR-0006 |
| 003 | [系统 A 的 namespace 数据为 `null`，系统 B 的数据正常保存，打印警告](story-003-a-namespace-null-b.md) | Integration | Ready | ADR-0008 |
| 004 | [该 provider 的 `restore_fn()` 收到空 Dictionary `{}`](story-004-provider-restore-fn-dictionary.md) | Integration | Ready | ADR-0008 |
| 005 | [迁移中止，不覆盖原文件，回退到 backup 或新游戏](story-005-backup.md) | Config/Data | Ready | ADR-0006 |
| 006 | [在关闭前完成一次保存](story-006-006-integration.md) | Integration | Ready | ADR-0008 |
| 007 | [文件写入 `user://test_save/save.json`](story-007-user-test-save-save-json.md) | Config/Data | Ready | ADR-0006 |
| 008 | [存在 `save.json` 和 `save.json.bak`，不存在 `save.json.tmp`（临时文件已清理）](story-008-save-json-save-json-bak-save-json-tmp.md) | Config/Data | Ready | ADR-0006 |

## Next Step

Run `/story-readiness production/epics/save-system/story-001-*.md` before implementing the first story in this epic.
