# ADR-0017: OMS 试算查询 API — `simulate_tick_for`

## Status

Proposed

## Date

2026-05-05

## Last Verified

2026-05-05

## Decision Makers

technical-director + game-designer

## Summary

修炼屏（cultivation-screen）的试算面板需要"切换姿态后 N 秒能得到多少资源"的只读查询。OMS GDD 已有 `get_breakdown()` 和 `get_tick_amount()`，缺少带 stance 覆写的试算 API。本 ADR 决定在 OMS 新增 `simulate_tick_for(resource_id, delta_seconds, stance)` 只读 query，不修改任何持久状态、不注册 modifier、不走 EventBus。

## Engine Compatibility

| Field | Value |
|-------|-------|
| **Engine** | Godot 4.6.2 |
| **Domain** | Core / Gameplay |
| **Knowledge Risk** | LOW — pure computation on existing data structures |
| **References Consulted** | `design/gdd/output-multiplier-system.md`, `design/gdd/cultivation-system.md`, `design/ux/cultivation-screen.md` |
| **Post-Cutoff APIs Used** | None |
| **Verification Required** | `simulate_tick_for` 结果与手动切换 stance 后 `get_tick_amount` 一致（同 stance、同 delta、同 carry 起点的前提下）|

## ADR Dependencies

| Field | Value |
|-------|-------|
| **Depends On** | ADR-0010 (ResourceSystem 不可变 BigNumber), ADR-0013 (FormulaEngine DSL) |
| **Enables** | Sprint 11 S11-009 cultivation-screen 试算面板完整实现 |
| **Blocks** | cultivation-screen INSPECTION ZONE 试算功能 — 无此 API 则试算降级为静态示例 |
| **Ordering Note** | 在 S11-009 dev 前必须 Accepted；否则 spec 降级到 §States.OMS Breakdown API Missing |

## Context

### Problem Statement

