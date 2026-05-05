# Active Session State

**Updated**: 2026-05-05（Player Experience Glue — 全部 6 份文档完成）

## Current Task

MVP Player Experience Glue ✅ — 30 系统 MVP 现在有了完整的"组装说明书"和"体验脚本"。

## 本次 session 完成：Experience Glue（6 份新设计文档）

| Phase | 文档 | Agent | 规模 | 状态 |
|-------|------|-------|------|------|
| A | `design/narrative/world-skeleton.md` | narrative-director | ~400 行 | ✅ |
| A | `design/balance/mvp-content-progression.md` | systems-designer | ~500 行 | ✅ |
| B | `design/experience/player-journey-map.md` | game-designer | ~450 行 | ✅ |
| B | `design/experience/screen-flow.md` | ux-designer | ~500 行 | ✅ |
| C | `design/experience/onboarding-flow.md` | ux-designer | ~450 行 | ✅ |
| C | `design/experience/session-loop.md` | game-designer | ~600 行 | ✅ |

## 之前 session 完成

| 阶段 | 动作 | 结果 |
|------|------|------|
| Phase 1 UX Design | 5 个 UX spec 起草 + /ux-review | cultivation ✅ Reviewed / 4 others ✅ Draft |
| Phase 2 Visual Design | art-director 产出视觉设计规范 | ✅ `visual-design-sprint-11.md`（~700 行） |
| Phase 3 UI Implementation | Sprint 11 代码实现 | ✅ 17 .gd scripts + HUD shell + 5 screens |

## 新增设计资产概览

### 世界观层（1 文件）
`design/narrative/world-skeleton.md`
- 境界命名：凡→炼→筑→金→元（MVP 5 境）+ 预留至合道（Phase 2+）
- 3 区域：青丘山林 / 幽墟灵谷 / 荒殒战场（完整主题+环境+敌人+叙事钩子）
- 开局文本：标题画面 + 首次修炼 + 首次战斗（各 1-2 句，沉浸式）
- 术语表：11 MVP 术语 + 12 Phase 2+ 术语
- 渐进叙事展开：开局仅修炼、境界=叙事门禁、留白给想象
- 6 个叙事锚点（为宗门/法宝/天劫/飞升/秘境/功法系统预埋）

### 数值层（1 文件）
`design/balance/mvp-content-progression.md`
- 15 个敌人完整属性表（含威胁评分，数值自洽验证通过）
- 3 区域掉落表（必定+概率掉落+权重+数量范围）
- Lv.1-30 逐级经验表 + 属性成长 + 战力评分
- 装备体系：4 品质 / 属性范围 / 区域对应
- 经济平衡：灵石产出/消耗、离线倍率曲线（4h 100% → 24h 50%）
- 5 个卡点位置与突破方式 + 3 种通关时长预估

### 体验层（4 文件）
`design/experience/player-journey-map.md`
- 8 个时间节点五维度分析（触发/所见/所做/所感/系统状态）
- 情感曲线（3 峰值+4 低谷+4 拐点）
- 6 个关键决策点（A/B 选项+信息支持+后果）
- 5 大流失风险评估（原因+缓解策略）
- 7 条 FTUE 核心原则

`design/experience/screen-flow.md`
- Mermaid 导航拓扑图 + Modal 触发条件总览
- 8 步渐进 UI 解锁序列（冷启动→全屏激活）
- LEFT NAV 可见性状态机（3 状态 × 5 Tab）+ ASCII 时间线
- 屏间数据流（EventBus + 共享 Service 双轨模式）
- Toast 5 级优先级 + 屏切换动画原则
- 7 个边界情况（战斗切屏/离线抽屉/存档锁屏/首次vs回归/时间冻结）

`design/experience/onboarding-flow.md`
- 5 条引导原则（不教只暗示、每阶段一行为、解锁=叙事事件、首X必有正反馈、灰度预告）
- 7 项明确禁止项（弹窗教程、强制点击、信息轰炸、系统宣告、教程敌人、引导箭头、虚假buff）
- 6 阶段引导流程（0:00→首次回归，每阶段5维度）
- HUD 字段密度梯度（4→12）+ LEFT NAV 激活节奏（1→5 Tab）
- 首战必胜数学护航 + 首次突破 0% 失败率 + 首次离线收益下限
- 13 项 P0-P3 可调参数

`design/experience/session-loop.md`
- 4 类会话定义（微<1min/短1-5min/标准5-20min/长20min+）+ 玩家画像覆盖
- 3 种回归入口（离线回归三层层递进/在线切回5行摘要/冷启动差异化）
- 4 核心决策流（去哪→怎么配→何时推→何时退出），每个有 UI 呈现+默认值
- 每日 4 时段节奏（早晨/午间/晚间/睡前）
- 4 层回归牵引（离线收益预览→进度预估→未完成目标记忆→新内容暗示）
- 22 个 225 系统编号的扩展标注

## 关键不变量

- **未修改 30 GDD** — 设计 baseline 保持
- **未修改 15 ADR** — 架构决策保持
- **未修改 27 系统逻辑代码** — 服务层 frozen
- **未修改 8 UX Spec** — 单屏 UX 保持
- **未修改 117 资产路径** — manifest 不变
- **新增 4 个 design/ 子目录**: narrative/、balance/、experience/（新建）
- **新增 6 份设计文档** — 全部可交付给 Sprint 12 story 拆解

## Next Steps

1. **用户审阅** — 6 份文档均需确认：世界观命名、数值曲线、引导流程、会话节奏
2. **Entity Registry** — systems-designer 建议将 15 敌人 ID + 3 区域 ID + 新增物品 ID 注册到 `design/registry/entities.yaml`
3. **Sprint 12 规划** — 基于这些文档拆解 story：
   - 新手引导实现（onboarding-flow.md → FTUE stories）
   - 数据配置落地（mvp-content-progression.md → enemy/loot/zone data stories）
   - 离线结算体验（session-loop.md → settlement UX stories）
   - 渐进 UI 解锁（screen-flow.md → UI state machine stories）
4. **Stage 1 完整性检查** — 确认体验层设计覆盖 game-concept.md §11 MVP 定义的全部需求
5. **225 系统扩展一致性** — 6 份文档共预留 ~30 个 Phase 2+ 扩展标注，需验证叙事锚点与系统编号对应

<!-- STATUS -->
Epic: MVP Player Experience Glue
Feature: 6 份体验层设计文档 — 连接 30 系统与可玩游戏
Task: All 6 documents complete — 总计 ~2,900 行设计规范
<!-- /STATUS -->
