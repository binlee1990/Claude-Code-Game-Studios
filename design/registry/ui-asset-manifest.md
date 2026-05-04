# UI Asset Manifest — Sprint 11 强制接入清单

> **Created**: 2026-05-05
> **Status**: Authoritative — Sprint 11 每个 epic 的 DoD 引用本文件
> **Source**: 实地扫描 `assets/` 目录得到 107 PNG + 1 theme.tres + 9 data JSON
> **Asset Pipeline**: 全部 PNG 由 Codex pipeline 生成（带 `pipeline-meta.json`），未来如重生成只动 PNG 不改路径
> **Reference**: Sprint 10 验收记录 `production/qa/evidence/asset-validation-report.json`（107 PNG, 0 失败）

---

## 0. 总览

| 资产族 | 数量 | 总目录 | 主要消费者（Sprint 11 epic） |
|--------|------|--------|-----------------------------|
| Theme | 1 | `assets/ui/theme.tres` | **所有** UI 场景必须挂载 |
| Resource icons | 5 | `assets/ui/icons/resources/` | hud-real-layout, mvp-screens (resources_screen) |
| Realm icons | 7 | `assets/ui/icons/realm/` | hud-real-layout, mvp-screens (cultivation_screen) |
| Stance icons | 4 | `assets/ui/icons/stances/` | mvp-screens (cultivation_screen) |
| Status icons | 5 | `assets/ui/icons/status/` | hud-real-layout, toast-stack |
| Rarity frames | 8 | `assets/ui/icons/rarity/` | mvp-screens (resources_screen 物品 grid), toast-stack (稀有掉落 toast) |
| UI panel frames | 4 | `assets/ui/frames/` | theme.tres 已引用；ui-scene-foundation 验证 9-slice |
| Seals | 3 | `assets/ui/seals/` | hud-real-layout (突破/失败全屏印章), toast-stack |
| Maps / 区域背景 | 5 | `assets/map/` | mvp-screens (cultivation/combat 屏背景), zone-system 切图 |
| Overlays | 2 | `assets/overlays/` | mvp-screens (offline drawer), hud-real-layout (战斗失败覆层) |
| Player character | 5 | `assets/characters/player/` | mvp-screens (cultivation_screen, combat_screen) |
| Enemy sheets | 38 | `assets/enemies/{starter,mid,end,current}_zone/` | mvp-screens (combat_screen) |
| Item icons | 13 | `assets/items/` | mvp-screens (resources_screen 背包 grid), toast-stack (掉落预览) |
| VFX | 8 | `assets/vfx/` | hud-real-layout, mvp-screens, toast-stack |
| Data configs | 9 | `assets/data/` | DataConfigHost autoload 已加载，无需 UI 单独挂 |

**资产总数**: 107 PNG + 1 theme.tres + 9 data JSON = 117 assets。**Sprint 11 出口 DoD 要求覆盖率 ≥ 100% PNG（除 Sprint 11 范围外的 enemy/item/character 子集，必须覆盖率 ≥ 80%）**。

---

## 1. Theme & Frames

**强制规则**：所有 Sprint 11 新建 .tscn 必须 `theme = ExtResource("res://assets/ui/theme.tres")` 或继承自挂载 theme 的父节点。

| Asset | Path | 用途 | 已用于（已存在） | Sprint 11 必接入 |
|-------|------|------|------------------|------------------|
| theme.tres | `res://assets/ui/theme.tres` | 全局主题 | hud.tscn (临时骨架) | 全部 UI epic 强制 |
| panel_primary.png | `res://assets/ui/frames/panel_primary.png` | Panel/styles/panel | theme.tres ext_resource 1 | （间接通过 theme） |
| panel_secondary.png | `res://assets/ui/frames/panel_secondary.png` | 次级面板 | theme.tres ext_resource 2 | hud-real-layout RIGHT PANEL 战斗日志区 |
| panel_elevated.png | `res://assets/ui/frames/panel_elevated.png` | PopupPanel/styles/panel | theme.tres ext_resource 3 | toast-stack toast 卡片底；offline-drawer drawer 底 |
| button_states.png | `res://assets/ui/frames/button_states.png` | Button/styles/normal (region 0,0,96,96) | theme.tres ext_resource 4 | ui-scene-foundation 验证 hover/pressed/disabled region 是否需要补 styles |

**已知 gap**：theme.tres 当前只定义 Button normal state；hover/pressed/disabled 三态在 button_states.png 内（96×96 一格，应为 4 格 sheet）。**ui-scene-foundation S11-001 必须在 theme.tres 补齐 4 个 StyleBoxTexture region**（0,0,96,96 / 96,0,96,96 / 192,0,96,96 / 288,0,96,96）。

