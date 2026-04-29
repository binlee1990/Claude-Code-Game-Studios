# Epic: Attack

> **Layer**: Feature
> **GDD**: design/gdd/attack.md
> **Architecture Module**: AttackResolver + AttackRangeResolver (Feature Layer)
> **Status**: Ready
> **Stories**: 3 stories created

## Stories
| # | Story | Type | Status | ADR |
|---|-------|------|--------|-----|
| 001 | 伤害公式 + AttackResult | Logic | Ready | ADR-0007 |
| 002 | 射程检查 + AttackRangeResolver | Logic | Ready | ADR-0007 |
| 003 | AttackResolver 执行 + 无反击 + 集成 | Integration | Ready | ADR-0007 |

## Overview

实现攻击系统：AttackResolver 为 RefCounted 纯函数执行确定性伤害公式 `damage = max(atk - def, 1)`。AttackRangeResolver 基于 Manhattan 距离过滤和排序有效目标。AttackResult 为不可变数据对象（attacker, target, damage, lethal）。MVP 无反击（信号槽位预留）。resolve_damage() 静态方法供 UI 伤害预览使用。本系统消费 Unit 属性（atk/def/rng/hp）、Map 占用查询，向 UI（攻击高亮+伤害预览）和 AI（目标选择）输出。

## Governing ADRs

| ADR | Decision Summary | Engine Risk |
|-----|-----------------|-------------|
| ADR-0007: Attack System | AttackResolver 和 AttackRangeResolver 为 RefCounted 纯函数；伤害公式 `max(atk-def,1)`；Manhattan 距离射程检查；AttackResult 不可变数据对象；无反击 MVP（信号槽位预留）；resolve_damage() 静态方法供预览 | LOW |

## GDD Requirements

| TR-ID | Requirement | ADR Coverage |
|-------|-------------|--------------|
| TR-atk-001 | 确定性伤害公式 `max(atk - def, 1)` | ADR-0007 ✅ |
| TR-atk-002 | Manhattan 距离射程检查（`\|r1-r2\| + \|c1-c2\| ≤ unit.rng`） | ADR-0007 ✅ |
| TR-atk-003 | AttackResolver 为 RefCounted 纯函数 | ADR-0007 ✅ |
| TR-atk-004 | AttackRangeResolver 目标过滤/排序（按距离、HP 升序） | ADR-0007 ✅ |
| TR-atk-005 | AttackResult 不可变数据对象 | ADR-0007 ✅ |
| TR-atk-006 | MVP 无反击（信号槽位 counter_attack 已预留） | ADR-0007 ✅ |
| TR-atk-007 | 伤害预览：resolve_damage(atk, def) 静态方法 | ADR-0007 ✅ |

## Definition of Done

本 Epic 完成条件：
- 所有 Story 已实现、审查并经由 `/story-done` 关闭
- `design/gdd/attack.md` 中所有验收标准已通过
- 全部 Logic Story 在 `tests/unit/attack/` 中有通过的测试文件

## Next Step

Run `/create-stories attack` 将本 Epic 拆解为可实施的 Story。
