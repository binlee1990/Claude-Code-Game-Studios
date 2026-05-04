# ADR-0018: SaveManager 多槽目录结构与 API 扩展

## Status

Accepted

## Date

2026-05-05

## Last Verified

2026-05-05

## Decision Makers

technical-director + game-designer

## Summary

Sprint 11 存档屏（S11-012）要求多存档槽（3 槽位），SaveManager GDD 原设计为单存档位（`user://save/save.json`）。本 ADR 决议多槽目录结构方案、新增 4 个查询 API、扩展 2 个命令 API，以及旧单槽存档的向后兼容迁移策略。

## Engine Compatibility

| Field | Value |
|-------|-------|
| **Engine** | Godot 4.6.2 |
| **Domain** | Core / Data |
| **Knowledge Risk** | LOW — pure file I/O and directory structure; no engine-specific APIs |
| **References Consulted** | `design/gdd/save-system.md`, `design/ux/save-screen.md` |
| **Post-Cutoff APIs Used** | None |
| **Verification Required** | 多槽保存/读取/删除/列表 + 旧单槽迁移 + 损坏恢复 per-slot |

## ADR Dependencies

| Field | Value |
|-------|-------|
| **Depends On** | ADR-0006 (Save Format and Version Migration) |
| **Enables** | Sprint 11 S11-012 save-screen 完整实现（非降级单槽模式） |
| **Blocks** | save-screen — 无此 ADR 则存档屏降级为单存档槽模式 |
| **Ordering Note** | 在 S11-012 dev 前必须 Accepted；S11-001..003（ui-scene-foundation）不受阻 |

## Context

### Problem Statement

SaveManager GDD 设计为单存档位：`user://save/save.json` + `save.json.bak`。Sprint 11 S11-012 存档屏 spec 要求 3 个存档槽，玩家可手动选择保存目标槽、读取不同槽、删除槽。当前 SaveManager 的 `save_game()` / `load_game()` 均无 `slot_index` 参数。

无此 ADR 的代价：存档屏降级为单槽模式 — 失去多存档管理的核心价值（分支尝试、不同角色、版本回退）。

### Current State

- SaveManager: Autoload 单例，注册表模式，单存档文件 `user://save/save.json`
- `save_game()`: 收集所有 provider → 写 JSON → 写 .bak
- `load_game()`: 读 JSON → 校验 → 分发 restore
- 迁移链: `_migrate(data, from_version)` → 顺序执行迁移脚本
- 无 `slot_index` 概念

### Constraints

- 保持注册表模式不变（各系统仍通过 `register_provider` 注册 save/restore 回调）
- 每个槽位必须保持原子写入（先写 temp，再 rename）和 .bak 备份
- 旧单槽存档（`user://save/save.json`）不能静默丢失
- 自动保存始终写入当前活跃槽

### Requirements

- 3 个存档槽，每个槽独立的 `save.json` + `save.json.bak`
- 查询 API：列出所有槽状态、获取上次自动保存时间、获取当前活跃槽
- 命令 API：保存到指定槽、从指定槽加载、删除指定槽
- 向后兼容旧单槽存档

## Decision

### 1. 目录结构：子目录方案

```
user://save/
├── slot_0/
│   ├── save.json
│   └── save.json.bak
├── slot_1/
│   ├── save.json
│   └── save.json.bak
├── slot_2/
│   ├── save.json
│   └── save.json.bak
└── slot_index.json          # 记录当前活跃槽 + 自动保存元数据
```

**选择理由**：
- 每个槽的 save.json + .bak 原子写入隔离，不会因一个槽损坏影响其他槽
- 槽目录可独立删除（`DirAccess.remove_absolute("user://save/slot_1/")` 递归删除）
- 未来扩展 per-slot 截图缩略图直接放同目录（`thumbnail.png`）

**拒绝扁平文件方案**（`save_0.json`, `save_1.json`, `save_2.json`）：
- 每个槽的 .bak 文件命名混乱（`save_0.json.bak`）
- 槽删除需逐文件清理，易残留

### 2. slot_index.json 结构

```json
{
  "active_slot": 0,
  "last_autosave_at": 1714713600.0,
  "version": 1
}
```

轻量文件，仅在 SaveManager 初始化时读写。当前活跃槽 + 自动保存时间戳的 single source of truth。

### 3. 新增 API

