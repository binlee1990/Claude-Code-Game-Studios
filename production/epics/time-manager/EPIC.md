# Epic: 时间管理器 (TimeManager)

> **Layer**: Foundation
> **GDD**: design/gdd/time-manager.md
> **Architecture Module**: TimeManager (Autoload, 全局单例)
> **Status**: Ready
> **Sprint Target**: Pre-Production Sprint 2（Foundation Services，与 RNGManager 并行）
> **Stories**: Created (7 stories)
> **PR-EPIC Verdict (2026-05-04)**: REALISTIC

## Overview

TimeManager 拥有全局**双时间体系**：real_time（系统真实时间，用于离线 delta 计算）+ game_time（游戏内时间，受加速 / 暂停 / 冻结影响）。提供 `get_real_time / get_game_time / freeze / unfreeze / add_speed_source / get_offline_delta`。**所有离线收益结算的真理之源**——离线收益必须通过"退出时间戳 → 返回时间戳"差值计算（technical-preferences "离线收益必须使用时间戳差值，不能依赖 _process 实时循环"）。

## Governing ADRs

| ADR | Decision Summary | Engine Risk |
|-----|-----------------|-------------|
| ADR-0003: 时间源与双时间体系 | `Time.get_unix_time_from_system()` 作为 real_time 源；game_time 由 _process delta 累积 + speed_sources 调整；offline_delta 上限 28800s（8h）防止单次回流过大 | LOW |
| ADR-0008: Autoload 初始化顺序 | TimeManager 在 EventBus 与 RNGManager 之后启动（依赖 EventBus 发布时间事件） | LOW |

## GDD Requirements

| TR-ID | Requirement | ADR Coverage |
|-------|-------------|--------------|
| TR-time-manager-001 | TimeManager owns real/game time, speed sources, freeze/unfreeze, save timestamp snapshots, and capped offline delta calculation. | ADR-0003 ✅ + ADR-0008 ✅ |

**Untraced requirements**: 0

## Engine Risk

**LOW** — `Time.get_unix_time_from_system()` 在 Godot 4.x 全版本稳定；不涉及高风险域。

## Cross-Epic Dependencies

- **Upstream blockers**: EventBus（必须在 Sprint 1 完成）— TimeManager 通过 EventBus 发布 `time.tick / speed_changed / offline_delta_calculated`
- **Downstream consumers**: SaveManager（exit_timestamp）、AutoProductionSystem（tick delta）、OfflineSimulationCore（capped offline delta）、CultivationSystem、UI（HUD 时间显示）

## Definition of Done

### Standard DoD
- 所有 stories 实现完成、通过 `/code-review`、走完 `/story-done` 关闭
- `design/gdd/time-manager.md` 全部 acceptance criteria 验证通过
- Logic / Integration stories 在 `tests/unit/time_manager/` 与 `tests/integration/time_manager/` 有通过的测试文件

### PR-EPIC 追加要求（Producer 2026-05-04 sign-off 附加）

- **离线 delta 上限测试**：`tests/integration/time_manager/offline_delta_cap_test.gd` 必须验证：模拟玩家离开 24h 后回流时，`get_offline_delta()` 返回值上限 = 28800s（8h），不超出
- **Autoload 顺序合规**：本 epic 启动检查必须断言 EventBus 已就绪（通过 `is_instance_valid(EventBus)`），否则报错并终止初始化
- **Web 导出风险预警**：在 `time-manager.md` GDD acceptance criteria 中已声明"不依赖 _process 持续累积"，本 epic 实现端必须在 Story comments 中显式回应该约束（防止 Web 标签页不活跃时 game_time 漂移）

### 折叠自 gate-check watchlist 的项

| Watchlist 项 | DoD 要求 |
|---|---|
| ADR-0003 验证证据 | 双时间体系单元测试 + 离线 delta cap 测试 + Web 不活跃情境断言 |

## Stories

| # | Story | Type | Status | ADR |
|---|-------|------|--------|-----|
| 001 | [返回当前 Unix 时间戳（精度 ±1 秒）](story-001-unix-1.md) | Integration | Ready | ADR-0008 |
| 002 | [返回 3.0（乘法叠加）](story-002-3-0.md) | Logic | Ready | ADR-0003 |
| 003 | [`get_effective_speed()` 返回 100.0（截断）](story-003-get-effective-speed-100-0.md) | Integration | Ready | ADR-0008 |
| 004 | [返回 0.0](story-004-0-0.md) | Integration | Ready | ADR-0008 |
| 005 | [offline_delta 钳位到 28800 秒（MAX_OFFLINE_SECONDS），超过部分忽略](story-005-offline-delta-28800-max-offline-seconds.md) | Integration | Ready | ADR-0008 |
| 006 | [倍率立即更新，但 game_time 仍不推进，解冻后使用新倍率](story-006-game-time.md) | Integration | Ready | ADR-0008 |
| 007 | [静默忽略，无错误](story-007-007-logic.md) | Logic | Ready | ADR-0003 |

## Next Step

Run `/story-readiness production/epics/time-manager/story-001-*.md` before implementing the first story in this epic.
