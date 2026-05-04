# Epic: 大数值系统 (BigNumber)

> **Layer**: Foundation
> **GDD**: design/gdd/big-number-system.md
> **Architecture Module**: BigNumber (RefCounted, value type)
> **Status**: Done
> **Sprint Target**: Pre-Production Sprint 1（Foundation Core）
> **Stories**: Created (14 stories)
> **PR-EPIC Verdict (2026-05-04)**: REALISTIC

## Overview

BigNumber 提供整个游戏所有大数值（修为、灵气、战力、掉落倍率等）的统一数值抽象。值类型（不进 Autoload），通过 mantissa + exponent 表达 1e30+ 量级，支持加减乘除幂、对数比较、序列化。**12+ 下游系统的强依赖基底**：systems-index High-Risk Systems 显式标注"wrong choice cascades everywhere"。本 epic 的 public API 一旦冻结将影响所有 Core / Feature 层系统。

## Governing ADRs

| ADR | Decision Summary | Engine Risk |
|-----|-----------------|-------------|
| ADR-0001: BigNumber 实现策略 | 纯 GDScript 值类型；mantissa(float) + exponent(int)；不归一化时延迟规范化；序列化为 `{m, e}` dict | LOW |

## GDD Requirements

| TR-ID | Requirement | ADR Coverage |
|-------|-------------|--------------|
| TR-big-number-001 | BigNumber provides the shared non-negative mantissa/exponent numeric abstraction for all large game quantities. | ADR-0001 ✅ |

**Untraced requirements**: 0

## Engine Risk

**LOW** — 纯数学，无 Engine API 依赖。Godot 4.6 兼容。

## Cross-Epic Dependencies

- **Downstream consumers**: ResourceSystem, AttributeSystem, FormulaEngine, ModifierEngine, NumberFormatter, OutputMultiplierSystem, LevelSystem, CombatCalculator, LootSystem, OfflineSimulationCore（共 12+ 系统）— 全部依赖 BigNumber API 稳定
- **Upstream blockers**: 无

## Definition of Done

This epic is complete when：

### Standard DoD
- 所有 stories 实现完成、通过 `/code-review`、走完 `/story-done` 关闭
- `design/gdd/big-number-system.md` 全部 acceptance criteria 验证通过
- 所有 Logic 与 Integration stories 在 `tests/unit/big_number/` 与 `tests/integration/big_number/` 有通过的测试文件
- 所有 Visual / UI stories 有 `production/qa/evidence/` 签字证据（本 epic 预计无 Visual / UI story）

### PR-EPIC 追加要求（Producer 2026-05-04 sign-off 附加）

- **本 epic Story #1 必须包含 GdUnit4 plugin 安装 + CI workflow 首次绿灯**。这是所有后续 epic 测试可执行性的前置。Story #1 未通过 → 所有 Foundation 层后续 stories 自动阻塞
- **BigNumber public API 在 Sprint 1 第 3 天前冻结**（即使内部实现未完成）。冻结方式：用接口契约测试（`tests/integration/big_number/api_contract_test.gd`）锁定全部 public 方法签名。冻结后任何 API 变更需 producer 复审
- **性能 benchmark 证据**：systems-index High-Risk 要求"prototype early with performance benchmarks"。本 epic 必须产出 BigNumber × 100,000 次运算（add / multiply / compare / serialize）的 benchmark 报告，落地 `tests/performance/big_number_bench.md`，验证不超过 1ms 单次平均

### 折叠自 gate-check watchlist 的项

| Watchlist 项 | DoD 要求 |
|---|---|
| GdUnit4 plugin install | Story #1 内完成 |
| CI workflow first push 绿灯 | Story #1 内完成 |
| ADR-0001 验证证据 | benchmark 报告 + 接口契约测试 |

## Stories

| # | Story | Type | Status | ADR |
|---|-------|------|--------|-----|
| 001 | [Testing harness and BigNumber API contract](story-001-testing-harness-and-bignumber-api-contract.md) | Integration | Done | ADR-0001 |
| 002 | [`mantissa ∈ \[1.0, 10.0)` 且 `exponent` 使得 `mantissa × 10^exponent` 等于原始](story-002-mantissa-1-0-10-0-exponent-mantissa-10-exponent.md) | Logic | Done | ADR-0001 |
| 003 | [结果为 `{6.0, 8}`](story-003-6-0-8.md) | Logic | Done | ADR-0001 |
| 004 | [结果约为 5.5（float，误差 < 0.01）](story-004-5-5-float-0-01.md) | Logic | Done | ADR-0001 |
| 005 | [结果为 `BigNumber.ZERO`](story-005-bignumber-zero.md) | Logic | Done | ADR-0001 |
| 006 | [结果为 `BigNumber.ZERO`](story-006-bignumber-zero.md) | Logic | Done | ADR-0001 |
| 007 | [结果为 `BigNumber.MAX`（饱和）](story-007-bignumber-max.md) | Logic | Done | ADR-0001 |
| 008 | [总耗时 < 16.6ms（60fps 帧预算内，纯 GDScript MVP 目标；若不达标，升级至 GDExtension C++）](story-008-16-6ms-60fps-gdscript-mvp-gdextension-c.md) | Logic | Done | ADR-0001 |
| 009 | [`mantissa == 4.2`，`exponent == 1`](story-009-mantissa-4-2-exponent-1.md) | Logic | Done | ADR-0001 |
| 010 | [返回 `100`](story-010-100.md) | Logic | Done | ADR-0001 |
| 011 | [返回格式为 `"1.23e150"` 的字符串](story-011-1-23e150.md) | Logic | Done | ADR-0001 |
| 012 | [均返回 `true`](story-012-true.md) | Logic | Done | ADR-0001 |
| 013 | [结果为 `BigNumber.MAX`](story-013-bignumber-max.md) | Logic | Done | ADR-0001 |
| 014 | [结果为 `BigNumber.MAX`（饱和）](story-014-bignumber-max.md) | Logic | Done | ADR-0001 |

## Next Step

Run `/story-readiness production/epics/big-number-system/story-001-*.md` before implementing the first story in this epic.
