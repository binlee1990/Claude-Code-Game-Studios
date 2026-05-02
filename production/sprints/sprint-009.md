# Sprint-009 — Vertical Slice 系统收尾

> **Status**: COMPLETE
> **Start**: 2026-05-13
> **End**: 2026-05-17
> **Goal**: 完成 Vertical Slice 层全部 4 个系统（fog-of-war / bond-combo / difficulty / boss），不含章节剧情内容
> **Capacity**: 5 天
> **Generated**: 2026-04-28

## Context

Sprint-008 完成 Ch.3 内容 + 装备养成收口。MVP 层 13 系统全部 Complete。
Vertical Slice 层 4 系统（fog / bond / difficulty / boss）均有 GDD，但无一完整实现。
Sprint-009 目标：将这 4 个系统推进到 Complete 或 MVP-ready。

**排除范围**: 章节剧情内容、Ch.4 规划、NG+ 难度倍率选择（依赖 NG+ 系统/Alpha 层）。

## Story Map

### Must Have (7 stories / ~3.75d)

| ID | Story | System | Type | Est. | Deps |
|----|-------|--------|------|------|------|
| FOG-001 | Visibility data model（三态 + 视野计算公式） | fog-of-war | Logic | 0.5d | tactical grid |
| FOG-002 | Fog rendering overlay MVP（三态颜色 overlay） | fog-of-war | UI/Visual | 0.5d | FOG-001, battle grid |
| FOG-003 | Unit visibility integration（隐藏敌人渲染 + 目标过滤） | fog-of-war | Integration | 0.5d | FOG-001, combat targeting |
| FOG-004 | Save/load fog state（battle_state explored_cells） | fog-of-war | Integration | 0.25d | FOG-001, SaveData |
| BOND-COMBO-001 | Combo skill data model + trigger（距离 ≤3 + AP 消耗 + 冷却 + 4 类型效果） | bond-system | Logic | 0.5d | BondRegistry, battle unit id |
| DIFF-001 | Difficulty data model + 一周目固定曲线（4 阶段倍率配置） | difficulty | Logic | 0.5d | — |
| BOSS-001 | Boss 系统 Epic 创建 + 数据模型（5 类型分类 + 检查点规范 + 失败恢复策略） | boss | Design/Logic | 0.5d | — |

### Should Have (3 stories / ~1.75d)

| ID | Story | System | Type | Est. | Deps |
|----|-------|--------|------|------|------|
| BOND-COMBO-002 | Combo skill battle UI + 4 类型效果集成（玩家主动触发入口） | bond-system | Integration/UI | 0.5d | BOND-COMBO-001 |
| DIFF-002 | Difficulty 集成（combat enemy stat ×倍率 + settlement exp/drop ×倍率 + AI 策略等级切换） | difficulty | Integration | 0.75d | DIFF-001, combat, settlement, AI |
| BOSS-002 | Boss action pattern 数据模型（telegraph 前兆 + range indicator + 冷却周期） | boss | Logic | 0.5d | BOSS-001 |

### Nice to Have (2 stories / ~0.5d)

| ID | Story | System | Type | Est. | Deps |
|----|-------|--------|------|------|------|
| EQUIP-014 | Equipment +11+ extreme-risk tuning（概率曲线 + 保护符号消耗） | equipment | Config | 0.25d | EQUIP-012 |
| ARCH-REVIEW | Post-Sprint-008 architecture review（增量审查 ADR-001~009 + fog/bond-combo/difficulty/boss 新 TR 同步） | governance | Review | 0.25d | — |

## TR Registry (待注册)

| TR-ID | System | Requirement |
|-------|--------|-------------|
| TR-fog-001 | fog-of-war | Visibility three-state model + vision range formula |
| TR-fog-002 | fog-of-war | Fog rendering overlay with map-opt-in toggle |
| TR-fog-003 | fog-of-war | Hidden enemy rendering + targeting filter |
| TR-fog-004 | fog-of-war | Fog state save/load in battle_state |
| TR-bond-005 | bond-system | Combo skill trigger: Manhattan ≤3, AP cost, cooldown, 4 bond-type effects |
| TR-bond-006 | bond-system | Combo skill battle UI + player-only trigger MVP |
| TR-diff-001 | difficulty | First-playthrough fixed curve (4 phases × enemy/exp/resource multipliers) |
| TR-diff-002 | difficulty | Difficulty integration with combat/settlement/AI |
| TR-boss-001 | boss | Boss type classification (5 types) + checkpoint spec |
| TR-boss-002 | boss | Boss action pattern: telegraph + range indicator + cooldown |

## Risk Assessment

| Risk | Severity | Mitigation |
|------|----------|------------|
| Fog rendering overlay 性能（15×15~25×25 grid × tile overlays） | MEDIUM | MVP 不做 LOS 裁剪；关闭 fog 的关卡零开销 |
| Boss action pattern telegraph 视觉效果依赖美术资产 | LOW | MVP 用纯色矩形/闪烁即可，不依赖正式资产 |
| Difficulty 集成触及 combat/settlement/AI 三系统 | MEDIUM | DIFF-001 先落地数据模型；DIFF-002 按 combat→settlement→AI 顺序集成 |
| Bond combo 4 类型效果差异化范围可能膨胀 | LOW | Sprint-008 GDD 已明确 4 类型效果规格，严格按 spec 实现 |

## Verification Gates

| Gate | Threshold |
|------|-----------|
| godot --check-only | 退出码 0 |
| GUT runner | 全部 PASS（基线 879 + 增量） |
| Windows export | 退出码 0 |
| Packaged smoke | PASS，fog-opt-in 关卡 + combo 触发 + difficulty 倍率应用 |

## Out of Scope

- Ch.4 规划及任何章节剧情内容
- NG+ 难度倍率选择（依赖 NG+ 系统 / Alpha 层）
- Boss telegraph 正式视觉资产（MVP 用几何占位）
- Fog minimap / 高级光源 / LOS 裁剪 / AI 视野公平化
- Enemy AI combo skill 触发
- S-rank bond 内容
- 多周目成就点数系统
