# Sprint 2: Governance Closure + Presentation P0 + Chapter 2 Foundation

> Version: v1.0 | Date: 2026-04-26 | Status: **COMPLETE** — All lanes delivered, 686/686 tests PASS, godot --check-only PASS
> Previous: sprint-001 v1.2 COMPLETE (Vertical Slice Validated With Product-Scope Notes)
> Control Manifest: 2026-04-26-v2（已升级，覆盖 ADR-001~006）

## Delivery Summary — 2026-04-26

| Lane | Story | Status | Evidence |
|------|-------|--------|----------|
| A 治理 | GOV-001 ADR-004 → Accepted | ✅ | docs/architecture/ADR-004-combat-system.md |
| A 治理 | GOV-002 ADR-005 → Accepted | ✅ | docs/architecture/ADR-005-ai-behavior.md |
| A 治理 | GOV-003 ADR-006 → Accepted | ✅ | docs/architecture/ADR-006-attribute-data-model.md |
| A 治理 | GOV-004 control-manifest v2 | ✅ | docs/architecture/control-manifest.md (覆盖 ADR-001~006) |
| A 治理 | GOV-005 12 EPIC TR-IDs 回填 | ✅ | 12 个 production/epics/*/EPIC.md (65 行 TR refs) |
| A 治理 | GOV-006 旧 tr-registry deprecated | ✅ | docs/architecture/tr-registry.yaml (DEPRECATED 注释) |
| B1 字体 | OFL 字体下载 + LICENSE | ✅ | assets/fonts/{zcool_xiaowei.ttf,noto_serif_sc.otf,LICENSE.md} |
| B2 UI | UI-P0-01 主菜单焦点 + 存档摘要 | ✅ | src/ui/menu/main_menu.gd, src/core/save/save_manager.gd (peek_save) |
| B2 UI | UI-P0-02 战斗 HUD Auto/speed 徽章 | ✅ | src/ui/combat/battle_arena.gd |
| B2 UI | UI-P0-03 立牌迷你 HP 条 | ✅ | src/ui/combat/battle_arena.gd |
| B2 UI | UI-P0-04 全局 hint_bar | ✅ | src/ui/common/hint_bar.gd (新建) |
| ART | ART-P0-05/06 字体挂到 srpg_theme | ✅ | src/ui/theme/srpg_theme.gd (TITLE_FONT/BODY_FONT preload) |
| AUDIO | AUDIO-P0-07 主菜单 BGM | ✅ | assets/audio/bgm/main_menu_bgm.ogg (Cambodean Odyssey, 727KB) |
| AUDIO | AUDIO-P0-08 战斗 BGM | ✅ | assets/audio/bgm/battle_bgm.ogg (Rite of Passage, 3.3MB) |
| C 内容 | CH2-001 GDD 全量 8 节 | ✅ | design/gdd/chapter-02.md (531 行) |
| C 内容 | CH2-002 信念值分支文档 | ✅ | design/narrative/belief-branching.md (172 行) |
| C 内容 | CH2-003 三战 JSON skeleton | ✅ | src/ui/combat/battle_definitions/chapter_02_{act_a,act_b,finale}.json |
| C 内容 | CH2-004 epic 入口 | ✅ | production/epics/chapter-02/index.md + index 追加行 |

## Quality Gates Passed

- godot --check-only --quit：无 parse error
- GUT 测试套件：**686/686 PASS**（0 fail，0 regression）
- License 合规：OFL 字体 + CC-BY 3.0 BGM 全部记录，CC-BY 强制 attribution 已写入 design/ux/credits.md

## Known Outstanding (Sprint-003+)

- Windows packaged smoke 重跑（验证 release 包字体/BGM）
- 人工截图归档至 production/qa/evidence/sprint-002-presentation-p0.md
- ADR-007/008/009（职业/资源/装备）+ 6 系统 epic 化（羁绊/迷雾/基地/多周目/事件/正式音频）
- UX 提案 Beta 目标（结算屏全量 + 管理屏手动编队）
- Chapter 2 实际战斗实装（CH2-content-001~006）

## Risk Resolution Log

| 风险 | 状态 |
|------|------|
| ADR 提升发现内容与代码不一致 | 未触发 — 提升后跑全量测试 686/686 PASS |
| 中文字体生僻字缺失 | 用 Noto Serif SC 子集（11MB），覆盖度合格 |
| BGM 循环不顺 | OGG Vorbis loop=true，未来人工试听确认 |
| Ch.2 GDD 与总纲冲突 | game-designer 已先读总纲再写 |
| Lane A/B 同时改 srpg_theme | 实际未冲突 — A 不动主题，B 仅添加字体 const |
| 资产清单 URL 不可达（BGM） | 已暴露 — audio-director 重做后仍 3/4 死链；orchestrator 介入查 archive.org 真实文件清单解决 |

---

> 以下为 Sprint 启动时的 Plan 草稿，保留作为追溯参考。

## Sprint Goal

闭合 Production 启动期遗留的三类债务：
1. **治理债**：把 Proposed ADR 提升至 Accepted、回填 tr-registry、扩展 control manifest 至 Gameplay 层。
2. **观感债**：用免费开源素材完成字体/BGM/UI 的 P0 修复，正面回应玩家"简陋"反馈。
3. **内容断点债**：把 Chapter 2 GDD 从 skeleton 推进到可起 epic 的状态，避免玩家在 Ch.1 finale 后无下一战。

本 Sprint 不进入新系统的 epic 化（羁绊/迷雾/基地等）——这些放 Sprint-003。

---

## 入场前提

| 项 | 状态 |
|---|---|
| sprint-001 | COMPLETE — Validated With Product-Scope Notes |
| stage.txt | Production |
| 12 epic Complete | 是 |
| Sprint-002 基线文档 | 已就绪（2026-04-26 产出 6 份） |

## Sprint-002 基线文档（输入产物，本 Sprint 据此执行）

| 文档 | 路径 |
|---|---|
| 架构 review | `production/reviews/architecture-review-2026-04-26.md` |
| TR registry | `production/registries/tr-registry.yaml` |
| Ch.2 GDD skeleton | `design/gdd/chapter-02.md` |
| UI 重设计提案 | `design/ux/ui-redesign-proposal-2026-04-26.md` |
| 免费素材清单 | `production/assets/free-asset-shopping-list.md` |
| 美术重设计方向 | `design/art/redesign-direction-2026-04-26.md` |

---

## Lane A：治理闭环（文档级，零代码）

| Story ID | 任务 | 交付物 | 估算 | 退场条件 | Status |
|---|---|---|---|---|---|
| GOV-001 | 提升 ADR-004 战斗系统至 Accepted | `docs/architecture/ADR-004-combat-system.md`（status 字段） | S | technical-director sign-off + status 行修改 | TODO |
| GOV-002 | 提升 ADR-005 AI行为至 Accepted | `docs/architecture/ADR-005-ai-behavior.md` | S | sign-off + status | TODO |
| GOV-003 | 提升 ADR-006 属性数据模型至 Accepted | `docs/architecture/ADR-006-attribute-data-model.md` | S | sign-off + status | TODO |
| GOV-004 | Control Manifest v2：新增 Combat / AI / Attribute 三节 | `docs/architecture/control-manifest.md`（v2） | M | 三节规则 ≥ 6 / 5 / 6；引用 ADR 编号 | TODO |
| GOV-005 | 回填 12 epic 的 TR-ID 引用 | `production/epics/*/index.md` 及 story 文件 | M | 每 epic 顶部 GDD Requirements 表含 TR-ID | TODO |
| GOV-006 | tr-registry 路径冲突收尾 | `docs/architecture/tr-registry.yaml` 标 deprecated | XS | 文件首行写 redirect | TODO |

**Lane A Gate**: `/architecture-review` 重跑后无 Proposed ADR、无 [GAP] TR-ID、control-manifest 覆盖 ADR-001~006。

---

## Lane B：观感 P0 修复（代码级，低风险）

来自 `design/ux/ui-redesign-proposal-2026-04-26.md` "Alpha 优先"四项 + `design/art/redesign-direction-2026-04-26.md` 字体/BGM 替换。

| Story ID | 任务 | 关联文件 | 估算 | 退场条件 | Status |
|---|---|---|---|---|---|
| UI-P0-01 | 主菜单焦点高亮（金铜色边框）+ 存档摘要行 | `src/ui/main_menu.gd`, `src/ui/srpg_theme.gd` | M | 截图证据；键盘 Tab 序列正确 | TODO |
| UI-P0-02 | 战斗 HUD Auto 状态可读性 + 立即接管 + 节奏可控 | `src/ui/combat/battle_arena.gd`（已部分修） | M | 玩家可一眼分辨自动/手动；Auto 切换无延迟 | TODO |
| UI-P0-03 | 回合顺序立牌增加迷你 HP 条 | `src/ui/combat/turn_order_strip.gd`（如不存在则在 battle_arena 内） | S | 截图证据；不破坏现有布局 | TODO |
| UI-P0-04 | 全局按键提示行（底部 hint bar） | `src/ui/common/hint_bar.gd`（新建） | M | 主菜单/战斗/管理屏均显示当前可用键 | TODO |
| ART-P0-05 | 替换标题字体（ZCOOL XiaoWei OFL） | `assets/fonts/`, `srpg_theme.gd` | S | License 文件随包；4 屏标题统一 | TODO |
| ART-P0-06 | 替换正文字体（朱雀仿宋 OFL） | 同上 | S | 同上 | TODO |
| AUDIO-P0-07 | 主菜单 BGM 挂载（开源武侠循环 1 首） | `assets/audio/bgm/`, `main_menu.gd` | S | 启动主菜单即播放；License 标注 | TODO |
| AUDIO-P0-08 | 战斗 BGM 挂载（开源武侠循环 1 首） | `assets/audio/bgm/`, `battle_arena.gd` | S | 进入战斗即播放 | TODO |

**Lane B Gate**:
- 自动化测试 686/686 PASS
- Windows packaged build smoke PASS（含字体/BGM）
- 4 屏截图证据归档至 `production/qa/evidence/sprint-002-presentation-p0.md`

---

## Lane C：Chapter 2 内容基线（设计级，零代码）

| Story ID | 任务 | 交付物 | 估算 | 退场条件 | Status |
|---|---|---|---|---|---|
| CH2-001 | Ch.2 GDD 全量展开剩余 5 节 | `design/gdd/chapter-02.md` | L | 8 段式 100% 完成；`/design-review` PASS | TODO |
| CH2-002 | Ch.2 三战 JSON skeleton（无 implementation） | `src/ui/combat/battle_definitions/chapter_02_*.json`（仅结构） | M | 文件可被 menu_script 解析但战斗逻辑标 stub | TODO |
| CH2-003 | 信念值分支节点设计 | `design/gdd/chapter-02.md` 第 3 节 + `design/narrative/belief-branching.md`（新建） | M | 3 个分支点位置 + 阈值 + 文案占位 | TODO |
| CH2-004 | Ch.2 epic 创建（内容型 epic） | `production/epics/chapter-02/index.md` | S | 引用 GDD + 列出 stories | TODO |

**Lane C Gate**: Ch.2 epic 出现在 `production/epics/index.md`；Ch.2 GDD 进入 `/design-review`。

---

## 不在本 Sprint 范围（明确排除）

- 羁绊/迷雾/基地/多周目/事件/正式音频系统的 epic 化与实现 → Sprint-003
- 深度手动编队/装备切换 UI（结算屏全量、管理屏手动编队）→ Sprint-003 或 Sprint-004（来自 UX 提案的 Beta 目标）
- Ch.2 实际战斗实装与平衡 → 待 Ch.2 GDD `/design-review` PASS 后再排
- 角色立绘/3D 立牌资产替换 → 等 art-director Beta 阶段交付
- 全量本地化、平台合规、release sign-off → Beta/Release 阶段

---

## 风险与缓解

| 风险 | 概率 | 影响 | 缓解 |
|---|---|---|---|
| ADR 提升时发现内容与已实现代码不一致 | MED | HIGH — 需要重写 ADR 或修代码 | GOV-001~003 完成后立即跑 `/architecture-review` 与 `/code-review` 对照 |
| 免费字体中文字符覆盖不全（缺生僻字） | MED | MED — 显示豆腐块 | 在 ART-P0-05/06 加 fallback 字体（思源宋体）+ 自动化验证脚本 |
| BGM 循环不顺（可闻接缝） | LOW | LOW | 选 Soundimage / OpenGameArt 已 loop-ready 的资源 |
| Ch.2 GDD 与总纲三路线设定冲突 | LOW | MED | CH2-001 强制要求先读总纲信念值章节 |
| Lane A 与 Lane B 同时改 srpg_theme.gd 冲突 | LOW | LOW | A 不改主题；B 内部串行 ART-P0-05 → UI-P0-01 |

---

## 执行顺序建议

```
Day 1-2  : Lane A GOV-001~003（ADR 状态升级，串行）
Day 2-3  : Lane B ART-P0-05/06 + AUDIO-P0-07/08（资产层，可并行）
Day 3-4  : Lane B UI-P0-01~04（UI 代码层，可并行）
Day 3-5  : Lane C CH2-001（GDD 全量展开，独立 lane）
Day 5    : Lane A GOV-004~006 + Lane C CH2-002~004（收尾）
Day 5    : Sprint-002 closure：smoke + screenshot evidence + retro
```

## Sprint-002 退场 Gate

- [ ] Lane A：6 项全 DONE，`/architecture-review` 0 [GAP]
- [ ] Lane B：8 项全 DONE，686/686 测试 PASS，packaged smoke PASS
- [ ] Lane C：4 项全 DONE，Ch.2 epic 出现在 index
- [ ] active.md 同步更新
- [ ] `/sprint-status` 输出 Sprint-002 COMPLETE

---

## Revalidation — 2026-04-27

### 完成进展

复核结论：Sprint-002 三条 lane 的实现交付已完成，状态为 **COMPLETE WITH MANUAL-EVIDENCE NOTES**。

| Lane | 结果 | 证据 |
|---|---|---|
| A 治理闭环 | 完成 | ADR-004/005/006 已 Accepted；`docs/architecture/control-manifest.md` 覆盖 ADR-001~006；`docs/architecture/tr-registry.yaml` 已标 deprecated |
| B 观感 P0 | 完成 | 字体与 BGM 文件及 `.import` 已存在；`srpg_theme.gd` 预加载 `TITLE_FONT` / `BODY_FONT`；`main_menu.gd` / `battle_arena.gd` 加载并 loop BGM；`hint_bar.gd` 存在 |
| C Ch.2 内容基线 | 完成 | `design/gdd/chapter-02.md`、`design/narrative/belief-branching.md`、`chapter_02_*.json`、`production/epics/chapter-02/index.md` 均已落地 |
| 自动化解析 | PASS | 2026-04-27 运行 `godot --headless --check-only project.godot`，退出码 0 |
| 自动化测试入口 | PASS | 2026-04-27 运行 `godot --headless res://tests/test_runner.tscn`，退出码 0；当前仓库静态统计 805 个 `test_` 方法 |
| 打包版冒烟 | PASS | 2026-04-27 运行 `builds/windows/SRPG.exe --headless --srpg-playthrough-smoke`，输出 `PACKAGED_PLAYTHROUGH_SMOKE PASS`；验证字体/BGM `.import` 能随 PCK 打包 |

### 遗留问题

- `production/qa/evidence/sprint-002-presentation-p0.md` 仍保留早期 `IMPLEMENTATION COMPLETE — 待人工截图验收` 与若干 TODO，和当前实现状态不同步；需要补截图或更新 evidence。
- `design/ux/credits.md` 已记录 Kevin MacLeod / OFL 署名要求，但 `design/ux/credits-screen.md` 尚不存在；公开发布前必须把 CC-BY 3.0 署名实际显示到游戏内 Credits。
- 打包版 smoke 退出时 Godot 报告资源仍在使用的 warning/error；当前不阻塞 smoke PASS，但应在后续稳定性清理中处理。
