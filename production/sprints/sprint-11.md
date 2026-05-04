# Sprint 11 -- UI Scene Layer (First Playable)

> **Created**: 2026-05-05
> **Status**: Planned — awaiting `/story-readiness` per epic
> **Predecessor**: Sprint 10（MVP Logic Layer Complete，但 First Playable 未达成）
> **Goal Type**: Net-new sprint added by 2026-05-05 dialectical audit；不在 sprint-1..10 原计划内

## Sprint Goal

把 27 个 autoload 的 RefCounted 服务真正接入 Godot 4.6 场景树。Sprint 出口标志：**MVP First Playable 真正达成** — 玩家启动 Godot 项目，能看到完整 HUD、5 个 MVP 主屏（修炼/战斗/资源/存档/离线结算）、Toast Stack、Offline Drawer、并能通过 UI 完成 game-concept §10.2 第一条可玩闭环（修炼 → 资源 → 等级 → 战斗 → 掉落 → 推进区域 → 离线结算）全部步骤。

> Sprint 11 **只补 UI 场景层**。不增加任何新系统、不改任何 GDD、不修任何 ADR、不动 27 系统逻辑代码。

## Layer / Milestone

- Layer: Presentation Scene Layer（新；Sprint 1–10 完成的 Presentation 是 RefCounted 服务层）
- Milestone: 🎯 **MVP First Playable**（end of Sprint 11）— 解除 sprint-10 DoD 中"被 UI 缺口阻塞"的 Production → Polish gate

## Pre-Sprint Bootstrap (已完成 2026-05-05)

| 项 | 状态 | 说明 |
|----|------|------|
| `src/ui/hud/hud.gd` | ✅ upgraded | EventBus 订阅 5 资源 + level + realm + stance + offline + combat.finished；3 Button 接 CultivationSystem；4 资产族（resource/realm/stance/status icons）动态切换 |
| `src/ui/hud/hud.tscn` | ✅ upgraded | CanvasLayer + theme.tres + main_base 背景 + 5 资源 row（图标 + Label）+ realm/stance/combat status TextureRect + 3 Button + 战斗日志 |
| `project.godot` HUDBootstrap autoload | ✅ added | `*res://src/ui/hud/hud.tscn` 在 27 服务 autoload 之后启动 |
| **资产挂载（临时骨架阶段）** | ✅ pass | 22 个资产路径（theme.tres + 5 resource icons + 7 realm icons + 4 stance icons + 5 status icons + main_base）静态 ExtResource 4 + 运行时 _load_icon_or_null 缓存其余 — Godot 4.6.2 headless 180 帧 0 error / 0 warning |
| Asset Manifest | ✅ created | `design/registry/ui-asset-manifest.md` 登记 117 资产；Sprint 11 各 epic 强制 DoD 引用本 manifest |
| 用户运行验证 | ⏳ pending | 等用户 `F5` 运行 main.tscn 看实际 HUD（含 main_base 水墨背景 + 资源图标 + 境界图标）|

> 临时骨架已展示 **theme.tres + 5 资产族 + main_base 背景** 的端到端可加载性；但仍 **不符合** design/ux/hud.md 的三段式布局，无 Toast / Drawer / 渐进解锁 / rarity frame / vfx / 印章 / 角色立绘 / 敌人 sheet / 物品 grid。Sprint 11 必须把剩余 95 个 PNG 资产全部接入。

## AI Context Budget

- Stories: 16 total（≤ 20）
- Parallelizable: 8 stories（5 主屏并行；Toast / Drawer / Settings 并行）
- Verification Density: 每 story ≥ 1 Visual evidence（截图）+ ≥ 1 Manual interaction walkthrough；HUD 与 Modal 路由类 story 加 ≥ 1 GdUnit4 集成测试

## Tasks

> **资产引用约定**：每行末"Assets"列引用 `design/registry/ui-asset-manifest.md` 段号。`§N` = 必须 100% 接入；`§N*` = 可选/部分；story 完成时实际接入路径写进 story 文件 Test Evidence 段。

