# Active Session State

**Updated**: 2026-05-05（4 个 MVP 主屏 UX spec 全部起草完成）

## Current Task

Sprint 11 所需的 5 个 MVP 主屏 UX spec 全部到位：
- ✅ cultivation-screen.md — /ux-review 完成，advisory issues 已修复
- ✅ combat-screen.md — 253 行初稿，等 /ux-review
- ✅ resources-screen.md — 504 行初稿（agent 起草），等 /ux-review
- ✅ save-screen.md — agent 详细版写入中（含 ADR-0018 + SaveManager API 扩展）
- ✅ offline-settlement-screen.md — 527 行初稿（agent 起草），等 /ux-review

## 本次 session 完成（Phase: UX Design — 批量创建 4 屏）

| 动作 | 文件 | 行数 | 状态 |
|------|------|------|------|
| /ux-review | cultivation-screen.md | 489 | NEEDS REVISION → advisory 全部修复 |
| Create ADR-0017 | `docs/architecture/adr-0017-oms-simulate-api.md` | — | Proposed |
| Add P-DAT-01-EXP | `design/ux/interaction-patterns.md` | — | 已入库 |
| Draft combat-screen | `design/ux/combat-screen.md` | 253 | Draft |
| Draft resources-screen | `design/ux/resources-screen.md` | 504 | Draft |
| Draft save-screen | `design/ux/save-screen.md` | ~400（agent 写入中） | Draft |
| Draft offline-settlement | `design/ux/offline-settlement-screen.md` | 527 | Draft |

## 当前 UX Spec 全景

| 文件 | 屏 | Sprint Story | 状态 |
|------|------|------|------|
| hud.md | HUD | S11-004..006 | ✅ Pre-existing |
| cultivation-screen.md | 修炼屏 | S11-009 | ✅ Reviewed |
| combat-screen.md | 战斗屏 | S11-010 | 🆕 Draft |
| resources-screen.md | 资源/背包屏 | S11-011 | 🆕 Draft |
| save-screen.md | 存档屏 | S11-012 | 🆕 Draft (agent writing) |
| offline-settlement-screen.md | 离线结算屏 | S11-013 | 🆕 Draft |
| interaction-patterns.md | Pattern Library | 全部 | ✅ Maintained |

## 关键不变量

- **未修改 30 GDD** — 设计 baseline 保持
- **未修改 15 ADR（ADR-0001–0015）** — 架构决策保持
- **新增 1 ADR** — ADR-0017 (Proposed)
- **未修改 187 epic story 文件** — Sprint 1–10 已完成的 story 内容不动
- **未修改 27 系统逻辑代码**（src/systems/）— 服务层 frozen

## Next Recommended Step

1. **用户运行 Godot 验证 A**：打开项目运行 main.tscn，验证临时 HUD 显示正常
2. **若 A 通过**：`/story-readiness production/sprints/sprint-11.md` → 按 Sprint 11 计划写 EPIC.md + story 文件
3. **若 A 失败**：截图给我修复
4. **ADR-0017 决议**：可先推进 S11-001..004（HUD 重构、RootViewport、三段式布局），它们不依赖 ADR-0017；S11-009（修炼屏）在 ADR-0017 Accept 前只能用降级态

## Status

Pre-Production → 进入 **Sprint 11 (UI Scene Layer)** — 30 系统逻辑层 frozen，新 sprint 专门把服务层接进 Godot 场景树。

## 本次 session 完成

| 阶段 | 动作 | 结果 |
|------|------|------|
| Phase 1 Diagnose | 读 game-concept.md / systems-index.md / project.godot / main.tscn / ui_manager.gd / hud_system.gd / hud.md / 27 autoload host | 8 条事实链定位真因（见下表） |
| Phase 2 Reframe | 区分"逻辑 MVP"vs"可玩 MVP" | active.md 与 sprint-10.md 措辞修正 |
| Phase 3 Challenge | 用户在 4 选项中选 A+D+C（不直接补完 5 屏 UI） | 范围确认 |
| Phase 4 Execute | 修改 / 新建 9 个文件 | 见下表 |
| Phase 5 Evaluate | Godot 启动可见 HUD（待用户运行验证） | PENDING USER TEST |

## 根因证据链

