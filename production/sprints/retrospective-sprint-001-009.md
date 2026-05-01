# Sprint 回顾汇总 — Sprint-001~009

> **类型**: 批量补做（Sprint-001~009）
> **生成日期**: 2026-05-01
> **方法**: 基于 git log + sprint plans + session-state 历史记录

---

## Sprint-001 (2026-04-21 → 2026-04-25)

**Goal**: Vertical Slice — 可玩的第一章战斗路径

### 完成了什么
- 13 stories: turn-based-mode (7) + battle-settlement (5) + camera-map-system (3) + ui-system (3)
- 从 2.5D 回退到 2D top-down（玩家反馈：可读性不足）
- Speed-up mode (1×/2×/3×) + Auto battle
- Windows packaged build 可试玩包
- 447→686 test functions，全 PASS

### 学到了什么
1. **视觉可读性 > 技术炫技**: 2.5D HD-2D 投射在 15×15 网格上不可读，2D top-down 明显更好
2. **验证驱动开发有效**: 每个 story 完成后立即测试，Sprint-001 的 0 回归问题归功于此
3. **人工验证不可替代**: 视觉/手感问题无法通过 unit test 发现

### 下次改进
- 战斗地图尺寸和分辨率应在设计阶段就确定
- 应在 Pre-Production 就做视觉 prototype，而非到 Production 才发现问题

---

## Sprint-002 (2026-04-26)

**Goal**: 治理闭环 + 观感 P0 修复 + Ch.2 内容基线

### 完成了什么
- Lane A (治理): ADR-004~006 → Accepted, control-manifest v2, TR registry 规范化
- Lane B (观感): 字体 + BGM + 主菜单焦点 + Auto 状态 + 迷你 HP 条 + 按键提示
- Lane C (内容): Ch.2 GDD + belief-branching + 三战 JSON + epic

### 学到了什么
1. **资产链验证需基于真实目录**: audio-director 的 BGM 清单 4/4 死链，必须直接 curl archive.org 获取文件清单
2. **ADR 状态与实现进度分离会积累债**: ADR-004~006 在 12 epic 完成时仍为 Proposed — 应同步推进
3. **三 lane 并行有效但需协调**: Lane B 的字体/BGM 变更不影响 Lane C 的内容设计，三者独立

### 下次改进
- 每完成一个 epic 实现，立即审查对应 ADR 的 status
- 资产来源验证使用脚本而非 agent 搜索

---

## Sprint-003 (2026-04-26)

**Goal**: Ch.2 从 GDD skeleton 推进到玩家可玩的三战完整内容

### 完成了什么
- 6 Must Have + 3 Should Have: Ch.2 路由+B2-GATE, 王秀 AI (A*+畏缩), 护卫姿态, 镇压战结算, Boss 三阶段+检查点, 果子二选三
- 686→776 test functions，全 PASS
- 5 天 sprint 压缩为 3 天（Day 1-3）

### 学到了什么
1. **AI 行为调参是最大的时间黑洞**: 王秀 A* + 畏缩 AI 花费了比其他 story 更多的时间
2. **Boss GDD 是硬前置**: CH2-c-005 依赖 boss-system GDD，提前创建避免了阻塞
3. **果子选择系统与信念值系统的交互比预期简单**: 二选三的逻辑（选择保留 3 个中的 2 个）仅 12 tests 就完全覆盖

### 下次改进
- AI 调参 story 应给予更多时间预算
- 信念值系统的乘法效应应在更早 sprint 验证

---

## Sprint-004 (2026-04-26 → 2026-05-01)

**Goal**: 管理界面 Beta + 基地系统 MVP

### 完成了什么
- 5 Must Have + 3 Should Have: 角色/装备管理 UI, 基地 Hub, 训练场, 市集
- Inventory 提升为 Autoload
- 1 Nice to Have 遗留 (BASE-004 Ch.2 人工 playtest)

### 学到了什么
1. **管理 UI 的复杂度被低估**: 角色/装备/基地三个 Tab 的整合比预期多花了时间
2. **Inventory 提升为 Autoload 是正确的**: 早期使用局部实例导致 save/load 不一致
3. **人工验证始终是瓶颈**: Sprint-004~008 的 visual sign-off 始终 pending

### 下次改进
- 管理 UI 应先做 UX spec 再写代码
- 人工验证任务应明确 owner 和 deadline

---

## Sprint-005 (2026-04-27)

**Goal**: 本地化 + Credits + Governance 同步

### 完成了什么
- 5 Must Have + 4 Should Have + 5 Nice to Have
- `srpg_localization.gd` 中/英切换
- Credits overlay + release readiness epic
- ADR-008/009 (资源经济/装备升级) Accepted