### Must Have（Critical Path — UI 框架与 HUD 基线）

| ID | Story | Epic（新） | Type | Depends On | Assets (manifest §) |
|----|-------|-----------|------|------------|---------------------|
| S11-001-ui-scene-foundation | UIManager 真实场景实例化 — 把 `open_screen` 从字典返回升级为 `load(path).instantiate()` + add_child + 转场动画 hook，不破坏现有单元测试 | ui-scene-foundation | UI | none | §1 theme.tres + §1 button_states 4 region 补齐 |
| S11-002-ui-scene-foundation | Modal stack Z-Order 与 input gate — 真实 CanvasLayer 实例栈；遵循 ADR-0011 max_modal_depth；与 ui-framework GDD AC 全对齐 | ui-scene-foundation | UI | S11-001 | §1 theme + §1 panel_elevated（Modal 底） |
| S11-003-ui-scene-foundation | 主入口场景重构 — 在 main.tscn 内挂 RootViewport（CanvasLayer + ScreenStack + ToastLayer + ModalLayer + DrawerLayer），由 UIManager 控制；HUDBootstrap autoload 改为加载首屏 | ui-scene-foundation | UI | S11-001, S11-002 | §1 theme（强制全树继承） |
| S11-004-hud-real-layout | HUD 三段式布局替换临时骨架 — 顶部 64px STRIP + 左 192px NAV + 右 320px PANEL + 底 48px ACTION BAR，符合 design/ux/hud.md §Layout Zones | hud-real-layout | Visual | S11-003 | §1 theme + §1 panel_secondary（RIGHT PANEL）+ §2 全 5 资源图标 + §3 全 7 境界图标 + §5 状态点（offline_pending / level_up / overflow_warn）|
| S11-005-hud-real-layout | 渐进解锁 — 顶栏 5→12 元素淡入 200ms；订阅 `system.{name}.unlocked`；元素位置预留不重排 | hud-real-layout | UI | S11-004 | §13 vfx/level_up_ring（渐进解锁淡入辅助）|
| S11-006-hud-real-layout | 资源警戒态 — fill_ratio ≥ 0.85 时 row fill bar 切 bottleneck_red + 数字右"⚠" + RIGHT PANEL 弹"满仓" chip + 全屏闪烁 | hud-real-layout | Visual | S11-004 | §5 overflow_warn + §13 overflow_warn_flash |
| S11-007-toast-stack | P-FBK-01 Toast Stack — 突破 / 稀有掉落 / 飞升 toast 4s 自动消失；最多 4 条堆叠；订阅 `level.changed` / `combat.finished` (epic loot) / `realm.advanced` | toast-stack | UI | S11-003 | §1 panel_elevated（toast 卡片底）+ §5 level_up + §6 全 8 rarity_frame + §7 burst_gold（突破全屏覆层）+ §12 item_pack_basic_sheet / item_pack_rare_sheet（稀有掉落开箱动画）+ §13 victory_burst_gold |
| S11-008-offline-drawer | P-NAV-04 Offline Drawer — 480px 宽，列资源/经验/战利品/生产；触发条件 = `offline.settled` 事件后 STRIP 状态点旁"📦 N"角标亮起 | offline-drawer | UI | S11-003 | §5 offline_pending + §9 offline_paper（drawer 主背景 9-slice）+ §2 全 5 资源图标（结算列表）|

### Should Have（5 个 MVP 主屏 — game-concept §11 要求）

