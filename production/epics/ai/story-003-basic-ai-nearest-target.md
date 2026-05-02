# Story 003: BasicAI — 最近目标启发式计划生成器

> **Epic**: AI | **Status**: Done | **Layer**: Feature / Tier 2 | **Type**: Logic

## Context

**GDD**: `design/gdd/ai.md` | **Requirement**: `TR-ai-005`, `TR-ai-006`
**ADR**: ADR-0008: AI Controller | **Engine**: Godot 4.6.2 | **Risk**: MEDIUM

MVP 通过 `NullAI` 证明 AIController 的零行为端。Tier 2 的第一个验证点是 `BasicAI`：在不引用或修改 `TurnManager` 的前提下，生成非空 `ActionList`，证明接口可以容纳实际 AI 决策。

## Acceptance Criteria

- [x] `BasicAI` extends `AIController`
- [x] `take_turn(units, world_state) -> ActionList` 为每个可行动单位生成一个计划
- [x] 相邻敌人优先生成 `ATTACK_ONLY`
- [x] 可移动到攻击范围时生成 `MOVE_AND_ATTACK`
- [x] 无法本回合攻击时向最近敌方单位移动，生成 `MOVE_ONLY`
- [x] 无目标或缺失 WorldState/Map 时生成 `WAIT`
- [x] 不修改传入的 `WorldState`
- [x] 不导入、不引用 `TurnManager`

## Implementation Notes

- `src/ai/basic_ai.gd` is a pure planner. It does not move units, apply damage, emit signals, or mutate game state.
- It uses `MovementResolver.compute_reachable()` and `AttackRangeResolver.get_valid_targets()` as read-only dependencies.
- Action execution remains a separate future concern. This story verifies interface compatibility, not automatic ENEMY phase execution.

## Test Evidence

`tests/unit/ai/basic_ai_test.gd`

- Direct attack plan
- Move-and-attack plan
- Move-only toward nearest target
- Wait fallback
- Null WorldState/Map fallback
- No `TurnManager` import
- WorldState immutability

## Completion

Completed: 2026-05-02
Runner evidence: `Total Passed: 292`
