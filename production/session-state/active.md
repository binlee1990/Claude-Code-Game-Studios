# Active Session State

**Updated**: 2026-05-03

## Current Task

基于 `design/gdd/reviews` 的辩证性 GDD 修复 — **完成（文档一致性阻塞项已清理，玩法桥梁 GDD 仍待专门设计）**

## Status

本轮按 `$reframe-and-execute` 将 cross-review 的 FAIL 项拆成三类处理：

1. **已成立且可直接修复的契约冲突** — 已修。
2. **review 中已被后续会话修过但状态/措辞陈旧的条目** — 已刷新。
3. **需要新增系统 GDD 的玩法闭环缺口** — 保留为后续阻塞，不在修复 pass 中伪装完成。

## Fixes Applied This Session

| Area | 修复 | 状态 |
|------|------|------|
| OMS 亚单位产出 | `base_rate_per_second` 改为 float 速率；`get_production_rate()` 返回 float；`get_tick_amount()` 通过 `fractional_carry` 累积 `<1` 产出后再返回 BigNumber | ✅ |
| EventBus 可实现性 | 移除“捕获回调异常”的 GDScript 不可实现承诺；改为 `Callable.is_valid()` / Node 有效性隔离 | ✅ |
| EventBus 命名空间 | 补齐 `save.*`、`time.*`、`production_multiplier_changed`、`modifier_expired`、`loot.dropped` 等事件 | ✅ |
| EventBus 高频治理 | 新增 `emit_coalesced(event_name, payload, coalesce_key)`，仅用于最新状态型 UI/调试事件；事务事件仍同步投递 | ✅ |
| debug-console 陈旧缺口 | `需新增` 标记改为已追加状态；OMS API 签名同步为 float rate + BigNumber tick amount | ✅ |
| 上游 GDD 反向引用 | resource/time/attribute/modifier/save 的 Interactions 表补充调试控制台只读/调试消费关系 | ✅ |
| systems-index | 10 个旧 `Needs Revision` 状态刷新；调试控制台完整软依赖列表写入；进度指标同步 | ✅ |

## Files Modified This Session

| File | Purpose |
|------|---------|
| design/gdd/output-multiplier-system.md | 修复亚单位 base_rate 与 BigNumber 钳位冲突；新增 fractional carry 结算语义 |
| design/gdd/event-bus.md | 修复 GDScript 异常隔离不可实现问题；补命名空间与 coalesced 显示事件 |
| design/gdd/debug-console.md | 清理陈旧“需新增”标记；同步 OMS/EventBus/Save/Modifier/DataConfig 接口状态 |
| design/gdd/resource-system.md | 补调试控制台只读查询反向引用；刷新 EventBus namespace 状态 |
| design/gdd/time-manager.md | 补调试控制台查询/调试控制引用；刷新 time.* 一致性说明 |
| design/gdd/attribute-system.md | 补调试控制台只读属性查询引用；刷新 EventBus namespace 状态 |
| design/gdd/modifier-engine.md | 补调试控制台 `get_all_targets` / `get_breakdown` 引用 |
| design/gdd/save-system.md | 补调试控制台 `save now/dump` 引用；把 provider 错误语义改为显式返回值 |
| design/gdd/data-config-system.md | 把 query 过滤错误语义改为显式 callable/返回值校验 |
| design/gdd/item-material-system.md | 刷新 item_registry EventBus namespace 状态 |
| design/gdd/systems-index.md | 刷新状态、依赖与进度指标 |
| .tasks/completed/2026-05-03-dialectical-gdd-review-fixes.task.md | 本轮 reframe-and-execute 任务系统（已归档） |

## Critical Decisions Locked This Session

- **不修改 BigNumber 已批准边界**：BigNumber 继续只表示 `>= 1` 的绝对量；亚单位产出由 OMS float rate + fractional carry 处理。
- **`get_production_rate()` 语义调整**：返回每秒速率 float；需要写入 ResourceSystem 的数量必须走 `get_tick_amount()`，其返回 BigNumber。
- **EventBus 不做异常捕获承诺**：GDScript 无 `try/catch`；EventBus 只隔离无效 callable / 已释放 Node，订阅者逻辑错误由 Godot 日志暴露。
- **透明节流被拒绝**：普通 `emit()` 保持同步因果；`emit_coalesced()` 仅给最新状态型 UI/调试事件使用。
- **本轮不新增等级/自动产出/修炼 GDD**：这些属于新的系统设计任务，应单独走 `/design-system` 或同等设计流程。