```
## 查询 API (Read-only)

list_saves() -> Array[Dictionary]
# 返回 3 个槽位的轻量摘要，不读完整 save.json
# 每个 element: {
#   "slot_index": int,
#   "exists": bool,
#   "meta": { version, saved_at, data_version, play_time_seconds } | null,
#   "portrait_ref": String | "",
#   "level": int | 0,
#   "realm": String | "",
#   "save_size_bytes": int | 0,
#   "corrupted": bool,
#   "recovered_from_backup": bool,
#   "migration_needed": bool
# }
# 性能: 只读每个 existing 槽的 meta 段（不解析 systems），3 槽 < 5ms

get_last_autosave_time() -> float | null
# 返回 Unix timestamp 或 null（从未自动保存）
# 从 slot_index.json 读取

get_current_slot() -> int
# 返回当前活跃槽编号 (0-2)
# 从 slot_index.json 读取

## 命令 API (Write)

save_game(slot_index: int) -> bool
# 扩展原有 save_game()，添加 slot_index 参数（默认 = current_slot）
# 内部: slot_index 参数传递给 _write_slot(slot_index, data)

load_game(slot_index: int) -> bool
# 扩展原有 load_game()，添加 slot_index 参数
# 内部: 从 user://save/slot_{slot_index}/save.json 读取

delete_save(slot_index: int) -> bool
# 删除 user://save/slot_{slot_index}/ 整个目录
# 返回是否成功
# 不删除 slot_index.json（仅更新元数据）
# 拒绝删除当前活跃槽（返回 false）
```

### 4. 向后兼容迁移

SaveManager 初始化时检测旧单槽存档：

```
if FileAccess.file_exists("user://save/save.json") and not DirAccess.dir_exists("user://save/slot_0/"):
    # 1. 创建 user://save/slot_0/ 目录
    # 2. 移动 save.json → slot_0/save.json
    # 3. 移动 save.json.bak → slot_0/save.json.bak（如果存在）
    # 4. 创建 slot_index.json（active_slot=0）
    # 5. 打印 info "Migrated legacy save to slot_0"
```

一次性迁移，不删除原始文件（移动而非复制）。迁移失败时保留旧文件不变，打印 error。

### 5. 自动保存行为

- 自动保存目标 = `get_current_slot()`（始终当前活跃槽）
- 自动保存触发条件不变：定时器 + 事件触发 + app quit
- `get_last_autosave_time()` 每次自动保存后更新 `slot_index.json`

### Architecture Diagram

```text
SaveManager (Autoload)
  |
  |-- slot_index.json (active_slot + last_autosave_at)
  |
  |-- slot_0/save.json + .bak
  |-- slot_1/save.json + .bak
  |-- slot_2/save.json + .bak
  |
  +-- register_provider(namespace, save_fn, restore_fn)  # 不变
  +-- list_saves() -> Array[Dictionary]                   # NEW
  +-- get_last_autosave_time() -> float | null            # NEW
  +-- get_current_slot() -> int                           # NEW
  +-- save_game(slot_index: int) -> bool                  # EXTENDED
  +-- load_game(slot_index: int) -> bool                  # EXTENDED
  +-- delete_save(slot_index: int) -> bool                # NEW
```

## Alternatives Considered

### Alternative 1: 扁平文件方案

- **Description**: `save_0.json`, `save_1.json`, `save_2.json` + `.bak` 同目录
- **Pros**: 目录结构简单，无子目录
- **Cons**: .bak 命名混乱；槽删除需逐文件清理；未来 per-slot 额外文件（截图）无处安放
- **Rejection Reason**: 子目录方案更干净，扩展性更好

### Alternative 2: 降级为单槽模式

- **Description**: Sprint 11 存档屏只显示 1 个槽，多槽延后到 Sprint 13+
- **Pros**: 零 SaveManager 改动
- **Cons**: 阉割存档屏 50% 价值；S11-012 spec 需重写
- **Rejection Reason**: save-screen spec 已明确设计为多槽，降级浪费 UX 设计投入

### Alternative 3: 每个槽独立 SaveManager 实例

- **Description**: 不同槽位走不同 SaveManager 注册表
- **Pros**: 完全隔离
- **Cons**: 打破 Autoload 单例模型；provider 注册表需 per-instance；架构变更过大
- **Rejection Reason**: 过度工程 — MVP 不需要 SaveManager 多实例

## Consequences

### Positive