---

## 2. Resource Icons (5 / 5 — MVP 全资源)

| Asset | Path | 资源 ID | 必接入屏 |
|-------|------|---------|---------|
| lingqi.png | `res://assets/ui/icons/resources/lingqi.png` | lingqi | hud-real-layout TOP STRIP, resources_screen |
| xiuwei.png | `res://assets/ui/icons/resources/xiuwei.png` | xiuwei | 同上 |
| lingshi.png | `res://assets/ui/icons/resources/lingshi.png` | lingshi | 同上 |
| herb.png | `res://assets/ui/icons/resources/herb.png` | herb | TOP STRIP（解锁炼丹后），resources_screen |
| exp.png | `res://assets/ui/icons/resources/exp.png` | exp | 等级徽章下方进度条，resources_screen |

**已挂载状态**：临时 hud.tscn (`src/ui/hud/hud.tscn`) 5 个图标已挂为 ExtResource — 升级时直接复用即可。

---

## 3. Realm Icons (7 / 7 — 完整境界链)

| Asset | Realm Key | LevelSystem 起始等级 |
|-------|-----------|---------------------|
| mortal.png | fanren | 1 |
| qi_refining.png | lianqi | 10 |
| foundation.png | zhuji | 30 |
| golden_core.png | jindan | 60 |
| yuanying.png | yuanying | 100 |
| huashen.png | huashen | 150 |
| heti.png | heti | 200 |

**Hardcoded 路径**：`src/systems/presentation/hud_system.gd` `_realm_icon_path()` 已 hardcode 这 7 个路径 — Sprint 11 hud-real-layout 必须复用 service 层接口，不要重新发明路径。

---

## 4. Stance Icons (4 / 4 — 含未实现的 closed_door / idle)

| Asset | Stance Key | 已实现？ |
|-------|-----------|---------|
| meditate.png | meditate | ✅ CultivationSystem.STANCE_MEDITATE |
| condense.png | condense | ✅ CultivationSystem.STANCE_CONDENSE |
| closed_door.png | closed_door | ❌ 资源已生成，姿态尚未在 CultivationSystem 实现 — **Sprint 11 不补，留给后续 sprint** |
| idle.png | idle | ❌ 同上 |

**Sprint 11 mvp-screens (cultivation_screen)** 必须挂载全部 4 个图标到 stance 切换 modal，未实现的 2 个置灰显示"未解锁"，给玩家世界感预告。

---

## 5. Status Icons (5 / 5 — 战斗 / 离线 / 升级 / 溢出全状态点)

| Asset | 触发事件 | 用于位置 |
|-------|---------|---------|
| combat_active.png | `combat.finished` (victory=true) | TOP STRIP 战斗状态点 |
| combat_failed.png | `combat.finished` (victory=false) | TOP STRIP 战斗状态点 + LEFT NAV failure_grey overlay 触发 |
| level_up.png | `level.changed` | TOP STRIP 状态点 + Toast 卡片左侧角标 |
| offline_pending.png | `offline.settled` 后玩家未查看 | TOP STRIP 状态点 + offline drawer 入口角标 |
| overflow_warn.png | `resource.{id}.overflow` | RIGHT PANEL 警告 chip 区 |

**Sprint 11 hud-real-layout S11-006 资源警戒态 story** 必须挂 overflow_warn；**toast-stack S11-007** 必须挂 level_up；**offline-drawer S11-008** 必须挂 offline_pending；**mvp-screens combat_screen** 必须挂 combat_active/combat_failed。

---

## 6. Rarity Frames (8 / 8 — 完整 art-bible 8 阶稀有度)

| Asset | Rarity | 中文 | art-bible Sec 4.3 色阶 |
|-------|--------|------|----------------------|
| common_frame.png | common | 凡品 | 灰白 |
| uncommon_frame.png | uncommon | 精良 | 浅绿 |
| rare_frame.png | rare | 稀有 | 浅蓝 |
| epic_frame.png | epic | 史诗 | 紫 |
| legendary_frame.png | legendary | 传奇 | 橙 |
| mythic_frame.png | mythic | 神话 | 红 |
| innate_frame.png | innate | 先天 | 金 |
| chaos_frame.png | chaos | 混沌 | 渐变（与 burst_gold 共享 #F5C842 token，参 art-bible Sec 4.3 重叠备注） |

**Sprint 11 mvp-screens (resources_screen) 物品 grid** 必须用 9-slice 配 rarity 框（每物品 80×80 单元，frame 包外 8px）；**toast-stack 稀有掉落 toast** 用 epic+ 框作为强调。