### 学到了什么
1. **本地化 scaffold 做对了**: 字符串在代码中仍 hardcode，但架构已支持运行时切换
2. **Governance 同步很便宜**: LOC/GOV/REL epics 仅需 0.25d 每个，效果显著
3. **BGM resource leak 修复很关键**: packaged build 中的 ObjectDB leak warning 被修复

### 下次改进
- 本地化字符串提取应在有 translator 可用时集中做一次

---

## Sprint-006 (2026-04-27)

**Goal**: Bond MVP + Equipment Enhancement + Base Phase 1

### 完成了什么
- BondRegistry + affinity 事件钩子
- Equipment enhancement UI (equipped items only)
- Base AP + Intel Room
- Ch.3 GDD skeleton
- Packaged smoke PASS

### 学到了什么
1. **Bond MVP 微缩正确**: 仅 1 个源文件 + 2 个测试文件实现了完整的 affinity 数据模型
2. **Equipment enhancement UI 从 equipped items 开始是对的**: 范围可控，没有打开完整 forge scope
3. **基地行动点系统为后续 sprint 提供了坚实的基础**

### 下次改进
- 组合技实现应更早规划 — Sprint-006 仅做了数据模型

---

## Sprint-007 (2026-04-27)

**Goal**: Ch.3 Battle 1 + Base Tavern/Upgrade + Equipment Risk Zone

### 完成了什么
- Ch.3 battle 1 boot/victory
- Base Tavern tab (affinity 对话)
- Base Upgrade tab
- Equipment +6~+10 risk zone + protection symbol
- Architecture full review + export + smoke PASS

### 学到了什么
1. **Risk zone 的 failure/downgrade 反馈是 UX 关键**: 失败时保护符号消耗的视觉提示需要足够明显
2. **Tavern affinity 对话复用 BondRegistry 是正确决策**
3. **Architecture full review 在 sprint 末尾做比推迟到 release 前有效**

---

## Sprint-008 (2026-04-27)

**Goal**: Ch.3 内容完成 + 装备养成收口

### 完成了什么
- Ch.3 Battle 2 (pressure scoring)
- B3-GATE (belief branch activation)
- Ch.3 Finale (Boss + route variant)
- Equipment decomp/reroll UI
- Architecture.md 补全 + ADR 001~009 fixups
- Bond combo GDD + Fog GDD
- 879/879 PASS

### 学到了什么
1. **Ch.3 三战 + B3-GATE + Finale 的复杂度超出了单个 sprint 的容量**，但通过高效的故事拆分得以完成
2. **Decomp/Reroll UI 是玩家养成闭环的关键入口**，不应再推迟
3. **GDD-only 交付（Bond Combo / Fog）为 Sprint-009 提供了清晰的设计输入**

---

## Sprint-009 (PLANNING — 2026-05-01)

**Goal**: Vertical Slice 系统收尾（fog / bond-combo / difficulty / boss）

### 当前状态
- 计划 12 stories: 7 Must Have + 3 Should Have + 2 Nice to Have
- ADR-010~013 已创建 (2026-05-01)
- difficulty/boss epic 已创建
- QA plan 已生成
- TR registry 已更新
- Project stage report 已更新

---

## 跨 Sprint 趋势

### Velocity
| Sprint | Stories | Test Δ | Duration |
|--------|---------|--------|----------|
| 001 | 13 | +686 | 4d |
| 002 | 18 | +0 (全部非代码) | 1d |
| 003 | 9 | +90 | 3d |
| 004 | 8 | +0 (全部 UI) | 1d |
| 005 | 13 | 0 (大部分非代码) | 1d |
| 006 | 6 | +? | 1d |
| 007 | 10 | +? | 1d |
| 008 | 10 | +? (879 total) | 1d |
| **009** | **12** | **TBD** | **5d (planned)** |

### 持续改进项
1. **Sprint 持续时间不均匀**: 001 耗时 4 天，002-008 各耗时 ~1 天（部分 sprint 在同一天完成）。Sprint-009 计划回归 5 天标准周期。
2. **测试始终健康**: 从 447→879 tests, 0 failures 从未破窗
3. **ADR 债务**: Sprint-001~008 仅 9 ADR，Sprint-009 启动前补全至 13 ADR
4. **人工验证积压**: visual sign-off / UX review 始终未完成

---

## Action Items

| # | 行动 | 负责人 | 优先级 |
|---|------|--------|--------|
| 1 | 执行 Sprint-009 12 stories | Agent (gameplay/ui programmer) | P0 |
| 2 | 完成人工 UX/visual sign-off | Human (binlee1990) | P1 |
| 3 | 创建 event-system epic | game-designer agent | P2 |
| 4 | 创建 new-game-plus epic | game-designer agent | P2 |
| 5 | 执行 gate-check (Production → Polish readiness) | technical-director agent | P2 |
| 6 | 生成 changelog (player-facing) | community-manager agent | P2 |
| 7 | 生成 launch-checklist | release-manager agent | P2 |
