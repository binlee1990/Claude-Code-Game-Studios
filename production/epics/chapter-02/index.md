# Epic: Chapter 2 Content

> **Layer**: Content
> **GDD**: design/gdd/chapter-02.md
> **Narrative Reference**: design/narrative/belief-branching.md
> **Architecture Module**: Content / Combat
> **Status**: Content - Ready for Playtest
> **Stories**: 6 stories created (placeholders — implement after GDD /design-review PASS)

## Overview

实现第二章"义路歧途"的全部内容：三场战斗（营地之争、护送/镇压分支、飞骑营决战）、
信念值首次分叉路由、NPC 护送机制（王秀保护战）、Boss·陈朗三阶段战斗、以及章节结算
果子二选三界面。本 epic 是 Ch.1 结束后的第一个叙事内容扩展，也是信念值三路线机制
第一次产生玩家可感知差异的关键节点。

## Governing ADRs

| ADR | Decision Summary | Engine Risk |
|-----|-----------------|-------------|
| ADR-001: Event Architecture | 信念值节点变更、NPC 退场剧情通过事件总线传播 | LOW |
| ADR-003: Save System | chapter_02_complete、belief_branch、wang_xiu_departed、fruit_selection 持久化 | LOW |
| ADR-004: Combat System（Proposed） | 护送战 NPC AI、护卫姿态伤害分摊、援军刷新回合计数 | MED — 待 Accepted |
| ADR-005: AI Behavior（Proposed） | 王秀 A* 寻路、畏缩判断、豪强骑士 aggressive AI | MED — 待 Accepted |

> Note: TR-IDs not yet registered. Placeholder IDs used. Run `/architecture-review` to populate after ADR-004/005 are Accepted.

## GDD Requirements

| Source | Requirement | TR-ID Placeholder |
|--------|-------------|-------------------|
| Detailed Rules §3.2 | 开场叙事选择（驱散/收留）影响战场布局和 NPC 出场 | TR-ch2-001 |
| Detailed Rules §3.3 | 护送战：王秀 A* 移动 + 畏缩判断 + 安全区到达判定 | TR-ch2-002 |
| Detailed Rules §3.4 | 护卫姿态：相邻我方单位分摊 30% 伤害 | TR-ch2-003 |
| Detailed Rules §3.5 | 镇压战：流民逃离计数 + 豪强击杀计数 + 部分失败结算 | TR-ch2-004 |
| Detailed Rules §3.6 | Boss·陈朗三阶段 + 检查点 + 援军回合触发 | TR-ch2-005 |
| Detailed Rules §3.7 | 果子二选三结算界面 + 强制弹窗 + 中断重载 | TR-ch2-006 |

## Stories

| # | Story ID | 描述 | 类型 | Status | TR-ID |
|---|----------|------|------|--------|-------|
| 001 | CH2-c-001 | 章节路由与信念值分叉逻辑（Ch.2-1 结算后读取 belief_values，决定 act_b branch_variant） | Logic | Done | TR-ch2-001 |
| 002 | CH2-c-002 | NPC 王秀护送 AI（A* 寻路 + 畏缩 + 安全区到达判定 + 退场剧情） | Logic | Done | TR-ch2-002 |
| 003 | CH2-c-003 | 护卫姿态伤害分摊系统（触发条件、分摊公式、护卫单位受伤结算） | Logic | Done | TR-ch2-003 |
| 004 | CH2-c-004 | 镇压战特殊结算（逃离计数、部分失败判定、豪强击杀计数对比） | Logic | Done | TR-ch2-004 |
| 005 | CH2-c-005 | Boss·陈朗三阶段实装（阶段检查点、援军回合触发、阶段行为切换） | Logic | Done | TR-ch2-005 |
| 006 | CH2-c-006 | 果子二选三结算界面（强制弹窗、选择写入库存、中断重载保护） | Logic | Done | TR-ch2-006 |

## Definition of Done

本 epic 完成条件：
- 所有 stories 实现、审查完毕并通过 `/story-done`
- `design/gdd/chapter-02.md` 的全部 Acceptance Criteria 验证通过
- 信念值分叉路由：自动化测试覆盖 AC-CH2-001 全部三个场景
- 护卫姿态：单元测试覆盖 AC-CH2-003 伤害分摊公式
- Boss 检查点：集成测试覆盖 AC-CH2-006
- Ch.2 三战 JSON 通过现有菜单脚本解析（无 JSON.parse 错误）
- `chapter_02_complete` 正确写入存档，菜单脚本可读取

## Dependencies（待 Sprint-003 Epic 化的系统）

以下系统本 epic 依赖但尚未 epic 化，实装时需协调：

| 系统 | 当前状态 | 影响的 Story |
|------|---------|------------|
| boss-system GDD | 不存在（Sprint-003） | CH2-content-005 |
| bond-system GDD | 不存在（Sprint-003） | CH2-content-001（R3 羁绊特殊对话） |

## Next Step

GDD 进入 `/design-review design/gdd/chapter-02.md`，PASS 后开始排 `/story-readiness` 逐条验收。
