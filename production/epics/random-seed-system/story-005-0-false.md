# Story 005: 钳位到 0，返回 false

> **Epic**: 随机数与种子系统
> **Status**: Done
> **Layer**: Foundation
> **Type**: Logic
> **Manifest Version**: 2026-05-04

## Context

**GDD**: `design/gdd/random-seed-system.md`
**Requirement**: `TR-rng-001` — RNGManager provides deterministic master-seed and multi-stream random services for combat, loot, events, affixes, saves, and offline simulation.

**ADR Governing Implementation**: ADR-0004: 确定性随机数架构
**ADR Decision Summary**: Implement `RNGManager` as an Autoload with a 64-bit master seed and independent `RandomNumberGenerator` instances for `COMBAT`, `LOOT`, `EVENT`, and `AFFIX`, plus optional named extension streams. Derive stream seeds from master seed using FNV-1a. Offline simulations operate on saved state copies and discard them after settlement.

**Engine**: Godot 4.6.2 | **Risk**: MEDIUM
**Engine Notes**: ADR-0004 status is Accepted; verify any Godot 4.6.2 behavior named by the ADR before closing the story.

**Control Manifest Rules (this layer)**:
- Required: **Use `BigNumber` for all game absolute quantities** — source: ADR-0001
- Required: **Keep BigNumber arithmetic immutable; every operation returns a new instance** — source: ADR-0001
- Required: **Serialize BigNumber as `{"m": mantissa, "e": exponent}`** — source: ADR-0001
- Required: **Route cross-system notifications through EventBus exact subscriptions in production** — source: ADR-0002
- Forbidden: **Never store resources, attributes, damage, experience, or rewards as raw `int` / `float` absolute values** — source: ADR-0001
- Forbidden: **Never introduce GDExtension BigNumber before the GDScript performance gate fails with measured evidence** — source: ADR-0001
- Forbidden: **Never use EventBus prefix subscriptions for production UI/gameplay behavior** — source: ADR-0002
- Guardrail: **BigNumber**: 1000 instances × 50 operations must fit within a 16.6 ms frame before GDExtension is deferred long term — source: ADR-0001
- Guardrail: **EventBus**: typical frame cost target is <= 0.5 ms/frame — source: ADR-0002
- Guardrail: **TimeManager**: 1000 `get_game_time()` calls target <= 0.1 ms — source: ADR-0003

---

## Acceptance Criteria

*From GDD `design/gdd/random-seed-system.md`, scoped to this story:*

- [x] GIVEN: `rand_bool` 的 probability 为 -0.5，**WHEN** 执行，**THEN** 钳位到 0，返回 false
- [x] GIVEN: `rand_bool` 的 probability 为 1.5，**WHEN** 执行，**THEN** 钳位到 1，返回 true
- [x] GIVEN: `rand_int(COMBAT, 10, 5)`（min > max），**WHEN** 执行，**THEN** 交换后返回 [5, 10] 范围内的随机整数，打印警告

---

## Implementation Notes

*Derived from ADR-0004 Implementation Guidelines:*

- Must route all gameplay randomness through `RNGManager`.
- Must not call global `randi()` or `randf()` from gameplay systems.
- Must keep COMBAT and LOOT streams independent.
- Must serialize master seed and per-stream seed/state.
- Must use copied RNG states for offline simulation.
- Must clamp invalid probabilities and weights rather than crashing.

---

## Out of Scope

- Story 001 covers the baseline contract for this epic; do not duplicate its setup work here.
- Story 006 covers the next acceptance group in this epic.

---

## QA Test Cases

*Written at story creation. The developer implements against these cases.*

- **AC**: GIVEN: `rand_bool` 的 probability 为 -0.5，**WHEN** 执行，**THEN** 钳位到 0，返回 false
  - Given: `rand_bool` 的 probability 为 -0.5
  - When: 执行
  - Then: 钳位到 0，返回 false
  - Edge cases: boundary, invalid, missing-data, and repeat-run variants from the GDD edge-case section

- **AC**: GIVEN: `rand_bool` 的 probability 为 1.5，**WHEN** 执行，**THEN** 钳位到 1，返回 true
  - Given: `rand_bool` 的 probability 为 1.5
  - When: 执行
  - Then: 钳位到 1，返回 true
  - Edge cases: boundary, invalid, missing-data, and repeat-run variants from the GDD edge-case section

- **AC**: GIVEN: `rand_int(COMBAT, 10, 5)`（min > max），**WHEN** 执行，**THEN** 交换后返回 [5, 10] 范围内的随机整数，打印警告
  - Given: `rand_int(COMBAT, 10, 5)`（min > max）
  - When: 执行
  - Then: 交换后返回 [5, 10] 范围内的随机整数，打印警告
  - Edge cases: boundary, invalid, missing-data, and repeat-run variants from the GDD edge-case section

---

## Test Evidence

**Story Type**: Logic
**Required evidence**:
- `tests/unit/random_seed/0-false_test.gd` — must exist and pass

**Status**: [x] Executed 2026-05-04

---

## Dependencies

- Depends on: Story 001 must be ready or done for shared test fixtures and baseline APIs
- Unlocks: Story 006

## 2026-05-04 Sprint Execution Evidence

- Sprint execution order: Sprint 1, story 19/20
- Sprint source: `production/sprints/sprint-1.md`
- QA plan: `production/qa/qa-plan-sprint-1-2026-05-04.md`
- Automated evidence: `reports/report_13/results.xml` (137 tests, 0 failures, 0 skipped, 0 flaky)
- QA gate evidence: `production/qa/evidence/sprint-1-qa-result-2026-05-04.md`
- Verdict: Done; acceptance criteria reviewed against implementation, runtime tests, and sprint QA plan evidence.
- QA-plan automated tests:
  - `tests/integration/big_number/api_contract_test.gd`
  - `tests/unit/big_number/big_number_arithmetic_test.gd`
  - `tests/performance/big_number_performance_test.gd`
  - `tests/integration/rng/deterministic_replay_test.gd`
  - `tests/unit/rng/stream_independence_test.gd`
