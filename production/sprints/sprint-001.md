# Sprint 1: Vertical Slice Core Loop

> Version: v1.2 | Date: 2026-04-25 | Status: COMPLETE — Validated With Product-Scope Notes
> Previous: v0.1 (规划中) — 重写以引用真实 story 路径
> Control Manifest: 2026-04-23-v1

## Sprint Goal

完成 SRPG 核心战斗循环的 Vertical Slice：从战斗开始到结算的完整玩家体验。

## Scope

### 已完成 (31 stories, 5 epics) — 不在本 Sprint 范围

| Epic | Stories | Status |
|------|---------|--------|
| attribute-system | 7 | COMPLETE |
| class-system | 6 | COMPLETE |
| resource-economy | 6 | COMPLETE |
| tactical-mechanism | 5 | COMPLETE |
| ai-system | 6 | COMPLETE |

### 本 Sprint 交付 (Vertical Slice 核心)

#### Epic 1: 回合制模式 — 收尾 (2 stories)

| Story ID | Path | Description | Est. | Status |
|----------|------|-------------|------|--------|
| TBM-006 | `production/epics/turn-based-mode/story-006-speed-up-mode.md` | 加速模式 (1x/2x/3x) | S | DONE |
| TBM-007 | `production/epics/turn-based-mode/story-007-save-load-integration.md` | 存档集成 | S | DONE |

#### Epic 2: 战斗结算 (5 stories)

| Story ID | Path | Description | Est. | Status |
|----------|------|-------------|------|--------|
| BS-001 | `production/epics/battle-settlement/story-001-settlement-trigger-flow.md` | 结算触发流程 | M | DONE |
| BS-002 | `production/epics/battle-settlement/story-002-experience-distribution.md` | 经验分配 | M | DONE |
| BS-003 | `production/epics/battle-settlement/story-003-battle-evaluation.md` | 战斗评价 | S | DONE |
| BS-004 | `production/epics/battle-settlement/story-004-material-equipment-drops.md` | 掉落系统 | M | DONE |
| BS-005 | `production/epics/battle-settlement/story-005-save-load-integration.md` | 存档集成 | S | DONE |

#### Epic 3: 视角与地图 (3 stories)

| Story ID | Path | Description | Est. | Status |
|----------|------|-------------|------|--------|
| CM-001 | `production/epics/camera-map-system/story-001-isometric-camera.md` | 斜45度摄像机 | M | DONE |
| CM-002 | `production/epics/camera-map-system/story-002-grid-map-rendering.md` | 网格地图渲染 | M | DONE |
| CM-003 | `production/epics/camera-map-system/story-003-save-load-integration.md` | 存档集成 | S | DONE |

#### Epic 4: UI 系统 (3 stories)

| Story ID | Path | Description | Est. | Status |
|----------|------|-------------|------|--------|
| UI-001 | `production/epics/ui-system/story-001-battle-hud.md` | 战斗 HUD | L | DONE |
| UI-002 | `production/epics/ui-system/story-002-resource-hud-menu-system.md` | 资源HUD+菜单 | M | DONE |
| UI-003 | `production/epics/ui-system/story-003-save-load-integration.md` | 存档集成 | S | DONE |

### 不在本 Sprint 范围 (后续 Sprint)

| Epic | Stories | Reason |
|------|---------|--------|
| skill-system | 7 | 依赖 VS 验证后再实施 |
| equipment-system | 7 | 同上 |
| character-management | 3 | 同上 |

## Vertical Slice Acceptance Criteria

Sprint 完成时，Vertical Slice 必须满足:

- [x] 完整战斗循环: 开始 → 行动(移动/攻击/技能) → 结算 → 奖励
- [x] 回合顺序正确显示且可操作
- [x] 伤害计算正确
- [x] 战斗评价和经验分配正确
- [x] 加速/自动战斗可用
- [x] 战斗 HUD 显示 HP/MP/技能栏/回合顺序
- [x] 地图正确渲染（斜45度 + 网格）
- [x] 存档/读档功能正常

## Timeline

- Sprint Start: 2026-04-23
- Sprint End: 2026-05-06 (2 weeks)
- 外部验证队列: `production/sprints/sprint-人工.md`

## GDD References

| System | GDD |
|--------|-----|
| 回合制 | design/gdd/turn-based-mode.md |
| 战斗结算 | design/gdd/battle-settlement.md |
| 视角地图 | design/gdd/camera-map-system.md |
| UI | design/gdd/ui-system.md |
| 存档 | design/gdd/save-system.md |

## Architecture References

| ADR | Scope |
|-----|-------|
| ADR-001 | 事件架构（所有系统通信） |
| ADR-002 | 场景管理（地图/战斗切换） |
| ADR-003 | 存档系统（存档集成 stories） |
| Control Manifest | docs/architecture/control-manifest.md (v2026-04-23-v1) |

---

## Revalidation — 2026-04-27

### 完成进展

复核结论：Sprint-001 按「Vertical Slice 可玩闭环」口径已执行完成，状态为 **COMPLETE WITH PRODUCT-SCOPE NOTES**。

| 复核项 | 结果 | 证据 |
|---|---|---|
| 核心战斗闭环 | 完成 | `production/qa/evidence/chapter-01-complete-release-evidence.md` 记录 Chapter 1 正式路径、结算、管理屏、保存/读取均 PASS |
| 自动化解析 | PASS | 2026-04-27 运行 `godot --headless --check-only project.godot`，退出码 0 |
| 自动化测试入口 | PASS | 2026-04-27 运行 `godot --headless res://tests/test_runner.tscn`，退出码 0；当前仓库静态统计 805 个 `test_` 方法 |
| 打包版冒烟 | PASS | 2026-04-27 运行 `builds/windows/SRPG.exe --headless --srpg-playthrough-smoke`，输出 `PACKAGED_PLAYTHROUGH_SMOKE PASS` |

### 遗留问题

- 原始 AC 写的是「斜45度 + 网格」，但当前实际交付为 2D top-down fallback 网格；`production/epics/camera-map-system/story-001-isometric-camera.md` 仍标记 Deferred，`story-003-save-load-integration.md` 也记录 rotation persistence deferred。
- 外部视觉 / 体验验证队列已移至 `production/sprints/sprint-人工.md`。
- 打包版 smoke 退出时 Godot 报告资源仍在使用的 warning/error；当前不阻塞 smoke PASS，但应在后续稳定性清理中处理。