## Remaining Blockers

| Blocker | Why Still Open | Recommended Next |
|---------|----------------|------------------|
| 等级系统 #15 未设计 | `exp → level → 属性成长` 链路仍缺，资源消费端不足 | 设计 `design/gdd/level-system.md` |
| 自动产出系统 #17 未设计 | `TimeManager/OMS → ResourceSystem.add()` 在线 tick 编排者仍缺 | 设计 `design/gdd/auto-production-system.md` |
| 修炼系统 #20 未设计 | `lingqi → xiuwei` 主动/自动转化消费仍缺 | 设计 `design/gdd/cultivation-system.md` |
| 离线结算链路仍未闭合 | 离线模拟内核/收益结算系统尚未设计 | 在 #17/#20 后设计离线模拟相关 GDD |

## Next Step Options

1. **设计等级系统 #15** — 优先补 `exp` 消费和玩家身份字段。
2. **设计自动产出系统 #17** — 锁定在线 tick 编排和 OMS fractional carry 调用方式。
3. **设计修炼系统 #20** — 锁定 `lingqi` 消费、`xiuwei` 增长、手动/自动修炼边界。
4. **重新运行 cross-GDD review** — 在上述桥梁系统至少 1-3 个完成后执行，避免重复报告已知玩法闭环缺口。

## Session Extract — /review-all-gdds 2026-05-03

- **Original Verdict**: FAIL
- **This Session Result**: Consistency blockers repaired; design-loop blockers remain.
- **Resolved consistency blockers**:
  1. OMS sub-unit production no longer collapses through BigNumber before accumulation.
  2. EventBus now has pattern subscription, missing namespaces, implementable error boundary, and high-frequency display coalescing.
  3. Debug-console upstream API gaps are marked resolved and reflected bidirectionally.
- **Still open design blockers**:
  1. MVP resources still need concrete consumption paths in level/cultivation systems.
  2. First playable loop still needs bridge-system GDDs.
  3. Offline settlement chain still needs orchestrator design.

<!-- STATUS -->
Epic: MVP Systems Design
Feature: Bridge System GDD — #15 Level System
Task: GDD COMPLETE 2026-05-04; CD-GDD-ALIGN REVISED; registry + systems-index 已同步；待 fresh session /design-review
<!-- /STATUS -->

## Active GDD: design/gdd/level-system.md (2026-05-04)

- Skeleton created with 8 required + 4 optional sections placeholder
- Pillars: 4.1 数字增长就是快乐 · 4.2 放置 = 低频高价值决策 · 4.5 多层重置（弱预留）
- Section progress:
  - [x] Overview (written 2026-05-04)
  - [x] Player Fantasy (written 2026-05-04, framing C 台阶)
  - [x] Detailed Design (Core Rules / States / Interactions, written 2026-05-04)
  - [x] Formulas (12 公式 written 2026-05-04)
  - [x] Edge Cases (28 条 written 2026-05-04)
  - [x] Dependencies (written 2026-05-04)
  - [x] Tuning Knobs (written 2026-05-04)
  - [x] Visual/Audio Requirements (无视觉需求声明 written 2026-05-04)
  - [x] UI Requirements (无 UI 需求声明 written 2026-05-04)
  - [x] Acceptance Criteria (33 条 written 2026-05-04)
  - [x] Open Questions (12 项 written 2026-05-04)
- **Phase 5 next**: CD-GDD-ALIGN gate (full mode) → Registry update → Systems-index update → /design-review in fresh session
- Locked upstream contracts: AttributeSystem.set_base, FormulaEngine `level_exp` + `atk_growth`, ResourceSystem.spend("exp"), `level.changed` event payload `{old_level, new_level}`, ModifierEngine `realm` 池
- Cross-review obligations: 必须实现 exp 消费路径 / 软上限 / realm modifier 重建 / 修仙身份字段