修炼屏 §Data Requirements 提出试算面板需要两个 OMS API：
1. `get_breakdown(resource_id)` — **已存在于 OMS GDD** (§Detailed Design #8, 返回 `Dictionary` 含 pools/base_rate/final_multiplier 等)
2. `simulate_tick_for(stance, seconds)` — **不存在**。当前 OMS 只能查询"当前 stance 下的产出"，无法回答"如果我切到 condense 30 秒会得到多少修为？"

无此 API 的代价：试算面板 60% 功能降级为静态示例，玩家无法做"姿态切换前试算"决策——直接削弱 pillar 4.2"放置 = 低频高价值决策"。

### Current State

- OMS 通过 `activate_source(source_def)` 注册 stance 倍率为 `source_type: "stance"`（或归属到现有 4 池之一）。姿态切换时 CultivationSystem 调用 `deactivate_source(old)` + `activate_source(new)` 更新 modifier。
- `get_tick_amount(resource_id, delta)` 基于当前已注册 modifier 计算产出。
- CultivationSystem 持有当前 stance，但不暴露 stance→倍率映射给外部查询。

### Constraints

- 试算是纯 UI 查询，**不得**修改任何 game state、不注册 modifier、不发 EventBus 事件。
- API 签名必须兼容 OMS 现有的 float-rate + BigNumber-amount 双轨制（速率用 float 防亚单位钳位，产出量用 BigNumber）。
- 试算结果与"实际切换 stance 后等 N 秒"的结果必须在浮点容差内一致。

### Requirements

- 调用方传入 target stance + duration，OMS 返回假设该 stance 下 duration 内的产出量。
- 只读 — 不影响 `active_sources`、不触发 `production_multiplier_changed`、不进 EventBus。
- OMS 已持有 base_rate 和 pool 定义，试算只需要 stance→pool_multiplier 映射即可完成计算。

## Decision

在 `OutputMultiplierSystem` 新增一个只读 query API：

```
simulate_tick_for(resource_id: String, delta_seconds: float, stance: String) -> Dictionary
```

返回 `{ "amount": BigNumber, "rate_per_second": float, "carry_used": float }`。

### Architecture

```text
CultivationScreen (UI)
  |
  | simulate_tick_for("xiuwei", 30.0, "condense")
  v
OutputMultiplierSystem
  |
  | 1. 查询当前 multiplier breakdown（已有 get_breakdown）
  | 2. 用 stance→pool_multiplier 映射覆写 stance 相关池的倍率
  | 3. 计算 hypothetical_rate = base_rate × overridden_multiplier
  | 4. 计算 accumulated = hypothetical_rate × delta_seconds
  | 5. 返回 {amount: BigNumber.from_float(accumulated), rate_per_second: hypothetical_rate}
  |
  +--> 不修改 active_sources
  +--> 不调用 ModifierEngine.register/unregister
  +--> 不发布任何 EventBus 事件
```

### Key Interfaces

```
## OMS 新增 public method

func simulate_tick_for(resource_id: String, delta_seconds: float, stance: String) -> Dictionary:
    # Returns: {
    #   "amount": BigNumber,           # 假设产出量
    #   "rate_per_second": float,      # 假设每秒速率
    #   "error": String                # 空字符串 = 成功；非空 = 错误描述
    # }
    #
    # Stance → pool_multiplier 映射：
    #   - "meditate": 使用当前 multiplier（stance 本身是 modifier 来源之一），
    #                 但冥想通常不额外覆写特定池
    #   - "condense": lingqi 速率不变或略降，xiuwei 速率大幅提升
    #   - "closed_door": 未来扩展，当前返回 error="stance not implemented"
    #   - "idle": 所有产出倍率 = 1.0（无 stance 加成）
    #
    # delta_seconds ≤ 0 → 返回 error
    # resource_id 不存在或 allows_passive=false → 返回 ZERO
```

### Implementation Guidelines

1. stance→pool_multiplier 映射从 `production_config.json` 扩展字段读取（如 `stance_overrides.condense.xiuwei_rate: 5.0`），不硬编码。
2. 试算使用当前 `base_rate` 和当前所有 modifier（除 stance 相关池被覆写外）。
3. 试算**不**累积 `fractional_carry` — 每次调用独立计算，不记忆上次余数。
4. 若 stance 参数与当前 stance 相同，直接委托给 `get_tick_amount()` 复用现有路径。
5. 性能：单次调用 < 0.02 ms（与 `get_tick_amount` 同级）。

## Alternatives Considered

### Alternative 1: UI 层自行计算

- **Description**: CultivationScreen 调用 `get_breakdown()` 获取当前 multiplier，自己维护 stance→倍率映射表，手动计算试算结果。
- **Pros**: 不改 OMS，零后端改动。
- **Cons**: stance→倍率映射泄露到 UI 层，违反"UI 不持有 game state"原则；映射表需与 CultivationSystem 同步维护，易漂移；其他屏如需试算需重复实现。
- **Estimated Effort**: 低（UI 侧 ~30 行）
- **Rejection Reason**: 违反架构约束（UI 不应持有 game state 的副本），且映射漂移风险不可接受。

### Alternative 2: 试算走临时 modifier 注册/注销

- **Description**: 试算时注册临时 stance modifier → 调 `get_tick_amount` → 立即注销。
- **Pros**: 复用现有管线，无新 API。
- **Cons**: 触发 EventBus 事件（`production_multiplier_changed` 在注册/注销时各发一次），HUD 可能短暂闪烁；注册/注销有副作用（dirty-flag 重算）；并发试算（多个 duration 档位同时预览）会互相干扰。
- **Estimated Effort**: 低
- **Rejection Reason**: 副作用不可接受 — 试算是纯查询，不应触发事件或修改状态。

### Alternative 3: 降级为静态示例

- **Description**: 不实现试算，INSPECTION ZONE 显示硬编码的示例数字（"切换到凝练大约可获得 3× 修为"）。
- **Pros**: 零工程投入。
- **Cons**: 阉割修炼屏 60% 价值；违反 pillar 4.2"低频高价值决策"原则（玩家无法做 informed decision）；UX review 标记为 BLOCKING。
- **Estimated Effort**: 零
- **Rejection Reason**: UX spec 明确将此列为 BLOCKING 级需求。

## Consequences

### Positive

- 修炼屏试算面板完整可用，玩家可做"切姿态前试算"决策
- API 是只读 query，无副作用，可高频调用（UI 实时滑块拖拽）
- stance→倍率映射保留在 OMS（配置驱动），UI 不持有 game state
- 未来其他屏（如离线结算预览）可复用同一 API

### Negative

- OMS 新增一个 public method 和 stance→倍率配置段
- `production_config.json` 需新增 `stance_overrides` 字段

### Neutral

- `get_breakdown()` 已存在于 OMS GDD（返回 `Dictionary`），修炼屏的"拆解"需求直接用现有 API 即可，无需新 ADR

## Risks

| Risk | Probability | Impact | Mitigation |
|------|------------|--------|-----------|
| stance_overrides 配置与 CultivationSystem 实际 stance 效果不一致 | Medium | High — 试算结果与实际不符，玩家信任崩塌 | 在 `simulate_tick_for` 的测试中对比 simulate vs 实际切换 stance 后 get_tick_amount |
| MVP 的 stance 倍率硬编码在配置中，后续 CultivationSystem 改动 stance 逻辑时忘记同步配置 | Medium | Medium | CultivationSystem 应作为 stance_overrides 的 single source of truth；OMS 配置由 CultivationSystem 初始化时写入 |

## Performance Implications

| Metric | Before | Expected After | Budget |
|--------|--------|---------------|--------|
| simulate_tick_for 单次调用 | N/A | < 0.02 ms | 0.05 ms |
| 试算面板 5 档 × 2 stance = 10 次调用 | N/A | < 0.2 ms | 1 ms（UI 帧预算内） |

## Migration Plan

1. OMS 实现 `simulate_tick_for(resource_id, delta_seconds, stance)` method
2. `production_config.json` 新增 `stance_overrides` 段（初始仅 meditate/condense）
3. CultivationSystem 在初始化时将当前 stance 倍率写入 OMS 配置（作为 single source of truth）
4. CultivationScreen 的 INSPECTION ZONE 调用此 API 替换静态示例
5. 若 ADR 被否决：CultivationScreen 降级到 §States.OMS Breakdown API Missing 降级态

**Rollback plan**: 删除 method，INSPECTION ZONE 切回静态示例（降级态已设计好）。

## Validation Criteria

- [ ] `simulate_tick_for("lingqi", 60.0, "meditate")` 返回值与当前 meditate 姿态下 `get_tick_amount("lingqi", 60.0)` 一致（容差 ≤ 0.01）
- [ ] `simulate_tick_for("xiuwei", 30.0, "condense")` 对 condense 姿态返回非零修为量
- [ ] `simulate_tick_for("lingqi", 0, "meditate")` 返回 error（delta ≤ 0）
- [ ] `simulate_tick_for("lingqi", 10.0, "closed_door")` 返回 error（stance not implemented in MVP）
- [ ] 调用 `simulate_tick_for` 后 `active_sources` 不变、无 EventBus 事件发射
- [ ] 试算 panel 5 档 duration 全部 ≤ 1ms 计算

## GDD Requirements Addressed

| GDD Document | System | Requirement | How This ADR Satisfies It |
|-------------|--------|-------------|--------------------------|
| `design/ux/cultivation-screen.md` | CultivationScreen UI | INSPECTION ZONE 试算面板：duration slider + stance dropdown + 结果展示 | 提供 `simulate_tick_for` API 作为试算数据源 |
| `design/ux/cultivation-screen.md` | CultivationScreen UI | AC-7: 试算 duration=60s + condense 结果与 simulate_tick_for("condense", 60) 一致 | 直接调用本 API 验证 |
| `design/gdd/output-multiplier-system.md` | OMS | 消费者查询 API 扩展 | 新增只读 query，不改变现有管线 |
| `design/gdd/cultivation-system.md` | CultivationSystem | stance 切换影响产出 | 试算 API 使用 stance 倍率映射模拟切换效果 |

## Related

- ADR-0010: ResourceSystem 不可变 BigNumber 策略（试算不写 ResourceSystem，只返回 BigNumber 给 UI 展示）
- ADR-0011: UI 屏幕管理架构（试算结果仅展示，不通过 UIManager 传递）
- `design/ux/cultivation-screen.md` §Data Requirements — 架构 gap 标注
- `design/ux/cultivation-screen.md` §States — OMS Breakdown API Missing 降级态