| ID | Story | Epic（新） | Type | Depends On | Assets (manifest §) |
|----|-------|-----------|------|------------|---------------------|
| S11-009-mvp-screens | 修炼屏（cultivation_screen.tscn）— 顶栏修炼姿态切换 modal + 手动修炼按钮 + 闭关进度环 + 当前 tick 产出乘数明细 | mvp-screens | UI | S11-004 | §8 main_base（背景）+ §10 portrait（玩家立绘）+ §10 idle_sheet（待机动画）+ §4 全 4 stance（modal 4 选 2，未实现的 closed_door/idle 置灰）+ §13 manual_click_pulse（按钮反馈）|
| S11-010-mvp-screens | 战斗屏（combat_screen.tscn）— 区域切换器 + 当前敌人 portrait + 队伍属性条 + 战斗日志（替换临时 RichTextLabel） | mvp-screens | UI | S11-004 | §8 starter_forest / east_sea_shore / ruined_temple（按 zone_id 动态背景）+ §10 idle_sheet / attack_sheet / hurt_sheet / death_sheet（玩家四态动画）+ §11 starter+mid+end zone 全 27 enemy PNG（按 enemy_id 动态加载，含 ghost_flame projectile）+ §5 combat_active / combat_failed + §9 failure_grey（失败覆层）+ §13 crit_hit_spark / victory_burst_gold / zone_transition_ink_wipe_01..04（区域切换转场）|
| S11-011-mvp-screens | 资源/背包屏（resources_screen.tscn）— 5 资源全量明细 + cap fill bar + 物品库存（item-material-system） + Loot Filter 占位 | mvp-screens | UI | S11-004 | §2 全 5 资源图标 + §6 全 8 rarity_frame（物品 grid 9-slice）+ §12 全 13 item icons（背包 grid，含 2 个 item_pack sheet 静态预览）|
| S11-012-mvp-screens | 存档屏（save_screen.tscn）— 多存档槽 + 自动保存指示 + 手动保存/读取按钮 + 版本号 + 迁移状态 | mvp-screens | UI | S11-003 | §10 portrait（每个槽显示主角头像）+ §3 当前存档境界图标 |
| S11-013-mvp-screens | 离线结算屏（offline_settlement_screen.tscn）— 解释式结算（vs. drawer 的速览）；展开生产链/战斗细节；玩家可"延后查看" | mvp-screens | UI | S11-008 | §9 offline_paper + §2 全 5 资源图标 + §6 rarity_frame（离线掉落物品行）+ §11 enemy portraits（离线战斗记录）|

### Nice to Have

| ID | Story | Epic（新） | Type | Depends On | Assets (manifest §) |
|----|-------|-----------|------|------------|---------------------|
| S11-014-debug-console-ui | 调试控制台 UI — `~`键打开；debug_console.gd 已有 service 层，缺 Control 节点 | debug-console-ui | UI | S11-001 | §1 theme + §1 panel_elevated（半透明 console 底）— ADR-0012 要求 release 构建排除 |
| S11-015-settings | 设置屏（settings_screen.tscn）— 音量/分辨率/语言/数字格式/reduce motion/离线收益确认 | settings | UI | S11-003 | §1 theme — 无图像资产，全 Control |
| S11-016-mvp-first-playable-smoke | MVP First Playable 端到端 — 录屏 + checklist：玩家从冷启动到完成 game-concept §10.2 全 8 步循环；**附 asset-coverage report** | mvp-screens | Integration | 上述 13 stories 全部 done | **跨 story 资产覆盖报告**（脚本扫所有 sprint-11 .tscn/.gd 中 `res://assets/` 引用，对照 manifest 计算）|

## Carryover from Previous Sprint

| Story | Reason |
|-------|--------|
| Sprint 10 临时 HUDBootstrap autoload | 临时骨架；S11-003 在 main.tscn 重构后移除 HUDBootstrap autoload，改由 RootViewport 加载首屏 |

## Risks

