# 战斗计算器 (Combat Calculator)

> **Status**: Approved
> **Author**: binlee1990 + agents
> **Last Updated**: 2026-05-04
> **Implements Pillar**: 4.2 放置不是无操作 · 4.7 子玩法服务主循环
> **Design Review (lean)**: APPROVED 2026-05-04 — required sections, dependency references, acceptance criteria, and cross-GDD contracts checked in this cleanup pass.

## Summary

战斗计算器是在线/离线共用的确定性战斗数学层。它接收双方属性快照和 RNG 种子，输出战斗结果、耗时、胜负、伤害摘要和奖励结算所需上下文。

> **Quick reference** — Layer: `Feature Integration` · Priority: `MVP` · Key deps: `属性系统, 公式引擎, 随机数与种子系统, 修正器/倍率引擎`

## Overview

战斗计算器不控制战斗循环，也不显示战斗过程。它是一个纯函数式服务：给定玩家/敌人属性快照、战斗配置和种子，返回同样的结果。半自动战斗系统用它处理在线战斗，离线战斗模拟系统用它批量估算或复放战斗。这个共享点是高风险系统的核心缓解：在线与离线不能各写一套伤害公式。

## Player Fantasy

玩家感受到的是 Build 决策真实有效：攻击更高会更快清怪，防御更高会少失败，暴击率确实会改变战斗日志。计算器本身不可见，但它保证"我换装后战斗表现变化"不是错觉。

## Detailed Design

### Core Rules

1. `CombatCalculator` 是无状态服务，公开 `simulate_encounter(attacker, defender, seed, options) -> CombatResult`。
2. 输入快照必须包含 MVP 6 属性：`hp_max/atk/def/spd/crit_rate/crit_dmg`。
3. 当前 HP 是战斗局部变量，不写入 AttributeSystem。
4. 行动顺序由 `spd` 决定；MVP 使用时间轴累积模型，速度越高行动越频繁。
5. 每次攻击依次执行：基础伤害 → 防御减免 → 暴击判定 → 最小伤害钳位。
6. 战斗有最大回合/最大秒数保护；超时按失败或平局策略返回。
7. 所有随机都从 Random Seed System 派生；同输入同种子必须结果相同。
8. 结果只包含计算摘要，不直接触发掉落、不写资源。

### States and Transitions

CombatCalculator 本身无持久状态。单场模拟内部有以下瞬时状态：

| State | Entry Condition | Exit Condition | Behavior |
|-------|----------------|----------------|----------|
| Initializing | 输入快照进入 | 校验通过 | 构建局部 HP/time accumulators |
| Resolving | 双方仍存活且未超时 | 一方死亡或超时 | 按行动时间轴推进 |
| Finished | 胜负已定 | 返回结果 | 输出 CombatResult |
| Invalid | 输入缺字段或非法 | 返回失败结果 | 不抛异常，附错误码 |

### Interactions with Other Systems

| System | Interface | Contract |
|--------|-----------|----------|
| 属性系统 | `get_final` or snapshots | 上游调用方准备属性快照 |
| 公式引擎 | formula ids | 伤害/减免公式可配置 |
| 随机数与种子系统 | deterministic rolls | 暴击和未来闪避等随机 |
| 修正器/倍率引擎 | indirect through AttributeSystem | 计算器不直接读取 modifier |
| 半自动战斗系统 | `simulate_encounter` | 在线战斗消费者 |
| 离线战斗模拟系统 | same API | 离线批量消费者 |

## Formulas

The `damage_per_hit` formula is defined as:

`damage_per_hit = max(MIN_DAMAGE, (atk * skill_multiplier - def * defense_weight) * crit_multiplier)`