**色弱 backup 强制**：art-bible Sec 4.6 要求形状/字角标 backup — frame 文件已自带形状变化（外框纹路），但稀有度文字角标"凡/精/稀/史/传/神/先/混"必须由代码 overlay。

---

## 7. Seals (3 / 3 — 全屏印章覆层)

| Asset | 触发情境 | art-bible Sec 2 状态 |
|-------|---------|---------------------|
| burst_gold.png | 突破成功 / 飞升 / 稀有掉落 | 状态③爆发荣耀 — 全屏 3s 收缩消散 |
| failure_red.png | 战斗团灭 / 渡劫失败 | 状态⑧（暂未编号；与失败灰一起出现） |
| ink_default.png | 普通成就达成 | 默认水墨印章 |

**Sprint 11 hud-real-layout 突破成功流程** + **toast-stack 稀有掉落** 必须用 burst_gold 做 3s 全屏覆层动效（reduced-motion 模式压到 0.5s 不缩放）。

---

## 8. Maps / 区域背景 (5 / 5 — MVP 区域全覆盖)

| Asset | 区域 | 用途 |
|-------|------|------|
| main_base.png | 主基地 / 洞府 | cultivation_screen 背景；临时 hud.tscn 已挂为 Background |
| starter_forest.png | 灵谷起始 | combat_screen starter zone 背景 |
| east_sea_shore.png | 东海岸 | combat_screen end zone 背景 |
| ruined_temple.png | 古庙遗迹 | combat_screen mid zone 背景 |
| town_economy.png | 城镇经济视图 | post-MVP（city/sect screen 占位）— Sprint 11 不接入，但路径登记 |

**Sprint 11 mvp-screens (combat_screen)** 必须根据当前 zone_id 动态切换背景；切换时配合 vfx/zone_transition_ink_wipe（4 帧 sprite sheet 转场动画）。

---

## 9. Overlays (2 / 2 — 全屏覆层)

| Asset | 触发情境 |
|-------|---------|
| failure_grey.png | 战斗失败 — art-bible 状态⑧全屏灰墨覆层 |
| offline_paper.png | 离线 drawer 背景纹理（卷轴质感） |

**Sprint 11 mvp-screens (combat_screen) S11-010** 战斗失败时全屏 fade-in；**offline-drawer S11-008** drawer 主背景必须用 offline_paper 9-slice 拉伸。

---

## 10. Player Character (5 — portrait + 4 动画 sheet)

| Asset | 用途 |
|-------|------|
| portrait.png | cultivation_screen 主角立绘；存档屏头像 |
| idle_sheet.png | combat_screen 队伍位待机动画（AnimatedSprite2D / SpriteFrames） |
| attack_sheet.png | 战斗时攻击动画 |
| hurt_sheet.png | 受击动画 |
| death_sheet.png | 失败动画 |

**注**：sheet 帧数与 fps 配置在 `pipeline-meta.json` 中；mvp-screens (combat_screen) 必须读取 meta 而非 hardcode。

---

## 11. Enemy Sheets (38 PNG — 13 敌人 × 平均 3 PNG)

按 zone 分组（与 zones.json 对齐）：

| Zone | Enemies | PNG 数 |
|------|---------|--------|
| starter_zone | forest_wolf, low_yao_qi, mountain_rat | 9（每敌 portrait+idle+attack） |
| mid_zone | cold_corpse, evil_disciple, ghost_flame（含 projectile） | 10 |
| end_zone | broken_dragon_shadow, reef_shark, sea_yao | 9 |
| current（实验组） | mountain_bandit, training_dummy, wild_wolf | 9 |

**Sprint 11 mvp-screens (combat_screen)** 必须根据 enemy_id 动态加载对应 portrait + idle + attack；ghost_flame 远程敌人额外挂 projectile sprite。

**已知 gap**：每个敌人缺 hurt/death sheet（仅主角有）；Sprint 11 战斗动画用静态闪烁兜底，post-Sprint 11 sprint 补 enemy 受击/死亡。

---

## 12. Item Icons (13 PNG)

| 类别 | 资产 |
|------|------|
| 资源类（5） | low_lingshi, mid_lingshi, high_lingshi, pure_qi_crystal, talisman_paper |
| 草药/原料（3） | blood_ginseng, ling_grass, iron_ore |
| 装备/掉落（4） | dragon_scale, sea_pearl, evil_dust, low_pill |
| 物品包动画（2） | item_pack_basic_sheet, item_pack_rare_sheet（开箱动画 sprite sheet） |

**Sprint 11 mvp-screens (resources_screen) 背包 grid** 必须挂全部 13；**toast-stack 稀有掉落** 必须显示对应 item icon + rarity_frame 组合。

