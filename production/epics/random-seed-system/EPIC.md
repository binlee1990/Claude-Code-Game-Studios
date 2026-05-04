# Epic: 随机数与种子系统 (RNGManager)

> **Layer**: Foundation
> **GDD**: design/gdd/random-seed-system.md
> **Architecture Module**: RNGManager (Autoload, 全局单例)
> **Status**: Ready
> **Sprint Target**: Pre-Production Sprint 2（Foundation Services，与 TimeManager 并行）
> **Stories**: Created (10 stories)
> **PR-EPIC Verdict (2026-05-04)**: REALISTIC

## Overview

RNGManager 提供**确定性随机数服务**：单一 master_seed 通过 FNV-1a 推导多流（COMBAT / LOOT / EVENT / AFFIX / OFFLINE 等），每流独立 RNG 状态。支持 `rand_int / rand_float / rand_bool / weighted_pick / save_states / load_states` 全套快照接口。**离线模拟可重现的核心保证**——离线战斗与在线战斗使用相同 master_seed → 相同战斗结果（防作弊 + 调试可回放）。

## Governing ADRs

| ADR | Decision Summary | Engine Risk |
|-----|-----------------|-------------|
| ADR-0004: 确定性随机数架构 | 单 master_seed → FNV-1a 推导各流 seed；每流独立 `RandomNumberGenerator`；`save_states()` 序列化所有流当前 state；`load_states()` 完整恢复 | LOW |
| ADR-0008: Autoload 初始化顺序 | RNGManager 在 EventBus 之后、TimeManager 之前启动 | LOW |

## GDD Requirements

| TR-ID | Requirement | ADR Coverage |
|-------|-------------|--------------|
| TR-rng-001 | RNGManager provides deterministic master-seed and multi-stream random services for combat, loot, events, affixes, saves, and offline simulation. | ADR-0004 ✅ + ADR-0008 ✅ |

**Untraced requirements**: 0

## Engine Risk

**LOW** — `RandomNumberGenerator` 在 Godot 4.x 全版本稳定，无 4.5/4.6 破坏性变更。

## Cross-Epic Dependencies

- **Upstream blockers**: EventBus（必须在 Sprint 1 完成）— RNGManager 通过 EventBus 发布 `rng.streams_loaded / state_snapshot_taken`
- **Downstream consumers**: CombatCalculator（COMBAT 流）、LootSystem（LOOT 流）、奇遇 / 词条系统（EVENT / AFFIX 流）、OfflineCombatSimulation（OFFLINE 流，复制在线状态）、SaveManager（持久化 states）

## Definition of Done

### Standard DoD
- 所有 stories 实现完成、通过 `/code-review`、走完 `/story-done` 关闭
- `design/gdd/random-seed-system.md` 全部 acceptance criteria 验证通过
- Logic / Integration stories 在 `tests/unit/rng/` 与 `tests/integration/rng/` 有通过的测试文件

### PR-EPIC 追加要求（Producer 2026-05-04 sign-off 附加）

- **确定性回放测试**：`tests/integration/rng/deterministic_replay_test.gd` 必须验证：相同 master_seed 下，连续生成 10000 次 `rand_int()` 的序列与从 save → load → 继续生成的序列完全一致
- **多流独立性测试**：`tests/unit/rng/stream_independence_test.gd` 必须验证：消费 COMBAT 流不影响 LOOT 流的下一个值，反之亦然
- **离线 vs. 在线重现性测试**：`tests/integration/rng/offline_online_match_test.gd` 必须验证：在线场景跑 100 次战斗 + 记录 RNG state 序列；离线场景用相同初始 state 跑 100 次战斗 → 战斗结果（伤害 / 掉落 / 触发）完全一致。**这是 ADR-0004 的核心验证**

### 折叠自 gate-check watchlist 的项

| Watchlist 项 | DoD 要求 |
|---|---|
| ADR-0004 验证证据 | 确定性回放测试 + 多流独立性测试 + 离线/在线重现测试 |

## Stories

| # | Story | Type | Status | ADR |
|---|-------|------|--------|-----|
| 001 | [获得同一个全局单例实例](story-001-001-integration.md) | Integration | Ready | ADR-0008 |
| 002 | [LOOT 流的下一个 `rand_float` 结果与从未调用 COMBAT 流时完全一致](story-002-loot-rand-float-combat.md) | Logic | Ready | ADR-0004 |
| 003 | [返回 -1](story-003-1.md) | Logic | Ready | ADR-0004 |
| 004 | [GIVEN: `rand_bool(COMBAT, 0](story-004-given-rand-bool-combat-0.md) | Logic | Ready | ADR-0004 |
| 005 | [钳位到 0，返回 false](story-005-0-false.md) | Logic | Ready | ADR-0004 |
| 006 | [返回 7，不消耗随机数](story-006-7.md) | Logic | Ready | ADR-0004 |
| 007 | [所有流的种子和状态恢复到保存时的值，后续随机序列与保存时完全一致](story-007-007-integration.md) | Integration | Ready | ADR-0008 |
| 008 | [模拟期间在线 RNG 仍为 S1，不受模拟调用影响](story-008-rng-s1.md) | Integration | Ready | ADR-0008 |
| 009 | [返回 null，打印警告](story-009-null.md) | Integration | Ready | ADR-0008 |
| 010 | [总 RNG 调用耗时占帧预算 < 1%](story-010-rng-1.md) | Integration | Ready | ADR-0008 |

## Next Step

Run `/story-readiness production/epics/random-seed-system/story-001-*.md` before implementing the first story in this epic.
