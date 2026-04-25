# Sprint 2: Governance Closure + Presentation P0 + Chapter 2 Foundation

> Version: v0.1 | Date: 2026-04-26 | Status: PLANNING
> Previous: sprint-001 v1.2 COMPLETE (Vertical Slice Validated With Product-Scope Notes)
> Control Manifest: 2026-04-23-v1（本 Sprint 内将升 v2）

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
