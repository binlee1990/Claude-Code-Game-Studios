# Playtest Report — Session 1

## Session Info
- **Date**: 2026-04-23
- **Build**: Vertical Slice (prototypes/vertical-slice/)
- **Duration**: ~10-15 分钟
- **Tester**: 开发者自测
- **Platform**: PC
- **Input Method**: KB+M
- **Session Type**: Targeted test (核心循环验证)

## Test Focus
验证 Vertical Slice 核心战斗循环：
- 选择单位 → 移动 → 攻击 → 结束回合
- 回合顺序显示
- 伤害计算
- 胜负判定

## First Impressions (First 5 minutes)
- **理解目标？** Yes — 点击蓝色单位开始，回合顺序清晰
- **理解操作？** Yes — 快捷键 1/2/3/4 工作正常
- **情绪反馈**: 满意
- **Notes**: 格子高亮正确（蓝色=移动，红色=攻击），UI 信息清晰

## Gameplay Flow
### What worked well
- 单位选择正常，选中高亮（金色）正确显示
- 移动范围计算正确（曼哈顿距离 3 格内）
- 攻击范围计算正确（曼哈顿距离 2 格内，Chebyshev 限制）
- 快捷键操作响应正常
- 敌方 AI 自动执行（移动+攻击）
- 回合顺序面板实时更新
- HP 条跟随单位位置变化
- 胜负判定正确触发（VICTORY/DEFEAT）

### Pain points
- 无明显问题

### Confusion points
- 无

### Moments of delight
- 敌方 AI 自动追击并攻击，有策略感

## Bugs Encountered
| # | Description | Severity | Reproducible |
|---|-------------|----------|-------------|
| 1 | 初始 `_process_next_turn()` 在 `_init_battle()` 中调用时 turn_order 为空 | Low | N/A (代码审查发现) |

## Feature-Specific Feedback
### 回合制战斗流程
- **Purpose understood?** Yes
- **Found engaging?** Yes
- **Suggestions**: 正常

### 伤害计算
- **Purpose understood?** Yes
- **Found engaging?** Yes
- **Suggestions**: 数值来源需数据驱动（后续 Sprint）

## Quantitative Data
- **Deaths**: 0
- **Time per area**: N/A (单场景演示)
- **Items used**: N/A
- **Features discovered vs missed**: 全部功能已测试

## Overall Assessment
- **会再玩吗？** Yes
- **Difficulty**: Just Right
- **Pacing**: Good
- **Session length preference**: Good

## Top 3 Priorities from this session
1. 无阻塞性问题 — 核心循环工作正常
2. 伤害数值硬编码（应数据驱动）
3. 加速/自动战斗未在本次验证（ Sprint-001 待办）