- 存档屏完整可用（3 槽管理 + 自动保存指示器 + 迁移/损坏状态）
- 每槽独立原子写入 + 备份，一个槽损坏不影响其他槽
- 注册表模式完全不变（各系统仍 register 一次，SaveManager 内部按 slot 路由）
- 旧单槽存档自动迁移不丢失

### Negative

- SaveManager 复杂度增加（~100 行新代码：目录管理 + 4 新 API + 兼容迁移）
- 存档文件总大小 ×3（每个槽完整 copies 全部 provider 数据）

### Neutral

- `list_saves()` 需要读每个 existing 槽的 meta 段 — 需给 save.json 加轻量 header 或只解析前 N 行

## Risks

| Risk | Probability | Impact | Mitigation |
|------|------------|--------|-----------|
| 旧单槽迁移失败导致数据丢失 | Low | High | 迁移前先 copy，失败则保留原始文件不动 |
| 3 槽 save.json 同时损坏（磁盘故障） | Very Low | Critical | .bak 恢复机制 per-slot；slot 间物理隔离 |
| 玩家误删活跃槽 | Medium | Medium | `delete_save(current_slot)` 返回 false，拒绝操作 |

## Performance Implications

| Metric | Before | Expected After | Budget |
|--------|--------|---------------|--------|
| `list_saves()` (3 槽) | N/A | < 5 ms | 10 ms |
| `save_game(slot)` | ~10 ms | ~10 ms（无变化 — 只写一个槽） | 50 ms |
| `load_game(slot)` | ~20 ms | ~20 ms（无变化） | 100 ms |
| 磁盘占用 (3 槽 full) | ~100 KB | ~300 KB | 1 MB |

## Migration Plan

1. SaveManager 新增 `_ensure_slot_dirs()` — 首次启动创建 `slot_0/`, `slot_1/`, `slot_2/` 空目录
2. SaveManager 新增 `_migrate_legacy_if_needed()` — 检测旧 `save.json` → 移动到 `slot_0/`
3. `save_game()` 添加 `slot_index` 参数，内部路由到 `_write_slot(slot_index, data)`
4. `load_game()` 添加 `slot_index` 参数，内部路由到 `_read_slot(slot_index)`
5. 新增 `list_saves()` / `get_last_autosave_time()` / `get_current_slot()` / `delete_save()`
6. `slot_index.json` 读写工具方法
7. Sprint 1-10 既有 137 GdUnit4 测试适配：原单槽测试的 `save_game()` 调用加 `slot_index=0`

**Rollback plan**: 删除 `slot_0/` `slot_1/` `slot_2/` 目录和 `slot_index.json`，恢复旧的 `save.json`（如未删除）。

## Validation Criteria

- [ ] `save_game(1)` → `user://save/slot_1/save.json` + `.bak` 存在
- [ ] `load_game(1)` → 从 slot_1 恢复，provider restore 被调用
- [ ] `list_saves()` 返回 3 个 element，含 exists/corrupted/migration_needed 状态
- [ ] `delete_save(2)` → `slot_2/` 目录被删除；`list_saves()[2].exists == false`
- [ ] `delete_save(current_slot)` → 返回 false
- [ ] 旧 `user://save/save.json` 存在时 → 自动迁移到 `slot_0/save.json`
- [ ] 一个槽损坏不影响其他槽的 load/save
- [ ] Sprint 1-10 既有 137 测试全部仍 pass

## GDD Requirements Addressed

| GDD Document | System | Requirement | How This ADR Satisfies It |
|-------------|--------|-------------|--------------------------|
| `design/gdd/save-system.md` | SaveManager | 单存档位（原设计） | 扩展为多槽，注册表模式不变 |
| `design/ux/save-screen.md` | SaveScreen | 3 存档槽 + 手动保存/读取/删除 + 自动保存指示器 | 提供 `list_saves` + `save_game(slot)` + `load_game(slot)` + `delete_save(slot)` API |
| `design/ux/save-screen.md` | SaveScreen | AC-5/6/7/8: 手动保存/读取/删除 + 空槽状态 + 损坏状态 | 全部依赖本 ADR 决议的 API |

## Related

- ADR-0006: Save Format and Version Migration（存档文件结构 + 迁移链 — 本 ADR 在此基础上加多槽目录层）
- `design/ux/save-screen.md` §Data Requirements + §架构关注
- `design/gdd/save-system.md` §Detailed Design（原单槽设计 — 需 minor update 标注多槽扩展）