| Risk | Probability | Impact | Mitigation |
|------|-------------|--------|------------|
| UIManager 升级（字典 → 真实 instantiate）打破已通过的 sprint-10 单元测试 | High | High | S11-001 第一条 AC = "sprint-10 全部 137 GdUnit4 测试仍 pass"；新增的真实场景行为通过新增测试覆盖，不替换旧测试 |
| Godot 4.6.2 CanvasLayer Z-Order + UI Toolkit 兼容性未知 | Medium | High | S11-002 spike 优先；查阅 docs/engine-reference/godot/VERSION.md 已记录的 4.6 D3D12 默认变更 |
| 5 主屏 spec 不完整（design/ux 只有 hud.md，没有 cultivation_screen.md 等） | High | Medium | S11-009..013 每条 story 必须先 `/ux-design` 出对应 ux spec 后才能 `/dev-story`；UX 阻塞期间可优先做 S11-001..008 |
| HUD 临时骨架与 Sprint 11 完整 HUD 在过渡期视觉割裂 | Low | Low | 临时骨架放 dev-only 顶栏文字"Sprint 11 临时骨架"，提醒非最终态 |
| project.godot autoload 顺序错引发空引用 | Low | High | HUDBootstrap 已经放在最后；S11-003 重构后改 RootViewport，挂在 main.tscn 内更安全 |

## Dependencies on External Factors

- **设计依赖**：Sprint 11 假设 design/ux/hud.md 已 Approved（事实如此）；5 个主屏 ux spec 必须先 `/ux-design` 出来
- **art-bible**：所有 UI 颜色/字号/对比度走 `res://assets/ui/theme.tres`（art-bible Sec 4.6）；如 theme.tres 不存在，S11-004 第一条任务先创建
- **localization**：所有字符串经 `tr()`；如 i18n 系统未到位，至少建好 `i18n/zh_CN.csv` 占位（参 `.claude/rules/ui-code.md`）
- **accessibility-requirements.md**：Standard tier 已声明；HUD 字号 ≥ 20px / 对比 ≥ 4.5:1 / 焦点描边 / Tab order / reduced-motion 全部强制

## Definition of Done for this Sprint

- [ ] All Must Have（S11-001..008）completed
- [ ] All Should Have（S11-009..013）completed
- [ ] S11-016 MVP First Playable smoke 录屏 + checklist 通过
- [ ] All Logic/Integration stories have passing GdUnit4 tests；sprint-10 既有 137 测试不破坏
- [ ] All UI stories have screenshot evidence in `production/qa/evidence/sprint-11/`
- [ ] All UI stories have manual walkthrough markdown
- [ ] No S1 or S2 bugs in delivered features
- [ ] **Traceability**: 所有 sprint stories 映射回 `design/ux/hud.md` + `design/ux/[screen].md`（每屏一份新 spec）+ `design/gdd/ui-framework.md` + `design/gdd/hud-system.md`（覆盖率 100%）
- [ ] **新 ADR 评估**: 如 UIManager.open_screen 真实 instantiate 引入 ADR-0011 范围外的决策（如 transition 动画策略 / Drawer 是否独立 CanvasLayer / Modal Z-Order），追加 ADR-0016+
- [ ] **Asset Coverage**（强制 — 引用 `design/registry/ui-asset-manifest.md` §15）:
  - [ ] §1 Theme + Frames：theme.tres 全树挂载；button_states 4 region 补齐 — **100%**
  - [ ] §2 Resource icons (5/5)：5 资源图标在 hud-real-layout TOP STRIP + resources_screen 全用 — **100%**
  - [ ] §3 Realm icons (7/7)：7 境界图标动态切换可达（含 fanren / lianqi / zhuji / jindan / yuanying / huashen / heti 全境界截图证据）— **100%**
  - [ ] §4 Stance icons (4/4)：cultivation_screen modal 显示全 4 个（2 个未实现置灰）— **100%**
  - [ ] §5 Status icons (5/5)：5 状态点全触发证据（screenshots of combat_active / combat_failed / level_up / offline_pending / overflow_warn）— **100%**
  - [ ] §6 Rarity frames (8/8)：toast-stack + resources_screen 物品 grid 全用 — **100%**
  - [ ] §7 Seals (3/3)：burst_gold（突破/飞升）+ failure_red（失败）+ ink_default（普通成就）— **100%**
  - [ ] §8 Maps (4/5)：main_base + starter_forest + east_sea_shore + ruined_temple — **100%**（town_economy 资产登记不接入，留 Sprint 13）
  - [ ] §9 Overlays (2/2)：failure_grey + offline_paper — **100%**
  - [ ] §10 Player character (5/5)：portrait + 4 sheets — **100%**
  - [ ] §11 Enemy sheets (≥ 27/38)：starter+mid+end zone 全 27 PNG **100%**；current 实验组 0% 允许
  - [ ] §12 Item icons (13/13)：13 物品图标 + 2 item_pack sheet — **100%**
  - [ ] §13 VFX (8/8)：8 VFX 全触发证据 — **100%**
  - [ ] §14 Data configs：sprint-11 不直接消费，但 resources_screen 通过 ItemRegistry 间接验证 items.json 有效
  - [ ] **覆盖率脚本**：S11-016 smoke 提交时附 `production/qa/evidence/sprint-11/asset-coverage-report.json`（脚本扫所有 .tscn + .gd 中 `res://assets/` 引用，对照 manifest）
  - [ ] **未引用资产白名单**：如有 manifest 中资产被 sprint-11 跳过，必须在白名单标注 "立项归宿 sprint-N+ 原因"