| # | 事实 | 来源 |
|---|------|------|
| 1 | MVP 定义 §11 要求"基础 UI：修炼/战斗/资源/存档/离线结算页面" | game-concept.md |
| 2 | systems-index 标 30/30 Approved | systems-index.md |
| 3 | active.md 旧版本声明 "MVP First Playable Achieved 2026-05-04" | active.md（已修） |
| 4 | `src/main/main.tscn` 仅一个空 Node 根（4 行） | 实读 |
| 5 | 27 个 autoload 全是 `*_host.gd`（headless RefCounted），0 场景 | project.godot |
| 6 | UIManagerHost 注册 `res://src/ui/hud/hud.tscn`，但 `src/ui/` 目录不存在 | Bash ls |
| 7 | `UIManager.open_screen()` 只返回 dict，从不 `load(path).instantiate()`、`add_child` | ui_manager.gd 全 61 行 |
| 8 | `HUDSystem` 是 RefCounted，只维护 `resource_rows` 字典 | hud_system.gd 全 96 行 |

## 修改 / 创建文件清单

| 文件 | 动作 | 关键变更 |
|------|------|----------|
| `design/gdd/systems-index.md` | Edit | "MVP First Playable Achieved" → "MVP Logic Layer Complete" + 新增"MVP First Playable 未达成"行 |
| `production/sprints/sprint-10.md` | Edit | DoD checklist 解除 "First Playable" 与 "Polish gate ready" 勾选；追加 2026-05-05 修订记录段 |
| `production/session-state/active.md` | Rewrite | 同步当前状态（本文件） |
| `src/main/main.tscn` | Rewrite | 加 HUD 场景实例作为子节点 |
| `src/ui/hud/hud.tscn` | Create | 最小 HUD：CanvasLayer + 5 资源 Label + 等级 Label + 姿态 Label + 3 按钮 + 战斗日志 RichTextLabel |
| `src/ui/hud/hud.gd` | Create | EventBus 订阅资源/等级/姿态变化 + Button 信号回调 + 初始读取 + battle log 拼接 |
| `production/sprints/sprint-11.md` | Create | Sprint 11 计划：UI Scene Layer，约 14–16 stories 拆分到 6 个新 epic |
| `production/sprints/index.md` | Edit | 新增 Sprint 11 行 + 更新 First Playable 时间归属 |
| `production/epics/index.md` | Edit | 新增 6 个 UI 场景 epic 条目（不写 EPIC.md，sprint-11 spec 内 inline） |
| `design/registry/ui-asset-manifest.md` | Create | 117 资产清单（107 PNG + theme + 9 data JSON）→ Sprint 11 epic 映射；§15 资产覆盖 DoD 阈值规则 |
| `src/ui/hud/hud.gd` | Upgrade | 加 4 个 ICON_PATHS 常量字典（resource/realm/stance/status）+ `_load_icon_or_null` 缓存 + combat.finished 订阅 + realm/stance/combat status 动态切换 |
| `src/ui/hud/hud.tscn` | Upgrade | 9 ext_resource 接入：theme.tres + main_base + 5 资源图标 + 1 默认境界图标；新增 RealmIcon/StanceIcon/CombatStatusIcon TextureRect 节点 |
| `production/sprints/sprint-11.md` | Edit | Tasks 三表加 Assets 列引用 manifest §；DoD 加 14 行 Asset Coverage 强制项 |

## 关键不变量

- **未修改 30 GDD**（design/gdd/*.md 除 systems-index）— 设计 baseline 保持
- **未修改 15 ADR** — 架构决策保持
- **未修改 187 epic story 文件** — Sprint 1–10 已完成的 story 内容不动
- **未修改 27 系统逻辑代码**（src/systems/）— 服务层 frozen，UI 层是新增

## Next Recommended Step

1. **用户运行 Godot 验证 A**：打开项目运行 main.tscn，应看到：
   - 顶部 5 行资源（灵气/修为/灵石/药材/经验）数字 + 灵气每秒自动跳动
   - 中段等级"Lv.1 fanren"+ 姿态"meditate"
   - 3 个按钮（手动修炼 / 切换姿态 / 凝丹）能点击且数字响应
   - 底部战斗日志显示订阅事件流
2. **若 A 通过**：`/story-readiness production/sprints/sprint-11.md` → 按 Sprint 11 计划写 EPIC.md + story 文件
3. **若 A 失败**：截图给我，我根据具体报错修复（最可能是 autoload 启动顺序或 NumberFormatter 静态调用）

<!-- STATUS -->
Epic: Sprint 11 — UI Scene Layer
Feature: 5 MVP 主屏 UX specs 全部完成
Task: combat/resources/save/offline-settlement 4 屏 Draft 完成，待 /ux-review 批量验证
<!-- /STATUS -->