**Variables:**
| Variable | Symbol | Type | Range | Description |
|----------|--------|------|-------|-------------|
| atk | A | BigNumber | 1-1e30 | 攻击方最终攻击 |
| skill_multiplier | S | float | 0.1-100 | 技能倍率，MVP 普攻为 1 |
| def | D | BigNumber | 0-1e30 | 防守方最终防御 |
| defense_weight | W | float | 0-2 | 防御权重 |
| crit_multiplier | C | float | 1-100 | 未暴击为 1，暴击为 crit_dmg |
| MIN_DAMAGE | m | BigNumber | 1-1e6 | 最小伤害 |

**Output Range:** MIN_DAMAGE to very large BigNumber.
**Example:** atk 100, def 20, W 0.5, crit 1.5 → (100 - 10) * 1.5 = 135。

The `action_interval` formula is defined as:

`action_interval = BASE_ACTION_SECONDS / sqrt(max(spd, 1) / 10)`

**Variables:**
| Variable | Symbol | Type | Range | Description |
|----------|--------|------|-------|-------------|
| BASE_ACTION_SECONDS | B | float | 0.5-5.0 | 基础行动间隔 |
| spd | V | BigNumber | 1-1000 | 速度属性 |

**Output Range:** 0.1s to 10s after clamp.
**Example:** base 2s, spd 40 → 1s。

## Edge Cases

- **If an input snapshot misses a required attribute**: return Invalid with missing field list.
- **If both sides die on the same timestamp**: player victory if enemy HP <= 0 and player HP > 0; true simultaneous death resolves as failure for farming stability.
- **If defense exceeds attack**: minimum damage still applies.
- **If crit_rate is above 1 or below 0**: clamp to [0,1] before rolling.
- **If max duration is reached**: return timeout failure and no loot context.

## Dependencies

| System | Direction | Nature |
|--------|-----------|--------|
| 属性系统 | Upstream | Provides final attributes |
| 公式引擎 | Upstream | Owns configurable combat formulas |
| 随机数与种子系统 | Upstream | Owns deterministic combat random |
| 半自动战斗系统 | Downstream | Online orchestrator |
| 离线战斗模拟系统 | Downstream | Batch orchestrator |

## Tuning Knobs

| Parameter | Current Value | Safe Range | Effect of Increase | Effect of Decrease |
|-----------|--------------|------------|-------------------|-------------------|
| `BASE_ACTION_SECONDS` | 2.0 | 0.5-5.0 | Slower combat | Faster combat |
| `defense_weight` | 0.5 | 0-2 | Defense matters more | Damage scales harder |
| `MIN_DAMAGE` | 1 | 1-1e6 | Prevents stalls harder | Allows tank walls |
| `MAX_COMBAT_SECONDS` | 120 | 10-600 | More long fights resolve | Faster timeout |

## Visual/Audio Requirements

No direct visual/audio. It must return enough combat events for battle log and HUD to show hits, crits, victory, failure, and timeout.

## UI Requirements

No direct UI. Debug view should expose input snapshots, formula version, seed, and CombatResult summary.

## Cross-References

| This Document References | Target GDD | Specific Element Referenced | Nature |
|--------------------------|-----------|-----------------------------|--------|
| Final attributes | `design/gdd/attribute-system.md` | `get_final` target semantics | Data dependency |
| Combat seed | `design/gdd/random-seed-system.md` | reproducible RNG | Rule dependency |
| Online consumer | `design/gdd/semi-auto-combat-system.md` | encounter result contract | Data dependency |

## Acceptance Criteria

- **GIVEN** identical snapshots and seed, **WHEN** simulate runs twice, **THEN** CombatResult is identical.
- **GIVEN** player atk increases while enemy unchanged, **WHEN** simulate runs, **THEN** average time-to-kill does not increase over enough seeded samples.
- **GIVEN** defender def exceeds attacker atk, **WHEN** attack resolves, **THEN** damage is at least MIN_DAMAGE.
- **GIVEN** crit_rate 1.0, **WHEN** attack resolves, **THEN** all attacks use crit_dmg multiplier.
- **GIVEN** max duration exceeded, **WHEN** simulate returns, **THEN** result status is timeout failure.