- [ ] **MVP First Playable milestone 检查清单**:
  - [ ] 玩家启动 Godot → 看到完整 HUD（不是临时骨架）
  - [ ] 玩家通过 UI 完成 game-concept §10.2 全 8 步循环
  - [ ] 临时 HUDBootstrap autoload 已移除
  - [ ] systems-index.md 标注 "MVP First Playable Achieved" 时间戳（真实达成）
  - [ ] 解除 sprint-10 DoD 中"被 UI 缺口阻塞"的 Production → Polish gate 标记

## 新 Epic 列表（本 sprint 新增 6 个，等 sprint 启动后再写 EPIC.md）

| Epic（slug） | 范围 | Stories（本 sprint） |
|--------------|------|---------------------|
| ui-scene-foundation | UIManager 升级 + main.tscn 重构 + RootViewport 多 CanvasLayer 分层 | 3 |
| hud-real-layout | hud.tscn 替换临时骨架，对齐 design/ux/hud.md 三段式 + 渐进解锁 + 警戒态 | 3 |
| toast-stack | P-FBK-01 浮动通知栈 | 1 |
| offline-drawer | P-NAV-04 离线结算速览 drawer | 1 |
| mvp-screens | 5 主屏 + first-playable smoke | 6 |
| debug-console-ui | 调试控制台的 Control 层（service 层已存在 sprint-7 完成） | 1 |
| settings | 设置屏 | 1 |

## 2026-05-05 立项备注

- Sprint 11 是 2026-05-04 dialectical audit 后第 12 个迭代（10 + 1 mvp-smoke + 1 UI scene layer），原 sprint-1..10 计划保持不变
- 本 sprint 不修任何已 done 的 sprint-1..10 story；仅补 UI 场景层
- 临时 HUD 骨架（`src/ui/hud/hud.tscn` + `hud.gd` + `HUDBootstrap` autoload）的存在原因：让"Sprint 10 期间假装 First Playable"的状态立即暴露真实情况（运行就能看到东西），而不是黑屏继续误导
- Sprint 11 完成后，临时骨架由 mvp-screens epic 的 cultivation_screen 替代，HUDBootstrap autoload 在 main.tscn 重构后移除

## Next Steps

- 等用户运行临时 HUD 通过后，按 `/scope-check ui-scene-foundation` → `/story-readiness` 开始 S11-001
- 5 主屏 spec 需先 `/ux-design cultivation-screen` etc. 出 design/ux/cultivation_screen.md ... 之后才能 dev
- Sprint 11 出口前 `/smoke-check sprint` + `/team-qa sprint` + 录屏证据
