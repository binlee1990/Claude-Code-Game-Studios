---
name: 章节进度状态
description: Ch.1 三战已实现并通过 686 测试；Ch.2 GDD v1.0 全量完成（8节）；Ch.2 三战 JSON skeleton 已建立；信念值分支文档已建立；Ch.2 epic 已入 index
type: project
---

Ch.1 已完成三场战斗（tutorial / crossroads / finale），全部通过 686 自动化测试，有打包 Release 证据（2026-04-25）。

Ch.2（"义路歧途"）设计文档和 skeleton 已于 2026-04-26 全量完成（Sprint-002 Lane C）：

- `design/gdd/chapter-02.md`：531 行，8 节全量，含三战规则、护卫姿态机制、Boss 三阶段、分叉路由、Formulas、Edge Cases、Tuning Knobs、Acceptance Criteria。
- `design/narrative/belief-branching.md`：信念值三路线矩阵，含 Ch.1-Ch.3 节点坐标、阈值、soft/hard lock 时点。目录 `design/narrative/` 本次新建。
- `src/ui/combat/battle_definitions/chapter_02_act_a.json`：营地之争（enemy_stat_multiplier=1.10）。
- `src/ui/combat/battle_definitions/chapter_02_act_b.json`：双分支文件（mercy 护送战 / suppression 镇压战，branch_variant 运行时解析，enemy_stat_multiplier=1.15）。
- `src/ui/combat/battle_definitions/chapter_02_finale.json`：飞骑营决战 Boss·陈朗三阶段（enemy_stat_multiplier=1.30，援军第 12 回合）。
- `production/epics/chapter-02/index.md`：6 stories，Status=Planning。
- `production/epics/index.md`：已追加 chapter-02 行（Layer=Content）。

**关键设计决策：**
- B2-GATE 分叉阈值 = 5（义领先 ≥5 走 suppression；平局默认 mercy）
- 王秀 HP=30，护卫姿态分摊比=30%
- Ch.2-3 援军：第 12 回合刷新（Boss 阶段三时提前至第 10 回合）
- 信念值 soft_lock 阈值 = 20（领先差值），hard_lock 阈值 = 40（Ch.4 中段）

**Why:** Ch.1 finale 后无下一战是 P0 内容断点；Lane C 完成后 Ch.2 可进入 `/design-review` 并排 epic stories。

**How to apply:** Ch.2 实际战斗实装需等 `/design-review design/gdd/chapter-02.md` PASS 后排 Sprint-003 stories。
boss-system GDD 和 bond-system GDD 尚不存在（Sprint-003 建立）；CH2-content-005 和部分叙事功能依赖这两个系统。