**item_pack_*_sheet** 是开箱动画 sprite sheet — 挂在 toast-stack 的"稀有掉落"特殊 toast 类型上，作为吸引注意力的开箱动画。

---

## 13. VFX (8 PNG)

| Asset | 触发 | 实现 |
|-------|------|------|
| crit_hit_spark.png | 战斗暴击 | combat_screen 单帧 sprite，订阅 `combat.crit` 事件（如未来添加） |
| level_up_ring.png | 升级 | hud-real-layout 等级徽章周围 light ring；订阅 `level.changed` |
| manual_click_pulse.png | 玩家点击修炼按钮 | cultivation_screen ManualButton 的 button_pressed 信号 |
| overflow_warn_flash.png | 资源溢出 | hud-real-layout 资源 row fill bar 闪烁 — 替代纯色闪烁，给水墨笔触感 |
| victory_burst_gold.png | 战斗胜利 | combat_screen + toast-stack 联动 |
| zone_transition_ink_wipe_01..04.png | 区域切换转场 | mvp-screens (combat_screen + cultivation_screen) 切区域时 4 帧 SpriteFrames 转场（120ms） |

**Sprint 11 hud-real-layout S11-005 + mvp-screens combat_screen S11-010** 必须接入；reduced-motion 模式下全部 vfx 压成单帧静态。

---

## 14. Data Configs (9 JSON — 已通过 DataConfigHost 加载)

| File | 消费系统 |
|------|---------|
| attribute_set_config.json | AttributeSystem |
| enemies.json | EnemyDatabase |
| formulas.json | FormulaEngine |
| items.json | ItemRegistry |
| level_realm_config.json | LevelSystem |
| loot_tables.json | LootSystem |
| production_config.json | OutputMultiplierSystem / AutoProductionSystem |
| resource_config.json | ResourceSystem (`_load_resource_definitions_from_config`) |
| zones.json | ZoneSystem |

**Sprint 11 不直接消费**（已在 27 系统逻辑层吃完），仅 mvp-screens (resources_screen) 通过 ItemRegistry 拿到 items.json 内容驱动背包 grid。

---

## 15. Sprint 11 Asset Coverage DoD

每条 Sprint 11 story 在 `Test Evidence` 段必须列出**接入的资产路径**（按本 manifest 编号引用），格式：

```markdown
## Test Evidence

### Asset Coverage
- §2 Resource Icons: lingqi/xiuwei/lingshi/herb/exp (5/5)
- §3 Realm Icons: 7/7（动态切换验证截图 + level_up 强制升级到 lianqi/zhuji/jindan 三档截图）
- §13 VFX: level_up_ring (订阅 level.changed 触发)
- 截图: production/qa/evidence/sprint-11/{story-id}-asset-snap.png
```

Sprint 11 出口 `/team-qa sprint`：
1. **覆盖率脚本**（待写）：扫所有 Sprint 11 .tscn + .gd 中的 `res://assets/` 引用，对照 manifest 计算覆盖率
2. **DoD 阈值**：
   - Theme + Frames + Resource icons + Realm icons + Status icons + Stance icons (in scope) + Maps (5/5) + Overlays + Seals = **必须 100%**
   - Player Character + Item Icons + Rarity Frames + VFX = **必须 100%**
   - Enemy Sheets = **必须 ≥ 80%**（current 实验组允许 0%；starter/mid/end 必须 100%）

---

## 16. 资产路径不变性约定

- 已 Codex pipeline 生成的 PNG 路径**永久 freeze**（除 art-director 决定重命名族）
- 重生成 PNG 通过 pipeline 覆盖原文件，路径不变 → .tscn / .gd 不需修改
- 新增 PNG 必须先在本 manifest 登记 + 通过 `/asset-spec` skill 走完审批流，才能在 Sprint 11 .tscn 中 ExtResource 引用
- 删除 PNG 必须 grep 全项目 `res://assets/...` 引用并连带清理

---

## 17. 已知缺口（Sprint 11 范围外）

| 缺口 | 影响 | 立项归宿 |
|------|------|---------|
| Enemy hurt/death sheet | combat_screen 失败/受击动画兜底 | Sprint 12 (post-MVP polish) |
| stance closed_door / idle 系统未实现 | cultivation_screen modal 4 选 2 置灰 | Sprint 12 闭关系统扩展 |
| town_economy 城镇屏未立项 | 资产已就绪但无消费方 | Sprint 13 (城镇 / 宗门) |
| Boss 系统专属 portrait | 当前 enemies/{zone} 无 boss 区分 | Sprint 12 boss 副本 |
| 字体资产 | theme.tres 用 Godot 默认字体；中文字号 ≥ 20px 需要主题字体（思源黑/宋等） | Sprint 11 nice-to-have，独立 epic |
