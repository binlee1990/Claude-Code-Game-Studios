# Story 002: WorldState + ActionPlan/ActionList 数据结构

> **Epic**: AI | **Status**: Ready | **Layer**: Feature | **Type**: Logic

## Context
**GDD**: `design/gdd/ai.md` | **Requirement**: `TR-ai-002`, `TR-ai-003`, `TR-ai-007`
**ADR**: ADR-0008: AI Controller | **Engine**: Godot 4.6.2 | **Risk**: LOW

## Acceptance Criteria
- [ ] WorldState 封装 Map 拓扑快照 + 单位状态
- [ ] WorldState.clone() 深拷贝（供 AI 模拟分支）
- [ ] ActionPlan 含动作序列（移动→攻击），ActionList 含多个 ActionPlan
- [ ] ActionList 为空时 Turn System 正常处理（ENEMY 阶段自动推进）
- [ ] 数据结构与 Turn System 的 take_turn() 返回值契约一致

## Implementation Notes
```gdscript
class_name WorldState extends RefCounted
var map: Map
var units: Array[Unit]
var turn_number: int
func clone() -> WorldState:
    # deep copy for AI simulations — units list duplicated, map ref shared (read-only)

class_name ActionPlan extends RefCounted
var moves: Array[Vector2i] = []  # path from start to target
var target: Unit                  # attack target (null = move only)

class_name ActionList extends RefCounted
var plans: Array[ActionPlan] = []
func is_empty() -> bool: return plans.is_empty()
```
- BasicAI（Tier 2）将在 clone 的 WorldState 上模拟，不污染真实状态

## Test Evidence: `tests/unit/ai/ai_data_structures_test.gd`
## Dependencies: Story 001（AIController 基类）、Map Epic、Unit Epic
